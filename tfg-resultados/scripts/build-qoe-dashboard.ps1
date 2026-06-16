# build-qoe-dashboard.ps1
# Genera un dashboard HTML limpio a partir de qoe_summary_auto.csv.
# Version sin acentos ni caracteres especiales para evitar problemas de codificacion.

$BaseLab = "C:\EasyMesh-Lab"
$CsvPath = Join-Path $BaseLab "tfg-resultados\qoe\qoe_summary_auto.csv"
$OutHtml = Join-Path $BaseLab "tfg-resultados\qoe\qoe_dashboard.html"

if (!(Test-Path $CsvPath)) {
    throw "No existe el CSV: $CsvPath. Ejecuta antes collect-qoe-from-genieacs.ps1"
}

$data = Import-Csv $CsvPath

function HtmlEncode {
    param($Value)

    if ($null -eq $Value) {
        return ""
    }

    return ([string]$Value).
        Replace("&", "&amp;").
        Replace("<", "&lt;").
        Replace(">", "&gt;").
        Replace('"', "&quot;")
}

function Get-QoeClass {
    param([string]$State)

    switch ($State) {
        "Buena" { return "qoe-good" }
        "Media" { return "qoe-mid" }
        "Degradada" { return "qoe-bad" }
        "Recuperada" { return "qoe-recovered" }
        default { return "qoe-unknown" }
    }
}

function Get-ScenarioTitle {
    param([string]$Scenario)

    switch ($Scenario) {
        "normal" { return "Escenario normal" }
        "cliente_lejos" { return "Cliente lejos" }
        "steering" { return "Steering" }
        default { return $Scenario }
    }
}

$normal = $data | Where-Object { $_.scenario -eq "normal" } | Select-Object -First 1
$lejos = $data | Where-Object { $_.scenario -eq "cliente_lejos" } | Select-Object -First 1
$steering = $data | Where-Object { $_.scenario -eq "steering" } | Select-Object -First 1

$improvement = "N/A"

if ($lejos -and $steering) {
    $improvementValue = [double]$steering.signal_strength_dbm - [double]$lejos.signal_strength_dbm
    $improvement = "$improvementValue dB"
}

$tableRows = ($data | ForEach-Object {
    $class = Get-QoeClass $_.qoe_state

    "<tr>
        <td>$(HtmlEncode $_.scenario)</td>
        <td>$(HtmlEncode $_.client)</td>
        <td>$(HtmlEncode $_.connected_ap)</td>
        <td>$(HtmlEncode $_.signal_strength_dbm) dBm</td>
        <td>$(HtmlEncode $_.radio_utilization_avg_pct) %</td>
        <td>$(HtmlEncode $_.backhaul_type)</td>
        <td>$(HtmlEncode $_.backhaul_rssi_dbm)</td>
        <td>$(HtmlEncode $_.event_type)</td>
        <td>$(HtmlEncode $_.event_result)</td>
        <td><span class='badge $class'>$(HtmlEncode $_.qoe_state)</span></td>
    </tr>"
}) -join "`n"

$cardsHtml = ($data | ForEach-Object {
    $class = Get-QoeClass $_.qoe_state
    $title = Get-ScenarioTitle $_.scenario

    "<article class='scenario-card'>
        <div class='scenario-card-header'>
            <h3>$title</h3>
            <span class='badge $class'>$(HtmlEncode $_.qoe_state)</span>
        </div>
        <div class='metric-row'><strong>Cliente:</strong><span>$(HtmlEncode $_.client)</span></div>
        <div class='metric-row'><strong>AP asociado:</strong><span>$(HtmlEncode $_.connected_ap)</span></div>
        <div class='metric-row'><strong>SignalStrength:</strong><span>$(HtmlEncode $_.signal_strength_dbm) dBm</span></div>
        <div class='metric-row'><strong>Utilizacion media radio:</strong><span>$(HtmlEncode $_.radio_utilization_avg_pct) %</span></div>
        <div class='metric-row'><strong>Evento:</strong><span>$(HtmlEncode $_.event_type) / $(HtmlEncode $_.event_result)</span></div>
    </article>"
}) -join "`n"

$jsData = $data |
    Select-Object scenario,client,connected_ap,device_index,sta_index,signal_strength_dbm,radio_utilization_avg_pct,backhaul_type,backhaul_rssi_dbm,event_type,event_from,event_to,event_result,qoe_state |
    ConvertTo-Json -Depth 4

