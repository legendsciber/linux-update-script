#!/bin/bash

# Renk tanımları
GREEN="\e[32m"
RED="\e[31m"
YELLOW="\e[33m"
RESET="\e[0m"

# Root kontrolü
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}Bu betik root olarak çalıştırılmalıdır. Lütfen 'sudo' ile çalıştırın.${RESET}"
    exit 1
fi

# Kullanıcıya bilgi
echo -e "${GREEN}Sistem güncelleme işlemi başlatılıyor...${RESET}"
echo -e "${YELLOW}Lütfen güncelleme sırasında sistemi kapatmayın veya yeniden başlatmayın.${RESET}"

# Dağıtımı belirle
distro=$(grep '^ID=' /etc/os-release | cut -d'=' -f2 | tr -d '"')
id_like=$(grep '^ID_LIKE=' /etc/os-release | cut -d'=' -f2 | tr -d '"')

echo -e "${GREEN}Dağıtım algılandı: $distro${RESET}"

# Paket yöneticisine göre güncelle
case "$distro" in
    ubuntu|debian|linuxmint|elementary)
        echo -e "${YELLOW}APT ile sistem güncelleniyor...${RESET}"
        apt update && apt upgrade -y || { echo -e "${RED}APT güncelleme başarısız.${RESET}"; exit 1; }
        ;;
    fedora|rhel|centos)
        echo -e "${YELLOW}DNF ile sistem güncelleniyor...${RESET}"
        dnf upgrade --refresh -y || { echo -e "${RED}DNF güncelleme başarısız.${RESET}"; exit 1; }
        ;;
    arch|manjaro|cachyos)
        echo -e "${YELLOW}Pacman ile sistem güncelleniyor...${RESET}"
        pacman -Syu --noconfirm || { echo -e "${RED}Pacman güncelleme başarısız.${RESET}"; exit 1; }

        if command -v yay &> /dev/null; then
            echo -e "${YELLOW}Yay ile AUR güncelleniyor...${RESET}"
            yay -Syu --noconfirm
        else
            echo -e "${RED}yay yüklü değil, atlanıyor.${RESET}"
        fi

        if command -v paru &> /dev/null; then
            echo -e "${YELLOW}Paru ile AUR güncelleniyor...${RESET}"
            paru -Syu --noconfirm
        else
            echo -e "${RED}paru yüklü değil, atlanıyor.${RESET}"
        fi
        ;;
    *)
        case "$id_like" in
            debian)
                echo -e "${YELLOW}APT ile (ID_LIKE) sistem güncelleniyor...${RESET}"
                apt update && apt upgrade -y || { echo -e "${RED}APT güncelleme başarısız.${RESET}"; exit 1; }
                ;;
            rhel|fedora)
                echo -e "${YELLOW}DNF ile (ID_LIKE) sistem güncelleniyor...${RESET}"
                dnf upgrade --refresh -y || { echo -e "${RED}DNF güncelleme başarısız.${RESET}"; exit 1; }
                ;;
            arch)
                echo -e "${YELLOW}Pacman ile (ID_LIKE) sistem güncelleniyor...${RESET}"
                pacman -Syu --noconfirm || { echo -e "${RED}Pacman güncelleme başarısız.${RESET}"; exit 1; }
                ;;
            *)
                echo -e "${RED}Desteklenmeyen dağıtım: $distro (ID_LIKE: $id_like)${RESET}"
                exit 1
                ;;
        esac
        ;;
esac

# Snap güncelle
if command -v snap &> /dev/null; then
    echo -e "${YELLOW}Snap paketleri güncelleniyor...${RESET}"
    snap refresh
else
    echo -e "${RED}Snap yüklü değil, atlanıyor.${RESET}"
fi

# Flatpak güncelle
if command -v flatpak &> /dev/null; then
    echo -e "${YELLOW}Flatpak paketleri güncelleniyor...${RESET}"
    flatpak update -y
else
    echo -e "${RED}Flatpak yüklü değil, atlanıyor.${RESET}"
fi

# Tamamlandı
echo -e "${GREEN}✅ Tüm güncellemeler başarıyla tamamlandı.${RESET}"
