# GitHub Setup Guide for SaHayak

## Step 1: Create GitHub Repository

You need to create a repository on GitHub first. Here's how:

1. Go to https://github.com/new (or log in at github.com, then click **+** icon → **New repository**)
2. Fill in the repository details:
   - **Repository name:** `SaHayak` (or your preferred name)
   - **Description:** Cross-platform blood donation coordination app
   - **Visibility:** Choose **Public** or **Private**
   - **Initialize with:** Leave unchecked (we already have local commits)
3. Click **Create repository**

After creation, GitHub will show you the repository URL. It will look like one of these:
- **HTTPS:** `https://github.com/YOUR-USERNAME/SaHayak.git`
- **SSH:** `git@github.com:YOUR-USERNAME/SaHayak.git`

Replace `YOUR-USERNAME` with your actual GitHub username.

## Step 2: Choose Authentication Method

### Option A: HTTPS with Personal Access Token (Recommended for most users)

1. Go to https://github.com/settings/tokens
2. Click **Generate new token** → **Generate new token (classic)**
3. Give it a name like "SaHayak Local Push"
4. Select scopes: Check **repo** (full control of private repositories)
5. Click **Generate token**
6. **COPY the token immediately** (you won't see it again!)
7. Save it securely - you'll use it as the password when Git prompts

**Advantages:**
- Easier to set up
- Works on any machine
- Can be revoked easily from GitHub settings

### Option B: SSH Key (More secure, no token)

1. Open PowerShell as Administrator
2. Generate key: `ssh-keygen -t ed25519 -C "your-github-email@example.com"`
3. When prompted for location, press Enter (uses default: `C:\Users\YOUR-USER\.ssh\id_ed25519`)
4. Enter a passphrase (optional but recommended)
5. Copy the PUBLIC key contents:
   ```powershell
   Get-Content "$env:USERPROFILE\.ssh\id_ed25519.pub" | Set-Clipboard
   ```
6. Go to https://github.com/settings/keys
7. Click **New SSH key**, paste the public key, give it a name like "SaHayak Build Machine"
8. Click **Add SSH key**

**Advantages:**
- More secure (no token stored)
- No password needed once configured
- Standard for development teams

## Step 3: Configure Git Remote

Once you have your repository URL and authentication ready:

```powershell
cd "g:\Sahayak"
git remote add origin https://github.com/YOUR-USERNAME/SaHayak.git
# OR for SSH:
# git remote add origin git@github.com:YOUR-USERNAME/SaHayak.git
```

Verify it was added:
```powershell
git remote -v
```

You should see:
```
origin  https://github.com/YOUR-USERNAME/SaHayak.git (fetch)
origin  https://github.com/YOUR-USERNAME/SaHayak.git (push)
```

## Step 4: Push to GitHub

```powershell
cd "g:\Sahayak"
git push -u origin master
```

**For HTTPS with Token:**
- When prompted for username: Enter your GitHub username
- When prompted for password: Enter your Personal Access Token (not your actual password)

**For SSH:**
- If you set a passphrase, enter it when prompted
- If no passphrase, it pushes automatically

## Summary of Commands

```powershell
# Check remote is configured
git remote -v

# Push all branches to GitHub
git push -u origin master

# Verify push was successful
git log --oneline -5  # Shows local commits
git ls-remote origin   # Shows remote commits
```

## Troubleshooting

**"fatal: remote origin already exists"**
- Someone already added a remote. Fix: `git remote remove origin` then add again

**"fatal: authentication failed"**
- HTTPS: Wrong username/token
- SSH: SSH key not on GitHub or passphrase wrong

**"fatal: couldn't read remote repository"**
- Repository URL is wrong, or network issue

## Next Steps

Once pushed to GitHub:
1. Your code is backed up in the cloud
2. Team members can clone: `git clone https://github.com/YOUR-USERNAME/SaHayak.git`
3. Future changes: `git push origin master`
4. Pull changes: `git pull origin master`
