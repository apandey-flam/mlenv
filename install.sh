#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# MLEnv - ML Environment Manager - Installer
# =============================================================================

VERSION="1.0.0"
SCRIPT_NAME="mlenv"
INSTALL_DIR="/usr/local/bin"
CUSTOM_INSTALL_DIR=""
COMPLETION_DIR=""
FORCE_INSTALL=false
UNINSTALL=false
CHECK_ONLY=false

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# -----------------------------
# Logging functions
# -----------------------------
info() {
  echo -e "${BLUE}ℹ${NC} $1"
}

success() {
  echo -e "${GREEN}✔${NC} $1"
}

warn() {
  echo -e "${YELLOW}⚠${NC} $1"
}

error() {
  echo -e "${RED}✖${NC} $1"
}

die() {
  error "$1"
  exit 1
}

# -----------------------------
# Check prerequisites
# -----------------------------
check_docker() {
  if ! command -v docker >/dev/null 2>&1; then
    error "Docker is not installed"
    info "Install Docker from: https://docs.docker.com/get-docker/"
    return 1
  fi
  success "Docker found: $(docker --version | head -n1)"
  
  if ! docker info >/dev/null 2>&1; then
    error "Docker daemon is not running"
    info "Start Docker and try again"
    return 1
  fi
  success "Docker daemon is running"
  return 0
}

check_nvidia_runtime() {
  if ! docker info 2>/dev/null | grep -q "Runtimes:.*nvidia"; then
    error "NVIDIA Container Toolkit not detected"
    info "Install from: https://github.com/NVIDIA/nvidia-container-toolkit"
    return 1
  fi
  success "NVIDIA Container Toolkit found"
  
  # Test GPU access
  if docker run --rm --gpus all nvidia/cuda:12.0.0-base-ubuntu22.04 nvidia-smi >/dev/null 2>&1; then
    success "GPU access verified"
  else
    warn "GPU test failed - you may need to configure your NVIDIA drivers"
  fi
  return 0
}

check_prerequisites() {
  info "Checking prerequisites..."
  echo ""
  
  local docker_ok=true
  local nvidia_ok=true
  
  check_docker || docker_ok=false
  echo ""
  check_nvidia_runtime || nvidia_ok=false
  echo ""
  
  if [ "$docker_ok" = false ] || [ "$nvidia_ok" = false ]; then
    error "Prerequisites not met"
    return 1
  fi
  
  success "All prerequisites met!"
  return 0
}

# -----------------------------
# Detect shell
# -----------------------------
detect_shell() {
  local shell_name
  shell_name="$(basename "$SHELL")"
  
  case "$shell_name" in
    bash)
      echo "bash"
      ;;
    zsh)
      echo "zsh"
      ;;
    fish)
      echo "fish"
      ;;
    *)
      echo "unknown"
      ;;
  esac
}

get_completion_dir() {
  local shell_type="$1"
  
  case "$shell_type" in
    bash)
      if [ -d "/etc/bash_completion.d" ]; then
        echo "/etc/bash_completion.d"
      elif [ -d "/usr/local/etc/bash_completion.d" ]; then
        echo "/usr/local/etc/bash_completion.d"
      else
        echo "$HOME/.bash_completion.d"
      fi
      ;;
    zsh)
      if [ -d "/usr/local/share/zsh/site-functions" ]; then
        echo "/usr/local/share/zsh/site-functions"
      else
        echo "$HOME/.zsh/completion"
      fi
      ;;
    fish)
      if [ -d "$HOME/.config/fish/completions" ]; then
        echo "$HOME/.config/fish/completions"
      else
        echo "$HOME/.config/fish/completions"
      fi
      ;;
    *)
      echo ""
      ;;
  esac
}

