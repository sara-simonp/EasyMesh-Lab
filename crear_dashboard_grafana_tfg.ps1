$ErrorActionPreference = "Stop"

$grafanaUrl = "http://localhost:3001"
$user = "admin"
$pass = "admin"

$pair = "$user`:$pass"
$bytes = [System.Text.Encoding]::ASCII.GetBytes($pair)
$base64 = [Convert]::ToBase64String($bytes)

$headers = @{
    Authorization = "Basic $base64"
    "Content-Type" = "application/json"
}

Write-Host "Comprobando Grafana..."
Invoke-RestMethod -Uri "$grafanaUrl/api/health" -Headers $headers | Out-Null

Write-Host "Buscando datasource Prometheus..."
$datasources = Invoke-RestMethod -Uri "$grafanaUrl/api/datasources" -Headers $headers
$prom = $datasources | Where-Object { $_.type -eq "prometheus" } | Select-Object -First 1

if ($null -eq $prom) {
    throw "No se ha encontrado datasource Prometheus en Grafana."
}

$dsUid = $prom.uid

Write-Host "Datasource Prometheus encontrado:"
Write-Host "Nombre: $($prom.name)"
Write-Host "UID:    $dsUid"

$datasource = @{
    type = "prometheus"
    uid  = $dsUid
}

function New-Target($expr, $legend, $refId) {
    return @{
        expr          = $expr
        legendFormat  = $legend
        refId         = $refId
        datasource    = $datasource
    }
}

function New-StatPanel($id, $title, $expr, $x, $y, $w, $h, $unit, $legend) {
    return @{
        id          = $id
        title       = $title
        type        = "stat"
        datasource  = $datasource
        gridPos     = @{
            x = $x
            y = $y
            w = $w
            h = $h
        }
        targets     = @(
            New-Target $expr $legend "A"
        )
        fieldConfig = @{
            defaults = @{
                unit = $unit
            }
            overrides = @()
        }
        options = @{
            reduceOptions = @{
                values = $false
                calcs  = @("lastNotNull")
                fields = ""
            }
            orientation = "auto"
            textMode    = "auto"
            colorMode   = "value"
            graphMode   = "area"
            justifyMode = "auto"
        }
    }
}

function New-TimeSeriesPanel($id, $title, $expr, $x, $y, $w, $h, $unit, $legend) {
    return @{
        id          = $id
        title       = $title
        type        = "timeseries"
        datasource  = $datasource
        gridPos     = @{
            x = $x
            y = $y
            w = $w
            h = $h
        }
        targets     = @(
            New-Target $expr $legend "A"
        )
        fieldConfig = @{
            defaults = @{
                unit = $unit
                custom = @{
                    drawStyle = "line"
                    lineInterpolation = "linear"
                    lineWidth = 2
                    fillOpacity = 15
                    showPoints = "auto"
                    spanNulls = $false
                }
            }
            overrides = @()
        }
        options = @{
            legend = @{
                displayMode = "list"
                placement = "bottom"
                showLegend = $true
            }
            tooltip = @{
                mode = "single"
                sort = "none"
            }
        }
    }
}

function New-TablePanel($id, $title, $expr, $x, $y, $w, $h) {
    return @{
        id          = $id
        title       = $title
        type        = "table"
        datasource  = $datasource
        gridPos     = @{
            x = $x
            y = $y
            w = $w
            h = $h
        }
        targets     = @(
            New-Target $expr "{{type}} {{from_device}} -> {{to_device}} {{result}}" "A"
        )
        fieldConfig = @{
            defaults = @{}
            overrides = @()
        }
        options = @{
            showHeader = $true
        }
    }
}

