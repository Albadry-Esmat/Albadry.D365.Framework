# ⚠️ PAC CLI OptionSet Limitation

## 🎯 **The Issue**

You specified 3 optionsets in your configuration:
```json
"optionSets": [
  "msdyn_flow_approval_priority",
  "powerpagelanguages", 
  "fullsyncstate"
]
```

But 100 optionset files were generated instead of 3.

## 🔍 **Why This Happened**

**PAC CLI does NOT support filtering optionsets!**

### Available PAC CLI Filters:
| Parameter | Supports Filtering? | Example |
|-----------|---------------------|---------|
| `--entitynamesfilter` | ✅ YES | `account;contact;invoice` |
| `--messagenamesfilter` | ✅ YES | `myAction;otherAction` |
| `--optionsetnamesfilter` | ❌ **DOES NOT EXIST** | N/A |
| `--generateGlobalOptionSets` | ⚠️ All or Nothing | Boolean flag |

### What Actually Happens:

```powershell
# What you WANT (doesn't exist):
pac modelbuilder build --optionsetnamesfilter "option1;option2;option3"  ❌

# What PAC CLI ACTUALLY supports:
pac modelbuilder build --generateGlobalOptionSets  # Generates ALL ~100 optionsets ✅
```

## 📊 **Your Options**

### **Option 1: Generate ALL OptionSets** (Current)
```json
"optionSets": ["anything"]  // Any non-empty array = ALL optionsets
```
**Result:** ~100 optionset files generated

---

### **Option 2: Don't Generate OptionSets**
```json
"optionSets": []  // Empty array = skip optionsets
```
**Result:** 0 optionset files

---

### **Option 3: Post-Process Deletion** (Manual)
Generate all, then manually delete the ones you don't need:
```powershell
# After generation
Remove-Item "EarlyBoundClasses\OptionSets\*" -Exclude "msdyn_flow_approval_priority.cs","powerpagelanguages.cs","fullsyncstate.cs"
```

## ✅ **Recommendation**

### For Most Projects:
```json
"optionSets": []  // Don't generate - define enums manually as needed
```

**Why?**
- ✅ Cleaner code (only what you need)
- ✅ Faster builds (less files to compile)
- ✅ Better control (know exactly what's in your project)
- ✅ Manual enums are often more readable

### If You Need Many OptionSets:
```json
"optionSets": ["any_value_here"]  // Generates ALL ~100
```

Then commit all to source control and update as needed.

## 📝 **Updated Configuration**

Your config now shows this clearly:

```json
{
  "filters": {
    "entities": ["account", "contact", "activitypointer"],
    "actions": ["adx_AzureBlobStorageUrl"],
    "optionSets": []  // Empty = don't generate
  },

  "_comments": {
    "optionSets": "IMPORTANT: PAC CLI does NOT support filtering optionsets! 
                   If this array has ANY items, ALL global optionsets (~100 files) 
                   will be generated. Set to empty array [] to skip optionset 
                   generation entirely."
  }
}
```

## 🎓 **Why Doesn't PAC Support OptionSet Filtering?**

Microsoft's design decision - optionsets are:
1. **Small files** - each optionset is typically 10-50 lines
2. **Interdependent** - entities reference optionsets
3. **Global** - shared across multiple entities

So they made it "all or nothing" to keep it simple.

## ✅ **Next Steps**

1. **Decide:** Do you need optionsets?
   - **Yes, many** → Keep config as-is (generates all 100)
   - **No / only a few** → Set `"optionSets": []` and create manual enums

2. **Regenerate:**
   ```powershell
   .\earlybound.ps1
   ```

3. **Verify:**
   ```powershell
   Get-ChildItem "EarlyBoundClasses\OptionSets" -Filter *.cs | Measure-Object
   ```

---

**Summary:** This is a PAC CLI limitation, not a bug in your script. You must choose ALL or NOTHING for optionsets.
