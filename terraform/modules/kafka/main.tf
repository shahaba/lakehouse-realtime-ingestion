terraform {
  required_providers {
    docker = {
      source = "kreuzwerker/docker"
    }
  }
}

resource "docker_container" "kafka" {
  name  = "local-kafka"
  image = "apache/kafka:4.3.1"
  networks_advanced { name = var.network_name }
  ports {
    internal = 9092
    external = 9092
  }

  env = [
    "KAFKA_NODE_ID=1",
    "KAFKA_PROCESS_ROLES=broker,controller",
    "KAFKA_CONTROLLER_QUORUM_VOTERS=1@localhost:29093",
    "KAFKA_CONTROLLER_LISTENER_NAMES=CONTROLLER",

    # Add an internal listener for Trino on port 29092
    "KAFKA_LISTENERS=PLAINTEXT://0.0.0.0:9092,CONTROLLER://0.0.0.0:29093,INTERNAL://0.0.0.0:29092",
    "KAFKA_ADVERTISED_LISTENERS=PLAINTEXT://localhost:9092,INTERNAL://local-kafka:29092",
    "KAFKA_LISTENER_SECURITY_PROTOCOL_MAP=CONTROLLER:PLAINTEXT,PLAINTEXT:PLAINTEXT,INTERNAL:PLAINTEXT",
    "KAFKA_INTER_BROKER_LISTENER_NAME=INTERNAL",
    "KAFKA_LOG_DIRS=/tmp/kraft-combined-logs",
    "KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR=1",
    "KAFKA_TRANSACTION_STATE_LOG_REPLICATION_FACTOR=1",
    "KAFKA_TRANSACTION_STATE_LOG_MIN_ISR=1"
  ]
}
