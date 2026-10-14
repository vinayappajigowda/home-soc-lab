# Applies the CIS-aligned hardening used in this lab.
# Run in an elevated PowerShell on the LAB VM only. Take a VM snapshot first.

# --- Password policy and account lockout ---
net accounts /minpwlen:14 /uniquepw:24 /minpwage:1 /maxpwage:365
net accounts /lockoutthreshold:5 /lockoutduration:15 /lockoutwindow:15

# --- Audit policy ---
# Use the advanced audit subcategories instead of the legacy categories
reg add HKLM\SYSTEM\CurrentControlSet\Control\Lsa /v SCENoApplyLegacyAuditPolicy /t REG_DWORD /d 1 /f

auditpol /set /subcategory:"Credential Validation"     /success:enable /failure:enable
auditpol /set /subcategory:"Logon"                     /success:enable /failure:enable
auditpol /set /subcategory:"Logoff"                    /success:enable
auditpol /set /subcategory:"Account Lockout"           /failure:enable
auditpol /set /subcategory:"Special Logon"             /success:enable
auditpol /set /subcategory:"User Account Management"   /success:enable /failure:enable
auditpol /set /subcategory:"Security Group Management" /success:enable
auditpol /set /subcategory:"Process Creation"          /success:enable

# --- Show the result ---
net accounts
auditpol /get /category:"Logon/Logoff","Account Management","Account Logon","Detailed Tracking"

# --- Restart the Wazuh agent so SCA rescans ---
NET STOP Wazuh
NET START Wazuh
