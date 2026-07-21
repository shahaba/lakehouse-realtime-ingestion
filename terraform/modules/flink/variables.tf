variable "network_name" {
  type        = string
  description = "The shared network name passed from the root module"
}

variable "flink_version" {
  type    = string
  default = "2.3-java21" # Adjust version based on your production target
}
