output "zookeeper_endpoint" {
  value       = "localhost:{docker_conatinaer.zookeeper.ports[0].external}"
  description = "The local endpoints to connect to ZooKeeper"
}
