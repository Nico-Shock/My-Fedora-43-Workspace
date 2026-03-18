#!/bin/bash

# ============================================================
#           Fedora 43 Workspace Setup — Unified Script
# ============================================================

SPINNER_CHARS="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
SPINNER_PID=""
CURRENT_TASK=""
LOG_FILE="$(dirname "$0")/log.txt"
KEEPALIVE_PID=""
CURRENT_STEP=0
TOTAL_STEPS=0

# ── Config (set by user selection) ──────────────────────────
DE=""          # "kde" or "gnome"
IS_VM=""       # "y" or "n"
INSTALL_NVIDIA="n"

cleanup() {
    [[ -n "$SPINNER_PID" ]]   && kill "$SPINNER_PID"   2>/dev/null
    [[ -n "$KEEPALIVE_PID" ]] && kill "$KEEPALIVE_PID" 2>/dev/null
    printf "\n"
    exit
}
trap cleanup SIGINT SIGTERM

# ── UI helpers ───────────────────────────────────────────────

header() {
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                  Fedora 43 Workspace Setup                   ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
}

spinner() {
    local i=0
    while true; do
        printf "\r🔄 %s %s" "$CURRENT_TASK" "${SPINNER_CHARS:$((i % ${#SPINNER_CHARS})):1}"
        sleep 0.15
        ((i++))
    done
}

show_progress() {
    [[ -n "$SPINNER_PID" ]] && { kill "$SPINNER_PID" 2>/dev/null; wait "$SPINNER_PID" 2>/dev/null; printf "\n"; }
    CURRENT_STEP=$((CURRENT_STEP + 1))
    CURRENT_TASK="$1"
    clear
    header
    printf "📊 Overall Progress: %s/%s\n" "$CURRENT_STEP" "$TOTAL_STEPS"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    if [[ $CURRENT_STEP -le $TOTAL_STEPS ]]; then
        spinner &
        SPINNER_PID=$!
    fi
}

simulate_process_progress() {
    local steps=$1
    for ((i=1; i<=steps; i++)); do sleep 0.3; done
}

run_with_progress() {
    local steps=$1; shift
    local cmd="$*"
    local tmplog; tmplog=$(mktemp)
    simulate_process_progress "$steps" &
    local sim_pid=$!
    sleep 0.1
    eval "$cmd" > "$tmplog" 2>&1
    local rc=$?
    wait "$sim_pid"
    cat "$tmplog" >> "$LOG_FILE"
    if [[ $rc -ne 0 ]]; then
        echo "❌ Fehler bei: $cmd" | tee -a "$LOG_FILE"
        echo "----------------------------------------------------" | tee -a "$LOG_FILE"
        cat "$tmplog" | tee -a "$LOG_FILE"
        echo "----------------------------------------------------" | tee -a "$LOG_FILE"
    fi
    rm "$tmplog"
}

# ── Interactive selection ────────────────────────────────────

clear
header

echo "  Bitte wähle deine Konfiguration:"
echo ""

# Desktop Environment
echo "  [1] Desktop Environment"
echo "      1) KDE Plasma"
echo "      2) GNOME"
echo ""
read -rp "  ➤ Auswahl (1/2): " de_choice
case "$de_choice" in
    1) DE="kde" ;;
    2) DE="gnome" ;;
    *) echo "Ungültige Auswahl."; exit 1 ;;
esac

echo ""

# VM oder bare metal
echo "  [2] Umgebung"
echo "      1) Bare Metal (echter PC)"
echo "      2) Virtuelle Maschine"
echo ""
read -rp "  ➤ Auswahl (1/2): " vm_choice
case "$vm_choice" in
    1) IS_VM="n" ;;
    2) IS_VM="y" ;;
    *) echo "Ungültige Auswahl."; exit 1 ;;
esac

# NVIDIA nur auf bare metal anbieten
if [[ "$IS_VM" == "n" ]]; then
    echo ""
    echo "  [3] NVIDIA-Treiber installieren?"
    read -rp "  ➤ (y/n): " nvidia_choice
    [[ "$nvidia_choice" == "y" ]] && INSTALL_NVIDIA="y"
fi