# -----------------------------
# Create shell completion
# -----------------------------
create_bash_completion() {
  cat <<'EOF'
# Bash completion for ngc

_mlenv_completion() {
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    
    # Main commands
    local commands="login logout up exec down restart rm status list jupyter logs clean version help"
    
    # Options for up command
    local up_opts="--image --requirements --force-requirements --port --gpu --env-file --memory --cpus --no-user-mapping --verbose"
    
    # Options for exec command
    local exec_opts="-c"
    
    if [ $COMP_CWORD -eq 1 ]; then
        COMPREPLY=( $(compgen -W "${commands}" -- ${cur}) )
        return 0
    fi
    
    case "${prev}" in
        up)
            COMPREPLY=( $(compgen -W "${up_opts}" -- ${cur}) )
            return 0
            ;;
        exec)
            COMPREPLY=( $(compgen -W "${exec_opts}" -- ${cur}) )
            return 0
            ;;
        --image)
            COMPREPLY=( $(compgen -W "nvcr.io/nvidia/pytorch:25.12-py3 nvcr.io/nvidia/tensorflow:24.12-tf2-py3" -- ${cur}) )
            return 0
            ;;
        --requirements|--env-file)
            COMPREPLY=( $(compgen -f -- ${cur}) )
            return 0
            ;;
        --gpu)
            COMPREPLY=( $(compgen -W "all 0 1 0,1 0,1,2,3" -- ${cur}) )
            return 0
            ;;
        --memory)
            COMPREPLY=( $(compgen -W "8g 16g 32g 64g" -- ${cur}) )
            return 0
            ;;
        --cpus)
            COMPREPLY=( $(compgen -W "2.0 4.0 8.0 16.0" -- ${cur}) )
            return 0
            ;;
    esac
    
    return 0
}

complete -F _mlenv_completion ngc
EOF
}

create_zsh_completion() {
  cat <<'EOF'
#compdef ngc

_mlenv() {
    local -a commands
    commands=(
        'login:Authenticate with NGC'
        'logout:Remove NGC authentication'
        'up:Create/start container'
        'exec:Open interactive shell'
        'down:Stop container'
        'restart:Restart container'
        'rm:Remove container'
        'status:Show container status'
        'list:List all NGC containers'
        'jupyter:Start Jupyter Lab'
        'logs:View debug logs'
        'clean:Remove NGC artifacts'
        'version:Show version'
        'help:Show help'
    )
    
    local -a up_opts
    up_opts=(
        '--image:Docker image'
        '--requirements:Requirements file'
        '--force-requirements:Force reinstall'
        '--port:Port forwarding'
        '--gpu:GPU devices'
        '--env-file:Environment file'
        '--memory:Memory limit'
        '--cpus:CPU limit'
        '--no-user-mapping:Run as root'
        '--verbose:Verbose output'
    )
    
    if (( CURRENT == 2 )); then
        _describe 'command' commands
    elif (( CURRENT == 3 )); then
        case "$words[2]" in
            up)
                _describe 'option' up_opts
                ;;
            exec)
                _arguments '-c[Command to execute]:command:'
                ;;
        esac
    fi
}

_ngc "$@"
EOF
}

create_fish_completion() {
  cat <<'EOF'
# Fish completion for ngc

# Commands
complete -c mlenv -f -n '__fish_use_subcommand' -a 'login' -d 'Authenticate with NGC'
complete -c mlenv -f -n '__fish_use_subcommand' -a 'logout' -d 'Remove NGC authentication'
complete -c mlenv -f -n '__fish_use_subcommand' -a 'up' -d 'Create/start container'
complete -c mlenv -f -n '__fish_use_subcommand' -a 'exec' -d 'Open interactive shell'
complete -c mlenv -f -n '__fish_use_subcommand' -a 'down' -d 'Stop container'
complete -c mlenv -f -n '__fish_use_subcommand' -a 'restart' -d 'Restart container'
complete -c mlenv -f -n '__fish_use_subcommand' -a 'rm' -d 'Remove container'
complete -c mlenv -f -n '__fish_use_subcommand' -a 'status' -d 'Show container status'
complete -c mlenv -f -n '__fish_use_subcommand' -a 'list' -d 'List all NGC containers'
complete -c mlenv -f -n '__fish_use_subcommand' -a 'jupyter' -d 'Start Jupyter Lab'
complete -c mlenv -f -n '__fish_use_subcommand' -a 'logs' -d 'View debug logs'
complete -c mlenv -f -n '__fish_use_subcommand' -a 'clean' -d 'Remove NGC artifacts'
complete -c mlenv -f -n '__fish_use_subcommand' -a 'version' -d 'Show version'
complete -c mlenv -f -n '__fish_use_subcommand' -a 'help' -d 'Show help'

# Options for 'up' command
complete -c mlenv -n '__fish_seen_subcommand_from up' -l image -d 'Docker image' -r
complete -c mlenv -n '__fish_seen_subcommand_from up' -l requirements -d 'Requirements file' -r -F
complete -c mlenv -n '__fish_seen_subcommand_from up' -l force-requirements -d 'Force reinstall'
complete -c mlenv -n '__fish_seen_subcommand_from up' -l port -d 'Port forwarding' -r
complete -c mlenv -n '__fish_seen_subcommand_from up' -l gpu -d 'GPU devices' -r -a 'all 0 1 0,1'
complete -c mlenv -n '__fish_seen_subcommand_from up' -l env-file -d 'Environment file' -r -F
complete -c mlenv -n '__fish_seen_subcommand_from up' -l memory -d 'Memory limit' -r -a '8g 16g 32g 64g'
complete -c mlenv -n '__fish_seen_subcommand_from up' -l cpus -d 'CPU limit' -r -a '2.0 4.0 8.0 16.0'
complete -c mlenv -n '__fish_seen_subcommand_from up' -l no-user-mapping -d 'Run as root'
complete -c mlenv -n '__fish_seen_subcommand_from up' -l verbose -d 'Verbose output'

# Options for 'exec' command
complete -c mlenv -n '__fish_seen_subcommand_from exec' -s c -d 'Command to execute' -r
EOF
}

