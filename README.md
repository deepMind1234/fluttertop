# FlutterTop 🚀

[![Platform](https://img.shields.io/badge/platform-linux-blue.svg)](https://flutter.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

**FlutterTop** is a modern Linux system monitoring dashboard built with Flutter. It provides real-time system insights through a clean and unified interface. It is based on the linux system monitor and other common resource monitors but tries to create an unified interface that is customizable with open code.

![FlutterTop Logo](snap/gui/fluttertop.png)

## 📖 Motivation

I built FlutterTop after diving into the Snap ecosystem and Linux app development during the Canonical interview process. I wanted to create a project that would help solidify some of the practicial knowledge that I had gained as well as be project that I could reference as a body work. I initially spent my time looking through the helpful flutter and dart documentaion in the official website and then building small script using prexisting components before graduating to scripting and project design.

Why I choose to create **another** resource monitor. I was tired of using multiple terminal and GUI resource monitors at the same time. The fragmented experience left much to be desired, and running multiple monitors caused unnecessary resource contention. I wanted to create a single, unified dashboard that brings all essential system metrics together.

## 🏗️ Architecture

The project follows a Clean Architecture approach with three main layers to separate the UI from low-level Linux system parsing:

![Architecture Mermaid Graph](mermaid_graph.png)

1. **Presentation**: UI, animations, and state visualization.
2. **Domain**: Core business logic, models, and data streams.
3. **Data**: Async parsing of the `/proc` and `/sys` file systems.

## ✨ Features

- **CPU**: Per-core heatmaps and usage history.
- **Memory**: Usage stats for RAM and swap space.
- **Disk**: Real-time I/O tracking and storage capacity.
- **GPU**: Metrics for AMD and NVIDIA hardware.
- **Network**: Live upload and download speeds.
- **Processes**: Process profiling, including hardware and software events.

## 📦 Installation

### Install via Snap (Recommended)

FlutterTop is packaged as a Snap for easy installation:

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
