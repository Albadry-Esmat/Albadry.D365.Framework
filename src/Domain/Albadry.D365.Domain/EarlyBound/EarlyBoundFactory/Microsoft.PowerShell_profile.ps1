function albadry {

    param(
        [Parameter(Position=0)]
        [string]$Command,

        [Parameter(Position=1)]
        [string]$Target,

        [switch]$Preview,
        [string[]]$Entities,
        [string[]]$Actions,
        [string[]]$OptionSets
    )

    if ($Command -ne "g" -or $Target -ne "earlybound") {
        Show-AlbadryHelp
        return
    }

    $root = Get-AlbadryRoot
    if (-not $root) {
        Write-Host "Albadry project root not found." -ForegroundColor Red
        return
    }

    $script = Join-Path $root "src\Domain\Albadry.D365.Domain\EarlyBound\EarlyBoundFactory\earlybound.ps1"

    if (-not (Test-Path $script)) {
        Write-Host "EarlyBound generator not found." -ForegroundColor Red
        return
    }

    Write-Host "Running EarlyBound generator..." -ForegroundColor Cyan
    Write-Host "Root: $root" -ForegroundColor Gray

    $params = @{}
    if ($Preview) { $params.Preview = $true }
    if ($Entities) { $params.Entities = $Entities }
    if ($Actions) { $params.Actions = $Actions }
    if ($OptionSets) { $params.OptionSets = $OptionSets }

    & $script @params
}

function Get-AlbadryRoot {

    $dir = Get-Location

    while ($dir) {

        $marker = Join-Path $dir "src\Domain\Albadry.D365.Domain\EarlyBound\EarlyBoundFactory"

        if (Test-Path $marker) {
            return $dir.Path
        }

        $dir = $dir.Parent
    }

    return $null
}

function Show-AlbadryHelp {

    Write-Host ""
    Write-Host "Albadry CLI" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Commands:" -ForegroundColor Yellow
    Write-Host "  albadry g earlybound" -ForegroundColor White
    Write-Host ""
    Write-Host "Options:" -ForegroundColor Yellow
    Write-Host "  -Preview"
    Write-Host "  -Entities account,contact"
    Write-Host "  -Actions new_Action"
    Write-Host "  -OptionSets account_category"
    Write-Host ""
}

Write-Host ""
Write-Host "Albadry CLI loaded" -ForegroundColor Cyan
Write-Host "Run: albadry g earlybound" -ForegroundColor Gray
Write-Host ""