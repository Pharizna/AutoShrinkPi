#!/bin/bash

echo
echo "==============================================="
echo "=== BACKUP MASTER v2.1 — Selección de tarea ==="
echo "==============================================="
echo

echo "1) Backup USB"
echo "2) Backup SD"
echo "3) Salir"
echo
read -p "Selecciona una opción: " OPCION

case $OPCION in
    1)
        echo
        echo "Ejecutando backup USB..."
        ./backup_usb_v2.1.sh
        ;;
    2)
        echo
        echo "Ejecutando backup SD..."
        ./backup_sd_v2.1.sh
        ;;
    3)
        echo "Saliendo..."
        exit 0
        ;;
    *)
        echo "Opción no válida."
        exit 1
        ;;
esac
