# Enable Reliable Hibernation on CachyOS / Arch  
## Limine + Btrfs root + Btrfs swapfile + systemd + Hypridle

This documents how to configure hibernation on a CachyOS/Arch-like system with:

- **Limine** bootloader
- **CachyOS kernels** (`linux-cachyos`, optionally `linux-cachyos-lts`)
- Root filesystem on **Btrfs**
- Root partition such as `/dev/sda2`
- Existing **zram** swap
- `mkinitcpio` using the `systemd` hook
- Hyprland + Hypridle
- A machine that only offers `s2idle` suspend and does not reliably wake from it

The goal is to use real disk-backed **hibernation** instead of unreliable suspend.

> [!important]
> `zram` alone cannot support hibernation.
>
> zram is compressed RAM used as swap. Hibernation requires the system RAM contents to survive a power-off, so the hibernation image must be written to persistent storage: a swap partition or disk-backed swapfile.

---

# 1. Check the Current Sleep Mode

Check available suspend modes:

```fish
cat /sys/power/mem_sleep
```

Example result:

```text
[s2idle]
```

This means only `s2idle` / Modern Standby is available.

Attempting to enable `deep` may fail:

```fish
echo deep | sudo tee /sys/power/mem_sleep
```

Example result:

```text
tee: /sys/power/mem_sleep: Invalid argument
```

This is not a configuration mistake. It means the firmware/kernel does not expose classic S3/deep sleep.

If `systemctl suspend` enters sleep but cannot wake correctly, that is likely an `s2idle`, firmware, GPU, or driver issue.

Hibernation avoids the suspend/resume path completely.

---

# 2. Confirm Existing Memory, Disk Space, and Swap

Check installed RAM and current swap:

```fish
free -h
```

Check available disk space:

```fish
df -h /
```

Check swap devices:

```fish
swapon --show
```

Example before configuration:

```text
NAME       TYPE      SIZE  USED PRIO
/dev/zram0 partition 7.3G 80M  100
```

For a system with approximately 8 GiB RAM, create at least an 8 GiB disk swapfile. A 10–12 GiB swapfile gives additional safety margin, especially if RAM usage is high before hibernation.

---

# 3. Create a Btrfs-Compatible Swapfile

> [!warning]
> Do not create a normal swapfile with `fallocate` on Btrfs.
>
> Use `btrfs filesystem mkswapfile`, which creates a correctly configured swapfile with the required NOCOW behavior.

Create a swap directory:

```fish
sudo mkdir -p /swap
```

Create an 8 GiB Btrfs swapfile:

```fish
sudo btrfs filesystem mkswapfile --size 8G /swap/swapfile
```

Enable it immediately:

```fish
sudo swapon /swap/swapfile
```

Verify:

```fish
swapon --show
```

Expected example:

```text
NAME           TYPE      SIZE  USED PRIO
/dev/zram0     partition 7.3G 80M  100
/swap/swapfile file        8G   0B   -1
```

Keeping zram enabled is fine. zram can still be used as high-priority regular swap; the disk-backed swapfile is specifically needed for hibernation.

---

# 4. Make the Swapfile Persistent

Edit `/etc/fstab`:

```fish
sudo nano /etc/fstab
```

Add this line:

```fstab
/swap/swapfile none swap defaults 0 0
```

> [!note]
> The `/etc/fstab` line is configuration text, not a command.
>
> Do **not** paste this directly into Fish:
>
> ```text
> /swap/swapfile none swap defaults 0 0
> ```
>
> Fish will report that it is not an executable command.

Test the fstab entry:

```fish
sudo swapoff /swap/swapfile
sudo swapon -a
swapon --show
```

The swapfile should reappear in the output.

---

# 5. Obtain the Resume UUID and Btrfs Swapfile Offset

The kernel needs two parameters to find and restore the hibernation image:

1. The UUID of the filesystem/device containing the swapfile.
2. The physical resume offset of the Btrfs swapfile.

For a root filesystem on `/dev/sda2`, get its UUID:

```fish
sudo blkid -s UUID -o value /dev/sda2
```

Example output:

```text
205a4077-e665-4463-b3fd-72a74f1b7479
```

Get the resume offset:

```fish
sudo btrfs inspect-internal map-swapfile -r /swap/swapfile
```

Example output:

```text
12068096
```

