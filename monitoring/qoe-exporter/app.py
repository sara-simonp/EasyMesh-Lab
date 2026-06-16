import json
import time
import urllib.parse
import urllib.request
from datetime import datetime
from http.server import BaseHTTPRequestHandler, HTTPServer

GENIEACS_URL = "http://genieacs-acs:7557"
DEVICE_ID = "535241-EasyMeshVirtualCPE-200001"
CLIENT_NAME = "MOVIL_SARA"


def get_prop(obj, name):
    if not isinstance(obj, dict):
        return None
    return obj.get(name)


def get_leaf_value(node):
    if isinstance(node, dict):
        return node.get("_value")
    return None


def get_leaf_timestamp(node):
    if not isinstance(node, dict):
        return 0

    ts = node.get("_timestamp")
    if not ts:
        return 0

    try:
        return datetime.fromisoformat(str(ts).replace("Z", "+00:00")).timestamp()
    except Exception:
        return 0


def get_path(obj, path):
    current = obj
    for part in path.split("."):
        if not isinstance(current, dict):
            return None
        current = current.get(part)
        if current is None:
            return None
    return current


def numeric_children(obj):
    if not isinstance(obj, dict):
        return []

    items = []
    for key, value in obj.items():
        if str(key).isdigit():
            items.append((int(key), str(key), value))

    return sorted(items, key=lambda x: x[0])


def qoe_state_to_number(state):
    mapping = {
        "Desconocida": 0,
        "Degradada": 1,
        "Media": 2,
        "Buena": 3,
        "Recuperada": 4,
    }
    return mapping.get(state, 0)


def classify_qoe(signal, event_type, event_result):
    if event_type == "ClientSteering" and event_result == "Success":
        return "Recuperada"

    if event_type == "LowRSSI" and event_result == "CandidateForSteering":
        return "Degradada"

    if signal is None:
        return "Desconocida"

    try:
        signal = float(signal)
    except Exception:
        return "Desconocida"

    if signal > -60:
        return "Buena"
    if signal > -70:
        return "Media"
    return "Degradada"


def fetch_device():
    query = urllib.parse.quote(json.dumps({"_id": DEVICE_ID}))
    url = f"{GENIEACS_URL}/devices/?query={query}"

    with urllib.request.urlopen(url, timeout=5) as response:
        data = json.loads(response.read().decode("utf-8"))

    if isinstance(data, list) and data:
        return data[0]

    raise RuntimeError("No device returned from GenieACS")


def avg_radio_utilization(ap_obj):
    radio_obj = get_prop(ap_obj, "Radio")
    values = []

    for _, _, radio in numeric_children(radio_obj):
        util = get_leaf_value(get_prop(radio, "Utilization"))
        if util is not None:
            try:
                values.append(float(util))
            except Exception:
                pass

    if not values:
        return None

    return round(sum(values) / len(values), 2)


def prometheus_escape(value):
    if value is None:
        return ""
    return str(value).replace("\\", "\\\\").replace('"', '\\"').replace("\n", " ")


def metric_headers():
    return [
        "# HELP genieacs_up Whether GenieACS API is reachable",
        "# TYPE genieacs_up gauge",

        "# HELP easymesh_agent_number Number of EasyMesh agents",
        "# TYPE easymesh_agent_number gauge",

        "# HELP easymesh_total_client_number Number of WiFi clients",
        "# TYPE easymesh_total_client_number gauge",

        "# HELP easymesh_event_info Current EasyMesh event",
        "# TYPE easymesh_event_info gauge",

        "# HELP easymesh_radio_utilization_avg_percent Average radio utilization by AP",
        "# TYPE easymesh_radio_utilization_avg_percent gauge",

        "# HELP easymesh_backhaul_rssi_dbm Backhaul RSSI by AP",
        "# TYPE easymesh_backhaul_rssi_dbm gauge",

        "# HELP easymesh_client_signal_strength_dbm Current client signal strength in dBm",
        "# TYPE easymesh_client_signal_strength_dbm gauge",

        "# HELP easymesh_client_qoe_state Numeric QoE state: 0 unknown, 1 degraded, 2 medium, 3 good, 4 recovered",
        "# TYPE easymesh_client_qoe_state gauge",

        "# HELP easymesh_target_client_found Whether target client was found",
        "# TYPE easymesh_target_client_found gauge",

        "# HELP easymesh_exporter_last_scrape_timestamp_seconds Last successful scrape timestamp",
        "# TYPE easymesh_exporter_last_scrape_timestamp_seconds gauge",
    ]


