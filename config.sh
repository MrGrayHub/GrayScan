#!/bin/bash
# Cross-distro installer for GrayScan
INSTALL_DIR="/opt/gray_scan_project"
BIN_NAME="gmap"
ENTRY_SCRIPT="gmap.sh"

# --- Helpers ---
echo_info() { echo "[GrayScan] $*"; }
echo_err()  { echo "[GrayScan] ERROR: $*" >&2; }

# --- Ensure Python3 exists (try to install later if missing) ---
if ! command -v python3 &>/dev/null; then
    echo_info "Python3 not found. The script will attempt to install it."
else
    echo_info "Python3 detected: $(command -v python3)"
fi

# --- Privilege escalation detection ---
if command -v sudo &>/dev/null; then
    SUDO="sudo"
elif command -v doas &>/dev/null; then
    SUDO="doas"
elif [ "$(id -u)" -eq 0 ]; then
    SUDO=""
elif command -v su &>/dev/null; then
    # use su -c "cmd" pattern when needed
    SUDO="su -c"
else
    echo_err "No sudo/doas/su found and not running as root. Please run as root or install sudo/doas."
    exit 1
fi

# Helper to run install commands with proper prefix
run_priv() {
    if [ -z "$SUDO" ]; then
        # already root
        bash -c "$*"
    elif [ "$SUDO" = "su -c" ]; then
        su -c "$*"
    else
        $SUDO bash -c "$*"
    fi
}

# --- Ensure pip (prefer pip3) ---
PIP_CMD=""
if command -v pip3 &>/dev/null; then
    PIP_CMD="pip3"
elif command -v pip &>/dev/null; then
    PIP_CMD="pip"
fi

if [ -z "$PIP_CMD" ]; then
    echo_info "pip not found. Attempting to bootstrap pip via python3 -m ensurepip..."
    if python3 -m ensurepip --upgrade &>/dev/null; then
        PIP_CMD="python3 -m pip"
    else
        echo_info "ensurepip failed or not available. Will install pip via package manager below."
        PIP_CMD="python3 -m pip"
    fi
else
    # prefer using python3 -m pip to avoid mismatched Python
    PIP_CMD="python3 -m pip"
fi

# --- Detect OS and install Python/pip if needed ---
OS="unknown"
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
fi
echo_info "Detected OS: $OS"

case $OS in
    ubuntu|debian|kali|linuxmint|pop|parrot)
        echo_info "Using apt (Debian/Ubuntu family)..."
        run_priv "apt update -y"
        run_priv "apt install -y python3 python3-venv python3-distutils python3-pip"
        ;;
    arch|manjaro)
        echo_info "Using pacman (Arch family)..."
        run_priv "pacman -Sy --noconfirm"
        run_priv "pacman -S --noconfirm python python-pip"
        ;;
    fedora)
        echo_info "Using dnf (Fedora)..."
        run_priv "dnf install -y python3 python3-pip"
        ;;
    centos|rhel|rocky|almalinux)
        echo_info "Using yum (RHEL family)..."
        run_priv "yum install -y python3 python3-pip || dnf install -y python3 python3-pip"
        ;;
    opensuse*|suse)
        echo_info "Using zypper (openSUSE/SUSE)..."
        run_priv "zypper install -y python3 python3-pip"
        ;;
    alpine)
        echo_info "Using apk (Alpine)..."
        run_priv "apk update"
        run_priv "apk add --no-cache python3 py3-pip"
        ;;
    termux)
        echo_info "Using pkg (Termux)..."
        run_priv "pkg update -y"
        run_priv "pkg install -y python"
        ;;
    freebsd)
        echo_info "Using pkg (FreeBSD)..."
        run_priv "pkg install -y python3 py38-pip"
        ;;
    *)
        echo_info "Unknown OS ID. Trying to detect package manager..."
        if command -v apt &>/dev/null; then
            run_priv "apt update -y && apt install -y python3 python3-pip"
        elif command -v dnf &>/dev/null; then
            run_priv "dnf install -y python3 python3-pip"
        elif command -v yum &>/dev/null; then
            run_priv "yum install -y python3 python3-pip"
        elif command -v pacman &>/dev/null; then
            run_priv "pacman -Sy --noconfirm python python-pip"
        elif command -v zypper &>/dev/null; then
            run_priv "zypper install -y python3 python3-pip"
        elif command -v apk &>/dev/null; then
            run_priv "apk add --no-cache python3 py3-pip"
        else
            echo_err "Could not find a supported package manager. Please install python3 and pip manually."
            exit 1
        fi
        ;;
esac

# re-evaluate pip command to prefer python3 -m pip
PIP_CMD="python3 -m pip"

# --- Install Python requirements if requirements.txt exists ---
if [ -f "requirements.txt" ]; then
    echo_info "Installing python dependencies from requirements.txt..."
    if ! $PIP_CMD install --upgrade -r requirements.txt; then
        echo_err "Failed to install Python requirements. You may try to run '$PIP_CMD install -r requirements.txt' manually."
        # continue, maybe optional deps
    fi
else
    echo_info "No requirements.txt found; skipping Python dependency installation."
fi

# --- Install project files to INSTALL_DIR ---
if [ ! -d "$INSTALL_DIR" ]; then
    echo_info "Creating install dir $INSTALL_DIR and copying files..."
    run_priv "mkdir -p '$INSTALL_DIR'"
    # copy all files except common system dirs and .git if present
    run_priv "cp -r . '$INSTALL_DIR'"
    echo_info "Project copied to $INSTALL_DIR"
else
    echo_info "Project already exists at $INSTALL_DIR"
fi

# --- Make entry scripts executable if present ---
for f in "$INSTALL_DIR/$ENTRY_SCRIPT" "$INSTALL_DIR/run.sh" "$INSTALL_DIR/config.sh"; do
    if [ -f "$f" ]; then
        run_priv "chmod +x '$f'"
        echo_info "Made $f executable"
    fi
done

# --- Create symlink in /usr/local/bin (handles existing regular file carefully) ---
TARGET_LINK="/usr/local/bin/$BIN_NAME"
if [ -L "$TARGET_LINK" ]; then
    echo_info "Symlink $TARGET_LINK already exists."
elif [ -e "$TARGET_LINK" ]; then
    echo_err "$TARGET_LINK exists and is not a symlink. Not overwriting."
    echo_err "If you want to replace it, remove it and re-run this installer."
else
    run_priv "ln -s '$INSTALL_DIR/$ENTRY_SCRIPT' '$TARGET_LINK'"
    echo_info "Created symlink $TARGET_LINK -> $INSTALL_DIR/$ENTRY_SCRIPT"
fi

echo_info "Installation complete. Run: $BIN_NAME <target> [options]"
echo_info "Or run: $BIN_NAME --help"