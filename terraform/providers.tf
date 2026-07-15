terraform {
  required_version = ">= 1.7.0"
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 4.2.0"
    }
  }
}

provider "docker" {}

# local network so services can talk to each other
resource "docker_network" "shared_net" {
  name = "local-data-network"
}
