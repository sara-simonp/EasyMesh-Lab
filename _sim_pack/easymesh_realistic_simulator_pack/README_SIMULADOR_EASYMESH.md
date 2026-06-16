# Simulador dinámico EasyMesh para TFG

Este paquete añade un contenedor `easymesh-network-simulator` al laboratorio `C:\EasyMesh-Lab`.

## Qué simula

Topología:

```text
GW_MASTER / Controller
 ├── AP_SALON       Device.1, backhaul Ethernet
 └── AP_DORMITORIO  Device.2, backhaul WiFi-5GHz

Clientes:
 ├── PORTATIL_SARA
 ├── MOVIL_SARA
 ├── TABLET
 └── clientes de fondo en escenarios de saturación
```

No implementa un controlador EasyMesh certificado ni una capa PHY real. Es un simulador de comportamiento y telemetría orientado a QoE: genera métricas similares a las que interesan a un ACS/NMS en un entorno TR-181/DataElements.

## Endpoints

```text
http://localhost:9200/health
http://localhost:9200/state
http://localhost:9200/metrics
http://localhost:9200/scenarios
http://localhost:9200/set?scenario=normal
```

## Escenarios

```text
normal
coverage
interference
saturation
roaming
backhaul_degraded
ap_failure
mixed
```

## Métricas generadas

- RSSI / SignalStrength
- SNR
- Noise
- Channel Utilization
- Channel, bandwidth, standard, transmit power
- Número de STAs por AP/radio
- PHY rates uplink/downlink
- Throughput uplink/downlink
- Latencia
- Jitter
- Packet loss
- Retry rate
- Bytes/packets por radio y cliente
- Backhaul type, RSSI, rate, latency y packet loss
- Eventos LowRSSI, ClientSteering, HighInterference, HighUtilization, BackhaulDegraded, APFailure
- QoE score 0-100 y estado QoE
- CPU, memoria y uptime del CPE virtual

## Instalación rápida

1. Descomprime el ZIP sobre `C:\EasyMesh-Lab`.
2. Copia la configuración de Prometheus:

```powershell
Copy-Item "C:\EasyMesh-Lab\monitoring\prometheus\prometheus.yml" "C:\EasyMesh-Lab\monitoring\prometheus\prometheus.yml" -Force
```

3. Levanta el simulador:

```powershell
cd C:\EasyMesh-Lab
docker compose -f docker-compose.yml -f docker-compose.monitoring.yml -f docker-compose.simulator.yml up -d --build easymesh-network-simulator prometheus-monitoring grafana-monitoring
```

4. Comprueba:

```powershell
curl.exe http://localhost:9200/state
curl.exe http://localhost:9200/metrics
```

5. En Prometheus, comprueba:

```text
http://localhost:9090/targets
```

Debe aparecer `easymesh-network-simulator` en estado `UP`.

## Cambio de escenario

```powershell
.\scripts\run-sim-scenario.ps1 -Scenario normal
.\scripts\run-sim-scenario.ps1 -Scenario coverage
.\scripts\run-sim-scenario.ps1 -Scenario interference
.\scripts\run-sim-scenario.ps1 -Scenario saturation
.\scripts\run-sim-scenario.ps1 -Scenario roaming
.\scripts\run-sim-scenario.ps1 -Scenario backhaul_degraded
.\scripts\run-sim-scenario.ps1 -Scenario ap_failure
.\scripts\run-sim-scenario.ps1 -Scenario mixed
```

Para actualizar el CPE virtual TR-069 con el CSV generado por el simulador:

```powershell
.\scripts\run-sim-scenario.ps1 -Scenario roaming -ReloadTr069Sim
```

Después lanza desde GenieACS la tarea `getParameterValues` usando:

```text
C:\EasyMesh-Lab\evidencias\get_tr181_simulator_values.json
```

## Evidencias

```powershell
.\scripts\collect-sim-evidence.ps1
```

Genera un ZIP en:

```text
C:\EasyMesh-Lab\tfg-resultados\evidencias\simulador_easymesh_<timestamp>.zip
```

## Dashboard Grafana

El dashboard incluido se llama:

```text
EasyMesh Network Simulator - QoE/TR-181
```

Debe aparecer en Grafana tras reiniciar el contenedor:

```powershell
docker compose -f docker-compose.yml -f docker-compose.monitoring.yml -f docker-compose.simulator.yml restart grafana-monitoring
```
