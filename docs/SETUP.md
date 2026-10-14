# Build guide

Hardware used: a Windows laptop with 16 GB RAM and about 60 GB of free disk space. Run only the VMs you need at any one time.

## 1. Wazuh SIEM

1. Download the Wazuh OVA from the official docs (*Installation alternatives → Virtual machine (OVA)*).
2. In VirtualBox, click **File → Import Appliance**.
3. Before first boot, change these settings:
   - **System:** 4096 MB RAM, 2 CPUs (the OVA defaults to 8 GB / 4 CPUs).
   - **Display:** Graphics Controller set to **VMSVGA**.
   - **Network:** Adapter 1 set to **Host-only Adapter**. The OVA defaults to *Bridged*, which would expose the SIEM on your real network.
4. Boot the VM and log in at the console with `wazuh-user` / `wazuh`. Run `ip a` to find its address (here, `192.168.56.104`).
5. Browse to `https://192.168.56.104` and log in. Change the default dashboard password for anything beyond a throwaway lab.

## 2. Windows 11 endpoint

1. Download the **Windows 11 Enterprise** evaluation ISO (90 days) from the Microsoft Evaluation Center.
2. Create a new VM with 4096 MB RAM, 2 CPUs, a 64 GB dynamically allocated disk, EFI enabled, and the unattended install skipped.
3. Set up the network adapters:
   - **Adapter 1:** NAT (internet for downloads).
   - **Adapter 2:** Host-only (to reach Wazuh).
4. Install Windows. Use **Sign-in options → Domain join instead** to create a local account.
5. Install Guest Additions (**Devices → Insert Guest Additions CD image**, then run `VBoxWindowsAdditions.exe`) and set **Shared Clipboard → Bidirectional**.
6. Take a snapshot.

## 3. Sysmon

Run these in elevated PowerShell:

```powershell
New-Item -ItemType Directory -Path C:\Tools\Sysmon -Force
cd C:\Tools\Sysmon
Invoke-WebRequest https://download.sysinternals.com/files/Sysmon.zip -OutFile Sysmon.zip
Expand-Archive Sysmon.zip -DestinationPath . -Force
Invoke-WebRequest https://raw.githubusercontent.com/SwiftOnSecurity/sysmon-config/master/sysmonconfig-export.xml -OutFile sysmonconfig-export.xml
.\Sysmon64.exe -accepteula -i sysmonconfig-export.xml
Get-Service Sysmon64
```

To check it's working, open Event Viewer and go to **Applications and Services Logs → Microsoft → Windows → Sysmon → Operational**.

## 4. Wazuh agent

1. In the dashboard, click **Deploy new agent** and choose Windows MSI, server `192.168.56.104`, name `WIN11-LAB`.
2. Run the generated PowerShell command in elevated PowerShell **inside the VM**, then run `NET START Wazuh`.
3. Check the agent shows **active** under **Agents management → Summary**.

## 5. Extra log sources

1. Append [`config/agent-localfile.xml`](../config/agent-localfile.xml) to `C:\Program Files (x86)\ossec-agent\ossec.conf`.
2. Enable PowerShell script block logging:

```powershell
New-Item "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging" -Force
Set-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging" -Name EnableScriptBlockLogging -Value 1
NET STOP Wazuh
NET START Wazuh
```

3. Check the agent is reading the new sources:

```powershell
Select-String -Path "C:\Program Files (x86)\ossec-agent\ossec.log" -Pattern "Analyzing event log" | Select-Object -Last 5
```

## 6. CIS assessment and hardening

1. Open **Endpoint security → Configuration Assessment** and select the agent. Record the score, then click **Export formatted**.
2. Take a snapshot, then run [`scripts/harden.ps1`](../scripts/harden.ps1).
3. Once the agent restarts, SCA rescans. Refresh the page, check the scan time has changed, and record the new score.
