#!/bin/bash

# Renk tanımları
GREEN="\e[32m"
RED="\e[31m"
YELLOW="\e[33m"
RESET="\e[0m"

# Log dosyası
LOG_FILE="/var/log/system-update.log"
exec 1>>"$LOG_FILE" 2>&1
echo "Güncelleme işlemi başladı: $(date)"

# Network kontrolü
echo -e "${YELLOW}İnternet bağlantısı kontrol ediliyor...${RESET}"
if ! ping -c 1 8.8.8.8 &> /dev/null; then
    echo -e "${RED}İnternet bağlantısı yok. Lütfen bağlantınızı kontrol edin.${RESET}"
    echo "Hata: İnternet bağlantısı yok - $(date)" >> "$LOG_FILE"
    exit 1
fi

# Root kontrolü
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}Bu betik root olarak çalıştırılmalıdır. Lütfen 'sudo' ile çalıştırın.${RESET}"
    echo "Hata: Root yetkisi gerekli - $(date)" >> "$LOG_FILE"
    exit 1
fi

# Kullanıcıya bilgi
echo -e "${GREEN}Sistem güncelleme işlemi başlatılıyor...${RESET}"
echo -e "${YELLOW}Lütfen güncelleme sırasında sistemi kapatmayın veya yeniden başlatmayın.${RESET}"
echo -e "${YELLOW}ÖNEMLİ: Güncellemeden önce önemli verilerinizi yedekleyin.${RESET}"

# Dağıtımı belirle
distro=$(grep '^ID=' /etc/os-release | cut -d'=' -f2 | tr -d '"' | tr '[:upper:]' '[:lower:]')
id_like=$(grep '^ID_LIKE=' /etc/os-release | cut -d'=' -f2 | tr -d '"' | tr '[:upper:]' '[:lower:]')

echo -e "${GREEN}Dağıtım algılandı: $distro${RESET}"
echo "Dağıtım: $distro, ID_LIKE: $id_like - $(date)" >> "$LOG_FILE"

# Hata mesajı yakalama fonksiyonu
capture_error() {
    local cmd_output="$1"
    local cmd_name="$2"
    echo -e "${RED}$cmd_name güncelleme başarısız: $cmd_output${RESET}"
    echo "Hata: $cmd_name güncelleme başarısız - $cmd_output - $(date)" >> "$LOG_FILE"
    exit 1
}

