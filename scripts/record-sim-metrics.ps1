param(
    [string]$Scenario = "current",
    [int]$DurationMinutes = 1,
    [int]$IntervalSeconds = 10,
    [string]$OutBase = "C:\EasyMesh-Lab\tfg-resultados\simulador"
)

$ErrorActionPreference = "Stop"

$BaseUrl = "http://localhost:9200"

function Format-Value {
    param($Value)

    if ($null -eq $Value) {
        return ""
    }

    if ($Value -is [double] -or $Value -is [single] -or $Value -is [decimal]) {
        return $Value.ToString([System.Globalization.CultureInfo]::InvariantCulture)
    }

    return [string]$Value
}

function Get-Unit {
    param([string]$MetricName)

    $m = $MetricName.ToLowerInvariant()

    if ($m -match "rssi|signal|noise|tx_power") { return "dBm" }
    if ($m -match "snr") { return "dB" }
    if ($m -match "latency|jitter") { return "ms" }
    if ($m -match "percent|usage|utilization|loss|retry") { return "%" }
    if ($m -match "rate|throughput") { return "Mbps" }
    if ($m -match "bytes") { return "bytes" }
    if ($m -match "packets") { return "packets" }
    if ($m -match "memory") { return "MB" }
    if ($m -match "frequency") { return "MHz" }
    if ($m -match "channel|entries|number|count|score|mcs") { return "count" }

    return ""
}

function Get-MetricName {
    param([string]$JsonPath)

    $parts = $JsonPath.Split(".")
    return $parts[$parts.Length - 1]
}

function Get-EntityType {
    param([string]$JsonPath)

    if ($JsonPath -match "^controller\.") { return "controller" }
    if ($JsonPath -match "^device_info\.") { return "device_info" }
    if ($JsonPath -match "^event\.") { return "event" }
    if ($JsonPath -match "^mobile_summary\.") { return "mobile_summary" }
    if ($JsonPath -match "^aps\.[^.]+\.radios\.") { return "radio" }
    if ($JsonPath -match "^aps\.[^.]+\.clients\.") { return "client" }
    if ($JsonPath -match "^aps\.[^.]+\.backhaul") { return "backhaul" }
    if ($JsonPath -match "^aps\.") { return "ap" }

    return "other"
}

function Get-EntityName {
    param([string]$JsonPath)

    if ($JsonPath -match "^controller\.") { return "GW_MASTER" }
    if ($JsonPath -match "^device_info\.") { return "EasyMeshVirtualCPE" }
    if ($JsonPath -match "^event\.") { return "Event.1" }
    if ($JsonPath -match "^mobile_summary\.") { return "MOVIL_SARA" }

    if ($JsonPath -match "^aps\.([^.]+)\.radios\.(\d+)\.") {
        $ap = $Matches[1]
        $idx = [int]$Matches[2] + 1
        return "$ap-Radio.$idx"
    }

    if ($JsonPath -match "^aps\.([^.]+)\.clients\.(\d+)\.") {
        $ap = $Matches[1]
        $idx = [int]$Matches[2] + 1
        return "$ap-STA.$idx"
    }

    if ($JsonPath -match "^aps\.([^.]+)\.") {
        return $Matches[1]
    }

    return ""
}

