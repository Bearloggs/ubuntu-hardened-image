source "virtualbox-iso" "ubuntu_hardened_virtualbox" {
  iso_url      = var.iso_url
  iso_checksum = var.iso_checksum
  disk_size    = var.vm_disk_size_mb
  headless     = true

  memory = var.build_memory_mb
  cpus   = var.build_cpus

  vm_name          = "${var.ami_name}-${var.ubuntu_version}-${formatdate("YYYY-MM-DD", timestamp())}"
  output_directory = "${local.repo_root}/output-virtualbox"

  ssh_username         = var.build_ssh_username
  ssh_private_key_file = local.build_ssh_key_path
  ssh_timeout          = "30m"
  ssh_pty      = true

  shutdown_command = "sudo shutdown -P now"

  guest_os_type = "Ubuntu_64"

  boot_command = [
    "e<down><down><down><end>",
    " autoinstall ds=nocloud-net;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/",
    "<f10>"
  ]
  http_content = local.packer_nocloud_http_content
}

build {
  sources = ["source.virtualbox-iso.ubuntu_hardened_virtualbox"]

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
    inline           = ["bash /tmp/scripts/platform/virtualbox.sh"]
  }

  provisioner "shell" {
    environment_vars = local.cleanup_env
    inline           = ["bash /tmp/scripts/base/99-cleanup.sh"]
  }

  post-processor "manifest" {
    output     = "${local.repo_root}/packer-manifest-virtualbox.json"
    strip_path = true
  }
}
