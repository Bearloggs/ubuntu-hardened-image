#!/bin/bash
# Amazon SSM Agent: deb (default), snap, or none. Region from AWS_DEFAULT_REGION.
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
export HISTSIZE=0
export HISTFILESIZE=0

METHOD="${SSM_INSTALL_METHOD:-deb}"

if [[ "${INSTALL_SSM_AGENT:-true}" != "true" ]] || [[ "${METHOD}" == "none" ]]; then
  echo "    Skipping SSM agent (INSTALL_SSM_AGENT=${INSTALL_SSM_AGENT:-true}, SSM_INSTALL_METHOD=${METHOD})"
  exit 0
fi

REGION="${AWS_DEFAULT_REGION:-${EC2_REGION:-us-east-1}}"
URL="https://s3.${REGION}.amazonaws.com/amazon-ssm-${REGION}/latest/debian_amd64/amazon-ssm-agent.deb"

if [[ "${METHOD}" == "deb" ]]; then
  echo "==> Installing Amazon SSM Agent (deb) from ${URL}..."
  sudo apt-get update -y
  sudo apt-get install -y curl
  curl -fsSL "${URL}" -o /tmp/amazon-ssm-agent.deb
  sudo dpkg -i /tmp/amazon-ssm-agent.deb || sudo apt-get install -f -y
  rm -f /tmp/amazon-ssm-agent.deb
  sudo systemctl enable amazon-ssm-agent
  sudo systemctl restart amazon-ssm-agent || sudo systemctl start amazon-ssm-agent || true
elif [[ "${METHOD}" == "snap" ]]; then
  echo "==> Installing Amazon SSM Agent (snap)..."
  sudo apt-get update -y
  sudo apt-get install -y snapd
  sudo systemctl enable --now snapd
  sudo snap install amazon-ssm-agent --classic
  sudo snap start amazon-ssm-agent || true
  sudo systemctl enable --now snap.amazon-ssm-agent.amazon-ssm-agent.service 2>/dev/null || true
  sudo systemctl restart snap.amazon-ssm-agent.amazon-ssm-agent.service 2>/dev/null || true
else
  echo "    Unknown SSM_INSTALL_METHOD=${METHOD}; skipping."
  exit 0
fi

echo "==> SSM agent install complete."
