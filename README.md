# PowerShell Network Hardening Bootstrap

<p align="center">
  <img src="assets/architecture.png" alt="PowerShell Network Hardening Bootstrap Architecture" />
</p>

<p align="center">
  <img src="https://img.shields.io/badge/PowerShell-Bootstrap-blue?style=for-the-badge&logo=powershell" />
  <img src="https://img.shields.io/badge/Windows-Network%20Hardening-0078D6?style=for-the-badge&logo=windows" />
  <img src="https://img.shields.io/badge/System-Unpacker-orange?style=for-the-badge" />
  <img src="https://img.shields.io/badge/Status-Safety--First-green?style=for-the-badge" />
</p>

---

# Important Concept

PowerShell Network Hardening Bootstrap is a bootloader / unpacker engine. You run one setup script, choose where to install, and it unpacks the complete Windows network monitoring and hardening runtime.

The bootloader is for installation. The generated runtime folder is for daily use.

---

# Only Entry File

```powershell
.\PowerShell_Network_Hardening_Bootstrap_Setup.ps1
```

The bootloader:

- Asks where to install the toolkit.
- Blocks unsafe Windows system install locations.
- Unpacks the complete runtime payload.
- Creates `Logs\` and `Backup\`.
- Validates generated PowerShell and JSON files.
- Prints the launch command when complete.

---

# Generated System

Default install path:

```text
C:\PowerShell-Network-Hardening-Bootstrap\
|-- Launch-Toolkit.bat
|-- Start-ToolkitMenu.ps1
|-- Bootstrap-WindowsHardeningToolkit.ps1
|-- Start-WindowsHardeningToolkit.ps1
|-- Restore-WindowsHardeningToolkit.ps1
|-- monitor-config.json
|-- README.md
|-- LICENSE
|-- Backup\
`-- Logs\
```

---

# Installation

Open PowerShell:

```powershell
cd <REPO_FOLDER>
.\PowerShell_Network_Hardening_Bootstrap_Setup.ps1
```

Follow the prompt to choose the install folder.

---

# Daily Operation

Double-click in the generated folder:

```text
Launch-Toolkit.bat
```

Or open PowerShell as Administrator:

```powershell
cd C:\PowerShell-Network-Hardening-Bootstrap
.\Start-ToolkitMenu.ps1
```

That opens the runtime menu:

```text
1. Start monitor-only mode
2. Preview safe hardening changes
3. Apply safe firewall baseline
4. Restore latest backup
5. Open logs folder
6. Run safety check
7. Exit
```

---

# Safety Layer

- Monitor-only is the default behavior.
- Hardening is opt-in from the menu.
- No UPnP/service-disabling actions are included.
- No force override exists.
- Hardening stops when VM, WSL, Docker, VPN-style adapters, or virtual networking indicators are detected.
- Runtime monitoring exits if a VM, WSL, or Docker workload starts.
- Restore points are created before firewall changes.

---

# Status

Safety-first bootstrap system.

---

# Author

TCDOverLord
