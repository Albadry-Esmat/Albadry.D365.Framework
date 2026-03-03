<#
.SYNOPSIS
    Generates Early-Bound classes for D365 / Dataverse using PAC CLI.

.PARAMETER environment
    The target environment profile to use: Dev, UAT, or Prod.

.PARAMETER all
    Generate for all environments at once.
#>

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("Dev","UAT","Prod")]
    [string]$environment,

    [switch]$all
)

# Stop on errors
$ErrorActionPreference = "Stop"

# Configuration
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
$outputBase = Join-Path $scriptRoot "src\Domain\Albadry.D365.Domain\EarlyBound"
$namespace = "Albadry.D365.Domain.EarlyBound"
$envList = @("Dev","UAT","Prod")

if ($all) { $environments = $envList }
elseif ($environment) { $environments = @($environment) }
else {
    Write-Host "Please specify -environment Dev/UAT/Prod or -all" -ForegroundColor Red
    exit 1
}

Write-Host "========== Early-Bound Generation ==========" -ForegroundColor Cyan

# --- Validate PAC CLI ---
try {
    $pacVersionRaw = & pac modelbuilder -? 2>&1 | Select-String "Version" | Select-Object -First 1
    if (-not $pacVersionRaw) { throw "PAC CLI not found." }
    $pacVersion = ($pacVersionRaw -replace "Version: ","").Trim()
    Write-Host "PAC CLI version: $pacVersion"
} catch {
    Write-Host "PAC CLI not found or not installed. Please install v2.3+" -ForegroundColor Red
    exit 1
}

# --- Loop through environments ---
foreach ($env in $environments) {
    Write-Host "`n========== Processing $env ==========" -ForegroundColor Yellow

    # --- Safety check for Prod ---
    if ($env -eq "Prod") {
        $confirm = Read-Host "WARNING: You are about to generate Early-Bound classes for PROD! Type 'YES' to continue"
        if ($confirm -ne "YES") { Write-Host "Aborted by user"; continue }
    }

    # --- Select PAC auth profile ---
    Write-Host "Selecting PAC authentication profile: $env"
    & pac auth select --name $env

    # --- Setup output folder ---
    $outputDir = Join-Path $outputBase $env
    if (-not (Test-Path $outputDir)) { 
        Write-Host "Creating output folder: $outputDir"
        New-Item -ItemType Directory -Force -Path $outputDir | Out-Null
    }

    # --- Generate timestamped filename ---
    $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $fileName = "EarlyBound_$env`_$timestamp.cs"
    $logName = "earlybound_$env`_$timestamp.log"
    $logFile = Join-Path $outputDir $logName

    # --- Optional: backup Prod ---
    if ($env -eq "Prod") {
        $backupDir = Join-Path $outputDir "Backup_$timestamp"
        Write-Host "Backing up old files to $backupDir"
        if (Test-Path $outputDir) {
            Copy-Item $outputDir $backupDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    # --- Clean output folder ---
    Write-Host "Cleaning existing Early-Bound files in $outputDir"
    Get-ChildItem -Path $outputDir -File | Remove-Item -Force -ErrorAction SilentlyContinue

    # --- Run PAC CLI to generate Early-Bound ---
    Write-Host "Generating Early-Bound classes..."
    $cmd = @(
        "pac modelbuilder build",
        "--environment https://albadry-$($env.ToLower()).crm4.dynamics.com",
        "--outdirectory `"$outputDir`"",
        "--namespace `"$namespace`"",
        "--emitfieldsclasses",
        "--generateGlobalOptionSets",
        "--generatesdkmessages",
        "--logLevel All"
    ) -join " "

    Write-Host "Executing: $cmd"
    Invoke-Expression $cmd | Tee-Object -FilePath $logFile

    Write-Host "`nGeneration completed for $env."
    Write-Host "Output folder: $outputDir"
    Write-Host "Log file: $logFile"
}

Write-Host "`n========== Early-Bound Generation Complete ==========" -ForegroundColor Cyan