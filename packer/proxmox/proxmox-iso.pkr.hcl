source "proxmox-iso" "ubuntu_hardened_proxmox" {
  proxmox_url              = var.proxmox_url
  username                 = var.proxmox_username
  password                 = var.proxmox_password
  node                     = var.proxmox_node
  insecure_skip_tls_verify = var.proxmox_insecure_skip_tls_verify

  boot_iso {
    iso_url          = var.iso_url
    iso_checksum     = var.iso_checksum
    iso_storage_pool = var.proxmox_iso_storage_pool
    unmount          = true
  }

  memory = var.build_memory_mb
  cores  = var.build_cpus

  vm_name = "${var.ami_name}-${var.ubuntu_version}-${formatdate("YYYY-MM-DD", timestamp())}"

  ssh_username         = var.build_ssh_username
  ssh_private_key_file = local.build_ssh_key_path
  ssh_timeout          = "30m"
  ssh_pty      = true

  boot_command = [
    "e<down><down><down><end>",
    " autoinstall ds=nocloud-net;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/",
    "<f10>"
  ]
  http_content = local.packer_nocloud_http_content
}

build {
  sources = ["source.proxmox-iso.ubuntu_hardened_proxmox"]

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
    inline           = ["bash /tmp/scripts/platform/proxmox.sh"]
  }

  provisioner "shell" {
    environment_vars = local.cleanup_env
    inline           = ["bash /tmp/scripts/base/99-cleanup.sh"]
  }

  post-processor "manifest" {
    output     = "${local.repo_root}/packer-manifest-proxmox.json"
    strip_path = true
  }
}
