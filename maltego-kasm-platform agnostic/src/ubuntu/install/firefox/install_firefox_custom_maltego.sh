#!/usr/bin/env bash
set -xe

# Ensure a sane HOME for desktop operations if running as root
export HOME="/root"

# Add icon (Assuming Dockerfile already copied firefox.desktop to the intended user's Desktop)
# We just need to ensure permissions if it's already there
if [ -f "/home/kasm-default-profile/Desktop/firefox.desktop" ]; then
    echo "Setting permissions for Firefox desktop icon."
    chmod +x "/home/kasm-default-profile/Desktop/firefox.desktop"
    # The chown -R 1000:0 $HOME at the end will handle ownership.
fi

ARCH=$(arch | sed 's/aarch64/arm64/g' | sed 's/x86_64/amd64/g')

echo "Installing Firefox..."

if [[ "${DISTRO}" == @(centos|oracle8|rockylinux9|rockylinux8|oracle9|almalinux9|almalinux8|fedora37|fedora38|fedora39) ]]; then
  echo "Detected RHEL/Fedora-based distribution: ${DISTRO}"
  if command -v dnf &> /dev/null; then
    dnf install -y firefox p11-kit
  else
    yum install -y firefox p11-kit
  fi
  # Perform cleanup for RHEL/Fedora
  if [ -z "${SKIP_CLEAN+x}" ]; then
    if command -v dnf &> /dev/null; then
      dnf clean all
    else
      yum clean all
    fi
  fi
elif [ "${DISTRO}" == "opensuse" ]; then
  echo "Detected OpenSUSE."
  zypper install -yn p11-kit-tools MozillaFirefox
  # Perform cleanup for OpenSUSE
  if [ -z "${SKIP_CLEAN+x}" ]; then
    zypper clean --all
  fi
# COMBINE Noble and Jammy to use the PPA method
elif grep -q Jammy /etc/os-release || grep -q Noble /etc/os-release; then
  echo "Detected Ubuntu Jammy or Noble. Installing Firefox from Mozillateam PPA."
  if [ ! -f '/etc/apt/preferences.d/mozilla-firefox' ]; then
    add-apt-repository -y ppa:mozillateam/ppa
    echo '
