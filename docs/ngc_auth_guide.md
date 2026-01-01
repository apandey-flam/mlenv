# NGC Authentication Guide

## Overview

NVIDIA NGC (NVIDIA GPU Cloud) provides access to GPU-optimized containers, models, and tools. Some content is public, while other content (like organization-specific models or enterprise images) requires authentication.

## When Do You Need NGC Authentication?

### ✅ No Authentication Required (Public Images)
```bash
# Official NVIDIA images are public
mlenv up --image nvcr.io/nvidia/pytorch:25.12-py3
mlenv up --image nvcr.io/nvidia/tensorflow:24.12-tf2-py3
mlenv up --image nvcr.io/nvidia/cuda:12.0.0-devel-ubuntu22.04
```

### 🔐 Authentication Required (Private Images)
```bash
# Organization-specific images
mlenv up --image nvcr.io/your-org/custom-model:v1.0

# Private team repositories
mlenv up --image nvcr.io/your-team/research-env:latest

# Enterprise NGC content
mlenv up --image nvcr.io/enterprise/private-app:production
```

## Step-by-Step Setup

### 1. Get Your NGC API Key

1. Visit [https://ngc.nvidia.com](https://ngc.nvidia.com)
2. Sign in or create an account (free)
3. Go to "Setup" → "Generate API Key"
4. Click "Generate API Key"
5. **Copy the key** (you won't be able to see it again!)

### 2. Login with NGC

```bash
# Run the login command
mlenv login

# You'll be prompted:
# Enter your NGC API Key: 

# Paste your API key (it won't be visible while typing)
# Press Enter
```

**Expected Output:**
```
▶ NGC Authentication Setup

ℹ NVIDIA NGC allows you to access private container images and models
ℹ You'll need an NGC API key from: https://ngc.nvidia.com/setup/api-key

Enter your NGC API Key: [hidden]
▶ Logging into nvcr.io...
✔ Successfully logged into nvcr.io
✔ NGC authentication complete!
ℹ You can now pull private images from nvcr.io

ℹ Example: mlenv up --image nvcr.io/your-org/your-image:tag
```

### 3. Verify Authentication

```bash
# Check Docker login status
docker info | grep nvcr.io
# Should show: Username: $oauthtoken

# Check NGC config file
cat ~/.mlenv/config
# Should show your API key (kept secure)

# Test with a private image
mlenv up --image nvcr.io/your-org/your-image:latest
```

## Where Credentials Are Stored

After running `mlenv login`, credentials are stored in two places:

```bash
~/.mlenv/config
# NGC CLI configuration with API key
# Permissions: 600 (read/write for user only)

~/.docker/config.json
# Docker registry authentication
# Contains nvcr.io login token
```

## Using Private Images

Once authenticated, use private images just like public ones:

```bash
# Standard usage
mlenv up --image nvcr.io/your-org/custom-pytorch:v2.1

# With additional options
mlenv up \
  --image nvcr.io/your-org/research-env:latest \
  --requirements requirements.txt \
  --port 8888:8888 \
  --gpu 0,1

# Different organizations
mlenv up --image nvcr.io/org-a/model-a:v1.0
mlenv up --image nvcr.io/org-b/model-b:v2.0
```

## Logout

To remove NGC credentials:

```bash
mlenv logout
```

This will:
- Remove `~/.mlenv/config`
- Logout from `nvcr.io` in Docker
- You'll need to login again to access private images

## Troubleshooting

### Error: "unauthorized: authentication required"

**Cause:** Not logged in to NGC

**Solution:**
```bash
mlenv login
```

### Error: "Error response from daemon: Get https://nvcr.io/v2/: unauthorized"

**Cause:** Invalid or expired API key

**Solution:**
```bash
# Logout and login with new key
mlenv logout
mlenv login
```

### Error: "denied: requested access to the resource is denied"

**Cause:** You don't have access to that image/organization

**Solution:**
- Check the image name is correct
- Verify you have permissions to that organization in NGC
- Contact your NGC administrator

### Check if You're Logged In

```bash
# Method 1: Check Docker
docker info | grep "Username" | grep nvcr.io

# Method 2: Check NGC config
cat ~/.mlenv/config

# Method 3: Try pulling a test image
docker pull nvcr.io/your-org/test-image:latest
```

### Re-authenticate

If you think your credentials are stale:

```bash
# Fresh login
mlenv logout
mlenv login
# Enter new API key
```

## Security Best Practices

### ✅ Do

- Store API keys securely
- Use different API keys for different machines/users
- Rotate API keys periodically
- Keep `~/.mlenv/config` permissions at 600
- Logout on shared systems

### ❌ Don't

- Commit API keys to git
- Share API keys between users
- Store API keys in plain text files
- Use root account unnecessarily
- Leave authentication on public/shared systems

## Example: Enterprise Workflow

```bash
# 1. Team lead generates API key for the project
# https://ngc.nvidia.com/setup/api-key

# 2. Each team member authenticates
mlenv login
# Paste shared API key

# 3. Everyone can now access private images
mlenv up --image nvcr.io/acme-corp/ml-platform:v3.2 \
  --requirements requirements.txt \
  --port 8888:8888

# 4. Work with private models
mlenv exec
# Inside container:
# - Private models accessible
# - Organization datasets available
# - Custom tools pre-installed

# 5. At project end, revoke/rotate keys
```

## Multi-Organization Access

If you work with multiple NGC organizations:

```bash
# Login with API key that has access to multiple orgs
mlenv login

# Use images from different organizations
mlenv up --image nvcr.io/org-alpha/model-a:v1.0
# Work on project A...
mlenv down

mlenv up --image nvcr.io/org-beta/model-b:v2.0
# Work on project B...
mlenv down
```

**Note:** Your API key must have permissions to all organizations you want to access.

## API Key Management

### Generate New Key

1. Go to https://ngc.nvidia.com/setup/api-key
2. Click "Generate API Key"
3. Old keys are automatically revoked
4. Update all systems with new key:
   ```bash
   mlenv logout
   mlenv login  # Enter new key
   ```

### Key Permissions

NGC API keys can have different permissions:
- **Compute**: Run workloads
- **Registry**: Pull/push containers
- **Models**: Access AI models
- **Datasets**: Access datasets

Check your key permissions in the NGC web interface.

## FAQ

**Q: Do I need to login every time?**  
A: No, credentials persist until you logout or they expire.

**Q: Can I use the same key on multiple machines?**  
A: Yes, but it's better to generate separate keys for tracking/revocation.

**Q: What if I lose my API key?**  
A: Generate a new one from NGC. Old keys are automatically revoked.

**Q: Can I use NGC without an account?**  
A: Yes, for public images only. Private content requires an NGC account.

**Q: Is there a cost for NGC?**  
A: Basic NGC access is free. Some enterprise features require a subscription.

## Resources

- **NGC Catalog**: https://catalog.ngc.nvidia.com
- **API Key Setup**: https://ngc.nvidia.com/setup/api-key
- **NGC Documentation**: https://docs.nvidia.com/ngc/
- **NGC CLI**: https://ngc.nvidia.com/setup/installers/cli

## Support

If you encounter issues:
1. Check the troubleshooting section above
2. Verify your NGC account status
3. Check NGC service status: https://status.ngc.nvidia.com
4. Contact NVIDIA NGC support for account issues