locals {
  cloud_init_nocloud_dir = "${local.repo_root}/cloud-init/nocloud"

  build_ssh_key_path   = var.build_ssh_private_key_path != "" ? abspath(pathexpand(var.build_ssh_private_key_path)) : "${local.repo_root}/packer/build-key"
  build_ssh_public_key = trimspace(file("${local.build_ssh_key_path}.pub"))

  autoinstall_identity_password_hash = trimspace(file("${local.cloud_init_nocloud_dir}/.identity-password-hash"))

  packer_nocloud_meta_data = templatefile("${local.cloud_init_nocloud_dir}/meta-data.pkrtpl.yml", {
    instance_id = var.cloud_init_instance_id
    hostname    = var.cloud_init_hostname
  })

  packer_nocloud_user_data_cloudimg = templatefile("${local.cloud_init_nocloud_dir}/user-data-cloudimg.pkrtpl.yml", {
    ssh_public_key = local.build_ssh_public_key
  })

  packer_nocloud_user_data_autoinstall = templatefile("${local.cloud_init_nocloud_dir}/user-data-autoinstall.pkrtpl.yml", {
    hostname                = var.cloud_init_hostname
    username                = var.build_ssh_username
    ssh_public_key          = local.build_ssh_public_key
    identity_password_hash  = local.autoinstall_identity_password_hash
  })

  packer_nocloud_http_content = {
    "meta-data" = local.packer_nocloud_meta_data
    "user-data" = local.packer_nocloud_user_data_autoinstall
  }

  packer_nocloud_cd_content = {
    "meta-data" = local.packer_nocloud_meta_data
    "user-data" = local.packer_nocloud_user_data_cloudimg
  }
}
