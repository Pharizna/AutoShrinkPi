#!/bin/bash

# ============================================
# AutoShrinkPi - Script Maestro v2.1
# Backup. Shrink. Expand. Done.
# ============================================

# Colores
GREEN="\e[32m"
RED="\e[31m"
YELLOW="\e[33m"
CYAN="\e[36m"
RESET="\e[0m"

# Ruta de scripts
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Comprobación de permisos
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}Este script debe ejecutarse como root.${RESET}"
    exit 1
fi

# Notificación final automática (sustituye a la pausa)
notify_end() {
    echo ""
    echo -e "${GREEN}=== PROCESO COMPLETADO ===${RESET}"
    echo "(Puedes cerrar la terminal si quieres)"
    sleep 2
}

# Menú principal
menu() {
    clear
    echo -e "${GREEN}"
    echo "==============================================="
    echo "            AutoShrinkPi - v2.1"
    echo "==============================================="
    echo -e "${RESET}"
    echo -e "${CYAN}1) Backup USB principal (detiene Docker)${RESET}"
    echo -e "${CYAN}2) Backup SD del sistema (detiene Docker)${RESET}"
    echo -e "${CYAN}3) Backup USB adicional (NO detiene Docker)${RESET}"
    echo -e "${CYAN}4) Recortar imagen existente (.img)${RESET}"
    echo -e "${CYAN}5) Recortar + preparar expansión automática${RESET}"
    echo -e "${CYAN}6) Salir${RESET}"
    echo ""
    read -p "Selecciona una opción: " opcion
}

# Bucle principal
while true; do
    menu

    case $opcion in

        1)
            clear
            echo -e "${YELLOW}Ejecutando backup de la USB principal...${RESET}"
            bash "$SCRIPT_DIR/backup_usb_v2.1.sh"
            notify_end
            ;;

        2)
            clear
            echo -e "${YELLOW}Ejecutando backup de la SD del sistema...${RESET}"
            bash "$SCRIPT_DIR/backup_sd_v2.1.sh"
            notify_end
            ;;

        3)
            clear
            echo -e "${YELLOW}Ejecutando backup de la USB adicional...${RESET}"
            bash "$SCRIPT_DIR/backup_usb_extra_v2.1.sh"
            notify_end
            ;;

        4)
            clear
            echo -e "${YELLOW}Recortando imagen existente...${RESET}"
            bash "$SCRIPT_DIR/recortar_imagen_v2.1.sh"
            notify_end
            ;;

        5)
            clear
            echo -e "${YELLOW}Recortando imagen + preparando expansión automática...${RESET}"
            bash "$SCRIPT_DIR/recortar_y_expandir_v2.1.sh"
            notify_end
            ;;

        6)
            echo -e "${GREEN}Saliendo de AutoShrinkPi. Hasta pronto.${RESET}"
            exit 0
            ;;

        *)
            echo -e "${RED}Opción no válida. Inténtalo de nuevo.${RESET}"
            sleep 2
            ;;
    esac
done
