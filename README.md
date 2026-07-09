# vllm-practice

Entraînement au déploiement et à l'usage de **vLLM** sur **Scaleway** (GPU Instance + Docker).
La CI (GitHub Actions) build une image custom → **GHCR** ; l'instance la pull et vLLM
télécharge le modèle depuis HuggingFace au démarrage. Infra via Terraform,
client Python OpenAI-compatible + benchmark.

```
deploy/   Dockerfile — wrapper vLLM pinné, buildé par la CI
.github/  CI: build de l'image et push vers ghcr.io
infra/    Terraform — instance GPU, lance vLLM via cloud-init (docker compose)
client/   Client chat OpenAI-compat + benchmark + smoke test
```

Chaîne : `Dockerfile → CI → GHCR → docker compose (cloud-init) → instance GPU`.

> ⚠️ Les GPU Scaleway sont **facturés à l'heure**. `terraform destroy` dès que terminé.

## Prérequis

- Compte Scaleway + clés API (access/secret key, project id)
- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.6
- [uv](https://docs.astral.sh/uv/) (gestion deps Python)
- Une paire de clés SSH

## 1. Builder l'image (CI → GHCR)

Le workflow `build-push-vllm` se lance au push sur `main` (ou manuellement via
*Run workflow*) : build `deploy/Dockerfile` (base `vllm/vllm-openai` pinnée) →
push `ghcr.io/<owner>/vllm-qwen:{latest,sha}`.
Auth via `GITHUB_TOKEN` natif : **aucun secret à configurer**.

**Après le premier push (une fois)** : le package GHCR est privé par défaut →
le rendre **public** pour que l'instance pull sans auth :
GitHub → Packages → `vllm-qwen` → Package settings → Change visibility → Public.

## 2. Déployer l'instance GPU

```bash
export SCW_ACCESS_KEY=... SCW_SECRET_KEY=...
export SCW_DEFAULT_PROJECT_ID=... SCW_DEFAULT_ORGANIZATION_ID=...

cd infra
cp terraform.tfvars.example terraform.tfvars   # éditer ssh_public_key + CIDRs
terraform init
terraform apply
```

Outputs : `public_ip`, `vllm_base_url`, `ssh_command`, `vllm_image`.

cloud-init écrit `/opt/vllm/docker-compose.yml` et lance `docker compose up -d`
(`restart: unless-stopped` gère crashs et reboots). Le premier démarrage
**télécharge le modèle** depuis HuggingFace (~1 GB, quelques minutes) ; le cache
HF est monté en volume, donc pas de re-téléchargement au restart.

```bash
# Suivre le boot du serveur
ssh root@<IP> 'docker compose -f /opt/vllm/docker-compose.yml logs -f'
```

## 3. Configurer le client

```bash
cd ..              # racine du projet
uv sync            # installe openai, httpx, python-dotenv
cp .env.example .env
# Mettre VLLM_BASE_URL = sortie terraform `vllm_base_url`
```

## 4. Tester

```bash
./client/smoke_test.sh                  # /health, /v1/models, 1 chat
uv run python client/chat.py "Bonjour ?"
uv run python client/benchmark.py --requests 20 --concurrency 4
```

## 5. Détruire (stoppe la facturation)

```bash
cd infra && terraform destroy
```

## Changer de modèle

`model = "<org>/<nom>"` dans `terraform.tfvars` **et** `MODEL=` dans `.env`
(les deux doivent matcher) → `terraform apply`. Modèle gated HF (Llama, Gemma…) :
il faudrait ajouter un token — non géré ici, les modèles Qwen sont publics.

| GPU              | VRAM  | Pour                              |
|------------------|-------|-----------------------------------|
| `L4-1-24G`       | 24 GB | Petits modèles (≤7B quantisés)    |
| `H100-1-80G`     | 80 GB | Modèles 7B–70B                    |

## Debug sur l'instance

```bash
ssh root@<IP>
cd /opt/vllm
docker compose ps
docker compose logs -f
docker compose restart
```
