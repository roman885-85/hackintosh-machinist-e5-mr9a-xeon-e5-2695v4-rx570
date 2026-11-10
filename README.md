# Hackintosh: MACHINIST E5-MR9A · Xeon E5-2695 v4 · Radeon RX 570 · OpenCore 1.0.8

🇺🇦 Українська · [🇬🇧 English](README.en.md)

Робоча папка **EFI** для OpenCore на китайській платі під LGA2011-3 із серверним процесором Broadwell-EP
і відеокартою AMD Polaris. Модель Mac — **MacPro7,1**. Поруч на інших дисках стоїть **Windows 10**.

> [!IMPORTANT]
> Серійні номери в `EFI/OC/config.plist` замінено заглушками (`W00000000001`), а шлях до Windows у меню OpenCore —
> заглушкою з нулями (запис вимкнено). Перед використанням — розділ [Перед першим запуском](#перед-першим-запуском).

## Перевірено

| macOS | Збірка | Результат |
|---|---|---|
| Tahoe 26.7.1 | 25G241 | ✅ усе обладнання з таблиці нижче; кілька перезапусків без попереджень OpenCore |

Інші версії macOS не перевірялися.

## Обладнання

| Компонент | Модель | Стан |
|---|---|---|
| Плата | MACHINIST E5-MR9A (LGA2011-3, AMI Aptio). Продається як «X99», але південний міст — Lynx Point (LPC 8086:8C4E, XHCI 8086:8C31, SATA 8086:8C02) | — |
| Процесор | Intel Xeon E5-2695 v4 (Broadwell-EP, 18 ядер / 36 потоків, 2,1 ГГц) | ✅ XCPM; CPUID підмінено на Haswell (`Cpuid1Data C3060300`) |
| Пам'ять | 4 × 8 ГБ DDR4-2400, разом 32 ГБ | ✅ |
| Відеокарта | AMD Radeon RX 570, 4 ГБ (1002:67DF) | ✅ Metal, апаратне декодування відео, **5 моніторів**, звук HDMI/DP |
| NVMe | Samsung 990 PRO 1 ТБ (PCIe x4) | ✅ NVMeFix, TRIM, позначений вбудованим |
| SATA | WD WD10EZRX 1 ТБ | ✅ |
| Мережа | Realtek RTL8111H, 1 Гбіт/с | ✅ RealtekRTL8111 2.4.2, позначена вбудованою (`en0`) |
| Bluetooth | USB-донгл CSR8510 (0A12:0001) | ✅ BlueToolFixup; Magic Trackpad |
| Wi-Fi | немає | — |
| Звук на платі | контролера HDA система не бачить | ❌ (у macOS 26 і AppleHDA немає) |
| Звук | HDMI/DP відеокарти; USB-мікшер Behringer WING | ✅ |
| Карти відеозахоплення | Blackmagic DeckLink SDI 4K і DeckLink Mini Recorder | ✅ драйвер Blackmagic |
| USB | Intel XHCI 8C31 + EHCI | ✅ USB 2.0 і 3.0 (обидва сині порти — 5 Гбіт/с); див. [нюанси](#нюанси) |
| Сон | — | ⚠️ не перевірявся (сон забороняють програми) |

## Що всередині

- **OpenCore 1.0.8** (офіційний RELEASE acidanthera), графічне меню OpenCanopy, інструмент OpenShell.
  Офіційний `ocvalidate` 1.0.8 зауважень не має.
- **SMBIOS:** `MacPro7,1`; `UpdateSMBIOSMode = Custom` разом із `CustomSMBIOSGuid` — Windows бачить рідний SMBIOS плати.
- **SecureBootModel:** `Disabled`; `csr-active-config` = `03080000` — лишилося від колишніх кореневих патчів OCLP, зараз вони не застосовуються.
- **RestrictEvents:** `revpatch=cpuname,sbvmm,pci,diskread`, `revcpu=1`, `revcpuname` = «Intel® Xeon™ Processor» (назва процесора в «Про цей Mac»).
- **ACPI:** `MaLd0n.aml` (набір Olarila).
- **Kernel:** `Cpuid1Data C3060300` / `Cpuid1Mask FFFFFFFF`, `AppleXcpmCfgLock`, `AppleXcpmExtraMsrs`, `AppleXcpmForceBoost`,
  `DisableIoMapper` (+ `Mapping`), `IncreasePciBarSize` разом із `npci=0x2000`, `XhciPortLimit`, `DisableLinkeditJettison`.
- **boot-args:** `npci=0x2000 watchdog=0 agdpmod=pikera` (`agdpmod=pikera` для Polaris не обов'язковий, лишився як був).
- **DeviceProperties:** `built-in` для NVMe — `PciRoot(0x0)/Pci(0x1,0x1)/Pci(0x0,0x0)` і мережевої карти —
  `PciRoot(0x0)/Pci(0x1C,0x5)/Pci(0x0,0x0)`. Шляхи залежать від слота: на іншій платі чи в іншому слоті перевірте їх
  (наприклад, через `gfxutil` або Hackintool).

| Kext | Версія | Навіщо |
|---|---|---|
| Lilu | 1.7.3 | основа для інших розширень |
| VirtualSMC + SMCProcessor + SMCSuperIO | 1.3.8 | емуляція SMC, датчики |
| WhateverGreen | 1.7.1 | відеокарта |
| RestrictEvents | 1.1.7 | назва процесора, оновлення ОС, без попереджень MacPro7,1 |
| CpuTscSync | 1.1.3 | синхронізація TSC на багатоядерному Xeon |
| AppleMCEReporterDisabler | — | вимикає AppleMCEReporter (поширена порада для MacPro7,1 на не-Apple процесорах) |
| NVMeFix | 1.1.4 | живлення NVMe |
| RealtekRTL8111 | 2.4.2 | мережа |
| BlueToolFixup | 2.7.3 | Bluetooth стороннього донгла |
| USBInjectAll | 1.0 | порти USB (без окремої карти) |

Драйвери UEFI: `OpenRuntime`, `OpenCanopy`, `ResetNvramEntry`, `HfsPlus`.

## Перед першим запуском

1. **Серійні номери.** [GenSMBIOS](https://github.com/corpnewt/GenSMBIOS) → `MacPro7,1`. Впишіть серійний номер, MLB і UUID
   у `PlatformInfo → Generic`, а також у `DataHub`, `PlatformNVRAM` і `SMBIOS` (там ті самі поля плюс `BoardSerialNumber`
   і `ChassisSerialNumber`). `ROM` — MAC-адреса мережевої карти.
2. **Пункт Windows у меню.** У `Misc → Entries[0]` шлях до `bootmgfw.efi` містить EUI-64 диска NVMe і GUID розділу —
   у кожного комп'ютера свої, тому тут нулі, а запис вимкнено. Як отримати свій: у меню OpenCore запустіть **OpenShell**,
   виконайте `map -b`, знайдіть том `FSx:`, на якому є `\EFI\Microsoft\Boot\bootmgfw.efi` (`ls FSx:\EFI\Microsoft\Boot`),
   і перенесіть його шлях пристрою в `Path`, потім `Enabled = true`.
   Простіший варіант — не вмикати цей запис: OpenCore сам покаже Windows як автоматичний пункт.
   На цьому комп'ютері автоматичний пункт приховано файлом `EFI/Microsoft/Boot/.contentVisibility` зі словом `Disabled`,
   а Windows додано окремим записом — так macOS завжди стоїть першою.
3. **Перевірка з флешки**, потім копіювання `EFI/OC` і `EFI/BOOT` на розділ EFI диска з macOS.
   Папку `EFI/Microsoft` (завантажувач Windows) не чіпайте — у неї свої ідентифікатори дисків.

## Нюанси

- **USB.** Порти працюють через USBInjectAll і `XhciPortLimit` (20 портів при ліміті 15), окремої карти портів немає.
  Внутрішню колодку USB 3.0 не перевіряли. Для надійності на майбутніх версіях macOS варто зробити власну карту портів
  (USBToolBox або USBMap, з ключами `usb-port-number` / `usb-port-type` для macOS 26).
- **`LauncherOption = Disabled`** залишено навмисно: документація OpenCore попереджає про збої на прошивках епохи Haswell
  ([acidanthera/bugtracker#1222](https://github.com/acidanthera/bugtracker/issues/1222)). Тому після скидання BIOS запис
  OpenCore у списку завантаження плати доведеться відновити вручну.
- **Tuxera NTFS.** Після того як мережеву карту позначено вбудованою, ліцензія Tuxera стала недійсною (вона прив'язана до основного
  мережевого інтерфейсу) — NTFS-розділи монтуються лише для читання, доки Tuxera не активувати заново.

## Історія змін (усе — 10.10.2026)

- Перехід із форка OpenCore-Mod 1.0.8 (з EFI Olarila/MaLd0n) на **офіційний OpenCore 1.0.8**: замінено `OpenCore.efi`, `BOOTx64.efi`,
  `OpenRuntime`, `OpenCanopy`, `ResetNvramEntry`, `OpenShell`; прибрано ключі, яких немає в офіційній версії (`EnableForAll` ×2,
  `SkipCustomEntryCheck`), — завантаження без попереджень (раніше 7 рядків «OCS: No schema»).
- Прибрано записи DeviceProperties поза `Add` і зайві ключі «New item»; з `boot-args` прибрано `alcid=1`, `dk.e1000=0`, `e1000=0`.
- NVMe і мережева карта позначені вбудованими; додано UEFI Shell; з розділу EFI знято 29 невикористаних файлів.
- macOS — пункт за замовчуванням, Windows — окремим записом.
- Для публікації прибрано 6 вимкнених kext (AirportBrcmFixup, AppleALC, AppleIGC, AtherosE2200Ethernet, IntelMausi, XHCI-unsupported).

## Подяки й ліцензії

- [OpenCorePkg](https://github.com/acidanthera/OpenCorePkg), Lilu, WhateverGreen, VirtualSMC, NVMeFix, RestrictEvents, BlueToolFixup
  ([BrcmPatchRAM](https://github.com/acidanthera/BrcmPatchRAM)) — acidanthera, BSD-3-Clause.
- [CpuTscSync](https://github.com/acidanthera/CpuTscSync) — lvs1974; [USBInjectAll](https://github.com/RehabMan/OS-X-USB-Inject-All) — RehabMan;
  AppleMCEReporterDisabler; [RealtekRTL8111](https://github.com/Mieze/RTL8111_driver_for_OS_X) — Laura Müller.
- `MaLd0n.aml` — Olarila; `HfsPlus.efi` (закритий драйвер Apple) і ресурси меню — [OcBinaryData](https://github.com/acidanthera/OcBinaryData).

Власні файли репозиторію (опис, `config.plist`) — [MIT](LICENSE). Користуєтеся на власний ризик;
macOS дозволено встановлювати лише на обладнання Apple.
