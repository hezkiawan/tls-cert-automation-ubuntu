# Automated TLS Certificate Provisioning on Ubuntu

This repository provides a Proof of Concept (PoC) and production reference for fully automating SSL/TLS certificate deployment on Ubuntu servers. It demonstrates how to automatically request, verify, and install certificates without manual intervention.

## How the Architecture Works (ACME & Certbot)

This automation is powered by the **ACME protocol** (Automated Certificate Management Environment). The workflow relies on two main components talking to each other:

1. **The Web Server (Client):** We use **Certbot** running on an Ubuntu VM with NGINX. Certbot acts as our automated agent.
2. **The Certificate Authority (CA):** The server that issues the certificate. In our local test, this is a simulated CA called **Pebble**. In production, this is a commercial CA like **Sectigo** or **Let's Encrypt**.

**The Process:**
* Certbot sends a request to the CA asking for a certificate for a specific domain (e.g., `app.domain.com`).
* The CA issues an HTTP-01 Challenge: *"Prove you own this domain by placing a specific secret token on your web server."*
* Certbot automatically spins up or reconfigures NGINX to host that token.
* The CA reaches out over the network, finds the token, verifies ownership, and issues the cryptographic certificate.
* Certbot locks the new certificate into NGINX and restarts the web server.

---

## Repository Structure

```text
tls-cert-automation-ubuntu/
├── 1-local-simulator/ # The active Proof of Concept using a local Docker CA
│ ├── docker-compose.yml
│ ├── setup-trust.sh
│ └── deploy-cert.sh
├── 2-production-reference/ # Production-ready artifact for live deployment
│ └── cloud-init-setup.sh
└── README.md

1. Local Simulator Environment
The 1-local-simulator directory contains a self-contained testing environment. Because we cannot test certificate issuance against a real public CA from a private VM, we run our own CA locally.

The Environment:

Host: Ubuntu Linux VM
Web Server: NGINX
Local CA: Pebble (Let's Encrypt's official testing CA), running inside a Docker container.
How to Run the Simulator
Prerequisites: You must have Docker, Docker Compose, and NGINX installed on the Ubuntu host.

Step 1: Start the Local CA

Spin up the Pebble server in the background. It will expose its API on port 14000.

Bash 
cd 1-local-simulator
sudo docker compose up -d

Step 2: Establish the Trust Bridge

Because Pebble is a private, simulated CA, your Ubuntu host does not trust it by default. This script downloads Pebble's management root certificate and injects it into the Ubuntu OS so Certbot can connect securely.

Bash 
./setup-trust.sh

Step 3: Execute the Automation

Run the provisioning script. This forces Certbot to request a certificate for app.local.com, bypass prompts, and temporarily answer the CA's challenge on port 5002 (due to Docker routing).

Bash 
./deploy-cert.sh

Step 4: Verify

Ping the local web server to verify NGINX is now serving traffic securely over HTTPS.

Bash 
curl -kI https://localhost

(You should receive an HTTP/1.1 200 OK header).

2. Production Reference
The 2-production-reference directory contains the blueprint for taking this local automation into a live enterprise environment.

How to Use the Production Script
Do not run this script directly on your local machine. The cloud-init-setup.sh script is designed to be injected into a live cloud environment via an Infrastructure as Code tool like Terraform.

Automated Bootstrapping: When Terraform builds a fresh Ubuntu VM, it passes this script in as user-data so it runs automatically the moment the server turns on.
Secret Injection: In a live environment using a commercial CA like Sectigo, you must authenticate using EAB (External Account Binding) keys. Terraform pulls these keys from a secure vault (like AWS Secrets Manager) and injects them into the Certbot command inside the script.
Execution: The script installs dependencies (NGINX, snapd, Certbot), reaches out to the live Sectigo API, passes the HTTP-01 challenge over public port 80, and secures the server automatically without human input.