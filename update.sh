#!/bin/bash

# Renk tanımları
GREEN="\e[32m"
RED="\e[31m"
RESET="\e[0m"

# Root olarak mı çalışıyor?
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}Bu betik root olarak çalıştırılmalıdır. Lütfen 'sudo' ile çalıştırın.${RESET}"
    exit 1
fi

# Dağıtımı belirle
distro=$(grep '^ID=' /etc/os-release | cut -d'=' -f2 | tr -d '"')

echo -e "${GREEN}Dağıtım algılandı: $distro${RESET}"

# Paket yöneticisine göre güncelle
case "$distro" in
    ubuntu|debian)
        apt update -y && apt upgrade -y || { echo -e "${RED}APT güncelleme başarısız.${RESET}"; exit 1; }
        ;;
    fedora|rhel|centos)
        dnf upgrade --refresh -y || { echo -e "${RED}DNF güncelleme başarısız.${RESET}"; exit 1; }
        ;;
    arch|manjaro|cachyos)
        pacman -Syu --noconfirm || { echo -e "${RED}Pacman güncelleme başarısız.${RESET}"; exit 1; }

        if command -v yay &> /dev/null; then
            yay -Syu --noconfirm
        else
            echo "yay yüklü değil, atlanıyor."
        fi

        if command -v paru &> /dev/null; then
            paru -Syu --noconfirm
        else
            echo "paru yüklü değil, atlanıyor."
        fi
        ;;
    *)
        echo -e "${RED}Desteklenmeyen dağıtım: $distro${RESET}"
        exit 1
        ;;
esac

# Snap güncelle
if command -v snap &> /dev/null; then
    snap refresh
else
    echo "Snap yüklü değil, atlanıyor."
fi

# Flatpak güncelle
if command -v flatpak &> /dev/null; then
    flatpak update -y
else
    echo "Flatpak yüklü değil, atlanıyor."
fi

# Güncelleme tamamlandı
echo -e "${GREEN}Tüm güncellemeler tamamlandı.${RESET}"
