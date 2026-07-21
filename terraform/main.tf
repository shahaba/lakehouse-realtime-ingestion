module "kafka" {
  source       = "./modules/kafka"
  network_name = docker_network.shared_net.name
}

module "minio" {
  source       = "./modules/minio"
  network_name = docker_network.shared_net.name
}

module "trino" {
  source       = "./modules/trino"
  network_name = docker_network.shared_net.name

  # Connect Trino to the other services by passing outputs
  kafka_broker_internal = module.kafka.internal_endpoint
  minio_endpoint        = module.minio.internal_endpoint
  minio_access_key      = module.minio.access_key
  minio_secret_key      = module.minio.secret_key
}

module "flink" {
  source       = "./modules/flink"
  network_name = docker_network.shared_net.name
}
