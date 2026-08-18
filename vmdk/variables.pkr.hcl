# Override with -var, a .pkrvars.hcl file, or `make` (which picks the first
# firmware files that exist and uses kvm when /dev/kvm is present).
#
# There is no single Linux OVMF path. Common CODE / VARS pairs:
#
#   SUSE / openSUSE (qemu-ovmf-x86_64):
#     /usr/share/qemu/ovmf-x86_64-code.bin
#     /usr/share/qemu/ovmf-x86_64-vars.bin
#   Fedora / RHEL (edk2-ovmf):
#     /usr/share/edk2/ovmf/OVMF_CODE.fd
#     /usr/share/edk2/ovmf/OVMF_VARS.fd
#   Debian / Ubuntu (ovmf); prefer the 4M images on current releases:
#     /usr/share/OVMF/OVMF_CODE_4M.fd
#     /usr/share/OVMF/OVMF_VARS_4M.fd
#     older: OVMF_CODE.fd / OVMF_VARS.fd in the same directory
#   Arch (edk2-ovmf):
#     /usr/share/edk2/x64/OVMF_CODE.4m.fd
#     /usr/share/edk2/x64/OVMF_VARS.4m.fd
#   macOS Homebrew:
#     /opt/homebrew/share/qemu/edk2-x86_64-code.fd   (Apple Silicon)
#     /opt/homebrew/share/qemu/edk2-i386-vars.fd
#     /usr/local/share/qemu/...                      (Intel)
#
# qemu-system-x86_64 is usually on PATH (/usr/bin on Linux; Homebrew bin on macOS).

variable "install_media" {
  type        = string
  default     = ""
  description = "Path to SLE Micro VMware VMDK. Empty uses ../base-images/SL-Micro.x86_64-6.2-Base-VMware-GM.vmdk from this directory."
}

variable "install_media_checksum" {
  type    = string
  default = "none"
}

variable "install_media_is_disk" {
  type        = bool
  default     = true
  description = "True for a pre-built disk image (Packer disk_image mode). qemu-img reads the GM VMDK."
}

variable "boot_command" {
  type        = list(string)
  default     = []
  description = "Empty for Base image first-boot. For a SelfInstall ISO, pass the KIWI OEM boot keys."
}

variable "output_name" {
  type    = string
  default = "sle-micro-sshd-hardening"
}

variable "disk_size_mb" {
  type        = number
  default     = 32768
  description = "Target virtual disk size in MB. Must be >= the source VMDK virtual size (24 GiB / 24576) or qemu-img will refuse to shrink."
}

variable "headless" {
  type    = bool
  default = true
}

variable "accelerator" {
  type        = string
  default     = "tcg"
  description = "QEMU accelerator. kvm on an x86_64 Linux host with /dev/kvm; tcg on Apple Silicon (x86_64 guest); hvf only for a native-arch macOS guest."
}

variable "qemu_binary" {
  type        = string
  default     = "qemu-system-x86_64"
  description = "QEMU binary for the guest arch (x86_64). Linux: /usr/bin/qemu-system-x86_64. macOS Homebrew: /opt/homebrew/bin or /usr/local/bin."
}

variable "efi_firmware_code" {
  type        = string
  default     = "/opt/homebrew/share/qemu/edk2-x86_64-code.fd"
  description = "OVMF CODE pflash (not -bios). Default is Homebrew on Apple Silicon; on Linux pass the CODE file from the comment at the top of this file (or use make)."
}

variable "efi_firmware_vars" {
  type        = string
  default     = "/opt/homebrew/share/qemu/edk2-i386-vars.fd"
  description = "OVMF VARS template, paired with efi_firmware_code. Must match CODE size (do not mix 2M and 4M images)."
}

variable "machine_type" {
  type        = string
  default     = "q35"
  description = "QEMU machine type. q35 is the usual pairing with OVMF."
}

variable "memory_mb" {
  type        = number
  default     = 2048
  description = "Guest RAM in MiB. Packer's default 512 is too small for SLE Micro first boot."
}

variable "cpus" {
  type    = number
  default = 2
}

variable "disk_interface" {
  type        = string
  default     = "virtio"
  description = "Same as examples/packer/qcow2. If the VMware GM initrd has no virtio-blk, try scsi or virtio-scsi."
}

variable "net_device" {
  type        = string
  default     = "virtio-net"
  description = "Same as examples/packer/qcow2. Network is not required for fw_cfg Ignition; try e1000 if the guest has no virtio-net."
}

variable "build_shutdown_timeout" {
  type    = string
  default = "60m"
}
