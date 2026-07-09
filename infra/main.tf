terraform {
  required_version = ">= 1.6"
  required_providers {
    scaleway = {
      source  = "scaleway/scaleway"
      version = ">= 2.39"
    }
  }
}

# Auth via env: SCW_ACCESS_KEY, SCW_SECRET_KEY, SCW_DEFAULT_PROJECT_ID,
# SCW_DEFAULT_ORGANIZATION_ID. Voir README.
provider "scaleway" {
  zone   = var.zone
  region = var.region
}

# IP publique dediee (flexible IP).
resource "scaleway_instance_ip" "vllm" {
  zone = var.zone
}

# Security group: SSH (22) restreint a allowed_ssh_cidr, API vLLM (8000)
# restreint a allowed_api_cidr.
resource "scaleway_instance_security_group" "vllm" {
  zone                    = var.zone
  name                    = "vllm-sg"
  inbound_default_policy  = "drop"
  outbound_default_policy = "accept"

  inbound_rule {
    action   = "accept"
    port     = 22
    ip_range = var.allowed_ssh_cidr
  }

  inbound_rule {
    action   = "accept"
    port     = 8000
    ip_range = var.allowed_api_cidr
  }
}

# Instance GPU. cloud-init ecrit /opt/vllm/docker-compose.yml et lance vLLM.
resource "scaleway_instance_server" "vllm" {
  zone              = var.zone
  name              = "vllm-practice"
  type              = var.gpu_type
  image             = var.image
  ip_id             = scaleway_instance_ip.vllm.id
  security_group_id = scaleway_instance_security_group.vllm.id

  root_volume {
    size_in_gb = var.root_volume_size_gb
  }

  user_data = {
    cloud-init = templatefile("${path.module}/cloud-init.yaml", {
      model          = var.model
      ssh_public_key = var.ssh_public_key
      max_model_len  = var.max_model_len
      gpu_mem_util   = var.gpu_memory_utilization
      vllm_image     = var.vllm_image
    })
  }
}
