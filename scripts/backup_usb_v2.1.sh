#!/bin/bash

timestamp() {
    date +"%Y-%m-%d %H:%M:%S"
}

echo
echo "==================================================="
echo "=== BACKUP USB v2.1 — Inicio: $(timestamp) ==="
echo "==================================================="
echo

# === CONFIGURACIÓN ===
FECHA=$(date +"%Y-%m-%d_%H-%M")
USB="/dev/sda"
IMG="/mnt/nas/backup-usb_${FECHA}.img"
IMG_SHRUNK="/mnt/nas/backup-usb_${FECHA}_shrunk.img"
DESTINO="${IMG_SHRUNK}.gz"
LOG="/home/pi/backup_usb.log"

echo "[INFO] Archivo final esperado: $DESTINO" | tee -a "$LOG"
echo "[INFO] Hora de inicio: $(timestamp)" | tee -a "$LOG"

# === 0. Comprobar NAS ===
echo "[CHECK] Verificando montaje NAS... $(timestamp)" | tee -a "$LOG"
if ! mountpoint -q /mnt/nas; then
    echo "[ERROR] /mnt/nas NO está montado. Abortando." | tee -a "$LOG"
    exit 1
fi

# === 1. Obtener tamaño real del USB ===
TAMANO_USB=$(sudo blockdev --getsize64 "$USB")
echo "[INFO] Tamaño real del USB: $TAMANO_USB bytes" | tee -a "$LOG"

# === 2. Detener Docker ===
echo "[ACTION] Deteniendo Docker... $(timestamp)" | tee -a "$LOG"
sudo systemctl stop docker.socket
sudo systemctl stop docker

while systemctl is-active --quiet docker; do
    echo "[WAIT] Esperando a que Docker se detenga..."
    sleep 1
done

echo "[OK] Docker detenido. $(timestamp)" | tee -a "$LOG"
sync

# === 3. Crear imagen completa con ETA ===
echo "[ACTION] Iniciando copia completa del USB... $(timestamp)" | tee -a "$LOG"
sudo dd if="$USB" bs=4M status=none | pv -s "$TAMANO_USB" > "$IMG"

sync
echo "[OK] Imagen completa creada: $IMG — $(timestamp)" | tee -a "$LOG"

# === 4. Detectar GPT o MBR ===
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

# === 5. Calcular tamaño final ===
TAMANO_FINAL=$(( (LAST_SECTOR + 1) * 512 ))
echo "[INFO] Tamaño final tras shrink: $TAMANO_FINAL bytes" | tee -a "$LOG"

# === 6. Truncar imagen ===
echo "[ACTION] Truncando imagen... $(timestamp)" | tee -a "$LOG"
truncate -s "$TAMANO_FINAL" "$IMG"
mv "$IMG" "$IMG_SHRUNK"

echo "[OK] Imagen reducida creada: $IMG_SHRUNK — $(timestamp)" | tee -a "$LOG"

# === 7. Comprimir con ETA real ===
echo "[ACTION] Iniciando compresión con ETA... $(timestamp)" | tee -a "$LOG"
pv -s "$TAMANO_FINAL" "$IMG_SHRUNK" | pigz -9 > "$DESTINO"

echo "[OK] Imagen comprimida: $DESTINO — $(timestamp)" | tee -a "$LOG"

# === 8. Limpiar imagen sin comprimir ===
rm -f "$IMG_SHRUNK"

# === 9. Arrancar Docker ===
echo "[ACTION] Arrancando Docker... $(timestamp)" | tee -a "$LOG"
sudo systemctl start docker.socket
sudo systemctl start docker

echo "[OK] Docker arrancado. $(timestamp)" | tee -a "$LOG"

echo
echo "=== BACKUP USB COMPLETADO — $(timestamp) ===" | tee -a "$LOG"
echo "[FINAL] Archivo listo para Balena: $DESTINO" | tee -a "$LOG"
echo
