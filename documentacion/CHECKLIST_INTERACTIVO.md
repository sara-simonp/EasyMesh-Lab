# ✅ CHECKLIST INTERACTIVO - IMPLEMENTACIÓN RÁPIDA

## 🎬 SIGUE ESTOS PASOS EN ORDEN

Cada sección que completes, marca con ✅. **No saltes pasos.**

---

### ✅ PASO 1: VERIFICAR DOCKER
- [ ] Abre una terminal
- [ ] Ejecuta: `docker --version`
  - ¿Salió un número de versión? → ✅ CONTINÚA
  - ¿Salió "command not found"? → ❌ Instala Docker Desktop: https://www.docker.com/products/docker-desktop
  
- [ ] Ejecuta: `docker-compose --version`
  - ¿Salió un número? → ✅ CONTINÚA
  - ¿Error? → ❌ Reinstala Docker Desktop

**Captura de pantalla esperada:**
```
$ docker --version
Docker version 24.0.0 (o similar, 20.10+)

$ docker-compose --version
Docker Compose version 2.20.0 (o similar, 1.29+)
```

✅ **MARCADO:** Tengo Docker y Docker Compose funcionando

---

### ✅ PASO 2: CREAR CARPETA DEL PROYECTO
- [ ] Abre Terminal/PowerShell
- [ ] Navega a donde quieras guardar el proyecto (ejemplo: escritorio)
  ```bash
  cd ~/Desktop
  # o en Windows:
  cd C:\Users\TuUsuario\Desktop
  ```

- [ ] Crea la carpeta principal:
  ```bash
  mkdir easymesh-lab
  cd easymesh-lab
  ```

- [ ] Verifica que estás dentro:
  ```bash
  pwd
  # Deberías ver algo como: /Users/TuUsuario/Desktop/easymesh-lab
  ```

- [ ] Crea las subcarpetas:
  ```bash
  mkdir -p genieacs/config
  mkdir -p genieacs/logs
  mkdir -p genieacs/data
  mkdir -p easymesh-simulator/config
  mkdir -p captures
  ```

- [ ] Verifica la estructura:
  ```bash
  ls -la
  ```
  
  **Esperado:**
  ```
  drwxr-xr-x  genieacs
  drwxr-xr-x  easymesh-simulator
  drwxr-xr-x  captures
  ```

✅ **MARCADO:** Carpetas creadas correctamente

---

### ✅ PASO 3: DESCARGAR ARCHIVOS
- [ ] Descarga estos 3 archivos ESENCIALES del correo/descarga:
  - [ ] `Dockerfile-geniaacs`
  - [ ] `genieacs.yml`
  - [ ] `docker-compose-fixed.yml`

- [ ] Coloca estos 3 archivos en la carpeta `easymesh-lab` (la raíz)

- [ ] Verifica que están ahí:
  ```bash
  ls -la *.yml *.geniaacs 2>/dev/null || ls Dockerfile* 2>/dev/null
  # o simplemente:
  ls -la
  ```
  
  **Esperado:**
  ```
  -rw-r--r--  Dockerfile-geniaacs
  -rw-r--r--  genieacs.yml
  -rw-r--r--  docker-compose-fixed.yml
  ```

✅ **MARCADO:** 3 archivos descargados en la carpeta correcta

---

### ✅ PASO 4: COPIAR DOCKERFILE
Esta es una operación CRÍTICA. El Dockerfile debe estar dentro de `genieacs/`

- [ ] Estoy en la carpeta `easymesh-lab`? 
  ```bash
  pwd
  ```
  
- [ ] Ejecuta:
  ```bash
  cp Dockerfile-geniaacs genieacs/Dockerfile
  ```

- [ ] Verifica que se copió:
  ```bash
  ls -la genieacs/Dockerfile
  ```
  
  **Esperado:**
  ```
  -rw-r--r--  Dockerfile
  ```

✅ **MARCADO:** Dockerfile en `genieacs/Dockerfile`

---

### ✅ PASO 5: COPIAR CONFIGURACIÓN
El archivo `genieacs.yml` debe estar dentro de `genieacs/config/`

- [ ] Ejecuta:
  ```bash
  cp genieacs.yml genieacs/config/
  ```

- [ ] Verifica:
  ```bash
  ls -la genieacs/config/
  ```
  
  **Esperado:**
  ```
  -rw-r--r--  genieacs.yml
  ```

