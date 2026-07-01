# Catalogo de metricas TR-181 / DataElements

Este documento recoge las metricas principales utilizadas en el laboratorio EasyMesh-Lab para caracterizar la experiencia de cliente en una red WiFi distribuida.

El catalogo se basa en el CSV generado por el simulador:

tr069-data/data_model_easymesh.csv

y en los CSV historicos guardados por escenario:

tfg-resultados/simulador/csv/

---

## 1. Objetivo del catalogo

El objetivo de este catalogo es documentar:

- que metricas se recogen;
- donde aparecen dentro del modelo TR-181/DataElements;
- que unidad tienen;
- que componente las genera;
- con que periodicidad se actualizan;
- para que se usan dentro del calculo de QoE;
- que limitaciones tienen en un entorno simulado y en un entorno real.

---

## 2. Ramas principales del modelo

El laboratorio utiliza las siguientes ramas principales:

| Rama | Funcion |
|---|---|
| InternetGatewayDevice.X_SARA_EasyMesh | Extension propia para informacion general del escenario y agentes EasyMesh |
| Device.WiFi.DataElements.Network | Representacion tipo DataElements de la red EasyMesh |
| Device.WiFi.DataElements.Network.Controller | Informacion del controlador EasyMesh |
| Device.WiFi.DataElements.Network.Device | Informacion de los nodos EasyMesh: gateway y satelite |
| Device.WiFi.DataElements.Network.Device.X.Radio | Metricas de radios WiFi |
| Device.WiFi.DataElements.Network.Device.X.STA | Metricas de clientes WiFi asociados |
| Device.WiFi.DataElements.Network.Event.1 | Evento EasyMesh actual |
| Device.WiFi.AccessPoint | Mapeo compatible con objetos WiFi AccessPoint |
| Device.WiFi.AccessPoint.X.AssociatedDevice | Clientes asociados a cada AP |
| Device.Hosts.Host | Vista de hosts conectados |
| Device.X_SARA_QoE | Resumen QoE del cliente objetivo |

---

## 3. Metricas de escenario

| Parametro | Descripcion | Unidad | Origen | Periodicidad | Uso QoE | Limitaciones |
|---|---|---|---|---|---|---|
| InternetGatewayDevice.X_SARA_EasyMesh.ScenarioId | Escenario activo | texto | simulador | 5 s | Contextualiza los resultados | No es parametro TR-181 estandar, es extension del laboratorio |
| InternetGatewayDevice.X_SARA_EasyMesh.ScenarioName | Descripcion del escenario | texto | simulador | 5 s | Explica la condicion de prueba | Extension propia |
| InternetGatewayDevice.X_SARA_EasyMesh.LastUpdateUTC | Ultima actualizacion | fecha UTC | simulador | 5 s | Permite correlacion temporal | Depende del reloj del host |
| InternetGatewayDevice.X_SARA_EasyMesh.Source | Fuente de la telemetria | texto | simulador | 5 s | Trazabilidad | Extension propia |

---

## 4. Metricas del controlador EasyMesh

| Parametro | Descripcion | Unidad | Origen | Periodicidad | Uso QoE | Limitaciones |
|---|---|---|---|---|---|---|
| Device.WiFi.DataElements.Network.Controller.ID | Identificador del controlador | texto/MAC | simulador | 5 s | Identifica el gateway/controlador | En equipos reales depende del fabricante |
| Device.WiFi.DataElements.Network.Controller.Name | Nombre del controlador | texto | simulador | 5 s | Identificacion operativa | Puede no existir igual en CPE real |
| Device.WiFi.DataElements.Network.Controller.Status | Estado del controlador | texto | simulador | 5 s | Determina si la red esta operativa | Representacion simulada |
| Device.WiFi.DataElements.Network.Controller.AgentNumber | Numero de agentes EasyMesh | numero | simulador | 5 s | Indica topologia mesh | En real debe obtenerse del controlador |
| Device.WiFi.DataElements.Network.Controller.TotalClientNumber | Numero total de clientes WiFi | numero | simulador | 5 s | Indica carga global de la red | En real puede variar segun soporte TR-181 |

---

