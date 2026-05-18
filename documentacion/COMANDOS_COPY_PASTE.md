# 📋 COMANDOS COPY-PASTE PARA EJECUTAR EN ORDEN

## ⚠️ IMPORTANTE
- Copia cada bloque COMPLETO (de línea a línea)
- Presiona Enter después de pegar
- Espera a que termine antes de pasar al siguiente

---

## 1️⃣ REQUISITOS PREVIOS

### Verificar Docker está instalado:
```bash
docker --version && docker-compose --version
```

**Esperado:**
```
Docker version 24.0.0 (o similar)
Docker Compose version 2.20.0 (o similar)
```

Si falla, instala desde: https://www.docker.com/products/docker-desktop

---

## 2️⃣ CREAR ESTRUCTURA DEL PROYECTO

### Copiar y ejecutar TODO ESTO junto:
```bash
# Crear carpeta
mkdir -p easymesh-lab && cd easymesh-lab

# Crear estructura
mkdir -p genieacs/{config,logs,data}
mkdir -p easymesh-simulator/config
mkdir -p captures

# Verificar
pwd
ls -la
```

**Debería mostrar:**
```
/path/to/easymesh-lab

drwxr-xr-x  genieacs
drwxr-xr-x  easymesh-simulator
drwxr-xr-x  captures
```

---

## 3️⃣ DESCARGAR ARCHIVOS

**ANTES DE CONTINUAR:**
- [ ] Descarga estos 3 archivos:
  - `Dockerfile-geniaacs`
  - `genieacs.yml`
  - `docker-compose-fixed.yml`
  
- [ ] Colócalos en la carpeta `easymesh-lab`

Verifica:
```bash
ls -la *.yml Dockerfile*
```

---

## 4️⃣ COPIAR ARCHIVOS AL LUGAR CORRECTO

### Copiar TODO ESTO junto:
```bash
# Copiar Dockerfile
cp Dockerfile-geniaacs genieacs/Dockerfile

# Copiar configuración
cp genieacs.yml genieacs/config/

# Reemplazar docker-compose
cp docker-compose-fixed.yml docker-compose.yml

# Verificar
echo "✅ Dockerfile:"
ls -la genieacs/Dockerfile

echo "✅ Config:"
ls -la genieacs/config/genieacs.yml

echo "✅ Docker Compose:"
ls -la docker-compose.yml
```

---

## 5️⃣ VERIFICAR ESTRUCTURA

### Ejecuta esto:
```bash
echo "=== ESTRUCTURA FINAL ==="
find . -type d | sort
echo ""
echo "=== ARCHIVOS CRÍTICOS ==="
find . -type f \( -name "Dockerfile*" -o -name "*.yml" \) | sort
```

**Debería mostrar:**
```
./genieacs/Dockerfile
./genieacs/config/genieacs.yml
./docker-compose.yml
```

---

## 6️⃣ CONSTRUCCIÓN DE IMÁGENES

### Ejecuta esto (tarda 5-10 minutos):
```bash
echo "🔨 Construyendo imagen GeniaACS..."
docker-compose build --no-cache geniaacs
```

**Espera a ver:**
```
Successfully tagged easymesh-lab_geniaacs:latest
```

Si falla, intenta sin `--no-cache`:
```bash
docker-compose build geniaacs
```

---

## 7️⃣ INICIAR SERVICIOS

### Ejecuta esto:
```bash
echo "🚀 Iniciando todos los servicios..."
docker-compose up -d

echo "⏳ Esperando 5 segundos..."
sleep 5

echo "📊 Estado de servicios:"
docker-compose ps
```

**Esperado:**
```
NAME                STATUS
mongo-db            Up (healthy)
redis-cache         Up (healthy)
geniaacs-acs        Up (starting)
easymesh-simulator  Up
tcpdump-sniffer     Up
```

---

## 8️⃣ ESPERAR A QUE GENIAACS ESTÉ LISTO

### Ver logs (presiona CTRL+C cuando termines):
```bash
echo "📝 Viendo logs de GeniaACS..."
echo "(Espera a ver 'successfully started', luego presiona CTRL+C)"
docker-compose logs -f geniaacs
```

---

## 9️⃣ PRUEBAS DE FUNCIONAMIENTO

