#!/bin/bash

TOTAL_STEPS=15
CURRENT_STEP=0
CURRENT_PROCESS_STEPS=1
CURRENT_PROCESS_STEP=0
SPINNER_CHARS="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
SPINNER_PID=""
CURRENT_TASK=""
LOG_FILE="$(dirname "$0")/log.txt"

cleanup() {
    if [[ -n "$SPINNER_PID" ]]; then
        kill $SPINNER_PID 2>/dev/null
    fi
    printf "\n"
    exit
}

trap cleanup SIGINT SIGTERM

simulate_process_progress() {
    CURRENT_PROCESS_STEP=0
    local steps=$1
    CURRENT_PROCESS_STEPS=$steps
    for ((i=1; i<=steps; i++)); do
        CURRENT_PROCESS_STEP=$i
        sleep 0.3
    done
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
    if [[ -n "$SPINNER_PID" ]]; then
        kill $SPINNER_PID 2>/dev/null
        wait $SPINNER_PID 2>/dev/null
        printf "\n"
    fi
    CURRENT_STEP=$((CURRENT_STEP + 1))
    CURRENT_TASK="$1"
    clear
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                   Fedora 43 Workspace Setup                    ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
    printf "📊 Overall Progress: %s/%s\n" "$CURRENT_STEP" "$TOTAL_STEPS"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    if [[ $CURRENT_STEP -le $TOTAL_STEPS ]]; then
        spinner &
        SPINNER_PID=$!
    fi
}

run_with_progress() {
    local steps=$1
    shift
    local cmd_to_run="$@"
    local temp_log=$(mktemp)
    simulate_process_progress $steps &
    local sim_pid=$!
    sleep 0.1
    eval "$cmd_to_run" > "$temp_log" 2>&1
    local exit_status=$?
    wait $sim_pid
    
    # Log everything to file for debugging
    cat "$temp_log" >> "$LOG_FILE"
    
    if [[ $exit_status -ne 0 ]]; then
        echo "❌ Fehler bei: $cmd_to_run" | tee -a "$LOG_FILE"
        echo "----------------------------------------------------" | tee -a "$LOG_FILE"
        cat "$temp_log" | tee -a "$LOG_FILE"
        echo "----------------------------------------------------" | tee -a "$LOG_FILE"
    fi
    rm "$temp_log"
}

clear
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                   Fedora 43 Workspace Setup                    ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

read -p "➤ Start Transforming? (y/n): " start_transform
echo ""

if [[ "$start_transform" != "y" ]]; then
    echo "Setup cancelled."
    exit 0
fi

install_nvidia="y"
> "$LOG_FILE"

show_progress "Installing required tools"
run_with_progress 3 sudo dnf install -y wget unzip git

show_progress "Optimizing DNF"
run_with_progress 3 bash -c '
sudo sed -i "/^max_parallel_downloads=/d" /etc/dnf/dnf.conf
sudo sed -i "/^fastestmirror=/d" /etc/dnf/dnf.conf
echo -e "max_parallel_downloads=20\nfastestmirror=True" | sudo tee -a /etc/dnf/dnf.conf
'

show_progress "Installing additional packages"
run_with_progress 8 sudo dnf install -y flatpak git wget kate thermald ufw fzf python3 python3-pip bluez blueman bluez-libs fastfetch vim
run_with_progress 2 sudo systemctl enable --now bluetooth ufw
run_with_progress 1 sudo ufw default deny

show_progress "Installing multimedia"
run_with_progress 5 sudo dnf group install -y multimedia

if [[ "$install_nvidia" == "y" ]]; then
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

show_progress "Installing gaming packages"
run_with_progress 12 sudo dnf install -y @c-development @development-tools steam lutris wine bottles gamescope mangohud libva-utils vulkan-tools mesa-dri-drivers mesa-vulkan-drivers gamemode libadwaita wine-dxvk dxvk-native goverlay --skip-broken
run_with_progress 3 sudo dnf copr enable -y atim/heroic-games-launcher
run_with_progress 4 sudo dnf install -y heroic-games-launcher-bin

show_progress "Debloating desktop"
run_with_progress 8 sudo dnf remove -y gnome-contacts gnome-maps mediawriter totem simple-scan gnome-boxes gnome-user-docs rhythmbox evince gnome-photos gnome-documents gnome-initial-setup yelp winhelp32 dosbox winehelp fedora-release-notes gnome-characters gnome-logs fonts-tweak-tool timeshift epiphany gnome-weather cheese pavucontrol qt5-settings
run_with_progress 2 sudo dnf clean all

