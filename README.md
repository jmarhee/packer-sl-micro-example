# SL Micro Packer

Packer builder example for KVM and VMware to customize SL Micro.

## Requirements

On the build host:

- [Packer](https://developer.hashicorp.com/packer) 1.9 or later (`packer init` pulls the QEMU plugin)
- `qemu-system-x86_64`, `qemu-img`, and OVMF/edk2 firmware for local validation (Optional)

From [SUSE Customer Center](https://scc.suse.com), download the VMware GM image into [`base-images/`](base-images/):

```text
SL-Micro.x86_64-6.2-Base-VMware-GM.vmdk
```

## VMDK

Packer will expect the base VMDK from SCC in `base-images/` for your SL Micro release.

To run the build:

```bash
make vmdk
```

On x86_64 Linux, `make` uses `kvm` when `/dev/kvm` exists and the first OVMF CODE/VARS pair it finds. There is no single distro path (see `vmdk/variables.pkr.hcl`):

- SUSE / openSUSE: `/usr/share/qemu/ovmf-x86_64-code.bin` and `ovmf-x86_64-vars.bin`
- Fedora / RHEL: `/usr/share/edk2/ovmf/OVMF_CODE.fd` and `OVMF_VARS.fd`
- Debian / Ubuntu: `/usr/share/OVMF/OVMF_CODE_4M.fd` and `OVMF_VARS_4M.fd`

Override if needed:

```bash
make vmdk EFI_CODE=/usr/share/qemu/ovmf-x86_64-code.bin EFI_VARS=/usr/share/qemu/ovmf-x86_64-vars.bin
```

Output vmdk image path:

```text
vmdk/output/sle-micro-sshd-hardening/sle-micro-sshd-hardening.vmdk
```

An intermediate `.qcow2` is created during this process; ignore for VMware.

Create a **UEFI** VM and attach the golden VMDK as the boot disk. 

**NOTE**Do not boot the unmodified GM image. The clone already has `/etc/machine-id`, so Ignition does not run again.

## Ignition

The VMDK template injects `vmdk/ignition/config.ign` (spec 3.4.0) on first boot:

- Writes `/etc/ssh/sshd_config.d/00-disable-password-auth.conf` so password and keyboard-interactive SSH are off for every user
- Installs `~/.ssh/id_rsa.pub` as root’s authorized key and enables `sshd.service`

A one-shot unit then powers the guest off so Packer can keep the disk.

## QEMU testing (optional)

`make qcow2` and `make test` build and boot the qcow2 GM for local verification. 
