# ======================================
# 🔐 System-Hardening-NetworkMonitor-v6
# CLEAN + SAFE + WHITELIST AWARE
# ======================================

# ======================================
# 📦 LOAD CONFIG
# ======================================

$configPath = "C:\Update Code\monitor-config.json"

if (!(Test-Path $configPath)) {
    Write-Host "Config file missing!" -ForegroundColor Red
    exit
}

$config = Get-Content $configPath -Raw | ConvertFrom-Json

$Whitelist = $config.Whitelist | ForEach-Object { $_.ToLower() }
$IgnoredIPs = $config.IgnoredIPs
$HighRiskPorts = $config.HighRiskPorts

Write-Host "Config loaded." -ForegroundColor Green

# ======================================
# 🔐 SYSTEM HARDENING
# ======================================

Write-Host "Applying firewall baseline..." -ForegroundColor Cyan

Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True
Set-NetFirewallProfile -Profile Domain,Public,Private `
    -DefaultInboundAction Block `
    -DefaultOutboundAction Allow

# Disable UPnP (common attack surface)
Try {
    Stop-Service -Name "upnphost" -Force -ErrorAction SilentlyContinue
    Set-Service -Name "upnphost" -StartupType Disabled
} Catch {}

# ======================================
# 🌐 EXPLICIT BROWSER ALLOW (FIXES 403)
# ======================================

$chromePath = "C:\Program Files\Google\Chrome\Application\chrome.exe"
$edgePath   = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"

if (Test-Path $chromePath) {
    New-NetFirewallRule -DisplayName "Allow Chrome Outbound" `
    -Program $chromePath -Direction Outbound -Action Allow -ErrorAction SilentlyContinue
}

if (Test-Path $edgePath) {
    New-NetFirewallRule -DisplayName "Allow Edge Outbound" `
    -Program $edgePath -Direction Outbound -Action Allow -ErrorAction SilentlyContinue
}

Write-Host "Hardening complete." -ForegroundColor Green

# ======================================
# 📁 LOG SETUP
# ======================================

$baseDir = "C:\Update Code"
$logDir = "$baseDir\Logs"
$backupDir = "$baseDir\Backup"

New-Item -ItemType Directory -Force -Path $logDir, $backupDir | Out-Null

$logFile = "$logDir\PortLog_$(Get-Date -Format yyyyMMdd_HHmmss).txt"

# ======================================
# 🧾 LOG FUNCTION
# ======================================

function Write-Log {
    param([string]$msg)

    $time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[$time] $msg"

    Add-Content $logFile $line

    if ($msg -match "\[HIGH\]") { Write-Host $line -ForegroundColor Red }
    elseif ($msg -match "\[MEDIUM\]") { Write-Host $line -ForegroundColor Yellow }
    else { Write-Host $line -ForegroundColor Gray }
}

# ======================================
# 🚨 ALERT POPUP
# ======================================

Add-Type -AssemblyName PresentationFramework

function Show-Alert($text) {
    [System.Windows.MessageBox]::Show($text, "⚠ Network Alert")
}

# ======================================
# 🧠 RISK CLASSIFIER
# ======================================

function Get-Risk($conn) {
    if ($conn.State -eq "Listen") { return "HIGH" }
    if ($conn.State -eq "Established") { return "MEDIUM" }
    if ($conn.State -in @("SynReceived","SynSent")) { return "MEDIUM" }
    return "LOW"
}

# ======================================
# 🔍 NETWORK SNAPSHOT
# ======================================

function Get-NetworkActivity {
    Get-NetTCPConnection | Where-Object {
        $_.State -in @("Listen","Established","SynSent","SynReceived","TimeWait")
    } | Select-Object LocalAddress,LocalPort,RemoteAddress,RemotePort,State,OwningProcess
}

# ======================================
# 🧬 SUSPICIOUS DETECTION
# ======================================

function Check-Suspicious($procName) {

    $Indicators = @(
        "inject",
        "backdoor",
        "keylogger",
        "stealer",
        "cryptominer",
        "meterpreter",
        "reverse_shell",
        "payload",
        "remoteadmin"
    )

    foreach ($Indicator in $Indicators) {
        if ($procName -match $Indicator) {
            return $true
        }
    }

    return $false
}

# ======================================
# 📊 BASELINE
# ======================================

Write-Log "=== MONITOR STARTED ==="

$known = @{}

$current = Get-NetworkActivity
foreach ($c in $current) {
    $key = "$($c.LocalAddress):$($c.LocalPort):$($c.RemoteAddress):$($c.RemotePort):$($c.State)"
    $known[$key] = $true
}

Write-Log "Baseline captured."

# ======================================
# 🔁 MONITOR LOOP
# ======================================

while ($true) {
    Start-Sleep 5

    $current = Get-NetworkActivity
    $new = @{}

    foreach ($c in $current) {

        $key = "$($c.LocalAddress):$($c.LocalPort):$($c.RemoteAddress):$($c.RemotePort):$($c.State)"
        $new[$key] = $true

        if (-not $known.ContainsKey($key)) {

            $proc = Get-Process -Id $c.OwningProcess -ErrorAction SilentlyContinue
            $name = if ($proc) { $proc.ProcessName } else { "Unknown" }

            $nameLower = $name.ToLower()

            # ✅ IGNORE WHITELIST (no spam)
            if ($Whitelist -contains $nameLower) { continue }

            # ✅ IGNORE SAFE IPS
            if ($IgnoredIPs -contains $c.RemoteAddress) { continue }

            $risk = Get-Risk $c

            if ($HighRiskPorts -contains $c.LocalPort) {
                $risk = "HIGH"
            }

            $msg = "[OPENED][$risk] $name | $($c.LocalPort) -> $($c.RemoteAddress):$($c.RemotePort)"

            if (Check-Suspicious $name -or $risk -eq "HIGH") {
                Show-Alert $msg
            }

            Write-Log $msg
        }
    }

    $known = $new
}
