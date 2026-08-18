# Bake golden SLE Micro images, or smoke-test the qcow2 artifact.
#
#   make qcow2
#   make vmdk
#   make test          # boot qcow2 output, SSH, cat /etc/os-release
#
# Extra Packer vars:  make qcow2 PACKER_ARGS='-var accelerator=kvm'

export PATH := /opt/homebrew/bin:$(PATH)

PACKER      ?= packer
QEMU        ?= qemu-system-x86_64
QEMU_IMG    ?= qemu-img
PACKER_ARGS ?=

OUTPUT_NAME ?= sle-micro-sshd-hardening
ROOT        := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
QCOW2_OUT   := $(ROOT)/qcow2/output/$(OUTPUT_NAME)/$(OUTPUT_NAME).qcow2
VMDK_OUT    := $(ROOT)/vmdk/output/$(OUTPUT_NAME)/$(OUTPUT_NAME).vmdk

ACCEL       ?= tcg
MEMORY_MB   ?= 2048
CPUS        ?= 2
SSH_PORT    ?= 2222
SSH_KEY     ?= $(HOME)/.ssh/id_rsa
EFI_CODE    ?= /opt/homebrew/share/qemu/edk2-x86_64-code.fd
EFI_VARS    ?= /opt/homebrew/share/qemu/edk2-i386-vars.fd
TEST_DIR    ?= /tmp/sle-micro-packer-test
SSH_OPTS    := -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=5 -o BatchMode=yes

.PHONY: help qcow2 vmdk test

help:
	@echo "make qcow2  Bake golden qcow2"
	@echo "make vmdk   Bake golden VMDK"
	@echo "make test   Boot qcow2 output in QEMU and print /etc/os-release"

qcow2:
	cd $(ROOT)/qcow2 && $(PACKER) init .
	cd $(ROOT)/qcow2 && $(PACKER) build -force -var qemu_binary=$(QEMU) $(PACKER_ARGS) .

vmdk:
	cd $(ROOT)/vmdk && $(PACKER) init .
	cd $(ROOT)/vmdk && $(PACKER) build -force -var qemu_binary=$(QEMU) $(PACKER_ARGS) .

test:
	@test -f "$(QCOW2_OUT)" || { echo "missing $(QCOW2_OUT); run make qcow2 first"; exit 1; }
	@test -f "$(EFI_CODE)" || { echo "missing EFI code: $(EFI_CODE)"; exit 1; }
	@test -f "$(EFI_VARS)" || { echo "missing EFI vars: $(EFI_VARS)"; exit 1; }
	rm -rf "$(TEST_DIR)"
	mkdir -p "$(TEST_DIR)"
	cp "$(EFI_VARS)" "$(TEST_DIR)/efivars.fd"
	$(QEMU_IMG) create -f qcow2 -b "$(QCOW2_OUT)" -F qcow2 "$(TEST_DIR)/overlay.qcow2"
	$(QEMU) \
	  -machine q35,accel=$(ACCEL) \
	  -cpu max \
	  -m $(MEMORY_MB) \
	  -smp $(CPUS) \
	  -drive if=pflash,format=raw,readonly=on,file=$(EFI_CODE) \
	  -drive if=pflash,format=raw,file=$(TEST_DIR)/efivars.fd \
	  -drive file=$(TEST_DIR)/overlay.qcow2,if=virtio,format=qcow2 \
	  -netdev user,id=net0,hostfwd=tcp::$(SSH_PORT)-:22 \
	  -device virtio-net-pci,netdev=net0 \
	  -display none \
	  -serial file:$(TEST_DIR)/serial.log \
	  -pidfile $(TEST_DIR)/qemu.pid \
	  -daemonize
	@i=0; \
	trap 'kill $$(cat "$(TEST_DIR)/qemu.pid") 2>/dev/null || true' EXIT; \
	echo "Waiting for SSH on 127.0.0.1:$(SSH_PORT) ..."; \
	until ssh $(SSH_OPTS) -i "$(SSH_KEY)" -p "$(SSH_PORT)" root@127.0.0.1 true; do \
	  i=$$((i + 1)); \
	  if [ $$i -ge 120 ]; then \
	    echo "SSH did not come up; last serial output:"; \
	    tail -n 80 "$(TEST_DIR)/serial.log" || true; \
	    exit 1; \
	  fi; \
	  sleep 5; \
	done; \
	ssh $(SSH_OPTS) -i "$(SSH_KEY)" -p "$(SSH_PORT)" root@127.0.0.1 'cat /etc/os-release'
