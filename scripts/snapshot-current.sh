#!/usr/bin/env bash

set -euo pipefail

# Snapshot에는 Helm manifest, computed values 등
# 민감한 정보가 포함될 가능성이 있으므로
# 현재 사용자만 읽을 수 있도록 생성한다.
umask 077

BASE_DIR="${HOME}/openstack/openstack-helm"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
SNAPSHOT_DIR="${BASE_DIR}/snapshots/${TIMESTAMP}"

mkdir -p \
  "${SNAPSHOT_DIR}/cluster" \
  "${SNAPSHOT_DIR}/envoy-gateway" \
  "${SNAPSHOT_DIR}/metallb" \
  "${SNAPSHOT_DIR}/rook-ceph" \
  "${SNAPSHOT_DIR}/ceph-csi-drivers" \
  "${SNAPSHOT_DIR}/openstack"

echo
echo "========================================"
echo " OpenStack Cluster Snapshot"
echo "========================================"
echo
echo "Snapshot directory:"
echo "${SNAPSHOT_DIR}"
echo


# ==================================================
# 1. Kubernetes Cluster
# ==================================================

echo "[1/6] Kubernetes Cluster"

helm list -A \
  > "${SNAPSHOT_DIR}/cluster/helm-releases.txt"

kubectl get nodes -o wide \
  > "${SNAPSHOT_DIR}/cluster/nodes.txt"

kubectl get pods -A -o wide \
  > "${SNAPSHOT_DIR}/cluster/pods.txt"

kubectl get namespaces \
  > "${SNAPSHOT_DIR}/cluster/namespaces.txt"

kubectl get sc \
  > "${SNAPSHOT_DIR}/cluster/storageclasses.txt"

kubectl get pvc -A \
  > "${SNAPSHOT_DIR}/cluster/pvc.txt"

kubectl get pv \
  > "${SNAPSHOT_DIR}/cluster/pv.txt"


# ==================================================
# 2. Envoy Gateway
# ==================================================

echo "[2/6] Envoy Gateway"

if helm status eg -n envoy-gateway-system >/dev/null 2>&1; then

  helm get values eg \
    -n envoy-gateway-system \
    > "${SNAPSHOT_DIR}/envoy-gateway/installed-values.yaml"

  helm get values eg \
    -n envoy-gateway-system \
    --all \
    > "${SNAPSHOT_DIR}/envoy-gateway/computed-values.yaml"

  helm get manifest eg \
    -n envoy-gateway-system \
    > "${SNAPSHOT_DIR}/envoy-gateway/manifest.yaml"

  kubectl get gatewayclass \
    -o yaml \
    > "${SNAPSHOT_DIR}/envoy-gateway/gatewayclasses.yaml" \
    2>/dev/null || true

  kubectl get gateway -A \
    -o yaml \
    > "${SNAPSHOT_DIR}/envoy-gateway/gateways.yaml" \
    2>/dev/null || true

  kubectl get httproute -A \
    -o yaml \
    > "${SNAPSHOT_DIR}/envoy-gateway/httproutes.yaml" \
    2>/dev/null || true

  kubectl get envoyproxy -A \
    -o yaml \
    > "${SNAPSHOT_DIR}/envoy-gateway/envoyproxies.yaml" \
    2>/dev/null || true

else
  echo "  Envoy Gateway release not found. Skipping."
fi


# ==================================================
# 3. MetalLB
# ==================================================

echo "[3/6] MetalLB"

if helm status metallb -n metallb-system >/dev/null 2>&1; then

  helm get values metallb \
    -n metallb-system \
    > "${SNAPSHOT_DIR}/metallb/installed-values.yaml"

  helm get values metallb \
    -n metallb-system \
    --all \
    > "${SNAPSHOT_DIR}/metallb/computed-values.yaml"

  helm get manifest metallb \
    -n metallb-system \
    > "${SNAPSHOT_DIR}/metallb/manifest.yaml"

  kubectl get ipaddresspool \
    -n metallb-system \
    -o yaml \
    > "${SNAPSHOT_DIR}/metallb/ipaddresspools.yaml" \
    2>/dev/null || true

  kubectl get l2advertisement \
    -n metallb-system \
    -o yaml \
    > "${SNAPSHOT_DIR}/metallb/l2advertisements.yaml" \
    2>/dev/null || true

  kubectl get bgpadvertisement \
    -n metallb-system \
    -o yaml \
    > "${SNAPSHOT_DIR}/metallb/bgpadvertisements.yaml" \
    2>/dev/null || true

  kubectl get bgppeer \
    -n metallb-system \
    -o yaml \
    > "${SNAPSHOT_DIR}/metallb/bgppeers.yaml" \
    2>/dev/null || true

else
  echo "  MetalLB release not found. Skipping."
fi


# ==================================================
# 4. Rook-Ceph
# ==================================================

echo "[4/6] Rook-Ceph"

