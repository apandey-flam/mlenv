# MLENV Quick Reference

## Installation
```bash
chmod +x mlenv
sudo mv mlenv /usr/local/bin/  # or add to PATH
```

## NGC Authentication

### For Private Images
If you need to access private NGC container images, you must authenticate first:

```bash
# 1. Get your API key from https://ngc.nvidia.com/setup/api-key

# 2. Login
mlenv login
# Enter your NGC API Key: [paste key]

# 3. Now you can use private images
mlenv up --image nvcr.io/your-org/private-image:latest
```

**Public images** (like `nvcr.io/nvidia/pytorch:25.12-py3`) don't require authentication.

### Check Login Status
```bash
# Check if logged in
docker info | grep nvcr.io

# Or check NGC config
cat ~/.mlenv/config
```

### Logout
```bash
mlenv logout
```

## Common Commands

### Basic Usage
```bash
mlenv login                # Authenticate with NGC (for private images)
mlenv up                   # Start container
mlenv exec                 # Enter container
mlenv down                 # Stop container
mlenv rm                   # Remove container
mlenv status               # Check status
```

### Development Workflow
```bash
# 1. Setup with requirements
mlenv up --requirements requirements.txt --port 8888:8888

# 2. Start Jupyter
mlenv jupyter

# 3. Or use terminal
mlenv exec

# 4. Run scripts
mlenv exec -c "python train.py"

# 5. Check GPU usage
mlenv status

# 6. Stop when done
mlenv down
```

### Advanced Options
```bash
# Specific GPUs
mlenv up --gpu 0,1

# Custom image
mlenv up --image nvcr.io/nvidia/tensorflow:24.12-tf2-py3

# Resource limits
mlenv up --memory 16g --cpus 4.0

# Environment variables
mlenv up --env-file .env

# Multiple ports
mlenv up --port 8888:8888,6006:6006,8080:8080

# Force requirements reinstall
mlenv up --force-requirements

# Verbose logging
mlenv up --verbose
```

## Real-World Examples

### Example 1: PyTorch Training
```bash
# requirements.txt
torch==2.1.0
torchvision==0.16.0
tensorboard==2.15.0
wandb==0.16.0

# .env
WANDB_API_KEY=your_key_here
CUDA_VISIBLE_DEVICES=0,1

# Setup
mlenv up \
  --requirements requirements.txt \
  --env-file .env \
  --port 6006:6006 \
  --gpu 0,1 \
  --memory 32g

# Train
mlenv exec -c "python train.py --batch-size 64 --epochs 100"

# Monitor TensorBoard (in another terminal)
mlenv exec -c "tensorboard --logdir runs --host 0.0.0.0"
# Open: http://localhost:6006
```

### Example 2: Jupyter Development
```bash
mlenv up --port 8888:8888 --gpu all
mlenv jupyter
# Open the URL shown in terminal
```

### Example 3: Data Processing
```bash
# requirements.txt
pandas==2.1.0
polars==0.19.0
pyarrow==14.0.0

mlenv up --requirements requirements.txt --memory 64g --cpus 8.0
mlenv exec -c "python process_data.py --input data/raw --output data/processed"
```

### Example 4: Multi-GPU Training
```bash
# Use all GPUs
mlenv up --requirements requirements.txt

# DDP training
mlenv exec -c "torchrun --nproc_per_node=4 train_ddp.py"
```

### Example 5: Model Serving
```bash
mlenv up --port 8000:8000 --gpu 0
mlenv exec -c "uvicorn app:app --host 0.0.0.0 --port 8000"
# API available at http://localhost:8000
```

## Tips & Tricks

### Check GPU Usage
```bash
# Inside container
mlenv exec -c "nvidia-smi"

# Quick status
mlenv status
```

### Install Additional Packages
```bash
# One-time install
mlenv exec -c "pip install transformers accelerate"

# Persistent: add to requirements.txt and:
mlenv rm
mlenv up --requirements requirements.txt
```

### Debug Issues
```bash
# View logs
mlenv logs

# Verbose mode
mlenv up --verbose

# Check container
docker logs ngc-myproject-xxxxxxxx
```

### Multiple Projects
Each directory gets its own container automatically:
```bash
cd /projects/project1
mlenv up  # Creates ngc-project1-abc123

cd /projects/project2  
mlenv up  # Creates ngc-project2-def456
```

### Access Container Files from Host
```bash
# Files are automatically synced (bind mount)
# Edit on host with VS Code, run in container with mlenv exec
```

### Port Already in Use?
```bash
# Find what's using port 8888
lsof -ti:8888 | xargs kill -9

# Or use different port
mlenv up --port 8889:8888
mlenv jupyter
```

### Clean Everything
```bash
mlenv rm                      # Remove container
mlenv clean                   # Clean MLEnv artifacts
docker system prune -a      # Clean all Docker (careful!)
```

## Troubleshooting

### "Container not running"
```bash
mlenv status  # Check status
mlenv up      # Start it
```

### "Port already allocated"
```bash
# Stop old container
mlenv down
mlenv rm

# Start with new port
mlenv up --port 8889:8888
```

### "Permission denied" errors
By default runs as your user. If you need root:
```bash
mlenv up --no-user-mapping
```

### GPU not detected
```bash
# Check NVIDIA runtime
docker info | grep nvidia

# If missing, install nvidia-container-toolkit:
# https://github.com/NVIDIA/nvidia-container-toolkit
```

### Requirements won't update
```bash
mlenv up --force-requirements
```

### Out of memory
```bash
# Increase shared memory
# Edit script: --shm-size=32g

# Or limit memory per container
mlenv up --memory 16g
```

## Keyboard Shortcuts

Inside container (mlenv exec):
- `Ctrl+D` or `exit` - Leave container (keeps running)
- `Ctrl+C` - Stop current command
- `Ctrl+P, Ctrl+Q` - Detach from container

## Integration with Tools

### VS Code
```bash
# Install Docker extension
# Right-click container in Docker panel → "Attach Visual Studio Code"
```

### PyCharm
```bash
# Settings → Project → Python Interpreter
# Add → Docker → Select mlenv container
```

### Git
```bash
# .gitignore
.mlenv/
```

## Performance Tips

1. **Use SSD for workspace** - Much faster than HDD
2. **Increase shared memory** if using DataLoader with many workers
3. **Limit GPU devices** if you don't need all GPUs
4. **Set CPU limits** to avoid hogging the system
5. **Use requirements caching** - Don't use --force-requirements unless needed

## Security Notes

- Runs as your user by default (not root)
- Environment files (.env) should be gitignored
- Ports are only exposed on localhost by default
- Container isolated from host except /workspace mount