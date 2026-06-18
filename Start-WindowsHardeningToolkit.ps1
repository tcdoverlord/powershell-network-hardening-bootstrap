<#
.SYNOPSIS
Monitors TCP activity and optionally applies a conservative Windows firewall baseline.

.DESCRIPTION
Windows Hardening Toolkit continuously logs new TCP connections with basic risk
classification. Hardening changes are opt-in and create a restore point before
changing firewall profile settings.

Run from an elevated PowerShell session.
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$ConfigPath = (Join-Path $PSScriptRoot 'monitor-config.json'),
    [string]$LogDirectory = (Join-Path $PSScriptRoot 'Logs'),
    [string]$BackupDirectory = (Join-Path $PSScriptRoot 'Backup'),
    [ValidateRange(1, 3600)]
    [int]$MonitorIntervalSeconds = 5,
    [switch]$ApplyHardening,
    [switch]$SkipHardening,
    [switch]$NoAlerts
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Test-IsAdministrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Read-ToolkitConfig {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Configuration file was not found: $Path"
    }

    $config = Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json

    [pscustomobject]@{
        Whitelist     = @($config.Whitelist | ForEach-Object { $_.ToString().ToLowerInvariant() })
        IgnoredIPs    = @($config.IgnoredIPs | ForEach-Object { $_.ToString() })
        HighRiskPorts = @($config.HighRiskPorts | ForEach-Object { [int]$_ })
    }
}

function Initialize-ToolkitFolders {
    param(
        [string]$LogPath,
        [string]$BackupPath
    )

    New-Item -ItemType Directory -Force -Path $LogPath, $BackupPath | Out-Null
}

function Get-VirtualNetworkAdapters {
    $patterns = @(
        'Hyper-V',
        'vEthernet',
        'VMware',
        'VirtualBox',
        'WSL',
        'Docker',
        'TAP-Windows',
        'ZeroTier',
        'Tailscale'
    )

    $pattern = $patterns -join '|'

    Get-NetAdapter -ErrorAction SilentlyContinue |
        Where-Object {
            $_.InterfaceDescription -match $pattern -or
            $_.Name -match $pattern
        } |
        Select-Object Name, InterfaceDescription, Status, MacAddress
}

function Get-RunningVirtualWorkloads {
    $workloads = @()

    if (Get-Command Get-VM -ErrorAction SilentlyContinue) {
        $runningHyperVGuests = @(Get-VM -ErrorAction SilentlyContinue | Where-Object { $_.State -eq 'Running' })
        foreach ($guest in $runningHyperVGuests) {
            $workloads += [pscustomobject]@{
                Type = 'Hyper-V VM'
                Name = $guest.Name
                Detail = 'State=Running'
            }
        }
    }

    $processChecks = @{
        'vmwp' = 'Hyper-V worker process'
        'vmware-vmx' = 'VMware virtual machine process'
        'VirtualBoxVM' = 'VirtualBox virtual machine process'
        'VBoxHeadless' = 'VirtualBox headless virtual machine process'
        'vmmem' = 'WSL/Docker virtual memory process'
        'vmmemWSL' = 'WSL virtual memory process'
        'com.docker.backend' = 'Docker Desktop backend'
    }

    foreach ($processName in $processChecks.Keys) {
        $processes = @(Get-Process -Name $processName -ErrorAction SilentlyContinue)
        foreach ($process in $processes) {
            $workloads += [pscustomobject]@{
                Type = $processChecks[$processName]
                Name = $process.ProcessName
                Detail = "PID=$($process.Id)"
            }
        }
    }

    return $workloads
}

function Test-HardeningKillSwitch {
    $virtualAdapters = @(Get-VirtualNetworkAdapters)
    $runningWorkloads = @(Get-RunningVirtualWorkloads)

    if ($virtualAdapters.Count -eq 0 -and $runningWorkloads.Count -eq 0) {
        return $true
    }

    Write-Warning 'Hardening kill switch triggered. No firewall changes were applied.'

    if ($runningWorkloads.Count -gt 0) {
        Write-Warning 'Running VM, WSL, Docker, or virtualization workloads were detected:'
        $runningWorkloads | Format-Table -AutoSize | Out-String | Write-Host
    }

    if ($virtualAdapters.Count -gt 0) {
        Write-Warning 'Virtual networking adapters were detected:'
        $virtualAdapters | Format-Table -AutoSize | Out-String | Write-Host
    }

    Write-Warning 'Stop VM/WSL/Docker workloads and review virtual networking before applying hardening.'
    return $false
}

