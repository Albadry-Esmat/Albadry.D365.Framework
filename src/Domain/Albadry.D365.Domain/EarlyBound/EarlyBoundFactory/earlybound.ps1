<#
.SYNOPSIS
    Fast Early-Bound Generator for Dynamics 365 / Dataverse
    Created by Albadry Esmat

.DESCRIPTION
    Generates all early-bound classes in one PAC CLI call.
    Detects changes by hashing the entire output folder.
    Supports preview mode, colorful logging, and automatic cleanup.

.PARAMETER Preview
    Show what will be generated without executing.
#>

param(
    [switch]$Preview
)

$ErrorActionPreference = "Stop"

#region Logging Functions
function Write-Info { 
    param([string]$M) 
    $timestamp = Get-Date -Format "HH:mm:ss"
    Write-Host "[$timestamp] [INFO]  $M" -ForegroundColor Cyan 
}

function Write-OK { 
    param([string]$M) 
    $timestamp = Get-Date -Format "HH:mm:ss"
    Write-Host "[$timestamp] [OK]    $M" -ForegroundColor Green 
}

function Write-Warn { 
    param([string]$M) 
    $timestamp = Get-Date -Format "HH:mm:ss"
    Write-Host "[$timestamp] [WARN]  $M" -ForegroundColor Yellow 
}

function Write-Err { 
    param([string]$M) 
    $timestamp = Get-Date -Format "HH:mm:ss"
    Write-Host "[$timestamp] [ERROR] $M" -ForegroundColor Red 
}

function Write-Header {
    param([string]$Title)
    Write-Host ""
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "  $Title" -ForegroundColor Cyan
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host ""
}

function Write-Section {
    param([string]$Title)
    Write-Host ""
    Write-Host "--- $Title ---" -ForegroundColor Yellow
}
#endregion

#region Banner
Write-Header "Albadry's EarlyBound Generator for Dynamics 365"
Write-Host "  Developer: Albadry Esmat" -ForegroundColor Gray
Write-Host "  Version:   2.0 (Fast & Filtered)" -ForegroundColor Gray
Write-Host "  Date:      $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host ""
#endregion

#region Paths
Write-Section "Loading Configuration"
$scriptRoot = $PSScriptRoot
$configFile = Join-Path $scriptRoot "earlybound.configuration.json"
$metadataFile = Join-Path $scriptRoot "earlybound.metadata.json"

Write-Info "Configuration file: $configFile"

if (-not (Test-Path $configFile)) { 
    Write-Err "Configuration file not found!"
    Write-Host "  Expected: $configFile" -ForegroundColor Gray
    exit 1 
}

$config = Get-Content -Raw $configFile | ConvertFrom-Json
Write-OK "Configuration loaded successfully"

$outputDir = Join-Path $scriptRoot "..\EarlyBoundClasses"
$logFile = Join-Path $outputDir "earlybound.log"

Write-Info "Output directory: $outputDir"
Write-Info "Log file: $logFile"

# Ensure output directory exists
if (-not (Test-Path $outputDir)) { 
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null 
    Write-OK "Created output directory"
}
#endregion

#region PAC CLI Check
Write-Section "Checking Prerequisites"

Write-Info "Verifying PAC CLI installation..."
if (-not (Get-Command pac -ErrorAction SilentlyContinue)) {
    Write-Err "PAC CLI not found!"
    Write-Host ""
    Write-Host "  Albadry, please install PAC CLI first:" -ForegroundColor Yellow
    Write-Host "  https://aka.ms/PowerPlatformCLI" -ForegroundColor Gray
    Write-Host ""
    exit 1
}

$pacVersion = (pac --version 2>&1 | Select-Object -First 1)
Write-OK "PAC CLI found: $pacVersion"

Write-Info "Verifying authentication..."
$authCheck = pac auth list 2>&1 | Out-String
if ($authCheck -notmatch '\*') {
    Write-Err "No active PAC authentication!"
    Write-Host ""
    Write-Host "  Albadry, please authenticate first:" -ForegroundColor Yellow
    Write-Host "  pac auth create --url $($config.dataverseUrl)" -ForegroundColor Gray
    Write-Host ""
    exit 1
}

