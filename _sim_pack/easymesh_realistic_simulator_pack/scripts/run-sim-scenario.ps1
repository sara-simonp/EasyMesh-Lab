param(
  [Parameter(Mandatory=$true)]
  [ValidateSet("normal", "coverage", "interference", "saturation", "roaming", "backhaul_degraded", "ap_failure", "mixed")]
  [string]$Scenario,
  [int]$WaitSeconds = 20,
  [switch]$ReloadTr069Sim
)

$ErrorActionPreference = "Stop"
$root = "C:\EasyMesh-Lab"
Write-Host "== EasyMesh Network Simulator =="
Write-Host "Escenario: $Scenario"

curl.exe "http://localhost:9200/set?scenario=$Scenario"
Start-Sleep -Seconds $WaitSeconds

Write-Host "\nEstado resumido:"
curl.exe http://localhost:9200/state | Out-File -Encoding utf8 "$root\evidencias\simulator_state_$Scenario.json"
Select-String -Path "$root\evidencias\simulator_state_$Scenario.json" -Pattern '"scenario"|"scenario_description"|"client"|"ap"|"signal_strength_dbm"|"latency_ms"|"packet_loss_percent"|"qoe_score"|"qoe_state"|"type"|"result"|"reason"'

Write-Host "\nMetricas Prometheus del simulador guardadas:"
curl.exe http://localhost:9200/metrics | Out-File -Encoding utf8 "$root\evidencias\simulator_metrics_$Scenario.prom"
Write-Host "$root\evidencias\simulator_metrics_$Scenario.prom"

if ($ReloadTr069Sim) {
  Write-Host "\nRecreando tr069-sim para que lea el CSV dinamico generado por el simulador..."
  docker compose up -d --force-recreate --no-deps tr069-sim
  Start-Sleep -Seconds 35
  Write-Host "tr069-sim recreado. Ahora puedes lanzar GetParameterValues desde GenieACS."
}
