param(
    [string]$Bucket,
    [string]$DistributionId
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

if (-not $Bucket) {
    $Bucket = terraform -chdir=terraform output -raw frontend_bucket_name
}

if (-not $DistributionId) {
    $DistributionId = terraform -chdir=terraform output -raw cloudfront_distribution_id
}

if (-not $Bucket -or -not $DistributionId) {
    throw "No se pudieron obtener el bucket o la distribucion. Ejecuta terraform apply primero."
}

Write-Host "Subiendo frontend a s3://$Bucket ..."
aws s3 sync app/frontend "s3://$Bucket" --delete

Write-Host "Invalidando CloudFront ($DistributionId) ..."
aws cloudfront create-invalidation --distribution-id $DistributionId --paths "/*"

Write-Host "Listo."
