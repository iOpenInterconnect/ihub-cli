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

if [ -f ~/.config/ihub/config.cfg ]; then
    ihub_home=$(awk '/^\[INSTALL_PATH\]/{getline; print; exit}' ~/.config/ihub/config.cfg)
else
    ihub_home="${IHUB_HOME:-$HOME/.ihub}"
    echo "No configuration file found. Defaulting to $ihub_home"
fi

case "$(uname -s)" in
	FreeBSD)
		sudo pkg install -y libplist gstreamer1 avahi-libdns git
		;;
	OpenBSD)
		doas pkg_add libplist gstreamer1-plugins-base avahi-libs avahi-main git
		;;
    Darwin)
        if ! command -v brew >/dev/null 2>&1; then
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] Homebrew is not installed. Please install Homebrew first." | tee -a "$HOME/.config/ihub/error.log" >&2
            exit 1
        fi

        brew install cmake pkg-config libplist openssl@3 git
        ;;
	Linux)
		if [[ ! -f /etc/os-release ]]; then
			echo "[$(date '+%Y-%m-%d %H:%M:%S')] Unsupported Linux system: /etc/os-release was not found." | tee -a "$HOME/.config/ihub/error.log" >&2
			exit 1
		fi

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
        sudo apt update

        libplist_package=libplist-dev
        if [[ "${ID:-}" == "debian" && "${VERSION_ID:-}" == 10* ]]; then
            libplist_package=libplist3
        fi

        sudo apt install -y \
            build-essential \
            pkg-config \
            cmake \
            libssl-dev \
            "$libplist_package" \
            libavahi-compat-libdnssd-dev \
            libgstreamer1.0-dev \
            libgstreamer-plugins-base1.0-dev \
            libx11-dev \
            git
        ;;

    rpm)
        sudo dnf install -y \
            gcc-c++ \
            make \
            pkgconf-pkg-config \
            cmake \
            openssl-devel \
            libplist-devel \
            gstreamer1-devel \
            gstreamer1-plugins-base-devel \
            libX11-devel \
            git
        ;;

    mageia)
        sudo urpmi \
            gcc-c++ \
            make \
            pkgconfig \
            cmake \
            libopenssl-devel \
            libplist-devel \
            gstreamer1.0-devel \
            gstreamer-plugins-base1.0-devel \
            libx11-devel \
            git
        ;;

    pclinuxos)
        sudo apt-get update
        sudo apt-get install -y \
            gcc-c++ \
            make \
            pkgconfig \
            cmake \
            openssl-devel \
            libplist-devel \
            gstreamer1.0-devel \
            gstreamer-plugins-base1.0-devel \
            libx11-devel \
            git
        ;;

    openmandriva)
        sudo dnf install -y \
            gcc-c++ \
            make \
            pkgconfig \
            cmake \
            libopenssl-devel \
            libplist-devel \
            gstreamer-devel \
            libgst-plugins-base1.0-devel \
            libX11-devel \
            git
        ;;

    opensuse)
        sudo zypper --non-interactive install \
            gcc-c++ \
            make \
            pkg-config \
            cmake \
            libopenssl-3-devel \
            libplist-2_0-devel \
            gstreamer-devel \
            gstreamer-plugins-base-devel \
            libX11-devel \
            git
        ;;

    arch)
        sudo pacman -Syu --needed --noconfirm \
            openssl \
            libplist \
            avahi \
            gst-plugins-base \
            base-devel \
            pkgconf \
            cmake \
            libx11 \
            gst-libav \
            git
        ;;

    *)
        echo "Unsupported Linux distribution: ${PRETTY_NAME:-${ID:-unknown}}" >&2
        exit 1
        ;;
esac
;;
esac

cd "$ihub_home"

git clone --single-branch --depth 1 https://github.com/iOpenInterconnect/UxPlay

cd UxPlay
cmake .
make
sudo make install

success "Install complete. UxPlay has been installed in $ihub_home/UxPlay"