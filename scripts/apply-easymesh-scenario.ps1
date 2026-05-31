param(
  [Parameter(Mandatory=$true)]
  [ValidateSet("normal", "cliente_lejos", "steering")]
  [string]$Scenario
)

$ErrorActionPreference = "Stop"
$root = "C:\EasyMesh-Lab"
$scenarioMap = @{
  "normal" = "scenario_01_normal.json"
  "cliente_lejos" = "scenario_02_cliente_lejos.json"
  "steering" = "scenario_03_steering.json"
}

$scenarioFile = $scenarioMap[$Scenario]
$src = Join-Path $root "adapter\topology-scenarios\$scenarioFile"
$dst = Join-Path $root "tr069-data\current_scenario.json"

Write-Host "== EasyMesh virtual avanzado =="
Write-Host "Escenario seleccionado: $Scenario"

if (!(Test-Path $src)) { throw "No existe el escenario: $src" }

New-Item -ItemType Directory -Force -Path (Join-Path $root "tr069-data") | Out-Null
Copy-Item $src $dst -Force

docker compose build easymesh-tr069-adapter
docker compose up easymesh-tr069-adapter
docker compose restart tr069-sim

Write-Host "Esperando 15 segundos..."
Start-Sleep -Seconds 15

$evidDir = Join-Path $root "evidencias"
New-Item -ItemType Directory -Force -Path $evidDir | Out-Null
$outJson = Join-Path $evidDir "devices_easymesh_${Scenario}.json"

curl.exe http://localhost:7557/devices > $outJson

Select-String -Path $outJson -Pattern "ScenarioId|ScenarioName|AgentNumber|AP_SALON|AP_DORMITORIO|ClientNumber|PORTATIL_SARA|MOVIL_SARA|TABLET|RSSI|ClientSteering|LowRSSI|BackhaulType|ChannelUtilization"

Write-Host ""
Write-Host "Escenario aplicado correctamente."
Write-Host "Evidencia: $outJson"
Write-Host "GenieACS: http://localhost:3000"