function Get-Tr181Path {
    param([string]$JsonPath)

    $deviceInfoMap = @{
        "manufacturer"       = "Manufacturer"
        "manufacturer_oui"   = "ManufacturerOUI"
        "product_class"      = "ProductClass"
        "serial_number"      = "SerialNumber"
        "software_version"   = "SoftwareVersion"
        "cpu_usage_percent"  = "X_SARA_CPUUsage"
        "memory_total_mb"    = "MemoryStatus.Total"
        "memory_free_mb"     = "MemoryStatus.Free"
    }

    $controllerMap = @{
        "name"                = "Name"
        "status"              = "Status"
        "almac"               = "ID"
        "ipv4"                = "IPv4Address"
        "agent_number"        = "AgentNumber"
        "total_client_number" = "TotalClientNumber"
    }

    $apMap = @{
        "name"                         = "Name"
        "device_index"                 = "X_SARA_DeviceIndex"
        "role"                         = "Role"
        "status"                       = "Status"
        "almac"                        = "ID"
        "mac"                          = "MACAddress"
        "ipv4"                         = "IPv4Address"
        "backhaul_type"                = "BackhaulType"
        "backhaul_rssi"                = "BackhaulRSSI"
        "backhaul_rate_mbps"           = "BackhaulRate"
        "backhaul_latency_ms"          = "BackhaulLatency"
        "backhaul_packet_loss_percent" = "BackhaulPacketLoss"
    }

    $radioMap = @{
        "id"                    = "Alias"
        "name"                  = "Name"
        "band"                  = "OperatingFrequencyBand"
        "channel"               = "Channel"
        "frequency_mhz"         = "FrequencyMHz"
        "bandwidth"             = "OperatingChannelBandwidth"
        "standard"              = "OperatingStandards"
        "tx_power_dbm"          = "TransmitPower"
        "status"                = "Status"
        "utilization_percent"   = "Utilization"
        "noise_dbm"             = "Noise"
        "bss_number_of_entries" = "BSSNumberOfEntries"
        "sta_number_of_entries" = "STANumberOfEntries"
        "bytes_sent"            = "Stats.BytesSent"
        "bytes_received"        = "Stats.BytesReceived"
        "packets_sent"          = "Stats.PacketsSent"
        "packets_received"      = "Stats.PacketsReceived"
        "errors_sent"           = "Stats.ErrorsSent"
        "errors_received"       = "Stats.ErrorsReceived"
    }

    $clientMap = @{
        "sta_index"                       = "Alias"
        "hostname"                        = "Hostname"
        "mac"                             = "MACAddress"
        "ip"                              = "IPAddress"
        "active"                          = "Active"
        "interface_type"                  = "InterfaceType"
        "service"                         = "X_SARA_Service"
        "connected_device"                = "ConnectedDevice"
        "connected_radio"                 = "ConnectedRadio"
        "connected_band"                  = "ConnectedBand"
        "ssid"                            = "SSID"
        "bssid"                           = "BSSID"
        "signal_strength_dbm"             = "SignalStrength"
        "noise_dbm"                       = "Noise"
        "snr_db"                          = "SNR"
        "mcs"                             = "MCS"
        "last_data_downlink_rate_mbps"    = "LastDataDownlinkRate"
        "last_data_uplink_rate_mbps"      = "LastDataUplinkRate"
        "throughput_downlink_mbps"        = "X_SARA_ThroughputDownlink"
        "throughput_uplink_mbps"          = "X_SARA_ThroughputUplink"
        "latency_ms"                      = "X_SARA_Latency"
        "jitter_ms"                       = "X_SARA_Jitter"
        "packet_loss_percent"             = "X_SARA_PacketLoss"
        "retry_rate_percent"              = "Stats.RetryRate"
        "qoe_score"                       = "X_SARA_QoEScore"
        "qoe_state"                       = "X_SARA_QoEState"
        "qoe_reason"                      = "X_SARA_QoEReason"
        "bytes_sent"                      = "Stats.BytesSent"
        "bytes_received"                  = "Stats.BytesReceived"
        "packets_sent"                    = "Stats.PacketsSent"
        "packets_received"                = "Stats.PacketsReceived"
        "last_connect_time"               = "LastConnectTime"
        "last_seen_seconds"               = "LastSeen"
        "roam_count"                      = "X_SARA_RoamCount"
    }

    $eventMap = @{
        "type"            = "Type"
        "from_device"     = "FromDevice"
        "to_device"       = "ToDevice"
        "result"          = "Result"
        "reason"          = "Reason"
        "client"          = "STAHostname"
        "client_mac"      = "STAMACAddress"
        "timestamp_utc"   = "TimestampUTC"
        "steering_count"  = "X_SARA_SteeringCount"
    }

    $mobileMap = @{
        "client"                   = "Client"
        "ap"                       = "CurrentAP"
        "signal_strength_dbm"      = "SignalStrength"
        "snr_db"                   = "SNR"
        "latency_ms"               = "Latency"
        "jitter_ms"                = "Jitter"
        "packet_loss_percent"      = "PacketLoss"
        "throughput_downlink_mbps" = "ThroughputDownlink"
        "throughput_uplink_mbps"   = "ThroughputUplink"
        "qoe_score"                = "QoEScore"
        "qoe_state"                = "QoEState"
        "qoe_numeric"              = "QoENumeric"
        "qoe_reason"               = "QoEReason"
    }

    if ($JsonPath -match "^device_info\.([^.]+)$") {
        $leaf = $Matches[1]
        if ($deviceInfoMap.ContainsKey($leaf)) {
            return "Device.DeviceInfo.$($deviceInfoMap[$leaf])"
        }
    }

    if ($JsonPath -match "^controller\.([^.]+)$") {
        $leaf = $Matches[1]
        if ($controllerMap.ContainsKey($leaf)) {
            return "Device.WiFi.DataElements.Network.Controller.$($controllerMap[$leaf])"
        }
    }

    if ($JsonPath -match "^event\.([^.]+)$") {
        $leaf = $Matches[1]
        if ($eventMap.ContainsKey($leaf)) {
            return "Device.WiFi.DataElements.Network.Event.1.$($eventMap[$leaf])"
        }
    }

    if ($JsonPath -match "^mobile_summary\.([^.]+)$") {
        $leaf = $Matches[1]
        if ($mobileMap.ContainsKey($leaf)) {
            return "Device.X_SARA_QoE.$($mobileMap[$leaf])"
        }
    }

    if ($JsonPath -match "^aps\.([^.]+)\.(.+)$") {
        $apName = $Matches[1]
        $rest = $Matches[2]

        $devIndex = switch ($apName) {
            "AP_SALON" { "1" }
            "AP_DORMITORIO" { "2" }
            default { "X" }
        }

        $base = "Device.WiFi.DataElements.Network.Device.$devIndex"

        if ($rest -match "^radios\.(\d+)\.([^.]+)$") {
            $radioIndex = [int]$Matches[1] + 1
            $leaf = $Matches[2]

            if ($radioMap.ContainsKey($leaf)) {
                return "$base.Radio.$radioIndex.$($radioMap[$leaf])"
            }

            return "$base.Radio.$radioIndex.X_SARA_$leaf"
        }

        if ($rest -match "^clients\.(\d+)\.([^.]+)$") {
            $staIndex = [int]$Matches[1] + 1
            $leaf = $Matches[2]

            if ($clientMap.ContainsKey($leaf)) {
                return "$base.STA.$staIndex.$($clientMap[$leaf])"
            }

            return "$base.STA.$staIndex.X_SARA_$leaf"
        }

        if ($rest -match "^([^.]+)$") {
            $leaf = $Matches[1]

            if ($apMap.ContainsKey($leaf)) {
                return "$base.$($apMap[$leaf])"
            }

            return "$base.X_SARA_$leaf"
        }
    }

    return ""
}

