# 🚀 WimBuilder - Advanced Windows Imaging Tool

[![Windows](https://img.shields.io/badge/Windows-10%20%7C%2011-blue.svg)](https://www.microsoft.com/windows)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Status](https://img.shields.io/badge/Status-Work%20in%20Progress-orange.svg)](https://github.com/yourusername/WimBuilder)

**WimBuilder** is a powerful Windows Imaging (.wim) customization tool that enables advanced editing, feature removal, AppX package injection, and multi-index merging into a single WIM file. Equipped with privilege detection, registry tweaks, and cleanup modules, WimBuilder streamlines the creation of optimized Windows images with minimal user interaction.

<img width="731" height="328" alt="image" src="https://github.com/user-attachments/assets/a5407dac-fa2c-46f6-b515-2c4574b45eca" />

## ✨ Features

### 🔧 Core Functionality
- **WIM Builder** - Create optimized Windows 10/11 images (Standard & LTSC)
- **WIM Merge Tool** - Combine multiple WIM indices into single file
- **WIM Index Deletion** - Remove unwanted indices from WIM files
- **WIM Info Editor** - View and edit WIM file metadata
- **Mount Directory Manager** - Check and manage mounted WIM directories

### 🛡️ Safety & Reliability
- **Automatic Backup System** - Optional backup creation before modifications
- **Privilege Detection** - Auto-elevation to Administrator privileges
- **Error Recovery** - Comprehensive error handling and rollback capabilities
- **Registry Cleanup** - Automatic cleanup of registry hives after operations

### 🎯 Optimization Features
- **Feature Debloating** - Remove unnecessary Windows features
- **AppX Package Management** - Inject or remove AppX packages
- **Registry Tweaks** - Apply performance and customization tweaks
- **Multi-Version Support** - Windows 10/11 Standard and LTSC editions

### 📦 Package Management
- **Shared Dependencies** - Common AppX dependencies for all versions
- **Version-Specific Packages** - Separate packages for Consumer and LTSC editions
- **Automatic Detection** - Smart package scanning and validation

## 🚀 Quick Start

### Prerequisites
- Windows 10/11 (Administrator privileges required)
- [WimLib](https://wimlib.net/) (included in packages folder)
- Windows WIM file (install.wim from Windows ISO)

### Installation
1. **Clone or Download** this repository
2. **Extract** to a folder of your choice
3. **Run as Administrator** - `WimBuilder_Launcher.cmd`

### Basic Usage
```batch
# Run the launcher
WimBuilder_Launcher.cmd

# Select option 1 for WIM Builder
# Choose your Windows version (10/11, Standard/LTSC)
# Follow the step-by-step wizard
```

## 🎮 Usage Guide

### 1. WIM Builder
The main feature for creating optimized Windows images:

1. **Select Windows Version**
   - Windows 10/11 Standard or LTSC
   - Automatic package selection based on version

2. **Choose WIM File**
   - Browse available WIM files in Image_Kitchen folder
   - Select specific index/edition

3. **Backup Options**
   - Optional automatic backup creation
   - Timestamped backup files for safety

4. **AppX Package Injection**
   - Automatic dependency scanning
   - Version-specific package injection
   - Skip option for Consumer editions

5. **Processing**
   - Feature removal and optimization
   - Registry tweaks application
   - Safe mount/unmount operations

### 2. WIM Merge Tool
Combine multiple WIM indices into a single file:
- Select source WIM file
- Choose indices to merge
- Specify output filename
- Automatic compression and optimization

### 3. WIM Index Deletion
Remove unwanted indices from WIM files:
- View all indices in WIM file
- Select indices for deletion
- Safe deletion with validation

### 4. Mount Directory Manager
Check and manage mounted WIM directories:
- List all mounted directories
- Commit or discard changes
- Force cleanup if needed

## 🔧 Advanced Configuration

### Custom AppX Packages
Add your own AppX packages to the appropriate folders:
- `App_LTSC/Consumer_W10/` - Windows 10 Consumer apps
- `App_LTSC/Consumer_W11/` - Windows 11 Consumer apps
- `App_LTSC/LTSC_W10/` - Windows 10 LTSC apps
- `App_LTSC/LTSC_W11/` - Windows 11 LTSC apps

### Registry Tweaks
Modify `ScriptModules/BuilderModule/Registry_Tweaks.cmd` to add custom registry modifications.

### Feature Removal
Edit `ScriptModules/BuilderModule/Features_Debloater.cmd` to customize which Windows features are removed.

## 🛠️ Troubleshooting

### Common Issues

**"WimLib not found"**
- Ensure WimLib is in `packages/WimLib/` directory
- Download from [wimlib.net](https://wimlib.net/) if missing

**"Mount operation failed"**
- Run as Administrator
- Ensure sufficient disk space (10GB+ recommended)
- Check if mount directory is in use
- Try restarting computer to clear locks

**"AppX injection failed"**
- Ensure Depedencies are correct
- Verify AppX package integrity
- Check package compatibility with Windows version
- Ensure packages are in correct directory

### Error Codes
- **Error -1052638937**: Mount directory in use, cleanup required
- **Error 0x80070002**: File not found, check paths
- **Error 0x80070005**: Access denied, run as Administrator

## 🤝 Contributing

We welcome contributions! Please feel free to:

1. **Fork** the repository
2. **Create** a feature branch
3. **Make** your changes
4. **Test** thoroughly
5. **Submit** a pull request

### Development Guidelines
- Follow existing code style
- Add proper error handling
- Include documentation
- Test on multiple Windows versions

## 📚 References

- [Tiny11 Builder by NTDEV](https://github.com/ntdevlabs/tiny11builder)  
- [Tiny11 24H2 by chrisGrando](https://github.com/chrisGrando/tiny11builder-24H2)
- [WimLib Documentation](https://wimlib.net/)
- [DISM Command-Line Options](https://docs.microsoft.com/en-us/windows-hardware/manufacture/desktop/dism-command-line-options)

## 🔧 Key Differences from Tiny11 Builder

- **WIM-Only Focus**: My script **only edits the WIM file**  
- **No ISO Creation**: Does **not** include ISO creation (yet)  
- **Modular Design**: Separate modules for different operations
- **Enhanced Safety**: Automatic backup and error recovery
- **Multi-Version Support**: Windows 10/11 Standard and LTSC
- **Future Plans**: ISO builder integration like TinyBuilder

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## ⚠️ Disclaimer

This tool modifies Windows system files. Use at your own risk. Always create backups before making modifications. The authors are not responsible for any data loss or system issues.

---

**Made with ❤️ for the Windows customization community** 
