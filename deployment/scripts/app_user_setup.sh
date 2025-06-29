#!/bin/bash
echo "script runs at:" $(date '+%Y-%m-%d %H:%M:%S')

# Variables
FUNCTIONAL_USER="appadmin"
APP_DIR="/opt/app"
CURRENT_USER="$(whoami)"
SUDO_RULE="$CURRENT_USER ALL=(ALL) NOPASSWD: /bin/su - $FUNCTIONAL_USER"
SUDOERS_FILE="/etc/sudoers.d/$FUNCTIONAL_USER"

# Ensure the user exists
if id "$FUNCTIONAL_USER" &>/dev/null; then
    echo "User $FUNCTIONAL_USER already exists."
else
    echo "Creating user $FUNCTIONAL_USER..."
    sudo useradd -m -s /bin/bash "$FUNCTIONAL_USER"
    sudo usermod -aG sudo "$FUNCTIONAL_USER" 2>/dev/null || sudo usermod -aG wheel "$FUNCTIONAL_USER"
    sudo passwd -l "$FUNCTIONAL_USER"

    if ! id "$FUNCTIONAL_USER" &>/dev/null; then
        echo "Failed to create user $FUNCTIONAL_USER." >&2
        exit 1
    fi
fi

# Add sudoers rule
echo "$SUDO_RULE" | sudo tee "$SUDOERS_FILE" > /dev/null
sudo chmod 0440 "$SUDOERS_FILE"
sudo visudo -cf "$SUDOERS_FILE"

# Setup directory
sudo mkdir -p "$APP_DIR"
sudo chown -R "$FUNCTIONAL_USER:$FUNCTIONAL_USER" "$APP_DIR"
sudo chmod 0755 "$APP_DIR"

echo "Setup complete."
