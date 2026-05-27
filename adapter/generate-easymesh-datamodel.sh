#!/bin/bash
set -e

OUT="/data/data_model_easymesh.csv"
BML_OUT="/data/bml_conn_map_para_tr069.txt"

echo "Esperando a easymesh-simulator..."

until docker ps --format "{{.Names}}" | grep -q "^easymesh-simulator$"; do
  echo "easymesh-simulator todav?a no est? arrancado..."
  sleep 5
done

echo "Esperando a que beerocks_cli responda..."

until docker exec easymesh-simulator bash -lc "export LD_LIBRARY_PATH=/opt/prplmesh/build/install/lib:/opt/prplmesh/build/out/lib:/usr/local/lib:/usr/lib; cd /opt/prplmesh/build/install/bin; ./beerocks_cli -c bml_conn_map" > "$BML_OUT" 2>/tmp/bml_error.log; do
  echo "beerocks_cli todav?a no responde..."
  sleep 5
done

echo "Mapa BML obtenido:"
cat "$BML_OUT"

GW_NAME=$(grep "GW_BRIDGE:" "$BML_OUT" | sed -E 's/.*name: ([^,]+), mac: ([^,]+).*/\1/' | head -n 1)
GW_MAC=$(grep "GW_BRIDGE:" "$BML_OUT" | sed -E 's/.*name: ([^,]+), mac: ([^,]+).*/\2/' | head -n 1)

if [ -z "$GW_NAME" ]; then
  GW_NAME="GW_MASTER"
fi

if [ -z "$GW_MAC" ]; then
  GW_MAC="00:00:00:00:00:00"
fi

RADIO_LINES=$(grep "RADIO:" "$BML_OUT" || true)
RADIO_COUNT=$(echo "$RADIO_LINES" | grep -c "RADIO:" || true)

if [ "$RADIO_COUNT" = "0" ]; then
  echo "ERROR: no se han detectado radios en el mapa BML."
  exit 1
fi

echo "Generando modelo TR-069 EasyMesh en $OUT"

cat > "$OUT" <<EOF
Parameter,Object,Writable,Value,Value type
InternetGatewayDevice,true,false,,
InternetGatewayDevice.DeviceInfo,true,false,,
InternetGatewayDevice.DeviceInfo.Manufacturer,false,false,Sara-Lab,xsd:string
InternetGatewayDevice.DeviceInfo.ManufacturerOUI,false,false,535241,xsd:string
InternetGatewayDevice.DeviceInfo.ProductClass,false,false,EasyMeshVirtualCPE,xsd:string
InternetGatewayDevice.DeviceInfo.SerialNumber,false,false,200001,xsd:string
InternetGatewayDevice.DeviceInfo.SoftwareVersion,false,false,prplMesh-Docker,xsd:string
InternetGatewayDevice.ManagementServer,true,false,,
InternetGatewayDevice.ManagementServer.PeriodicInformEnable,false,true,true,xsd:boolean
InternetGatewayDevice.ManagementServer.PeriodicInformInterval,false,true,60,xsd:unsignedInt
InternetGatewayDevice.X_SARA_EasyMesh,true,false,,
InternetGatewayDevice.X_SARA_EasyMesh.ControllerStatus,false,false,Running,xsd:string
InternetGatewayDevice.X_SARA_EasyMesh.GatewayName,false,false,$GW_NAME,xsd:string
InternetGatewayDevice.X_SARA_EasyMesh.GatewayMac,false,false,$GW_MAC,xsd:string
InternetGatewayDevice.X_SARA_EasyMesh.RadioNumber,false,false,$RADIO_COUNT,xsd:unsignedInt
InternetGatewayDevice.X_SARA_EasyMesh.Source,false,false,beerocks_cli_bml_conn_map,xsd:string
InternetGatewayDevice.X_SARA_EasyMesh.Radio,true,false,,
EOF

i=1

echo "$RADIO_LINES" | while read -r line; do
  IFACE=$(echo "$line" | sed -E 's/.*RADIO: ([^ ]+) mac:.*/\1/')
  MAC=$(echo "$line" | sed -E 's/.*mac: ([^,]+), ch:.*/\1/')
  CH=$(echo "$line" | sed -E 's/.*ch: ([0-9]+), bw:.*/\1/')
  BW=$(echo "$line" | sed -E 's/.*bw: ([^,]+), freq:.*/\1/')
  FREQ=$(echo "$line" | sed -E 's/.*freq: ([0-9]+)MHz.*/\1/')

  if [ "$FREQ" -lt 3000 ]; then
    BAND="2.4GHz"
  else
    BAND="5GHz"
  fi

  cat >> "$OUT" <<EOF
InternetGatewayDevice.X_SARA_EasyMesh.Radio.$i,true,false,,
InternetGatewayDevice.X_SARA_EasyMesh.Radio.$i.Interface,false,false,$IFACE,xsd:string
InternetGatewayDevice.X_SARA_EasyMesh.Radio.$i.MACAddress,false,false,$MAC,xsd:string
InternetGatewayDevice.X_SARA_EasyMesh.Radio.$i.Channel,false,false,$CH,xsd:unsignedInt
InternetGatewayDevice.X_SARA_EasyMesh.Radio.$i.Bandwidth,false,false,$BW,xsd:string
InternetGatewayDevice.X_SARA_EasyMesh.Radio.$i.FrequencyMHz,false,false,$FREQ,xsd:unsignedInt
InternetGatewayDevice.X_SARA_EasyMesh.Radio.$i.Band,false,false,$BAND,xsd:string
EOF

  i=$((i+1))
done

echo "Modelo generado:"
cat "$OUT"

echo "Adaptador EasyMesh -> TR-069 finalizado correctamente."

exit 0