$activeAuth = ($authCheck -split "`n" | Where-Object { $_ -match '\*' }) -replace '\s+', ' '
Write-OK "Authenticated: $activeAuth"
#endregion

#region Load previous metadata hash
$previousHash = $null
if (Test-Path $metadataFile) {
    $previousMetadata = Get-Content -Raw $metadataFile | ConvertFrom-Json
    $previousHash = $previousMetadata.folderHash
}
#endregion

#region Build filters for PAC
Write-Section "Configuring Filters"

$entitiesFilter = $config.filters.entities -join ';'
$actionsFilter  = $config.filters.actions -join ';'

# NOTE: PAC CLI does not support filtering optionsets!
# The --generateGlobalOptionSets flag generates ALL global optionsets
# We'll generate all and then delete the ones NOT in the filter
$includeOptionSets = ($config.filters.optionSets.Count -gt 0)
$optionSetsToKeep = $config.filters.optionSets

Write-Info "Environment: $($config.dataverseUrl)"
Write-Info "Namespace: $($config.namespace)"
Write-Info "Service Context: $($config.serviceContextName)"
Write-Host ""

Write-Host "  Filters Applied:" -ForegroundColor Cyan
Write-Host "    Entities:   $($config.filters.entities.Count) selected" -ForegroundColor White
foreach ($entity in $config.filters.entities) {
    Write-Host "      - $entity" -ForegroundColor Gray
}

Write-Host ""
Write-Host "    Actions:    $($config.filters.actions.Count) selected" -ForegroundColor White
foreach ($action in $config.filters.actions) {
    Write-Host "      - $action" -ForegroundColor Gray
}

Write-Host ""
if ($includeOptionSets) {
    Write-Host "    OptionSets: $($optionSetsToKeep.Count) selected (filtered from ALL)" -ForegroundColor White
    foreach ($optionset in $optionSetsToKeep) {
        Write-Host "      - $optionset" -ForegroundColor Gray
    }
    Write-Host ""
    Write-Warn "PAC CLI will generate ALL optionsets (~100), then Albadry's filter will delete unwanted ones"
} else {
    Write-Host "    OptionSets: (disabled)" -ForegroundColor Gray
}
#endregion

#region Preview mode: just show what would happen
if ($Preview) {
    Write-Header "PREVIEW MODE - No Files Will Be Generated"

    Write-Host "  Albadry, here's what WOULD be generated:" -ForegroundColor Magenta
    Write-Host ""
    Write-Host "  Command to execute:" -ForegroundColor Yellow
    Write-Host "    pac modelbuilder build" -ForegroundColor Gray
    Write-Host "      --environment $($config.dataverseUrl)" -ForegroundColor Gray
    Write-Host "      --namespace $($config.namespace)" -ForegroundColor Gray
    Write-Host "      --serviceContextName $($config.serviceContextName)" -ForegroundColor Gray
    Write-Host "      --outdirectory $outputDir" -ForegroundColor Gray
    if ($entitiesFilter) {
        Write-Host "      --entitynamesfilter $entitiesFilter" -ForegroundColor Gray
    }
    if ($actionsFilter) {
        Write-Host "      --messagenamesfilter $actionsFilter" -ForegroundColor Gray
    }
    if ($includeOptionSets) {
        Write-Host "      --generateGlobalOptionSets" -ForegroundColor Gray
    }

    Write-Host ""
    Write-Host "  Expected Output:" -ForegroundColor Yellow
    Write-Host "    - $($config.filters.entities.Count) Entity classes" -ForegroundColor Gray
    Write-Host "    - $($config.filters.actions.Count) Message/Action classes" -ForegroundColor Gray
    if ($includeOptionSets) {
        Write-Host "    - $($optionSetsToKeep.Count) OptionSet classes (filtered from ~100)" -ForegroundColor Gray
    }
    Write-Host "    - 1 CrmServiceContext.cs" -ForegroundColor Gray
    Write-Host "    - 1 EntityOptionSetEnum.cs" -ForegroundColor Gray

    Write-Host ""
    Write-Host "  Output Location:" -ForegroundColor Yellow
    Write-Host "    $outputDir" -ForegroundColor Gray

    Write-Host ""
    Write-OK "Preview complete. Run without -Preview to execute."
    Write-Host ""
    exit 0
}
#endregion

