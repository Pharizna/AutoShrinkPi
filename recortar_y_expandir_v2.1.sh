#!/bin/bash

timestamp() {
    date +"%Y-%m-%d %H:%M:%S"
}

echo
echo "====================================================================="
echo "=== RECORTE + EXPANSIÓN AUTOMÁTICA v2.1 — Inicio: $(timestamp) ==="
echo "====================================================================="
echo

# === 1. Comprobar argumento ===
if [ -z "$1" ]; then
    echo "[ERROR] Debes indicar la imagen .img a procesar."
    echo "Uso: ./recortar_y_expandir_v2.1.sh archivo.img"
    exit 1
fi

IMG="$1"

if [ ! -f "$IMG" ]; then
    echo "[ERROR] El archivo '$IMG' no existe."
    exit 1
fi

# === 2. Preparar nombres ===
BASE=$(basename "$IMG" .img)
IMG_SHRUNK="${BASE}_shrunk.img"
DESTINO="${IMG_SHRUNK}.gz"

echo "[INFO] Imagen original: $IMG"
echo "[INFO] Imagen reducida será: $IMG_SHRUNK"
echo "[INFO] Archivo final comprimido: $DESTINO"
echo

# === 3. Detectar GPT o MBR ===
echo "[ACTION] Detectando tipo de partición... $(timestamp)"

if sudo parted -s "$IMG" print >/dev/null 2>&1; then
    ES_GPT=$(sudo parted -s "$IMG" print | grep -c "gpt")
else
    ES_GPT=0
fi

if [ "$ES_GPT" -gt 0 ]; then
    echo "[INFO] Particionado GPT detectado."
    LAST_SECTOR=$(sudo sgdisk -p "$IMG" | grep "last usable sector" | awk '{print $4}')
else
    echo "[INFO] Particionado MBR detectado."
    LAST_SECTOR=$(sudo fdisk -l "$IMG" | grep "^$IMG" | tail -n 1 | awk '{print $3}')
fi

echo "[INFO] Último sector útil: $LAST_SECTOR"

# === 4. Calcular tamaño final ===
TAMANO_FINAL=$(( (LAST_SECTOR + 1) * 512 ))
echo "[INFO] Tamaño final tras recorte: $TAMANO_FINAL bytes"

# === 5. Copiar imagen original ===
echo "[ACTION] Copiando imagen original... $(timestamp)"
cp "$IMG" "$IMG_SHRUNK"

# === 6. Truncar ===
echo "[ACTION] Truncando imagen... $(timestamp)"
truncate -s "$TAMANO_FINAL" "$IMG_SHRUNK"

echo "[OK] Imagen recortada creada: $IMG_SHRUNK — $(timestamp)"

# === 7. Insertar trigger de expansión ===
echo "[ACTION] Insertando trigger de expansión automática... $(timestamp)"

mkdir -p /mnt/img_boot

# Obtener offset de la partición BOOT
BOOT_OFFSET=$(sudo fdisk -l "$IMG_SHRUNK" | grep "^$IMG_SHRUNK" | head -n 1 | awk '{print $2}')
BOOT_OFFSET_BYTES=$(( BOOT_OFFSET * 512 ))

# Montar BOOT
sudo mount -o loop,offset=$BOOT_OFFSET_BYTES "$IMG_SHRUNK" /mnt/img_boot

# Crear trigger
sudo touch /mnt/img_boot/resize-rootfs

# Desmontar
sudo umount /mnt/img_boot
rmdir /mnt/img_boot

echo "[OK] Trigger añadido. La imagen se expandirá al primer arranque."

# === 8. Comprimir ===
echo "[ACTION] Iniciando compresión con ETA... $(timestamp)"
pv -s "$TAMANO_FINAL" "$IMG_SHRUNK" | pigz -9 > "$DESTINO"

echo "[OK] Imagen comprimida: $DESTINO — $(timestamp)"

echo
echo "=== RECORTE + EXPANSIÓN COMPLETADO — $(timestamp) ==="
echo "[FINAL] Archivo listo para Balena: $DESTINO"
echo

