#!/bin/bash
# =============================================================================
# Supabase Key Generator
# =============================================================================
# This script generates all required secrets for Supabase self-hosting
# Run this once and save the output to your .env file

set -e

echo "=== Supabase Secrets Generator ==="
echo ""

# Generate random secrets
POSTGRES_PASSWORD=$(openssl rand -base64 24 | tr -dc 'a-zA-Z0-9' | head -c 32)
JWT_SECRET=$(openssl rand -base64 32 | tr -dc 'a-zA-Z0-9' | head -c 40)
VAULT_ENC_KEY=$(openssl rand -base64 24 | head -c 32)
SECRET_KEY_BASE=$(openssl rand -base64 64 | tr -dc 'a-zA-Z0-9' | head -c 64)
REALTIME_SECRET_KEY_BASE=$(openssl rand -base64 64 | tr -dc 'a-zA-Z0-9' | head -c 64)
DASHBOARD_PASSWORD=$(openssl rand -base64 16 | tr -dc 'a-zA-Z0-9' | head -c 20)

echo "# Database"
echo "POSTGRES_PASSWORD=$POSTGRES_PASSWORD"
echo ""

echo "# JWT (this is used to generate ANON_KEY and SERVICE_ROLE_KEY)"
echo "JWT_SECRET=$JWT_SECRET"
echo ""

echo "# Encryption Keys"
echo "VAULT_ENC_KEY=$VAULT_ENC_KEY"
echo "SECRET_KEY_BASE=$SECRET_KEY_BASE"
echo "REALTIME_SECRET_KEY_BASE=$REALTIME_SECRET_KEY_BASE"
echo ""

echo "# Dashboard"
echo "DASHBOARD_USERNAME=admin"
echo "DASHBOARD_PASSWORD=$DASHBOARD_PASSWORD"
echo ""

# Generate JWT tokens (ANON_KEY and SERVICE_ROLE_KEY)
# These require the jwt-cli tool or can be generated online at:
# https://supabase.com/docs/guides/self-hosting/docker#generate-api-keys

echo "=== JWT API Keys ==="
echo ""
echo "You need to generate ANON_KEY and SERVICE_ROLE_KEY using your JWT_SECRET."
echo ""
echo "Option 1: Use the online generator:"
echo "  https://supabase.com/docs/guides/self-hosting/docker#generate-api-keys"
echo ""
echo "Option 2: Use this Node.js script:"
echo ""
cat << 'NODEJS'
// Save as generate-jwt.js and run with: node generate-jwt.js

const crypto = require('crypto');

const JWT_SECRET = process.env.JWT_SECRET || 'YOUR_JWT_SECRET_HERE';

function base64url(source) {
  return Buffer.from(source)
    .toString('base64')
    .replace(/=/g, '')
    .replace(/\+/g, '-')
    .replace(/\//g, '_');
}

function createJWT(payload, secret) {
  const header = { alg: 'HS256', typ: 'JWT' };
  const headerB64 = base64url(JSON.stringify(header));
  const payloadB64 = base64url(JSON.stringify(payload));
  const signature = crypto
    .createHmac('sha256', secret)
    .update(`${headerB64}.${payloadB64}`)
    .digest('base64')
    .replace(/=/g, '')
    .replace(/\+/g, '-')
    .replace(/\//g, '_');
  return `${headerB64}.${payloadB64}.${signature}`;
}

// Generate keys with 10 year expiry
const exp = Math.floor(Date.now() / 1000) + (10 * 365 * 24 * 60 * 60);

const anonKey = createJWT({
  iss: 'supabase',
  role: 'anon',
  iat: Math.floor(Date.now() / 1000),
  exp: exp
}, JWT_SECRET);

const serviceRoleKey = createJWT({
  iss: 'supabase',
  role: 'service_role',
  iat: Math.floor(Date.now() / 1000),
  exp: exp
}, JWT_SECRET);

console.log('ANON_KEY=' + anonKey);
console.log('SERVICE_ROLE_KEY=' + serviceRoleKey);
NODEJS

echo ""
echo "=== Dashboard Password Hash (for Traefik Basic Auth) ==="
echo ""
echo "Generate with: htpasswd -nb admin '$DASHBOARD_PASSWORD'"
echo "Or install apache2-utils: apt-get install apache2-utils"
echo ""
echo "The hash should be added to .env as DASHBOARD_PASSWORD_HASH"
echo "(escape \$ with \$\$ in docker-compose)"
