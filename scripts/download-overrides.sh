#!/usr/bin/env bash

set -euo pipefail

# -e       : 명령 하나가 실패하면 스크립트 즉시 중단
# -u       : 정의되지 않은 변수를 사용하면 실패
# pipefail : 파이프라인 중 하나라도 실패하면 전체를 실패로 처리

source "$(dirname "$0")/../env.sh"

mkdir -p "${OVERRIDES_DIR}"

# OpenStack-Helm 공식 override를 다운로드할 컴포넌트 목록
CHARTS=(
  rabbitmq
  mariadb
  memcached
  openvswitch
  libvirt
  keystone
  heat
  glance
  cinder
  trove
  placement
  nova
  neutron
  horizon
)

for chart in "${CHARTS[@]}"; do
  echo
  echo "========================================"
  echo "Downloading overrides: ${chart}"
  echo "========================================"

  helm osh get-values-overrides \
    -d \
    -u "${OVERRIDES_URL}" \
    -p "${OVERRIDES_DIR}" \
    -c "${chart}" \
    ${FEATURES}
done

echo
echo "Override download complete."
