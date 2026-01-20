[Hi :)](https://nico-shock.github.io/My-Fedora43-Workspace/)

(The Bash scripts are still not working correctly.)

# General Steps

### Additional Packages Installation

Install additional packages:
```
sudo dnf in -y flatpak git wget gedit thermald ufw fzf python3 python3-pip bluez blueman bluez-libs fastfetch vim gnome-tweaks 
sudo systemctl enable --now bluetooth ufw
sudo ufw default deny
```

```
sudo dnf group install multimedia
```

### Make Download Faster
```
sudo vim /etc/dnf/dnf.conf
```
Add the following lines:
```
max_parallel_downloads=20
fastestmirror=True
```

### Update System
```
sudo dnf up -y && sudo reboot now
```

### Install Nvidia Drivers
```
sudo dnf in -y @base-x kernel-devel kernel-headers gcc make dkms acpid libglvnd-devel pkgconf xorg-x11-server-Xwayland libxcb egl-wayland akmod-nvidia xorg-x11-drv-nvidia-cuda --skip-broken --allowerasing
sudo reboot now
```

```
sudo su
```

```
echo "blacklist nouveau" >> /etc/modprobe.d/blacklist.conf
echo "blacklist nova_core" >> /etc/modprobe.d/blacklist.conf
```

```
echo "options nvidia NVreg_PreserveVideoMemoryAllocations=1" >> /etc/modprobe.d/nvidia.conf
echo "options nvidia-drm modeset=1 fbdev=0" >> /etc/modprobe.d/nvidia.conf
```

### Installing the CachyOS Kernel
```
sudo dnf copr enable bieszczaders/kernel-cachyos
sudo dnf in -y kernel-cachyos kernel-cachyos-devel-matched
sudo dnf copr enable bieszczaders/kernel-cachyos-addons
sudo dnf in -y cachyos-settings --allowerasing
sudo dracut -f --regenerate-all
sudo grub2-mkconfig -o /boot/grub2/grub.cfg
```

### Installing Gaming Meta
```
sudo dnf in -y @c-development @development-tools steam lutris wine bottles gamescope mangohud libva-utils vulkan-tools mesa-dri-drivers mesa-vulkan-drivers gamemode libadwaita wine-dxvk dxvk-native goverlay --skip-broken
sudo dnf copr enable atim/heroic-games-launcher
sudo dnf in -y heroic-games-launcher-bin
```

### Debloating Desktop
```
sudo dnf rm -y gnome-contacts gnome-maps mediawriter totem simple-scan gnome-boxes gnome-user-docs rhythmbox evince gnome-photos gnome-documents gnome-initial-setup yelp winhelp32 dosbox winehelp fedora-release-notes gnome-characters gnome-logs fonts-tweak-tool timeshift epiphany gnome-weather cheese pavucontrol qt5-settings
sudo dnf clean all
```

### Install Firefox ESR

```
sudo dnf install -y firefox-esr
```

# Gnome Setup

## Extensions

- Blur My Shell  
- Just Perfection  
- Dash to Dock  
- Arc Menu (outdated) 
- Coverflow  
- Impatience  
- Gnome 4x UI Improvements  
- Caffeine   
- Open Bar  
- User Themes  
- System Monitor
- Extension List

## Extension Settings

### Blur My Shell:

- Default Rounded Pipeline: Radius 20, Brightness: 100  
- Panel: Dynamic: 30, Sigma: Brightness: 1.00  
- Applications: opaque focused windows: off, blur in overview: off, enable all by default: on, disable manually: browser

### Dash to Dock:

- Intelligent auto-hide: off  
- Size: 20
- Menu moved to the left  
- Show drives and devices: off  
- Minimize appearance: on  
- Window counter indicators: dots

### Just Perfection:

- Panel button spacing: 0px  
- Panel indicator spacing: 2px  
- Clock position: left + 1pt offset

### Open Bar:

#### Autotheming:
- Auto Refresh theme on background change: on
- Auto set bar margins and island bg alpha: off

#### Topbar properties:
- Type: Islands
- Apply in overview: on
- enable buttons proximity: off
- Bar Margins: 0
- Bar Height: 32

#### Dash/Dock:
- Style: Use top bar colors
- Disable Shadows
- Dock Size: 20

#### Gnome Shell:
- enable everything

Here are more of my custom configs:

- https://github.com/Nico-Shock/My-OpenBar-configs

## Commands

### Extensions Manager Installation:
```
flatpak install flathub com.mattjakeman.ExtensionManager
```

### MacOS Tahoe GTK Theme:
```
git clone https://github.com/vinceliuice/MacTahoe-gtk-theme.git --depth 1
cd MacTahoe-gtk-theme
./install.sh -l 
cd ..  
sudo rm -r MacTahoe-gtk-theme
```

### Rosepine Theme:
```
sudo dnf install -y gtk-murrine-engine
git clone https://github.com/Fausto-Korpsvart/Rose-Pine-GTK-Theme.git --depth 1
cd Rose-Pine-GTK-Theme/themes
./install.sh -c dark
cd ..
cd ..
sudo rm -r Rose-Pine-GTK-Theme
```

### Tela Circle Icons
```
git clone --depth 1 https://github.com/vinceliuice/Tela-circle-icon-theme.git
cd Tela-circle-icon-theme
./install.sh -a
cd ..
sudo rm -rf Tela-circle-icon-theme
```

## Gnome Tweaks

- Set the Shell theme to `Adwaita`
- Set the other theme to the `Rosepine-Dark` theme.
- Set every font to the Inter Semi Bold one.

### Zsh:
```
sudo dnf install -y zsh
```
``` 
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/powerlevel10k  
echo 'source ~/powerlevel10k/powerlevel10k.zsh-theme' >>~/.zshrc
```
```
chsh -s $(which zsh)
```

### Terminal (Ptyxis):
```
sudo dnf install -y dejavu-sans-mono-fonts powerline-fonts
```
```
gsettings set 'org.gnome.Ptyxis.Profile:/org/gnome/Ptyxis/Profiles/'$PTYXIS_PROFILE'/' 'opacity' '0.70'
```

- Select DejaVu Sans Mono or Powerline font for the Ptyxis terminal.

# KDE Plasma

## Installation
```
sudo dnf install -y plasma-desktop konsole ark sddm
systemctl enable sddm
```

## Material You Theme:

**Just follow the guide here:**

[KDE Material You Colors](https://github.com/luisbocanegra/kde-material-you-colors)

## Klassy Theme:

**Just follow the guide here:**

[Klassy](https://github.com/paulmcauley/klassy)

- In the Appearance settings, make sure to select the "Klassy" theme in the Window Decoration.

## Klassy Settings:

### Klassy Window Decoration:

**Buttons:**

- Set the icons to Fluent
- Set the icon size to 16
- Select bold icons
- Select the "Full-height rounded Rectangle" shape

**Window:**

- Set the corner radius to 0
- Uncheck the box "Colourize with highlighted buttons colour"
- Go to the Window Outline Style and change the outline to 2.15, the opacity of active windows to 80% and of inactive windows to 55%

### Klassy Application Style:

**General:**

- Uncheck every box with "Draw.." (so, uncheck all boxes)

## Install Papirus Icons

1. Open the icon settings in Appearance in the KDE Plasma settings
2. Click on "Get New"
3. Search for "Papirus"
4. Install the default "Papirus" icon theme and in the drop-down menu select the standard one called "papirus-icon-theme-versionnumber.tar.xz"

## Konsole

### Change Font Size:

1. Right-click the Konsole window and select "Edit Current Profile," then go to Appearance
2. Here you can change the font, I like to change it to the DejaVu Sans Mono font (11px).

### Editing the Top Bar:

- Right-click the top bar of the Konsole and try to remove everything except the title bar

## Editing the Taskbar/Panel

1. Right-click on the Panel and go to edit mode
2. Disable the floating effect by changing the option to "Disabled." And enable the blur effect.
3. Change the taskbar size to 28.

### Make Windows Transparent

1. Go to Settings under Window Management and then to window rules
2. Click on Add new and give the rule a name
3. Then click the "Detect Window Properties" button and click on the window you want to make transparent
4. Then add everything that is shown for the window in the rule
5. After that manually add new window properties called "Opacity inactive" and "Opacity active"
6. For Dolphin select opacity for active to 98 and for Konsole to 90 (keep inactive to 100)

# General Things:

### Fonts:

https://fonts.google.com/specimen/Inter

- I use the Semi Bold one

### Mouse Cursor:

- `sudo dnf install -y breeze-cursor-theme`

### Icons:

```
git clone --depth 1 https://github.com/vinceliuice/Tela-circle-icon-theme.git
cd Tela-circle-icon-theme
./install.sh -a
cd ..
sudo rm -rf Tela-circle-icon-theme
```

### Additional Fonts:

```sh
git clone --depth 1 https://github.com/ryanoasis/nerd-fonts.git
cd nerd-fonts
./install.sh
cd ..
sudo rm -rf nerd-fonts
```

## Fonts Installation:

```
sudo dnf install -y dejavu-sans-mono-fonts powerline-fonts
```