#region Delete old files before generating new ones
Write-Section "Preparing Output Directory"

Write-Info "Cleaning previous generation..."
if (Test-Path $outputDir) {
    $oldFiles = Get-ChildItem "$outputDir" -Recurse -File
    $oldFileCount = $oldFiles.Count

    Remove-Item "$outputDir\*" -Recurse -Force -ErrorAction SilentlyContinue
    Write-OK "Deleted $oldFileCount old files"
} else {
    Write-Info "Output directory is new (first generation)"
}
#endregion

#region Initialize log
$logHeader = @"
================================================================
Albadry Esmat - Dynamics 365 Early-Bound Generation Log
================================================================
Developer:    Albadry Esmat
Timestamp:    $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Environment:  $($config.dataverseUrl)
Namespace:    $($config.namespace)
Output Dir:   $outputDir

================================================================
Configuration Filters:
================================================================
Entities ($($config.filters.entities.Count)):
$(($config.filters.entities | ForEach-Object { "  - $_" }) -join "`n")

Actions ($($config.filters.actions.Count)):
$(($config.filters.actions | ForEach-Object { "  - $_" }) -join "`n")

OptionSets ($($config.filters.optionSets.Count)):
$(if ($config.filters.optionSets.Count -gt 0) { ($config.filters.optionSets | ForEach-Object { "  - $_" }) -join "`n" } else { "  (disabled)" })

================================================================
PAC CLI Output:
================================================================

"@

$logHeader | Out-File -FilePath $logFile -Encoding UTF8
Write-OK "Log file initialized"
#endregion

#region Build PAC arguments
$pacArgs = @(
    'modelbuilder', 'build',
    '--environment', $config.dataverseUrl,
    '--namespace', $config.namespace,
    '--serviceContextName', $config.serviceContextName,
    '--outdirectory', $outputDir
)

if ($entitiesFilter) {
    $pacArgs += '--entitynamesfilter'
    $pacArgs += $entitiesFilter
}

if ($actionsFilter) {
    $pacArgs += '--messagenamesfilter'
    $pacArgs += $actionsFilter
}

if ($includeOptionSets) {
    $pacArgs += '--generateGlobalOptionSets'
}
#endregion

#region Run PAC generator
Write-Section "Generating Early-Bound Classes"

Write-Info "Starting PAC modelbuilder..."
Write-Host "  This typically takes 30-60 seconds depending on the number of entities" -ForegroundColor Gray
Write-Host ""

$script:startTime = Get-Date

$pacOutput = & pac @pacArgs 2>&1
$pacOutput | Out-File -Append -FilePath $logFile -Encoding UTF8

$script:endTime = Get-Date
$script:duration = ($script:endTime - $script:startTime).TotalSeconds

if ($LASTEXITCODE -ne 0) {
    Write-Err "PAC CLI generation failed!"
    Write-Host ""
    Write-Host "  Albadry, check the log file for details:" -ForegroundColor Yellow
    Write-Host "  $logFile" -ForegroundColor Gray
    Write-Host ""
    exit 1
}

Write-OK "PAC generation completed in $([math]::Round($script:duration, 1)) seconds"
#endregion

