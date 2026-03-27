# AutoShrinkPi  
### Backup. Shrink. Expand. Done.

┌──────────────────────────────────────────────┐
│                AutoShrinkPi                  │
│      Backup. Shrink. Expand. Done.           │
└──────────────────────────────────────────────┘

---

# 🇪🇸 Descripción (Español)

**AutoShrinkPi** es un sistema modular y automatizado para realizar:

- Backups completos de la SD y de la USB principal
- Backups de una USB adicional sin detener Docker
- Recorte (shrink) de imágenes `.img`
- Preparación de imágenes con expansión automática al primer arranque
- Compresión optimizada con `pigz`
- Almacenamiento centralizado en un NAS

El objetivo es disponer de copias de seguridad fiables, comprimidas, optimizadas y listas para restaurar con Balena Etcher.

---

# 🏗 Arquitectura del sistema

## 1. USB principal con `/opt/mydockers`
La Raspberry Pi utiliza una USB externa como almacenamiento principal para Docker:

```
/opt/mydockers
```

Esta unidad contiene contenedores, volúmenes y datos persistentes.  
Por seguridad, Docker debe detenerse antes de clonar esta unidad.

---

## 2. SD interna del sistema
Contiene:

- Sistema operativo  
- `/boot`  
- Partición raíz  

También se respalda con recorte automático.

---

## 3. NAS montado en `/mnt/nas`
Todas las imágenes generadas se almacenan en:

```
/mnt/nas
```

Ejemplo de `/etc/fstab`:

```
192.168.1.X:/backups /mnt/nas nfs defaults 0 0
```

---

# 📦 Scripts incluidos (v2.1)

| Script | Descripción |
|--------|-------------|
| `backup_usb_v2.1.sh` | Backup USB principal (detiene Docker) |
| `backup_sd_v2.1.sh` | Backup SD del sistema (detiene Docker) |
| `backup_usb_extra_v2.1.sh` | Backup USB adicional (NO detiene Docker) |
| `recortar_imagen_v2.1.sh` | Recorta una imagen `.img` existente |
| `recortar_y_expandir_v2.1.sh` | Recorta `.img` + expansión automática |
| `backup_master_v2.1.sh` | Menú principal para gestionar todo |

---

# 🧭 Flujo de trabajo típico

### Backup del sistema completo
```
./backup_master_v2.1.sh
→ Opción
