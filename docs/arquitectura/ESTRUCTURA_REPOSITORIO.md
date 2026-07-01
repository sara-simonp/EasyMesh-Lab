# Estructura del repositorio EasyMesh-Lab

Este documento describe la organizacion actual del repositorio y diferencia entre los componentes finales del laboratorio, los datos generados, las evidencias del TFG y los elementos conservados de fases anteriores.

---

## 1. Laboratorio final usado en el TFG

El componente principal del laboratorio simulado es:

simulator usado en el TFG

El componente principal del laboratorio simulado es:

simulator/easymesh-network-simulator/

Archivos principales:

- app.py
- Dockerfile

Servicio Docker:

easymesh-network-simulator

Puerto:

9200

Endpoints principales:

- http://localhost:9200/state
- http://localhost:9200/metrics
- http://localhost:9200/scenarios
- http://localhost:9200/set?scenario=<escenario>

Escenarios disponibles:

- normal
- coverage
- interference
- saturation
- roaming
- backhaul_degraded
- ap_failure
- mixed

Este simulador genera telemetria WiFi/EasyMesh, metricas Prometheus y un CSV tipo TR-181/DataElements.

---

## 2. Datos vivos generados por el simulador

Ruta:

tr069-data/

Archivos principales:

- data_model_easymesh.csv
- easymesh_simulator_state.json
- easymesh_simulator_summary.txt

Funcion de cada archivo:

data_model_easymesh.csv

CSV tipo TR-181/DataElements generado por el simulador. Es usado como entrada para el simulador TR-069.

easymesh_simulator_state.json

Estado completo del escenario activo en formato JSON.

easymesh_simulator_summary.txt

Resumen textual del escenario activo.

Estos archivos son actualizados automaticamente por el simulador.

---

## 3. Integracion TR-069 y GenieACS

### 3.1 tr069-sim

Ruta:

tr069-sim/

Servicio Docker:

tr069-sim

Funcion:

Lee el CSV tr069-data/data_model_easymesh.csv y lo expone como CPE virtual hacia GenieACS mediante TR-069/CWMP.

Dispositivo virtual:

535241-EasyMeshVirtualCPE-200001

---

### 3.2 GenieACS

Ruta:

genieacs/

Servicio Docker:

genieacs-acs

URLs:

- GenieACS UI: http://localhost:3000
- GenieACS NBI/API: http://localhost:7557/devices
- GenieACS CWMP: http://localhost:7547

Funcion:

Actua como ACS para almacenar y consultar los parametros TR-181 del CPE virtual.

---

## 4. Monitorizacion

### 4.1 QoE exporter de GenieACS

Ruta:

monitoring/qoe-exporter/

Servicio Docker:

genieacs-qoe-exporter

Endpoint:

http://localhost:9108/metrics

Funcion:

Consulta GenieACS y expone metricas Prometheus derivadas de parametros TR-181/DataElements.

Metricas principales:

- genieacs_up
- easymesh_agent_number
- easymesh_total_client_number
- easymesh_event_info
- easymesh_radio_utilization_avg_percent
- easymesh_backhaul_rssi_dbm
- easymesh_client_signal_strength_dbm
- easymesh_client_qoe_state
- easymesh_target_client_found

---

### 4.2 Prometheus

Ruta de configuracion:

monitoring/prometheus/prometheus.yml

Servicio Docker:

prometheus-monitoring

URL:

http://localhost:9090

Targets configurados:

- easymesh-network-simulator:9200
- csv-prometheus-exporter:9210
- genieacs-qoe-exporter:9108

---

### 4.3 Grafana

Ruta:

monitoring/grafana/

Servicio Docker:

grafana-monitoring

URL:

http://localhost:3001

Credenciales por defecto:

admin / admin

Dashboard principal:

TFG EasyMesh - Simulador final TR-181 TR-069 QoE

---

### 4.4 CSV exporter

Ruta:

tools/csv-exporter/

Servicio Docker:

csv-prometheus-exporter

Endpoint:

http://localhost:9210/metrics

Funcion:

Lee los CSV historicos guardados en tfg-resultados/simulador/csv y los convierte en metricas Prometheus.

Metricas principales:

- easymesh_csv_exporter_up
- easymesh_csv_snapshots_total
- easymesh_csv_latest_snapshot_timestamp_seconds
- easymesh_csv_tr181_numeric_value
- easymesh_csv_tr181_info
- easymesh_csv_prometheus_metric_value

---

## 5. Evidencias generadas

### 5.1 CSV historicos por escenario

Ruta:

tfg-resultados/simulador/csv/

