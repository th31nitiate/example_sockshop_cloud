output "network_id" {
  value = google_compute_network.main_net.id
}

output "subnet_id" {
  value = google_compute_subnetwork.kube_subnet.id
}