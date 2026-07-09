#!/usr/bin/env bash
# Smoke test du serveur vLLM. Charge .env si present.
set -euo pipefail

if [ -f .env ]; then
  set -a; . ./.env; set +a
fi

BASE_URL="${VLLM_BASE_URL:-http://localhost:8000/v1}"
ROOT="${BASE_URL%/v1}"

echo "== /health =="
curl -fsS "${ROOT}/health" && echo "  OK" || echo "  FAIL"

echo "== /v1/models =="
curl -fsS "${BASE_URL}/models" | python3 -m json.tool

echo "== chat completion =="
curl -fsS "${BASE_URL}/chat/completions" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${VLLM_API_KEY:-EMPTY}" \
  -d "{
    \"model\": \"${MODEL:-Qwen/Qwen2.5-1.5B-Instruct}\",
    \"messages\": [{\"role\": \"user\", \"content\": \"Dis bonjour.\"}],
    \"max_tokens\": 32
  }" | python3 -m json.tool
