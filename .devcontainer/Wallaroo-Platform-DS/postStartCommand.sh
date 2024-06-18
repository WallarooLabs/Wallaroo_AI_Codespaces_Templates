for i in $(seq 90); do
    if [ "ready" = "$(kubectl kots app-status wallaroo -n wallaroo | jq -r .appstatus.state)" ]; then
        sleep 1
        sed -i '/WALLAROO_START/, /WALLAROO_END/ s/Starting/Ready/' README.md
        echo "kots install SUCCESS after $(( i * 10 )) sec"
        exit 0
    fi
    sed -i '/WALLAROO_START/, /WALLAROO_END/ s/Ready/Starting/' README.md
    printf '.'
    sleep 10
done
