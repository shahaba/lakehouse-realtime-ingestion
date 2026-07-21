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

resource "docker_image" "iceberg_rest" {
  name         = "tabulario/iceberg-rest:0.6.0"
  keep_locally = true
}

resource "docker_container" "iceberg_rest" {
  name  = "local-iceberg-rest"
  image = docker_image.iceberg_rest.image_id
  networks_advanced {
    name = docker_network.shared_net.name
  }
  ports {
    internal = 8181
    external = 8181
  }
  env = [
    "AWS_ACCESS_KEY_ID=admin",
    "AWS_SECRET_ACCESS_KEY=supersecret",
    "AWS_REGION=us-east-1",
    "CATALOG_WAREHOUSE=s3a://lakehouse/",
    "CATALOG_IO__IMPL=org.apache.iceberg.aws.s3.S3FileIO",
    "CATALOG_S3_ENDPOINT=http://local-minio:9000",
    "CATALOG_S3_PATH__STYLE__ACCESS=true"
  ]
  depends_on = [module.minio]
}
