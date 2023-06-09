resource "google_compute_network" "main_net" {
  name                    = "${var.project}-main-net"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "kube_subnet" {
  name          = "kube-net"
  ip_cidr_range = "10.31.31.0/24"
  region        = var.region
  network       = google_compute_network.main_net.id

  secondary_ip_range = [for name, value in var.ranges : merge(value, { range_name = "${var.project}-${value["range_name"]}" })]
}


resource "google_compute_router" "kube_net_router" {
  name    = "kube-net-router"
  region  = google_compute_subnetwork.kube_subnet.region
  network = google_compute_network.main_net.id

  bgp {
    asn = 64514
  }
}

resource "google_compute_router_nat" "kube_net_nat" {
  name                               = "${google_compute_router.kube_net_router.name}-nat"
  router                             = google_compute_router.kube_net_router.name
  region                             = google_compute_router.kube_net_router.region
  nat_ip_allocate_option             = "AUTO_ONLY" ## Here we can disbale IP allocation instead of defining that in the node pool
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}