$html = @"
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<title>Dashboard QoE EasyMesh - GenieACS TR-181</title>
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<style>
    :root {
        --bg: #0f172a;
        --panel: #111827;
        --panel2: #1f2937;
        --text: #e5e7eb;
        --muted: #9ca3af;
        --line: #334155;
        --good: #22c55e;
        --mid: #eab308;
        --bad: #ef4444;
        --rec: #38bdf8;
        --accent: #a78bfa;
    }

    * {
        box-sizing: border-box;
    }

    body {
        margin: 0;
        font-family: Arial, Helvetica, sans-serif;
        background: linear-gradient(135deg, #020617, #111827);
        color: var(--text);
    }

    header {
        padding: 32px 40px;
        border-bottom: 1px solid var(--line);
        background: rgba(15, 23, 42, 0.95);
    }

    header h1 {
        margin: 0 0 8px 0;
        font-size: 32px;
    }

    header p {
        margin: 0;
        color: var(--muted);
        max-width: 1000px;
        line-height: 1.5;
    }

    main {
        padding: 32px 40px;
        display: grid;
        gap: 28px;
    }

    section {
        background: rgba(17, 24, 39, 0.92);
        border: 1px solid var(--line);
        border-radius: 18px;
        padding: 24px;
        box-shadow: 0 20px 50px rgba(0,0,0,0.25);
    }

    h2 {
        margin-top: 0;
        font-size: 24px;
    }

    .summary {
        display: grid;
        grid-template-columns: repeat(4, minmax(0, 1fr));
        gap: 16px;
    }

    .summary-box {
        background: var(--panel2);
        border: 1px solid var(--line);
        border-radius: 16px;
        padding: 18px;
    }

    .summary-box h3 {
        margin: 0 0 8px 0;
        font-size: 15px;
        color: var(--muted);
    }

    .summary-box p {
        margin: 0;
        font-size: 22px;
        font-weight: bold;
    }

    .grid-3 {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(360px, 1fr));
        gap: 18px;
    }

    .scenario-card {
        background: var(--panel2);
        border: 1px solid var(--line);
        border-radius: 16px;
        padding: 20px;
        min-height: 230px;
    }

    .scenario-card-header {
        display: flex;
        justify-content: space-between;
        gap: 12px;
        align-items: center;
        margin-bottom: 12px;
    }

    .scenario-card h3 {
        margin: 0;
    }

    .metric-row {
        display: grid;
        grid-template-columns: 185px 1fr;
        gap: 12px;
        margin: 10px 0;
        line-height: 1.35;
    }

    .metric-row strong {
        color: var(--text);
        white-space: nowrap;
    }

    .metric-row span {
        color: var(--muted);
        overflow-wrap: anywhere;
    }

    .badge {
        display: inline-block;
        padding: 6px 10px;
        border-radius: 999px;
        font-weight: bold;
        font-size: 13px;
        color: #020617;
        white-space: nowrap;
    }

    .qoe-good { background: var(--good); }
    .qoe-mid { background: var(--mid); }
    .qoe-bad { background: var(--bad); color: white; }
    .qoe-recovered { background: var(--rec); }
    .qoe-unknown { background: var(--muted); }

    .dashboard {
        display: grid;
        grid-template-columns: 1.4fr 1fr;
        gap: 24px;
        align-items: stretch;
    }

    .mesh-map {
        position: relative;
        min-height: 420px;
        background:
            radial-gradient(circle at 20% 50%, rgba(34,197,94,0.18), transparent 24%),
            radial-gradient(circle at 78% 50%, rgba(56,189,248,0.18), transparent 24%),
            #020617;
        border: 1px solid var(--line);
        border-radius: 18px;
        overflow: hidden;
    }

    .node {
        position: absolute;
        width: 160px;
        padding: 14px;
        border-radius: 14px;
        background: rgba(31,41,55,0.96);
        border: 1px solid var(--line);
        text-align: center;
        box-shadow: 0 12px 24px rgba(0,0,0,0.35);
    }

    .controller {
        top: 30px;
        left: 50%;
        transform: translateX(-50%);
        border-color: var(--accent);
    }

    .ap1 {
        left: 13%;
        top: 180px;
        border-color: var(--good);
    }

    .ap2 {
        right: 13%;
        top: 180px;
        border-color: var(--rec);
    }

    .client {
        position: absolute;
        width: 130px;
        padding: 12px;
        border-radius: 999px;
        background: #f97316;
        color: #111827;
        font-weight: bold;
        text-align: center;
        transition: all 0.7s ease;
        box-shadow: 0 0 28px rgba(249,115,22,0.55);
        z-index: 4;
    }

    .client.normal {
        left: 18%;
        top: 315px;
    }

    .client.cliente_lejos {
        left: 25%;
        top: 345px;
        background: #ef4444;
        color: white;
        animation: pulseBad 1s infinite alternate;
    }

    .client.steering {
        left: 69%;
        top: 315px;
        background: #38bdf8;
        color: #020617;
    }

    @keyframes pulseBad {
        from { transform: scale(1); box-shadow: 0 0 20px rgba(239,68,68,0.45); }
        to { transform: scale(1.08); box-shadow: 0 0 40px rgba(239,68,68,0.85); }
    }

    .link {
        position: absolute;
        height: 2px;
        background: rgba(148,163,184,0.5);
        transform-origin: left center;
    }

    .link.ctrl-ap1 {
        width: 240px;
        left: 38%;
        top: 150px;
        transform: rotate(155deg);
    }

    .link.ctrl-ap2 {
        width: 240px;
        left: 50%;
        top: 150px;
        transform: rotate(25deg);
    }

    .info-panel {
        background: #020617;
        border: 1px solid var(--line);
        border-radius: 18px;
        padding: 22px;
    }

    .info-panel code {
        display: block;
        white-space: pre-wrap;
        background: #111827;
        color: #d1d5db;
        border: 1px solid var(--line);
        padding: 14px;
        border-radius: 12px;
        margin-top: 12px;
        font-size: 13px;
    }

    .buttons {
        display: flex;
        gap: 10px;
        flex-wrap: wrap;
        margin-bottom: 16px;
    }

    button {
        cursor: pointer;
        border: 1px solid var(--line);
        background: #1f2937;
        color: var(--text);
        border-radius: 999px;
        padding: 10px 14px;
        font-weight: bold;
    }

    button.active {
        background: var(--accent);
        color: #020617;
    }

    .metric-big {
        font-size: 42px;
        font-weight: bold;
        margin: 8px 0;
    }

    .muted {
        color: var(--muted);
    }

    table {
        width: 100%;
        border-collapse: collapse;
        overflow: hidden;
        border-radius: 12px;
    }

    th, td {
        padding: 12px 10px;
        border-bottom: 1px solid var(--line);
        text-align: left;
        font-size: 14px;
    }

    th {
        background: #020617;
        color: #c4b5fd;
    }

    tr:hover {
        background: rgba(255,255,255,0.04);
    }

    @media (max-width: 1000px) {
        .grid-3, .dashboard, .summary {
            grid-template-columns: 1fr;
        }

        header, main {
            padding: 22px;
        }
    }
