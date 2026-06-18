<#
.SYNOPSIS
Prepares and launches Windows Hardening Toolkit from a cloned repository.
#>

[CmdletBinding()]
param(
    [switch]$ApplyHardening,
    [switch]$NoAlerts,
    [ValidateRange(1, 3600)]
    [int]$MonitorIntervalSeconds = 5
)

$ErrorActionPreference = 'Stop'

$toolkitScript = Join-Path $PSScriptRoot 'Start-WindowsHardeningToolkit.ps1'

if (-not (Test-Path -LiteralPath $toolkitScript)) {
    throw "Toolkit entry script was not found: $toolkitScript"
}

Unblock-File -LiteralPath $toolkitScript -ErrorAction SilentlyContinue
Unblock-File -LiteralPath (Join-Path $PSScriptRoot 'monitor-config.json') -ErrorAction SilentlyContinue
Unblock-File -LiteralPath (Join-Path $PSScriptRoot 'Restore-WindowsHardeningToolkit.ps1') -ErrorAction SilentlyContinue

$arguments = @{
    MonitorIntervalSeconds = $MonitorIntervalSeconds
}

if ($ApplyHardening) {
    $arguments.ApplyHardening = $true
}

if ($NoAlerts) {
    $arguments.NoAlerts = $true
}

& $toolkitScript @arguments
