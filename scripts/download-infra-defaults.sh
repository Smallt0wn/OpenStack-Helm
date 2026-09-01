#!/usr/bin/env bash

set -euo pipefail

# -e       : 명령 하나가 실패하면 스크립트 즉시 중단
# -u       : 정의되지 않은 변수를 사용하면 실패
# pipefail : 파이프라인 중 하나라도 실패하면 전체를 실패로 처리

source "$(dirname "$0")/../env.sh"

cd "${BASE_DIR}"


# ==================================================
# Required variables
# ==================================================

: "${ENVOY_GATEWAY_VERSION:?ENVOY_GATEWAY_VERSION is not set}"
: "${METALLB_VERSION:?METALLB_VERSION is not set}"
: "${ROOK_CEPH_VERSION:?ROOK_CEPH_VERSION is not set}"
: "${CEPH_CSI_DRIVERS_VERSION:?CEPH_CSI_DRIVERS_VERSION is not set}"
: "${CEPH_CSI_DRIVERS_REPO:?CEPH_CSI_DRIVERS_REPO is not set}"
: "${ROOK_GITHUB_RAW_BASE:?ROOK_GITHUB_RAW_BASE is not set}"


echo
echo "========================================"
echo " Infrastructure Default Helm Values"
echo "========================================"
echo
echo "Envoy Gateway : ${ENVOY_GATEWAY_VERSION}"
echo "MetalLB       : ${METALLB_VERSION}"
echo "Rook-Ceph     : ${ROOK_CEPH_VERSION}"
echo "Ceph CSI      : ${CEPH_CSI_DRIVERS_VERSION}"
echo


# ==================================================
# Directory preparation
# ==================================================

mkdir -p \
  infrastructure/envoy-gateway \
  infrastructure/metallb/config \
  infrastructure/rook-ceph/cluster \
  infrastructure/ceph-csi-drivers


# ==================================================
# Helm repositories
# ==================================================

echo "========================================"
echo " Helm repositories"
echo "========================================"

helm repo add metallb \
  https://metallb.github.io/metallb \
  --force-update

helm repo add rook-release \
  https://charts.rook.io/release \
  --force-update

helm repo add ceph-csi-operator \
  "${CEPH_CSI_DRIVERS_REPO}" \
  --force-update

helm repo update


# ==================================================
# 1. Envoy Gateway
# ==================================================

echo
echo "========================================"
echo "[1/4] Envoy Gateway ${ENVOY_GATEWAY_VERSION}"
echo "========================================"

ENVOY_OUTPUT="infrastructure/envoy-gateway/default-values-${ENVOY_GATEWAY_VERSION}.yaml"

helm show values \
  oci://docker.io/envoyproxy/gateway-helm \
  --version "${ENVOY_GATEWAY_VERSION}" \
  > "${ENVOY_OUTPUT}"

test -s "${ENVOY_OUTPUT}"

echo "Saved:"
echo "${ENVOY_OUTPUT}"


# ==================================================
# 2. MetalLB
# ==================================================

echo
echo "========================================"
echo "[2/4] MetalLB ${METALLB_VERSION}"
echo "========================================"

METALLB_OUTPUT="infrastructure/metallb/default-values-${METALLB_VERSION}.yaml"

helm show values \
  metallb/metallb \
  --version "${METALLB_VERSION}" \
  > "${METALLB_OUTPUT}"

test -s "${METALLB_OUTPUT}"

echo "Saved:"
echo "${METALLB_OUTPUT}"


# ==================================================
# 3. Rook-Ceph
# ==================================================

echo
echo "========================================"
echo "[3/4] Rook-Ceph ${ROOK_CEPH_VERSION}"
echo "========================================"

ROOK_OUTPUT="infrastructure/rook-ceph/default-values-${ROOK_CEPH_VERSION}.yaml"

helm show values \
  rook-release/rook-ceph \
  --version "${ROOK_CEPH_VERSION}" \
  > "${ROOK_OUTPUT}"

test -s "${ROOK_OUTPUT}"

echo "Saved:"
echo "${ROOK_OUTPUT}"


# ==================================================
# 4. Ceph CSI Drivers
# ==================================================

echo
echo "========================================"
echo "[4/4] Ceph CSI Drivers ${CEPH_CSI_DRIVERS_VERSION}"
echo "========================================"


# --------------------------------------------------
# 4-1. Ceph CSI chart 자체 공식 default values
# --------------------------------------------------

CSI_DEFAULT_OUTPUT="infrastructure/ceph-csi-drivers/default-values-${CEPH_CSI_DRIVERS_VERSION}.yaml"

helm show values \
  ceph-csi-operator/ceph-csi-drivers \
  --version "${CEPH_CSI_DRIVERS_VERSION}" \
  > "${CSI_DEFAULT_OUTPUT}"

test -s "${CSI_DEFAULT_OUTPUT}"

echo "Saved chart defaults:"
echo "${CSI_DEFAULT_OUTPUT}"


# --------------------------------------------------
# 4-2. Rook 버전에 맞는 권장 CSI values
#
# Rook 1.20에서는 chart default만 사용하지 않고
# Rook에서 제공하는 CSI values를 실제 배포에 사용한다.
# --------------------------------------------------

ROOK_CSI_VALUES_URL="${ROOK_GITHUB_RAW_BASE}/${ROOK_CEPH_VERSION}/deploy/charts/ceph-csi-drivers/values.yaml"

ROOK_CSI_OUTPUT="infrastructure/ceph-csi-drivers/rook-values-${ROOK_CEPH_VERSION}.yaml"

curl -fsSL \
  "${ROOK_CSI_VALUES_URL}" \
  -o "${ROOK_CSI_OUTPUT}"

test -s "${ROOK_CSI_OUTPUT}"

echo
echo "Saved Rook-compatible CSI values:"
echo "${ROOK_CSI_OUTPUT}"


# ==================================================
# Checksums
# ==================================================

echo
echo "========================================"
echo " Generating checksums"
echo "========================================"

sha256sum \
  "${ENVOY_OUTPUT}" \
  "${METALLB_OUTPUT}" \
  "${ROOK_OUTPUT}" \
  "${CSI_DEFAULT_OUTPUT}" \
  "${ROOK_CSI_OUTPUT}" \
  > infrastructure/SHA256SUMS


# ==================================================
# Result
# ==================================================

echo
echo "========================================"
echo " Download completed"
echo "========================================"
echo

echo "Generated files:"
echo

find infrastructure \
  -maxdepth 2 \
  -type f \
  \( -name 'default-values-*' -o -name 'rook-values-*' -o -name 'SHA256SUMS' \) \
  | sort

echo
echo "All required infrastructure values were downloaded."
echo
echo "NOTE:"
echo "default-values-* = upstream chart defaults"
echo "rook-values-*    = actual Rook-compatible CSI configuration"
