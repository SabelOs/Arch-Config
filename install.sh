#!/usr/bin/env bash

set -euo pipefail

# ============================================================
# DOTFILES INSTALLER
#
# Usage:
#   ./install.sh surface
#   ./install.sh desktop
#
# Expected repository structure:
#
# ~/dotfiles/
# ├── install.sh
# ├── hypr/
# │   ├── env-variables.lua
# │   ├── autostart.lua
# │   ├── lookandfeel.lua
# │   ├── input.lua
# │   ├── keybindings.lua
# │   ├── windowrules.lua
# │   ├── hypridle.conf
# │   ├── hyprlock.conf
# │   └── hyprpaper.conf
# ├── hosts/
# │   ├── surface/
# │   │   ├── hyprland.lua
# │   │   └── monitors.lua
# │   └── desktop/
# │       ├── hyprland.lua
# │       └── monitors.lua
# ├── waybar/
# │   ├── config
# │   └── style.css
# └── bin/
#     └── ...
# ============================================================


# ------------------------------------------------------------
# BASIC PATHS
# ------------------------------------------------------------

DOTFILES="$HOME/Arch-Config"
HOST="${1:-}"

HYPR_CONFIG="$HOME/.config/hypr"
WAYBAR_CONFIG="$HOME/.config/waybar"


# ------------------------------------------------------------
# CHECKS
# ------------------------------------------------------------

if [[ ! -d "$DOTFILES" ]]; then
    echo "ERROR: Dotfiles directory does not exist:"
    echo "       $DOTFILES"
    exit 1
fi

if [[ -z "$HOST" ]]; then
    echo "Usage: $0 <host>"
    echo
    echo "Available hosts:"

    if [[ -d "$DOTFILES/hosts" ]]; then
        find "$DOTFILES/hosts" \
            -mindepth 1 \
            -maxdepth 1 \
            -type d \
            -printf '  %f\n'
    fi

    exit 1
fi


HOST_DIR="$DOTFILES/hosts/$HOST"


if [[ ! -d "$HOST_DIR" ]]; then
    echo "ERROR: Host '$HOST' does not exist."
    echo
    echo "Available hosts:"
    find "$DOTFILES/hosts" \
        -mindepth 1 \
        -maxdepth 1 \
        -type d \
        -printf '  %f\n'
    exit 1
fi


# ------------------------------------------------------------
# HELPER FUNCTIONS
# ------------------------------------------------------------

backup_if_needed() {
    local target="$1"

    # Nothing exists -> nothing to back up
    if [[ ! -e "$target" && ! -L "$target" ]]; then
        return
    fi

    # Already a symlink -> remove it.
    # We are replacing it with the correct symlink below.
    if [[ -L "$target" ]]; then
        rm "$target"
        return
    fi

    # Existing real file/directory -> make a timestamped backup
    local backup="${target}.backup.$(date +%Y%m%d-%H%M%S)"

    echo "Backing up:"
    echo "  $target"
    echo "  -> $backup"

    mv "$target" "$backup"
}


link_file() {
    local source="$1"
    local target="$2"

    if [[ ! -e "$source" ]]; then
        echo "ERROR: Source file does not exist:"
        echo "       $source"
        exit 1
    fi

    mkdir -p "$(dirname "$target")"

    backup_if_needed "$target"

    ln -s "$source" "$target"

    echo "Linked:"
    echo "  $target"
    echo "  -> $source"
}

# ------------------------------------------------------------
# INSTALL PARU
# ------------------------------------------------------------

install_paru() {
    local paru_dir="$DOTFILES/paru"
    local paru_repo="https://aur.archlinux.org/paru.git"

    # Already installed -> nothing to do
    if command -v paru >/dev/null 2>&1; then
        echo "paru is already installed:"
        echo "  $(command -v paru)"
        return
    fi

    echo
    echo "Installing paru..."

    # Clone paru into the dotfiles repository
    if [[ ! -d "$paru_dir" ]]; then
        echo "Cloning paru repository..."
        git clone "$paru_repo" "$paru_dir"
    else
        echo "paru repository already exists:"
        echo "  $paru_dir"

        echo "Updating paru repository..."
        git -C "$paru_dir" pull
    fi

    # Build and install paru
    echo "Building paru..."

    (
        cd "$paru_dir"
        makepkg -si --noconfirm
    )

    echo
    echo "paru installation complete."
}

# ------------------------------------------------------------
# PACKAGE INSTALLATION
# ------------------------------------------------------------