The resulting kernel parameters are:

```text
resume=UUID=205a4077-e665-4463-b3fd-72a74f1b7479 resume_offset=12068096
```

> [!important]
> This is **not** a Fish command.
>
> It is a pair of kernel command-line parameters. It must be placed in the Limine configuration source, as described below.

If the swapfile is recreated, resized, moved, or deleted, rerun:

```fish
sudo btrfs inspect-internal map-swapfile -r /swap/swapfile
```

Then update `resume_offset=` with the new value.

---

# 6. Add the `resume` Hook to mkinitcpio

Check current mkinitcpio hooks:

```fish
grep '^HOOKS=' /etc/mkinitcpio.conf
```

For a system using the `systemd` initramfs hook, the line may resemble:

```text
HOOKS=(base systemd autodetect microcode kms modconf block keyboard sd-vconsole plymouth filesystems)
```

Edit it:

```fish
sudo nano /etc/mkinitcpio.conf
```

Add `resume` after `filesystems`:

```text
HOOKS=(base systemd autodetect microcode kms modconf block keyboard sd-vconsole plymouth filesystems resume)
```

The important requirement is that `resume` is included.

Rebuild the initramfs:

```fish
sudo mkinitcpio -P
```

On CachyOS with Limine integration, this may report:

```text
==> ERROR: No presets found in /etc/mkinitcpio.d
==> WARNING: This does not update Limine boot entries.
==> Would you like to run 'limine-mkinitcpio' now? [Y/n]:
```

Answer:

```text
y
```

Alternatively, run the Limine-aware command directly:

```fish
sudo limine-mkinitcpio
```

This rebuilds the initramfs and regenerates `/boot/limine.conf`.

---

# 7. Configure Persistent Kernel Parameters for Limine

## Do not edit generated `/boot/limine.conf` permanently

On this CachyOS setup, `/boot/limine.conf` contains entries such as:

```text
### This kernel entry is auto-generated by limine-entry-tool
```

It is regenerated by:

```fish
sudo limine-mkinitcpio
```

Therefore manual changes to `/boot/limine.conf` will be lost.

The persistent kernel-command-line configuration is:

```text
/etc/default/limine
```

Inspect it:

```fish
sudo cat /etc/default/limine
```

Edit it:

```fish
sudo nano /etc/default/limine
```

Look for a kernel command-line variable. It may look like one of these:

```sh
KERNEL_CMDLINE[default]="quiet nowatchdog splash"
```

or:

```sh
KERNEL_CMDLINE="quiet nowatchdog splash"
```

Append the resume options inside the quotes.

Example with the array form:

```sh
KERNEL_CMDLINE[default]="quiet nowatchdog splash resume=UUID=205a4077-e665-4463-b3fd-72a74f1b7479 resume_offset=12068096"
```

Example with the normal variable form:

```sh
KERNEL_CMDLINE="quiet nowatchdog splash resume=UUID=205a4077-e665-4463-b3fd-72a74f1b7479 resume_offset=12068096"
```

Do not remove existing options such as:

```text
quiet nowatchdog splash
```

Regenerate the Limine entries after saving:

```fish
sudo limine-mkinitcpio
```

Verify that the normal generated entries received the options:

```fish
sudo grep -n 'cmdline:' /boot/limine.conf | head -n 2
```

Expected result includes:

```text
resume=UUID=205a4077-e665-4463-b3fd-72a74f1b7479
resume_offset=12068096
```

The generated line may look similar to:

```text
cmdline: quiet nowatchdog splash resume=UUID=205a4077-e665-4463-b3fd-72a74f1b7479 resume_offset=12068096 rw rootflags=subvol=/@ root=UUID=205a4077-e665-4463-b3fd-72a74f1b7479
```

The ordering of kernel options does not matter.

> [!note]
> Do not worry about adding resume options to every historical Snapper snapshot entry in `/boot/limine.conf`.
>
> The important entries are the normal current CachyOS kernel entries. The generated Limine configuration may contain many old snapshot boot entries.

---

# 8. Reboot and Verify Configuration

Reboot:

```fish
systemctl reboot
```

After logging in again, verify that the running kernel received the resume parameters:

```fish
cat /proc/cmdline
```

It must contain both:

```text
resume=UUID=205a4077-e665-4463-b3fd-72a74f1b7479
resume_offset=12068096
```

