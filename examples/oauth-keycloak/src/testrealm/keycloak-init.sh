#!/bin/sh
set -euo pipefail

KEYCLOAK_HOST=localhost
KEYCLOAK_URL="http://${KEYCLOAK_HOST}:8080/auth"
KEYCLOAK_ADMIN_URL="http://${KEYCLOAK_HOST}:9000"
ADMIN_USER="testadmin"
ADMIN_PASSWORD="${KEYCLOAK_ADMIN_PASSWORD}"
REALM_NAME="testrealm"

# Wait for Keycloak to be ready
echo "Waiting for Keycloak to be ready..."
while ! curl -f "${KEYCLOAK_ADMIN_URL}/auth/health/ready" >/dev/null 2>&1; do
  echo "Keycloak not ready yet, waiting..."
  sleep 5
done
echo "Keycloak is ready!"

WELCOME_STATE_CHECKER=$(curl -s --output /dev/null --cookie-jar - $KEYCLOAK_URL/ | grep "WELCOME_STATE_CHECKER" | awk '{print $7}' || true)

if [ -z "$WELCOME_STATE_CHECKER" ]; then
  echo "No WELCOME_STATE_CHECKER cookie fund, skipping admin account setup"
else
  echo "Setting up admin user..."
  curl -f -s --show-error $KEYCLOAK_URL/ \
    -H "Cookie: WELCOME_STATE_CHECKER=${WELCOME_STATE_CHECKER}" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    --data-urlencode "username=$ADMIN_USER" \
    --data-urlencode "password=${ADMIN_PASSWORD}" \
    --data-urlencode "passwordConfirmation=${ADMIN_PASSWORD}" \
    --data-urlencode "stateChecker=${WELCOME_STATE_CHECKER}" \
    -o /dev/null -w "%{http_code}\n"
fi

function accesstoken {
  curl -f --silent -X POST "$KEYCLOAK_URL/realms/master/protocol/openid-connect/token" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "username=$ADMIN_USER" \
    -d "password=$ADMIN_PASSWORD" \
    -d 'grant_type=password' \
    -d 'client_id=admin-cli' | yq -o=t -M '.access_token' -
}

echo "Getting admin access token..."
ACCESS_TOKEN=$(accesstoken)

if [ "$ACCESS_TOKEN" = "null" ] || [ -z "$ACCESS_TOKEN" ]; then
  echo "Failed to get access token" && exit 1
fi

echo "Successfully authenticated as admin"

REALM_EXISTS=$(curl -s -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  "${KEYCLOAK_URL}/auth/admin/realms/${REALM_NAME}" \
  -w "%{http_code}" -o /dev/null)

if [ "$REALM_EXISTS" = "200" ]; then
  echo "Realm ${REALM_NAME} already exists"
else
  echo "Importing realm from testrealm.json..."
  curl -f -s --show-error \
    -X POST "${KEYCLOAK_URL}/admin/realms" \
    -H "Authorization: Bearer ${ACCESS_TOKEN}" \
    -H "Content-Type: application/json" \
    -d @testrealm.json
  echo "Realm imported successfully"
fi

PARTIAL_IMPORTS=20-oauth2.json
for partialImport in $PARTIAL_IMPORTS; do
  echo "Importing $partialImport..."
  curl -f -s --show-error "$KEYCLOAK_URL/admin/realms/$REALM_NAME/partialImport?ifResourceExists=SKIP" \
    -H "Accept: application/json" \
    -H "Authorization: Bearer ${ACCESS_TOKEN}" \
    -H "Content-Type: application/json" \
    -d @"$partialImport" -o "/tmp/$partialImport.out" --write-out "%{http_code}\n"
done

echo "Keycloak initialization completed successfully!"

[ -z "$ON_END_SLEEP" ] || sleep $ON_END_SLEEP
