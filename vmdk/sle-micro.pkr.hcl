# SLE Micro 6.x QEMU builder — bake sshd password-auth off, emit a VMDK.
# Source is the VMware GM VMDK in ../base-images. Packer's QEMU builder only
# writes qcow2/raw, so a shell-local post-processor converts to VMDK.
# Untested on VMware; same first-boot Ignition path as examples/packer/qcow2.

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
  install_media = var.install_media != "" ? var.install_media : abspath("${path.root}/../base-images/SL-Micro.x86_64-6.2-Base-VMware-GM.vmdk")
  qcow2_path    = "${path.root}/output/${var.output_name}/${var.output_name}.qcow2"
  vmdk_path     = "${path.root}/output/${var.output_name}/${var.output_name}.vmdk"
}

source "qemu" "sle_micro" {
  iso_url      = local.install_media
  iso_checksum = var.install_media_checksum
  disk_image   = var.install_media_is_disk
  qemu_binary  = var.qemu_binary

  vm_name           = "${var.output_name}.qcow2"
  output_directory  = "${path.root}/output/${var.output_name}"
  format            = "qcow2"
  disk_size         = var.disk_size_mb
  disk_interface    = var.disk_interface
  net_device        = var.net_device
  accelerator       = var.accelerator
  headless          = var.headless
  memory            = var.memory_mb
  cpus              = var.cpus
  machine_type      = var.machine_type
  efi_boot          = true
  efi_firmware_code = var.efi_firmware_code
  efi_firmware_vars = var.efi_firmware_vars

  communicator = "none"
  cd_label     = "ignition"
  cd_content = {
    "/ignition/config.ign" = file("${path.root}/ignition/config.ign")
  }

  boot_wait    = "5s"
  boot_command = var.boot_command

  shutdown_timeout = var.build_shutdown_timeout

  qemuargs = [
    ["-cpu", "max"],
    ["-serial", "file:${path.root}/qemu-serial.log"],
    ["-fw_cfg", "name=opt/com.coreos/config,file=${abspath("${path.root}/ignition/config.ign")}"],
  ]
}

build {
  name    = "sle-micro-sshd-hardening-vmdk"
  sources = ["source.qemu.sle_micro"]

  # QEMU builder cannot emit vmdk. Convert the baked qcow2 to a single-file
  # sparse VMDK matching the GM image's create type (monolithicSparse).
  post-processor "shell-local" {
    inline = [
      "qemu-img convert -p -f qcow2 -O vmdk -o subformat=monolithicSparse ${local.qcow2_path} ${local.vmdk_path}",
    ]
  }
}
