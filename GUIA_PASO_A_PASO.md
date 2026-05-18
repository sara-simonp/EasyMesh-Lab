# 🎯 GUÍA PASO A PASO - IMPLEMENTACIÓN EXACTA

## ⚠️ IMPORTANTE: LEE ESTO PRIMERO

Esta guía asume que:
- ✅ Tienes Docker instalado
- ✅ Tienes Docker Compose instalado
- ✅ Tienes Git o acceso a los archivos que descargaste
- ✅ Estás en Linux o macOS (o WSL en Windows)

---

## 📍 PASO 0: VERIFICAR REQUISITOS

Abre una terminal y ejecuta estos comandos:

```bash
docker --version
# Deberías ver algo como: Docker version 20.10.x o superior

docker-compose --version
# Deberías ver algo como: Docker Compose version 1.29.x o superior
```

Si alguno no funciona, instala Docker desde: https://www.docker.com/products/docker-desktop

---

## 📁 PASO 1: CREAR ESTRUCTURA DE DIRECTORIOS

Abre una terminal en la carpeta donde quieres tu proyecto. Ejecuta EXACTAMENTE esto:

```bash
# Crear carpeta principal del proyecto
mkdir -p easymesh-lab
cd easymesh-lab

# Crear todas las subcarpetas necesarias
mkdir -p genieacs/config
mkdir -p genieacs/logs
mkdir -p genieacs/data
mkdir -p easymesh-simulator/config
mkdir -p captures

# Verificar que se crearon
ls -la
```

**Deberías ver:**
```
drwxr-xr-x genieacs/
drwxr-xr-x easymesh-simulator/
drwxr-xr-x captures/
```

---

## 📥 PASO 2: DESCARGAR LOS 5 ARCHIVOS QUE TE DI

Descarga estos 5 archivos del correo/descarga que te pasé y colócalos en la carpeta `easymesh-lab`:

1. ✅ `Dockerfile-geniaacs`
2. ✅ `genieacs.yml`
3. ✅ `docker-compose-fixed.yml`
4. ✅ `setup.sh` (opcional pero recomendado)
5. ✅ `TROUBLESHOOTING.md` (para referencia)

**Después de descargar, tu carpeta debe verse así:**

```
easymesh-lab/
├── Dockerfile-geniaacs          ← Descargado
├── genieacs.yml                 ← Descargado
├── docker-compose-fixed.yml     ← Descargado
├── setup.sh                     ← Descargado (opcional)
├── TROUBLESHOOTING.md           ← Descargado (opcional)
├── genieacs/
│   ├── config/
│   ├── logs/
│   └── data/
├── easymesh-simulator/
│   └── config/
└── captures/
```

**En terminal, verifica que están ahí:**

```bash
ls -la
```

---

## 🔧 PASO 3: COPIAR ARCHIVO DOCKERFILE AL LUGAR CORRECTO

Este es un paso **CRUCIAL**. El Dockerfile debe estar dentro de `genieacs/`:

```bash
# Copiar el Dockerfile
cp Dockerfile-geniaacs genieacs/Dockerfile

# Verificar que está en el lugar correcto
ls -la genieacs/
```

**Deberías ver:**
```
-rw-r--r-- Dockerfile
drwxr-xr-x config/
drwxr-xr-x logs/
drwxr-xr-x data/
```

---

## ⚙️ PASO 4: COPIAR ARCHIVO DE CONFIGURACIÓN

El archivo `genieacs.yml` debe estar dentro de `genieacs/config/`:

```bash
# Copiar la configuración
cp genieacs.yml genieacs/config/

# Verificar
ls -la genieacs/config/
```

**Deberías ver:**
```
-rw-r--r-- genieacs.yml
```

---

## 🔄 PASO 5: REEMPLAZAR docker-compose.yml

Este es el archivo principal que controla todo:

```bash
# Renombrar el antiguo (si existe)
mv docker-compose.yml docker-compose.yml.backup 2>/dev/null || true

# Copiar el nuevo
cp docker-compose-fixed.yml docker-compose.yml

# Verificar
ls -la docker-compose.yml
```

**Deberías ver:**
```
-rw-r--r-- docker-compose.yml
```

---

## 📋 PASO 6: VERIFICAR ESTRUCTURA FINAL

Ejecuta este comando para ver si está todo en su lugar:

```bash
tree -L 2
# o si no tienes tree:
find . -type f -o -type d | head -30
```

**Deberías ver algo como esto:**

```
easymesh-lab/
├── Dockerfile-geniaacs
├── genieacs.yml
├── docker-compose.yml          ← El que acabas de copiar
├── setup.sh
├── TROUBLESHOOTING.md
├── genieacs/
│   ├── Dockerfile               ← Copiado en PASO 3
│   ├── config/
│   │   └── genieacs.yml         ← Copiado en PASO 4
│   ├── logs/
│   └── data/
├── easymesh-simulator/
│   └── config/
└── captures/
```

