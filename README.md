<p align="center">
  <img src="https://img.shields.io/badge/PowerShell-Security-blue?style=for-the-badge&logo=powershell" />
  <img src="https://img.shields.io/badge/Windows-10%2F11-0078D6?style=for-the-badge&logo=windows" />
  <img src="https://img.shields.io/badge/Network-Monitoring-green?style=for-the-badge&logo=icloud" />
  <img src="https://img.shields.io/badge/Firewall-Hardening-orange?style=for-the-badge&logo=windows-defender" />
  <img src="https://img.shields.io/badge/Status-Stable-brightgreen?style=for-the-badge" />
</p>

# 🛡️ Windows Hardening Toolkit

A security-focused PowerShell toolkit designed to harden Windows systems, reduce attack surfaces, and provide continuous network monitoring with configurable alerts, logging, and process whitelisting.

---

## 🎬 Demo

<p align="center">
  <img src="windows-hardening-toolkit-demo.gif" alt="Windows Hardening Toolkit Demo" />
</p>

---

# 🧠 Overview

Windows Hardening Toolkit combines system hardening and network monitoring into a single automation solution.

The toolkit establishes a secure baseline configuration, monitors network activity in real time, classifies connection risk, and generates alerts when suspicious activity is detected.

### Security Objectives

* Reduce common Windows attack surfaces
* Enforce firewall protection
* Monitor active network connections
* Detect potentially suspicious activity
* Generate security-focused logging and alerts
* Provide lightweight defensive monitoring

---

# ✨ Features

## 🔐 Security Hardening

* Enables Windows Firewall across all profiles
* Applies secure inbound and outbound firewall policies
* Disables Universal Plug and Play (UPnP)
* Preserves browser connectivity through allow rules
* Reduces common Windows attack surfaces

## 🌐 Network Monitoring

* Monitors active TCP connections
* Detects newly opened ports
* Tracks listening and established connections
* Supports process whitelisting
* Supports trusted IP exclusions
* Continuously monitors network activity

## 🚨 Alerting & Detection

* Real-time security notifications
* High-risk port monitoring
* Suspicious process detection
* Connection risk classification
* Automatic event logging

## 📋 Logging

* Timestamped activity logs
* Historical event tracking
* Organized log storage
* Security event auditing
* Automatic log generation

---

# 💻 Requirements

## Supported Operating Systems

* Windows 10
* Windows 11

## Required Software

* PowerShell 5.1 or newer
* Administrator privileges

---

# 🚀 Quick Start

## 1. Create Working Directory

```text
C:\Update Code
```

## 2. Add Required Files

```text
C:\Update Code
│
├── System-Hardening-NetworkMonitor-v6.ps1
└── monitor-config.json
```

## 3. Open PowerShell as Administrator

## 4. Navigate to Directory

```powershell
cd "C:\Update Code"
```

## 5. Unblock Script (if downloaded)

```powershell
Unblock-File .\System-Hardening-NetworkMonitor-v6.ps1
```

## 6. Launch Toolkit

```powershell
.\System-Hardening-NetworkMonitor-v6.ps1
```

Or:

```powershell
cd "C:\Update Code"; Unblock-File .\System-Hardening-NetworkMonitor-v6.ps1; .\System-Hardening-NetworkMonitor-v6.ps1
```

---

# ⚙️ Configuration

The toolkit uses:

```text
monitor-config.json
```

### Process Whitelist

Trusted processes excluded from alert generation.

Examples:

* Chrome
* Microsoft Edge
* OBS Studio
* Windows System Processes

### Ignored IP Addresses

Trusted IP addresses excluded from monitoring.

Examples:

* 127.0.0.1
* ::1
* Internal infrastructure addresses

### High-Risk Ports

Ports that trigger elevated monitoring.

Examples:

* 4444
* 5555
* 6666
* Custom administrative ports

---

# 🔄 Monitoring Workflow

```text
START
  ↓
Load Configuration
  ↓
Apply Firewall Baseline
  ↓
Disable UPnP
  ↓
Capture Initial Network State
  ↓
Create Connection Baseline
  ↓
Monitor Network Activity
  ↓
Classify Connection Risk
  ↓
Generate Alerts
  ↓
Write Security Logs
  ↓
CONTINUOUS MONITORING
```

---

# 🧠 Risk Classification

| Level  | Description                                                          |
| ------ | -------------------------------------------------------------------- |
| LOW    | Normal network activity                                              |
| MEDIUM | Suspicious or unexpected activity                                    |
| HIGH   | Listening ports, suspicious processes, or configured high-risk ports |

---

# 🚨 Alert Conditions

Alerts are generated when:

* High-risk ports are detected
* Suspicious process names are identified
* New listening ports appear
* Unexpected network activity is observed
* Configured monitoring thresholds are exceeded

---

# 📂 Generated Directories

```text
C:\Update Code\Logs
C:\Update Code\Backup
```

These directories are automatically created during operation.

---

# 📋 Log Storage

Security logs are stored in:

```text
C:\Update Code\Logs
```

Logged information includes:

* Connection activity
* Risk classifications
* Alert events
* Monitoring status
* Security notifications

---

# ⚠️ Important Notes

* Do not disable Windows Firewall while using the toolkit
* Do not whitelist unknown applications
* Do not remove required networking services
* Review configuration settings before deployment
* Test changes in a non-production environment when possible

---

# 🎯 Project Goals

Windows Hardening Toolkit was developed to demonstrate:

* PowerShell Automation
* Windows Security Administration
* Firewall Management
* Network Activity Analysis
* Process Monitoring
* Configuration Management
* Event Logging
* Security Alerting

The project emphasizes lightweight security automation using native Windows technologies and PowerShell.

---

# 👨‍💻 Author

**TCDOverLord**

GitHub: https://github.com/tcdoverlord

---

# ⚠️ Disclaimer

This project is intended for educational, defensive security, and system administration purposes. Review all security settings before deployment and test thoroughly in your own environment.
