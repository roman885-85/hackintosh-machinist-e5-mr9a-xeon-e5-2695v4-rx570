# Hackintosh: MACHINIST E5-MR9A · Xeon E5-2695 v4 · Radeon RX 570 · OpenCore 1.0.8

[🇺🇦 Українська](README.md) · 🇬🇧 English

A working OpenCore **EFI** folder for a Chinese LGA2011-3 board with a Broadwell-EP server CPU
and an AMD Polaris GPU. SMBIOS is **MacPro7,1**. **Windows 10** lives on other disks.

> [!IMPORTANT]
> The serial numbers in `EFI/OC/config.plist` are placeholders (`W00000000001`), and the Windows path in the OpenCore picker
> is a zeroed placeholder (entry disabled). Before use, read [Before the first boot](#before-the-first-boot).

## Tested

| macOS | Build | Result |
|---|---|---|
| Tahoe 26.7.1 | 25G241 | ✅ all hardware listed below; several restarts with no OpenCore warnings |

Other macOS versions have not been tested.

## Hardware

| Component | Model | Status |
|---|---|---|
| Motherboard | MACHINIST E5-MR9A (LGA2011-3, AMI Aptio). Sold as "X99", but the PCH is Lynx Point (LPC 8086:8C4E, XHCI 8086:8C31, SATA 8086:8C02) | — |
| CPU | Intel Xeon E5-2695 v4 (Broadwell-EP, 18 cores / 36 threads, 2.1 GHz) | ✅ XCPM; CPUID spoofed as Haswell (`Cpuid1Data C3060300`) |
| RAM | 4 × 8 GB DDR4-2400, 32 GB total | ✅ |
| GPU | AMD Radeon RX 570, 4 GB (1002:67DF) | ✅ Metal, hardware video decoding, **5 displays**, HDMI/DP audio |
| NVMe | Samsung 990 PRO 1 TB (PCIe x4) | ✅ NVMeFix, TRIM, marked built-in |
| SATA | WD WD10EZRX 1 TB | ✅ |
| Ethernet | Realtek RTL8111H, 1 Gbit/s | ✅ RealtekRTL8111 2.4.2, marked built-in (`en0`) |
| Bluetooth | CSR8510 USB dongle (0A12:0001) | ✅ BlueToolFixup; Magic Trackpad |
| Wi-Fi | none | — |
| Onboard audio | no HDA controller visible to the OS | ❌ (and macOS 26 has no AppleHDA anyway) |
| Audio | GPU HDMI/DP; Behringer WING USB mixer | ✅ |
| Capture cards | Blackmagic DeckLink SDI 4K and DeckLink Mini Recorder | ✅ Blackmagic driver |
| USB | Intel XHCI 8C31 + EHCI | ✅ USB 2.0 and 3.0 (both blue ports at 5 Gbit/s); see [quirks](#quirks) |
| Sleep | — | ⚠️ not tested (apps prevent sleep) |

## What's inside

- **OpenCore 1.0.8** (official acidanthera RELEASE), OpenCanopy picker, OpenShell tool.
  The official `ocvalidate` 1.0.8 reports no issues.
- **SMBIOS:** `MacPro7,1`; `UpdateSMBIOSMode = Custom` together with `CustomSMBIOSGuid` — Windows sees the board's own SMBIOS.
- **SecureBootModel:** `Disabled`; `csr-active-config` = `03080000` — left over from former OCLP root patches, which are not applied now.
- **RestrictEvents:** `revpatch=cpuname,sbvmm,pci,diskread`, `revcpu=1`, `revcpuname` = "Intel® Xeon™ Processor" (CPU name in About This Mac).
- **ACPI:** `MaLd0n.aml` (Olarila bundle).
- **Kernel:** `Cpuid1Data C3060300` / `Cpuid1Mask FFFFFFFF`, `AppleXcpmCfgLock`, `AppleXcpmExtraMsrs`, `AppleXcpmForceBoost`,
  `DisableIoMapper` (+ `Mapping`), `IncreasePciBarSize` together with `npci=0x2000`, `XhciPortLimit`, `DisableLinkeditJettison`.
- **boot-args:** `npci=0x2000 watchdog=0 agdpmod=pikera` (`agdpmod=pikera` isn't required for Polaris, kept as it was).
- **DeviceProperties:** `built-in` for the NVMe — `PciRoot(0x0)/Pci(0x1,0x1)/Pci(0x0,0x0)` and the NIC —
  `PciRoot(0x0)/Pci(0x1C,0x5)/Pci(0x0,0x0)`. The paths depend on the slot: on another board or slot, check them
  (e.g. with `gfxutil` or Hackintool).

| Kext | Version | Purpose |
|---|---|---|
| Lilu | 1.7.3 | patching framework |
| VirtualSMC + SMCProcessor + SMCSuperIO | 1.3.8 | SMC emulation, sensors |
| WhateverGreen | 1.7.1 | GPU |
| RestrictEvents | 1.1.7 | CPU name, OS updates, no MacPro7,1 warnings |
| CpuTscSync | 1.1.3 | TSC sync on the many-core Xeon |
| AppleMCEReporterDisabler | — | disables AppleMCEReporter (a common recommendation for MacPro7,1 on non-Apple CPUs) |
| NVMeFix | 1.1.4 | NVMe power management |
| RealtekRTL8111 | 2.4.2 | Ethernet |
| BlueToolFixup | 2.7.3 | third-party Bluetooth dongle |
| USBInjectAll | 1.0 | USB ports (no dedicated map) |

UEFI drivers: `OpenRuntime`, `OpenCanopy`, `ResetNvramEntry`, `HfsPlus`.

## Before the first boot

1. **Serial numbers.** [GenSMBIOS](https://github.com/corpnewt/GenSMBIOS) → `MacPro7,1`. Put the serial, MLB and UUID into
   `PlatformInfo → Generic`, and also into `DataHub`, `PlatformNVRAM` and `SMBIOS` (same fields plus `BoardSerialNumber`
   and `ChassisSerialNumber`). `ROM` — your Ethernet MAC address.
2. **Windows picker entry.** In `Misc → Entries[0]` the path to `bootmgfw.efi` contains the NVMe EUI-64 and the partition GUID —
   unique to every machine, so it is zeroed here and the entry is disabled. To get yours: start **OpenShell** from the OpenCore picker,
   run `map -b`, find the `FSx:` volume that has `\EFI\Microsoft\Boot\bootmgfw.efi` (`ls FSx:\EFI\Microsoft\Boot`),
   copy its device path into `Path`, then set `Enabled = true`.
   Simpler: leave this entry disabled — OpenCore will list Windows as an automatic entry on its own.
   On this machine the automatic entry is hidden with an `EFI/Microsoft/Boot/.contentVisibility` file containing `Disabled`,
   and Windows is added as a separate entry — so macOS always stays first.
3. **Test from a USB stick** first, then copy `EFI/OC` and `EFI/BOOT` to the EFI partition of the macOS disk.
   Leave `EFI/Microsoft` (the Windows boot loader) alone — it has its own disk identifiers.

## After installing macOS

This machine needs **no separate driver package**: everything the board's hardware needs is already in the EFI
(Ethernet, Bluetooth, USB, sensors, GPU). macOS doesn't see onboard audio on this board, and there is no Wi-Fi.
Third-party software comes from the vendors:
- **Blackmagic DeckLink** — the [Desktop Video](https://www.blackmagicdesign.com/support/family/capture-and-playback) package (driver 12.1 runs here);
- **Behringer WING** — class-compliant USB audio, no macOS driver needed;
- **NTFS with write support** — Tuxera NTFS or similar (see [quirks](#quirks) about the Tuxera license).

## After a BIOS reset

`LauncherOption` is disabled here (see [quirks](#quirks)), so after a BIOS reset the board forgets the OpenCore entry and boots Windows
via "Windows Boot Manager" on the same EFI partition. To restore the entry:
- **from Windows** — `tools/windows/Restore-OpenCore.cmd` (asks for admin rights itself): creates an "OpenCore" firmware entry
  (`bcdedit /copy {bootmgr}` + path `\EFI\OC\OpenCore.efi`) and puts it first. Before the first run, set your EFI volume in
  `restore_opencore.ps1` (how to find it — see the comment at the top of the file);
- **from the BIOS menu** — add a boot option pointing to `\EFI\OC\OpenCore.efi` on the NVMe EFI partition (if the firmware supports it).

## Quirks

- **USB.** Ports work via USBInjectAll and `XhciPortLimit` (20 ports with a 15-port limit); there is no dedicated port map.
  The internal USB 3.0 header was not tested. For future macOS versions it is worth making a proper port map
  (USBToolBox or USBMap, with the `usb-port-number` / `usb-port-type` keys for macOS 26).
- **`LauncherOption = Disabled`** is intentional: the OpenCore docs warn about failures on Haswell-era firmware
  ([acidanthera/bugtracker#1222](https://github.com/acidanthera/bugtracker/issues/1222)). So after a BIOS reset the OpenCore
  entry in the firmware boot list has to be restored by hand.
- **Tuxera NTFS.** After the NIC was marked built-in, the Tuxera license became invalid (it is bound to the primary network
  interface) — NTFS partitions mount read-only until Tuxera is re-activated.

## Changelog

- **2026-11-10** — "After installing macOS" notes, a Windows script to restore the OpenCore entry after a BIOS reset.

**2026-10-10:**

- Moved from the OpenCore-Mod 1.0.8 fork (from an Olarila/MaLd0n EFI) to the **official OpenCore 1.0.8**: replaced `OpenCore.efi`, `BOOTx64.efi`,
  `OpenRuntime`, `OpenCanopy`, `ResetNvramEntry`, `OpenShell`; removed keys the official build doesn't know (`EnableForAll` ×2,
  `SkipCustomEntryCheck`) — boots with no warnings (previously 7 "OCS: No schema" lines).
- Removed DeviceProperties entries outside `Add` and stray "New item" keys; dropped `alcid=1`, `dk.e1000=0`, `e1000=0` from `boot-args`.
- NVMe and NIC marked built-in; UEFI Shell added; 29 unused files removed from the EFI partition.
- macOS is the default entry, Windows is a separate entry.
- For publication, 6 disabled kexts were removed (AirportBrcmFixup, AppleALC, AppleIGC, AtherosE2200Ethernet, IntelMausi, XHCI-unsupported).

## Credits & licenses

- [OpenCorePkg](https://github.com/acidanthera/OpenCorePkg), Lilu, WhateverGreen, VirtualSMC, NVMeFix, RestrictEvents, BlueToolFixup
  ([BrcmPatchRAM](https://github.com/acidanthera/BrcmPatchRAM)) — acidanthera, BSD-3-Clause.
- [CpuTscSync](https://github.com/acidanthera/CpuTscSync) — lvs1974; [USBInjectAll](https://github.com/RehabMan/OS-X-USB-Inject-All) — RehabMan;
  AppleMCEReporterDisabler; [RealtekRTL8111](https://github.com/Mieze/RTL8111_driver_for_OS_X) — Laura Müller.
- `MaLd0n.aml` — Olarila; `HfsPlus.efi` (Apple's closed-source driver) and picker resources — [OcBinaryData](https://github.com/acidanthera/OcBinaryData).

This repository's own files (docs, `config.plist`) — [MIT](LICENSE). Use at your own risk;
Apple's license allows macOS on Apple hardware only.
