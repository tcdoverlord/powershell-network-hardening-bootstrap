<#
.SYNOPSIS
Unpacks PowerShell Network Hardening Bootstrap into a user-selected folder.

.DESCRIPTION
This bootstrap installer copies the complete toolkit runtime from the repository
folder into a chosen install location, creates runtime folders, validates the
generated files, and prints the launch command.
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

    Write-Host ("{0,-44}" -f $Label) -NoNewline
    try {
        & $Action
        Write-Host 'OK' -ForegroundColor Green
    }
    catch {
        Write-Host 'FAILED' -ForegroundColor Red
        Stop-Bootstrap "$Label failed. $($_.Exception.Message)"
    }
}

function Test-SafeInstallPath {
    param([Parameter(Mandatory = $true)][string]$Path)

    $fullPath = [System.IO.Path]::GetFullPath($Path)
    $blockedRoots = @(
        "$env:WINDIR",
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

function Copy-ToolkitFile {
    param(
        [Parameter(Mandatory = $true)][string]$Source,
        [Parameter(Mandatory = $true)][string]$Destination
    )

    if (-not (Test-Path -LiteralPath $Source -PathType Leaf)) {
        Stop-Bootstrap "Missing source file: $Source"
    }

    Copy-Item -LiteralPath $Source -Destination $Destination -Force

    if (-not (Test-Path -LiteralPath $Destination -PathType Leaf)) {
        Stop-Bootstrap "Failed to create file: $Destination"
    }

    if ((Get-Item -LiteralPath $Destination).Length -eq 0) {
        Stop-Bootstrap "Generated file is empty: $Destination"
    }
}

function Assert-GeneratedToolkit {
    param([Parameter(Mandatory = $true)][string]$Root)

    $requiredFolders = @(
        'assets',
        'Backup',
        'Logs'
    )

    $requiredFiles = @(
        'Launch-Toolkit.bat',
        'Start-ToolkitMenu.ps1',
        'Bootstrap-WindowsHardeningToolkit.ps1',
        'Start-WindowsHardeningToolkit.ps1',
        'Restore-WindowsHardeningToolkit.ps1',
        'monitor-config.json',
        'README.md',
        'LICENSE',
        'assets\architecture.png',
        'assets\readme-banner.png'
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

if ([string]::IsNullOrWhiteSpace($InstallPath)) {
    Write-Host ''
    Write-Host 'INSTALL LOCATION SETUP' -ForegroundColor Yellow
    $InstallPath = Read-Host "Enter install path (ENTER for default: $defaultInstall)"
}

if ([string]::IsNullOrWhiteSpace($InstallPath)) {
    $InstallPath = $defaultInstall
}

$installRoot = Test-SafeInstallPath -Path $InstallPath
$sourceRoot = $PSScriptRoot

Write-Host ''
Write-Host "Source:  $sourceRoot" -ForegroundColor DarkGray
Write-Host "Install: $installRoot" -ForegroundColor Green
Write-Host ''

$filesToCopy = @(
    'Launch-Toolkit.bat',
    'Start-ToolkitMenu.ps1',
    'Bootstrap-WindowsHardeningToolkit.ps1',
    'Start-WindowsHardeningToolkit.ps1',
    'Restore-WindowsHardeningToolkit.ps1',
    'monitor-config.json',
    'README.md',
    'LICENSE'
)

Write-Step 'Creating install folders' {
    foreach ($folder in @($installRoot, (Join-Path $installRoot 'assets'), (Join-Path $installRoot 'Backup'), (Join-Path $installRoot 'Logs'))) {
        New-Item -ItemType Directory -Force -Path $folder | Out-Null
    }
}

Write-Step 'Copying toolkit runtime files' {
    foreach ($file in $filesToCopy) {
        Copy-ToolkitFile -Source (Join-Path $sourceRoot $file) -Destination (Join-Path $installRoot $file)
    }
}

Write-Step 'Copying README image assets' {
    foreach ($asset in @('architecture.png', 'readme-banner.png')) {
        Copy-ToolkitFile -Source (Join-Path $sourceRoot "assets\$asset") -Destination (Join-Path $installRoot "assets\$asset")
    }
}

Write-Step 'Unblocking installed scripts' {
    Get-ChildItem -LiteralPath $installRoot -Filter '*.ps1' -File | ForEach-Object {
        Unblock-File -LiteralPath $_.FullName -ErrorAction SilentlyContinue
    }
}

Write-Step 'Validating generated toolkit' {
    Assert-GeneratedToolkit -Root $installRoot
}

Write-Host ''
Write-Host 'BOOTSTRAP COMPLETE' -ForegroundColor Green
Write-Host "Toolkit installed at: $installRoot"
Write-Host ''
Write-Host 'Launch options:'
Write-Host "  Double-click: $([System.IO.Path]::Combine($installRoot, 'Launch-Toolkit.bat'))"
Write-Host '  PowerShell:'
Write-Host "    cd `"$installRoot`""
Write-Host '    .\Start-ToolkitMenu.ps1'
Write-Host ''
Write-Host 'PowerShell Network Hardening Bootstrap is ready.' -ForegroundColor Cyan
