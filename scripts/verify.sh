#!/usr/bin/env bash
set -euo pipefail

namespace="assessment"
local_port="8080"

for command in kubectl curl; do
  if ! command -v "${command}" >/dev/null 2>&1; then
    echo "Missing required command: ${command}" >&2
    exit 1
  fi
done

kubectl port-forward --namespace "${namespace}" service/customer-api "${local_port}:80" >/tmp/dexwin-devops-port-forward.log 2>&1 &
port_forward_pid=$!
trap 'kill "${port_forward_pid}" >/dev/null 2>&1 || true' EXIT

sleep 2
curl --fail --silent --show-error "http://127.0.0.1:${local_port}/api/status"
echo
echo "End-to-end service verification passed."
