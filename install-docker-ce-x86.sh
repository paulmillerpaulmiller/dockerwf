#!/bin/bash
# Install docker community edition on Ubuntu.
# See instructions https://docs.docker.com/engine/install/ubuntu/

if [ "$EUID" -ne 0 ]; then
  echo "Run this script with sudo."
  exit 1
fi

# Who is the user that ran as sudo?
ORIGUSER="${SUDO_USER}"

# Uninstall old docker versions
for PACKAGE in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; \
do
  sudo apt-get remove $PACKAGE;
done

# Get the docker repository
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  | sudo gpg --batch --yes --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
  | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install docker community edition
sudo apt-get update
sudo apt-get install -y \
  docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Now, be able to run docker command line without sudo.
# This requires adding the user to the docker group.
sudo groupadd -f docker
sudo usermod -aG docker "${ORIGUSER}"
sudo newgrp docker <<< exit >/dev/null

# Test the installation.
sudo -u "${ORIGUSER}" -g "${ORIGUSER}" docker run hello-world

echo "Success. You can test docker with: 'docker run hello-world'"