Verify that the disk-backed swapfile was activated automatically:

```fish
swapon --show
```

Expected result includes:

```text
/swap/swapfile file 8G ...
```

If `/swap/swapfile` is missing after boot, check `/etc/fstab`:

```fish
grep -vE '^\s*(#|$)' /etc/fstab
```

It should contain:

```fstab
/swap/swapfile none swap defaults 0 0
```

---

# 9. Test Hibernation Manually

Before involving Hypridle, test hibernation directly:

```fish
sudo systemctl hibernate
```

Expected behavior:

1. The system saves memory to the disk swapfile.
2. The machine powers off completely.
3. Pressing the physical power button boots the machine.
4. The previous session is restored.

A successful restore should return to the state from before hibernation, rather than starting a fresh desktop/login session.

After a successful resume, inspect logs if desired:

```fish
journalctl -b | grep -Ei 'hibernate|resume|swap'
```

Or:

```fish
dmesg | grep -Ei 'hibernate|resume|swap'
```

---

# 10. Configure Suspend Then Hibernate with Hypridle

If the computer wakes reliably from normal suspend, `suspend-then-hibernate` is preferable to immediate hibernation:

1. The computer uses low-power suspend first.
2. After a defined time suspended, systemd automatically hibernates it.
3. This preserves battery compared with leaving it in suspend indefinitely.
4. The system can still restore the previous session after full hibernation.

> [!warning]
> This system supports only `s2idle`:
>
> ```fish
> cat /sys/power/mem_sleep
> ```
>
> Result:
>
> ```text
> [s2idle]
> ```
>
> Before relying on suspend-then-hibernate, test normal suspend and wake several times:
>
> ```fish
> sudo systemctl suspend
> ```
>
> If the computer still fails to wake reliably, use direct hibernation instead:
>
> ```ini
> on-timeout = systemctl hibernate
> ```

---

## Configure systemd’s Hibernate Delay

Hypridle cannot track time while the computer is suspended. Therefore it must not use a second, later Hypridle timeout to request hibernation.

Use systemd's `suspend-then-hibernate` mechanism instead.

Create the systemd sleep configuration directory:

```fish
sudo mkdir -p /etc/systemd/sleep.conf.d
```

Create a configuration drop-in:

```fish
sudo nano /etc/systemd/sleep.conf.d/suspend-then-hibernate.conf
```

Use this configuration:

```ini
[Sleep]
AllowSuspendThenHibernate=yes
HibernateDelaySec=1h
```

This means that once systemd enters suspend-then-hibernate mode, it will:

1. Suspend first.
2. Stay suspended for one hour.
3. Wake internally.
4. Hibernate to `/swap/swapfile`.
5. Power off completely.

`AllowSuspend=yes` and `AllowHibernation=yes` are normally already enabled by default, so they are not required. The following more explicit version is also valid:

```ini
[Sleep]
AllowSuspend=yes
AllowHibernation=yes
AllowSuspendThenHibernate=yes
HibernateDelaySec=1h
```

There is no need to configure these unless a specific reason exists:

```ini
#AllowHybridSleep=yes
#SuspendState=mem standby freeze
#HibernateMode=platform shutdown
#MemorySleepMode=
#HibernateOnACPower=yes
#SuspendEstimationSec=60min
```

In particular, setting `MemorySleepMode=deep` cannot enable deep sleep if firmware exposes only `s2idle`.

Verify the effective systemd sleep configuration:

```fish
systemd-analyze cat-config systemd/sleep.conf
```

---

## Test with a Short Delay First

Before using a one-hour delay, temporarily configure a two-minute test:

```ini
[Sleep]
AllowSuspendThenHibernate=yes
HibernateDelaySec=2min
```

Then run:

```fish
sudo systemctl suspend-then-hibernate
```

Expected behavior:

1. The system suspends.
2. After approximately two minutes, it wakes internally without user interaction.
3. It hibernates to the disk-backed swapfile.
4. The computer powers off.
5. Pressing the physical power button restores the previous desktop session.

After confirming this works, change the delay back to:

```ini
HibernateDelaySec=1h
```

---

## Hypridle Configuration

Use one sleep listener only:

