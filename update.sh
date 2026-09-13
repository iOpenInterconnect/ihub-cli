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

# Updating dependencies

if [ -f ~/.config/ihub/config.cfg ]; then
    ihub_home=$(awk '/^\[INSTALL_PATH\]/{getline; print; exit}' ~/.config/ihub/config.cfg)
else
    ihub_home="${IHUB_HOME:-$HOME/.ihub}"
    warn "No configuration file found. Defaulting to $ihub_home"
fi


INSTALL="false"

read -p "Update dependencies? (y/n): " answer
case "$answer" in
    y|Y)
        INSTALL="true"
        ;;
    n|N)
        warn "Updating dependencies aborted."
        ;;
    *)
        error "Invalid input. Update aborted."
        exit 1
        ;;
esac


if [ "$INSTALL" = "true" ]; then
    info "Updating dependencies..."

    case "$(uname -s)" in
        FreeBSD)
            sudo pkg install -y git
            ;;
        OpenBSD)
            doas pkg_add git
            ;;
        Darwin)
            if ! command -v brew >/dev/null 2>&1; then
                error "Homebrew is not installed. Please install Homebrew first."
                exit 1
            fi

            brew install git
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
        sudo apt-get update
        sudo apt-get install -y \
            git
        ;;

    rpm)
        sudo dnf install -y \
            git
        ;;

    mageia)
        sudo urpmi \
            git
        ;;

    pclinuxos)
        sudo apt-get update
        sudo apt-get install -y \
            git
        ;;

    openmandriva)
        sudo dnf install -y \
            git
        ;;

    opensuse)
        sudo zypper --non-interactive install \
            git
        ;;

    arch)
        sudo pacman -Syu --needed --noconfirm \
            git
        ;;

    *)
        error "Unsupported Linux distribution: ${PRETTY_NAME:-${ID:-unknown}}"
        exit 1
        ;;
esac
fi

# Updating the cli

cd "$ihub_home/cli"
git fetch origin

LOCAL=$(git rev-parse HEAD)
REMOTE=$(git rev-parse @{u})

if [[ "$LOCAL" == "$REMOTE" ]]; then
    success "CLI already up to date."
else
    echo "CLI update available:"
    git --no-pager log --oneline "$LOCAL..$REMOTE"

    read -rp "Update now? (y/n): " answer

    case "$answer" in
    y|Y)
        git pull
        success "CLI update complete."
        ;;
    *)
        warn "Update cancelled."
        ;;
    esac
fi

answer=skip

if [[ -f "$HOME/.bashrc" ]]; then
    if ! grep -q "$ihub_home/cli/core" "$HOME/.bashrc"; then
        read -p "Could not find iHub in PATH, add now? (y/n): " answer
    fi
elif [[ -f "$HOME/.zshrc" ]]; then
    if ! grep -q "$ihub_home/cli/core" "$HOME/.zshrc"; then
        read -p "Could not find iHub in PATH, add now? (y/n): " answer
    fi
elif [[ -f "$HOME/.config/fish/config.fish" ]]; then
    if ! grep -q "$ihub_home/cli/core" "$HOME/.config/fish/config.fish"; then
        read -p "Could not find iHub in PATH, add now? (y/n): " answer
    fi
elif [[ -f "$HOME/.tcshrc" ]]; then
    if ! grep -q "$ihub_home/cli/core" "$HOME/.tcshrc"; then
        read -p "Could not find iHub in PATH, add now? (y/n): " answer
    fi
fi

case "$answer" in
    y|Y)
        info "Exporting iHub to PATH..."
        export PATH="$PATH:$ihub_home/cli/core"
        if [[ -f "$HOME/.bashrc" ]]; then
            if ! grep -q "$ihub_home/cli/core" "$HOME/.bashrc"; then
                echo "export PATH=\"\$PATH:$ihub_home/cli/core\"" >> "$HOME/.bashrc"
                success "Added iHub to PATH in .bashrc"
            else
                info "iHub is already in PATH in .bashrc"
            fi
        fi
        if [[ -f "$HOME/.zshrc" ]]; then
            if ! grep -q "$ihub_home/cli/core" "$HOME/.zshrc"; then
                echo "export PATH=\"\$PATH:$ihub_home/cli/core\"" >> "$HOME/.zshrc"
                success "Added iHub to PATH in .zshrc"
            else
                info "iHub is already in PATH in .zshrc"
            fi
        fi
        if [[ -f "$HOME/.config/fish/config.fish" ]]; then
            if ! grep -q "$ihub_home/cli/core" "$HOME/.config/fish/config.fish"; then
                echo "set -gx PATH \$PATH $ihub_home/cli/core" >> "$HOME/.config/fish/config.fish"
                success "Added iHub to PATH in config.fish"
            else
                info "iHub is already in PATH in config.fish"
            fi
        fi
        if [[ -f "$HOME/.tcshrc" ]]; then
            if ! grep -q "$ihub_home/cli/core" "$HOME/.tcshrc"; then
                echo "setenv PATH \$PATH:$ihub_home/cli/core" >> "$HOME/.tcshrc"
                success "Added iHub to PATH in .tcshrc"
            else
                info "iHub is already in PATH in .tcshrc"
            fi
        fi
        ;;
    n|N)
        warn "Skipping PATH export."
        warn "To use iHub, you can run it directly from the installation directory: ./$ihub_home/cli/ihub"
        ;;
    skip)
        ;;
    *)
        echo "Invalid input. Skipping PATH export."
        ;;
esac

echo "Updating the projects..."

# Updating UxPlay, if installed
if "$ihub_home/cli/ihub" status uxplay | grep -q " installed "; then

    if [[ -f "uxplay/update.sh" ]]; then
        bash uxplay/update.sh
    else
        warn "UxPlay update script not found"
    fi
fi

success "Update complete."