# -----------------------------
# Installation
# -----------------------------
install_script() {
  local target_dir="$1"
  local script_path="$target_dir/$SCRIPT_NAME"
  
  # Check if ngc script exists in current directory
  if [ ! -f "$SCRIPT_NAME" ]; then
    die "NGC script not found in current directory. Please run installer from the same directory as the ngc script."
  fi
  
  # Check if target directory exists
  if [ ! -d "$target_dir" ]; then
    info "Creating directory: $target_dir"
    mkdir -p "$target_dir" || die "Failed to create directory: $target_dir"
  fi
  
  # Check for existing installation
  if [ -f "$script_path" ] && [ "$FORCE_INSTALL" = false ]; then
    error "NGC is already installed at: $script_path"
    info "Use --force to overwrite, or --uninstall to remove"
    return 1
  fi
  
  # Copy script
  info "Installing NGC to: $script_path"
  cp "$SCRIPT_NAME" "$script_path" || die "Failed to copy script"
  chmod +x "$script_path" || die "Failed to make script executable"
  
  success "NGC installed successfully"
  return 0
}

install_completions() {
  local shell_type="$1"
  local comp_dir
  
  if [ -n "$COMPLETION_DIR" ]; then
    comp_dir="$COMPLETION_DIR"
  else
    comp_dir="$(get_completion_dir "$shell_type")"
  fi
  
  if [ -z "$comp_dir" ]; then
    warn "Could not determine completion directory for $shell_type"
    return 1
  fi
  
  # Create completion directory if it doesn't exist
  if [ ! -d "$comp_dir" ]; then
    info "Creating completion directory: $comp_dir"
    mkdir -p "$comp_dir" || {
      warn "Failed to create completion directory: $comp_dir"
      return 1
    }
  fi
  
  # Install appropriate completion
  case "$shell_type" in
    bash)
      info "Installing Bash completion..."
      create_bash_completion > "$comp_dir/ngc" || {
        warn "Failed to install Bash completion"
        return 1
      }
      success "Bash completion installed to: $comp_dir/ngc"
      info "Reload with: source $comp_dir/ngc"
      ;;
    zsh)
      info "Installing Zsh completion..."
      create_zsh_completion > "$comp_dir/_ngc" || {
        warn "Failed to install Zsh completion"
        return 1
      }
      success "Zsh completion installed to: $comp_dir/_ngc"
      info "Reload with: autoload -U compinit && compinit"
      ;;
    fish)
      info "Installing Fish completion..."
      create_fish_completion > "$comp_dir/ngc.fish" || {
        warn "Failed to install Fish completion"
        return 1
      }
      success "Fish completion installed to: $comp_dir/ngc.fish"
      info "Reload with: source $comp_dir/ngc.fish"
      ;;
    *)
      warn "Unknown shell type: $shell_type"
      return 1
      ;;
  esac
  
  return 0
}

# -----------------------------
# Uninstallation
# -----------------------------
uninstall_script() {
  local target_dir="$1"
  local script_path="$target_dir/$SCRIPT_NAME"
  
  if [ ! -f "$script_path" ]; then
    warn "NGC not found at: $script_path"
    return 1
  fi
  
  info "Removing NGC from: $script_path"
  rm -f "$script_path" || die "Failed to remove script"
  
  success "NGC uninstalled"
  return 0
}

