# 🛡️ Windows Hardening Toolkit

Security-focused PowerShell toolkit designed to harden Windows systems, reduce attack surfaces, and provide real-time network monitoring with configurable alerts, logging, and process whitelisting.

---

# 🚀 Features

## 🔐 Security Hardening

➜ Enables Windows Firewall across all profiles

➜ Applies secure inbound and outbound firewall policies

➜ Disables Universal Plug and Play (UPnP)

➜ Preserves browser connectivity through explicit allow rules

➜ Reduces common Windows attack surfaces

---

## 🌐 Network Monitoring

➜ Monitors active TCP connections

➜ Detects newly opened ports

➜ Tracks listening and established connections

➜ Supports process whitelisting

➜ Supports trusted IP exclusions

➜ Continuously monitors network activity

---

## 🚨 Alerting & Detection

➜ Real-time security notifications

➜ High-risk port monitoring

➜ Suspicious process detection

➜ Connection risk classification

➜ Automatic event logging

---

## 📋 Logging

➜ Timestamped activity logs

➜ Historical event tracking

➜ Automatic log generation

➜ Organized log storage

➜ Security event auditing

---

# 💻 Requirements

### Supported Operating Systems

✅ Windows 10

✅ Windows 11

### Required Software

✅ PowerShell 5.1 or newer

✅ Administrator privileges

---

# 🚀 Quick Start

## Step 1

Create:

```text
C:\Update Code
```

---

## Step 2

Place the following files inside:

```text
System-Hardening-NetworkMonitor-v6.ps1
monitor-config.json
```

Result:

```text
C:\Update Code
│
├── System-Hardening-NetworkMonitor-v6.ps1
└── monitor-config.json
```

---

## Step 3

Open PowerShell as Administrator.

---

## Step 4

Navigate to the directory:

```powershell
cd "C:\Update Code"
```

---

## Step 5

If the script was downloaded from the internet:

```powershell
Unblock-File .\System-Hardening-NetworkMonitor-v6.ps1
```

---

## Step 6

Launch the toolkit:

```powershell
.\System-Hardening-NetworkMonitor-v6.ps1
```

Or run everything at once:

```powershell
cd "C:\Update Code"; Unblock-File .\System-Hardening-NetworkMonitor-v6.ps1; .\System-Hardening-NetworkMonitor-v6.ps1
```

---

# ⚙️ Configuration

The toolkit uses:

```text
monitor-config.json
```

Supported configuration options:

### Process Whitelist

Trusted processes that should not generate alerts.

Examples:

➜ Chrome

➜ Edge

➜ OBS Studio

➜ Windows System Processes

---

### Ignored IP Addresses

Trusted addresses excluded from monitoring.

Examples:

➜ 127.0.0.1

➜ ::1

➜ Internal infrastructure

---

### High-Risk Ports

Ports that automatically trigger elevated monitoring and alerting.

Examples:

➜ 4444

➜ 5555

➜ 6666

➜ Custom administrative ports

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
| MEDIUM | Established or suspicious connections                                |
| HIGH   | Listening ports, suspicious processes, or configured high-risk ports |

---

# 🚨 Alert Conditions

The toolkit generates alerts when:

➜ High-risk ports are detected

➜ Suspicious process names are identified

➜ New listening ports appear

➜ Unexpected network activity is observed

➜ Configured monitoring thresholds are exceeded

---

# 📂 Generated Folders

The toolkit automatically creates:

```text
C:\Update Code\Logs
C:\Update Code\Backup
```

These folders are used for activity logging and future data storage.

---

# 📋 Log Location

Security logs are stored in:

```text
C:\Update Code\Logs
```

Logged information includes:

➜ Connection activity

➜ Risk classifications

➜ Alert events

➜ Monitoring status

➜ Security notifications

---

# ⚠️ Important Notes

❌ Do not disable Windows Firewall while using this toolkit

❌ Do not whitelist unknown applications

❌ Do not remove required Windows networking services

❌ Review configuration settings before deployment

❌ Test security changes in a non-production environment when possible

---

# 🏗️ Project Purpose

Windows Hardening Toolkit was developed as a practical Windows administration and security project demonstrating:

➜ PowerShell Automation

➜ Windows Security Management

➜ Firewall Administration

➜ Network Activity Analysis

➜ Process Monitoring

➜ Configuration Management

➜ Event Logging

➜ Security Alerting

The project emphasizes lightweight security automation using native Windows technologies and PowerShell capabilities.

---

# 👨‍💻 Author

**TCDOverLord**

GitHub:
https://github.com/tcdoverlord

---

# ⚠️ Disclaimer

This project is intended for educational, defensive security, and system administration purposes. Review all security settings before deployment and test thoroughly in your own environment.
