#!/usr/bin/env bash
set -xe # Exit immediately if a command exits with a non-zero status, and print commands and their arguments as they are executed.

# Ensure HOME is set to /root for script execution context,
# as the script runs as root and performs operations in a temporary root home.
# The Dockerfile's ENV HOME will apply to the final user.
export HOME="/root"

# Determine architecture for downloading correct binaries
ARCH=$(arch | sed 's/aarch64/arm64/g' | sed 's/x86_64/amd64/g')

echo "Starting Obsidian installation script..."

# --- Function to install common dependencies (curl, ca-certificates, xdg-utils) ---
# These are often needed for downloading files and desktop integration.
install_common_deps() {
    echo "Installing common dependencies..."
    if command -v apt-get &> /dev/null; then
        apt-get update || echo "Warning: apt-get update failed." >&2
        apt-get install -y curl ca-certificates xdg-utils || echo "Warning: Failed to install apt common dependencies." >&2
    elif command -v dnf &> /dev/null; then
        dnf install -y curl ca-certificates xdg-utils || echo "Warning: Failed to install dnf common dependencies." >&2
    elif command -v yum &> /dev/null; then
        yum install -y curl ca-certificates xdg-utils || echo "Warning: Failed to install yum common dependencies." >&2
    elif command -v zypper &> /dev/null; then
        zypper install -yn curl ca-certificates xdg-utils || echo "Warning: Failed to install zypper common dependencies." >&2
    else
        echo "Error: Could not find a supported package manager to install common dependencies (curl, ca-certificates, xdg-utils)." >&2
        exit 1 # Exit if essential tools cannot be installed
    fi
}

# --- Function to get the latest Obsidian download URL from GitHub Releases API ---
# Parameters:
#   $1: asset_type - "AppImage" (always AppImage now)
# Returns: The direct download URL or an empty string if not found/error.
get_obsidian_download_url() {
    local asset_type="$1" # This will always be "AppImage" now
    local required_suffix=""

    if [ "$ARCH" == "amd64" ]; then
        required_suffix=".AppImage"
    elif [ "$ARCH" == "arm64" ]; then
        required_suffix="-arm64.AppImage" # Obsidian's specific arm64 AppImage naming
    else
        echo "Error: Unsupported architecture for Obsidian: $ARCH" >&2
        return 1
    fi

    if [ -z "$required_suffix" ]; then
        echo "Error: Invalid asset type '$asset_type' or architecture '$ARCH' for URL fetching." >&2
        return 1
    fi

    # Fetch latest release info and parse for the specific asset URL
    # Using grep -m 1 to get only the first matching URL
    curl -s "https://api.github.com/repos/obsidianmd/obsidian-releases/releases/latest" | \
    grep -m 1 "browser_download_url.*${required_suffix}" | \
    cut -d '"' -f 4
}

# --- Install common dependencies first ---
install_common_deps

# --- Main installation logic for all distributions (now using AppImage for all) ---
echo "Installing Obsidian via AppImage for all supported Linux distributions."

OBSIDIAN_URL=$(get_obsidian_download_url "AppImage")
if [ -z "$OBSIDIAN_URL" ]; then
  echo "Error: Could not determine Obsidian AppImage download URL for $ARCH. Skipping installation."
  exit 1 # Fatal error: cannot proceed without download URL
fi

OBSIDIAN_APPIMAGE_NAME=$(basename "$OBSIDIAN_URL")
DOWNLOAD_PATH="/tmp/$OBSIDIAN_APPIMAGE_NAME"

echo "Downloading Obsidian AppImage from: $OBSIDIAN_URL"
curl -L -o "$DOWNLOAD_PATH" "$OBSIDIAN_URL" || { echo "Error: Failed to download Obsidian AppImage from $OBSIDIAN_URL."; exit 1; }

# Move AppImage to a standard PATH location and make it executable
# /usr/local/bin is typically in the PATH for all users
echo "Installing Obsidian AppImage to /usr/local/bin/Obsidian..."
install -m 755 "$DOWNLOAD_PATH" "/usr/local/bin/Obsidian" || { echo "Error: Failed to install Obsidian AppImage to /usr/local/bin."; exit 1; }
rm -f "$DOWNLOAD_PATH" # Clean up downloaded AppImage

# Create a .desktop file for desktop environment integration
OBSIDIAN_DESKTOP_DIR="/usr/share/applications"
mkdir -p "$OBSIDIAN_DESKTOP_DIR" || { echo "Error: Failed to create directory $OBSIDIAN_DESKTOP_DIR."; exit 1; }

echo "Creating obsidian.desktop file..."
cat >"${OBSIDIAN_DESKTOP_DIR}/obsidian.desktop" <<EOF
[Desktop Entry]
Name=Obsidian
Exec=/usr/local/bin/Obsidian %U
Icon=obsidian # Assumes an icon named 'obsidian' is available in system icon themes
Type=Application
Categories=Office;TextEditor;Utility;
Comment=Knowledge Base and Markdown Editor
Terminal=false
StartupWMClass=Obsidian
EOF
# Update desktop database to ensure the new .desktop file is recognized
if command -v update-desktop-database &> /dev/null; then
    echo "Updating desktop database..."
    update-desktop-database || echo "Warning: update-desktop-database failed." >&2
fi

# Perform cleanup based on detected package manager
if [ -z "${SKIP_CLEAN+x}" ]; then
  echo "Performing package manager cleanup..."
  if command -v apt-get &> /dev/null; then
    apt-get autoclean || echo "Warning: apt-get autoclean failed." >&2
    rm -rf \
      /var/lib/apt/lists/* \
      /var/tmp/* || echo "Warning: Failed to clean apt lists/tmp files." >&2
  elif command -v dnf &> /dev/null; then
    dnf clean all || echo "Warning: dnf clean all failed." >&2
  elif command -v yum &> /dev/null; then
    yum clean all || echo "Warning: yum clean all failed." >&2
  elif command -v zypper &> /dev/null; then
    zypper clean --all || echo "Warning: zypper clean --all failed." >&2
  fi
fi

echo "Obsidian installation complete."

# --- Final ownership adjustments for the non-root user (1000) ---
# This assumes the Dockerfile sets ENV HOME to the user's actual home directory
# (e.g., /home/kasm-default-profile).
# Obsidian typically stores configuration and data in $HOME/.config/obsidian or similar.
# The chown operation ensures the default Kasm user (1000) has full access.
# Note: The $HOME here refers to the Dockerfile's ENV HOME, not the script's temporary /root.
KASM_USER_HOME_DIR="/home/kasm-default-profile" # Explicitly define the target home dir

echo "Setting ownership for Obsidian related files in $KASM_USER_HOME_DIR to user 1000."
# Ensure the user's home directory and its contents are owned by user 1000
chown -R 1000:1000 "$KASM_USER_HOME_DIR" || echo "Warning: Failed to chown $KASM_USER_HOME_DIR to 1000:1000." >&2

echo "Obsidian installation script finished."