install_packages() {
    local package_file="$1"

    if [[ ! -f "$package_file" ]]; then
        echo "WARNING: Package file does not exist:"
        echo "         $package_file"
        return
    fi

    mapfile -t packages < <(
        grep -vE '^\s*(#|$)' "$package_file"
    )

    if [[ ${#packages[@]} -eq 0 ]]; then
        echo "No packages to install."
        return
    fi

    echo
    echo "Installing required packages..."

    sudo pacman -S --needed "${packages[@]}"
}

install_aur_packages() {
    if ! command -v paru >/dev/null 2>&1; then
        echo "ERROR: paru is not installed."
        echo "Please install an AUR helper before continuing."
        exit 1
    fi
    local package_file="$1"

    if [[ ! -f "$package_file" ]]; then
        echo "WARNING: AUR package file does not exist:"
        echo "         $package_file"
        return
    fi

    mapfile -t packages < <(
        grep -vE '^\s*(#|$)' "$package_file"
    )

    if [[ ${#packages[@]} -eq 0 ]]; then
        echo "No AUR packages to install."
        return
    fi

    echo
    echo "Installing AUR packages..."

    paru -S --needed "${packages[@]}"
}


# ------------------------------------------------------------
# PACKAGE INSTALLATION
# ------------------------------------------------------------
echo
echo "Installing packages..."

install_packages "$DOTFILES/packages/base.txt"
install_packages "$DOTFILES/packages/$HOST.txt"
install_aur_packages "$DOTFILES/packages/base-aur.txt"
install_aur_packages "$DOTFILES/packages/$HOST-aur.txt"

#enable elephant as a service for walker
elephant service enable
systemctl --user enable elephant
systemctl --user start elephant

# ------------------------------------------------------------
# CREATE CONFIG DIRECTORIES
# ------------------------------------------------------------

echo
echo "Creating configuration directories..."

mkdir -p "$HYPR_CONFIG"
mkdir -p "$WAYBAR_CONFIG"


# ------------------------------------------------------------
# HYPRLAND
# ------------------------------------------------------------

echo
echo "Installing Hyprland configuration..."
echo "Host: $HOST"

# The host-specific loader.
#
# This means:
#
# ~/.config/hypr/hyprland.lua
#     ->
# ~/dotfiles/hosts/<host>/hyprland.lua
#
link_file \
    "$HOST_DIR/hyprland.lua" \
    "$HYPR_CONFIG/hyprland.lua"


# ------------------------------------------------------------
# HYPRIDLE / HYPRLOCK / HYPRPAPER
# ------------------------------------------------------------

echo
echo "Installing Hyprland auxiliary configuration..."

link_file \
    "$DOTFILES/hypr/hypridle.conf" \
    "$HYPR_CONFIG/hypridle.conf"

link_file \
    "$DOTFILES/hypr/hyprlock.conf" \
    "$HYPR_CONFIG/hyprlock.conf"

link_file \
    "$DOTFILES/hypr/hyprpaper.conf" \
    "$HYPR_CONFIG/hyprpaper.conf"


# ------------------------------------------------------------
# WAYBAR
# ------------------------------------------------------------

echo
echo "Installing Waybar configuration..."

link_file \
    "$DOTFILES/waybar/config" \
    "$WAYBAR_CONFIG/config"

link_file \
    "$DOTFILES/waybar/style.css" \
    "$WAYBAR_CONFIG/style.css"


# ------------------------------------------------------------
# MAKE ALL DOTFILES BINARIES EXECUTABLE
# ------------------------------------------------------------

echo
echo "Making dotfiles/bin scripts executable..."

if [[ -d "$DOTFILES/bin" ]]; then

    find "$DOTFILES/bin" \
        -type f \
        -exec chmod +x {} \;

    echo "Executable permissions applied to:"
    echo "  $DOTFILES/bin/"

else
    echo "WARNING: $DOTFILES/bin does not exist."
fi


# ------------------------------------------------------------
# ADD DOTFILES/BIN TO FISH PATH
# ------------------------------------------------------------

echo
echo "Configuring Fish PATH..."

if command -v fish >/dev/null 2>&1; then
    # Use || true to prevent script exit on fish_add_path failure
    if fish -c "fish_add_path '$DOTFILES/bin'" 2>/dev/null; then
        echo "Added to Fish PATH:"
        echo "  $DOTFILES/bin"
    else
        echo "WARNING: Failed to add to Fish PATH (but continuing)."
        echo "         You can manually run: fish_add_path '$DOTFILES/bin'"
    fi
else
    echo "WARNING: Fish is not installed."
    echo "         Skipping Fish PATH configuration."
fi

# ------------------------------------------------------------
# SUMMARY
# ------------------------------------------------------------

echo
echo "============================================================"
echo " Dotfiles installation complete"
echo "============================================================"
echo
echo "Host:"
echo "  $HOST"
echo
echo "Hyprland:"
echo "  ~/.config/hypr/hyprland.lua"
echo "      -> $HOST_DIR/hyprland.lua"
echo
echo "Hypridle:"
echo "  ~/.config/hypr/hypridle.conf"
echo "      -> $DOTFILES/hypr/hypridle.conf"
echo
echo "Hyprlock:"
echo "  ~/.config/hypr/hyprlock.conf"
echo "      -> $DOTFILES/hypr/hyprlock.conf"
echo
echo "Hyprpaper:"
echo "  ~/.config/hypr/hyprpaper.conf"
echo "      -> $DOTFILES/hypr/hyprpaper.conf"
echo
echo "Waybar:"
echo "  ~/.config/waybar/config"
echo "      -> $DOTFILES/waybar/config"
echo "  ~/.config/waybar/style.css"
echo "      -> $DOTFILES/waybar/style.css"
echo
echo "Executables:"
echo "  $DOTFILES/bin/"
echo
# Save the selected host for future use
echo "$HOST" > "$HOME/.config/hypr/.host"
echo "Saved host '$HOST' to $HOME/.config/hypr/.host"