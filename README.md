# 🛡️ Windows Hardening Toolkit

PowerShell-based Windows security hardening and real-time network monitoring toolkit designed to improve system security, reduce attack surfaces, and provide visibility into active network activity.

---

## 🚀 Features

### 🔐 Security Hardening

* Enables Windows Firewall across all profiles
* Applies secure inbound and outbound firewall rules
* Disables Universal Plug and Play (UPnP)
* Preserves browser connectivity through explicit allow rules
* Reduces common attack surfaces

### 🌐 Network Monitoring

* Monitors active TCP connections
* Detects newly opened ports
* Tracks listening and established connections
* Supports configurable process whitelisting
* Supports trusted IP exclusions

### 🚨 Alerting & Detection

* Real-time security notifications
* High-risk port monitoring
* Suspicious process detection
* Connection risk classification

### 📋 Logging

* Timestamped event logging
* Automatic log generation
* Historical activity tracking
* Organized log storage

---

## 💻 Requirements

* Windows 10 or Windows 11
* PowerShell 5.1 or newer
* Administrator privileges

---

## 📦 Installation

Create the following folder:

```text
C:\Update Code
```

Place the following files inside:

```text
System-Hardening-NetworkMonitor-v6.ps1
monitor-config.json
```

---

## ▶️ Running the Toolkit

Open PowerShell as Administrator and run:

```powershell
cd "C:\Update Code"
Unblock-File .\System-Hardening-NetworkMonitor-v6.ps1
.\System-Hardening-NetworkMonitor-v6.ps1
```

Or run everything in a single command:

```powershell
cd "C:\Update Code"; Unblock-File .\System-Hardening-NetworkMonitor-v6.ps1; .\System-Hardening-NetworkMonitor-v6.ps1
```

---

## ⚙️ Configuration

The toolkit uses:

```text
monitor-config.json
```

Configuration options include:

* Process Whitelist
* Ignored IP Addresses
* High-Risk Ports
* Monitoring Exclusions

Example trusted applications:

* Google Chrome
* Microsoft Edge
* Mozilla Firefox
* OBS Studio
* Core Windows Processes

---

## 📂 Log Location

Logs are automatically stored in:

```text
C:\Update Code\Logs
```

---

## 🧠 Risk Classification

| Level  | Description                                                          |
| ------ | -------------------------------------------------------------------- |
| LOW    | Normal network activity                                              |
| MEDIUM | Established or suspicious connections                                |
| HIGH   | Listening ports, suspicious processes, or configured high-risk ports |

---

## 🏗️ Project Purpose

Windows Hardening Toolkit was developed as a practical Windows administration and security project demonstrating:

* PowerShell Automation
* Windows Security Management
* Firewall Administration
* Network Activity Analysis
* Process Monitoring
* Configuration Management
* Event Logging
* Security Alerting

The project focuses on lightweight security automation using native Windows tools and PowerShell capabilities.

---

## 👨‍💻 Author

**TCDOverLord**

GitHub:
https://github.com/tcdoverlord

---

## ⚠️ Disclaimer

This project is intended for educational, defensive security, and system administration purposes. Review all security settings before deployment and test thoroughly in your own environment.
