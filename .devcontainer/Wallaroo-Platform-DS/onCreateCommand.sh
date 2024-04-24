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

# # Add local registry https://kind.sigs.k8s.io/docs/user/local-registry/
# # 1. Create registry container unless it already exists
reg_name='kind-registry'
reg_port='5001'
if [ "$(docker inspect -f '{{.State.Running}}' "${reg_name}" 2>/dev/null || true)" != 'true' ]; then
  docker run \
    -d --restart=always -p "127.0.0.1:${reg_port}:5000" --name "${reg_name}" \
    registry:2
fi

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
kind create cluster --image=kindest/node:v1.28.0 --config=./.devcontainer/Wallaroo-Platform-DS/wallaroo-kind.yaml 

# # 3. Add the registry config to the nodes
# #
# # This is necessary because localhost resolves to loopback addresses that are
# # network-namespace local.
# # In other words: localhost in the container is not localhost on the host.
# #
# # We want a consistent name that works from both ends, so we tell containerd to
# # alias localhost:${reg_port} to the registry container when pulling images
REGISTRY_DIR="/etc/containerd/certs.d/localhost:${reg_port}"
for node in $(kind get nodes -n wallaroo); do
  docker exec "${node}" mkdir -p "${REGISTRY_DIR}"
  cat <<EOF | docker exec -i "${node}" cp /dev/stdin "${REGISTRY_DIR}/hosts.toml"
[host."http://${reg_name}:5000"]
EOF
done

# # 4. Connect the registry to the cluster network if not already connected
# # This allows kind to bootstrap the network but ensures they're on the same network
if [ "$(docker inspect -f='{{json .NetworkSettings.Networks.kind}}' "${reg_name}")" = 'null' ]; then
  docker network connect "kind" "${reg_name}"
fi

# # 5. Document the local registry
# # https://github.com/kubernetes/enhancements/tree/master/keps/sig-cluster-lifecycle/generic/1755-communicating-a-local-registry
# cat <<EOF | kubectl apply -f -
# apiVersion: v1
# kind: ConfigMap
# metadata:
#   name: local-registry-hosting
#   namespace: kube-public
# data:
#   localRegistryHosting.v1: |
#     host: "localhost:${reg_port}"
#     help: "https://kind.sigs.k8s.io/docs/user/local-registry/"
# EOF

# 6. install replicated cli
curl https://kots.io/install/1.107.2 |  REPL_INSTALL_PATH=/usr/local/bin sudo bash

# 7. install oras
VERSION="1.1.0"
curl -LO "https://github.com/oras-project/oras/releases/download/v${VERSION}/oras_${VERSION}_linux_amd64.tar.gz"
mkdir -p oras-install/
tar -zxf oras_${VERSION}_*.tar.gz -C oras-install/
sudo mv oras-install/oras /usr/local/bin/
rm -rf oras_${VERSION}_*.tar.gz oras-install/

