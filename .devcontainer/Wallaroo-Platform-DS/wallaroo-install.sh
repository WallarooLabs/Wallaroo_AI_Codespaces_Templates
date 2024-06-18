#/usr/bin/env bash
kubectl apply -f ./.devcontainer/Wallaroo-Platform-DS/wallaroo-storage.yaml

export DOMAIN_SUFFIX=$GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN

export DASH_URL=$CODESPACE_NAME-8443.$GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN

export AUTH_URL=$CODESPACE_NAME-8443.$GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN

export MS_BASE_URL=$(echo $WALLAROO_LICENSE| base64 -di | yq -r '.spec.entitlements.domainSuffix.value')
envsubst < ./.wallaroo/replicated-config.yaml.templ > ./.wallaroo/replicated-config.yaml

# License is stored in a gh secret
echo $WALLAROO_LICENSE | base64 -di > ./.wallaroo/wallaroo_license.yaml

kubectl kots install wallaroo/ci --shared-password=password --namespace=wallaroo --skip-preflights=true --no-port-forward --license-file=./.wallaroo/wallaroo_license.yaml --config-values ./.wallaroo/replicated-config.yaml

for i in $(seq 90); do
    if [ "ready" = "$(kubectl kots app-status wallaroo -n wallaroo | jq -r .appstatus.state)" ]; then
        echo "kots install SUCCESS after $(( i * 10 )) sec"
        kubectl -n wallaroo patch svc api-lb-ext  --type='json' -p '[{"op":"replace","path":"/spec/type","value":"NodePort"},{"op":"replace","path":"/spec/ports/1/nodePort","value":30525}]'
        sleep 1
        exit 0
    fi
    printf '.'
    sleep 10
done

echo Failed install: KOTS app-status did not turn "ready" within the timeout
exit 1
