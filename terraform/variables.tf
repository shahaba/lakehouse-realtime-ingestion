variable "network_name" {
  type        = string
  default     = "local-data-network"
  description = "Docker network name for container communication"
}

variable "minio_root_user" {
  type        = string
  default     = "admin"
  description = "MinIO root access key"
}

variable "minio_root_password" {
  type        = string
  default     = "supersecret"
  sensitive   = true
  description = "MinIO root secret password"
}
