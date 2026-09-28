#!/usr/bin/env bash

# 1. Check if connected to Kubernetes cluster / Teleport session
if ! kubectl get namespaces &>/dev/null; then
    echo "ERROR: No active Kubernetes cluster connection found."
    echo "Please login first: tsh kube login <cluster_name>"
    exit 1
fi

# 2. Check customer argument
if [ -z "$1" ]; then
    echo "Usage: list <customer_id_or_namespace>"
    echo "Examples:"
    echo "  list 78956701"
    echo "  list customer-78956701"
    exit 1
fi

NAMESPACE="$1"
if [[ ! "$NAMESPACE" =~ ^customer- ]]; then
    NAMESPACE="customer-${NAMESPACE}"
fi

echo "$NAMESPACE" > ~/.gc_current_customer

echo "Finding script-server pod in namespace: ${NAMESPACE}..."

SCRIPT_POD=$(kubectl get pod -l "app=script-server" --namespace="${NAMESPACE}" -o jsonpath="{.items[0].metadata.name}" 2>/dev/null)

if [ -z "$SCRIPT_POD" ]; then
    echo "ERROR: Please verify the Customer ID and ensure you are logged into the correct cluster."
    exit 1
fi

echo "Executing list_aggregators on pod: ${SCRIPT_POD}..."
echo "--------------------------------------------------------"

kubectl exec -it "$SCRIPT_POD" -n "${NAMESPACE}" -- python3 /var/lib/guardicore/management/scripts/mgmtctl/main.pyc list_aggregators
