# MLEnv - ML Environment Manager - Installation Guide

## Prerequisites

Before installing NGC, ensure you have:

1. **Docker** (version 20.10+)
   - Install: https://docs.docker.com/get-docker/

2. **NVIDIA GPU** with compatible drivers
   - Check: `nvidia-smi`

3. **NVIDIA Container Toolkit**
   - Install: https://github.com/NVIDIA/nvidia-container-toolkit

## Quick Installation

### One-Line Install
```bash
# Clone and install
git clone https://github.com/your-username/mlenv.git
cd mlenv
sudo ./install.sh
```

That's it! The installer will:
- ✅ Check all prerequisites
- ✅ Install NGC to `/usr/local/bin`
- ✅ Install shell completions
- ✅ Test GPU access

### Verify Installation
```bash
mlenv help
ngc --version  # Coming soon
```

## Installation Options

### 1. Standard Installation (Requires sudo)
```bash
sudo ./install.sh
```
Installs to `/usr/local/bin` (available system-wide)

### 2. User Installation (No sudo)
```bash
./install.sh --install-dir ~/.local/bin

# Add to PATH if not already there
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

### 3. Custom Location
```bash
./install.sh --install-dir /opt/ngc
export PATH="/opt/ngc:$PATH"
```

### 4. Check Prerequisites Only
```bash
./install.sh --check
```
Verifies Docker and NVIDIA setup without installing

### 5. Force Reinstall
```bash
sudo ./install.sh --force
```
Overwrites existing installation

## Shell Completions

The installer automatically detects your shell and installs completions:

### Bash
```bash
# Installed to one of:
# - /etc/bash_completion.d/ngc
# - /usr/local/etc/bash_completion.d/ngc
# - ~/.bash_completion.d/ngc

# Reload completions
source /etc/bash_completion.d/ngc
# or restart your terminal
```

### Zsh
```bash
# Installed to:
# - /usr/local/share/zsh/site-functions/_ngc
# - ~/.zsh/completion/_ngc

# Reload completions
autoload -U compinit && compinit
# or restart your terminal
```

### Fish
```bash
# Installed to: ~/.config/fish/completions/ngc.fish

# Reload completions
source ~/.config/fish/completions/ngc.fish
# or restart your terminal
```

### Manual Completion Install
If auto-detection fails:
```bash
# Bash
./install.sh --completion-dir /etc/bash_completion.d

# Zsh
./install.sh --completion-dir /usr/local/share/zsh/site-functions

# Fish
./install.sh --completion-dir ~/.config/fish/completions
```

## Testing Installation

Run the test suite:
```bash
chmod +x test-install.sh
./test-install.sh
```

Expected output:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  NGC Installation Test Suite
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Test 1: NGC command exists
✔ mlenv command found in PATH

Test 2: NGC is executable
✔ mlenv is executable

Test 3: NGC help command
✔ mlenv help works

Test 4: Docker availability
✔ Docker command found
✔ Docker daemon is running

Test 5: NVIDIA Container Toolkit
✔ NVIDIA runtime detected

...

✔ All critical tests passed!
```

## Manual Installation

If you prefer not to use the installer:

### 1. Copy Script
```bash
chmod +x ngc
sudo cp ngc /usr/local/bin/
```

### 2. Add to PATH (if not using /usr/local/bin)
```bash
mkdir -p ~/.local/bin
cp ngc ~/.local/bin/
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

### 3. Verify
```bash
which ngc
mlenv help
```

## Troubleshooting Installation

### "Docker not found"
```bash
# Install Docker
# Ubuntu/Debian
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add user to docker group (avoid sudo)
sudo usermod -aG docker $USER
newgrp docker
```

### "Docker daemon not running"
```bash
# Start Docker
sudo systemctl start docker

# Enable on boot
sudo systemctl enable docker
```

### "NVIDIA Container Toolkit not detected"
```bash
# Ubuntu/Debian
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/libnvidia-container/gpgkey | sudo apt-key add -
curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list | \
  sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

sudo apt-get update
sudo apt-get install -y nvidia-container-toolkit
sudo systemctl restart docker

# Test
docker run --rm --gpus all nvidia/cuda:12.0.0-base-ubuntu22.04 nvidia-smi
```

### "Permission denied" when installing
```bash
# Use sudo for system directories
sudo ./install.sh

