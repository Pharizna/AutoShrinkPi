#!/bin/bash

timestamp() {
    date +"%Y-%m-%d %H:%M:%S"
}

echo
echo "==========================================================="
echo "=== BACKUP USB EXTRA v2.1 — Inicio: $(timestamp) ==="
echo "==========================================================="
echo

# === CONFIGURACIÓN ===
FECHA=$(date +"%Y-%m-%d_%H-%M")

# Cambia /dev/sdb si tu USB adicional es otra
USB_EXTRA="/dev/sdb"

IMG="/mnt/nas/backup-usb-extra_${FECHA}.img"
IMG_SHRUNK="/mnt/nas/backup-usb-extra_${FECHA}_shrunk.img"
DESTINO="${IMG_SHRUNK}.gz"
LOG="/home/pi/backup_usb_extra.log"

echo "[INFO] Dispositivo origen: $USB_EXTRA" | tee -a "$LOG"
echo "[INFO] Archivo final esperado: $DESTINO" | tee -a "$LOG"
echo "[INFO] Hora de inicio: $(timestamp)" | tee -a "$LOG"

# === 0. Comprobar NAS ===
echo "[CHECK] Verificando montaje NAS... $(timestamp)" | tee -a "$LOG"
if ! mountpoint -q /mnt/nas; then
    echo "[ERROR] /mnt/nas NO está montado. Abortando." | tee -a "$LOG"
    exit 1
fi

# === 1. Obtener tamaño real de la USB adicional ===
TAMANO_USB=$(sudo blockdev --getsize64 "$USB_EXTRA")
echo "[INFO] Tamaño real de la USB adicional: $TAMANO_USB bytes" | tee -a "$LOG"

# === 2. Crear imagen completa con ETA ===
echo "[ACTION] Iniciando copia completa de la USB adicional... $(timestamp)" | tee -a "$LOG"
sudo dd if="$USB_EXTRA" bs=4M status=none | pv -s "$TAMANO_USB" > "$IMG"

sync
echo "[OK] Imagen completa creada: $IMG — $(timestamp)" | tee -a "$LOG"

# === 3. Detectar GPT o MBR ===
echo "[ACTION] Detectando tipo de partición... $(timestamp)" | tee -a "$LOG"

if sudo parted -s "$IMG" print >/dev/null 2>&1; then
    ES_GPT=$(sudo parted -s "$IMG" print | grep -c "gpt")
else
    ES_GPT=0
fi

if [ "$ES_GPT" -gt 0 ]; then
    echo "[INFO] Particionado GPT detectado." | tee -a "$LOG"
    LAST_SECTOR=$(sudo sgdisk -p "$IMG" | grep "last usable sector" | awk '{print $4}')
else
    echo "[INFO] Particionado MBR detectado." | tee -a "$LOG"
    LAST_SECTOR=$(sudo fdisk -l "$IMG" | grep "^$IMG" | tail -n 1 | awk '{print $3}')
fi

echo "[INFO] Último sector útil: $LAST_SECTOR" | tee -a "$LOG"

# === 4. Calcular tamaño final ===
TAMANO_FINAL=$(( (LAST_SECTOR + 1) * 512 ))
echo "[INFO] Tamaño final tras shrink: $TAMANO_FINAL bytes" | tee -a "$LOG"

# === 5. Truncar imagen ===
echo "[ACTION] Truncando imagen... $(timestamp)" | tee -a "$LOG"
truncate -s "$TAMANO_FINAL" "$IMG"
mv "$IMG" "$IMG_SHRUNK"

echo "[OK] Imagen reducida creada: $IMG_SHRUNK — $(timestamp)" | tee -a "$LOG"

# === 6. Comprimir con ETA real ===
echo "[ACTION] Iniciando compresión con ETA... $(timestamp)" | tee -a "$LOG"
pv -s "$TAMANO_FINAL" "$IMG_SHRUNK" | pigz -9 > "$DESTINO"

echo "[OK] Imagen comprimida: $DESTINO — $(timestamp)" | tee -a "$LOG"

# === 7. Limpiar imagen sin comprimir ===
rm -f "$IMG_SHRUNK"

echo
echo "=== BACKUP USB EXTRA COMPLETADO — $(timestamp) ===" | tee -a "$LOG"
echo "[FINAL] Archivo listo para Balena: $DESTINO" | tee -a "$LOG"
echo