</style>
</head>
<body>

<header>
    <h1>Dashboard QoE EasyMesh - GenieACS / TR-181</h1>
    <p>
        Cuadro de mando generado automaticamente a partir de qoe_summary_auto.csv.
        Resume la evolucion de MOVIL_SARA en los escenarios normal, cliente_lejos y steering.
    </p>
</header>

<main>

<section>
    <h2>Resumen de la validacion</h2>
    <div class="summary">
        <div class="summary-box">
            <h3>Cliente analizado</h3>
            <p>MOVIL_SARA</p>
        </div>
        <div class="summary-box">
            <h3>Escenarios</h3>
            <p>3</p>
        </div>
        <div class="summary-box">
            <h3>Mejora tras steering</h3>
            <p>$improvement</p>
        </div>
        <div class="summary-box">
            <h3>Resultado final</h3>
            <p>QoE recuperada</p>
        </div>
    </div>
</section>

<section>
    <h2>Escenarios QoE</h2>
    <div class="grid-3">
        $cardsHtml
    </div>
</section>

<section>
    <h2>Mapa interactivo de escenarios</h2>
    <div class="dashboard">
        <div class="mesh-map">
            <div class="link ctrl-ap1"></div>
            <div class="link ctrl-ap2"></div>

            <div class="node controller">
                <strong>GW_MASTER</strong><br>
                Controller
            </div>

            <div class="node ap1">
                <strong>AP_SALON</strong><br>
                Device.1
            </div>

            <div class="node ap2">
                <strong>AP_DORMITORIO</strong><br>
                Device.2
            </div>

            <div id="clientDot" class="client normal">
                MOVIL_SARA
            </div>
        </div>

        <div class="info-panel">
            <div class="buttons">
                <button id="btn-normal" onclick="selectScenario('normal')">Normal</button>
                <button id="btn-cliente_lejos" onclick="selectScenario('cliente_lejos')">Cliente lejos</button>
                <button id="btn-steering" onclick="selectScenario('steering')">Steering</button>
            </div>

            <p class="muted">Escenario seleccionado</p>
            <h2 id="scenarioTitle">Normal</h2>

            <p class="muted">SignalStrength</p>
            <div id="signalValue" class="metric-big">-52 dBm</div>

            <p><strong>AP asociado:</strong> <span id="apValue">AP_SALON</span></p>
            <p><strong>Utilizacion media radio:</strong> <span id="utilValue">34 %</span></p>
            <p><strong>Evento:</strong> <span id="eventValue">None / NoEvent</span></p>
            <p><strong>QoE:</strong> <span id="qoeValue" class="badge qoe-good">Buena</span></p>

            <code id="pathValue">Device.WiFi.DataElements.Network.Device.1.STA.2.SignalStrength</code>
        </div>
    </div>
