#!/bin/bash
# ==============================================================================
# ZERO-TOUCH ACME PROVISIONING (LOCAL PoC)
# Demonstrates automated domain verification and NGINX configuration.
# ==============================================================================

echo "🚀 Executing Zero-Touch ACME Provisioning..."

# LOCAL BYPASS 1: REQUESTS_CA_BUNDLE forces Certbot's Python engine to trust our downloaded API CA.
# LOCAL BYPASS 2: --http-01-port 5002 forces NGINX to answer the challenge on a non-root port, as required by Pebble.
sudo REQUESTS_CA_BUNDLE=$(pwd)/pebble-api.pem certbot \
  --nginx \
  --server https://localhost:14000/dir \
  --email admin@local.com \
  --agree-tos \
  --no-eff-email \
  -d app.local.com \
  --http-01-port 5002

echo "🎉 Deployment Complete!"