#!/usr/bin/env bash

set +e

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo ":: ERROR: This script is meant to be run on macOS only."
  exit 1
fi

if [ "$(whoami)" != "root" ]; then
  echo "This script needs to be run as root."
  exit 1
fi

# Load daemon if available
if [ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh 

  if which darwin-uninstaller &>/dev/null; then
    echo "Uninstalling nix-darwin"
    darwin-uninstaller
  fi
fi

# Stop and remove all nix-related services
launchctl list | grep nix | cut -f 3 | while read unit; do
  launchctl bootout "system/${unit}"
done
find /Library/LaunchDaemons -name "*nix*" -delete

# Remove all users nix created
dscl . list /Users | grep nix | while read user; do
  sudo dscl . delete "/Users/${user}"
done

# Remove disk volume from nix, and remove it from fstab
diskutil apfs deleteVolume "Nix Store"
sed -i '' '/\/nix/d' /etc/fstab

# Remove old secret for Nix volume
sudo security delete-generic-password -a "Nix Store" -s "Nix Store" -l "disk3 encryption password" -D "Encrypted volume password"

echo "DONE!"