# Or install to user directory
./install.sh --install-dir ~/.local/bin
```

### "NGC command not found" after installation
```bash
# Check where it was installed
./install.sh --check

# Make sure the install directory is in PATH
echo $PATH

# Add to PATH if needed
export PATH="/usr/local/bin:$PATH"
# Make permanent
echo 'export PATH="/usr/local/bin:$PATH"' >> ~/.bashrc
```

### Completions not working
```bash
# Bash - manually source
source /etc/bash_completion.d/ngc

# Zsh - rebuild completion cache
rm -f ~/.zcompdump
autoload -U compinit && compinit

# Fish - reload
source ~/.config/fish/completions/ngc.fish
```

## Uninstallation

### Using Installer
```bash
sudo ./install.sh --uninstall
```

### Manual Uninstall
```bash
# Remove script
sudo rm /usr/local/bin/ngc

# Remove completions
sudo rm /etc/bash_completion.d/ngc  # Bash
sudo rm /usr/local/share/zsh/site-functions/_ngc  # Zsh
rm ~/.config/fish/completions/ngc.fish  # Fish

# Remove project artifacts (optional)
cd /path/to/your/project
rm -rf .mlenv/
```

## Upgrading

### To Latest Version
```bash
cd mlenv
git pull origin main
sudo ./install.sh --force
```

### Version Check
```bash
mlenv help | head -n 1
# MLEnv - ML Environment Manager - Improved Version
```

## Multi-User Setup

For shared servers:

### 1. Install System-Wide
```bash
sudo ./install.sh --install-dir /usr/local/bin
```

### 2. Configure Docker Group
```bash
# Add all users to docker group
sudo usermod -aG docker user1
sudo usermod -aG docker user2
```

### 3. User-Specific Configs
Each user can have their own:
- Project workspaces
- Requirements files
- Environment variables
- Containers (unique names per project directory)

## CI/CD Integration

### GitHub Actions
```yaml
name: NGC Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Install NGC
        run: |
          chmod +x install.sh ngc
          sudo ./install.sh
      
      - name: Test NGC
        run: |
          chmod +x test-install.sh
          ./test-install.sh
```

### GitLab CI
```yaml
test:
  script:
    - chmod +x install.sh ngc
    - ./install.sh --install-dir ./bin
    - export PATH="./bin:$PATH"
    - mlenv help
```

## Docker-in-Docker Setup

If running NGC inside a container:
```bash
# Mount Docker socket
docker run -v /var/run/docker.sock:/var/run/docker.sock ...

# Install NGC in container
./install.sh --install-dir /usr/local/bin
```

## Next Steps

After installation:

1. **Read the Quick Start**
   ```bash
   cat QUICKSTART.md
   ```

2. **Try Basic Commands**
   ```bash
   mkdir ~/test-project
   cd ~/test-project
   mlenv up
   mlenv exec
   ```

3. **Setup Your First Project**
   ```bash
   # Create requirements.txt
   echo "torch==2.1.0" > requirements.txt
   
   # Start container
   mlenv up --requirements requirements.txt --port 8888:8888
   
   # Launch Jupyter
   mlenv jupyter
   ```

4. **Explore Features**
   ```bash
   mlenv help
   mlenv status
   ```

## Getting Help

- **Documentation**: `mlenv help` or read `README.md`
- **Quick Reference**: See `QUICKSTART.md`
- **Issues**: https://github.com/your-username/mlenv/issues
- **Test Installation**: Run `./test-install.sh`

## System Requirements

### Minimum
- Docker 20.10+
- NVIDIA GPU with 4GB+ VRAM
- 8GB RAM
- 20GB disk space

### Recommended
- Docker 24.0+
- NVIDIA GPU with 16GB+ VRAM
- 32GB RAM
- 100GB disk space (for datasets + models)

## Supported Platforms

- ✅ Ubuntu 20.04, 22.04, 24.04
- ✅ Debian 11, 12
- ✅ CentOS 7, 8
- ✅ RHEL 8, 9
- ✅ Fedora 36+
- ✅ WSL2 (Windows Subsystem for Linux) with NVIDIA support
- ❌ macOS (no NVIDIA GPU support in Docker)
- ❌ Windows native (use WSL2 instead)

**Note:** This tool is designed specifically for Linux systems with NVIDIA GPUs. macOS is not supported due to lack of NVIDIA GPU passthrough in Docker.