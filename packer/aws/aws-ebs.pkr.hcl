source "amazon-ebs" "ubuntu_hardened_aws" {
  region        = var.aws_region
  instance_type = var.instance_type

  source_ami_filter {
    filters = {
      name                = "ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["099720109477"]
  }
  ssh_username              = "ubuntu"
  ssh_clear_authorized_keys = true
  temporary_key_pair_type   = "ed25519"
  ssh_timeout               = "10m"
  ssh_pty                   = true
  ssh_keep_alive_interval   = "15s"

  ami_name        = "${var.ami_name}-${var.ubuntu_version}-${formatdate("YYYY-MM-DD", timestamp())}"
  ami_description = "Ubuntu ${var.ubuntu_version} hardened baseline (CIS-oriented controls)"

  ami_regions = var.ami_regions
  ami_users   = var.ami_users

  tags = {
    Name      = "${var.ami_name}-${var.ubuntu_version}"
    OS        = "Ubuntu"
    Version   = var.ubuntu_version
    Hardened  = "true"
    CIS_Level = "oriented"
    BuildDate = formatdate("YYYY-MM-DD", timestamp())
  }

  launch_block_device_mappings {
    device_name           = "/dev/sda1"
    volume_size           = var.root_volume_size
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }
}

build {
  sources = ["source.amazon-ebs.ubuntu_hardened_aws"]

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
    inline           = ["bash /tmp/scripts/platform/aws.sh"]
  }

  provisioner "shell" {
    environment_vars = local.cleanup_env
    inline           = ["bash /tmp/scripts/base/99-cleanup.sh"]
  }

  post-processor "manifest" {
    output     = "${local.repo_root}/packer-manifest-aws.json"
    strip_path = true
  }
}
