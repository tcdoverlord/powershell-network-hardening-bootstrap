<#
.SYNOPSIS
Unpacks PowerShell Network Hardening Bootstrap into a user-selected folder.

.DESCRIPTION
This repository is a lightweight bootstrap. The setup script expands the
runtime payload, creates working folders, validates the generated files, and
prints the launch command.
#>

[CmdletBinding()]
param(
    [string]$InstallPath
)

$ErrorActionPreference = 'Stop'

function Stop-Bootstrap {
    param([Parameter(Mandatory = $true)][string]$Message)

    Write-Host "ERROR: $Message" -ForegroundColor Red
    exit 1
}

function Write-Step {
    param(
        [Parameter(Mandatory = $true)][string]$Label,
        [Parameter(Mandatory = $true)][scriptblock]$Action
    )

    Write-Host ("{0,-42}" -f $Label) -NoNewline
    try {
        & $Action
        Write-Host 'OK' -ForegroundColor Green
    }
    catch {
        Write-Host 'FAILED' -ForegroundColor Red
        Stop-Bootstrap "$Label failed. $($_.Exception.Message)"
    }
}

function Resolve-SafeInstallPath {
    param([Parameter(Mandatory = $true)][string]$Path)

    $fullPath = [System.IO.Path]::GetFullPath($Path)
    $blockedRoots = @(
        $env:WINDIR,
        (Join-Path $env:WINDIR 'System32'),
        (Join-Path $env:ProgramFiles 'WindowsApps')
    ) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }

    foreach ($blockedRoot in $blockedRoots) {
        $blockedFullPath = [System.IO.Path]::GetFullPath($blockedRoot)
        if ($fullPath.StartsWith($blockedFullPath, [System.StringComparison]::OrdinalIgnoreCase)) {
            Stop-Bootstrap "Install location is blocked for safety: $fullPath"
        }
    }

    return $fullPath
}

function Test-PowerShellScript {
    param([Parameter(Mandatory = $true)][string]$Path)

    $tokens = $null
    $parseErrors = $null
    [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$tokens, [ref]$parseErrors) | Out-Null

    if ($parseErrors.Count -gt 0) {
        $details = ($parseErrors | ForEach-Object { $_.Message }) -join '; '
        Stop-Bootstrap "Generated PowerShell has syntax errors: $Path. $details"
    }
}

function Assert-GeneratedRuntime {
    param([Parameter(Mandatory = $true)][string]$Root)

    $requiredFolders = @('Backup', 'Logs')
    $requiredFiles = @(
        'Launch-Toolkit.bat',
        'Start-ToolkitMenu.ps1',
        'Bootstrap-WindowsHardeningToolkit.ps1',
        'Start-WindowsHardeningToolkit.ps1',
        'Restore-WindowsHardeningToolkit.ps1',
        'monitor-config.json',
        'README.md',
        'LICENSE'
    )

    foreach ($folder in $requiredFolders) {
        $path = Join-Path $Root $folder
        if (-not (Test-Path -LiteralPath $path -PathType Container)) {
            Stop-Bootstrap "Missing generated folder: $path"
        }
    }

    foreach ($file in $requiredFiles) {
        $path = Join-Path $Root $file
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
            Stop-Bootstrap "Missing generated file: $path"
        }

        if ((Get-Item -LiteralPath $path).Length -eq 0) {
            Stop-Bootstrap "Generated file is empty: $path"
        }
    }

    try {
        Get-Content -LiteralPath (Join-Path $Root 'monitor-config.json') -Raw | ConvertFrom-Json | Out-Null
    }
    catch {
        Stop-Bootstrap "Generated monitor-config.json is invalid JSON. $($_.Exception.Message)"
    }

    foreach ($script in @(
        'Start-ToolkitMenu.ps1',
        'Bootstrap-WindowsHardeningToolkit.ps1',
        'Start-WindowsHardeningToolkit.ps1',
        'Restore-WindowsHardeningToolkit.ps1'
    )) {
        Test-PowerShellScript -Path (Join-Path $Root $script)
    }
}

Write-Host '=================================================' -ForegroundColor Cyan
Write-Host 'PowerShell Network Hardening Bootstrap Setup' -ForegroundColor Cyan
Write-Host '=================================================' -ForegroundColor Cyan

$defaultInstall = 'C:\PowerShell-Network-Hardening-Bootstrap'
$payloadPath = Join-Path $PSScriptRoot 'assets\runtime-payload.zip'

if (-not (Test-Path -LiteralPath $payloadPath -PathType Leaf)) {
    Stop-Bootstrap "Missing runtime payload: $payloadPath"
}

if ([string]::IsNullOrWhiteSpace($InstallPath)) {
    Write-Host ''
    Write-Host 'INSTALL LOCATION SETUP' -ForegroundColor Yellow
    $InstallPath = Read-Host "Enter install path (ENTER for default: $defaultInstall)"
}

if ([string]::IsNullOrWhiteSpace($InstallPath)) {
    $InstallPath = $defaultInstall
}

$installRoot = Resolve-SafeInstallPath -Path $InstallPath

Write-Host ''
Write-Host "Payload: $payloadPath" -ForegroundColor DarkGray
Write-Host "Install: $installRoot" -ForegroundColor Green
Write-Host ''

Write-Step 'Creating install folder' {
    New-Item -ItemType Directory -Force -Path $installRoot | Out-Null
}

Write-Step 'Unpacking runtime payload' {
    Expand-Archive -LiteralPath $payloadPath -DestinationPath $installRoot -Force
}

Write-Step 'Creating runtime folders' {
    foreach ($folder in @('Backup', 'Logs')) {
        New-Item -ItemType Directory -Force -Path (Join-Path $installRoot $folder) | Out-Null
    }
}

Write-Step 'Unblocking installed scripts' {
    Get-ChildItem -LiteralPath $installRoot -Filter '*.ps1' -File | ForEach-Object {
        Unblock-File -LiteralPath $_.FullName -ErrorAction SilentlyContinue
    }
}

Write-Step 'Validating generated runtime' {
    Assert-GeneratedRuntime -Root $installRoot
}

Write-Host ''
Write-Host 'BOOTSTRAP COMPLETE' -ForegroundColor Green
Write-Host "Toolkit installed at: $installRoot"
Write-Host ''
Write-Host 'Launch options:'
Write-Host ("  Double-click: {0}" -f ([System.IO.Path]::Combine($installRoot, 'Launch-Toolkit.bat')))
Write-Host '  PowerShell:'
Write-Host ("    cd ""{0}""" -f $installRoot)
Write-Host '    .\Start-ToolkitMenu.ps1'
Write-Host ''
Write-Host 'PowerShell Network Hardening Bootstrap is ready.' -ForegroundColor Cyan
