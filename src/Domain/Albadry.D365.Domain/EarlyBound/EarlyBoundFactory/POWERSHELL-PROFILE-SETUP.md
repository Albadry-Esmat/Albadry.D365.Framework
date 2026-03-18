# 🔧 PowerShell Profile Setup Guide

## 📋 **Overview**

The `albadry` command allows you to run EarlyBound generation from anywhere using a simple command.

---

## 🚀 **Quick Setup**

### **Option 1: Automatic Detection (Recommended)**

The function automatically searches for the script starting from your current directory.

**Just navigate to your project root and run:**
```powershell
cd C:\Users\Albadry Esmat\Desktop\Projects\Albadry.D365.Framework
albadry g earlybound -Preview
```

✅ **Works from:**
- Project root directory
- Any subdirectory within the project
- Up to 5 levels deep from project root

---

### **Option 2: Set Environment Variable (Best for Teams)**

Set the project root once, then use the command from anywhere.

#### **For Current Session:**
```powershell
$env:ALBADRY_D365_ROOT = "C:\Users\Albadry Esmat\Desktop\Projects\Albadry.D365.Framework"
```

#### **Permanent (Add to PowerShell Profile):**
```powershell
# Open your PowerShell profile
notepad $PROFILE

# Add this line:
$env:ALBADRY_D365_ROOT = "C:\Users\Albadry Esmat\Desktop\Projects\Albadry.D365.Framework"
```

#### **Helper Function:**
```powershell
# Navigate to project root
cd C:\Users\Albadry Esmat\Desktop\Projects\Albadry.D365.Framework

# Set project root
Set-AlbadryProjectRoot

# Now albadry command works from anywhere!
albadry g earlybound -Preview
```

---

## 📦 **Installation Steps**

### **Step 1: Locate Your PowerShell Profile**

```powershell
# Check if profile exists
Test-Path $PROFILE

# If False, create it:
New-Item -Path $PROFILE -Type File -Force

# Open in notepad
notepad $PROFILE
```

**Profile Location:**
```
C:\Users\YourName\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1
```

### **Step 2: Copy the Profile Content**

Copy the contents of this file:
```
src\Domain\Albadry.D365.Domain\EarlyBound\EarlyBoundFactory\Microsoft.PowerShell_profile.ps1
```

And paste into your PowerShell profile (`$PROFILE`).

### **Step 3: Reload Profile**

```powershell
# Reload profile
. $PROFILE

# Or restart PowerShell
```

### **Step 4: Verify Installation**

```powershell
# Should show welcome message
. $PROFILE

# Test command
albadry g earlybound -Preview
```

---

## 🎯 **How It Works**

### **Search Strategy**

The `albadry` function uses a multi-strategy approach:

```
1. Check environment variable: $env:ALBADRY_D365_ROOT
   ↓ (if not set)
   
2. Search from current directory
   ↓ (walk up directory tree)
   
3. Look for .git folder (project root)
   ↓
   
4. Construct path: src\Domain\Albadry.D365.Domain\EarlyBound\EarlyBoundFactory\earlybound.ps1
   ↓
   
5. Execute script ✅
```

### **Example Walkthrough**

```powershell
# You're here:
PS C:\Users\YourName\Desktop\Projects\Albadry.D365.Framework\src\Domain>

# Run command:
albadry g earlybound -Preview

# Function searches:
# 1. Current dir: C:\...\src\Domain\src\Domain\...\earlybound.ps1 ❌
# 2. Parent dir:  C:\...\src\src\Domain\...\earlybound.ps1 ❌
# 3. Parent dir:  C:\...\Albadry.D365.Framework\src\Domain\...\earlybound.ps1 ✅

# Found! Executes script
```

---

## 📍 **Directory Structure Required**

The function expects this structure:

```
YourProjectRoot/                                  ← Can be anywhere
└── src/
    └── Domain/
        └── Albadry.D365.Domain/
            └── EarlyBound/
                └── EarlyBoundFactory/
                    └── earlybound.ps1            ← Target script
```

---

## 🎮 **Usage Examples**

### **From Project Root**
```powershell
cd C:\Users\Albadry Esmat\Desktop\Projects\Albadry.D365.Framework
albadry g earlybound -Preview
```

