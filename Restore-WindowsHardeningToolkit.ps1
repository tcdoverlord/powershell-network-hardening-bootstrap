<#
.SYNOPSIS
Restores firewall and service settings saved by Windows Hardening Toolkit.

.DESCRIPTION
Reads a restore point from the Backup folder and restores Windows Firewall
profile defaults captured before hardening was applied.
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$BackupDirectory = (Join-Path $PSScriptRoot 'Backup'),
    [string]$RestorePointPath,
    [switch]$KeepToolkitFirewallRules
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Test-IsAdministrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-IsAdministrator)) {
    throw 'Run this script from an elevated PowerShell session.'
}

if (-not $RestorePointPath) {
    if (-not (Test-Path -LiteralPath $BackupDirectory)) {
        throw "Backup directory was not found: $BackupDirectory"
    }

    $latestRestorePoint = Get-ChildItem -LiteralPath $BackupDirectory -Filter 'RestorePoint_*.json' |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1

    if (-not $latestRestorePoint) {
        throw "No restore points were found in: $BackupDirectory"
    }

    $RestorePointPath = $latestRestorePoint.FullName
}

if (-not (Test-Path -LiteralPath $RestorePointPath)) {
    throw "Restore point was not found: $RestorePointPath"
}

$restorePoint = Get-Content -LiteralPath $RestorePointPath -Raw | ConvertFrom-Json

Write-Host 'Windows Hardening Toolkit Restore' -ForegroundColor Cyan
Write-Host "Restore point: $RestorePointPath" -ForegroundColor DarkGray
Write-Host "Created UTC:   $($restorePoint.CreatedAtUtc)" -ForegroundColor DarkGray

foreach ($profile in $restorePoint.FirewallProfiles) {
    if ($PSCmdlet.ShouldProcess("Firewall profile $($profile.Name)", 'Restore profile defaults')) {
        Set-NetFirewallProfile `
            -Profile $profile.Name `
            -Enabled $profile.Enabled `
            -DefaultInboundAction $profile.DefaultInboundAction `
            -DefaultOutboundAction $profile.DefaultOutboundAction
    }
}

if (-not $KeepToolkitFirewallRules) {
    foreach ($ruleName in $restorePoint.ToolkitFirewallRules) {
        $rules = @(Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue)
        foreach ($rule in $rules) {
            if ($PSCmdlet.ShouldProcess($rule.DisplayName, 'Remove toolkit-created firewall rule')) {
                Remove-NetFirewallRule -Name $rule.Name
            }
        }
    }
}

Write-Host 'Restore complete.' -ForegroundColor Green
