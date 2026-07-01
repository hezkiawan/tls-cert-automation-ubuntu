#!/bin/bash

# ==============================================================================
# PRODUCTION ACME PROVISIONING SCRIPT (UBUNTU / NGINX / SECTIGO)
#
# Purpose:
# Automates end-to-end TLS certificate provisioning for an NGINX web server
# using the ACME protocol.
#
# Designed for unattended execution during VM provisioning via:
#   - Terraform cloud-init
#   - AWS EC2 User Data
#   - Azure Custom Data
#
# High-Level Workflow:
# 1. Install NGINX and required dependencies.
# 2. Install Certbot.
# 3. Configure Certbot to communicate with Sectigo's ACME server.
# 4. Authenticate using External Account Binding (EAB).
# 5. Request a TLS certificate.
# 6. Automatically configure NGINX to use HTTPS.
# ==============================================================================


#------------------------------------------------------------------------------
# STEP 1 - Install NGINX and Required Dependencies
#
# NGINX serves as the web server that hosts the application.
#
# snapd is required because the recommended distribution method for Certbot
# is through Canonical's Snap packages, ensuring the latest supported version.
#------------------------------------------------------------------------------

echo "📦 Installing NGINX and Core Dependencies..."

apt-get update -y

# Install NGINX and Snap package manager.
apt-get install nginx snapd -y


#------------------------------------------------------------------------------
# STEP 2 - Install Certbot
#
# Certbot is the ACME client responsible for:
#   - communicating with the Certificate Authority (Sectigo)
#   - completing ACME challenge validation
#   - requesting TLS certificates
#   - installing certificates
#   - automatically updating the NGINX configuration
#
# Installing through Snap ensures Certbot remains up-to-date.
#------------------------------------------------------------------------------

echo "🔧 Installing Production Certbot via Snap..."

# Install Snap core and ensure it is fully updated.
snap install core
snap refresh core

# Install the latest Certbot release.
snap install --classic certbot

# Create a symbolic link so Certbot is accessible globally.
ln -s /snap/bin/certbot /usr/bin/certbot


#------------------------------------------------------------------------------
# STEP 3 - Configure Sectigo ACME Endpoint
#
# Commercial Certificate Authorities (such as Sectigo) require
# External Account Binding (EAB).
#
# Unlike Let's Encrypt, commercial providers require ACME clients to
# authenticate against an enterprise account before certificates are issued.
#
# These credentials should NEVER be hardcoded in production.
# Instead, inject them securely using:
#   • HashiCorp Vault
#   • AWS Secrets Manager
#   • Azure Key Vault
#------------------------------------------------------------------------------

# Sectigo ACME API endpoint.
SECTIGO_ACME_URL="https://acme.sectigo.com/v2/OV"

# Enterprise authentication credentials.
EAB_KID="<INJECT_SECTIGO_KEY_ID_HERE>"
EAB_HMAC="<INJECT_SECTIGO_MAC_KEY_HERE>"

# Domain requesting a certificate.
DOMAIN="app.helios.com"

# Email address used for ACME account registration and expiry notifications.
EMAIL="admin@helios.com"


#------------------------------------------------------------------------------
# STEP 4 - Request and Install TLS Certificate
#
# Certbot automatically performs the following:
#
# 1. Detects the existing NGINX configuration.
# 2. Generates a new private key.
# 3. Creates a Certificate Signing Request (CSR).
# 4. Authenticates with Sectigo using EAB credentials.
# 5. Completes the ACME HTTP-01 challenge.
# 6. Downloads the issued certificate.
# 7. Stores certificates under:
#        /etc/letsencrypt/
# 8. Updates the NGINX virtual host configuration.
# 9. Enables HTTPS and reloads NGINX.
#
# No manual certificate installation or NGINX configuration is required.
#------------------------------------------------------------------------------

echo "🔐 Requesting and Deploying Sectigo SSL Certificate..."

certbot --nginx \
  --server $SECTIGO_ACME_URL \
  --eab-kid $EAB_KID \
  --eab-hmac-key $EAB_HMAC \
  --email $EMAIL \
  --agree-tos \
  --non-interactive \
  -d $DOMAIN


#------------------------------------------------------------------------------
# STEP 5 - Verify Execution Result
#
# Certbot returns an exit code:
#
#   0  = Success
#   >0 = Failure
#
# Returning a non-zero exit code allows Terraform, cloud-init,
# and CI/CD pipelines to detect provisioning failures immediately.
#------------------------------------------------------------------------------

if [ $? -ne 0 ]; then
    echo "❌ Provisioning Failed! Check Certbot logs under /var/log/letsencrypt/"
    exit 1
fi

echo "🎉 Production Deployment Complete! NGINX is secured via Sectigo."
