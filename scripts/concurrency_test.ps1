
param(
    [Parameter(Mandatory = $true)]
    [string]$BaseUrl,

    [int]$SedeId = 1
)

$ErrorActionPreference = "Stop"
$BaseUrl = $BaseUrl.TrimEnd("/")

# Usar un horario futuro para las reservas de prueba.
$inicio = [DateTime]::UtcNow.AddDays(4)
$fin = $inicio.AddHours(1)

$inicioTexto = $inicio.ToString("yyyy-MM-ddTHH:mm:ssZ")
$finTexto = $fin.ToString("yyyy-MM-ddTHH:mm:ssZ")

# Consultar la disponibilidad inicial.
$consulta = "$BaseUrl/api/disponibilidad?sede_id=$SedeId&inicio=$([uri]::EscapeDataString($inicioTexto))&fin=$([uri]::EscapeDataString($finTexto))"

try {
    $inicial = Invoke-RestMethod -Uri $consulta -Method Get
    $disponiblesIniciales = [int]$inicial.disponibles
}
catch {
    Write-Host "No se pudo consultar la disponibilidad: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "Disponibles al inicio: $disponiblesIniciales"
Write-Host "Enviando 50 solicitudes simultáneas..."

# Enviar las solicitudes en trabajos separados.
$trabajos = for ($i = 1; $i -le 50; $i++) {
    Start-Job -ArgumentList @(
        $BaseUrl,
        $SedeId,
        $inicioTexto,
        $finTexto,
        $i
    ) -ScriptBlock {
        param($url, $sede, $inicio, $fin, $numero)

        $cuerpo = @{
            sede_id = $sede
            placa   = "CONC$numero"
            inicio  = $inicio
            fin     = $fin
        } | ConvertTo-Json -Compress

        try {
            $respuesta = Invoke-RestMethod `
                -Uri "$url/api/reservas" `
                -Method Post `
                -ContentType "application/json" `
                -Body $cuerpo

            [pscustomobject]@{
                Estado = 201
                Mensaje = "Aceptada"
            }
        }
        catch {
            $codigo = 0

            if ($_.Exception.Response) {
                try {
                    $codigo = [int]$_.Exception.Response.StatusCode
                }
                catch {}
            }

            [pscustomobject]@{
                Estado = $codigo
                Mensaje = $_.Exception.Message
            }
        }
    }
}

# Esperar a que terminen todas las solicitudes.
Wait-Job -Job $trabajos | Out-Null
$resultados = @(
    foreach ($trabajo in $trabajos) {
        Receive-Job -Job $trabajo
    }
)
Remove-Job -Job $trabajos -Force

$aceptadas = @($resultados | Where-Object { $_.Estado -eq 201 }).Count
$conflictos = @($resultados | Where-Object { $_.Estado -eq 409 }).Count
$errores = @($resultados | Where-Object { $_.Estado -ne 201 -and $_.Estado -ne 409 }).Count

Write-Host "`n=== RESULTADOS ===" -ForegroundColor Cyan
Write-Host "Solicitudes enviadas: 50"
Write-Host "Reservas aceptadas: $aceptadas"
Write-Host "Conflictos de capacidad: $conflictos"
Write-Host "Otros errores: $errores"

if ($aceptadas -gt $disponiblesIniciales) {
    Write-Host "FALLO: se aceptaron más reservas que espacios iniciales." -ForegroundColor Red
    exit 1
}

if ($errores -gt 0) {
    Write-Host "REVISAR: algunas solicitudes fallaron por motivos distintos a la capacidad." -ForegroundColor Yellow
    exit 1
}

Write-Host "OK: las reservas aceptadas no superaron la disponibilidad inicial." -ForegroundColor Green
