output "internal_endpoint" {
  value       = "http://${docker_container.minio.name}:9000"
  description = "The internal DNS endpoint for MinIO inside the Docker network"
}

output "access_key" {
  value       = "admin"
  description = "The MinIO root access key"
}

output "secret_key" {
  value       = "supersecret"
  description = "The MinIO root secret key"
}
