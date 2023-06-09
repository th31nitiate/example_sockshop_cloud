variable "region" {
  description = "Basic region description"
  default     = "us-central1"
}

variable "project" {
  description = "Basic project decription"
  default     = "peppy-glyph-388514"
}

variable "cluster_ranges" {
  description = "Kubernetes cluster primary and secondary ranges"
  type        = list(map(string))
  default = [
    {
      range_name    = "cluster-range"
      ip_cidr_range = "172.16.0.0/16"
    },
    {
      range_name    = "cluster-services"
      ip_cidr_range = "192.168.0.0/24"
    },
  ]
}

variable "cloud_func_bucket" {
        type = string
}

variable "cloud_func_file" {
        type = string
}