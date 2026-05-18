# EasyMesh Lab

Laboratorio de simulación y pruebas para redes **EasyMesh** utilizando **GenieACS** como servidor de auto-configuración (ACS), **MongoDB** para persistencia de datos y **Redis** para caché.

## 📋 Descripción General

EasyMesh Lab es una solución de laboratorio containerizada que simula una red EasyMesh completa con los siguientes componentes:

- **EasyMesh Simulator**: Simulador de dispositivos y nodos EasyMesh
- **GenieACS**: Servidor de gestión y auto-configuración de dispositivos (ACS)
- **MongoDB**: Base de datos para almacenar configuraciones y datos
- **Redis**: Caché en memoria para optimizar rendimiento
- **tcpdump**: Herramienta de captura de tráfico de red para análisis

## 🏗️ Estructura del Proyecto

```
EasyMesh-Lab/
├── docker-compose.yml          # Configuración de orquestación de contenedores
├── easymesh-simulator/         # Componente simulador EasyMesh
│   └── config/                 # Configuraciones del simulador (vacío)
│       └── Dockerfile          # Dockerfile para construir la imagen
├── geniaacs/                   # Componente GenieACS (ACS)
│   └── config/                 # Archivos de configuración (vacío)
├── tcpdump-config/             # Configuración de captura de tráfico (vacío)
└── captures/                   # Directorio para archivos PCAP capturados
```

## 🐳 Componentes Docker

### 1. **tcpdump** (Sniffer de Red)
- **Imagen**: `corfr/tcpdump`
- **Propósito**: Captura el tráfico de red en la interfaz eth0
- **IP**: 172.25.0.30
- **Volumen**: `./captures:/data` - Almacena archivos PCAP
- **Comando**: Captura en formato `.pcap` (`sniffer.pcap`)

### 2. **GeniaACS** (Servidor ACS)
- **Imagen**: `genieacs/genieacs:latest`
- **IP**: 172.25.0.10
- **Puertos**:
  - `7557`: Puerto ACS (HTTP)
  - `7558`: Puerto ACS (HTTPS)
  - `8080`: Web UI
  - `3000`: API/UI adicional
- **Dependencias**: MongoDB, Redis
- **Volumen**: `./geniaacs/config:/opt/genieacs/config:ro`

### 3. **MongoDB** (Base de Datos)
- **Imagen**: `mongo:5.0`
- **IP**: 172.25.0.20
- **Puerto**: `27017`
- **Volumen**: `mongo_data:/data/db` (persistencia de datos)

### 4. **Redis** (Caché)
- **Imagen**: `redis:7-alpine`
- **IP**: 172.25.0.21
- **Puerto**: `6379`

### 5. **EasyMesh Simulator**
- **Construcción**: Imagen local desde `./easymesh-simulator/Dockerfile`
- **IP**: 172.25.0.40
- **Puerto**: `8888`
- **Variable de entorno**: `ACS_URL=http://geniaacs-acs:7557`
- **Dependencias**: GenieACS

## 🔗 Red Docker

- **Nombre**: `easymesh-net`
- **Driver**: bridge
- **Subred**: `172.25.0.0/24`
- **Gateway**: `172.25.0.1`

### Asignación de IPs

| Servicio | IP |
|----------|-----|
| Gateway | 172.25.0.1 |
| GenieACS | 172.25.0.10 |
| MongoDB | 172.25.0.20 |
| Redis | 172.25.0.21 |
| tcpdump | 172.25.0.30 |
| EasyMesh Simulator | 172.25.0.40 |

## 🚀 Inicio Rápido

### Requisitos Previos

- Docker Engine 20.10+
- Docker Compose 1.29+
- 4GB RAM mínimo disponible
- 10GB espacio en disco

### Iniciar el Laboratorio

```bash
# Navegar al directorio del proyecto
cd EasyMesh-Lab

# Iniciar todos los servicios en background
docker-compose up -d

# Ver logs en tiempo real
docker-compose logs -f

# Ver estado de los servicios
docker-compose ps
```

### Acceso a Servicios

| Servicio | URL/Endpoint |
|----------|--------------|
| GenieACS Web UI | http://localhost:8080 |
| GenieACS API | http://localhost:3000 |
| MongoDB | mongodb://localhost:27017 |
| Redis | localhost:6379 |
| ACS HTTP | http://localhost:7557 |
| ACS HTTPS | https://localhost:7558 |
| EasyMesh Simulator | http://localhost:8888 |

## 🛑 Detener el Laboratorio

```bash
# Detener todos los servicios sin eliminar volúmenes
docker-compose stop

# Detener y eliminar contenedores (mantiene volúmenes)
docker-compose down

# Eliminar todo incluyendo volúmenes (CUIDADO: borra datos)
docker-compose down -v
```

## 📊 Captura de Tráfico

El servicio tcpdump captura automáticamente todo el tráfico de red:

```bash
# Ver archivos capturados
ls -lh EasyMesh-Lab/captures/

# Analizar con Wireshark
wireshark captures/sniffer.pcap
```

## 🔧 Configuración

### GenieACS
Coloca archivos de configuración en `geniaacs/config/` - serán accesibles como volumen read-only en `/opt/genieacs/config`

### EasyMesh Simulator
Coloca archivos de configuración en `easymesh-simulator/config/`

### tcpdump
Configuración en `tcpdump-config/` (actualmente vacío)

## 📈 Variables de Entorno

- **MongoDB Connection**: `mongodb://mongo:27017/genieacs`
- **Redis URL**: `redis://redis:6379`
- **ACS URL**: `http://geniaacs-acs:7557`

## 🐛 Troubleshooting

### Contenedores no inician
```bash
# Ver logs detallados
docker-compose logs [nombre-servicio]

# Validar configuración
docker-compose config
```

### Problemas de conectividad
```bash
# Acceder a un contenedor
docker exec -it [container-name] sh

# Probar conectividad entre servicios
docker exec -it easymesh-sim curl http://geniaacs-acs:7557
```

### Limpiar estado
```bash
# Eliminar contenedores e imágenes no usadas
docker system prune -a

# Reiniciar servicios
docker-compose restart
```

## 📝 Notas

- Los datos de MongoDB se persisten en el volumen `mongo_data`
- Los archivos PCAP capturados se guardan en `captures/`
- Todos los contenedores están conectados a la misma red virtual
- El simulador se comunica con GenieACS a través de su URL interna

## 📚 Referencias

- [GenieACS Documentation](https://genieacs.com/)
- [EasyMesh Specification](https://www.wi-fi.org/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [MongoDB Documentation](https://docs.mongodb.com/)
- [Redis Documentation](https://redis.io/documentation)

## 📄 Licencia

Se debe especificar según los componentes utilizados.

---

**Última actualización**: Abril 2026
