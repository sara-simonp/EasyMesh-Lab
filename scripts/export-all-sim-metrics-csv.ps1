param(
    [string]$Scenario = "current",
    [int]$DurationMinutes = 1,
    [int]$IntervalSeconds = 10,
    [string]$OutDir = "C:\EasyMesh-Lab\tfg-resultados\simulador\csv"
)

$ErrorActionPreference = "Stop"

$BaseUrl = "http://localhost:9200"

function Get-Unit {
    param([string]$MetricName)

    if ($MetricName -match "rssi|signal|noise") { return "dBm" }
    if ($MetricName -match "snr") { return "dB" }
    if ($MetricName -match "latency|jitter") { return "ms" }
    if ($MetricName -match "percent|usage|utilization|loss|retry") { return "%" }
    if ($MetricName -match "rate|throughput") { return "Mbps" }
    if ($MetricName -match "bytes") { return "bytes" }
    if ($MetricName -match "packets") { return "packets" }
    if ($MetricName -match "memory") { return "MB" }
    if ($MetricName -match "channel|entries|number|count|score|mcs") { return "count" }

    return ""
}

function Add-Metric {
    param(
        [System.Collections.ArrayList]$Rows,
        [string]$RunId,
        [int]$Sample,
        [string]$TimestampLocal,
        [string]$TimestampUtc,
        [string]$Scenario,
        [string]$EntityType,
        [string]$EntityName,
        [string]$MetricGroup,
        [string]$MetricName,
        $MetricValue,
        [string]$Tr181Path,
        [string]$ExtraLabels = ""
    )

    if ($null -eq $MetricValue) {
        return
    }

    [void]$Rows.Add([PSCustomObject]@{
        run_id          = $RunId
        sample          = $Sample
        timestamp_local = $TimestampLocal
        timestamp_utc   = $TimestampUtc
        scenario        = $Scenario
        entity_type     = $EntityType
        entity_name     = $EntityName
        metric_group    = $MetricGroup
        metric_name     = $MetricName
        metric_value    = $MetricValue
        unit            = Get-Unit $MetricName
        tr181_path      = $Tr181Path
        labels          = $ExtraLabels
    })
}

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

if ($Scenario -ne "current") {
    Write-Host "Cambiando escenario a: $Scenario"
    $encodedScenario = [uri]::EscapeDataString($Scenario)
    Invoke-WebRequest -Uri "$BaseUrl/set?scenario=$encodedScenario" -UseBasicParsing | Out-Null
    Start-Sleep -Seconds 5
}

$firstState = Invoke-RestMethod -Uri "$BaseUrl/state" -TimeoutSec 10

if ($Scenario -eq "current") {
    $Scenario = $firstState.scenario
}

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$RunId = "${timestamp}_${Scenario}"
$OutCsv = Join-Path $OutDir "metricas_completas_${RunId}.csv"

$totalSamples = [math]::Max(1, [math]::Ceiling(($DurationMinutes * 60) / $IntervalSeconds))

$rows = New-Object System.Collections.ArrayList

Write-Host "Guardando TODAS las metricas del simulador"
Write-Host "Escenario: $Scenario"
Write-Host "Duracion: $DurationMinutes minutos"
Write-Host "Intervalo: $IntervalSeconds segundos"
Write-Host "Muestras: $totalSamples"
Write-Host "CSV salida: $OutCsv"

