# 🌌 setupscripties

Automation scripts for infrastructure setup and configuration.

## 📋 Project Overview

This repository contains utility scripts designed to automate the deployment and configuration of various infrastructure components. The primary focus is currently on **Nebula**, a scalable overlay networking tool.

## 🚀 Key Scripts

### `join-nebula.sh`
A robust Bash script that automates the process of joining a Linux host to a Nebula mesh network.

**Capabilities:**
- **Installation:** Downloads and installs the latest Nebula and `nebula-cert` binaries.
- **Cleanup:** Removes existing Nebula installations, services, and network interfaces to ensure a clean state.
- **Provisioning:** Connects to a remote VPS via SSH to register the node and retrieve signed certificates.
- **Configuration:** Generates an optimized `config.yml` for the node, including firewall rules and static host maps.
- **Persistence:** Sets up and enables a `systemd` service (`nebula.service`) to ensure the mesh network starts on boot and restarts on failure.
- **Validation:** Provides commands to verify the connection via IP and DNS.

## 🛠 Usage

To join the Nebula mesh:

```bash
chmod +x join-nebula.sh
./join-nebula.sh
```

**Requirements:**
- **Linux OS** with `systemd` (preferred).
- **sudo** privileges.
- **SSH access** to the lighthouse VPS (configured in the script).
- `curl`, `tar`, and `ssh` installed on the host.

## ⚙️ Configuration Variables

The following variables in `join-nebula.sh` define the mesh environment:

- `VPS_IP`: The public IP of the Nebula lighthouse/CA server.
- `VPS_USER`: The SSH username for the VPS.
- `LIGHTHOUSE_IP`: The internal Nebula IP of the lighthouse.
- `NEBULA_PORT`: The UDP port used for Nebula communication (default: `4242`).

---
*This file was generated to provide context for AI-assisted development and operations.*
