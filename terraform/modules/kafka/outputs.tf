output "internal_endpoint" {
  # Refers to the internal listener defined in the env variables (port 29092)
  value       = "${docker_container.kafka.name}:29092"
  description = "The internal bootstrap broker address for Kafka"
}