⚠️ **Si algo falta, VE AL PASO QUE CORRESPONDA**

---

## 🎨 PASO 7: VERIFICAR QUE DOCKER-COMPOSE.YML ES CORRECTO

Abre el archivo `docker-compose.yml` en un editor de texto (VS Code, Notepad++, etc) y **verifica** que contiene estos bloques (no importa el orden):

```yaml
version: "3.8"

services:
  mongo:
    ...
  redis:
    ...
  geniaacs:
    build:
      context: ./genieacs
      dockerfile: Dockerfile
    ...
  easymesh-simulator:
    ...
  sniffer:
    ...

volumes:
  mongo_data:

networks:
  easymesh-net:
    ...
```

Si no contiene esto, significa que copiaste el archivo incorrecto. Descarga nuevamente `docker-compose-fixed.yml` y repite PASO 5.

---

## 🚀 PASO 8: CONSTRUIR LAS IMÁGENES DE DOCKER

Este paso crea las imágenes necesarias. **Tarda 5-10 minutos la PRIMERA VEZ.**

```bash
# Construir (no usar el viejo geniaacs)
docker-compose build --no-cache geniaacs

# Si sale bien, verás al final:
# Successfully tagged easymesh-lab_geniaacs:latest
```

**Si sale error, ejecuta esto:**

```bash
docker-compose build geniaacs
```

**Esto debería ver algo como:**
```
Building geniaacs
Sending build context to Docker daemon  2.048kB
Step 1/10 : FROM node:18-alpine
 ---> xxxxxxxxxxxx
Step 2/10 : WORKDIR /app
 ---> Running in xxxxxxxxxxxx
...
Successfully built xxxxxxxxxxxx
Successfully tagged easymesh-lab_geniaacs:latest
```

---

## 🔌 PASO 9: INICIAR TODOS LOS SERVICIOS

Este es el momento crítico. Ejecuta:

```bash
# Iniciar TODO en segundo plano (-d = detached)
docker-compose up -d

# Espera 3 segundos y luego verifica:
sleep 3
docker-compose ps
```

**Deberías ver algo como esto (después de esperar ~20 segundos):**

```
NAME                COMMAND             STATUS              PORTS
mongo-db            mongosh ...         Up (healthy)        0.0.0.0:27017->27017/tcp
redis-cache         redis-server ...    Up (healthy)        0.0.0.0:6379->6379/tcp
geniaacs-acs        genieacs            Up (starting)        0.0.0.0:7557->7557/tcp
easymesh-simulator  /bin/bash           Up                   0.0.0.0:6510->6510/tcp
tcpdump-sniffer     tcpdump ...         Up                   (none)
```

⚠️ **El geniaacs-acs puede estar en "Up (starting)" durante 30-40 segundos, eso es NORMAL.**

---

## ⏳ PASO 10: ESPERAR A QUE GENIAACS ESTÉ LISTO

GeniaACS tarda tiempo en iniciar. Ejecuta esto para ver los logs:

```bash
docker-compose logs -f geniaacs
```

**Espera hasta ver algo como esto:**

```
geniaacs-acs  | GenieACS started successfully
geniaacs-acs  | CWMP server listening on 0.0.0.0:7557
geniaacs-acs  | Web UI listening on 0.0.0.0:8080
geniaacs-acs  | REST API listening on 0.0.0.0:3000
```

**Cuando veas eso, presiona `CTRL+C` para salir de los logs.**

---

## ✅ PASO 11: VERIFICAR QUE TODO FUNCIONA

Ejecuta estos comandos uno a uno:

### 11a) Ver estado de los containers
```bash
docker-compose ps
```

Todos deben estar en estado `Up`. Si alguno está en `Exit`, ve al PASO 12 (troubleshooting).

### 11b) Probar GeniaACS Web UI
```bash
curl http://localhost:8080/
```

Deberías ver HTML (aunque sea poco legible en terminal). Si no funciona:
```bash
docker-compose logs geniaacs | tail -20
```

### 11c) Probar API REST
```bash
curl http://localhost:3000/api/system
```

Deberías ver algo en JSON como:
```json
{"status":"ok"}
```

### 11d) Probar MongoDB
```bash
docker-compose exec mongo mongosh admin -u admin -p admin --eval "db.version()"
```

Debería mostrar la versión de MongoDB.

### 11e) Probar Redis
```bash
docker-compose exec redis redis-cli ping
```

Debería responder `PONG`.

---

## 🌐 PASO 12: ACCEDER A LAS INTERFACES

Abre tu navegador web en estas direcciones:

