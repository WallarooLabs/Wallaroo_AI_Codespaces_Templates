# workaround for https://github.com/kubernetes-sigs/kind/issues/3696
# from https://github.com/dvordrova/kind-istio-tempo-otel/issues/1
sudo tee /etc/docker/daemon.json > /dev/null <<'EOF'
{
  "ip6tables": false
}
EOF
sudo pkill -f dockerd
sudo dockerd --dns 168.63.129.16 &

# wait for docker
for i in $(seq 90); do
    docker ps
    status=$?
    if [ "$status" -eq 0 ]; then
        echo "docker worked after $(( i * 10 )) sec"
        break
    fi
    printf '.'
    sleep 10
done
docker ps
status=$?
[ "$status" -eq 0 ] || exit 1

# 2. Create kind cluster
kind create cluster --image=kindest/node:v1.29.0 --config=./.devcontainer/Wallaroo-Platform-DS/wallaroo-kind.yaml 

# 6. install replicated cli
curl https://kots.io/install/1.112.2 |  REPL_INSTALL_PATH=/usr/local/bin sudo bash