## 5. Metricas de agentes EasyMesh

| Parametro | Descripcion | Unidad | Origen | Periodicidad | Uso QoE | Limitaciones |
|---|---|---|---|---|---|---|
| Device.WiFi.DataElements.Network.Device.X.Name | Nombre del nodo EasyMesh | texto | simulador | 5 s | Identifica gateway o satelite | X representa indice del dispositivo |
| Device.WiFi.DataElements.Network.Device.X.ID | Identificador AL-MAC del nodo | MAC | simulador | 5 s | Correlacion de nodos | Puede variar en equipos reales |
| Device.WiFi.DataElements.Network.Device.X.Status | Estado del nodo | Online/Offline | simulador | 5 s | Detecta fallo de AP | Simulado |
| Device.WiFi.DataElements.Network.Device.X.IPv4Address | IP del nodo | IPv4 | simulador | 5 s | Diagnostico de gestion | Puede no estar disponible via TR-181 |
| Device.WiFi.DataElements.Network.Device.X.BackhaulType | Tipo de backhaul | texto | simulador | 5 s | Distingue Ethernet/WiFi | En real depende del vendor |
| Device.WiFi.DataElements.Network.Device.X.BackhaulRSSI | RSSI del backhaul | dBm | simulador | 5 s | Evalua calidad del enlace satelite-gateway | Solo aplica a backhaul WiFi |
| Device.WiFi.DataElements.Network.Device.X.BackhaulRateMbps | Tasa del backhaul | Mbps | simulador | 5 s | Evalua capacidad del backhaul | Valor estimado en simulacion |
| Device.WiFi.DataElements.Network.Device.X.BackhaulLatencyMs | Latencia del backhaul | ms | simulador | 5 s | Impacta QoE del cliente asociado al satelite | Estimada |
| Device.WiFi.DataElements.Network.Device.X.BackhaulPacketLossPercent | Perdida del backhaul | porcentaje | simulador | 5 s | Impacta QoE y estabilidad | Estimada |
| Device.WiFi.DataElements.Network.Device.X.RadioNumberOfEntries | Numero de radios del nodo | numero | simulador | 5 s | Describe capacidades radio | Puede cambiar en equipos reales |
| Device.WiFi.DataElements.Network.Device.X.STANumberOfEntries | Numero de clientes asociados al nodo | numero | simulador | 5 s | Indica carga por AP | Depende de visibilidad del CPE |

---

## 6. Metricas de radio WiFi

| Parametro | Descripcion | Unidad | Origen | Periodicidad | Uso QoE | Limitaciones |
|---|---|---|---|---|---|---|
| Device.WiFi.DataElements.Network.Device.X.Radio.Y.Name | Nombre de interfaz radio | texto | simulador | 5 s | Identifica radio | wlan0/wlan2 en simulacion |
| Device.WiFi.DataElements.Network.Device.X.Radio.Y.Status | Estado de la radio | Up/Down | simulador | 5 s | Detecta radio caida | Simulado |
| Device.WiFi.DataElements.Network.Device.X.Radio.Y.Band | Banda WiFi | GHz | simulador | 5 s | Distingue 2.4 GHz y 5 GHz | En real puede usar otro nombre |
| Device.WiFi.DataElements.Network.Device.X.Radio.Y.Channel | Canal WiFi | canal | simulador | 5 s | Diagnostico de interferencia | Simulado |
| Device.WiFi.DataElements.Network.Device.X.Radio.Y.Bandwidth | Ancho de canal | MHz | simulador | 5 s | Capacidad teorica | Simulado |
| Device.WiFi.DataElements.Network.Device.X.Radio.Y.OperatingStandards | Estandar WiFi | texto | simulador | 5 s | Identifica 802.11n/ac/ax | Simulado |
| Device.WiFi.DataElements.Network.Device.X.Radio.Y.TransmitPower | Potencia de transmision | dBm | simulador | 5 s | Influye en cobertura | Simulado |
| Device.WiFi.DataElements.Network.Device.X.Radio.Y.Utilization | Utilizacion radio | porcentaje | simulador | 5 s | Detecta saturacion | Estimada |
| Device.WiFi.DataElements.Network.Device.X.Radio.Y.ChannelUtilization | Utilizacion de canal | porcentaje | simulador | 5 s | Detecta saturacion/interferencia | Estimada |
| Device.WiFi.DataElements.Network.Device.X.Radio.Y.Noise | Ruido radio | dBm | simulador | 5 s | Detecta interferencia | Estimado |
| Device.WiFi.DataElements.Network.Device.X.Radio.Y.STANumberOfEntries | Clientes asociados a la radio | numero | simulador | 5 s | Carga por radio | Simulado |
| Device.WiFi.DataElements.Network.Device.X.Radio.Y.Stats.BytesSent | Bytes enviados por radio | bytes | simulador | 5 s | Trafico acumulado | Contador simulado |
| Device.WiFi.DataElements.Network.Device.X.Radio.Y.Stats.BytesReceived | Bytes recibidos por radio | bytes | simulador | 5 s | Trafico acumulado | Contador simulado |
| Device.WiFi.DataElements.Network.Device.X.Radio.Y.Stats.ErrorsSent | Errores de envio | numero | simulador | 5 s | Degradacion radio | Estimado |
| Device.WiFi.DataElements.Network.Device.X.Radio.Y.Stats.ErrorsReceived | Errores de recepcion | numero | simulador | 5 s | Degradacion radio | Estimado |

