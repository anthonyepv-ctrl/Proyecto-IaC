#Requires -Version 7
$ErrorActionPreference = "Stop"

$root    = Split-Path -Parent $PSScriptRoot
$backend = Join-Path $root "app/backend"
$build   = Join-Path $root "build"
$functions = @("disponibilidad", "registrar", "expandir", "db_init")

if (Test-Path $build) { Remove-Item $build -Recurse -Force }
New-Item -ItemType Directory -Path $build | Out-Null

foreach ($fn in $functions) {
    $src = Join-Path $backend $fn
    if (-not (Test-Path $src)) { throw "No existe la carpeta $src" }

    $stage = Join-Path $build $fn
    New-Item -ItemType Directory -Path $stage | Out-Null

    $common = Join-Path $backend "common"
    if (Test-Path $common) { Copy-Item (Join-Path $common "*") $stage -Recurse }
    Copy-Item (Join-Path $src "*") $stage -Recurse -Force

    $req = Join-Path $src "requirements.txt"
    if (Test-Path $req) {
        python -m pip install -r $req --target $stage --quiet --no-compile
        if ($LASTEXITCODE -ne 0) { throw "pip fallo en $fn" }
    } else {
        Write-Warning "$fn no tiene requirements.txt"
    }

    $zip = Join-Path $build "$fn.zip"
    Compress-Archive -Path (Join-Path $stage "*") -DestinationPath $zip -Force
    Remove-Item $stage -Recurse -Force
    Write-Host "OK  $zip"
}