# Paket yöneticisine göre güncelle
case "$distro" in
    ubuntu|debian|linuxmint|elementary)
        echo -e "${YELLOW}APT ile sistem güncelleniyor...${RESET}"
        error=$(apt update 2>&1) || capture_error "$error" "APT update"
        error=$(apt upgrade -y 2>&1) || capture_error "$error" "APT upgrade"
        echo "APT güncelleme tamamlandı - $(date)" >> "$LOG_FILE"
        ;;
    fedora|rhel|centos)
        echo -e "${YELLOW}DNF ile sistem güncelleniyor...${RESET}"
        error=$(dnf upgrade --refresh -y 2>&1) || capture_error "$error" "DNF"
        echo "DNF güncelleme tamamlandı - $(date)" >> "$LOG_FILE"
        ;;
    arch|manjaro|cachyos)
        echo -e "${YELLOW}Pacman ile sistem güncelleniyor...${RESET}"
        error=$(pacman -Syu --noconfirm 2>&1) || capture_error "$error" "Pacman"
        echo "Pacman güncelleme tamamlandı - $(date)" >> "$LOG_FILE"

        if command -v yay &> /dev/null; then
            echo -e "${YELLOW}Yay ile AUR güncelleniyor...${RESET}"
            error=$(yay -Syu --noconfirm 2>&1) || capture_error "$error" "Yay"
            echo "Yay güncelleme tamamlandı - $(date)" >> "$LOG_FILE"
        else
            echo -e "${RED}yay yüklü değil, atlanıyor.${RESET}"
            echo "yay yüklü değil - $(date)" >> "$LOG_FILE"
        fi

        if command -v paru &> /dev/null; then
            echo -e "${YELLOW}Paru ile AUR güncelleniyor...${RESET}"
            error=$(paru -Syu --noconfirm 2>&1) || capture_error "$error" "Paru"
            echo "Paru güncelleme tamamlandı - $(date)" >> "$LOG_FILE"
        else
            echo -e "${RED}paru yüklü değil, atlanıyor.${RESET}"
            echo "paru yüklü değil - $(date)" >> "$LOG_FILE"
        fi
        ;;
    opensuse|suse)
        echo -e "${YELLOW}Zypper ile sistem güncelleniyor...${RESET}"
        error=$(zypper refresh 2>&1) || capture_error "$error" "Zypper refresh"
        error=$(zypper update -y 2>&1) || capture_error "$error" "Zypper update"
        echo "Zypper güncelleme tamamlandı - $(date)" >> "$LOG_FILE"
        ;;
    *)
        case "$id_like" in
            *debian*)
                echo -e "${YELLOW}APT ile (ID_LIKE) sistem güncelleniyor...${RESET}"
                error=$(apt update 2>&1) || capture_error "$error" "APT update (ID_LIKE)"
                error=$(apt upgrade -y 2>&1) || capture_error "$error" "APT upgrade (ID_LIKE)"
                echo "APT (ID_LIKE) güncelleme tamamlandı - $(date)" >> "$LOG_FILE"
                ;;
            *rhel*|*fedora*)
                echo -e "${YELLOW}DNF ile (ID_LIKE) sistem güncelleniyor...${RESET}"
                error=$(dnf upgrade --refresh -y 2>&1) || capture_error "$error" "DNF (ID_LIKE)"
                echo "DNF (ID_LIKE) güncelleme tamamlandı - $(date)" >> "$LOG_FILE"
                ;;
            *arch*)
                echo -e "${YELLOW}Pacman ile (ID_LIKE) sistem güncelleniyor...${RESET}"
                error=$(pacman -Syu --noconfirm 2>&1) || capture_error "$error" "Pacman (ID_LIKE)"
                echo "Pacman (ID_LIKE) güncelleme tamamlandı - $(date)" >> "$LOG_FILE"
                ;;
            *)
                echo -e "${RED}Desteklenmeyen dağıtım: $distro (ID_LIKE: $id_like)${RESET}"
                echo "Hata: Desteklenmeyen dağıtım: $distro (ID_LIKE: $id_like) - $(date)" >> "$LOG_FILE"
                exit 1
                ;;
        esac
        ;;
esac

# Snap güncelle
if command -v snap &> /dev/null; then
    echo -e "${YELLOW}Snap paketleri güncelleniyor...${RESET}"
    error=$(snap refresh 2>&1) || capture_error "$error" "Snap"
    echo "Snap güncelleme tamamlandı - $(date)" >> "$LOG_FILE"
else
    echo -e "${RED}Snap yüklü değil, atlanıyor.${RESET}"
    echo "Snap yüklü değil - $(date)" >> "$LOG_FILE"
fi

# Flatpak güncelle
if command -v flatpak &> /dev/null; then
    echo -e "${YELLOW}Flatpak paketleri güncelleniyor...${RESET}"
    error=$(flatpak update -y 2>&1) || capture_error "$error" "Flatpak"
    echo "Flatpak güncelleme tamamlandı - $(date)" >> "$LOG_FILE"
else
    echo -e "${RED}Flatpak yüklü değil, atlanıyor.${RESET}"
    echo "Flatpak yüklü değil - $(date)" >> "$LOG_FILE"
fi

# Yeniden başlatma kontrolü
if [ -f /var/run/reboot-required ]; then
    echo -e "${YELLOW}Sistem güncellemeleri sonrası yeniden başlatma gerekiyor.${RESET}"
    echo "Yeniden başlatma gerekli - $(date)" >> "$LOG_FILE"
fi

# Tamamlandı
echo -e "${GREEN}✅ Tüm güncellemeler başarıyla tamamlandı.${RESET}"
echo "Güncelleme işlemi tamamlandı - $(date)" >> "$LOG_FILE"