---

## 7. Metricas de cliente WiFi

| Parametro | Descripcion | Unidad | Origen | Periodicidad | Uso QoE | Limitaciones |
|---|---|---|---|---|---|---|
| Device.WiFi.DataElements.Network.Device.X.STA.Y.Hostname | Nombre del cliente | texto | simulador | 5 s | Identifica cliente | Simulado |
| Device.WiFi.DataElements.Network.Device.X.STA.Y.MACAddress | MAC del cliente | MAC | simulador | 5 s | Correlacion temporal | En real es clave para roaming |
| Device.WiFi.DataElements.Network.Device.X.STA.Y.IPAddress | IP del cliente | IPv4 | simulador | 5 s | Diagnostico | Puede cambiar por DHCP |
| Device.WiFi.DataElements.Network.Device.X.STA.Y.ConnectedDevice | AP al que esta asociado | texto | simulador | 5 s | Detecta roaming/punto ciego | Muy importante en mesh |
| Device.WiFi.DataElements.Network.Device.X.STA.Y.ConnectedRadio | Radio asociada | texto | simulador | 5 s | Relacion cliente-radio | Simulado |
| Device.WiFi.DataElements.Network.Device.X.STA.Y.ConnectedBand | Banda asociada | GHz | simulador | 5 s | Diagnostico de banda | Simulado |
| Device.WiFi.DataElements.Network.Device.X.STA.Y.SSID | SSID asociado | texto | simulador | 5 s | Contexto WiFi | Simulado |
| Device.WiFi.DataElements.Network.Device.X.STA.Y.BSSID | BSSID asociado | MAC | simulador | 5 s | Correlacion de AP | Importante en roaming |
| Device.WiFi.DataElements.Network.Device.X.STA.Y.SignalStrength | RSSI del cliente | dBm | simulador | 5 s | KPI principal de calidad radio | En real depende del AP que reporte |
| Device.WiFi.DataElements.Network.Device.X.STA.Y.RSSI | RSSI equivalente | dBm | simulador | 5 s | KPI principal de calidad radio | Duplicado util para compatibilidad |
| Device.WiFi.DataElements.Network.Device.X.STA.Y.Noise | Ruido percibido | dBm | simulador | 5 s | Calcula SNR | Estimado |
| Device.WiFi.DataElements.Network.Device.X.STA.Y.SNR | Relacion senal/ruido | dB | simulador | 5 s | Calidad de enlace | Derivado |
| Device.WiFi.DataElements.Network.Device.X.STA.Y.MCS | Modulation Coding Scheme | texto | simulador | 5 s | Capacidad radio | Aproximado |
| Device.WiFi.DataElements.Network.Device.X.STA.Y.LastDataDownlinkRate | Tasa PHY bajada | Mbps | simulador | 5 s | Capacidad enlace | Aproximada |
| Device.WiFi.DataElements.Network.Device.X.STA.Y.LastDataUplinkRate | Tasa PHY subida | Mbps | simulador | 5 s | Capacidad enlace | Aproximada |
| Device.WiFi.DataElements.Network.Device.X.STA.Y.ThroughputDownlinkMbps | Throughput bajada | Mbps | simulador | 5 s | KPI de servicio | Estimado |
| Device.WiFi.DataElements.Network.Device.X.STA.Y.ThroughputUplinkMbps | Throughput subida | Mbps | simulador | 5 s | KPI de servicio | Estimado |
| Device.WiFi.DataElements.Network.Device.X.STA.Y.LatencyMs | Latencia del cliente | ms | simulador | 5 s | KPI QoE | Estimada |
| Device.WiFi.DataElements.Network.Device.X.STA.Y.JitterMs | Jitter del cliente | ms | simulador | 5 s | KPI QoE | Estimado |
| Device.WiFi.DataElements.Network.Device.X.STA.Y.PacketLossPercent | Perdida de paquetes | porcentaje | simulador | 5 s | KPI QoE | Estimada |
| Device.WiFi.DataElements.Network.Device.X.STA.Y.RetryRatePercent | Tasa de reintentos | porcentaje | simulador | 5 s | Detecta interferencia/calidad radio | Estimada |
| Device.WiFi.DataElements.Network.Device.X.STA.Y.QoEScore | Puntuacion QoE | 0-100 | simulador | 5 s | Indicador final de experiencia | Calculado por laboratorio |
| Device.WiFi.DataElements.Network.Device.X.STA.Y.QoEState | Estado QoE | texto | simulador | 5 s | Clasificacion de experiencia | Calculado |
| Device.WiFi.DataElements.Network.Device.X.STA.Y.QoEReason | Motivo de QoE | texto | simulador | 5 s | Diagnostico | Calculado |
| Device.WiFi.DataElements.Network.Device.X.STA.Y.RoamCount | Numero de roamings | numero | simulador | 5 s | Analisis de movilidad | Solo aumenta en evento ClientSteering |

