<#
.SYNOPSIS
Interactive menu for PowerShell Network Hardening Bootstrap.
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$toolkitScript = Join-Path $PSScriptRoot 'Start-WindowsHardeningToolkit.ps1'
$restoreScript = Join-Path $PSScriptRoot 'Restore-WindowsHardeningToolkit.ps1'
$logDirectory = Join-Path $PSScriptRoot 'Logs'

function Test-IsAdministrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Wait-ForUser {
    Write-Host ''
    Read-Host 'Press Enter to return to the menu' | Out-Null
}

function Show-Header {
    Clear-Host
    Write-Host 'PowerShell Network Hardening Bootstrap' -ForegroundColor Cyan
    Write-Host 'Monitor first. Harden intentionally. Restore safely.' -ForegroundColor DarkGray
    Write-Host ''
}

function Invoke-SafetyCheck {
    Show-Header
    Write-Host 'Safety Check' -ForegroundColor Cyan
    Write-Host ''

    $virtualPatterns = @(
        'Hyper-V',
        'vEthernet',
        'VMware',
        'VirtualBox',
        'WSL',
        'Docker',
        'TAP-Windows',
        'ZeroTier',
        'Tailscale'
    ) -join '|'

    $virtualAdapters = @(Get-NetAdapter -ErrorAction SilentlyContinue |
        Where-Object { $_.InterfaceDescription -match $virtualPatterns -or $_.Name -match $virtualPatterns } |
        Select-Object Name, InterfaceDescription, Status)

    $processNames = @('vmwp', 'vmware-vmx', 'VirtualBoxVM', 'VBoxHeadless', 'vmmem', 'vmmemWSL', 'com.docker.backend')
    $runningVirtualProcesses = foreach ($processName in $processNames) {
        Get-Process -Name $processName -ErrorAction SilentlyContinue |
            Select-Object ProcessName, Id
    }

    if ($virtualAdapters.Count -eq 0 -and @($runningVirtualProcesses).Count -eq 0) {
        Write-Host 'No VM, WSL, Docker, or virtual networking indicators were detected.' -ForegroundColor Green
        Write-Host 'Hardening preflight looks clear.' -ForegroundColor Green
    }
    else {
        Write-Host 'Hardening should not be applied right now.' -ForegroundColor Yellow

        if ($virtualAdapters.Count -gt 0) {
            Write-Host ''
            Write-Host 'Virtual adapters detected:' -ForegroundColor Yellow
            $virtualAdapters | Format-Table -AutoSize
        }

        if (@($runningVirtualProcesses).Count -gt 0) {
            Write-Host ''
            Write-Host 'Virtual workload processes detected:' -ForegroundColor Yellow
            $runningVirtualProcesses | Format-Table -AutoSize
        }
    }

    Wait-ForUser
}

function Open-LogsFolder {
    New-Item -ItemType Directory -Force -Path $logDirectory | Out-Null
    Start-Process explorer.exe -ArgumentList $logDirectory
}

if (-not (Test-IsAdministrator)) {
    Write-Warning 'This menu works best from an elevated PowerShell session.'
    Write-Warning 'Monitor mode may work, but hardening and restore actions require Administrator.'
    Write-Host ''
    Read-Host 'Press Enter to continue' | Out-Null
}

foreach ($path in @($toolkitScript, $restoreScript)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Required script was not found: $path"
    }

    Unblock-File -LiteralPath $path -ErrorAction SilentlyContinue
}

while ($true) {
    Show-Header
    Write-Host '1. Start monitor-only mode (press Ctrl+C to stop)' -ForegroundColor White
    Write-Host '2. Preview safe hardening changes' -ForegroundColor White
    Write-Host '3. Apply safe firewall baseline' -ForegroundColor White
    Write-Host '4. Restore latest backup' -ForegroundColor White
    Write-Host '5. Open logs folder' -ForegroundColor White
    Write-Host '6. Run safety check' -ForegroundColor White
    Write-Host '7. Exit' -ForegroundColor White
    Write-Host ''

    $choice = Read-Host 'Select an option'

    switch ($choice) {
        '1' {
            try {
                & $toolkitScript
            }
            finally {
                Wait-ForUser
            }
        }
        '2' {
            & $toolkitScript -ApplyHardening -WhatIf
            Wait-ForUser
        }
        '3' {
            Show-Header
            Write-Host 'This will apply the safe firewall baseline only if the kill switch passes.' -ForegroundColor Yellow
            $confirm = Read-Host 'Type APPLY to continue'
            if ($confirm -eq 'APPLY') {
                & $toolkitScript -ApplyHardening
            }
            else {
                Write-Host 'Cancelled.' -ForegroundColor Yellow
            }
            Wait-ForUser
        }
        '4' {
            & $restoreScript
            Wait-ForUser
        }
        '5' {
            Open-LogsFolder
        }
        '6' {
            Invoke-SafetyCheck
        }
        '7' {
            break
        }
        default {
            Write-Host 'Invalid option.' -ForegroundColor Yellow
            Start-Sleep -Seconds 1
        }
    }
}
