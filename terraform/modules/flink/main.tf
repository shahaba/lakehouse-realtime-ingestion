terraform {
  required_providers {
    docker = {
      source = "kreuzwerker/docker"
    }
  }
}


# Pull the official Flink image
resource "docker_image" "flink" {
  name         = "flink:${var.flink_version}"
  keep_locally = true
}

# 1. JobManager Container (Master node)
resource "docker_container" "jobmanager" {
  name  = "local-flink-jobmanager"
  image = docker_image.flink.image_id

  networks_advanced {
    name = var.network_name
  }

  # Expose Flink Web UI (8081) and RPC port (6123)
  ports {
    internal = 8081
    external = 8081
  }
  ports {
    internal = 6123
    external = 6123
  }

  # Start command explicitly defining the master role
  command = ["jobmanager"]

  env = [
    "FLINK_PROPERTIES=jobmanager.rpc.address: local-flink-jobmanager"
  ]
}

# 2. TaskManager Container (Worker node)
resource "docker_container" "taskmanager" {
  name  = "local-flink-taskmanager"
  image = docker_image.flink.image_id

  networks_advanced {
    name = var.network_name
  }

  command = ["taskmanager"]

  env = [
    # Point the worker directly to the master node container name
    "FLINK_PROPERTIES=jobmanager.rpc.address: local-flink-jobmanager"
  ]

  # Explicit lifecycle rule: ensures the master is live before worker starts up
  depends_on = [
    docker_container.jobmanager
  ]
}
