#!/bin/bash
# ==============================================================================
# LOCAL TRUST ESTABLISHMENT
# Injects Pebble's hardcoded Management API Root CA into the OS so 
# Certbot can securely connect to port 14000.
# ==============================================================================

echo "🔒 Downloading Private API Root CA from Pebble source..."
curl -s -o pebble-api.pem https://raw.githubusercontent.com/letsencrypt/pebble/master/test/certs/pebble.minica.pem

echo "🛡️ Injecting CA into Ubuntu Trust Store..."
sudo cp pebble-api.pem /usr/local/share/ca-certificates/pebble.crt
sudo update-ca-certificates

echo "✅ Trust Bridge Established."