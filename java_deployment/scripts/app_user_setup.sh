#!/bin/bash

# Exit immediately on error, treat unset variables as errors, and ensure pipelines fail on any command failure
set -euxo pipefail

# Variables
FUNCTIONAL_USER="jvapp"
APP_DIR="/opt/app"
CURRENT_USER="$(whoami)"
SUDO_RULE="$CURRENT_USER ALL=(ALL) NOPASSWD: /bin/su - FUNCTIONAL_USER"
SUDOERS_FILE="/etc/sudoers.d/$FUNCTIONAL_USER"

# 1. Ensure the user exists
if id "$FUNCTIONAL_USER" &>/dev/null; then
    echo "User $FUNCTIONAL_USER already exists."
else
    echo "Creating user $FUNCTIONAL_USER..."
    useradd -m -s /bin/bash -G sudo "$FUNCTIONAL_USER"
fi

# 2. Disable password login for the user
echo "Disabling password login for $FUNCTIONAL_USER..."
usermod -p '!' "$FUNCTIONAL_USER"

# 3. Add sudo rule for passwordless su
echo "Adding sudo rule..."
echo "$SUDO_RULE" > "$SUDOERS_FILE"
chmod 0440 "$SUDOERS_FILE"
visudo -cf "$SUDOERS_FILE"

# 4. Ensure the app directory exists
echo "Ensuring $APP_DIR exists..."
mkdir -p "$APP_DIR"
chmod 0755 "$APP_DIR"

# 5. Change ownership
echo "Changing ownership of $APP_DIR to $FUNCTIONAL_USER..."
chown -R "$FUNCTIONAL_USER:$FUNCTIONAL_USER" "$APP_DIR"

echo "Setup complete."
