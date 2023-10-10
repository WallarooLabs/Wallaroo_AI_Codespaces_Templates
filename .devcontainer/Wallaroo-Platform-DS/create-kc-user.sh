# Create Keycloak user with gh identity

export KEYCLOAK_ADMIN_USER=$(kubectl get -n wallaroo secret keycloak-admin-secret -o json |jq -r [.data.KEYCLOAK_ADMIN_USER][] | base64 --decode)
export KEYCLOAK_ADMIN_PASSWORD=$(kubectl get -n wallaroo secret keycloak-admin-secret -o json |jq -r [.data.KEYCLOAK_ADMIN_PASSWORD][] | base64 --decode)
export KEYCLOAK_ADMIN_TOKEN=$(curl --location --request POST 'http://localhost:8080/auth/realms/master/protocol/openid-connect/token' --header 'Content-Type: application/x-www-form-urlencoded' --data-urlencode 'username='$KEYCLOAK_ADMIN_USER --data-urlencode 'password='$KEYCLOAK_ADMIN_PASSWORD --data-urlencode 'grant_type=password' --data-urlencode 'client_id=admin-cli' | jq -r [.access_token][])

export NEW_USER_NAME=$(git config --system --get user.name)
export NEW_USER_EMAIL=$(git config --system --get user.email)

curl --location --request POST 'http://localhost:8080/auth/admin/realms/master/users' \
--header 'Content-Type: application/json' \
--header 'Authorization: Bearer '$KEYCLOAK_ADMIN_TOKEN \
--data-raw "{\"firstName\":\"$NEW_USER_NAME\", \"email\":\"$NEW_USER_EMAIL\", \"enabled\":\"true\", \"username\":\"$NEW_USER_EMAIL\"}"
