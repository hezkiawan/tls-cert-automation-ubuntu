# Zero-Trust ACME Provisioning Architecture

This repository demonstrates a fully automated, zero-touch SSL/TLS provisioning pipeline using the ACME protocol. It serves as a Proof of Concept (PoC) to prove that manual certificate management can be entirely eliminated across internal infrastructure, seamlessly bridging local simulations with enterprise-grade CA integrations (e.g., Sectigo).

## 🏗️ Repository Architecture

This project is separated into two distinct environments to demonstrate both the isolated testing mechanics and the real-world deployment strategy.

```text
zero-trust-acme-poc/
├── 1-local-simulator/ # The active Proof of Concept (Docker + Pebble)
│ ├── docker-compose.yml # Containerized ACME server with DNS host-gateway overrides
│ ├── setup-trust.sh # Injects the private CA into the OS trust store
│ └── deploy-cert.sh # Executes the zero-touch Certbot provisioner
├── 2-production-reference/ # Enterprise Deployment Artifacts
│ └── cloud-init-setup.sh # Automated VM startup script (Terraform ready)
└── README.md # Architecture and execution runbook

🛠️ Phase 1: Local Simulation (The PoC)
The 1-local-simulator directory contains a self-contained Docker environment using Pebble (Let's Encrypt's development CA). This simulation proves the complex network routing, DNS overrides, and custom CA trust injections required to provision certificates inside an isolated, air-gapped network.

Prerequisites
Ubuntu Linux Environment
Docker & Docker Compose
Standard build tools (curl, bash)
Execution Runbook
1. Initialize the Certificate Authority

Spin up the isolated ACME server and its internal HTTPS API.

Bash 
cd 1-local-simulator
sudo docker compose up -d

2. Establish the Trust Bridge

Because the local CA is private, the host OS does not trust it by default. This script downloads the CA's root management certificate and explicitly injects it into the Ubuntu trust store, allowing Certbot to establish a secure handshake.

Bash 
./setup-trust.sh

3. Execute Zero-Touch Provisioning

This script triggers Certbot to bypass interactive prompts, request a certificate for app.local.com, automatically temporarily reconfigure NGINX to answer the ACME challenge on port 5002, and deploy the resulting cryptographic keys.

Bash 
./deploy-cert.sh

4. Verification

Ping the local web server, ignoring OS trust warnings, to verify the web server is successfully returning the 200 OK header over port 443.

Bash 
curl -kI https://localhost

🚀 Phase 2: Production Deployment Strategy
The 2-production-reference directory demonstrates how the logic validated in Phase 1 scales to a live cloud environment using Infrastructure as Code (IaC).

In a live production environment using a commercial CA like Sectigo, manual execution is replaced by automated VM provisioning.

The Terraform Pipeline
The provided cloud-init-setup.sh is designed to be passed to a cloud provider (via Terraform) as user-data.

Infrastructure Creation: Terraform provisions the new VM.
Secret Injection: Terraform retrieves the Sectigo EAB (External Account Binding) credentials—specifically the EAB_KID and EAB_HMAC—from a secure digital vault (e.g., HashiCorp Vault or AWS Secrets Manager) directly into memory.
Automated Execution: The cloud-init script runs on first boot, installing NGINX, installing the Snap-isolated version of Certbot, and executing the ACME request using the injected Sectigo credentials.
Zero-Trust Handoff: The certificate is issued, NGINX is secured, and the secrets vanish from memory without ever being written to a code repository.
Review 2-production-reference/cloud-init-setup.sh for the exact Sectigo API endpoint and EAB flag configurations.