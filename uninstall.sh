#!/usr/bin/env bash

set -euo pipefail

# Doing logging stuff
LOG_FILE="$HOME/.config/ihub/error.log"

mkdir -p "$(dirname "$LOG_FILE")"
touch "$LOG_FILE"

# figured some fancy colors would be nice
RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
RESET='\033[0m'

warn() {
    echo -e "${YELLOW}[WARN]${RESET} $*"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [WARN] $*" >> "$LOG_FILE"
}

info() {
    echo -e "[INFO] $*"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] $*" >> "$LOG_FILE"
}

success() { # this is most likely only used once or twice at the end of a script
    echo -e "${GREEN}[SUCCESS]${RESET} $*"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERROR]${RESET} $*"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] $*" >> "$LOG_FILE"
}

error_handler() { # couldn't think of a better way of trapping errors properly
    error "Command failed: $BASH_COMMAND (line $LINENO, exit code $?)"
}

trap error_handler ERR

info "Sending logs to $LOG_FILE"

# Uninstalling dependencies

if [ -f ~/.config/ihub/config.cfg ]; then
    ihub_home=$(awk '/^\[INSTALL_PATH\]/{getline; print; exit}' ~/.config/ihub/config.cfg)
else
    ihub_home="${IHUB_HOME:-$HOME/.ihub}"
    warn "No configuration file found. Defaulting to $ihub_home"
fi


INSTALL="false"

read -p "Uninstall dependencies? (y/n): " answer
case "$answer" in
    y|Y)
        INSTALL="true"
        ;;
    n|N)
        warn "Uninstalling dependencies aborted."
        ;;
    *)
        error "Invalid input. Uninstall aborted."
        exit 1
        ;;
esac


if [ "$INSTALL" = "true" ]; then
    info "Uninstalling dependencies..."

    case "$(uname -s)" in
        FreeBSD)
            sudo pkg delete -y git
            ;;
        OpenBSD)
            doas pkg_delete git
            ;;
        Darwin)
            if ! command -v brew >/dev/null 2>&1; then
                error "Homebrew is not installed. Please install Homebrew first."
            fi

            brew uninstall git
            ;;
        Linux)
            if [[ ! -f /etc/os-release ]]; then
                error "Unsupported Linux system: /etc/os-release was not found."
                exit 1
            fi
            ;;
    esac

. /etc/os-release

case "${ID:-}" in
    debian|ubuntu|linuxmint|pop)
        distro_family=debian
        ;;

    fedora|rhel|centos|rocky|almalinux)
        distro_family=rpm
        ;;

    mageia)
        distro_family=mageia
        ;;

    pclinuxos)
        distro_family=pclinuxos
        ;;

    openmandriva)
        distro_family=openmandriva
        ;;

    opensuse*|sles)
        distro_family=opensuse
        ;;

    arch|manjaro|endeavouros)
        distro_family=arch
        ;;

    *)

        distro_family=

        for id_like in ${ID_LIKE:-}; do
            case "$id_like" in
                debian|ubuntu)
                    distro_family=debian
                    break
                    ;;

                fedora|rhel)
                    distro_family=rpm
                    break
                    ;;

                arch)
                    distro_family=arch
                    break
                    ;;

                mageia)
                    distro_family=mageia
                    break
                    ;;

                pclinuxos)
                    distro_family=pclinuxos
                    break
                    ;;

                openmandriva)
                    distro_family=openmandriva
                    break
                    ;;

                opensuse|sles)
                    distro_family=opensuse
                    break
                    ;;
            esac
        done
        ;;
esac

