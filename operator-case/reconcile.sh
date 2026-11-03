#!/bin/sh
# Stand-in for an operator that enforces the Deployment it owns. It compares the live pod-template
# annotations with its desired spec and replaces the Deployment on any difference. It also reports
# what the running pod looks like, without acting on it.
NS=ebpf-poc
DESIRED=/desired/desired-deployment.yaml

while true; do
  want=$(kubectl create --dry-run=client -o json -f "$DESIRED" | jq -cS '.spec.template.metadata.annotations // {}')
  have=$(kubectl -n "$NS" get deploy managed-app -o json 2>/dev/null | jq -cS '.spec.template.metadata.annotations // {}')

  if [ -z "$have" ]; then
    echo "[operator] creating managed-app"
    kubectl create -f "$DESIRED"
  elif [ "$want" != "$have" ]; then
    echo "[operator] drift: want $want, have $have; replacing"
    kubectl replace -f "$DESIRED"
  else
    pod=$(kubectl -n "$NS" get pod -l app=managed-app -o jsonpath='{range .items[*]}{.metadata.name} init=[{.spec.initContainers[*].name}] restarts={.status.containerStatuses[0].restartCount}{"\n"}{end}')
    echo "[operator] in sync; pods: $pod"
  fi
  sleep 15
done