#region Filter OptionSets (delete unwanted ones)
if ($includeOptionSets -and $optionSetsToKeep.Count -gt 0) {
    Write-Section "Filtering OptionSets"

    $optionSetsFolder = Join-Path $outputDir "OptionSets"

    if (Test-Path $optionSetsFolder) {
        Write-Info "Applying Albadry's OptionSet filter..."

        $allOptionSets = Get-ChildItem $optionSetsFolder -Filter "*.cs"
        $totalGenerated = $allOptionSets.Count
        $deleted = 0
        $deletedNames = @()

        foreach ($file in $allOptionSets) {
            # Extract optionset name from filename (remove .cs extension)
            $optionSetName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)

            # Check if this optionset should be kept
            if ($optionSetsToKeep -notcontains $optionSetName) {
                Remove-Item $file.FullName -Force
                $deletedNames += $optionSetName
                $deleted++
            }
        }

        $kept = $totalGenerated - $deleted
        Write-OK "Filtered: kept $kept of $totalGenerated optionsets (deleted $deleted)"
        Write-Host "  Kept OptionSets:" -ForegroundColor Green
        foreach ($name in $optionSetsToKeep) {
            Write-Host "    - $name" -ForegroundColor Gray
        }

        # Log the filtering with detailed information
        $filterLog = @"

================================================================
Albadry's OptionSet Post-Processing Filter
================================================================
Total Generated by PAC CLI:  $totalGenerated
Filtered (kept):             $kept
Deleted (not in filter):     $deleted

Kept OptionSets:
$(($optionSetsToKeep | ForEach-Object { "  + $_" }) -join "`n")

Deleted OptionSets (first 10):
$(($deletedNames | Select-Object -First 10 | ForEach-Object { "  - $_" }) -join "`n")
$(if ($deletedNames.Count -gt 10) { "  ... and $($deletedNames.Count - 10) more" } else { "" })

================================================================
"@
        $filterLog | Add-Content -Path $logFile
    }
}
#endregion

#region Fix PAC CLI Bugs (Response classes)
Write-Section "Fixing Known PAC CLI Bugs"

$messagesFolder = Join-Path $outputDir "Messages"

if (Test-Path $messagesFolder) {
    Write-Info "Scanning for Response class bugs..."

    $messageFiles = Get-ChildItem $messagesFolder -Filter "*.cs"
    $fixedCount = 0
    $fixedFiles = @()

    foreach ($file in $messageFiles) {
        $content = Get-Content $file.FullName -Raw
        $originalContent = $content
        $fileFixed = $false

        # Split content into lines for analysis
        $lines = $content -split "`r?`n"
        $inResponseClass = $false
        $inGetter = $false
        $inSetter = $false
        $propertyName = ""
        $getterUsesResults = $false

        for ($i = 0; $i -lt $lines.Count; $i++) {
            $line = $lines[$i]

            # Detect Response class
            if ($line -match 'class\s+(\w+)Response\s*:\s*Microsoft\.Xrm\.Sdk\.OrganizationResponse') {
                $inResponseClass = $true
            }

            # Detect property start
            if ($inResponseClass -and $line -match '^\s+public\s+(\S+)\s+(\w+)\s*$') {
                $propertyName = $matches[2]
                $getterUsesResults = $false
            }

            # Detect getter block
            if ($inResponseClass -and $line -match '^\s+get\s*$') {
                $inGetter = $true
                $inSetter = $false
            }

            # Detect setter block
            if ($inResponseClass -and $line -match '^\s+set\s*$') {
                $inSetter = $true
                $inGetter = $false
            }

            # Check if getter uses Results
            if ($inGetter -and $line -match 'this\.Results\.Contains') {
                $getterUsesResults = $true
            }

            # Fix setter if it incorrectly uses Parameters
            if ($inSetter -and $getterUsesResults -and $line -match '^\s+this\.Parameters\[') {
                $lines[$i] = $line -replace 'this\.Parameters\[', 'this.Results['
                $fileFixed = $true
            }

            # End of getter or setter
            if (($inGetter -or $inSetter) -and $line -match '^\s+\}$') {
                $inGetter = $false
                $inSetter = $false
            }

            # Reset when class ends
            if ($line -match '^\}$' -and $inResponseClass) {
                $inResponseClass = $false
            }
        }

        # Save file if fixed
        if ($fileFixed) {
            $newContent = $lines -join "`r`n"
            Set-Content -Path $file.FullName -Value $newContent -NoNewline -Encoding UTF8
            $fixedCount++
            $fixedFiles += $file.Name
            Write-Host "    Fixed: $($file.Name)" -ForegroundColor Green
        }
    }

    if ($fixedCount -gt 0) {
        Write-OK "Fixed Response class bugs in $fixedCount files"

        # Log the bug fixes
        $bugFixLog = @"

================================================================
Albadry's PAC CLI Bug Fixes
================================================================
Bug: Response class setters incorrectly use 'Parameters' instead of 'Results'
PAC CLI Version: 2.0.0.16
Fixed Files: $fixedCount

Files Fixed:
$(($fixedFiles | ForEach-Object { "  + $_" }) -join "`n")

Fix Applied:
  BEFORE: set { this.Parameters["PropertyName"] = value; }
  AFTER:  set { this.Results["PropertyName"] = value; }

================================================================
"@
        $bugFixLog | Add-Content -Path $logFile
    } else {
        Write-OK "No Response class bugs found (all clean!)"
    }
} else {
    Write-Info "No Messages folder found - skipping bug fixes"
}
#endregion