$dashboard = @{
    uid           = "tfg-easymesh-final"
    title         = "TFG EasyMesh - Simulador final TR-181 TR-069 QoE"
    tags          = @("TFG", "EasyMesh", "TR-181", "TR-069", "GenieACS", "Prometheus")
    timezone      = "browser"
    schemaVersion = 39
    version       = 1
    refresh       = "5s"
    time          = @{
        from = "now-30m"
        to   = "now"
    }
    panels        = @(
        # Fila 1 - Estado general
        New-StatPanel 1 "Simulador EasyMesh activo" `
            "easymesh_simulator_up" `
            0 0 6 4 "none" "simulator"

        New-StatPanel 2 "GenieACS conectado" `
            "genieacs_up" `
            6 0 6 4 "none" "genieacs"

        New-StatPanel 3 "CSV de evidencias guardados" `
            "easymesh_csv_snapshots_total" `
            12 0 6 4 "none" "{{kind}}"

        New-StatPanel 4 "Steering acumulado" `
            "easymesh_sim_steering_count_total" `
            18 0 6 4 "none" "steering"

        # Fila 2 - Cliente principal
        New-TimeSeriesPanel 5 "RSSI MOVIL_SARA - simulador final" `
            'easymesh_sim_client_signal_dbm{client="MOVIL_SARA"}' `
            0 4 12 8 "dBm" "{{client}} - {{ap}}"

        New-TimeSeriesPanel 6 "QoE MOVIL_SARA - simulador final" `
            'easymesh_sim_client_qoe_score{client="MOVIL_SARA"}' `
            12 4 12 8 "none" "{{client}} - {{ap}} - {{state}}"

        # Fila 3 - Latencia, jitter, pérdida
        New-TimeSeriesPanel 7 "Latencia MOVIL_SARA" `
            'easymesh_sim_client_latency_ms{client="MOVIL_SARA"}' `
            0 12 8 7 "ms" "{{client}} - {{ap}}"

        New-TimeSeriesPanel 8 "Jitter MOVIL_SARA" `
            'easymesh_sim_client_jitter_ms{client="MOVIL_SARA"}' `
            8 12 8 7 "ms" "{{client}} - {{ap}}"

        New-TimeSeriesPanel 9 "Pérdida de paquetes MOVIL_SARA" `
            'easymesh_sim_client_packet_loss_percent{client="MOVIL_SARA"}' `
            16 12 8 7 "percent" "{{client}} - {{ap}}"

        # Fila 4 - Radio y backhaul
        New-TimeSeriesPanel 10 "Utilización radio por AP" `
            "easymesh_sim_radio_utilization_percent" `
            0 19 12 8 "percent" "{{ap}} - {{radio}} - {{band}}"

        New-TimeSeriesPanel 11 "Ruido radio por AP" `
            "easymesh_sim_radio_noise_dbm" `
            12 19 12 8 "dBm" "{{ap}} - {{radio}} - {{band}}"

        New-TimeSeriesPanel 12 "RSSI backhaul EasyMesh" `
            "easymesh_sim_backhaul_rssi_dbm" `
            0 27 12 8 "dBm" "{{ap}} - {{type}}"

        New-TimeSeriesPanel 13 "Latencia backhaul EasyMesh" `
            "easymesh_sim_backhaul_latency_ms" `
            12 27 12 8 "ms" "{{ap}} - {{type}}"

        # Fila 5 - Eventos
        New-TablePanel 14 "Evento EasyMesh actual" `
            "easymesh_sim_event_info" `
            0 35 24 7

        # Fila 6 - CSV TR-181
        New-TimeSeriesPanel 15 "QoE desde CSV TR-181" `
            'easymesh_csv_tr181_numeric_value{parameter="Device.X_SARA_QoE.QoEScore"}' `
            0 42 12 8 "none" "{{scenario}} - {{parameter}}"

        New-TimeSeriesPanel 16 "RSSI desde CSV TR-181" `
            'easymesh_csv_tr181_numeric_value{parameter="Device.X_SARA_QoE.SignalStrength"}' `
            12 42 12 8 "dBm" "{{scenario}} - {{parameter}}"

        New-TimeSeriesPanel 17 "Latencia desde CSV TR-181" `
            'easymesh_csv_tr181_numeric_value{parameter="Device.X_SARA_QoE.LatencyMs"}' `
            0 50 8 7 "ms" "{{scenario}}"

        New-TimeSeriesPanel 18 "Pérdida desde CSV TR-181" `
            'easymesh_csv_tr181_numeric_value{parameter="Device.X_SARA_QoE.PacketLossPercent"}' `
            8 50 8 7 "percent" "{{scenario}}"

        New-TablePanel 19 "Eventos desde CSV TR-181" `
            'easymesh_csv_tr181_info{parameter=~".*Event.*"}' `
            16 50 8 7

        # Fila 7 - GenieACS / TR-069
        New-TimeSeriesPanel 20 "RSSI vía GenieACS / TR-069" `
            "easymesh_client_signal_strength_dbm" `
            0 57 12 8 "dBm" "{{client}} - {{ap}}"

        New-TimeSeriesPanel 21 "Utilización radio vía GenieACS" `
            "easymesh_radio_utilization_avg_percent" `
            12 57 12 8 "percent" "{{ap}}"

        New-StatPanel 22 "Agentes EasyMesh vía GenieACS" `
            "easymesh_agent_number" `
            0 65 8 4 "none" "agents"

        New-StatPanel 23 "Clientes WiFi vía GenieACS" `
            "easymesh_total_client_number" `
            8 65 8 4 "none" "clients"

        New-TimeSeriesPanel 24 "Backhaul vía GenieACS" `
            "easymesh_backhaul_rssi_dbm" `
            16 65 8 4 "dBm" "{{ap}} - {{backhaul_type}}"
    )
}

$payload = @{
    dashboard = $dashboard
    overwrite = $true
    message   = "Dashboard TFG EasyMesh final creado desde PowerShell"
}

$json = $payload | ConvertTo-Json -Depth 100

$outFile = "C:\EasyMesh-Lab\monitoring\grafana\dashboards\tfg_easymesh_dashboard_final.json"

[System.IO.File]::WriteAllText(
    $outFile,
    $json,
    [System.Text.UTF8Encoding]::new($false)
)

Write-Host "Dashboard JSON guardado en:"
Write-Host $outFile

Write-Host "Importando dashboard en Grafana..."

$response = Invoke-RestMethod `
    -Method Post `
    -Uri "$grafanaUrl/api/dashboards/db" `
    -Headers $headers `
    -Body $json

Write-Host ""
Write-Host "Dashboard creado correctamente."
Write-Host "URL:"
Write-Host "$grafanaUrl$($response.url)"
