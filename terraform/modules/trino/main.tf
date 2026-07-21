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
    external = 8083
  }

  volumes {
    host_path      = abspath("${path.root}/../trino/etc/catalog")
    container_path = "/etc/trino/catalog"
  }
}