show_progress "Installing Material You Colors"
run_with_progress 4 sudo dnf install -y pipx gcc python3-devel glib2-devel
run_with_progress 8 pipx install kde-material-you-colors
run_with_progress 3 pipx inject kde-material-you-colors pywal16

show_progress "Installing Klassy dependencies"
run_with_progress 3 sudo dnf install -y git cmake extra-cmake-modules gettext
run_with_progress 10 sudo dnf install -y "cmake(KF5Config)" "cmake(KF5CoreAddons)" "cmake(KF5FrameworkIntegration)" "cmake(KF5GuiAddons)" "cmake(KF5Kirigami2)" "cmake(KF5WindowSystem)" "cmake(KF5I18n)" "cmake(Qt5DBus)" "cmake(Qt5Quick)" "cmake(Qt5Widgets)" "cmake(Qt5X11Extras)" "cmake(KDecoration3)" "cmake(KF6ColorScheme)" "cmake(KF6Config)" "cmake(KF6CoreAddons)" "cmake(KF6FrameworkIntegration)" "cmake(KF6GuiAddons)" "cmake(KF6I18n)" "cmake(KF6KCMUtils)" "cmake(KF6KirigamiPlatform)" "cmake(KF6WindowSystem)" "cmake(Qt6Core)" "cmake(Qt6DBus)" "cmake(Qt6Quick)" "cmake(Qt6Svg)" "cmake(Qt6Widgets)" "cmake(Qt6Xml)"

show_progress "Installing Klassy"
cd /tmp
run_with_progress 4 git clone --depth 1 https://github.com/paulmcauley/klassy.git
cd klassy
run_with_progress 12 ./install.sh
cd /tmp
run_with_progress 1 sudo rm -rf klassy

show_progress "Installing Tela Circle icons"
cd /tmp
run_with_progress 4 git clone --depth 1 https://github.com/vinceliuice/Tela-circle-icon-theme.git
cd Tela-circle-icon-theme
run_with_progress 8 ./install.sh -a
cd /tmp
run_with_progress 1 sudo rm -rf Tela-circle-icon-theme

show_progress "Installing Inter Font"
cd /tmp
run_with_progress 5 wget -q --show-progress "https://github.com/rsms/inter/releases/download/v4.0/Inter-4.0.zip" -O Inter.zip
run_with_progress 3 unzip -q Inter.zip -d Inter_font
run_with_progress 4 sudo mkdir -p /usr/local/share/fonts/Inter
run_with_progress 6 sudo cp Inter_font/Inter-roman/*.ttf /usr/local/share/fonts/Inter/
run_with_progress 2 fc-cache -f -v
run_with_progress 1 rm -rf Inter.zip Inter_font

show_progress "Setting up Zsh and fonts"
run_with_progress 4 sudo dnf install -y zsh dejavu-sans-mono-fonts powerline-fonts
cd $HOME
run_with_progress 3 git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/powerlevel10k
run_with_progress 1 sh -c 'echo "source ~/powerlevel10k/powerlevel10k.zsh-theme" >> ~/.zshrc'
run_with_progress 2 chsh -s $(which zsh)

cd /tmp
run_with_progress 5 git clone --depth 1 https://github.com/ryanoasis/nerd-fonts.git
cd nerd-fonts
run_with_progress 6 ./install.sh JetBrainsMono Hack FiraCode
cd /tmp
run_with_progress 1 sudo rm -rf nerd-fonts

show_progress "Finalizing configuration"
run_with_progress 8 sudo dracut -f --regenerate-all
run_with_progress 4 sudo grub2-mkconfig -o /boot/grub2/grub.cfg

# Stop spinner immediately after last step
if [[ -n "$SPINNER_PID" ]]; then
    kill $SPINNER_PID 2>/dev/null
    wait $SPINNER_PID 2>/dev/null
fi

clear
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                   ✨ Transformation Complete! ✨                 ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
printf "📊 Overall Progress: %s/%s\n" "$TOTAL_STEPS" "$TOTAL_STEPS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🎯 Manual steps required:"
echo "    • Configure Klassy theme settings in System Settings"
echo "    • Set Konsole font to DejaVu Sans Mono (or Inter)"
echo "    • Run 'p10k configure' to setup Powerlevel10k"
echo ""
echo "🔄 System update and reboot required!"
read -p "    Update system and reboot now? (y/n): " update_reboot
if [[ "$update_reboot" == "y" ]]; then
    sudo dnf update -y && sudo reboot now
fi