function Test-RuntimeKillSwitch {
    param([string]$Path)

    $runningWorkloads = @(Get-RunningVirtualWorkloads)
    if ($runningWorkloads.Count -eq 0) {
        return $true
    }

    Write-ToolkitLog -Path $Path -Message '[KILL-SWITCH][HIGH] Virtual workload detected while monitoring. Exiting to avoid interfering with VM, WSL, or Docker activity.'
    $runningWorkloads | Format-Table -AutoSize | Out-String | Write-Host
    return $false
}

function New-HardeningRestorePoint {
    param([string]$Path)

    $profiles = Get-NetFirewallProfile -Profile Domain,Private,Public |
        Select-Object Name, Enabled, DefaultInboundAction, DefaultOutboundAction

    $restorePoint = [pscustomobject]@{
        CreatedAtUtc = (Get-Date).ToUniversalTime().ToString('o')
        ComputerName = $env:COMPUTERNAME
        FirewallProfiles = @($profiles)
        ToolkitFirewallRules = @(
            'Windows Hardening Toolkit - Allow Chrome Outbound',
            'Windows Hardening Toolkit - Allow Edge Outbound'
        )
    }

    $fileName = 'RestorePoint_{0}.json' -f (Get-Date -Format 'yyyyMMdd_HHmmss')
    $restorePath = Join-Path $Path $fileName
    $restorePoint | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $restorePath -Encoding UTF8

    return $restorePath
}

function Write-ToolkitLog {
    param(
        [string]$Message,
        [string]$Path
    )

    $line = '[{0}] {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Message
    Add-Content -LiteralPath $Path -Value $line

    switch -Regex ($Message) {
        '\[HIGH\]'   { Write-Host $line -ForegroundColor Red; break }
        '\[MEDIUM\]' { Write-Host $line -ForegroundColor Yellow; break }
        default      { Write-Host $line -ForegroundColor Gray }
    }
}

function Ensure-OutboundProgramRule {
    param(
        [string]$DisplayName,
        [string]$ProgramPath
    )

    if (-not (Test-Path -LiteralPath $ProgramPath)) {
        return
    }

    $existingRule = Get-NetFirewallRule -DisplayName $DisplayName -ErrorAction SilentlyContinue
    if ($existingRule) {
        return
    }

    New-NetFirewallRule `
        -DisplayName $DisplayName `
        -Program $ProgramPath `
        -Direction Outbound `
        -Action Allow `
        -Profile Domain,Private,Public | Out-Null
}

function Invoke-SystemHardening {
    param([string]$RestoreDirectory)

    if (-not (Test-HardeningKillSwitch)) {
        return $false
    }

    $restorePath = New-HardeningRestorePoint -Path $RestoreDirectory
    Write-Host "Restore point saved: $restorePath" -ForegroundColor DarkGray

    if ($PSCmdlet.ShouldProcess('Windows Firewall profiles', 'Enable firewall and apply baseline policy')) {
        Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True
        Set-NetFirewallProfile -Profile Domain,Public,Private -DefaultInboundAction Block -DefaultOutboundAction Allow
    }

    Ensure-OutboundProgramRule -DisplayName 'Windows Hardening Toolkit - Allow Chrome Outbound' `
        -ProgramPath 'C:\Program Files\Google\Chrome\Application\chrome.exe'
    Ensure-OutboundProgramRule -DisplayName 'Windows Hardening Toolkit - Allow Edge Outbound' `
        -ProgramPath 'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe'

    return $true
}

function Get-ConnectionRisk {
    param(
        [object]$Connection,
        [int[]]$HighRiskPorts
    )

    if ($HighRiskPorts -contains [int]$Connection.LocalPort) {
        return 'HIGH'
    }

    switch ($Connection.State.ToString()) {
        'Listen'      { return 'HIGH' }
        'Established' { return 'MEDIUM' }
        'SynReceived' { return 'MEDIUM' }
        'SynSent'     { return 'MEDIUM' }
        default       { return 'LOW' }
    }
}

function Test-SuspiciousProcessName {
    param([string]$ProcessName)

    $indicators = @('inject', 'backdoor', 'keylogger', 'stealer', 'cryptominer')
    foreach ($indicator in $indicators) {
        if ($ProcessName -match $indicator) {
            return $true
        }
    }

    return $false
}

function Get-NetworkActivity {
    Get-NetTCPConnection |
        Where-Object { $_.State -in @('Listen', 'Established', 'SynSent', 'SynReceived', 'TimeWait') } |
        Select-Object LocalAddress, LocalPort, RemoteAddress, RemotePort, State, OwningProcess
}

function Get-ConnectionKey {
    param([object]$Connection)

    return '{0}:{1}:{2}:{3}:{4}:{5}' -f `
        $Connection.LocalAddress,
        $Connection.LocalPort,
        $Connection.RemoteAddress,
        $Connection.RemotePort,
        $Connection.State,
        $Connection.OwningProcess
}

