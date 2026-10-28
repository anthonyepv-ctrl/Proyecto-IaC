$ErrorActionPreference = "Stop"

$root    = Split-Path -Parent $PSScriptRoot
$backend = Join-Path $root "app/backend"
$build   = Join-Path $root "build"
$functions = @("disponibilidad", "registrar", "db_init")

if (Test-Path $build) { Remove-Item $build -Recurse -Force }
New-Item -ItemType Directory -Path $build | Out-Null

foreach ($fn in $functions) {
    $src = Join-Path $backend $fn
    if (-not (Test-Path $src)) { throw "No existe la carpeta $src" }

    $stage = Join-Path $build $fn
    New-Item -ItemType Directory -Path $stage | Out-Null

    $common = Join-Path $backend "common"
    if (Test-Path $common) {
        Copy-Item $common $stage -Recurse -Force
    }
    Copy-Item (Join-Path $src "*") $stage -Recurse -Force

    $req = Join-Path $src "requirements.txt"
    if (-not (Test-Path $req)) { $req = Join-Path $backend "requirements.txt" }
    if (Test-Path $req) {
        python -m pip install -r $req --target $stage --quiet --no-compile
        if ($LASTEXITCODE -ne 0) { throw "pip fallo en $fn" }
    } else {
        Write-Warning "$fn no tiene requirements.txt"
    }

    $zip = Join-Path $build "$fn.zip"
    python -c "import sys,os,zipfile; src,dst=sys.argv[1],sys.argv[2]; z=zipfile.ZipFile(dst,'w',zipfile.ZIP_DEFLATED); [z.write(os.path.join(r,f), os.path.relpath(os.path.join(r,f),src).replace(os.sep,'/')) for r,_,fs in os.walk(src) for f in fs]; z.close()" $stage $zip
    if ($LASTEXITCODE -ne 0) { throw "zip fallo en $fn" }
    Remove-Item $stage -Recurse -Force
    Write-Host "OK  $zip"
}