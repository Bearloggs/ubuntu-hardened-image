# Ubuntu hardened image — Packer build helpers
# Usage: make help

.DEFAULT_GOAL := help

REPO_ROOT          := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
PACKER_BIN         ?= packer
PLATFORMS          := aws qemu proxmox vmware virtualbox
KEY_PLATFORMS      := qemu proxmox vmware virtualbox
PACKER_EXTRA_ARGS  ?=
LOCAL_PKRVARS      := $(REPO_ROOT)/packer/local.pkrvars.hcl
LOCAL_PKRVARS_EX   := $(REPO_ROOT)/packer/local.pkrvars.hcl.example
BUILD_KEY          := $(REPO_ROOT)/packer/build-key
IDENTITY_HASH      := $(REPO_ROOT)/cloud-init/nocloud/.identity-password-hash
INSTANCE_LOCAL     := $(REPO_ROOT)/cloud-init/instance.local.yaml
INSTANCE_EXAMPLE   := $(REPO_ROOT)/cloud-init/instance.example.yaml

platform_dir = $(REPO_ROOT)/packer/$(1)

.PHONY: help vars clean build-key sync-instance-key
.PHONY: $(foreach p,$(PLATFORMS),init-$(p) build-$(p) build-$(p)-debug validate-$(p))

help:
	@echo "Ubuntu hardened image — common targets"
	@echo ""
	@echo "  make vars                     Copy packer/local.pkrvars.hcl.example if missing"
	@echo "  make init-<platform>          packer init in packer/<platform>/"
	@echo "  make build-<platform>         vars + keys + packer build"
	@echo "  make build-<platform>-debug   Same, with -on-error=ask"
	@echo "  make validate-<platform>      packer validate"
	@echo "  make build-key                Generate packer/build-key (auto-run by build if missing)"
	@echo "  make sync-instance-key        Copy build-key.pub into instance.local.yaml"
	@echo "  make clean                    Remove packer caches, outputs, manifests"
	@echo ""
	@echo "Operator files (gitignored): packer/local.pkrvars.hcl, packer/build-key,"
	@echo "  cloud-init/instance.local.yaml"
	@echo ""
	@echo "Platforms: $(PLATFORMS)"
	@echo ""
	@echo "Example: make vars && \$$EDITOR packer/local.pkrvars.hcl && make build-proxmox"

vars:
	@if [ ! -f '$(LOCAL_PKRVARS)' ]; then \
		cp '$(LOCAL_PKRVARS_EX)' '$(LOCAL_PKRVARS)'; \
		echo 'Created $(LOCAL_PKRVARS) — edit before building.'; \
	else echo 'Vars file already exists: $(LOCAL_PKRVARS)'; fi

define platform_init_recipe
init-$(1):
	@cd '$(call platform_dir,$(1))' && $(PACKER_BIN) init .
endef
$(foreach p,$(PLATFORMS),$(eval $(call platform_init_recipe,$(p))))

define ensure_autoinstall_password_hash
	@openssl passwd -6 -salt "$$(openssl rand -hex 4)" locked > '$(IDENTITY_HASH)'; \
	echo '==> Autoinstall identity hash (gitignored): cloud-init/nocloud/.identity-password-hash'
endef

define ensure_build_key
	@if [ -f '$(BUILD_KEY)' ] && [ -f '$(BUILD_KEY).pub' ]; then \
		echo '==> Build SSH key present: $(BUILD_KEY)'; \
	elif [ -e '$(BUILD_KEY)' ] || [ -e '$(BUILD_KEY).pub' ]; then \
		echo 'ERROR: incomplete key pair (need packer/build-key and packer/build-key.pub)'; exit 1; \
	else \
		echo '==> Generating $(BUILD_KEY) (ed25519)...'; \
		ssh-keygen -t ed25519 -N "" -f '$(BUILD_KEY)'; \
	fi
endef

define platform_validate_recipe
validate-$(1): vars
	$(call ensure_autoinstall_password_hash)
	$(if $(filter $(1),$(KEY_PLATFORMS)),$(call ensure_build_key))
	@cd '$(call platform_dir,$(1))' && \
	$(PACKER_BIN) validate -var-file='$(LOCAL_PKRVARS)' .
endef
$(foreach p,$(PLATFORMS),$(eval $(call platform_validate_recipe,$(p))))

define platform_build_recipe
build-$(1): init-$(1) vars
	$(call ensure_autoinstall_password_hash)
	$(if $(filter $(1),$(KEY_PLATFORMS)),$(call ensure_build_key))
	@cd '$(call platform_dir,$(1))' && \
	$(PACKER_BIN) build $(PACKER_EXTRA_ARGS) -var-file='$(LOCAL_PKRVARS)' .
endef
$(foreach p,$(PLATFORMS),$(eval $(call platform_build_recipe,$(p))))

define platform_build_debug_recipe
build-$(1)-debug: init-$(1) vars
	$(call ensure_autoinstall_password_hash)
	$(if $(filter $(1),$(KEY_PLATFORMS)),$(call ensure_build_key))
	@cd '$(call platform_dir,$(1))' && \
	$(PACKER_BIN) build -on-error=ask $(PACKER_EXTRA_ARGS) -var-file='$(LOCAL_PKRVARS)' .
endef
$(foreach p,$(PLATFORMS),$(eval $(call platform_build_debug_recipe,$(p))))

build-key:
	$(call ensure_build_key)

sync-instance-key: build-key
	@if [ ! -f '$(INSTANCE_LOCAL)' ]; then \
		cp '$(INSTANCE_EXAMPLE)' '$(INSTANCE_LOCAL)'; \
		echo 'Created $(INSTANCE_LOCAL) from example.'; \
	fi
	@pub=$$(cat '$(BUILD_KEY).pub'); \
	if grep -q 'ssh_authorized_keys:' '$(INSTANCE_LOCAL)'; then \
		awk -v pub="$$pub" 'BEGIN { inkeys=0 } \
			/^ssh_authorized_keys:/ { print; print "  - " pub; inkeys=1; next } \
			inkeys && /^  - / { next } \
			inkeys && /^[^ #]/ { inkeys=0 } \
			{ print }' '$(INSTANCE_LOCAL)' > '$(INSTANCE_LOCAL).tmp' && \
		mv '$(INSTANCE_LOCAL).tmp' '$(INSTANCE_LOCAL)'; \
	else \
		printf '\nssh_authorized_keys:\n  - %s\n' "$$pub" >> '$(INSTANCE_LOCAL)'; \
	fi
	@echo '==> Updated ssh_authorized_keys in $(INSTANCE_LOCAL) from packer/build-key.pub'

clean:
	rm -rf packer_cache crash.log packer-manifest*.json
	@for p in $(PLATFORMS); do \
		rm -rf "$(REPO_ROOT)/packer/$$p/packer_cache" \
			"$(REPO_ROOT)/packer/$$p"/output-* 2>/dev/null || true; \
	done
	@echo "Cleaned packer caches, output-* dirs, and manifest files."