function Add-Leaves {
    param(
        $Node,
        [string]$Path
    )

    if ($null -eq $Node) {
        return
    }

    if ($Node -is [System.Array]) {
        for ($idx = 0; $idx -lt $Node.Count; $idx++) {
            $newPath = if ($Path) { "$Path.$idx" } else { "$idx" }
            Add-Leaves -Node $Node[$idx] -Path $newPath
        }
        return
    }

    if ($Node -is [System.Management.Automation.PSCustomObject]) {
        foreach ($prop in $Node.PSObject.Properties) {
            $newPath = if ($Path) { "$Path.$($prop.Name)" } else { $prop.Name }
            Add-Leaves -Node $prop.Value -Path $newPath
        }
        return
    }

    $metricName = Get-MetricName $Path

    [void]$script:Rows.Add([PSCustomObject]@{
        run_id          = $script:RunId
        sample          = $script:SampleNumber
        timestamp_local = $script:TimestampLocal
        timestamp_utc   = $script:TimestampUtc
        scenario        = $script:ScenarioName
        entity_type     = Get-EntityType $Path
        entity_name     = Get-EntityName $Path
        metric_name     = $metricName
        metric_value    = Format-Value $Node
        unit            = Get-Unit $metricName
        json_path       = $Path
        tr181_path      = Get-Tr181Path $Path
    })
}