✅ **MARCADO:** Configuración en `genieacs/config/genieacs.yml`

---

### ✅ PASO 6: REEMPLAZAR docker-compose.yml
Este es el archivo principal de Docker Compose.

- [ ] Ejecuta:
  ```bash
  cp docker-compose-fixed.yml docker-compose.yml
  ```

- [ ] Verifica:
  ```bash
  ls -la docker-compose.yml
  ```
  
  **Esperado:**
  ```
  -rw-r--r--  docker-compose.yml
  ```

- [ ] Abre el archivo en un editor de texto y verifica que contiene:
  - `version: "3.8"`
  - Servicio `geniaacs` con `build:`
  - Volumen `mongo_data`
  - Red `easymesh-net`

✅ **MARCADO:** docker-compose.yml en su lugar

---

### ✅ PASO 7: VERIFICAR ESTRUCTURA FINAL
- [ ] Ejecuta esto para ver la estructura:
  ```bash
  find . -type d | sort
  ```
  
  **Esperado:**
  ```
  .
  ./captures
  ./easymesh-simulator
  ./easymesh-simulator/config
  ./genieacs
  ./genieacs/config
  ./genieacs/data
  ./genieacs/logs
  ```

- [ ] Ejecuta esto para ver los archivos:
  ```bash
  find . -type f -name "Dockerfile*" -o -name "*.yml" -o -name "docker-compose.yml"
  ```
  
  **Esperado:**
  ```
  ./Dockerfile-geniaacs
  ./genieacs.yml
  ./docker-compose.yml
  ./genieacs/Dockerfile
  ./genieacs/config/genieacs.yml
  ```

✅ **MARCADO:** Estructura PERFECTA

---

### ✅ PASO 8: CONSTRUCCIÓN DE IMÁGENES DOCKER
Esta es la parte que tarda más (5-10 minutos la primera vez).

- [ ] Estoy en la carpeta `easymesh-lab`?
  ```bash
  pwd
  ```

- [ ] Construye la imagen de GeniaACS:
  ```bash
  docker-compose build --no-cache geniaacs
  ```
  
  **Esto puede tardar 5-10 minutos. Espera sin interrumpir.**
  
  **Esperado al final:**
  ```
  Successfully tagged easymesh-lab_geniaacs:latest
  ```
  
  Si sale un error, ejecuta:
  ```bash
  docker-compose build geniaacs
  ```

- [ ] Verifica que la imagen se creó:
  ```bash
  docker images | grep geniaacs
  ```
  
  **Esperado:**
  ```
  easymesh-lab_geniaacs   latest    xxxxxxxxxxxx   1.2GB
  ```

✅ **MARCADO:** Imagen Docker construida

---

### ✅ PASO 9: INICIAR TODOS LOS SERVICIOS
Este es el momento de la verdad.

- [ ] Estoy en `easymesh-lab`?
  ```bash
  pwd
  ```

- [ ] Inicia todos los servicios:
  ```bash
  docker-compose up -d
  ```
  
  **Esperado:**
  ```
  Creating network "easymesh-lab_easymesh-net" with driver "bridge"
  Creating volume "easymesh-lab_mongo_data" with default driver
  Creating redis-cache ... done
  Creating mongo-db ... done
  Creating geniaacs-acs ... done
  Creating easymesh-simulator ... done
  Creating tcpdump-sniffer ... done
  ```

- [ ] Espera 5 segundos:
  ```bash
  sleep 5
  ```

- [ ] Verifica el estado:
  ```bash
  docker-compose ps
  ```
  
  **Esperado (después de ~30 segundos):**
  ```
  NAME                STATUS              PORTS
  mongo-db            Up (healthy)        0.0.0.0:27017->27017/tcp
  redis-cache         Up (healthy)        0.0.0.0:6379->6379/tcp
  geniaacs-acs        Up (starting)       0.0.0.0:7557->7557/tcp
  easymesh-simulator  Up                  0.0.0.0:6510->6510/tcp
  tcpdump-sniffer     Up                  (none)
  ```
  
  ⚠️ El `geniaacs-acs` puede estar en "Up (starting)" durante 30-40 segundos. **ESO ES NORMAL.**

✅ **MARCADO:** Servicios iniciados

---

### ✅ PASO 10: ESPERAR A QUE GENIAACS ESTÉ LISTO
GeniaACS tarda tiempo en iniciar completamente.