### **From Subdirectory**
```powershell
cd C:\Users\Albadry Esmat\Desktop\Projects\Albadry.D365.Framework\src
albadry g earlybound -Preview
```

### **From Anywhere (with environment variable set)**
```powershell
cd C:\SomeOtherFolder
albadry g earlybound -Preview  # Still works!
```

### **With Parameters**
```powershell
albadry g earlybound -Entities account,contact
albadry g earlybound -Preview -OptionSets status
```

---

## 🔍 **Troubleshooting**

### **Problem: "EarlyBound script not found!"**

**Solution 1: Navigate to Project Root**
```powershell
cd C:\Users\Albadry Esmat\Desktop\Projects\Albadry.D365.Framework
albadry g earlybound -Preview
```

**Solution 2: Set Environment Variable**
```powershell
$env:ALBADRY_D365_ROOT = "C:\Users\Albadry Esmat\Desktop\Projects\Albadry.D365.Framework"
albadry g earlybound -Preview
```

**Solution 3: Run Script Directly**
```powershell
.\src\Domain\Albadry.D365.Domain\EarlyBound\EarlyBoundFactory\earlybound.ps1 -Preview
```

---

### **Problem: "albadry: command not found"**

**Solution: Profile Not Loaded**
```powershell
# Reload profile
. $PROFILE

# Or check if profile exists
Test-Path $PROFILE

# Create if needed
New-Item -Path $PROFILE -Type File -Force
```

---

## 🎓 **Advanced: Team Setup**

For teams, add to a shared team profile or setup script:

### **team-setup.ps1**
```powershell
# Team Setup Script
# Run this once to configure PowerShell for Albadry D365 Framework

# Detect project root (current directory)
$projectRoot = Get-Location

# Set environment variable
$env:ALBADRY_D365_ROOT = $projectRoot

# Add to profile if not already there
$profileContent = Get-Content $PROFILE -ErrorAction SilentlyContinue
$envLine = "`$env:ALBADRY_D365_ROOT = '$projectRoot'"

if ($profileContent -notcontains $envLine) {
    Add-Content -Path $PROFILE -Value $envLine
    Write-Host "✅ Added project root to PowerShell profile" -ForegroundColor Green
}

# Source the Albadry functions
$functionsFile = Join-Path $projectRoot "src\Domain\Albadry.D365.Domain\EarlyBound\EarlyBoundFactory\Microsoft.PowerShell_profile.ps1"
. $functionsFile

Write-Host "✅ Setup complete! Run 'albadry g earlybound -Preview' to test." -ForegroundColor Green
```

**Usage:**
```powershell
cd C:\Projects\Albadry.D365.Framework
.\team-setup.ps1
```

---

## 📚 **Reference**

### **Available Commands**

| Command | Description |
|---------|-------------|
| `albadry g earlybound` | Generate EarlyBound classes |
| `albadry g earlybound -Preview` | Preview generation (no changes) |
| `Set-AlbadryProjectRoot` | Set project root for current session |
| `Set-AlbadryProjectRoot "C:\Path"` | Set specific path as project root |

### **Environment Variables**

| Variable | Description | Example |
|----------|-------------|---------|
| `$env:ALBADRY_D365_ROOT` | Project root directory | `C:\Projects\Albadry.D365.Framework` |
| `$PROFILE` | PowerShell profile location | `C:\Users\...\Microsoft.PowerShell_profile.ps1` |

---

## ✅ **Verification Checklist**

- [ ] PowerShell profile created (`$PROFILE`)
- [ ] Albadry functions added to profile
- [ ] Profile reloaded (`. $PROFILE`)
- [ ] Welcome message displays on profile load
- [ ] `albadry g earlybound -Preview` works from project root
- [ ] (Optional) `$env:ALBADRY_D365_ROOT` set for any-directory usage

---

## 🎉 **Success!**

Once setup, you can run:

```powershell
# From anywhere in your project
albadry g earlybound -Preview

# Or from absolutely anywhere (with env var set)
cd C:\Windows
albadry g earlybound -Preview  # Still works! 🚀
```

---

**Status:** Ready for team use!  
**Portability:** ✅ Works on any machine  
**Team-friendly:** ✅ Easy setup for new developers