---

## 8. Metricas QoE resumidas

| Parametro | Descripcion | Unidad | Origen | Periodicidad | Uso QoE | Limitaciones |
|---|---|---|---|---|---|---|
| Device.X_SARA_QoE.Client | Cliente objetivo | texto | simulador | 5 s | Identifica cliente analizado | Extension propia |
| Device.X_SARA_QoE.ConnectedAP | AP actual del cliente | texto | simulador | 5 s | Detecta punto ciego/roaming | Extension propia |
| Device.X_SARA_QoE.SignalStrength | RSSI resumido | dBm | simulador | 5 s | KPI principal | Extension propia |
| Device.X_SARA_QoE.LatencyMs | Latencia resumida | ms | simulador | 5 s | KPI QoE | Extension propia |
| Device.X_SARA_QoE.PacketLossPercent | Perdida resumida | porcentaje | simulador | 5 s | KPI QoE | Extension propia |
| Device.X_SARA_QoE.QoEScore | Puntuacion QoE resumida | 0-100 | simulador | 5 s | Indicador principal | Calculado |
| Device.X_SARA_QoE.QoEState | Estado QoE resumido | texto | simulador | 5 s | Clasificacion | Calculado |
| Device.X_SARA_QoE.QoENumeric | Estado QoE numerico | numero | simulador | 5 s | Visualizacion en Grafana | Calculado |
| Device.X_SARA_QoE.Reason | Motivo de degradacion | texto | simulador | 5 s | Diagnostico | Calculado |

---

## 9. Eventos EasyMesh

