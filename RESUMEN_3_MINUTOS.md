# 🎬 GUÍA VISUAL SUPER RESUMIDA (3 MINUTOS)

## 🔴 PASO 0: Abre una Terminal

```bash
# Verifica Docker
docker --version
docker-compose --version
```

---

## 🔴 PASO 1: Crear Carpetas

```bash
mkdir -p easymesh-lab && cd easymesh-lab
mkdir -p genieacs/{config,logs,data} easymesh-simulator/config captures
```

---

## 🔴 PASO 2: Descargar 3 Archivos

Descarga estos 3 archivos y colócalos en la carpeta `easymesh-lab/`:

1. ✅ `Dockerfile-geniaacs`
2. ✅ `genieacs.yml`
3. ✅ `docker-compose-fixed.yml`

```bash
# Verifica que están ahí
ls -la *.yml *.geniaacs
```

---

## 🔴 PASO 3: Copiar Archivos

```bash
# Copia Dockerfile
cp Dockerfile-geniaacs genieacs/Dockerfile

# Copia configuración
cp genieacs.yml genieacs/config/

# Renombra docker-compose
cp docker-compose-fixed.yml docker-compose.yml
```

---

## 🔴 PASO 4: Construir (espera 5-10 minutos)

```bash
docker-compose build --no-cache geniaacs
```

Deberías ver:
```
✓ Successfully tagged easymesh-lab_geniaacs:latest
```

---

## 🔴 PASO 5: Iniciar

```bash
docker-compose up -d
sleep 5
docker-compose ps
```

Deberías ver todos en "Up"

---

## 🔴 PASO 6: Esperar GeniaACS

```bash
docker-compose logs -f geniaacs
```

Cuando veas:
```
geniaacs-acs  | GenieACS started successfully
```

Presiona **CTRL+C**

---

## 🔴 PASO 7: Acceder

Abre tu navegador y ve a:

```
http://localhost:8080
```

**Usuario:** admin
**Contraseña:** admin

---

## 🎉 ¡LISTO!

Si llegaste aquí → **Funcionando perfecto**

---

## 🆘 SI ALGO FALLA

```bash
# Ver logs
docker-compose logs geniaacs

# Reiniciar
docker-compose restart geniaacs

# Reset total
docker-compose down -v
docker system prune -a
docker-compose build --no-cache geniaacs
docker-compose up -d
```

---

## 📞 COMANDOS ÚTILES

```bash
docker-compose ps              # Ver estado
docker-compose logs -f         # Ver logs en vivo
docker-compose down            # Parar todo
docker-compose up -d           # Iniciar todo
docker-compose down -v         # Eliminar TODO (cuidado)
```

---

## ✅ VERIFICACIÓN

```bash
# Test 1
docker-compose ps

# Test 2
curl http://localhost:8080/

# Test 3
curl http://localhost:3000/api/system

# Test 4
docker-compose exec redis redis-cli ping
# Debería responder: PONG
```

---

**¿Necesitas más detalle?**

→ Lee `GUIA_PASO_A_PASO.md`
→ Consulta `TROUBLESHOOTING.md`
→ Revisa `FAQ.md`

