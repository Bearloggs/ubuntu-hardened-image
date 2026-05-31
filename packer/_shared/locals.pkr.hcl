locals {
  repo_root = abspath("${path.root}/../..")

  provision_env = [
    "DEBIAN_FRONTEND=noninteractive",
    "BUILD_SSH_USERNAME=${var.build_ssh_username}",
    "AWS_DEFAULT_REGION=${var.aws_region}",
    "HARDEN_MODULES=${var.harden_modules ? "true" : "false"}",
    "ENABLE_APPARMOR=${var.enable_apparmor ? "true" : "false"}",
    "HARDEN_GRUB=${var.harden_grub ? "true" : "false"}",
    "HARDEN_SYSTEMD_SERVICES=${var.harden_systemd_services ? "true" : "false"}",
    "INSTALL_AIDE=${var.install_aide ? "true" : "false"}",
    "INITIALIZE_AIDE=${var.initialize_aide ? "true" : "false"}",
    "INSTALL_SSM_AGENT=${var.install_ssm_agent ? "true" : "false"}",
    "SSM_INSTALL_METHOD=${var.ssm_install_method}",
    "HARDEN_FSTAB=${var.harden_fstab ? "true" : "false"}",
  ]

  cleanup_env = concat(local.provision_env, [
    "CLEAR_CLOUDINIT_SUDOERS=${var.clear_cloudinit_sudoers ? "true" : "false"}",
  ])
}
