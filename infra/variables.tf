variable "region" {
  description = "Region Scaleway."
  type        = string
  default     = "fr-par"
}

variable "zone" {
  description = "Zone Scaleway (doit avoir des GPU disponibles)."
  type        = string
  default     = "fr-par-2"
}

variable "gpu_type" {
  description = "Type d'instance GPU. Ex: L4-1-24G (eco), H100-1-80G (gros modeles)."
  type        = string
  default     = "L4-1-24G"
}

variable "image" {
  description = "Image OS GPU Scaleway (Docker + drivers NVIDIA preinstalles)."
  type        = string
  default     = "ubuntu_jammy_gpu_os_12"
}

variable "root_volume_size_gb" {
  description = "Taille du volume root (poids modele + cache HF)."
  type        = number
  default     = 100
}

variable "model" {
  description = "Modele HuggingFace telecharge par vLLM au demarrage du conteneur."
  type        = string
  default     = "Qwen/Qwen2.5-0.5B-Instruct"
}

variable "vllm_image" {
  description = "Image Docker vLLM construite par la CI (package GHCR public)."
  type        = string
  default     = "ghcr.io/philippestepniewskiperso/vllm-qwen:latest"
}

variable "max_model_len" {
  description = "Longueur de contexte max (reduire si OOM)."
  type        = number
  default     = 8192
}

variable "gpu_memory_utilization" {
  description = "Fraction de VRAM utilisee par vLLM (0-1)."
  type        = number
  default     = 0.90
}

variable "ssh_public_key" {
  description = "Cle publique SSH injectee dans l'instance."
  type        = string
}

variable "allowed_ssh_cidr" {
  description = "CIDR autorise pour SSH. Mettre <votre-ip>/32."
  type        = string
}

variable "allowed_api_cidr" {
  description = "CIDR autorise pour l'API vLLM (port 8000)."
  type        = string
}
