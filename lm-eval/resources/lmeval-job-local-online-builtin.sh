#!/bin/bash

MODEL_NAME="${MODEL_NAME:-google/flan-t5-base}"
TASK_NAME="${TASK_NAME:-arc_easy}"
GPU="${GPU:-false}"

TMP_YAML=$(mktemp /tmp/lmeval_job.XXXXXX.yaml)

BASE_YAML="
apiVersion: trustyai.opendatahub.io/v1alpha1
kind: LMEvalJob
metadata:
  name: \"lmeval-test\"
  namespace: \"test\"
spec:
  allowOnline: true
  model: hf
  modelArgs:
    - name: pretrained
      value: \"{{MODEL_NAME}}\"
  taskList:
    taskNames:
      - \"{{TASK_NAME}}\"
  logSamples: true
"

if [[ "$GPU" == "true" ]]; then
  GPU_SECTION="
  pod:
    container:
      resources:
        limits:
          cpu: '1'
          memory: 8Gi
          nvidia.com/gpu: '1'
        requests:
          cpu: '1'
          memory: 8Gi
          nvidia.com/gpu: '1'
"
  YAML_CONTENT="${BASE_YAML}${GPU_SECTION}"
else
  YAML_CONTENT="${BASE_YAML}"
fi

echo "$YAML_CONTENT" | sed \
  -e "s|{{MODEL_NAME}}|$MODEL_NAME|g" \
  -e "s|{{TASK_NAME}}|$TASK_NAME|g" > "$TMP_YAML"

echo "Generated YAML file:"
cat "$TMP_YAML"

kubectl apply -f "$TMP_YAML"

rm "$TMP_YAML"
