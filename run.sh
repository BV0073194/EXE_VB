#!/bin/bash

# Exit on error
set -e

echo "Starting setup..."

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Update system packages
echo "Updating system packages..."
sudo apt-get update -y && sudo apt-get upgrade -y

# Install Docker if not installed
if ! command_exists docker; then
    echo "Installing Docker..."
    sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update -y
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io
    sudo systemctl enable docker
    sudo systemctl start docker
else
    echo "Docker is already installed."
fi

# Install Python if not installed
if ! command_exists python3; then
    echo "Installing Python 3..."
    sudo apt-get install -y python3 python3-pip
else
    echo "Python 3 is already installed."
fi

# Install required Python packages
echo "Installing Python dependencies..."
pip3 install fastapi uvicorn docker

# Create Dockerfile for Wine
echo "Setting up Wine Docker image..."
cat > Dockerfile <<EOF
FROM ubuntu:20.04

# Install Wine and dependencies
RUN dpkg --add-architecture i386 &&     apt-get update &&     apt-get install -y wine xvfb wget x11vnc &&     apt-get clean

WORKDIR /sandbox
CMD ["xvfb-run", "-a", "wine", "app.exe"]
EOF

# Build the Docker image
docker build -t wine-image .

# Run the FastAPI server
echo "Starting FastAPI server..."
uvicorn server:app --host 0.0.0.0 --port 8000
