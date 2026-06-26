#!/bin/bash
# ==============================================================================
# PRODUCTION ACME PROVISIONING SCRIPT (SECTIGO ENVIRONMENT)
# Designed for automated execution via Terraform / cloud-init on boot.
# ==============================================================================

echo "📦 Installing NGINX and Core Dependencies..."
apt-get update -y
# Explicitly install snapd in case it hasnt been installed yet
apt-get install nginx snapd -y

echo "🔧 Installing Production Certbot via Snap..."
# Ensure snap core is installed and up to date before installing Certbot
snap install core; snap refresh core
snap install --classic certbot
ln -s /snap/bin/certbot /usr/bin/certbot

# ==============================================================================
# SECTIGO ACME CONFIGURATION
# Commercial CAs require External Account Binding (EAB) to verify the corporate account.
# These values are generated in the Sectigo Certificate Manager portal.
# In a real Terraform pipeline, these would be injected securely via Vault or AWS Secrets.
# ==============================================================================
SECTIGO_ACME_URL="https://acme.sectigo.com/v2/OV" # (Adjust to OV/EV/DV based on corporate tier)
EAB_KID="<INJECT_SECTIGO_KEY_ID_HERE>"
EAB_HMAC="<INJECT_SECTIGO_MAC_KEY_HERE>"
DOMAIN="app.helios.com"
EMAIL="admin@helios.com"

echo "🔐 Requesting and Deploying Sectigo SSL Certificate..."
certbot --nginx \
  --server $SECTIGO_ACME_URL \
  --eab-kid $EAB_KID \
  --eab-hmac-key $EAB_HMAC \
  --email $EMAIL \
  --agree-tos \
  --non-interactive \
  -d $DOMAIN

echo "🎉 Production Deployment Complete! Web server is secured via Sectigo."