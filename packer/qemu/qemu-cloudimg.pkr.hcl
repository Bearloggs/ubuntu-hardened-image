locals {
  qemu_build_ssh_public_key = trimspace(file("${local.build_ssh_key_path}.pub"))
  qemu_nocloud_cd_content = {
    "meta-data" = local.packer_nocloud_meta_data
    "user-data" = templatefile("${local.cloud_init_nocloud_dir}/user-data-cloudimg.pkrtpl.yml", {
      ssh_public_key = local.qemu_build_ssh_public_key
    })
  }
}

source "qemu" "ubuntu_hardened_qemu" {
  disk_image     = true
  iso_url        = var.qemu_cloudimg_url
  iso_checksum   = var.qemu_cloudimg_checksum
  disk_size      = "${var.qemu_disk_size}G"
  format         = "qcow2"
  headless       = var.qemu_headless
  accelerator    = var.qemu_accelerator
  net_device     = "virtio-net"
  disk_interface = "virtio"
  machine_type   = "q35"

  memory = var.build_memory_mb
  cpus   = var.build_cpus

  vm_name          = "${var.ami_name}-${var.ubuntu_version}-${formatdate("YYYY-MM-DD", timestamp())}.qcow2"
  output_directory = "${local.repo_root}/${var.qemu_output_dir}"

  ssh_username            = var.build_ssh_username
  ssh_private_key_file    = local.build_ssh_key_path
  ssh_timeout             = "30m"
  ssh_pty                 = true
  ssh_keep_alive_interval = "15s"

  shutdown_command = "sudo shutdown -P now"

  cd_label   = "cidata"
  cd_content = local.qemu_nocloud_cd_content
}

build {
  sources = ["source.qemu.ubuntu_hardened_qemu"]

  provisioner "file" {
    source      = "${local.repo_root}/scripts"
    destination = "/tmp/scripts"
  }

  provisioner "shell" {
    environment_vars = local.provision_env
    inline           = ["bash /tmp/scripts/base/packer-run-provisioners.sh"]
  }

  provisioner "shell" {
    environment_vars = local.provision_env
    inline           = ["bash /tmp/scripts/platform/qemu.sh"]
  }

  provisioner "shell" {
    environment_vars = local.cleanup_env
    inline           = ["bash /tmp/scripts/base/99-cleanup.sh"]
  }

  post-processor "manifest" {
    output     = "${local.repo_root}/packer-manifest-qemu.json"
    strip_path = true
  }
}