if helm status rook-ceph -n rook-ceph >/dev/null 2>&1; then

  helm get values rook-ceph \
    -n rook-ceph \
    > "${SNAPSHOT_DIR}/rook-ceph/installed-values.yaml"

  helm get values rook-ceph \
    -n rook-ceph \
    --all \
    > "${SNAPSHOT_DIR}/rook-ceph/computed-values.yaml"

  helm get manifest rook-ceph \
    -n rook-ceph \
    > "${SNAPSHOT_DIR}/rook-ceph/manifest.yaml"

  kubectl get cephcluster rook-ceph \
    -n rook-ceph \
    -o yaml \
    > "${SNAPSHOT_DIR}/rook-ceph/cephcluster.yaml"

  kubectl get cephblockpool \
    -n rook-ceph \
    -o yaml \
    > "${SNAPSHOT_DIR}/rook-ceph/cephblockpools.yaml" \
    2>/dev/null || true

  kubectl get cephfilesystem \
    -n rook-ceph \
    -o yaml \
    > "${SNAPSHOT_DIR}/rook-ceph/cephfilesystems.yaml" \
    2>/dev/null || true

  kubectl get cephobjectstore \
    -n rook-ceph \
    -o yaml \
    > "${SNAPSHOT_DIR}/rook-ceph/cephobjectstores.yaml" \
    2>/dev/null || true

  kubectl get storageclass general \
    -o yaml \
    > "${SNAPSHOT_DIR}/rook-ceph/storageclass-general.yaml"

  # 사람이 보기 쉬운 Ceph 상태
  if kubectl get deployment rook-ceph-tools \
      -n rook-ceph >/dev/null 2>&1; then

    kubectl -n rook-ceph exec deploy/rook-ceph-tools -- \
      ceph -s \
      > "${SNAPSHOT_DIR}/rook-ceph/ceph-status.txt" \
      2>/dev/null || true

    kubectl -n rook-ceph exec deploy/rook-ceph-tools -- \
      ceph osd tree \
      > "${SNAPSHOT_DIR}/rook-ceph/ceph-osd-tree.txt" \
      2>/dev/null || true

    kubectl -n rook-ceph exec deploy/rook-ceph-tools -- \
      ceph df \
      > "${SNAPSHOT_DIR}/rook-ceph/ceph-df.txt" \
      2>/dev/null || true
  fi

else
  echo "  Rook-Ceph release not found. Skipping."
fi


# ==================================================
# 5. Ceph CSI Drivers
# ==================================================

echo "[5/6] Ceph CSI Drivers"

if helm status ceph-csi-drivers -n rook-ceph >/dev/null 2>&1; then

  helm get values ceph-csi-drivers \
    -n rook-ceph \
    > "${SNAPSHOT_DIR}/ceph-csi-drivers/installed-values.yaml"

  helm get values ceph-csi-drivers \
    -n rook-ceph \
    --all \
    > "${SNAPSHOT_DIR}/ceph-csi-drivers/computed-values.yaml"

  helm get manifest ceph-csi-drivers \
    -n rook-ceph \
    > "${SNAPSHOT_DIR}/ceph-csi-drivers/manifest.yaml"

else
  echo "  Ceph CSI Drivers release not found. Skipping."
fi


# ==================================================
# 6. OpenStack Helm Releases
# ==================================================

echo "[6/6] OpenStack Helm Releases"

OPENSTACK_RELEASES=(
  ceph-adapter-rook
  mariadb
  rabbitmq
  memcached
  keystone
  heat
  glance
  cinder
  openvswitch
  libvirt
  placement
  nova
  neutron
  horizon
  trove
)

for release in "${OPENSTACK_RELEASES[@]}"; do

  if helm status "${release}" \
      -n openstack >/dev/null 2>&1; then

    echo "  Saving: ${release}"

    mkdir -p \
      "${SNAPSHOT_DIR}/openstack/${release}"

    helm get values "${release}" \
      -n openstack \
      > "${SNAPSHOT_DIR}/openstack/${release}/installed-values.yaml"

    helm get values "${release}" \
      -n openstack \
      --all \
      > "${SNAPSHOT_DIR}/openstack/${release}/computed-values.yaml"

    helm get manifest "${release}" \
      -n openstack \
      > "${SNAPSHOT_DIR}/openstack/${release}/manifest.yaml"

  fi

done


# ==================================================
# Additional OpenStack Runtime State
# ==================================================

kubectl get pods \
  -n openstack \
  -o wide \
  > "${SNAPSHOT_DIR}/openstack/pods.txt" \
  2>/dev/null || true

kubectl get svc \
  -n openstack \
  -o wide \
  > "${SNAPSHOT_DIR}/openstack/services.txt" \
  2>/dev/null || true

kubectl get pvc \
  -n openstack \
  > "${SNAPSHOT_DIR}/openstack/pvc.txt" \
  2>/dev/null || true

kubectl get jobs \
  -n openstack \
  > "${SNAPSHOT_DIR}/openstack/jobs.txt" \
  2>/dev/null || true


echo
echo "========================================"
echo " Snapshot completed"
echo "========================================"
echo
echo "Saved to:"
echo "${SNAPSHOT_DIR}"
echo
echo "WARNING:"
echo "Snapshots may contain credentials,"
echo "Secrets or internal cluster information."
echo "Do NOT commit snapshots to Git."
