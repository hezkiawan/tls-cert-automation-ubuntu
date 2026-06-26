# Automated TLS Certificate Provisioning on Ubuntu

This repository provides a Proof of Concept (PoC) and production reference for fully automating SSL/TLS certificate deployment on Ubuntu servers. It demonstrates how to automatically request, verify, and install certificates without manual intervention.

## How the Architecture Works (ACME & Certbot)

This automation is powered by the **ACME protocol** (Automated Certificate Management Environment). The workflow relies on two main components communicating with each other:

1. **The Web Server (Client):** We use **Certbot** running on an Ubuntu VM with NGINX. Certbot acts as the automated ACME client.
2. **The Certificate Authority (CA):** The server that issues certificates. In our local test environment, this is **Pebble**. In production, it would be a commercial CA such as **Sectigo** or **Let's Encrypt**.

### Certificate Issuance Workflow

1. Certbot requests a certificate for a domain (e.g., `app.domain.com`).
2. The CA issues an **HTTP-01 Challenge**, asking the client to prove ownership of the domain.
3. Certbot automatically configures NGINX to serve the required challenge token.
4. The CA verifies the token by connecting to the web server.
5. Once verified, the CA issues the TLS certificate.
6. Certbot installs the certificate into NGINX and reloads the web server.

---

## Repository Structure

```text
tls-cert-automation-ubuntu/
├── 1-local-simulator/
│   ├── docker-compose.yml
│   ├── setup-trust.sh
│   └── deploy-cert.sh
├── 2-production-reference/
│   └── cloud-init-setup.sh
└── README.md
```

---

## 1. Local Simulator Environment

The `1-local-simulator` directory contains a self-contained testing environment.

Since a private Ubuntu VM cannot complete ACME validation against a public Certificate Authority, this project uses a local CA simulator instead.

### Environment

* **Host:** Ubuntu Linux VM
* **Web Server:** NGINX
* **Certificate Authority:** Pebble (Let's Encrypt's official ACME testing server)
* **Container Runtime:** Docker

### Prerequisites

Install the following before running the simulator:

* Docker
* Docker Compose
* NGINX

### Step 1 – Start the Local CA

Launch Pebble in the background.

```bash
cd 1-local-simulator
sudo docker compose up -d
```

Pebble will expose its ACME API on **port 14000**.

### Step 2 – Establish the Trust Bridge

Because Pebble is a private Certificate Authority, Ubuntu does not trust it by default.

Run:

```bash
./setup-trust.sh
```

This script downloads Pebble's root certificate and adds it to Ubuntu's trusted certificate store.

### Step 3 – Execute the Automation

Run the provisioning script:

```bash
./deploy-cert.sh
```

This script:

* Requests a certificate for `app.local.com`
* Runs Certbot non-interactively
* Responds to the HTTP-01 challenge
* Installs the issued certificate into NGINX

### Step 4 – Verify

Verify that HTTPS is working:

```bash
curl -kI https://localhost
```

Expected output:

```text
HTTP/1.1 200 OK
```

---

## 2. Production Reference

The `2-production-reference` directory contains a production-oriented reference for deploying this automation into a cloud environment.

### How the Production Script Works

> **Note:** Do not execute `cloud-init-setup.sh` directly on your local machine.

Instead, it is intended to be passed into a newly created Ubuntu VM as **cloud-init user data**, typically through an Infrastructure-as-Code tool such as Terraform.

During deployment:

1. **Automated Bootstrapping**

   * Terraform creates a new Ubuntu VM.
   * It passes `cloud-init-setup.sh` as the VM's startup script.

2. **Secret Injection**

   * Production CAs such as Sectigo require **External Account Binding (EAB)** credentials.
   * Terraform retrieves these credentials from a secure secret manager (for example, AWS Secrets Manager or HashiCorp Vault).
   * The credentials are injected into the script during provisioning rather than being stored in source control.

3. **Automatic Certificate Provisioning**

   * The script installs NGINX, Snap, and Certbot.
   * Certbot requests a certificate from the production CA.
   * The CA validates ownership using the HTTP-01 challenge over port 80.
   * The certificate is automatically installed into NGINX without manual intervention.