# TOTAL_STEPS berechnen
# Basis-Steps (alle Varianten)
# 1 tools, 1 dnf-opt, 1 packages, 1 multimedia, 1 cachyos, 1 debloat, 1 icons, 1 font-inter, 1 zsh, 1 finalize = 10
TOTAL_STEPS=10
[[ "$INSTALL_NVIDIA" == "y" ]] && TOTAL_STEPS=$((TOTAL_STEPS + 1))
if [[ "$DE" == "kde" ]]; then
    TOTAL_STEPS=$((TOTAL_STEPS + 3))   # material-you, klassy-deps, klassy
elif [[ "$DE" == "gnome" ]]; then
    TOTAL_STEPS=$((TOTAL_STEPS + 3))   # extension-manager, mactahoe, rosepine
    [[ "$IS_VM" == "n" ]] && TOTAL_STEPS=$((TOTAL_STEPS + 1))  # gaming (nur bare metal)
fi
# gaming bei KDE bare metal
[[ "$DE" == "kde" && "$IS_VM" == "n" ]] && TOTAL_STEPS=$((TOTAL_STEPS + 1))

echo ""
echo "  Konfiguration:"
echo "    DE      : $DE"
echo "    VM      : $IS_VM"
echo "    NVIDIA  : $INSTALL_NVIDIA"
echo "    Steps   : $TOTAL_STEPS"
echo ""
read -rp "➤ Start Transforming? (y/n): " start_transform
[[ "$start_transform" != "y" ]] && { echo "Setup cancelled."; exit 0; }

> "$LOG_FILE"

# sudo keepalive
sudo -v
while true; do
    sudo -n true
    sleep 60
    kill -0 "$$" 2>/dev/null || exit
done &
KEEPALIVE_PID=$!

# ── STEPS ────────────────────────────────────────────────────

show_progress "Installing required tools"
run_with_progress 3 sudo dnf install -y wget unzip git

show_progress "Optimizing DNF"
run_with_progress 2 sudo sed -i "/^max_parallel_downloads=/d" /etc/dnf/dnf.conf
run_with_progress 2 sudo sed -i "/^fastestmirror=/d" /etc/dnf/dnf.conf
run_with_progress 2 bash -c 'echo "max_parallel_downloads=20" | sudo tee -a /etc/dnf/dnf.conf'
run_with_progress 2 bash -c 'echo "fastestmirror=True" | sudo tee -a /etc/dnf/dnf.conf'

show_progress "Installing additional packages"
if [[ "$DE" == "gnome" ]]; then
    run_with_progress 8 sudo dnf install -y flatpak git wget gedit thermald ufw fzf python3 python3-pip bluez blueman bluez-libs fastfetch vim gnome-tweaks
else
    run_with_progress 8 sudo dnf install -y flatpak git wget kate thermald ufw fzf python3 python3-pip bluez blueman bluez-libs fastfetch vim
fi
run_with_progress 2 sudo systemctl enable --now bluetooth ufw
run_with_progress 1 sudo ufw default deny

show_progress "Installing multimedia"
run_with_progress 5 sudo dnf group install -y multimedia

if [[ "$INSTALL_NVIDIA" == "y" ]]; then
    show_progress "Installing NVIDIA drivers"
    run_with_progress 10 sudo dnf install -y @base-x kernel-devel kernel-headers gcc make dkms acpid libglvnd-devel pkgconf xorg-x11-server-Xwayland libxcb egl-wayland akmod-nvidia xorg-x11-drv-nvidia-cuda --skip-broken --allowerasing
    run_with_progress 2 sudo sh -c 'echo "blacklist nouveau" >> /etc/modprobe.d/blacklist.conf'
    run_with_progress 2 sudo sh -c 'echo "blacklist nova_core" >> /etc/modprobe.d/blacklist.conf'
    run_with_progress 2 sudo sh -c 'echo "options nvidia NVreg_PreserveVideoMemoryAllocations=1" >> /etc/modprobe.d/nvidia.conf'
    run_with_progress 2 sudo sh -c 'echo "options nvidia-drm modeset=1 fbdev=0" >> /etc/modprobe.d/nvidia.conf'
fi

show_progress "Installing CachyOS Kernel"
run_with_progress 4 sudo dnf copr enable -y bieszczaders/kernel-cachyos
run_with_progress 6 sudo dnf install -y kernel-cachyos kernel-cachyos-devel-matched
run_with_progress 3 sudo dnf copr enable -y bieszczaders/kernel-cachyos-addons
run_with_progress 5 sudo dnf install -y cachyos-settings --allowerasing