| Parametro | Descripcion | Unidad | Origen | Periodicidad | Uso QoE | Limitaciones |
|---|---|---|---|---|---|---|
| Device.WiFi.DataElements.Network.Event.1.Type | Tipo de evento | texto | simulador | 5 s | Detecta degradacion o roaming | Simulado |
| Device.WiFi.DataElements.Network.Event.1.ClientMAC | MAC del cliente afectado | MAC | simulador | 5 s | Correlacion temporal | Simulado |
| Device.WiFi.DataElements.Network.Event.1.FromDevice | Nodo origen | texto | simulador | 5 s | Analiza roaming | Simulado |
| Device.WiFi.DataElements.Network.Event.1.ToDevice | Nodo destino | texto | simulador | 5 s | Analiza roaming | Simulado |
| Device.WiFi.DataElements.Network.Event.1.Result | Resultado del evento | texto | simulador | 5 s | Diagnostico | Simulado |
| Device.WiFi.DataElements.Network.Event.1.Reason | Motivo del evento | texto | simulador | 5 s | Explicacion tecnica | Simulado |
| Device.WiFi.DataElements.Network.Event.1.TimestampUTC | Marca temporal | fecha UTC | simulador | 5 s | Correlacion temporal | Depende del reloj del host |
| Device.WiFi.DataElements.Network.Event.1.SteeringCount | Numero de steerings | numero | simulador | 5 s | Mide roaming acumulado | Simulado |

Tipos de evento usados en el laboratorio:

| Evento | Significado |
|---|---|
| None | Estado estable sin evento relevante |
| LowRSSI | Cliente con RSSI bajo y candidato a steering |
| ClientSteering | Cambio de AP del cliente MOVIL_SARA |
| HighInterference | Degradacion por interferencia |
| HighUtilization | Saturacion de radio |
| BackhaulDegraded | Degradacion del enlace backhaul |
| APFailure | Fallo del punto de acceso satelite |

---

## 10. Relacion con Prometheus y Grafana

Las metricas TR-181 se visualizan por tres rutas:

### 10.1 Ruta directa del simulador

Metricas Prometheus:

- easymesh_sim_client_signal_dbm
- easymesh_sim_client_qoe_score
- easymesh_sim_client_latency_ms
- easymesh_sim_client_jitter_ms
- easymesh_sim_client_packet_loss_percent
- easymesh_sim_radio_utilization_percent
- easymesh_sim_backhaul_rssi_dbm
- easymesh_sim_event_info

### 10.2 Ruta CSV historico

Metricas Prometheus:

- easymesh_csv_exporter_up
- easymesh_csv_snapshots_total
- easymesh_csv_tr181_numeric_value
- easymesh_csv_tr181_info
- easymesh_csv_prometheus_metric_value

### 10.3 Ruta GenieACS / TR-069

Metricas Prometheus:

- genieacs_up
- easymesh_agent_number
- easymesh_total_client_number
- easymesh_event_info
- easymesh_radio_utilization_avg_percent
- easymesh_backhaul_rssi_dbm
- easymesh_client_signal_strength_dbm
- easymesh_client_qoe_state

---

## 11. Periodicidad

En el laboratorio simulado:

- el simulador actualiza el estado cada 5 segundos;
- el CSV TR-181 se reescribe cada 5 segundos;
- Prometheus scrapea los exporters cada 5 segundos;
- los CSV historicos se guardan cuando se ejecuta el script de evidencia.

En un laboratorio real, la periodicidad dependera de:

- configuracion del CPE;
- periodic inform de TR-069;
- soporte de parametros TR-181;
- capacidad de polling desde GenieACS;
- carga aceptable sobre el equipo real.

---

## 12. Limitaciones

Limitaciones del laboratorio simulado:

- No implementa una pila EasyMesh certificada.
- No implementa el plano de control IEEE 1905.1 completo.
- No mide radiofrecuencia real.
- Las metricas de latencia, jitter, perdida, retry y throughput son estimadas.
- Los parametros X_SARA son extensiones propias del laboratorio.
- La disponibilidad de parametros TR-181 en dispositivos reales dependera del fabricante.
- El mecanismo bulk-data se aproxima mediante CSV TR-181/DataElements y exporters, no mediante una implementacion completa TR-369/USP.

---

## 13. Uso en el TFG

Este catalogo sirve para justificar:

- que indicadores KPI se han definido;
- que parametros TR-181/DataElements se usan;
- que unidades tienen;
- que componente los genera;
- como se visualizan en Prometheus y Grafana;
- como se analiza el punto ciego de visibilidad durante roaming;
- que diferencias habra al pasar del simulador a dispositivos reales.