Contiene:

- data_model_easymesh_<escenario>_<fecha>.csv
- metricas_prometheus_<escenario>_<fecha>.csv

---

### 5.2 JSON de estado por escenario

Ruta:

tfg-resultados/simulador/capturas/

Contiene:

- state_<escenario>_<fecha>.json

---

### 5.3 Resumenes por escenario

Ruta:

tfg-resultados/simulador/resumen/

Contiene:

- summary_<escenario>_<fecha>.txt

---

### 5.4 Evidencias Prometheus

Ruta:

tfg-resultados/evidencias/prometheus/

Contiene respuestas exportadas desde la API de Prometheus en formato JSON y CSV.

---

## 6. Docker Compose usados

Archivos principales:

- docker-compose.yml
- docker-compose.monitoring.yml
- docker-compose.simulator-final-local.yml
- docker-compose.tr069-local.yml
- docker-compose.csv-exporter.yml
- docker-compose.prometheus-local.yml
- docker-compose.web-local.yml

Comando recomendado para levantar el laboratorio completo:

docker compose `
  -f docker-compose.yml `
  -f docker-compose.monitoring.yml `
  -f docker-compose.simulator-final-local.yml `
  -f docker-compose.tr069-local.yml `
  -f docker-compose.csv-exporter.yml `
  -f docker-compose.prometheus-local.yml `
  -f docker-compose.web-local.yml `
  up -d --build

---

## 7. Scripts importantes

### 7.1 Guardar ejecucion de escenario

Ruta:

tfg-resultados/scripts/guardar-ejecucion-simulador.ps1

Funcion:

Ejecuta un escenario, espera a que el simulador actualice el estado y guarda CSV, JSON y resumen sin sobrescribir evidencias anteriores.

Ejemplo:

powershell.exe -ExecutionPolicy Bypass -File "C:\EasyMesh-Lab\tfg-resultados\scripts\guardar-ejecucion-simulador.ps1" -Scenario interference -WaitSeconds 30

---

### 7.2 Crear dashboard Grafana

Ruta:

crear_dashboard_grafana_tfg.ps1

Funcion:

Crea automaticamente el dashboard final de Grafana usando el datasource Prometheus existente.

Ejemplo:

powershell.exe -ExecutionPolicy Bypass -File "C:\EasyMesh-Lab\crear_dashboard_grafana_tfg.ps1"

---

## 8. Componentes legacy o de fases anteriores

El repositorio puede contener componentes de fases anteriores. Se conservan como referencia, pero no son el componente principal de la entrega final.

Ejemplos:

- easymesh-simulator/
- README_FINAL.md
- documentacion antigua
- scripts antiguos

El componente principal para la entrega final del TFG es:

simulator/easymesh-network-simulator/

El pipeline final de observabilidad es:

easymesh-network-simulator
  -> tr069-sim
  -> GenieACS
  -> genieacs-qoe-exporter
  -> Prometheus
  -> Grafana

Y, para evidencias historicas:

tfg-resultados/simulador/csv
  -> csv-prometheus-exporter
  -> Prometheus
  -> Grafana

---

## 9. Pendiente antes de pasar a dispositivos reales

Antes de iniciar el laboratorio con dispositivos reales hay que cerrar:

1. Validacion de CSV TR-181 por escenario.
2. Catalogo de metricas TR-181.
3. Capturas finales.
4. Export del dashboard Grafana.
5. Evidencias Prometheus.
6. Logs finales.
7. Analisis comparativo entre escenarios.
8. Memoria del TFG.

---

## 10. Laboratorio futuro con dispositivos reales

Se propone crear un laboratorio separado en:

labs/docker-dispositivos-reales/

En ese laboratorio no se usara el simulador como fuente principal.

Flujo previsto:

CPE/router real
  -> TR-069/CWMP
  -> GenieACS
  -> exporter
  -> Prometheus
  -> Grafana

Objetivo:

Comparar que parametros TR-181 existen realmente en equipos fisicos frente a los parametros simulados en el laboratorio actual.

---

## 11. Estado actual resumido

El laboratorio simulado ya incluye:

- simulador EasyMesh dinamico;
- generacion de CSV TR-181/DataElements;
- generacion de metricas Prometheus directas;
- integracion con tr069-sim;
- integracion con GenieACS;
- exporter QoE desde GenieACS;
- exporter de CSV historicos;
- Prometheus;
- Grafana;
- dashboard automatizado;
- scripts de captura de evidencias por escenario.

El siguiente bloque de trabajo es validar los CSV finales por escenario y crear el catalogo de metricas TR-181.
