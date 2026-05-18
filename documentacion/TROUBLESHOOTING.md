# 🔧 Guía de Troubleshooting - EasyMesh Lab

## Problemas y Soluciones

### ❌ Error: "Container geniaacs-acs exited"

#### Causas comunes:

**1. Dockerfile no existe en `./genieacs/`**
```bash
# Solución:
cp Dockerfile-geniaacs ./genieacs/Dockerfile
```

**2. Directorio de configuración vacío**
```bash
# Solución:
mkdir -p ./genieacs/config
cp genieacs.yml ./genieacs/config/
```

**3. MongoDB no es accesible**
```bash
# Verificar que MongoDB está corriendo:
docker ps | grep mongo-db

# Ver logs:
docker logs mongo-db
```

**4. Problemas de red/conectividad**
```bash
# Verificar red:
docker network inspect easymesh-net
```

---

## 📋 Estructura de directorios CORRECTA

```
project-root/
├── docker-compose.yml
├── Dockerfile-geniaacs
├── genieacs.yml
├── genieacs/
│   ├── Dockerfile
│   ├── config/
│   │   └── genieacs.yml
│   ├── logs/
│   └── data/
├── easymesh-simulator/
│   ├── Dockerfile
│   └── config/
├── captures/
├── README.md
└── (otros archivos)
```

---

## 🚀 Pasos para iniciar correctamente

### 1. Preparar la estructura
```bash
mkdir -p genieacs/{config,logs,data}
mkdir -p easymesh-simulator/config
mkdir -p captures
```

### 2. Copiar Dockerfile
```bash
cp Dockerfile-geniaacs genieacs/Dockerfile
```

### 3. Copiar configuración
```bash
cp genieacs.yml genieacs/config/
```

### 4. Actualizar docker-compose.yml
Reemplaza tu `docker-compose.yml` con el contenido de `docker-compose-fixed.yml`

### 5. Iniciar los servicios
```bash
# Build y start
docker-compose up -d

# Ver logs en tiempo real
docker-compose logs -f geniaacs
```

---

## 🔍 Comandos útiles para diagnóstico

```bash
# Ver estado de todos los containers
docker-compose ps

# Ver logs de un servicio específico
docker-compose logs geniaacs
docker-compose logs mongo
docker-compose logs redis

# Ejecutar comando dentro del container
docker-compose exec geniaacs curl http://localhost:8080/api/system

# Acceder a bash en un container
docker-compose exec geniaacs sh

# Ver uso de recursos
docker stats

# Limpiar todo (si es necesario)
docker-compose down -v  # CUIDADO: elimina volúmenes
```

---

## ✅ Verificar que todo funciona

### 1. Verificar containers
```bash
docker-compose ps
# Todos deben estar con estado "Up"
```

### 2. Verificar conectividad
```bash
# Probar GeniaACS Web UI
curl http://localhost:8080/

# Probar API REST
curl http://localhost:3000/api/system

# Probar MongoDB
docker-compose exec mongo mongosh admin -u admin -p admin
```

### 3. Acceder a interfaces
- **Web UI GeniaACS**: http://localhost:8080
- **REST API**: http://localhost:3000
- **Redis CLI**: `docker-compose exec redis redis-cli`

---

## 🐛 Errores específicos y soluciones

### Error: "Cannot find module 'genieacs'"
**Causa**: npm install no se ejecutó correctamente
**Solución**: Rebuild la imagen
```bash
docker-compose build --no-cache geniaacs
docker-compose up -d geniaacs
```

### Error: "Connection refused" en 27017
**Causa**: MongoDB aún no está listo
**Solución**: Esperar a que el healthcheck pase
```bash
docker-compose logs mongo
```

### Error: "Port already in use"
**Causa**: Puerto ocupado en el host
**Solución**: Cambiar puerto en docker-compose.yml o liberar el puerto
```bash
# Ver qué usa el puerto 8080
lsof -i :8080
# Matar el proceso o cambiar puerto
```

---

## 📊 Monitoreo

### Ver logs en tiempo real
```bash
docker-compose logs -f
```

### Ver logs de un servicio
```bash
docker-compose logs -f --tail=100 geniaacs
```

### Ver estadísticas de recursos
```bash
docker stats geniaacs mongo redis
```

---

## 🔐 Seguridad y configuración

### Variables de entorno recomendadas
```bash
# .env (crear en raíz del proyecto)
MONGO_ROOT_PASSWORD=tu_contraseña_segura
GENIEACS_ADMIN_PASSWORD=tu_contraseña_segura
```

### Usar .env en docker-compose
```yaml
environment:
  - MONGO_ROOT_PASSWORD=${MONGO_ROOT_PASSWORD}
```

---

## 🆘 Si nada funciona

1. **Limpiar todo**:
```bash
docker-compose down -v
docker system prune -a
```

2. **Reconstruir desde cero**:
```bash
docker-compose build --no-cache
docker-compose up -d
```

3. **Verificar logs**:
```bash
docker-compose logs
```

4. **Chequear requisitos del sistema**:
- Docker 20.10+
- Docker Compose 1.29+
- Mínimo 4GB RAM disponible
- Mínimo 10GB disco libre