- [ ] Ver logs en vivo:
  ```bash
  docker-compose logs -f geniaacs
  ```
  
  **Espera a ver algo como:**
  ```
  geniaacs-acs  | GenieACS started successfully
  geniaacs-acs  | CWMP server listening on 0.0.0.0:7557
  geniaacs-acs  | Web UI listening on 0.0.0.0:8080
  geniaacs-acs  | REST API listening on 0.0.0.0:3000
  ```
  
  **CUANDO VEAS ESO, presiona CTRL+C para salir de los logs.**

✅ **MARCADO:** GeniaACS iniciado completamente

---

### ✅ PASO 11: PRUEBAS DE FUNCIONAMIENTO
Vamos a verificar que todo funciona.

#### Prueba 1: Estado de containers
- [ ] Ejecuta:
  ```bash
  docker-compose ps
  ```
  
  **Todos deben estar "Up"**
  
  ✅ Prueba 1 OK

#### Prueba 2: GeniaACS Web UI
- [ ] Ejecuta:
  ```bash
  curl http://localhost:8080/
  ```
  
  **Debería devolver HTML (aunque sea poco legible)**
  
  Si falla, espera más:
  ```bash
  sleep 20
  curl http://localhost:8080/
  ```
  
  ✅ Prueba 2 OK

#### Prueba 3: API REST
- [ ] Ejecuta:
  ```bash
  curl http://localhost:3000/api/system
  ```
  
  **Debería devolver JSON**
  
  ✅ Prueba 3 OK

#### Prueba 4: MongoDB
- [ ] Ejecuta:
  ```bash
  docker-compose exec mongo mongosh admin -u admin -p admin --eval "db.version()"
  ```
  
  **Debería mostrar la versión de MongoDB**
  
  ✅ Prueba 4 OK

#### Prueba 5: Redis
- [ ] Ejecuta:
  ```bash
  docker-compose exec redis redis-cli ping
  ```
  
  **Debería responder "PONG"**
  
  ✅ Prueba 5 OK

✅ **MARCADO:** Todas las pruebas pasadas

---

### ✅ PASO 12: ACCEDER A INTERFACES WEB
Ahora puedes usar el navegador.

- [ ] Abre tu navegador web

- [ ] Accede a GeniaACS Web UI:
  ```
  http://localhost:8080
  ```
  
  **Login:**
  - Usuario: `admin`
  - Contraseña: `admin`
  
  ✅ GeniaACS accesible

- [ ] Accede a la API REST:
  ```
  http://localhost:3000/api/system
  ```
  
  ✅ API accesible

- [ ] Accede a prplMesh:
  ```
  http://localhost:6510
  ```
  
  ✅ prplMesh accesible

✅ **MARCADO:** Todas las interfaces web funcionando

---

## 🎉 ¡COMPLETADO!

Si tienes todas las casillas marcadas, **¡tu sistema está funcionando perfectamente!**

### Resumen de lo que tienes corriendo:

| Servicio | URL | Estado |
|----------|-----|--------|
| GeniaACS Web UI | http://localhost:8080 | ✅ Funcionando |
| REST API | http://localhost:3000 | ✅ Funcionando |
| CWMP (TR-069) | localhost:7557 | ✅ Funcionando |
| MongoDB | localhost:27017 | ✅ Funcionando |
| Redis | localhost:6379 | ✅ Funcionando |
| prplMesh | localhost:6510 | ✅ Funcionando |

---

## 🛑 COMANDOS PARA EL DÍA A DÍA

### Ver todo
```bash
docker-compose ps
docker-compose logs
```

### Ver logs de un servicio
```bash
docker-compose logs -f geniaacs
docker-compose logs -f mongo
docker-compose logs -f redis
```

### Parar todo (sin perder datos)
```bash
docker-compose down
```

### Iniciar de nuevo
```bash
docker-compose up -d
```

### Parar TODO y eliminar datos
```bash
docker-compose down -v
```

---

## 🆘 SI ALGO FALLÓ

**¿En qué paso fallaste?**

- [ ] Paso 1 (Docker) → Reinstala Docker
- [ ] Paso 2-6 (Archivos) → Verifica que todos estén en el lugar correcto
- [ ] Paso 8 (Build) → Ejecuta `docker system prune -a` y reintenta
- [ ] Paso 9-10 (Inicio) → Ver logs con `docker-compose logs`
- [ ] Paso 11 (Pruebas) → Leer el archivo `TROUBLESHOOTING.md`

