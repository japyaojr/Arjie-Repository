#!/usr/bin/env bash

# 1. Check if connected to Kubernetes cluster / Teleport session
if ! kubectl get namespaces &>/dev/null; then
    echo "ERROR: No active Kubernetes cluster connection found."
    echo "Please login first: tsh kube login <cluster_name>"
    exit 1
fi

# 2. Check aggregator argument
if [ -z "$1" ]; then
    echo "Usage: gcsh <aggregator_name_or_ip> [optional_customer_id]"
    echo "Examples:"
    echo "  gcsh gc-aggregator-172-234-148-229"
    echo "  gcsh 78956701 gc-aggregator-172-234-148-229"
    exit 1
fi

TARGET=""
NAMESPACE=""

# Case A: Two arguments provided
if [ -n "$2" ]; then
    if [[ "$1" =~ ^customer- ]] || [[ "$1" =~ ^[0-9]+ ]]; then
        NAMESPACE="$1"
        TARGET="$2"
    else
        TARGET="$1"
        NAMESPACE="$2"
    fi
else
    # Case B: Only one argument provided
    TARGET="$1"
    if [ -f ~/.gc_current_customer ]; then
        NAMESPACE=$(cat ~/.gc_current_customer)
    fi
fi

if [ -z "$NAMESPACE" ]; then
    echo "ERROR: Please verify the Customer ID and ensure you are logged into the correct cluster."
    exit 1
fi

if [[ ! "$NAMESPACE" =~ ^customer- ]]; then
    NAMESPACE="customer-${NAMESPACE}"
fi

echo "$NAMESPACE" > ~/.gc_current_customer

SCRIPT_POD=$(kubectl get pod -l "app=script-server" --namespace="${NAMESPACE}" -o jsonpath="{.items[0].metadata.name}" 2>/dev/null)

if [ -z "$SCRIPT_POD" ]; then
    echo "ERROR: Please verify the Customer ID and ensure you are logged into the correct cluster."
    exit 1
fi

echo "Connecting via gcsh to \"${TARGET}\"..."
echo "--------------------------------------------------------"

kubectl exec -it "$SCRIPT_POD" -n "${NAMESPACE}" -- /var/lib/guardicore/cloud/management/application/scripts/gcsh/gcsh.sh "$TARGET"
