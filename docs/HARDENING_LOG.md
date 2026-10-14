# Hardening log: WIN11-LAB

**Endpoint:** Windows 11 Enterprise Evaluation (build 26100), VirtualBox
**Assessment:** Wazuh SCA, CIS Microsoft Windows 11 Enterprise Benchmark v3.0.0 (482 checks)
**Date:** 14 October 2026

## Baseline

| Passed | Failed | Not applicable | Score | Scan time |
|---|---|---|---|---|
| 123 | 350 | 9 | 26% | 15:35 |

Before making changes I exported the results (`sca_before.csv`) and took a VM snapshot (`before-hardening`) so I could roll back.

## Changes

| Area | Setting | Windows default | Set to | Command |
|---|---|---|---|---|
| Password policy | Minimum password length | 0 | 14 | `net accounts /minpwlen:14` |
| Password policy | Enforce password history | 0 | 24 | `net accounts /uniquepw:24` |
| Password policy | Minimum password age | 0 days | 1 day | `net accounts /minpwage:1` |
| Password policy | Maximum password age | 42 days | 365 days | `net accounts /maxpwage:365` |
| Account lockout | Lockout threshold | 10 | 5 | `net accounts /lockoutthreshold:5` |
| Account lockout | Lockout duration | 10 min | 15 min | `net accounts /lockoutduration:15` |
| Account lockout | Reset lockout counter after | 10 min | 15 min | `net accounts /lockoutwindow:15` |
| Audit policy | Force advanced audit policy subcategories | Not set | Enabled | `SCENoApplyLegacyAuditPolicy = 1` |
| Audit policy | Credential Validation | No auditing | Success and Failure | `auditpol` |
| Audit policy | Logon | Partial | Success and Failure | `auditpol` |
| Audit policy | Logoff | Partial | Success | `auditpol` |
| Audit policy | Account Lockout | Partial | Failure | `auditpol` |
| Audit policy | Special Logon | Partial | Success | `auditpol` |
| Audit policy | User Account Management | Partial | Success and Failure | `auditpol` |
| Audit policy | Security Group Management | Partial | Success | `auditpol` |
| Audit policy | Process Creation | No auditing | Success | `auditpol` |

The full set of commands is in [`scripts/harden.ps1`](../scripts/harden.ps1).

## Verification

I restarted the Wazuh agent to start a new SCA scan, then checked that the scan time had changed before reading the result.

| Passed | Failed | Not applicable | Score | Scan time |
|---|---|---|---|---|
| 134 | 339 | 9 | **28%** | 15:50 |

**11 more controls passed.** Results were exported to `sca_after.csv` and the VM was snapshotted as `after-hardening`.

## Why I chose these controls

- **Password and lockout settings** make password guessing much harder. A lockout threshold of 5 also gives the SOC a clear signal (Windows event 4740) when an account is under attack.
- **Audit policy settings** decide what Windows logs at all. Turning on credential validation, logon and account management auditing means the SIEM can see failed logons, new accounts and group changes. Hardening here directly improves detection.

## Still open (accepted for the lab)

339 checks still fail. Most are settings a company would apply through Group Policy or Intune (for example, user rights assignments, Defender and SmartScreen policies, and service restrictions). In a real environment I would:

1. Apply a CIS-aligned GPO baseline to a test group first.
2. Record a risk exception, with an owner and review date, for each control that can't be applied for business reasons.
3. Track the score over time instead of aiming for 100% in one go.
