# BO7 Ranked – TPM Attestation Fix

A lightweight Windows utility that restores TPM provisioning scheduled tasks and forces Windows to complete TPM attestation if it is not ready.

This tool is designed for situations where Ranked mode (or other secure applications) may fail hardware verification due to incomplete TPM provisioning.

---

## What This Tool Does

- Checks TPM attestation status using `tpmtool`
- If attestation is already healthy, exits without making changes
- Re-registers missing Windows TPM scheduled tasks
- Runs TPM maintenance and certificate retrieval tasks
- Allows Windows to regenerate missing attestation components if needed

---

## What This Tool Does NOT Do

- Does **not** perform a firmware-level TPM clear
- Does **not** reset or wipe TPM ownership
- Does **not** disable Secure Boot
- Does **not** modify BIOS/UEFI settings
- Does **not** alter BitLocker configuration

This tool only restores Windows-level task registration and provisioning workflows.

---

## When To Use

Use this tool if:

- `tpmtool getdeviceinformation` shows:
  - `Ready For Attestation: False`
  - or `Is Capable For Attestation: False`
- Secure applications fail hardware verification due to TPM attestation status

---

## How To Use

1. Right-click `BO7_Ranked_TPM_Fix.bat`
2. Select **Run as Administrator**
3. Follow on-screen instructions
4. Reboot your PC after repair (if repair runs)

---

## Manual Verification

Open an elevated Command Prompt and run:

```
tpmtool getdeviceinformation
```

Both of these values should be:

- `Ready For Attestation: True`
- `Is Capable For Attestation: True`

---

## Important Notes

- This tool is safe to run on healthy systems (it exits without changes).
- It does not modify firmware or clear TPM hardware.
- It operates only at the Windows task and provisioning layer.

---

## Disclaimer

This utility is provided as-is without warranty.  
Use at your own discretion.