# Gaming nur auf bare metal
if [[ "$IS_VM" == "n" ]]; then
    show_progress "Installing gaming packages"
    run_with_progress 12 sudo dnf install -y @c-development @development-tools steam lutris wine bottles gamescope mangohud libva-utils vulkan-tools mesa-dri-drivers mesa-vulkan-drivers gamemode libadwaita wine-dxvk dxvk-native goverlay --skip-broken
    run_with_progress 3 sudo dnf copr enable -y atim/heroic-games-launcher
    run_with_progress 4 sudo dnf install -y heroic-games-launcher-bin
fi

show_progress "Debloating desktop"
run_with_progress 8 sudo dnf remove -y gnome-contacts gnome-maps mediawriter totem simple-scan gnome-boxes gnome-user-docs rhythmbox evince gnome-photos gnome-documents gnome-initial-setup yelp winhelp32 dosbox winehelp fedora-release-notes gnome-characters gnome-logs fonts-tweak-tool timeshift epiphany gnome-weather cheese pavucontrol qt5-settings

# ── DE-spezifisch ────────────────────────────────────────────

if [[ "$DE" == "gnome" ]]; then

    show_progress "Installing Extension Manager"
    run_with_progress 6 sudo flatpak install -y flathub com.mattjakeman.ExtensionManager

    show_progress "Installing MacTahoe theme"
    TEMP_DIR=$(mktemp -d)
    run_with_progress 4 git clone --depth 1 https://github.com/vinceliuice/MacTahoe-gtk-theme.git "$TEMP_DIR/MacTahoe-gtk-theme"
    cd "$TEMP_DIR/MacTahoe-gtk-theme"
    run_with_progress 6 ./install.sh -l
    cd /tmp; sudo rm -rf "$TEMP_DIR"

    show_progress "Installing Rose Pine theme"
    TEMP_DIR=$(mktemp -d)
    run_with_progress 2 sudo dnf install -y gtk-murrine-engine
    run_with_progress 4 git clone --depth 1 https://github.com/Fausto-Korpsvart/Rose-Pine-GTK-Theme.git "$TEMP_DIR/Rose-Pine-GTK-Theme"
    cd "$TEMP_DIR/Rose-Pine-GTK-Theme/themes"
    run_with_progress 7 ./install.sh -c dark
    cd /tmp; sudo rm -rf "$TEMP_DIR"

elif [[ "$DE" == "kde" ]]; then

    show_progress "Installing Material You Colors"
    run_with_progress 4 sudo dnf install -y pipx gcc python3-devel glib2-devel dbus-devel
    run_with_progress 8 pipx install kde-material-you-colors
    run_with_progress 3 pipx inject kde-material-you-colors pywal16

    show_progress "Installing Klassy dependencies"
    run_with_progress 3 sudo dnf install -y git cmake extra-cmake-modules gettext
    run_with_progress 10 sudo dnf install -y \
        "cmake(KF5Config)" "cmake(KF5CoreAddons)" "cmake(KF5FrameworkIntegration)" \
        "cmake(KF5GuiAddons)" "cmake(KF5Kirigami2)" "cmake(KF5WindowSystem)" \
        "cmake(KF5I18n)" "cmake(Qt5DBus)" "cmake(Qt5Quick)" "cmake(Qt5Widgets)" \
        "cmake(Qt5X11Extras)" "cmake(KDecoration3)" "cmake(KF6ColorScheme)" \
        "cmake(KF6Config)" "cmake(KF6CoreAddons)" "cmake(KF6FrameworkIntegration)" \
        "cmake(KF6GuiAddons)" "cmake(KF6I18n)" "cmake(KF6KCMUtils)" \
        "cmake(KF6KirigamiPlatform)" "cmake(KF6WindowSystem)" "cmake(Qt6Core)" \
        "cmake(Qt6DBus)" "cmake(Qt6Quick)" "cmake(Qt6Svg)" "cmake(Qt6Widgets)" "cmake(Qt6Xml)"

    show_progress "Installing Klassy"
    TEMP_DIR=$(mktemp -d)
    run_with_progress 4 git clone --depth 1 https://github.com/paulmcauley/klassy.git "$TEMP_DIR/klassy"
    cd "$TEMP_DIR/klassy"
    run_with_progress 12 ./install.sh
    cd /tmp; sudo rm -rf "$TEMP_DIR"

