terraform {
  required_providers {
    docker = {
      source = "kreuzwerker/docker"
    }
  }
}

resource "docker_container" "minio" {
  name  = "local-minio"
  image = "minio/minio:latest"
  networks_advanced { name = var.network_name }
  ports { # API
    internal = 9000
    external = 9000
  }
  ports { # Web UI
    internal = 9001
    external = 9001
  }

  env = [
    "MINIO_ROOT_USER=admin",
    "MINIO_ROOT_PASSWORD=supersecret"
  ]
  command = ["server", "/data", "--console-address", ":9001"]
}
