# Wrapper pedagogique: base vLLM pinnee + labels OCI. Le modele n'est PAS dans
# l'image: vLLM le telecharge depuis HuggingFace au demarrage (cache HF monte
# en volume par cloud-init, voir infra/).
#
# Build local:  docker build -t vllm-qwen deploy/
# La CI (.github/workflows/build-push-vllm.yml) push vers GHCR.

ARG VLLM_VERSION=v0.24.0
FROM vllm/vllm-openai:${VLLM_VERSION}

# Lie le package GHCR au repo GitHub.
LABEL org.opencontainers.image.source="https://github.com/philippestepniewskiperso/vllm_practice"
LABEL org.opencontainers.image.description="vLLM OpenAI-compatible server (modele telecharge au demarrage)"