fi

# ── Gemeinsam: Icons, Cursor (GNOME), Inter Font, Zsh ────────

show_progress "Installing Tela Circle icons"
TEMP_DIR=$(mktemp -d)
run_with_progress 4 git clone --depth 1 https://github.com/vinceliuice/Tela-circle-icon-theme.git "$TEMP_DIR/Tela-circle-icon-theme"
cd "$TEMP_DIR/Tela-circle-icon-theme"
run_with_progress 8 ./install.sh -a
cd /tmp; sudo rm -rf "$TEMP_DIR"

if [[ "$DE" == "gnome" ]]; then
    run_with_progress 5 sudo dnf install -y breeze-cursor-theme
fi

show_progress "Installing Inter Font"
TEMP_DIR=$(mktemp -d)
run_with_progress 5 wget -q "https://github.com/rsms/inter/releases/download/v4.0/Inter-4.0.zip" -O "$TEMP_DIR/Inter.zip"
run_with_progress 3 unzip -q "$TEMP_DIR/Inter.zip" -d "$TEMP_DIR/Inter_font"
run_with_progress 4 sudo mkdir -p /usr/local/share/fonts/Inter
run_with_progress 6 sudo cp "$TEMP_DIR/Inter_font/Inter-roman/"*.ttf /usr/local/share/fonts/Inter/
run_with_progress 2 fc-cache -f -v
sudo rm -rf "$TEMP_DIR"

show_progress "Setting up Zsh and Nerd Fonts"
run_with_progress 4 sudo dnf install -y zsh dejavu-sans-mono-fonts powerline-fonts
run_with_progress 3 git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/powerlevel10k
run_with_progress 1 sh -c 'echo "source ~/powerlevel10k/powerlevel10k.zsh-theme" >> ~/.zshrc'
run_with_progress 2 chsh -s "$(which zsh)"

if [[ "$DE" == "gnome" ]]; then
    PTYXIS_PROFILE=$(gsettings get org.gnome.Ptyxis default-profile-uuid 2>/dev/null | tr -d "'" || echo "")
    if [[ -n "$PTYXIS_PROFILE" ]]; then
        run_with_progress 1 gsettings set "org.gnome.Ptyxis.Profile:/org/gnome/Ptyxis/Profiles/$PTYXIS_PROFILE/" opacity 0.70
    fi
fi

TEMP_DIR=$(mktemp -d)
run_with_progress 5 git clone --depth 1 https://github.com/ryanoasis/nerd-fonts.git "$TEMP_DIR/nerd-fonts"
cd "$TEMP_DIR/nerd-fonts"
run_with_progress 6 ./install.sh JetBrainsMono Hack FiraCode
cd /tmp; sudo rm -rf "$TEMP_DIR"

show_progress "Finalizing configuration"
run_with_progress 8 sudo dracut -f --regenerate-all
run_with_progress 4 sudo grub2-mkconfig -o /boot/grub2/grub.cfg
run_with_progress 2 sudo dnf clean all

# ── Abschluss ─────────────────────────────────────────────────

[[ -n "$SPINNER_PID" ]]   && { kill "$SPINNER_PID" 2>/dev/null; wait "$SPINNER_PID" 2>/dev/null; }
[[ -n "$KEEPALIVE_PID" ]] && kill "$KEEPALIVE_PID" 2>/dev/null

clear
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                 ✨ Transformation Complete! ✨                ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
printf "📊 Overall Progress: %s/%s\n" "$TOTAL_STEPS" "$TOTAL_STEPS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🎯 Manual steps required:"
if [[ "$DE" == "kde" ]]; then
    echo "    • Configure Klassy theme settings in System Settings"
    echo "    • Set Konsole font to DejaVu Sans Mono (or Inter)"
elif [[ "$DE" == "gnome" ]]; then
    echo "    • Install GNOME extensions via Extension Manager"
    echo "    • Configure themes in GNOME Tweaks"
    echo "    • Set Ptyxis font to DejaVu Sans Mono (or Inter)"
fi
echo "    • Run 'p10k configure' to setup Powerlevel10k"
echo ""
echo "🔄 System update and reboot required!"
read -rp "    Update system and reboot now? (y/n): " update_reboot
if [[ "$update_reboot" == "y" ]]; then
    sudo dnf update -y && sudo reboot now
fi
