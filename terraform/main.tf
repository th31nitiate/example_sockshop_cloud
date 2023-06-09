module "kube_net" {
  source = "./kube_net"

  project = var.project
  ranges  = var.cluster_ranges
  region  = var.region
}

module "compute" {
  source = "./compute"

  project           = var.project
  network           = module.kube_net.network_id
  subnetwork        = module.kube_net.subnet_id
  cloud_func_bucket = var.cloud_func_bucket
  cloud_func_file   = var.cloud_func_file
  location          = var.region
}

module "kube_data" {
  source = "./data"

  project         = var.project
  region          = var.region
  service_account = module.compute.kube_svc_account
}

output "kube_cert" {
  value = module.compute.kubeconfig_output
}