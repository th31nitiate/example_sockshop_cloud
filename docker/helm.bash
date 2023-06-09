#!/bin/bash -e

echo "Running: gcloud container clusters get-credentials --project=\"$GCLOUD_PROJECT\" --region=\"$CLOUDSDK_COMPUTE_REGION\" \"$CLOUDSDK_CONTAINER_CLUSTER\""
gcloud container clusters get-credentials --project="$GCLOUD_PROJECT" --region="$CLOUDSDK_COMPUTE_REGION" "$CLOUDSDK_CONTAINER_CLUSTER"

echo "Running helm with the following input: $@"

/helm "$@"

