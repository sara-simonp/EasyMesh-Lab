$ErrorActionPreference = "Stop"
$root = "C:\EasyMesh-Lab"
$ts = Get-Date -Format "yyyyMMdd_HHmmss"
$out = "$root\tfg-resultados\evidencias\simulador_easymesh_$ts"
New-Item -ItemType Directory -Force -Path $out | Out-Null

curl.exe http://localhost:9200/state -o "$out\simulator_state.json"
curl.exe http://localhost:9200/metrics -o "$out\simulator_metrics.prom"
curl.exe http://localhost:9108/metrics -o "$out\genieacs_qoe_exporter_metrics.prom"
curl.exe "http://localhost:9090/api/v1/query?query=easymesh_sim_mobile_qoe_state" -o "$out\prometheus_query_qoe.json"
curl.exe "http://localhost:9090/api/v1/query?query=easymesh_sim_client_signal_dbm" -o "$out\prometheus_query_signal.json"
Copy-Item "$root\tr069-data\data_model_easymesh.csv" "$out\data_model_easymesh.csv" -Force
Copy-Item "$root\tr069-data\easymesh_simulator_state.json" "$out\easymesh_simulator_state.json" -Force -ErrorAction SilentlyContinue

docker ps --format "table {{.Names}}`t{{.Status}}`t{{.Networks}}`t{{.Ports}}" | Out-File -Encoding utf8 "$out\docker_ps.txt"
docker compose -f docker-compose.yml -f docker-compose.monitoring.yml -f docker-compose.simulator.yml logs --tail=300 easymesh-network-simulator > "$out\logs_simulator.txt"
docker compose -f docker-compose.yml -f docker-compose.monitoring.yml -f docker-compose.simulator.yml logs --tail=300 prometheus-monitoring > "$out\logs_prometheus.txt"
docker compose -f docker-compose.yml -f docker-compose.monitoring.yml -f docker-compose.simulator.yml logs --tail=300 grafana-monitoring > "$out\logs_grafana.txt"

Compress-Archive -Path "$out\*" -DestinationPath "$out.zip" -Force
Write-Host "Evidencias creadas en: $out"
Write-Host "ZIP: $out.zip"
