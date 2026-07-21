terraform {
  required_providers {
    docker = {
      source = "kreuzwerker/docker"
    }
  }
}

resource "docker_volume" "minio_data" {
  name = "minio_data_volume"
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

  volumes {
    volume_name    = docker_volume.minio_data.name
    container_path = "/data"
  }
}

# Short Lived container to auto provision Lakehouse bucket
resource "docker_container" "minio_mc" {
  name       = "local-minio-mc"
  image      = "minio/mc:latest"
  entrypoint = ["/bin/sh", "-c"]
  command    = ["until mc alias set myminio http://local-minio:9000 admin supersecret; do echo 'Waiting for MinIO...'; sleep 1; done && mc mb --ignore-existing myminio/lakehouse"]

  networks_advanced {
    name = var.network_name
  }

  depends_on = [docker_container.minio]
}
