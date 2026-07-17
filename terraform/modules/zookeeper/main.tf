terraform {
  required_providers {
    docker = {
      source = "kreuzwerker/docker"
    }
  }
}

resource "docker_image" "zookeeper_image" {
  name         = "zookeeper:latest"
  keep_locally = true
}

resource "docker_container" "zookeeper" {
  name    = "local_zookeeper"
  image   = docker_image.zookeeper_image
  restart = "always"

  networks_advanced {
    name = var.network_name
  }

  # Expose standard ZooKeeper client ports
  ports {
    internal = 2181
    external = 2181
  }

  # Environment variables for config
  env = [
    "ZOO_MU_ID=1"
    "ZOO_PORT=2181"
  ]
}
