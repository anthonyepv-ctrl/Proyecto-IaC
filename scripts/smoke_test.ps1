param(
    [Parameter(Mandatory = $true)]
    [string]$BaseUrl
)

$ErrorActionPreference = "Stop"
$BaseUrl = $BaseUrl.TrimEnd("/")

$inicio = [DateTime]::UtcNow.AddDays(2)
$fin = $inicio.AddHours(1)

$inicioTexto = $inicio.ToString("yyyy-MM-ddTHH:mm:ssZ")
$finTexto = $fin.ToString("yyyy-MM-ddTHH:mm:ssZ")

Write-Host "`n=== PRUEBAS DEL BACKEND ===" -ForegroundColor Cyan

# 1. Consultar las sedes
try {
    $sedesRespuesta = Invoke-RestMethod `
        -Uri "$BaseUrl/api/sedes" `
        -Method Get

    if (-not $sedesRespuesta.sedes -or $sedesRespuesta.sedes.Count -eq 0) {
        throw "La respuesta no contiene sedes."
    }

    Write-Host "[OK] GET /api/sedes" -ForegroundColor Green
    $sedeId = $sedesRespuesta.sedes[0].id
}
catch {
    Write-Host "[ERROR] GET /api/sedes : $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# 2. Consultar disponibilidad
try {
    $consulta = "$BaseUrl/api/disponibilidad?sede_id=$sedeId&inicio=$([uri]::EscapeDataString($inicioTexto))&fin=$([uri]::EscapeDataString($finTexto))"

    $disponibilidad = Invoke-RestMethod -Uri $consulta -Method Get

    if ($null -eq $disponibilidad.disponibles -or $disponibilidad.disponibles -lt 0) {
        throw "La respuesta de disponibilidad no es válida."
    }

    Write-Host "[OK] GET /api/disponibilidad" -ForegroundColor Green
    Write-Host "Espacios disponibles: $($disponibilidad.disponibles)"
}
catch {
    Write-Host "[ERROR] GET /api/disponibilidad : $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# 3. Registrar una reserva de prueba
if ($disponibilidad.disponibles -le 0) {
    Write-Host "[ERROR] No hay espacios disponibles para probar el registro." -ForegroundColor Red
    exit 1
}

try {
    $placa = "TST" + (Get-Date -Format "MMddHHmmss")

    $cuerpo = @{
        sede_id = $sedeId
        placa   = $placa
        inicio  = $inicioTexto
        fin     = $finTexto
    } | ConvertTo-Json

    $reserva = Invoke-RestMethod `
        -Uri "$BaseUrl/api/reservas" `
        -Method Post `
        -ContentType "application/json" `
        -Body $cuerpo

    if (-not $reserva.id) {
        throw "La respuesta no contiene el ID de la reserva."
    }

    Write-Host "[OK] POST /api/reservas" -ForegroundColor Green
    Write-Host "Reserva de prueba creada con ID: $($reserva.id)"
}
catch {
    Write-Host "[ERROR] POST /api/reservas : $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "`nPruebas completadas correctamente." -ForegroundColor Green