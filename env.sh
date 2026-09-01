#!/usr/bin/env bash

export OPENSTACK_RELEASE=2026.1
export FEATURES="${OPENSTACK_RELEASE} ubuntu_noble"

export BASE_DIR="${HOME}/openstack/openstack-helm"
export OVERRIDES_DIR="${BASE_DIR}/overrides"

export OVERRIDES_URL="https://opendev.org/openstack/openstack-helm/raw/branch/master/values_overrides"

echo "OpenStack-Helm environment loaded"
echo "OPENSTACK_RELEASE=${OPENSTACK_RELEASE}"
echo "FEATURES=${FEATURES}"
echo "BASE_DIR=${BASE_DIR}"
echo "OVERRIDES_DIR=${OVERRIDES_DIR}"