Package: *
Pin: release o=LP-PPA-mozillateam
Pin-Priority: 1001
' > /etc/apt/preferences.d/mozilla-firefox
  fi
  apt-get update
  apt-get install -y firefox p11-kit-modules
  # Perform cleanup for APT
  if [ -z "${SKIP_CLEAN+x}" ]; then
    apt-get autoclean
    rm -rf \
      /var/lib/apt/lists/* \
      /var/tmp/*
  fi
elif grep -q "ID=debian" /etc/os-release || grep -q "ID=kali" /etc/os-release || grep -q "ID=parrot" /etc/os-release; then
  echo "Detected Debian/Kali/Parrot. Installing Firefox from unstable repository."
  echo "deb http://deb.debian.org/debian/ unstable main contrib non-free" >> /etc/apt/sources.list.d/debian-unstable.list
cat > /etc/apt/preferences.d/99pin-unstable <<EOF
Package: *
Pin: release a=stable
Pin-Priority: 900

Package: *
Pin: release a=unstable
Pin-Priority: 10
EOF
  apt-get update
  apt-get install -y -t unstable firefox p11-kit-modules
  # Perform cleanup for APT
  if [ -z "${SKIP_CLEAN+x}" ]; then
    apt-get autoclean
    rm -rf \
      /var/lib/apt/lists/* \
      /var/tmp/*
  fi
else
  echo "Detected other Debian-based distribution. Installing Firefox via APT."
  apt-mark unhold firefox || :
  apt-get remove firefox || :
  apt-get update
  apt-get install -y firefox p11-kit-modules
  # Perform cleanup for APT
  if [ -z "${SKIP_CLEAN+x}" ]; then
    apt-get autoclean
    rm -rf \
      /var/lib/apt/lists/* \
      /var/tmp/*
  fi
fi

echo "Firefox installation complete."

# Profile Creation (keep this if you need a specific default profile for Kasm)
echo "Creating Firefox default profile for Kasm..."
if [[ "${DISTRO}" == @(centos|oracle8|rockylinux9|rockylinux8|oracle9|almalinux9|almalinux8|opensuse|fedora37|fedora38|fedora39) ]]; then
  # Set temp XDG_RUNTIME_DIR to avoid permission issues. Preserve the default XDG_RUNTIME_DIR
  XDG_RUNTIME_DIR_TMP="${XDG_RUNTIME_DIR:-}"
  export XDG_RUNTIME_DIR="/tmp/xdg-runtime-dir-kasm-$(mktemp -u XXXX)"
  mkdir -p "${XDG_RUNTIME_DIR}"
  chmod 700 "${XDG_RUNTIME_DIR}"

  chown -R root:root "$HOME"
  firefox -headless -CreateProfile "kasm $HOME/.mozilla/firefox/kasm"
  # Generate a certdb to be detected on squid start
  HOME=/root firefox --headless &
  mkdir -p "/root/.mozilla"
  CERTDB=$(find  "/root/.mozilla"* -name "cert9.db")
  while [ -z "${CERTDB}" ] ; do
    sleep 1
    echo "waiting for certdb"
    CERTDB=$(find  "/root/.mozilla"* -name "cert9.db")
  done
  sleep 2
  kill "$(pgrep firefox)" || :
  CERTDIR=$(dirname "${CERTDB}")
  mv "${CERTDB}" "$HOME/.mozilla/firefox/kasm/"
  rm -Rf "/root/.mozilla"

  # Restore the original XDG_RUNTIME_DIR
  export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR_TMP}"
else
  # Creating Default Profile for Debian/Ubuntu
  XDG_RUNTIME_DIR_TMP="${XDG_RUNTIME_DIR:-}"
  export XDG_RUNTIME_DIR="/tmp/xdg-runtime-dir-kasm-$(mktemp -u XXXX)"
  mkdir -p "${XDG_RUNTIME_DIR}"
  chmod 700 "${XDG_RUNTIME_DIR}"

  chown -R 0:0 "$HOME"
  firefox -headless -CreateProfile "kasm $HOME/.mozilla/firefox/kasm"
  # Restore the original XDG_RUNTIME_DIR
  export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR_TMP}"
fi

# Profile Mapping (keep this if you need to set the default profile for Kasm)
echo "Setting default Firefox profile for Kasm..."
if [[ "${DISTRO}" != @(centos|oracle8|rockylux9|rockylinux8|oracle9|almalinux9|almalinux8|opensuse|fedora37|fedora38|fedora39) ]]; then
cat >>"$HOME/.mozilla/firefox/profiles.ini" <<EOL
[Install4F96D1932A9F858E]
Default=kasm
Locked=1
EOL
elif [[ "${DISTRO}" == @(centos|oracle8|rockylinux9|rockylinux8|oracle9|almalinux9|almalinux8|opensuse|fedora37|fedora38|fedora39) ]]; then
cat >>"$HOME/.mozilla/firefox/profiles.ini" <<EOL
[Install11457493C5A56847]
Default=kasm
Locked=1
EOL
fi

# Desktop Icon Fixes (keep this if specific icon paths are needed)
if [[ "${DISTRO}" == @(rockylinux9|oracle9|almalinux9|fedora39) ]]; then
  sed -i 's#Icon=/usr/lib/firefox#Icon=/usr/lib64/firefox#g' "$HOME/Desktop/firefox.desktop"
fi

# Cleanup for app layer (keep relevant parts for user ownership and cache)
echo "Performing final cleanup..."
chown -R 1000:0 "$HOME"
find /usr/share/ -name "icon-theme.cache" -exec rm -f {} \;
if [ -f "$HOME/Desktop/firefox.desktop" ]; then
  chmod +x "$HOME/Desktop/firefox.desktop"
fi
chown -R 1000:1000 "$HOME/.mozilla"