</section>

<section>
    <h2>Tabla normalizada de metricas QoE</h2>
    <table>
        <thead>
            <tr>
                <th>Escenario</th>
                <th>Cliente</th>
                <th>AP asociado</th>
                <th>SignalStrength</th>
                <th>Utilizacion media</th>
                <th>Backhaul</th>
                <th>Backhaul RSSI</th>
                <th>Evento</th>
                <th>Resultado</th>
                <th>QoE</th>
            </tr>
        </thead>
        <tbody>
            $tableRows
        </tbody>
    </table>
</section>

<section>
    <h2>Interpretacion tecnica</h2>
    <p>
        En el escenario normal, MOVIL_SARA se encuentra conectado a AP_SALON con una senal de -52 dBm,
        considerada buena dentro de las reglas QoE definidas.
    </p>
    <p>
        En el escenario cliente_lejos, el mismo cliente permanece en AP_SALON pero su senal cae hasta -74 dBm.
        Esta condicion se interpreta como QoE degradada y se asocia al evento LowRSSI con resultado CandidateForSteering.
    </p>
    <p>
        En el escenario steering, MOVIL_SARA pasa a estar asociado a AP_DORMITORIO, mejorando su senal hasta -49 dBm.
        El evento ClientSteering con resultado Success confirma que la operacion de cambio de AP se ha completado correctamente.
    </p>
</section>

</main>

<script>
const scenarioData = $jsData;

function qoeClass(state) {
    if (state === "Buena") return "badge qoe-good";
    if (state === "Media") return "badge qoe-mid";
    if (state === "Degradada") return "badge qoe-bad";
    if (state === "Recuperada") return "badge qoe-recovered";
    return "badge qoe-unknown";
}

function scenarioTitle(scenario) {
    if (scenario === "normal") return "Escenario normal";
    if (scenario === "cliente_lejos") return "Cliente lejos";
    if (scenario === "steering") return "Steering";
    return scenario;
}

function selectScenario(scenario) {
    const row = scenarioData.find(x => x.scenario === scenario);
    if (!row) return;

    document.querySelectorAll("button").forEach(btn => btn.classList.remove("active"));
    const btn = document.getElementById("btn-" + scenario);
    if (btn) btn.classList.add("active");

    const dot = document.getElementById("clientDot");
    dot.className = "client " + scenario;

    document.getElementById("scenarioTitle").textContent = scenarioTitle(row.scenario);
    document.getElementById("signalValue").textContent = row.signal_strength_dbm + " dBm";
    document.getElementById("apValue").textContent = row.connected_ap;
    document.getElementById("utilValue").textContent = row.radio_utilization_avg_pct + " %";
    document.getElementById("eventValue").textContent = row.event_type + " / " + row.event_result;

    const qoe = document.getElementById("qoeValue");
    qoe.textContent = row.qoe_state;
    qoe.className = qoeClass(row.qoe_state);

    document.getElementById("pathValue").textContent =
        "Device.WiFi.DataElements.Network.Device." +
        row.device_index +
        ".STA." +
        row.sta_index +
        ".SignalStrength";
}

selectScenario("normal");
</script>

</body>
</html>
"@

[System.IO.File]::WriteAllText($OutHtml, $html, [System.Text.UTF8Encoding]::new($false))

Write-Host "Dashboard generado en:"
Write-Host $OutHtml