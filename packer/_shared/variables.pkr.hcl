variable "aws_region" {
  type        = string
  description = "AWS region for the build and resulting AMI (also used for SSM agent deb URL)."
  default     = "eu-west-1"
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type used during the Packer build."
  default     = "t3.micro"
}

variable "ubuntu_version" {
  type        = string
  description = "Ubuntu LTS series (used for naming and documentation)."
  default     = "24.04"
}

variable "ami_name" {
  type        = string
  description = "Prefix for the generated AMI name."
  default     = "ubuntu-hardened"
}

variable "root_volume_size" {
  type        = number
  description = "Root EBS volume size in GB."
  default     = 20
}

variable "install_ssm_agent" {
  type        = bool
  description = "If false, skip SSM agent install. If true, use ssm_install_method (deb or snap)."
  default     = true
}

variable "clear_cloudinit_sudoers" {
  type        = bool
  description = "If true, remove /etc/sudoers.d/90-cloud-init-users during cleanup (use with caution)."
  default     = false
}

variable "ssm_install_method" {
  type        = string
  description = "How to install SSM agent when install_ssm_agent is true: deb (default), snap, or none."
  default     = "deb"
  validation {
    condition     = contains(["deb", "snap", "none"], var.ssm_install_method)
    error_message = "The ssm_install_method must be set to deb, snap, or none."
  }
}

variable "harden_fstab" {
  type        = bool
  description = "Apply guarded fstab hardening (/dev/shm tmpfs and separate ext partitions if present)."
  default     = true
}

variable "harden_grub" {
  type        = bool
  description = "Append kernel cmdline (apparmor, audit, lockdown) and run update-grub once."
  default     = true
}

variable "harden_systemd_services" {
  type        = bool
  description = "Apply systemd sandbox drop-in for ssh."
  default     = true
}

variable "harden_modules" {
  type        = bool
  description = "Install CIS-style modprobe blacklist and update-initramfs."
  default     = true
}

variable "enable_apparmor" {
  type        = bool
  description = "Install AppArmor packages and enforce selected profiles."
  default     = true
}

variable "install_aide" {
  type        = bool
  description = "Install AIDE, exclusions, and aide-check.timer."
  default     = true
}

variable "initialize_aide" {
  type        = bool
  description = "Run aideinit (slow). Prefer true only on workflow_dispatch or production builds."
  default     = false
}

variable "ami_regions" {
  type        = list(string)
  description = "Optional list of regions to copy the AMI to after build."
  default     = []
}

variable "ami_users" {
  type        = list(string)
  description = "Optional list of AWS account IDs allowed to launch the AMI."
  default     = []
}

variable "build_memory_mb" {
  type        = number
  description = "RAM in MiB allocated to the build VM (all non-AWS builders)."
  default     = 4096
}

variable "build_cpus" {
  type        = number
  description = "vCPUs allocated to the build VM (all non-AWS builders)."
  default     = 2
}

variable "cloud_init_instance_id" {
  type        = string
  description = "NoCloud instance-id served during Packer builds."
  default     = "iid-packer-ubuntu-hardened"
}

variable "cloud_init_hostname" {
  type        = string
  description = "Hostname in NoCloud meta-data during Packer builds."
  default     = "packer-ubuntu-hardened"
}

variable "build_ssh_username" {
  type        = string
  description = "OS user for Packer SSH and autoinstall identity."
  default     = "ubuntu"
}

variable "build_ssh_private_key_path" {
  type        = string
  description = "SSH private key for Packer builds (NoCloud / autoinstall). Default: packer/build-key."
  default     = ""
}

variable "qemu_cloudimg_url" {
  type        = string
  description = "Ubuntu Noble amd64 cloud image (qcow2) URL."
  default     = "https://cloud-images.ubuntu.com/releases/noble/release/ubuntu-24.04-server-cloudimg-amd64.img"
}

variable "qemu_cloudimg_checksum" {
  type        = string
  description = "Checksum for qemu_cloudimg_url; use file:URL to upstream SHA256SUMS."
  default     = "file:https://cloud-images.ubuntu.com/releases/noble/release/SHA256SUMS"
}

variable "qemu_disk_size" {
  type        = number
  description = "Expanded root disk size in GB for the output qcow2."
  default     = 20
}

variable "qemu_output_dir" {
  type        = string
  description = "Directory for the output qcow2 (created by Packer)."
  default     = "output-qemu"
}

variable "qemu_headless" {
  type        = bool
  description = "Run QEMU without a display."
  default     = true
}

variable "qemu_accelerator" {
  type        = string
  description = "QEMU accelerator: kvm (Linux with /dev/kvm), tcg (slow, nested VMs), hvf (macOS)."
  default     = "kvm"
}

variable "iso_url" {
  type        = string
  description = "Ubuntu Noble amd64 live-server ISO URL (shared by VMware, VirtualBox and Proxmox builders)."
  default     = "https://releases.ubuntu.com/noble/ubuntu-24.04.4-live-server-amd64.iso"
}

variable "iso_checksum" {
  type        = string
  description = "SHA256 checksum for iso_url."
  default     = "sha256:e907d92eeec9df64163a7e454cbc8d7755e8ddc7ed42f99dbc80c40f1a138433"
}

variable "vm_disk_size_mb" {
  type        = number
  description = "Disk size in MB for ISO-based build VMs (VMware, VirtualBox, Proxmox)."
  default     = 20480
}

variable "vmware_network_adapter_type" {
  type        = string
  description = "VMware network adapter type: vmxnet3, e1000e, or e1000."
  default     = "vmxnet3"
}

variable "proxmox_url" {
  type        = string
  description = "Proxmox API URL (e.g. https://proxmox.local:8006/api2/json)."
  default     = ""
}

variable "proxmox_username" {
  type        = string
  description = "Proxmox API username."
  default     = "root@pam"
}

variable "proxmox_password" {
  type        = string
  description = "Proxmox API password."
  default     = ""
  sensitive   = true
}

variable "proxmox_node" {
  type        = string
  description = "Proxmox node name."
  default     = "pve"
}

variable "proxmox_iso_storage_pool" {
  type        = string
  description = "Proxmox storage pool where the ISO will be stored (e.g. local, local-lvm)."
  default     = "local"
}

variable "proxmox_insecure_skip_tls_verify" {
  type        = bool
  description = "Skip TLS certificate verification for the Proxmox API (self-signed or hostname mismatch)."
  default     = false
}
