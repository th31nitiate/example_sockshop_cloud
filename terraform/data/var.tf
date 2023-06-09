variable "project" {
  type = string
}

variable "region" {
  type = string
}

variable "services" {
  type    = list(string)
  default = ["monitoring", "sock-shop"]
}

variable "src_repos" {
  type    = list(string)
  default = ["docker_files", "kube_charts"]
}

variable "service_account" {
  type = string
}