uninstall_completions() {
  local shell_type="$1"
  local comp_dir="$(get_completion_dir "$shell_type")"
  local removed=false
  
  if [ -z "$comp_dir" ]; then
    return 0
  fi
  
  case "$shell_type" in
    bash)
      if [ -f "$comp_dir/ngc" ]; then
        rm -f "$comp_dir/ngc"
        success "Removed Bash completion"
        removed=true
      fi
      ;;
    zsh)
      if [ -f "$comp_dir/_ngc" ]; then
        rm -f "$comp_dir/_ngc"
        success "Removed Zsh completion"
        removed=true
      fi
      ;;
    fish)
      if [ -f "$comp_dir/ngc.fish" ]; then
        rm -f "$comp_dir/ngc.fish"
        success "Removed Fish completion"
        removed=true
      fi
      ;;
  esac
  
  if [ "$removed" = false ]; then
    info "No completions found for $shell_type"
  fi
}

# -----------------------------
# Main installation flow
# -----------------------------
do_install() {
  local install_dir="${CUSTOM_INSTALL_DIR:-$INSTALL_DIR}"
  local shell_type="$(detect_shell)"
  
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  MLEnv - ML Environment Manager - Installer v${VERSION}"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  
  # Check prerequisites
  if ! check_prerequisites; then
    die "Installation aborted due to missing prerequisites"
  fi
  echo ""
  
  # Install script
  info "Installation directory: $install_dir"
  if ! install_script "$install_dir"; then
    die "Installation failed"
  fi
  echo ""
  
  # Install completions
  if [ "$shell_type" != "unknown" ]; then
    info "Detected shell: $shell_type"
    if install_completions "$shell_type"; then
      echo ""
    fi
  else
    warn "Could not detect shell type, skipping completions"
    echo ""
  fi
  
  # Verify installation
  if command -v ngc >/dev/null 2>&1; then
    success "NGC is ready to use!"
    echo ""
    info "Try: ngc help"
  else
    warn "NGC installed but not in PATH"
    info "Add to PATH: export PATH=\"$install_dir:\$PATH\""
    info "Or add this line to your ~/.bashrc or ~/.zshrc"
  fi
  
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  success "Installation complete!"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

do_uninstall() {
  local install_dir="${CUSTOM_INSTALL_DIR:-$INSTALL_DIR}"
  local shell_type="$(detect_shell)"
  
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  MLEnv - ML Environment Manager - Uninstaller"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  
  uninstall_script "$install_dir"
  echo ""
  
  if [ "$shell_type" != "unknown" ]; then
    uninstall_completions "$shell_type"
    echo ""
  fi
  
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  success "Uninstallation complete!"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

do_check() {
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  MLEnv - ML Environment Manager - System Check"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  
  if check_prerequisites; then
    echo ""
    success "Your system is ready for NGC!"
  else
    echo ""
    error "Please fix the issues above before installing NGC"
    exit 1
  fi
}

# -----------------------------
# Usage
# -----------------------------
show_help() {
  cat <<EOF
MLEnv - ML Environment Manager - Installer

USAGE:
  ./install.sh [options]

OPTIONS:
  --install-dir <dir>     Custom installation directory (default: /usr/local/bin)
  --completion-dir <dir>  Custom completion directory (auto-detected by default)
  --force                 Force overwrite existing installation
  --uninstall             Remove NGC from system
  --check                 Check prerequisites without installing
  --help                  Show this help message

EXAMPLES:
  # Standard installation (requires sudo for /usr/local/bin)
  sudo ./install.sh

  # Install to custom directory
  ./install.sh --install-dir ~/.local/bin

  # Force reinstall
  sudo ./install.sh --force

  # Check system prerequisites
  ./install.sh --check

  # Uninstall
  sudo ./install.sh --uninstall

NOTES:
  - Checks for Docker and NVIDIA Container Toolkit
  - Installs shell completions for bash/zsh/fish
  - Adds ngc to system PATH
  - Does NOT require internet connection (offline install)

AFTER INSTALLATION:
  Run: ngc help
  Or: ngc up --requirements requirements.txt

EOF
}

# -----------------------------
# Parse arguments
# -----------------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --install-dir)
      CUSTOM_INSTALL_DIR="$2"
      shift 2
      ;;
    --completion-dir)
      COMPLETION_DIR="$2"
      shift 2
      ;;
    --force)
      FORCE_INSTALL=true
      shift
      ;;
    --uninstall)
      UNINSTALL=true
      shift
      ;;
    --check)
      CHECK_ONLY=true
      shift
      ;;
    --help|-h)
      show_help
      exit 0
      ;;
    *)
      error "Unknown option: $1"
      echo ""
      show_help
      exit 1
      ;;
  esac
done

# -----------------------------
# Execute
# -----------------------------
if [ "$CHECK_ONLY" = true ]; then
  do_check
elif [ "$UNINSTALL" = true ]; then
  do_uninstall
else
  do_install
fi