#!/bin/bash
set -euo pipefail

echo "==> Waiting for cloud-init to finish..."
sudo cloud-init status --wait
echo "==> cloud-init finished."