#region Compute hash of generated files
function Get-FolderHash($path) {
    # Normalize path
    $path = $path.TrimEnd('\')

    $files = Get-ChildItem -Path $path -File -Recurse -ErrorAction SilentlyContinue | Sort-Object FullName
    if ($files.Count -eq 0) { return $null }

    $hashString = ""
    foreach ($file in $files) {
        try {
            $fullPath = $file.FullName
            if ($fullPath.StartsWith($path)) {
                $relative = $fullPath.Substring($path.Length).TrimStart('\')
                $fileHash = (Get-FileHash $file.FullName -Algorithm MD5).Hash
                $hashString += "$relative|$fileHash`n"
            }
        }
        catch {
            Write-Warn "Skipping file in hash: $($file.FullName)"
        }
    }

    if ([string]::IsNullOrEmpty($hashString)) { return $null }
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($hashString)
    $md5 = [System.Security.Cryptography.MD5]::Create()
    $hashBytes = $md5.ComputeHash($bytes)
    return [BitConverter]::ToString($hashBytes) -replace '-', ''
}

$currentHash = Get-FolderHash $outputDir
#endregion

#region Compare with previous hash and update metadata
$changed = $true
if ($previousHash -and $previousHash -eq $currentHash) {
    $changed = $false
    Write-Info "No changes detected in generated files."
} else {
    Write-OK "Changes detected - generated files updated."
}

# Save new metadata
$metadata = @{
    folderHash    = $currentHash
    generatedAt   = (Get-Date -Format "o")
    filters       = @{
        entities   = $config.filters.entities
        actions    = $config.filters.actions
        optionSets = $config.filters.optionSets
    }
}
$metadata | ConvertTo-Json -Depth 5 | Set-Content -Path $metadataFile -Encoding UTF8
Write-OK "Metadata saved to $metadataFile"
#endregion

#region Final summary
Write-Header "Generation Complete - Summary"

# Count generated files
$entityFiles = Get-ChildItem "$outputDir\Entities" -Filter "*.cs" -ErrorAction SilentlyContinue
$messageFiles = Get-ChildItem "$outputDir\Messages" -Filter "*.cs" -ErrorAction SilentlyContinue
$optionsetFiles = Get-ChildItem "$outputDir\OptionSets" -Filter "*.cs" -ErrorAction SilentlyContinue
$contextFile = Get-ChildItem "$outputDir\CrmServiceContext.cs" -ErrorAction SilentlyContinue
$enumFile = Get-ChildItem "$outputDir\EntityOptionSetEnum.cs" -ErrorAction SilentlyContinue

Write-Host "  Albadry, your early-bound classes are ready!" -ForegroundColor Green
Write-Host ""
Write-Host "  [Generation Statistics]" -ForegroundColor Cyan
Write-Host "    - Entities:     $($entityFiles.Count) files" -ForegroundColor White
Write-Host "    - Messages:     $($messageFiles.Count) files" -ForegroundColor White
Write-Host "    - OptionSets:   $($optionsetFiles.Count) files" -ForegroundColor White
if ($contextFile) {
    Write-Host "    - Context:      1 file (CrmServiceContext.cs)" -ForegroundColor White
} else {
    Write-Host "    - Context:      0 files" -ForegroundColor White
}
if ($enumFile) {
    Write-Host "    - Enums:        1 file (EntityOptionSetEnum.cs)" -ForegroundColor White
} else {
    Write-Host "    - Enums:        0 files" -ForegroundColor White
}
Write-Host ""

if ($entityFiles.Count -gt 0) {
    Write-Host "  [Entity Classes]" -ForegroundColor Cyan
    foreach ($file in $entityFiles | Sort-Object Name) {
        Write-Host "    + $($file.BaseName)" -ForegroundColor Gray
    }
    Write-Host ""
}

if ($messageFiles.Count -gt 0) {
    Write-Host "  [Message/Action Classes]" -ForegroundColor Cyan
    foreach ($file in $messageFiles | Sort-Object Name) {
        Write-Host "    + $($file.BaseName)" -ForegroundColor Gray
    }
    Write-Host ""
}

if ($optionsetFiles.Count -gt 0) {
    Write-Host "  [OptionSet Classes]" -ForegroundColor Cyan
    foreach ($file in $optionsetFiles | Sort-Object Name) {
        Write-Host "    + $($file.BaseName)" -ForegroundColor Gray
    }
    Write-Host ""
}

Write-Host "  [Output Location]" -ForegroundColor Cyan
Write-Host "    $outputDir" -ForegroundColor Gray
Write-Host ""

Write-Host "  [Detailed Log]" -ForegroundColor Cyan
Write-Host "    $logFile" -ForegroundColor Gray
Write-Host ""

if (-not $changed) {
    Write-Info "Note: No changes detected since last run (folder hash unchanged)."
    Write-Host "  The generated files are identical to the previous generation." -ForegroundColor Gray
    Write-Host ""
}

# Add final summary to log
$totalFiles = $entityFiles.Count + $messageFiles.Count + $optionsetFiles.Count
if ($contextFile) { $totalFiles++ }
if ($enumFile) { $totalFiles++ }

$logSummary = "`n"
$logSummary += "================================================================`n"
$logSummary += "Albadry Esmat - Generation Summary`n"
$logSummary += "================================================================`n"
$completionTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$logSummary += "Completion Time:   $completionTime`n"
$logSummary += "Total Duration:    $([math]::Round($script:duration, 1)) seconds`n"
$logSummary += "`n"
$logSummary += "Files Generated:`n"
$logSummary += "  Entities:      $($entityFiles.Count) files`n"
$logSummary += "  Messages:      $($messageFiles.Count) files`n"
$logSummary += "  OptionSets:    $($optionsetFiles.Count) files`n"
if ($contextFile) {
    $logSummary += "  Context:       1 file`n"
} else {
    $logSummary += "  Context:       0 files`n"
}
if ($enumFile) {
    $logSummary += "  Enums:         1 file`n"
} else {
    $logSummary += "  Enums:         0 files`n"
}
$logSummary += "`n"
$logSummary += "Total Files:       $totalFiles`n"
$logSummary += "Output Directory:  $outputDir`n"
if ($changed) {
    $logSummary += "Changes Detected:  Yes`n"
} else {
    $logSummary += "Changes Detected:  No (identical to previous)`n"
}
$logSummary += "`n"
$logSummary += "================================================================`n"
$logSummary += "Status: SUCCESS`n"
$logSummary += "================================================================`n"
$logSummary += "Generated by Albadry Esmat - EarlyBound Generator v2.0`n"
$logSummary += "================================================================`n"

$logSummary | Add-Content -Path $logFile

Write-OK "All done! Happy coding, Albadry! 🚀"
Write-Host ""
#endregion
