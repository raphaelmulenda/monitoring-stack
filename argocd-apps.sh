#!/bin/bash

# Exit on error
set -e

# Variables
PROJECT_NAME="monitoring-stack"
NAMESPACE="argocd"
CHART_PATH="kubernetes/argocd-apps"
VALUES_FILE="$CHART_PATH/values.yaml"

# Ensure the script is run from the correct base directory
BASE_DIR=$(dirname "$(realpath "$0")")
echo "Running script from: $BASE_DIR"
cd "$BASE_DIR"

# Ensure ArgoCD namespace exists
echo "Ensuring namespace '$NAMESPACE' exists..."
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Add the Argo Helm repo
echo "Adding Argo Helm repo..."
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

# Update Helm dependencies
if [[ -d "$CHART_PATH" ]]; then
  echo "Updating Helm dependencies in: $CHART_PATH"
  cd "$CHART_PATH"
  helm dependency update
  helm dependency build
  cd "$BASE_DIR"  # Return to the base directory
else
  echo "Error: Chart path '$CHART_PATH' does not exist."
  exit 1
fi

# Check if values.yaml exists
if [[ -f "$VALUES_FILE" ]]; then
  echo "Using values file: $VALUES_FILE"
else
  echo "Error: Values file '$VALUES_FILE' does not exist."
  exit 1
fi

# Deploy the Helm chart
echo "Deploying Helm chart..."
helm upgrade --install "${PROJECT_NAME}-apps" "$CHART_PATH" \
  --namespace "$NAMESPACE" --values "$VALUES_FILE"

echo "Deployment completed successfully!"