function Show-ToolkitAlert {
    param([string]$Text)

    if ($NoAlerts) {
        return
    }

    try {
        Add-Type -AssemblyName PresentationFramework -ErrorAction Stop
        [System.Windows.MessageBox]::Show($Text, 'Windows Hardening Toolkit Alert') | Out-Null
    }
    catch {
        Write-Warning $Text
    }
}

if (-not (Test-IsAdministrator)) {
    throw 'Run this script from an elevated PowerShell session.'
}

$config = Read-ToolkitConfig -Path $ConfigPath
Initialize-ToolkitFolders -LogPath $LogDirectory -BackupPath $BackupDirectory

$logFile = Join-Path $LogDirectory ('PortLog_{0}.txt' -f (Get-Date -Format 'yyyyMMdd_HHmmss'))

Write-Host 'Windows Hardening Toolkit' -ForegroundColor Cyan
Write-Host "Config: $ConfigPath" -ForegroundColor DarkGray
Write-Host "Logs:   $logFile" -ForegroundColor DarkGray

if ($SkipHardening) {
    Write-Warning '-SkipHardening is kept for compatibility. Hardening is now skipped unless -ApplyHardening is specified.'
}

if ($ApplyHardening -and -not $SkipHardening) {
    Write-Host 'Applying Windows firewall baseline...' -ForegroundColor Cyan
    $hardeningApplied = Invoke-SystemHardening -RestoreDirectory $BackupDirectory
    if ($hardeningApplied) {
        Write-Host 'Hardening baseline complete.' -ForegroundColor Green
    }
}
else {
    Write-Host 'Monitoring only. No firewall or service changes will be applied.' -ForegroundColor Yellow
    Write-Host 'Use -ApplyHardening to apply the firewall baseline after reviewing VM/network impact.' -ForegroundColor DarkGray
}

Write-ToolkitLog -Path $logFile -Message '=== MONITOR STARTED ==='

$knownConnections = @{}
foreach ($connection in Get-NetworkActivity) {
    $knownConnections[(Get-ConnectionKey -Connection $connection)] = $true
}

Write-ToolkitLog -Path $logFile -Message 'Baseline captured.'
Write-Host 'Monitoring new TCP activity. Press Ctrl+C to stop.' -ForegroundColor Cyan

while ($true) {
    Start-Sleep -Seconds $MonitorIntervalSeconds

    if (-not (Test-RuntimeKillSwitch -Path $logFile)) {
        break
    }

    $currentConnections = Get-NetworkActivity
    $nextKnownConnections = @{}

    foreach ($connection in $currentConnections) {
        $key = Get-ConnectionKey -Connection $connection
        $nextKnownConnections[$key] = $true

        if ($knownConnections.ContainsKey($key)) {
            continue
        }

        $process = Get-Process -Id $connection.OwningProcess -ErrorAction SilentlyContinue
        $processName = if ($process) { $process.ProcessName } else { 'Unknown' }
        $processNameLower = $processName.ToLowerInvariant()

        if ($config.Whitelist -contains $processNameLower) {
            continue
        }

        if ($config.IgnoredIPs -contains $connection.RemoteAddress) {
            continue
        }

        $risk = Get-ConnectionRisk -Connection $connection -HighRiskPorts $config.HighRiskPorts
        $message = '[OPENED][{0}] {1} | {2} -> {3}:{4}' -f `
            $risk,
            $processName,
            $connection.LocalPort,
            $connection.RemoteAddress,
            $connection.RemotePort

        if ((Test-SuspiciousProcessName -ProcessName $processName) -or $risk -eq 'HIGH') {
            Show-ToolkitAlert -Text $message
        }

        Write-ToolkitLog -Path $logFile -Message $message
    }

    $knownConnections = $nextKnownConnections
}
