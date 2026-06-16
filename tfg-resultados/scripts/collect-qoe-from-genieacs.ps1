# collect-qoe-from-genieacs.ps1
# Extrae metricas QoE desde los JSON exportados de GenieACS.
# Objetivo:
# - Leer escenarios normal / cliente_lejos / steering.
# - Localizar automaticamente a MOVIL_SARA.
# - Detectar AP asociado, SignalStrength, Utilization, Backhaul y evento.
# - Generar qoe_summary_auto.csv.

$BaseLab = "C:\EasyMesh-Lab"
$EvidenceDir = Join-Path $BaseLab "evidencias"
$OutputDir = Join-Path $BaseLab "tfg-resultados\qoe"
$OutputCsv = Join-Path $OutputDir "qoe_summary_auto.csv"

$ClientName = "MOVIL_SARA"

function Get-Prop {
    param(
        [Parameter(Mandatory=$false)] $Object,
        [Parameter(Mandatory=$true)] [string] $Name
    )

    if ($null -eq $Object) {
        return $null
    }

    $prop = $Object.PSObject.Properties[$Name]
    if ($null -eq $prop) {
        return $null
    }

    return $prop.Value
}

function Get-LeafValue {
    param($Node)

    if ($null -eq $Node) {
        return $null
    }

    $value = Get-Prop $Node "_value"

    if ($null -ne $value) {
        return $value
    }

    return $null
}

function Get-LeafTimestamp {
    param($Node)

    if ($null -eq $Node) {
        return [datetime]::MinValue
    }

    $ts = Get-Prop $Node "_timestamp"

    if ([string]::IsNullOrWhiteSpace($ts)) {
        return [datetime]::MinValue
    }

    try {
        return [datetime]::Parse($ts)
    }
    catch {
        return [datetime]::MinValue
    }
}

function Get-PathNode {
    param(
        [Parameter(Mandatory=$true)] $Root,
        [Parameter(Mandatory=$true)] [string] $Path
    )

    $current = $Root

    foreach ($part in $Path.Split(".")) {
        $current = Get-Prop $current $part

        if ($null -eq $current) {
            return $null
        }
    }

    return $current
}

function Get-NumericChildren {
    param($Object)

    if ($null -eq $Object) {
        return @()
    }

    return @(
        $Object.PSObject.Properties |
        Where-Object { $_.Name -match '^\d+$' } |
        Sort-Object { [int]$_.Name }
    )
}

function Get-UtilizationAverage {
    param($ApObject)

    $radioObj = Get-Prop $ApObject "Radio"
    $values = @()

    foreach ($radioProp in Get-NumericChildren $radioObj) {
        $utilNode = Get-Prop $radioProp.Value "Utilization"
        $util = Get-LeafValue $utilNode

        if ($null -ne $util -and "$util" -match '^-?\d+(\.\d+)?$') {
            $values += [double]$util
        }
    }

    if ($values.Count -eq 0) {
        return $null
    }

    return [math]::Round((($values | Measure-Object -Average).Average), 2)
}

function Get-QoeState {
    param(
        [Parameter(Mandatory=$false)] $SignalStrength,
        [Parameter(Mandatory=$false)] [string] $EventType,
        [Parameter(Mandatory=$false)] [string] $EventResult
    )

    if ($EventType -eq "ClientSteering" -and $EventResult -eq "Success") {
        return "Recuperada"
    }

    if ($EventType -eq "LowRSSI" -and $EventResult -eq "CandidateForSteering") {
        return "Degradada"
    }

    if ($null -eq $SignalStrength) {
        return "Desconocida"
    }

    $signal = [double]$SignalStrength

    if ($signal -gt -60) {
        return "Buena"
    }
    elseif ($signal -gt -70) {
        return "Media"
    }
    else {
        return "Degradada"
    }
}

function Resolve-ScenarioFile {
    param(
        [Parameter(Mandatory=$true)] [string] $Scenario
    )

    $final = Join-Path $EvidenceDir "devices_tr181_${Scenario}_final.json"
    $normal = Join-Path $EvidenceDir "devices_tr181_${Scenario}.json"

    if (Test-Path $final) {
        return $final
    }

    if (Test-Path $normal) {
        return $normal
    }

    return $null
}

function Read-FirstDeviceFromJson {
    param(
        [Parameter(Mandatory=$true)] [string] $Path
    )

    $raw = Get-Content $Path -Raw
    $parsed = $raw | ConvertFrom-Json

    if ($parsed -is [System.Array]) {
        return $parsed[0]
    }

    return $parsed
}