for ($i = 1; $i -le $totalSamples; $i++) {

    $sampleTime = Get-Date
    $timestampLocal = $sampleTime.ToString("yyyy-MM-dd HH:mm:ss")

    Write-Host "Muestra $i / $totalSamples - $timestampLocal"

    $state = Invoke-RestMethod -Uri "$BaseUrl/state" -TimeoutSec 10

    $timestampUtc = $state.timestamp_utc
    $scenarioName = $state.scenario

    # =========================
    # CONTROLLER
    # =========================

    Add-Metric $rows $RunId $i $timestampLocal $timestampUtc $scenarioName "controller" "GW_MASTER" "controller" "status" $state.controller.status "Device.WiFi.DataElements.Network.Controller.Status"
    Add-Metric $rows $RunId $i $timestampLocal $timestampUtc $scenarioName "controller" "GW_MASTER" "controller" "agent_number" $state.controller.agent_number "Device.WiFi.DataElements.Network.Controller.AgentNumber"
    Add-Metric $rows $RunId $i $timestampLocal $timestampUtc $scenarioName "controller" "GW_MASTER" "controller" "total_client_number" $state.controller.total_client_number "Device.WiFi.DataElements.Network.Controller.TotalClientNumber"
    Add-Metric $rows $RunId $i $timestampLocal $timestampUtc $scenarioName "controller" "GW_MASTER" "controller" "almac" $state.controller.almac "Device.WiFi.DataElements.Network.Controller.ID"
    Add-Metric $rows $RunId $i $timestampLocal $timestampUtc $scenarioName "controller" "GW_MASTER" "controller" "ipv4" $state.controller.ipv4 "Device.WiFi.DataElements.Network.Controller.IPv4Address"

    # =========================
    # DEVICE INFO
    # =========================

    Add-Metric $rows $RunId $i $timestampLocal $timestampUtc $scenarioName "device" $state.device_id "device_info" "manufacturer" $state.device_info.manufacturer "Device.DeviceInfo.Manufacturer"
    Add-Metric $rows $RunId $i $timestampLocal $timestampUtc $scenarioName "device" $state.device_id "device_info" "manufacturer_oui" $state.device_info.manufacturer_oui "Device.DeviceInfo.ManufacturerOUI"
    Add-Metric $rows $RunId $i $timestampLocal $timestampUtc $scenarioName "device" $state.device_id "device_info" "product_class" $state.device_info.product_class "Device.DeviceInfo.ProductClass"
    Add-Metric $rows $RunId $i $timestampLocal $timestampUtc $scenarioName "device" $state.device_id "device_info" "serial_number" $state.device_info.serial_number "Device.DeviceInfo.SerialNumber"
    Add-Metric $rows $RunId $i $timestampLocal $timestampUtc $scenarioName "device" $state.device_id "device_info" "software_version" $state.device_info.software_version "Device.DeviceInfo.SoftwareVersion"
    Add-Metric $rows $RunId $i $timestampLocal $timestampUtc $scenarioName "device" $state.device_id "device_info" "cpu_usage_percent" $state.device_info.cpu_usage_percent "Device.DeviceInfo.X_SARA_CPUUsage"
    Add-Metric $rows $RunId $i $timestampLocal $timestampUtc $scenarioName "device" $state.device_id "device_info" "memory_total_mb" $state.device_info.memory_total_mb "Device.DeviceInfo.MemoryStatus.Total"
    Add-Metric $rows $RunId $i $timestampLocal $timestampUtc $scenarioName "device" $state.device_id "device_info" "memory_free_mb" $state.device_info.memory_free_mb "Device.DeviceInfo.MemoryStatus.Free"

    # =========================
    # APS, RADIOS Y CLIENTES
    # =========================

    foreach ($apProp in $state.aps.PSObject.Properties) {

        $apName = $apProp.Name
        $ap = $apProp.Value
        $devIdx = $ap.device_index
        $apBase = "Device.WiFi.DataElements.Network.Device.$devIdx"

        Add-Metric $rows $RunId $i $timestampLocal $timestampUtc $scenarioName "ap" $apName "ap" "name" $ap.name "$apBase.Name"
        Add-Metric $rows $RunId $i $timestampLocal $timestampUtc $scenarioName "ap" $apName "ap" "role" $ap.role "$apBase.Role"
        Add-Metric $rows $RunId $i $timestampLocal $timestampUtc $scenarioName "ap" $apName "ap" "status" $ap.status "$apBase.Status"
        Add-Metric $rows $RunId $i $timestampLocal $timestampUtc $scenarioName "ap" $apName "ap" "almac" $ap.almac "$apBase.ID"
        Add-Metric $rows $RunId $i $timestampLocal $timestampUtc $scenarioName "ap" $apName "ap" "mac" $ap.mac "$apBase.MACAddress"
        Add-Metric $rows $RunId $i $timestampLocal $timestampUtc $scenarioName "ap" $apName "ap" "ipv4" $ap.ipv4 "$apBase.IPv4Address"

        Add-Metric $rows $RunId $i $timestampLocal $timestampUtc $scenarioName "backhaul" $apName "backhaul" "backhaul_type" $ap.backhaul_type "$apBase.BackhaulType"
        Add-Metric $rows $RunId $i $timestampLocal $timestampUtc $scenarioName "backhaul" $apName "backhaul" "backhaul_rssi" $ap.backhaul_rssi "$apBase.BackhaulRSSI"
        Add-Metric $rows $RunId $i $timestampLocal $timestampUtc $scenarioName "backhaul" $apName "backhaul" "backhaul_rate_mbps" $ap.backhaul_rate_mbps "$apBase.BackhaulRate"
        Add-Metric $rows $RunId $i $timestampLocal $timestampUtc $scenarioName "backhaul" $apName "backhaul" "backhaul_latency_ms" $ap.backhaul_latency_ms "$apBase.BackhaulLatency"
        Add-Metric $rows $RunId $i $timestampLocal $timestampUtc $scenarioName "backhaul" $apName "backhaul" "backhaul_packet_loss_percent" $ap.backhaul_packet_loss_percent "$apBase.BackhaulPacketLoss"

        Add-Metric $rows $RunId $i $timestampLocal $timestampUtc $scenarioName "ap" $apName "ap" "client_count" (@($ap.clients).Count) "$apBase.STANumberOfEntries"
        Add-Metric $rows $RunId $i $timestampLocal $timestampUtc $scenarioName "ap" $apName "ap" "radio_count" (@($ap.radios).Count) "$apBase.RadioNumberOfEntries"

        foreach ($radio in $ap.radios) {
            $radioIdx = $radio.id
            $radioBase = "$apBase.Radio.$radioIdx"
            $radioName = "$apName-$($radio.name)-$($radio.band)"

            Add-Metric $rows $RunId $i $timestampLocal $timestampUtc $scenarioName "radio" $radioName "radio" "radio_name" $radio.name "$radioBase.Name" "ap=$apName;band=$($radio.band)"
            Add-Metric $rows $RunId $i $timestampLocal $timestampUtc $scenarioName "radio" $radioName "radio" "band" $radio.band "$radioBase.OperatingFrequencyBand" "ap=$apName"
            Add-Metric $rows $RunId $i $timestampLocal $timestampUtc $scenarioName "radio" $radioName "radio" "channel" $radio.channel "$radioBase.Channel" "ap=$apName"
            Add-Metric $rows $RunId $i $timestampLocal $timestampUtc $scenarioName "radio" $radioName "radio" "frequency_mhz" $radio.frequency_mhz "$radioBase.FrequencyMHz" "ap=$apName"
            Add-Metric $rows $RunId $i $timestampLocal $timestampUtc $scenarioName "radio" $radioName "radio" "bandwidth" $radio.bandwidth "$radioBase.OperatingChannelBandwidth" "ap=$apName"
            Add-Metric $rows $RunId $i $timestampLocal $timestampUtc $scenarioName "radio" $radioName "radio" "standard" $radio.standard "$radioBase.OperatingStandards" "ap=$apName"
            Add-Metric $rows $RunId $i $timestampLocal $timestampUtc $scenarioName "radio" $radioName "radio" "tx_power_dbm" $radio.tx_power_dbm "$radioBase.TransmitPower" "ap=$apName"
            Add-Metric $rows $RunId $i $timestampLocal $timestampUtc $scenarioName "radio" $radioName "radio" "status" $radio.status "$radioBase.Status" "ap=$apName"
            Add-Metric $rows $RunId $i $timestampLocal $timestampUtc $scenarioName "radio" $radioName "radio" "utilization_percent" $radio.utilization_percent "$radioBase.Utilization" "ap=$apName"
            Add-Metric $rows $RunId $i $timestampLocal $timestampUtc $scenarioName "radio" $radioName "radio" "noise_dbm" $radio.noise_dbm "$radioBase.Noise" "ap=$apName"
            Add-Metric $rows $RunId $i $timestampLocal $timestampUtc $scenarioName "radio" $radioName "radio" "bss_number_of_entries" $radio.bss_number_of_entries "$radioBase.BSSNumberOfEntries" "ap=$apName"
            Add-Metric $rows $RunId $i $timestampLocal $timestampUtc $scenarioName "radio" $radioName "radio" "sta_number_of_entries" $radio.sta_number_of_entries "$radioBase.STANumberOfEntries" "ap=$apName"
            Add-Metric $rows $RunId $i $timestampLocal $timestampUtc $scenarioName "radio" $radioName "radio_stats" "bytes_sent" $radio.bytes_sent "$radioBase.Stats.BytesSent" "ap=$apName"
            Add-Metric $rows $RunId $i $timestampLocal $timestampUtc $scenarioName "radio" $radioName "radio_stats" "bytes_received" $radio.bytes_received "$radioBase.Stats.BytesReceived" "ap=$apName"
            Add-Metric $rows $RunId $i $timestampLocal $timestampUtc $scenarioName "radio" $radioName "radio_stats" "packets_sent" $radio.packets_sent "$radioBase.Stats.PacketsSent" "ap=$apName"
            Add-Metric $rows $RunId $i $timestampLocal $timestampUtc $scenarioName "radio" $radioName "radio_stats" "packets_received" $radio.packets_received "$radioBase.Stats.PacketsReceived" "ap=$apName"
            Add-Metric $rows $RunId $i $timestampLocal $timestampUtc $scenarioName "radio" $radioName "radio_stats" "errors_sent" $radio.errors_sent "$radioBase.Stats.ErrorsSent" "ap=$apName"
            Add-Metric $rows $RunId $i $timestampLocal $timestampUtc $scenarioName "radio" $radioName "radio_stats" "errors_received" $radio.errors_received "$radioBase.Stats.ErrorsReceived" "ap=$apName"
        }

        foreach ($client in $ap.clients) {
            $staIdx = $client.sta_index
            $staBase = "$apBase.STA.$staIdx"
            $clientName = $client.hostname
            $labels = "ap=$apName;sta_index=$staIdx;band=$($client.connected_band)"

            Add-Metric $rows $RunId $i $timestampLocal $timestampUtc $scenarioName "client" $clientName "client" "hostname" $client.hostname "$staBase.Hostname" $labels
            Add-Metric $rows $RunId $i $timestampLocal $timestampUtc $scenarioName "client" $clientName "client" "mac" $client.mac "$staBase.MACAddress" $labels
            Add-Metric $rows $RunId $i $timestampLocal $timestampUtc $scenarioName "client" $clientName "client" "ip" $client.ip "$staBase.IPAddress" $labels
            Add-Metric $rows $RunId $i $timestampLocal $timestampUtc $scenarioName "client" $clientName "client" "active" $client.active "$staBase.Active" $labels
            Add-Metric $rows $RunId $i $timestampLocal $timestampUtc $scenarioName "client" $clientName "client" "interface_type" $client.interface_type "$staBase.InterfaceType" $labels
            Add-Metric $rows $RunId $i $timestampLocal $timestampUtc $scenarioName "client" $clientName "client" "service" $client.service "$staBase.X_SARA_Service" $labels
            Add-Metric $rows $RunId $i $timestampLocal $timestampUtc $scenarioName "client" $clientName "association" "connected_device" $client.connected_device "$staBase.ConnectedDevice" $labels
            Add-Metric $rows $RunId $i $timestampLocal $timestampUtc $scenarioName "client" $clientName "association" "connected_radio" $client.connected_radio "$staBase.ConnectedRadio" $labels
            Add-Metric $rows $RunId $i $timestampLocal $timestampUtc $scenarioName "client" $clientName "association" "connected_band" $client.connected_band "$staBase.ConnectedBand" $labels
            Add-Metric $rows $RunId $i $timestampLocal $timestampUtc $scenarioName "client" $clientName "association" "ssid" $client.ssid "$staBase.SSID" $labels
            Add-Metric $rows $RunId $i $timestampLocal $timestampUtc $scenarioName "client" $clientName "association" "bssid" $client.bssid "$staBase.BSSID" $labels

            Add-Metric $rows $RunId $i $timestampLocal $timestampUtc $scenarioName "client" $clientName "rf" "signal_strength_dbm" $client.signal_strength_dbm "$staBase.SignalStrength" $labels
            Add-Metric $rows $RunId $i $timestampLocal $timestampUtc $scenarioName "client" $clientName "rf" "noise_dbm" $client.noise_dbm "$staBase.Noise" $labels
            Add-Metric $rows $RunId $i $timestampLocal $timestampUtc $scenarioName "client" $clientName "rf" "snr_db" $client.snr_db "$staBase.SNR" $labels
            Add-Metric $rows $RunId $i $timestampLocal $timestampUtc $scenarioName "client" $clientName "rf" "mcs" $client.mcs "$staBase.MCS" $labels
            Add-Metric $rows $RunId $i $timestampLocal $timestampUtc $scenarioName "client" $clientName "rate" "last_data_downlink_rate_mbps" $client.last_data_downlink_rate_mbps "$staBase.LastDataDownlinkRate" $labels
            Add-Metric $rows $RunId $i $timestampLocal $timestampUtc $scenarioName "client" $clientName "rate" "last_data_uplink_rate_mbps" $client.last_data_uplink_rate_mbps "$staBase.LastDataUplinkRate" $labels
            Add-Metric $rows $RunId $i $timestampLocal $timestampUtc $scenarioName "client" $clientName "traffic" "throughput_downlink_mbps" $client.throughput_downlink_mbps "$staBase.X_SARA_ThroughputDownlink" $labels
            Add-Metric $rows $RunId $i $timestampLocal $timestampUtc $scenarioName "client" $clientName "traffic" "throughput_uplink_mbps" $client.throughput_uplink_mbps "$staBase.X_SARA_ThroughputUplink" $labels
            Add-Metric $rows $RunId $i $timestampLocal $timestampUtc $scenarioName "client" $clientName "qos" "latency_ms" $client.latency_ms "$staBase.X_SARA_Latency" $labels
            Add-Metric $rows $RunId $i $timestampLocal $timestampUtc $scenarioName "client" $clientName "qos" "jitter_ms" $client.jitter_ms "$staBase.X_SARA_Jitter" $labels
            Add-Metric $rows $RunId $i $timestampLocal $timestampUtc $scenarioName "client" $clientName "qos" "packet_loss_percent" $client.packet_loss_percent "$staBase.X_SARA_PacketLoss" $labels
            Add-Metric $rows $RunId $i $timestampLocal $timestampUtc $scenarioName "client" $clientName "qos" "retry_rate_percent" $client.retry_rate_percent "$staBase.Stats.RetryRate" $labels
            Add-Metric $rows $RunId $i $timestampLocal $timestampUtc $scenarioName "client" $clientName "qoe" "qoe_score" $client.qoe_score "$staBase.X_SARA_QoEScore" $labels
            Add-Metric $rows $RunId $i $timestampLocal $timestampUtc $scenarioName "client" $clientName "qoe" "qoe_state" $client.qoe_state "$staBase.X_SARA_QoEState" $labels
            Add-Metric $rows $RunId $i $timestampLocal $timestampUtc $scenarioName "client" $clientName "qoe" "qoe_reason" $client.qoe_reason "$staBase.X_SARA_QoEReason" $labels
            Add-Metric $rows $RunId $i $timestampLocal $timestampUtc $scenarioName "client" $clientName "stats" "bytes_sent" $client.bytes_sent "$staBase.Stats.BytesSent" $labels
            Add-Metric $rows $RunId $i $timestampLocal $timestampUtc $scenarioName "client" $clientName "stats" "bytes_received" $client.bytes_received "$staBase.Stats.BytesReceived" $labels
            Add-Metric $rows $RunId $i $timestampLocal $timestampUtc $scenarioName "client" $clientName "stats" "packets_sent" $client.packets_sent "$staBase.Stats.PacketsSent" $labels
            Add-Metric $rows $RunId $i $timestampLocal $timestampUtc $scenarioName "client" $clientName "stats" "packets_received" $client.packets_received "$staBase.Stats.PacketsReceived" $labels
            Add-Metric $rows $RunId $i $timestampLocal $timestampUtc $scenarioName "client" $clientName "mobility" "last_connect_time" $client.last_connect_time "$staBase.LastConnectTime" $labels
            Add-Metric $rows $RunId $i $timestampLocal $timestampUtc $scenarioName "client" $clientName "mobility" "last_seen_seconds" $client.last_seen_seconds "$staBase.LastSeen" $labels
            Add-Metric $rows $RunId $i $timestampLocal $timestampUtc $scenarioName "client" $clientName "mobility" "roam_count" $client.roam_count "$staBase.X_SARA_RoamCount" $labels
        }
    }

    # =========================
    # EVENTO
    # =========================

    Add-Metric $rows $RunId $i $timestampLocal $timestampUtc $scenarioName "event" "Event.1" "event" "type" $state.event.type "Device.WiFi.DataElements.Network.Event.1.Type"
    Add-Metric $rows $RunId $i $timestampLocal $timestampUtc $scenarioName "event" "Event.1" "event" "from_device" $state.event.from_device "Device.WiFi.DataElements.Network.Event.1.FromDevice"
    Add-Metric $rows $RunId $i $timestampLocal $timestampUtc $scenarioName "event" "Event.1" "event" "to_device" $state.event.to_device "Device.WiFi.DataElements.Network.Event.1.ToDevice"
    Add-Metric $rows $RunId $i $timestampLocal $timestampUtc $scenarioName "event" "Event.1" "event" "result" $state.event.result "Device.WiFi.DataElements.Network.Event.1.Result"
    Add-Metric $rows $RunId $i $timestampLocal $timestampUtc $scenarioName "event" "Event.1" "event" "reason" $state.event.reason "Device.WiFi.DataElements.Network.Event.1.Reason"
    Add-Metric $rows $RunId $i $timestampLocal $timestampUtc $scenarioName "event" "Event.1" "event" "client" $state.event.client "Device.WiFi.DataElements.Network.Event.1.STAHostname"
    Add-Metric $rows $RunId $i $timestampLocal $timestampUtc $scenarioName "event" "Event.1" "event" "client_mac" $state.event.client_mac "Device.WiFi.DataElements.Network.Event.1.STAMACAddress"
    Add-Metric $rows $RunId $i $timestampLocal $timestampUtc $scenarioName "event" "Event.1" "event" "steering_count" $state.event.steering_count "Device.WiFi.DataElements.Network.Event.1.X_SARA_SteeringCount"

    # =========================
    # MOBILE SUMMARY
    # =========================

    Add-Metric $rows $RunId $i $timestampLocal $timestampUtc $scenarioName "mobile_summary" "MOVIL_SARA" "mobile_summary" "ap" $state.mobile_summary.ap "Device.X_SARA_QoE.CurrentAP"
    Add-Metric $rows $RunId $i $timestampLocal $timestampUtc $scenarioName "mobile_summary" "MOVIL_SARA" "mobile_summary" "signal_strength_dbm" $state.mobile_summary.signal_strength_dbm "Device.X_SARA_QoE.SignalStrength"
    Add-Metric $rows $RunId $i $timestampLocal $timestampUtc $scenarioName "mobile_summary" "MOVIL_SARA" "mobile_summary" "snr_db" $state.mobile_summary.snr_db "Device.X_SARA_QoE.SNR"
    Add-Metric $rows $RunId $i $timestampLocal $timestampUtc $scenarioName "mobile_summary" "MOVIL_SARA" "mobile_summary" "latency_ms" $state.mobile_summary.latency_ms "Device.X_SARA_QoE.Latency"
    Add-Metric $rows $RunId $i $timestampLocal $timestampUtc $scenarioName "mobile_summary" "MOVIL_SARA" "mobile_summary" "jitter_ms" $state.mobile_summary.jitter_ms "Device.X_SARA_QoE.Jitter"
    Add-Metric $rows $RunId $i $timestampLocal $timestampUtc $scenarioName "mobile_summary" "MOVIL_SARA" "mobile_summary" "packet_loss_percent" $state.mobile_summary.packet_loss_percent "Device.X_SARA_QoE.PacketLoss"
    Add-Metric $rows $RunId $i $timestampLocal $timestampUtc $scenarioName "mobile_summary" "MOVIL_SARA" "mobile_summary" "throughput_downlink_mbps" $state.mobile_summary.throughput_downlink_mbps "Device.X_SARA_QoE.ThroughputDownlink"
    Add-Metric $rows $RunId $i $timestampLocal $timestampUtc $scenarioName "mobile_summary" "MOVIL_SARA" "mobile_summary" "throughput_uplink_mbps" $state.mobile_summary.throughput_uplink_mbps "Device.X_SARA_QoE.ThroughputUplink"
    Add-Metric $rows $RunId $i $timestampLocal $timestampUtc $scenarioName "mobile_summary" "MOVIL_SARA" "mobile_summary" "qoe_score" $state.mobile_summary.qoe_score "Device.X_SARA_QoE.QoEScore"
    Add-Metric $rows $RunId $i $timestampLocal $timestampUtc $scenarioName "mobile_summary" "MOVIL_SARA" "mobile_summary" "qoe_state" $state.mobile_summary.qoe_state "Device.X_SARA_QoE.QoEState"
    Add-Metric $rows $RunId $i $timestampLocal $timestampUtc $scenarioName "mobile_summary" "MOVIL_SARA" "mobile_summary" "qoe_numeric" $state.mobile_summary.qoe_numeric "Device.X_SARA_QoE.QoENumeric"
    Add-Metric $rows $RunId $i $timestampLocal $timestampUtc $scenarioName "mobile_summary" "MOVIL_SARA" "mobile_summary" "qoe_reason" $state.mobile_summary.qoe_reason "Device.X_SARA_QoE.QoEReason"

    if ($i -lt $totalSamples) {
        Start-Sleep -Seconds $IntervalSeconds
    }
}

$rows | Export-Csv $OutCsv -NoTypeInformation -Encoding UTF8

Write-Host ""
Write-Host "CSV generado correctamente:"
Write-Host $OutCsv
Write-Host ""
Write-Host "Numero total de filas:"
Write-Host $rows.Count
Write-Host ""

$rows |
    Group-Object entity_type |
    Select-Object Name, Count |
    Format-Table -AutoSize

Write-Host ""
Write-Host "Primeras filas:"
$rows | Select-Object -First 20 | Format-Table -AutoSize