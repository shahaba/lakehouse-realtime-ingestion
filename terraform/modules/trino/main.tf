variable "network_name" { type = string }
variable "kafka_broker_internal" { type = string }
variable "minio_endpoint" { type = string }
variable "minio_access_key" { type = string }
variable "minio_secret_key" { type = string }

terraform {
  required_providers {
    docker = {
      source = "kreuzwerker/docker"
    }
  }
}


resource "docker_container" "trino" {
  name  = "local-trino"
  image = "trinodb/trino:latest"
  networks_advanced { name = var.network_name }
  ports {
    internal = 8080
    external = 8080
  }

  # Trino configurations would be mounted here via files using 
  # the 'upload' block or host volume mounts to dynamically inject 
  # catalog configuration properties pointing to var.kafka_broker_internal
}