function Extract-ScenarioQoe {
    param(
        [Parameter(Mandatory=$true)] [string] $Scenario,
        [Parameter(Mandatory=$true)] [string] $JsonPath
    )

    $device = Read-FirstDeviceFromJson -Path $JsonPath

    $network = Get-PathNode $device "Device.WiFi.DataElements.Network"

    if ($null -eq $network) {
        throw "No se encuentra Device.WiFi.DataElements.Network en $JsonPath"
    }

    $eventTypeNode = Get-PathNode $network "Event.1.Type"
    $eventFromNode = Get-PathNode $network "Event.1.FromDevice"
    $eventToNode = Get-PathNode $network "Event.1.ToDevice"
    $eventResultNode = Get-PathNode $network "Event.1.Result"

    $eventType = Get-LeafValue $eventTypeNode
    $eventFrom = Get-LeafValue $eventFromNode
    $eventTo = Get-LeafValue $eventToNode
    $eventResult = Get-LeafValue $eventResultNode

    $networkDevices = Get-Prop $network "Device"

    if ($null -eq $networkDevices) {
        throw "No se encuentra Network.Device en $JsonPath"
    }

    $candidateRows = @()

    foreach ($apProp in Get-NumericChildren $networkDevices) {
        $deviceIndex = $apProp.Name
        $apObj = $apProp.Value

        $apNameNode = Get-Prop $apObj "Name"
        $apName = Get-LeafValue $apNameNode

        $backhaulType = Get-LeafValue (Get-Prop $apObj "BackhaulType")
        $backhaulRssi = Get-LeafValue (Get-Prop $apObj "BackhaulRSSI")

        $utilAvg = Get-UtilizationAverage -ApObject $apObj

        $staObj = Get-Prop $apObj "STA"

        foreach ($staProp in Get-NumericChildren $staObj) {
            $staIndex = $staProp.Name
            $sta = $staProp.Value

            $hostnameNode = Get-Prop $sta "Hostname"
            $hostname = Get-LeafValue $hostnameNode

            if ($hostname -ne $ClientName) {
                continue
            }

            $signalNode = Get-Prop $sta "SignalStrength"
            $connectedNode = Get-Prop $sta "ConnectedDevice"

            $signal = Get-LeafValue $signalNode
            $connectedDevice = Get-LeafValue $connectedNode

            if ([string]::IsNullOrWhiteSpace($connectedDevice)) {
                $connectedDevice = $apName
            }

            $latestTs = @(
                Get-LeafTimestamp $hostnameNode
                Get-LeafTimestamp $signalNode
                Get-LeafTimestamp $connectedNode
            ) | Sort-Object -Descending | Select-Object -First 1

            $candidateRows += [PSCustomObject]@{
                latest_timestamp = $latestTs
                scenario = $Scenario
                client = $ClientName
                connected_ap = $connectedDevice
                device_index = $deviceIndex
                sta_index = $staIndex
                signal_strength_dbm = $signal
                radio_utilization_avg_pct = $utilAvg
                backhaul_type = $backhaulType
                backhaul_rssi_dbm = $backhaulRssi
                event_type = $eventType
                event_from = $eventFrom
                event_to = $eventTo
                event_result = $eventResult
                qoe_state = Get-QoeState -SignalStrength $signal -EventType $eventType -EventResult $eventResult
                source_file = Split-Path $JsonPath -Leaf
            }
        }
    }

    if ($candidateRows.Count -eq 0) {
        return [PSCustomObject]@{
            latest_timestamp = $null
            scenario = $Scenario
            client = $ClientName
            connected_ap = "NO_ENCONTRADO"
            device_index = ""
            sta_index = ""
            signal_strength_dbm = ""
            radio_utilization_avg_pct = ""
            backhaul_type = ""
            backhaul_rssi_dbm = ""
            event_type = $eventType
            event_from = $eventFrom
            event_to = $eventTo
            event_result = $eventResult
            qoe_state = "Desconocida"
            source_file = Split-Path $JsonPath -Leaf
        }
    }

    # Si GenieACS conserva valores antiguos en cache, puede aparecer MOVIL_SARA dos veces.
    # Nos quedamos con la entrada con timestamp mas reciente.
    return $candidateRows | Sort-Object latest_timestamp -Descending | Select-Object -First 1
}

$scenarios = @("normal", "cliente_lejos", "steering")
$results = @()

foreach ($scenario in $scenarios) {
    $jsonPath = Resolve-ScenarioFile -Scenario $scenario

    if ($null -eq $jsonPath) {
        Write-Warning "No se ha encontrado JSON para el escenario: $scenario"
        continue
    }

    Write-Host "Procesando escenario $scenario desde $jsonPath"

    try {
        $results += Extract-ScenarioQoe -Scenario $scenario -JsonPath $jsonPath
    }
    catch {
        Write-Warning "Error procesando $scenario : $($_.Exception.Message)"
    }
}

if ($results.Count -eq 0) {
    throw "No se ha generado ningun resultado. Revisa que existan los JSON de evidencias."
}

$results |
    Select-Object latest_timestamp,scenario,client,connected_ap,device_index,sta_index,signal_strength_dbm,radio_utilization_avg_pct,backhaul_type,backhaul_rssi_dbm,event_type,event_from,event_to,event_result,qoe_state,source_file |
    Export-Csv -Path $OutputCsv -NoTypeInformation -Encoding UTF8

Write-Host ""
Write-Host "CSV QoE generado en:"
Write-Host $OutputCsv
Write-Host ""

Import-Csv $OutputCsv | Format-Table -AutoSize