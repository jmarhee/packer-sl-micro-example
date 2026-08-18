# Override with -var or a .pkrvars.hcl file.

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
  description = "QEMU accelerator. tcg is required to run this x86_64 image on Apple Silicon. Use kvm on an x86_64 Linux host."
}

variable "qemu_binary" {
  type        = string
  default     = "qemu-system-x86_64"
  description = "QEMU binary. Must match the guest architecture of the VMDK (x86_64)."
}

variable "efi_firmware_code" {
  type        = string
  default     = "/opt/homebrew/share/qemu/edk2-x86_64-code.fd"
  description = "OVMF code pflash. Do not pass this via -bios; QEMU 11 cannot load the 4MiB Homebrew firmware that way."
}

variable "efi_firmware_vars" {
  type        = string
  default     = "/opt/homebrew/share/qemu/edk2-i386-vars.fd"
  description = "OVMF vars template. Homebrew pairs this with edk2-x86_64-code.fd."
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
