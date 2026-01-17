#!/bin/bash

TOTAL_STEPS=14
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
    local overall_percent=$((CURRENT_STEP * 100 / TOTAL_STEPS))
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                   Fedora 43 Workspace Setup                    ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
    printf "📊 Overall Progress: [%02d%%] %s/%s\n" "$overall_percent" "$CURRENT_STEP" "$TOTAL_STEPS"
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

install_nvidia="n"
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
run_with_progress 8 sudo dnf install -y flatpak git wget gedit thermald ufw fzf python3 python3-pip bluez blueman bluez-libs fastfetch vim gnome-tweaks
run_with_progress 2 sudo systemctl enable --now bluetooth ufw
run_with_progress 1 sudo ufw default deny

show_progress "Installing multimedia"
run_with_progress 5 sudo dnf group install -y multimedia

show_progress "Installing CachyOS Kernel"
run_with_progress 4 sudo dnf copr enable -y bieszczaders/kernel-cachyos
run_with_progress 6 sudo dnf install -y kernel-cachyos kernel-cachyos-devel-matched
run_with_progress 3 sudo dnf copr enable -y bieszczaders/kernel-cachyos-addons
run_with_progress 5 sudo dnf install -y cachyos-settings --allowerasing

show_progress "Debloating desktop"
run_with_progress 8 sudo dnf remove -y gnome-contacts gnome-maps mediawriter totem simple-scan gnome-boxes gnome-user-docs rhythmbox evince gnome-photos gnome-documents gnome-initial-setup yelp winhelp32 dosbox winehelp fedora-release-notes gnome-characters gnome-logs fonts-tweak-tool timeshift epiphany gnome-weather cheese pavucontrol qt5-settings
run_with_progress 2 sudo dnf clean all

show_progress "Installing Firefox ESR"
run_with_progress 5 sudo dnf install -y firefox-esr

show_progress "Installing Extension Manager"
run_with_progress 6 sudo flatpak install -y flathub com.mattjakeman.ExtensionManager

show_progress "Installing MacTahoe theme"
cd /tmp
run_with_progress 4 git clone --depth 1 https://github.com/vinceliuice/MacTahoe-gtk-theme.git
cd MacTahoe-gtk-theme
run_with_progress 6 ./install.sh -l
cd /tmp
run_with_progress 1 sudo rm -rf MacTahoe-gtk-theme

show_progress "Installing Rose Pine theme"
cd /tmp
run_with_progress 2 sudo dnf install -y gtk-murrine-engine
run_with_progress 4 git clone --depth 1 https://github.com/Fausto-Korpsvart/Rose-Pine-GTK-Theme.git
cd Rose-Pine-GTK-Theme/themes
run_with_progress 7 ./install.sh -c dark
cd /tmp
run_with_progress 1 sudo rm -rf Rose-Pine-GTK-Theme

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

show_progress "Installing Bibata Cursor"
cd /tmp
run_with_progress 5 wget -q --show-progress "https://github.com/ful1e5/Bibata_Cursor/releases/download/v2.0.7/Bibata-Modern-Classic.tar.xz" -O Bibata-Modern-Classic.tar.xz
run_with_progress 3 sudo tar -xf Bibata-Modern-Classic.tar.xz -C /usr/share/icons/
run_with_progress 2 sudo gtk-update-icon-cache -f -t /usr/share/icons/Bibata-Modern-Classic
run_with_progress 1 rm Bibata-Modern-Classic.tar.xz

show_progress "Setting up Zsh and fonts"
run_with_progress 4 sudo dnf install -y zsh dejavu-sans-mono-fonts powerline-fonts
cd $HOME
run_with_progress 3 git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/powerlevel10k
run_with_progress 1 sh -c 'echo "source ~/powerlevel10k/powerlevel10k.zsh-theme" >> ~/.zshrc'
run_with_progress 2 chsh -s $(which zsh)

PTYXIS_PROFILE=$(gsettings get org.gnome.Ptyxis default-profile-uuid 2>/dev/null | tr -d "'" || echo "")
if [[ -n "$PTYXIS_PROFILE" ]]; then
    run_with_progress 1 gsettings set "org.gnome.Ptyxis.Profile:/org/gnome/Ptyxis/Profiles/$PTYXIS_PROFILE/" opacity 0.70
fi

cd /tmp
run_with_progress 5 git clone --depth 1 https://github.com/ryanoasis/nerd-fonts.git
cd nerd-fonts
run_with_progress 10 ./install.sh
cd /tmp
run_with_progress 1 sudo rm -rf nerd-fonts

show_progress "Finalizing configuration"
run_with_progress 8 sudo dracut -f --regenerate-all
run_with_progress 4 sudo grub2-mkconfig -o /boot/grub2/grub.cfg

if [[ -n "$SPINNER_PID" ]]; then
    kill $SPINNER_PID 2>/dev/null
    wait $SPINNER_PID 2>/dev/null
fi

clear
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                   ✨ Transformation Complete! ✨                 ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
printf "📊 Overall Progress: [100%%] %s/%s\n" "$TOTAL_STEPS" "$TOTAL_STEPS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🎯 Manual steps required:"
echo "    • Install GNOME extensions via Extension Manager"
echo "    • Configure themes in GNOME Tweaks"
echo "    • Set Ptyxis font to DejaVu Sans Mono (or Inter)"
echo "    • Run 'p10k configure' to setup Powerlevel10k"
echo ""
echo "🔄 System update and reboot required!"
read -p "    Update system and reboot now? (y/n): " update_reboot
if [[ "$update_reboot" == "y" ]]; then
    sudo dnf update -y && sudo reboot now
fi