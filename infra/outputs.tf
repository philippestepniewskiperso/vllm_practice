output "public_ip" {
  description = "IP publique de l'instance."
  value       = scaleway_instance_ip.vllm.address
}

output "vllm_base_url" {
  description = "Base URL OpenAI-compatible a mettre dans .env (VLLM_BASE_URL)."
  value       = "http://${scaleway_instance_ip.vllm.address}:8000/v1"
}

output "ssh_command" {
  description = "Commande SSH vers l'instance."
  value       = "ssh root@${scaleway_instance_ip.vllm.address}"
}

output "model" {
  description = "Modele servi."
  value       = var.model
}

output "vllm_image" {
  description = "Image Docker lancee sur l'instance."
  value       = var.vllm_image
}