| Servicio | URL | Usuario | Contraseña |
|----------|-----|---------|-----------|
| **GeniaACS Web UI** | http://localhost:8080 | admin | admin |
| **REST API** | http://localhost:3000 | - | - |
| **CWMP** | cwmp://localhost:7557 | - | - |
| **prplMesh** | http://localhost:6510 | - | - |

---

## 🛑 PASO 13: DETENER TODO (Cuando quieras apagar)

Cuando termines de trabajar:

```bash
# Parar todos los servicios (sin eliminar datos)
docker-compose down

# Si quieres eliminar TODO incluyendo bases de datos:
docker-compose down -v

# Si quieres ver logs después de parar:
docker-compose logs
```

---

## 🆘 PASO 14: TROUBLESHOOTING - SI ALGO FALLA

### ❌ "geniaacs-acs exited with code 1"

```bash
# Ver logs detallados
docker-compose logs geniaacs

# Si necesitas reparar, ejecuta:
docker-compose down
docker-compose build --no-cache geniaacs
docker-compose up -d
docker-compose logs -f geniaacs
```

### ❌ "Connection refused on port 8080"

```bash
# Esperar más tiempo (GeniaACS tarda 40 segundos)
sleep 40
curl http://localhost:8080/

# Si sigue sin funcionar:
docker-compose restart geniaacs
docker-compose logs -f geniaacs
```

### ❌ "Port already in use"

```bash
# Ver qué está usando el puerto (ejemplo puerto 8080)
lsof -i :8080

# Cambiar puerto en docker-compose.yml:
# Buscar: "8080:8080"
# Cambiar a: "8081:8080"
# Luego: docker-compose restart
```

### ❌ "geniaacs/Dockerfile not found"

Asegúrate de estar en la carpeta correcta y que `genieacs/Dockerfile` existe:

```bash
pwd  # Deberías estar en easymesh-lab/
ls -la genieacs/Dockerfile
```

Si no existe, ve al PASO 3.

---

## 📊 PASO 15: COMANDOS ÚTILES PARA EL DÍA A DÍA

```bash
# Ver estado de todo
docker-compose ps

# Ver logs en vivo (presiona CTRL+C para salir)
docker-compose logs -f

# Ver logs de un servicio específico
docker-compose logs -f geniaacs
docker-compose logs -f mongo
docker-compose logs -f redis

# Ejecutar comando dentro de un container
docker-compose exec geniaacs curl http://localhost:8080/

# Entrar a bash de un container
docker-compose exec geniaacs sh
# Luego: exit

# Reiniciar un servicio
docker-compose restart geniaacs

# Parar un servicio
docker-compose stop geniaacs

# Iniciar un servicio parado
docker-compose start geniaacs

# Ver uso de recursos
docker stats

# Limpiar todo de Docker (CUIDADO)
docker system prune -a
```

---

## ✨ RESUMEN RÁPIDO (SI SOLO QUIERES COPIAR-PEGAR)

Si ya tienes todo descargado en `easymesh-lab/`, ejecuta esto:

```bash
cd easymesh-lab

# Copiar archivos
cp Dockerfile-geniaacs genieacs/Dockerfile
cp genieacs.yml genieacs/config/
cp docker-compose-fixed.yml docker-compose.yml

# Construir
docker-compose build --no-cache geniaacs

# Iniciar
docker-compose up -d

# Esperar y ver
sleep 10
docker-compose logs -f geniaacs

# (Presiona CTRL+C cuando veas "successfully started")

# Probar
docker-compose ps
curl http://localhost:8080/
```

---

## 🎉 ¡LISTO!

Si llegaste aquí y todo funciona, **¡FELICIDADES!** 🎊

Tu stack EasyMesh Lab está corriendo con:
- ✅ MongoDB
- ✅ Redis
- ✅ GeniaACS (ACS Server TR-069)
- ✅ prplMesh Simulator
- ✅ tcpdump (packet capture)

Ahora puedes acceder a:
- **Web UI**: http://localhost:8080
- **API**: http://localhost:3000
- **CWMP**: localhost:7557

---

## 📞 PREGUNTAS FRECUENTES

**P: ¿Cuánto tarda en iniciar?**
R: La primera vez 10-15 minutos (por descargar imágenes). Las siguientes veces, ~30 segundos.

**P: ¿Puedo usar Windows?**
R: Sí, con Docker Desktop. Usa PowerShell o WSL 2.

**P: ¿Se guardan los datos?**
R: Sí, en el volumen `mongo_data` y carpetas `genieacs/logs` y `genieacs/data`.

**P: ¿Cómo elimino TODO?**
R: `docker-compose down -v` (cuidado, elimina datos).

**P: ¿Puedo cambiar puertos?**
R: Sí, en `docker-compose.yml`, busca `ports:` y cambia los números.