case "$distro_family" in
    debian)
        sudo apt remove -y \
            git
        ;;

    rpm)
        sudo dnf remove  -y \
            git
        ;;

    mageia)
        sudo urpme \
            git
        ;;

    pclinuxos)
        sudo apt-get remove -y \
            git
        ;;

    openmandriva)
        sudo dnf remove -y \
            git
        ;;

    opensuse)
        sudo zypper --non-interactive remove \
            git
        ;;

    arch)
        sudo pacman -Rns --noconfirm \
            git
        ;;

    *)
        error "Unsupported Linux distribution: ${PRETTY_NAME:-${ID:-unknown}}"
        exit 1
        ;;
esac
fi

echo "Removing projects..." # removing projects BEFORE removing the CLI, otherwise ihub status uxplay would fail

# Removing UxPlay, if installed
if "$ihub_home/cli/ihub" status uxplay | grep -q " installed "; then

    if [[ -f "uxplay/uninstall.sh" ]]; then
        bash uxplay/uninstall.sh
    else
        warn "UxPlay uninstall script not found\nShould be here: $ihub_home/cli/uxplay/uninstall.sh"
    fi
else
    warn "No external projects found, skipping"
fi

# Removing the cli

info "Removing iHub CLI..."
rm -rf "$ihub_home/cli"

answer="skip"

if [[ -f "$HOME/.bashrc" ]]; then
    if ! grep -q "$ihub_home/cli/core" "$HOME/.bashrc"; then
        warn "Could not find iHub in PATH, removing from .bashrc failed."
        return
    else
        read -p "Remove the following line from $HOME/.bashrc: $(grep "$ihub_home/cli/core" "$HOME/.bashrc") (y/n)? (Recommended): " answer
    fi
elif [[ -f "$HOME/.zshrc" ]]; then
    if ! grep -q "$ihub_home/cli/core" "$HOME/.zshrc"; then
        warn "Could not find iHub in PATH, removing from .zshrc failed."
        return
    else
        read -p "Remove the following line from $HOME/.zshrc: $(grep "$ihub_home/cli/core" "$HOME/.zshrc") (y/n)? (Recommended): " answer
    fi
elif [[ -f "$HOME/.config/fish/config.fish" ]]; then
    if ! grep -q "$ihub_home/cli/core" "$HOME/.config/fish/config.fish"; then
        warn "Could not find iHub in PATH, removing from config.fish failed."
        return
    else
        read -p "Remove the following line from $HOME/.config/fish/config.fish: $(grep "$ihub_home/cli/core" "$HOME/.config/fish/config.fish") (y/n)? (Recommended): " answer
    fi
elif [[ -f "$HOME/.tcshrc" ]]; then
    if ! grep -q "$ihub_home/cli/core" "$HOME/.tcshrc"; then
        warn "Could not find iHub in PATH, removing from .tcshrc failed."
        return
    else
        read -p "Remove the following line from $HOME/.tcshrc: $(grep "$ihub_home/cli/core" "$HOME/.tcshrc") (y/n)? (Recommended): " answer
    fi
fi

case "$answer" in
    y|Y)
        info "Removing iHub from PATH..."
        if [[ -f "$HOME/.bashrc" ]]; then
            sed -i "\|^export PATH=\"\$PATH:$ihub_home/cli/core\"$|d" "$HOME/.bashrc"
        fi
        if [[ -f "$HOME/.zshrc" ]]; then
            sed -i "\|^export PATH=\"\$PATH:$ihub_home/cli/core\"$|d" "$HOME/.zshrc"
        fi
        if [[ -f "$HOME/.config/fish/config.fish" ]]; then
            sed -i "\|^set -gx PATH \$PATH $ihub_home/cli/core$|d" "$HOME/.config/fish/config.fish"
        fi
        if [[ -f "$HOME/.tcshrc" ]]; then
            sed -i "\|^setenv PATH \$PATH:$ihub_home/cli/core$|d" "$HOME/.tcshrc"
        fi
        success "iHub removed from PATH."
        ;;
    n|N)
        warn "Skipping PATH removal."
        ;;
    skip)
        ;;
    *)
        echo "Invalid input. Skipping PATH removal."
        ;;
esac

success "Uninstall complete."
