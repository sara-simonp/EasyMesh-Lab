#!/bin/bash
set -e

export LD_LIBRARY_PATH=/opt/prplmesh/build/install/lib:/opt/prplmesh/build/out/lib

mkdir -p /opt/prplmesh/build/install/bin
mkdir -p /opt/prplmesh/build/install/lib
mkdir -p /opt/prplmesh/build/install/config
mkdir -p /opt/prplmesh/build/install/scripts
mkdir -p /opt/prplmesh/build/install/share

cp -a /opt/prplmesh/build/out/bin/* /opt/prplmesh/build/install/bin/ 2>/dev/null || true
cp -a /opt/prplmesh/build/out/lib/* /opt/prplmesh/build/install/lib/ 2>/dev/null || true
cp -a /opt/prplmesh/build/out/config/* /opt/prplmesh/build/install/config/ 2>/dev/null || true
cp -a /opt/prplmesh/build/out/scripts/* /opt/prplmesh/build/install/scripts/ 2>/dev/null || true
cp -a /opt/prplmesh/build/out/share/prplmesh_platform_db /opt/prplmesh/build/install/share/prplmesh_platform_db 2>/dev/null || true

rm -rf /tmp/beerocks
mkdir -p /tmp/beerocks/logs
mkdir -p /tmp/beerocks/pid
mkdir -p /tmp/captures

ip link add br-lan type bridge 2>/dev/null || true
ip link set br-lan up || true

ip link add wlan0 type dummy 2>/dev/null || true
ip link add wlan1 type dummy 2>/dev/null || true
ip link add wlan2 type dummy 2>/dev/null || true

ip link set wlan0 up || true
ip link set wlan1 up || true
ip link set wlan2 up || true

cd /opt/prplmesh/build/install/bin

pkill -f ieee1905_transport 2>/dev/null || true
pkill -f beerocks_controller 2>/dev/null || true
pkill -f beerocks_agent 2>/dev/null || true
pkill -f beerocks_fronthaul 2>/dev/null || true

./ieee1905_transport > /tmp/beerocks/logs/ieee1905_transport.log 2>&1 &
sleep 1

./beerocks_controller > /tmp/beerocks/logs/beerocks_controller_manual.log 2>&1 &
sleep 2

./beerocks_agent > /tmp/beerocks/logs/beerocks_agent_manual.log 2>&1 &
sleep 3

echo "EasyMesh/prplMesh started from GitLab repository."
echo "Running processes:"
ps aux | grep beerocks | grep -v grep || true
ps aux | grep ieee1905 | grep -v grep || true

echo "Testing BML connection:"
./beerocks_cli -c bml_conn_map || true

tail -f /tmp/beerocks/logs/beerocks_agent_manual.log