def build_metrics():
    device = fetch_device()

    network = get_path(device, "Device.WiFi.DataElements.Network")
    if network is None:
        raise RuntimeError("Device.WiFi.DataElements.Network not found")

    controller = get_prop(network, "Controller")
    devices = get_prop(network, "Device")
    event = get_path(network, "Event.1")

    agent_number = get_leaf_value(get_prop(controller, "AgentNumber"))
    total_client_number = get_leaf_value(get_prop(controller, "TotalClientNumber"))

    event_type = get_leaf_value(get_prop(event, "Type"))
    event_from = get_leaf_value(get_prop(event, "FromDevice"))
    event_to = get_leaf_value(get_prop(event, "ToDevice"))
    event_result = get_leaf_value(get_prop(event, "Result"))

    lines = metric_headers()
    lines.append("genieacs_up 1")

    if agent_number is not None:
        lines.append(f"easymesh_agent_number {agent_number}")

    if total_client_number is not None:
        lines.append(f"easymesh_total_client_number {total_client_number}")

    lines.append(
        'easymesh_event_info{type="%s",from_device="%s",to_device="%s",result="%s"} 1'
        % (
            prometheus_escape(event_type),
            prometheus_escape(event_from),
            prometheus_escape(event_to),
            prometheus_escape(event_result),
        )
    )

    client_candidates = []

    for _, device_index, ap_obj in numeric_children(devices):
        ap_name = get_leaf_value(get_prop(ap_obj, "Name"))
        backhaul_type = get_leaf_value(get_prop(ap_obj, "BackhaulType"))
        backhaul_rssi = get_leaf_value(get_prop(ap_obj, "BackhaulRSSI"))
        util_avg = avg_radio_utilization(ap_obj)

        if util_avg is not None:
            lines.append(
                'easymesh_radio_utilization_avg_percent{ap="%s",device_index="%s"} %s'
                % (
                    prometheus_escape(ap_name),
                    device_index,
                    util_avg,
                )
            )

        if backhaul_rssi is not None:
            try:
                float(backhaul_rssi)
                lines.append(
                    'easymesh_backhaul_rssi_dbm{ap="%s",backhaul_type="%s",device_index="%s"} %s'
                    % (
                        prometheus_escape(ap_name),
                        prometheus_escape(backhaul_type),
                        device_index,
                        backhaul_rssi,
                    )
                )
            except Exception:
                pass

        sta_obj = get_prop(ap_obj, "STA")

        for _, sta_index, sta in numeric_children(sta_obj):
            hostname_node = get_prop(sta, "Hostname")
            hostname = get_leaf_value(hostname_node)

            if hostname != CLIENT_NAME:
                continue

            signal_node = get_prop(sta, "SignalStrength")
            connected_node = get_prop(sta, "ConnectedDevice")

            signal = get_leaf_value(signal_node)
            connected_ap = get_leaf_value(connected_node) or ap_name

            latest_ts = max(
                get_leaf_timestamp(hostname_node),
                get_leaf_timestamp(signal_node),
                get_leaf_timestamp(connected_node),
            )

            client_candidates.append({
                "timestamp": latest_ts,
                "hostname": hostname,
                "signal": signal,
                "connected_ap": connected_ap,
                "device_index": device_index,
                "sta_index": sta_index,
                "ap_name": ap_name,
            })

    selected_client = None

    # Si el evento actual es ClientSteering, priorizamos el AP destino.
    if event_type == "ClientSteering" and event_to:
        steering_candidates = [
            c for c in client_candidates
            if c["connected_ap"] == event_to or c["ap_name"] == event_to
        ]
        if steering_candidates:
            selected_client = sorted(
                steering_candidates,
                key=lambda c: c["timestamp"],
                reverse=True
            )[0]

    # Si no hay candidato por evento, usamos el valor mas reciente.
    if selected_client is None and client_candidates:
        selected_client = sorted(
            client_candidates,
            key=lambda c: c["timestamp"],
            reverse=True
        )[0]

    if selected_client is not None:
        signal = selected_client["signal"]
        qoe_state = classify_qoe(signal, event_type, event_result)
        qoe_value = qoe_state_to_number(qoe_state)

        if signal is not None:
            lines.append(
                'easymesh_client_signal_strength_dbm{client="%s",ap="%s",device_index="%s",sta_index="%s"} %s'
                % (
                    prometheus_escape(selected_client["hostname"]),
                    prometheus_escape(selected_client["connected_ap"]),
                    selected_client["device_index"],
                    selected_client["sta_index"],
                    signal,
                )
            )

        lines.append(
            'easymesh_client_qoe_state{client="%s",ap="%s",state="%s"} %s'
            % (
                prometheus_escape(selected_client["hostname"]),
                prometheus_escape(selected_client["connected_ap"]),
                prometheus_escape(qoe_state),
                qoe_value,
            )
        )

        lines.append("easymesh_target_client_found 1")
    else:
        lines.append("easymesh_target_client_found 0")

    lines.append(f"easymesh_exporter_last_scrape_timestamp_seconds {int(time.time())}")

    return "\n".join(lines) + "\n"


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path not in ["/", "/metrics"]:
            self.send_response(404)
            self.end_headers()
            return

        try:
            body = build_metrics()
        except Exception as exc:
            body = (
                "# HELP genieacs_up Whether GenieACS API is reachable\n"
                "# TYPE genieacs_up gauge\n"
                "genieacs_up 0\n"
                '# exporter_error{message="%s"} 1\n'
                % prometheus_escape(exc)
            )

        encoded = body.encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "text/plain; version=0.0.4; charset=utf-8")
        self.send_header("Content-Length", str(len(encoded)))
        self.end_headers()
        self.wfile.write(encoded)

    def log_message(self, format, *args):
        return


if __name__ == "__main__":
    server = HTTPServer(("0.0.0.0", 9108), Handler)
    print("QoE exporter listening on :9108")
    server.serve_forever()