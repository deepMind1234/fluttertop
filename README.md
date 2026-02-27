# FlutterTop 🚀

[![Platform](https://img.shields.io/badge/platform-linux-blue.svg)](https://flutter.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

**FlutterTop** is a visually stunning, modern Linux system monitoring dashboard built with Flutter. It provides real-time insights into your system's performance with beautiful animations and a clean, intuitive interface.

![FlutterTop Logo](snap/gui/fluttertop.png)

## ✨ Features

- **CPU Monitoring**: Detailed per-core heatmaps and overall usage history.
- **Memory & Swap**: Visualized usage stats for physical RAM and swap space.
- **Disk & Storage**: Real-time I/O tracking and storage capacity pie charts.
- **GPU Stats**: Dedicated metrics for AMD and NVIDIA hardware.
- **Network I/O**: Live upload and download speeds per interface.
- **Process Management**: Deep profiling of individual processes, including hardware events (page faults) and software events (context switches).

## 📦 Installation

### Install via Snap (Recommended)

FlutterTop is packaged as a Snap for easy installation on most Linux distributions:

```bash
# Once published to the store:
sudo snap install fluttertop

# To install the local build (experimental):
sudo snap install fluttertop_*.snap --dangerous
```

### Build from Source

Ensure you have [Flutter installed](https://docs.flutter.dev/get-started/install/linux).

1. Clone the repository:
   ```bash
   git clone https://github.com/deepMind1234/fluttertop.git
   cd fluttertop
   ```

2. Get dependencies:
   ```bash
   flutter pub get
   ```

3. Run the application:
   ```bash
   flutter run -d linux
   ```

## 🛠 Development

### Snapcraft Build
To package the application as a snap locally:
```bash
snapcraft pack
```

### Static Analysis
Keep the codebase clean by running:
```bash
flutter analyze
```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---
Created with ❤️ by **[soulful](https://github.com/deepMind1234)**