if (!(Test-Path $OutBase)) {
    New-Item -ItemType Directory -Force -Path $OutBase | Out-Null
}

New-Item -ItemType Directory -Force -Path "$OutBase\csv" | Out-Null
New-Item -ItemType Directory -Force -Path "$OutBase\capturas" | Out-Null

if ($Scenario -ne "current") {
    Write-Host "Cambiando escenario a: $Scenario"
    $encoded = [uri]::EscapeDataString($Scenario)
    Invoke-WebRequest -Uri "$BaseUrl/set?scenario=$encoded" -UseBasicParsing | Out-Null
    Start-Sleep -Seconds 5
}

$firstRaw = Invoke-WebRequest -Uri "$BaseUrl/state" -UseBasicParsing -TimeoutSec 10
$firstState = $firstRaw.Content | ConvertFrom-Json

if ($Scenario -eq "current") {
    $Scenario = $firstState.scenario
}

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$script:RunId = "${timestamp}_${Scenario}"

$runDir = Join-Path "$OutBase\capturas" $RunId
$rawDir = Join-Path $runDir "raw"
$promDir = Join-Path $runDir "prometheus"

New-Item -ItemType Directory -Force -Path $runDir | Out-Null
New-Item -ItemType Directory -Force -Path $rawDir | Out-Null
New-Item -ItemType Directory -Force -Path $promDir | Out-Null

$csvMain = Join-Path $runDir "metricas_completas.csv"
$csvCopy = Join-Path "$OutBase\csv" "metricas_completas_$RunId.csv"

$totalSamples = [math]::Max(1, [math]::Ceiling(($DurationMinutes * 60) / $IntervalSeconds))

$script:Rows = New-Object System.Collections.ArrayList

Write-Host ""
Write-Host "Grabando todas las metricas del simulador"
Write-Host "Escenario: $Scenario"
Write-Host "Duracion: $DurationMinutes minutos"
Write-Host "Intervalo: $IntervalSeconds segundos"
Write-Host "Muestras: $totalSamples"
Write-Host "Salida: $runDir"
Write-Host ""

for ($i = 1; $i -le $totalSamples; $i++) {
    $sampleTime = Get-Date
    $sampleStamp = $sampleTime.ToString("yyyyMMdd_HHmmss")

    Write-Host "Muestra $i / $totalSamples - $sampleStamp"

    $raw = Invoke-WebRequest -Uri "$BaseUrl/state" -UseBasicParsing -TimeoutSec 10
    $state = $raw.Content | ConvertFrom-Json

    $raw.Content | Set-Content -Path "$rawDir\state_$sampleStamp.json" -Encoding UTF8

    Invoke-WebRequest -Uri "$BaseUrl/metrics" -UseBasicParsing -OutFile "$promDir\metrics_$sampleStamp.prom"

    $script:SampleNumber = $i
    $script:TimestampLocal = $sampleTime.ToString("yyyy-MM-dd HH:mm:ss")
    $script:TimestampUtc = $state.timestamp_utc
    $script:ScenarioName = $state.scenario

    Add-Leaves -Node $state -Path ""

    if ($i -lt $totalSamples) {
        Start-Sleep -Seconds $IntervalSeconds
    }
}

$Rows | Export-Csv $csvMain -NoTypeInformation -Encoding UTF8
Copy-Item $csvMain $csvCopy -Force

Write-Host ""
Write-Host "CSV generado correctamente:"
Write-Host $csvMain
Write-Host ""
Write-Host "Copia rapida:"
Write-Host $csvCopy
Write-Host ""
Write-Host "Numero total de filas:"
Write-Host $Rows.Count
Write-Host ""

$Rows |
    Group-Object entity_type |
    Select-Object Name, Count |
    Format-Table -AutoSize

Write-Host ""
Write-Host "Primeras filas:"
$Rows | Select-Object -First 20 | Format-Table -AutoSize