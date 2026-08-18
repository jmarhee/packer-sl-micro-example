# SLE Micro 6.x QEMU builder — bake sshd password-auth off into a golden disk.
# Defaults to the Base qcow2 in ../base-images (first-boot image, not SelfInstall).

packer {
  required_version = ">= 1.9.0"

  required_plugins {
    qemu = {
      version = ">= 1.1.0"
      source  = "github.com/hashicorp/qemu"
    }
  }
}

locals {
  install_media = var.install_media != "" ? var.install_media : abspath("${path.root}/../base-images/SL-Micro.x86_64-6.2-Base-qcow-GM.qcow2")
}

source "qemu" "sle_micro" {
  iso_url      = local.install_media
  iso_checksum = var.install_media_checksum
  disk_image   = var.install_media_is_disk
  qemu_binary  = var.qemu_binary

  vm_name           = "${var.output_name}.${var.output_format == "raw" ? "raw" : "qcow2"}"
  output_directory  = "${path.root}/output/${var.output_name}"
  format            = var.output_format
  disk_size         = var.disk_size_mb
  disk_interface    = "virtio"
  net_device        = "virtio-net"
  accelerator       = var.accelerator
  headless          = var.headless
  memory            = var.memory_mb
  cpus              = var.cpus
  machine_type      = var.machine_type
  efi_boot          = true
  efi_firmware_code = var.efi_firmware_code
  efi_firmware_vars = var.efi_firmware_vars

  # Ignition via fw_cfg (preferred) and a CD labeled "ignition".
  # Combustion is omitted: its t-u wrapper rolls back a successful script
  # when /dev/shm/combustion/retval is not visible across tukit's mount ns.
  communicator = "none"
  cd_label     = "ignition"
  cd_content = {
    "/ignition/config.ign" = file("${path.root}/ignition/config.ign")
  }

  # Base qcow2 already runs first-boot on its own; do not send KIWI SelfInstall keys.
  boot_wait    = "5s"
  boot_command = var.boot_command

  shutdown_timeout = var.build_shutdown_timeout

  # -cpu max: SLE Micro 6 userspace needs x86-64-v2 (SSE4.1+). TCG's default qemu64 panics in init.
  qemuargs = [
    ["-cpu", "max"],
    ["-serial", "file:${path.root}/qemu-serial.log"],
    ["-fw_cfg", "name=opt/com.coreos/config,file=${abspath("${path.root}/ignition/config.ign")}"],
  ]
}

build {
  name    = "sle-micro-sshd-hardening"
  sources = ["source.qemu.sle_micro"]
}