```ini
general {
    lock_cmd = pidof hyprlock || hyprlock

    before_sleep_cmd = loginctl lock-session
    after_sleep_cmd = hyprctl dispatch 'hl.dsp.dpms({ action = "enable" })'

    ignore_dbus_inhibit = false
    ignore_systemd_inhibit = false
    ignore_wayland_inhibit = false

    inhibit_sleep = 3
}

listener {
    timeout = 300
    on-timeout = pidof hyprlock || hyprlock
}

listener {
    timeout = 600
    on-timeout = systemctl suspend-then-hibernate
}
```

Timeline:

|
 Time since inactivity 
|
 Action 
|

|
---:
|
---
|

|
 5 minutes 
|
 Lock screen using Hyprlock 
|

|
 10 minutes 
|
 Begin suspend-then-hibernate 
|

|
 10 minutes + 1 hour suspended 
|
 Hibernate and power off 
|

|
 Later 
|
 Press power button to resume the hibernated session 
|


> [!important]
> Do not use a second Hypridle sleep listener such as:
>
> ```ini
> listener {
>     timeout = 6000
>     on-timeout = systemctl suspend
> }
> ```
>
> Hypridle is suspended along with the rest of userspace, so it cannot reliably continue counting while the machine sleeps. Also, that command requests another suspend, not hibernation.
>
> Let systemd manage the suspend-to-hibernate transition with:
>
> ```ini
> on-timeout = systemctl suspend-then-hibernate
> ```






---

# Troubleshooting Checklist

## Hibernation is unavailable

Check:

```fish
systemctl hibernate
```

If systemd reports hibernation is not available, verify:

```fish
swapon --show
cat /proc/cmdline
grep '^HOOKS=' /etc/mkinitcpio.conf
```

Required conditions:

- `/swap/swapfile` is active.
- Kernel command line includes `resume=UUID=...`.
- Kernel command line includes `resume_offset=...`.
- `resume` exists in `HOOKS=(...)`.
- Initramfs was rebuilt after changing `mkinitcpio.conf`.

---

## Hibernation powers off but performs a fresh boot

This almost always means the resume configuration was not found early during boot.

Check:

```fish
cat /proc/cmdline
```

Confirm the exact UUID and offset match:

```fish
sudo blkid -s UUID -o value /dev/sda2
sudo btrfs inspect-internal map-swapfile -r /swap/swapfile
```

Then ensure `/etc/default/limine` contains the correct options and regenerate:

```fish
sudo limine-mkinitcpio
```

Reboot and check `/proc/cmdline` again.

---

## Manual changes to `/boot/limine.conf` disappear

That is expected.

The file is generated by `limine-entry-tool` / `limine-mkinitcpio`.

Use:

```text
/etc/default/limine
```

for persistent kernel command-line options.

Then regenerate:

```fish
sudo limine-mkinitcpio
```

---

## Swapfile was recreated or resized

The Btrfs physical offset can change.

Run:

```fish
sudo btrfs inspect-internal map-swapfile -r /swap/swapfile
```

Update the `resume_offset=` value in:

```text
/etc/default/limine
```

Then regenerate:

```fish
sudo limine-mkinitcpio
```

Reboot afterward.

---

## `deep` sleep cannot be enabled

If this shows only:

```text
[s2idle]
```

then the hardware/firmware exposes no `deep` sleep mode:

```fish
cat /sys/power/mem_sleep
```

This command failing is expected in that case:

```fish
echo deep | sudo tee /sys/power/mem_sleep
```

The resulting `Invalid argument` does not indicate a problem with Btrfs, swap, Limine, or hibernation.

Use direct hibernation if `s2idle` wake is unreliable.

---

# System-Specific Values Used in This Setup

| Setting | Value |
|---|---|
| Root device | `/dev/sda2` |
| Root filesystem | Btrfs |
| Root UUID | `205a4077-e665-4463-b3fd-72a74f1b7479` |
| Swapfile | `/swap/swapfile` |
| Swapfile size | `8G` |
| Btrfs resume offset | `12068096` |
| Bootloader | Limine |
| Persistent Limine settings | `/etc/default/limine` |
| Generated Limine configuration | `/boot/limine.conf` |
| Initramfs configuration | `/etc/mkinitcpio.conf` |
| Required mkinitcpio hook | `resume` |

Current kernel parameters required for hibernation:

```text
resume=UUID=205a4077-e665-4463-b3fd-72a74f1b7479 resume_offset=12068096
```