### Prueba 1 - Estado:
```bash
echo "1️⃣  ESTADO DE CONTAINERS"
docker-compose ps
```

### Prueba 2 - GeniaACS Web UI:
```bash
echo "2️⃣  PRUEBA WEB UI (http://localhost:8080/)"
curl -s http://localhost:8080/ | head -20
```

### Prueba 3 - API REST:
```bash
echo "3️⃣  PRUEBA API REST (http://localhost:3000/api/system)"
curl -s http://localhost:3000/api/system | head -5
```

### Prueba 4 - MongoDB:
```bash
echo "4️⃣  PRUEBA MONGODB"
docker-compose exec mongo mongosh admin -u admin -p admin --eval "db.version()" 2>/dev/null
```

### Prueba 5 - Redis:
```bash
echo "5️⃣  PRUEBA REDIS"
docker-compose exec redis redis-cli ping
```

---

## 🔟 ACCEDER A SERVICIOS WEB

Abre en tu navegador:

```
Web UI GeniaACS:  http://localhost:8080
    Usuario:      admin
    Contraseña:   admin

API REST:         http://localhost:3000/api/system

prplMesh:         http://localhost:6510

CWMP:             cwmp://localhost:7557
```

---

## 🛑 COMANDOS ÚTILES PARA EL FUTURO

### Ver estado
```bash
docker-compose ps
```

### Ver logs
```bash
docker-compose logs -f
docker-compose logs -f geniaacs
docker-compose logs -f mongo
```

### Ejecutar comando en container
```bash
docker-compose exec geniaacs curl http://localhost:8080/
```

### Entrar a un container
```bash
docker-compose exec geniaacs sh
# Dentro del container: exit
```

### Reiniciar un servicio
```bash
docker-compose restart geniaacs
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

### Ver estadísticas
```bash
docker stats
```

### Limpiar (si algo falla)
```bash
docker system prune -a
```

---

## 🆘 TROUBLESHOOTING RÁPIDO

### ❌ "geniaacs-acs exited"
```bash
docker-compose logs geniaacs
docker-compose down
docker-compose build --no-cache geniaacs
docker-compose up -d
docker-compose logs -f geniaacs
```

### ❌ "Connection refused" en puerto 8080
```bash
# Esperar más tiempo
sleep 30
curl http://localhost:8080/

# Si sigue sin funcionar:
docker-compose restart geniaacs
docker-compose logs -f geniaacs
```

### ❌ "Port already in use"
```bash
# Ver qué usa el puerto 8080
lsof -i :8080

# Editar docker-compose.yml:
# Cambiar "8080:8080" por "8081:8080"
# Luego:
docker-compose restart
```

### ❌ "Dockerfile not found"
```bash
# Verificar ubicación
pwd  # debe ser easymesh-lab/
ls -la genieacs/Dockerfile

# Si no existe:
cp Dockerfile-geniaacs genieacs/Dockerfile
docker-compose build --no-cache geniaacs
```

### ❌ Los containers no se inician
```bash
# Limpiar
docker-compose down -v
docker system prune -a

# Reconstruir
docker-compose build --no-cache
docker-compose up -d
docker-compose logs -f
```

---

## ✅ CHECKLIST FINAL

- [ ] Docker instalado y funcionando
- [ ] Carpeta `easymesh-lab` creada
- [ ] 3 archivos descargados y colocados
- [ ] Dockerfile copiado a `genieacs/Dockerfile`
- [ ] Configuración copiada a `genieacs/config/genieacs.yml`
- [ ] `docker-compose.yml` reemplazado
- [ ] Imagen construida (`docker-compose build`)
- [ ] Servicios iniciados (`docker-compose up -d`)
- [ ] GeniaACS iniciado completamente
- [ ] Pruebas de funcionamiento pasadas
- [ ] Acceso web verificado (localhost:8080)

---

## 🎉 ¡LISTO!

Si completaste todo, tienes corriendo:
- ✅ MongoDB
- ✅ Redis
- ✅ GeniaACS (ACS Server TR-069)
- ✅ prplMesh Simulator
- ✅ tcpdump (Packet Capture)

Accede a: **http://localhost:8080**

Usuario: **admin**
Contraseña: **admin**

