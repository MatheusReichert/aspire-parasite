function Get-Label($filename) {
    $name = [System.IO.Path]::GetFileNameWithoutExtension($filename)
    if ($name -eq "apphost") { return "All services" }
    $suffix = $name -replace "^apphost-", ""
    return ($suffix.ToCharArray() | ForEach-Object { $_.ToString().ToUpper() }) -join " + "
}

$configs = Get-ChildItem -Path $PSScriptRoot -Filter "apphost*.cs" |
    Sort-Object Name |
    ForEach-Object { @{ Label = Get-Label $_.Name; File = $_.Name } }

Write-Host ""
Write-Host "  Aspire Parasite - Orchestration Selector" -ForegroundColor Cyan
Write-Host "  =========================================" -ForegroundColor Cyan
Write-Host ""

for ($i = 0; $i -lt $configs.Count; $i++) {
    Write-Host "  [$($i + 1)] $($configs[$i].Label)" -ForegroundColor White
}

Write-Host ""
Write-Host "  [Q] Quit" -ForegroundColor DarkGray
Write-Host ""

$choice = Read-Host "  Select"

if ($choice -match '^[Qq]$') {
    Write-Host ""
    Write-Host "  Bye." -ForegroundColor DarkGray
    exit 0
}

$index = $choice -as [int]

if ($null -eq $index -or $index -lt 1 -or $index -gt $configs.Count) {
    Write-Host ""
    Write-Host "  Invalid option." -ForegroundColor Red
    exit 1
}

$selected = $configs[$index - 1]

Write-Host ""
Write-Host "  Starting: $($selected.Label)" -ForegroundColor Green
Write-Host "  File    : $($selected.File)" -ForegroundColor DarkGray
Write-Host ""

dotnet run $selected.File
