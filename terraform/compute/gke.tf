## We create out cluster a VPC native cluster

resource "google_container_cluster" "kube" {
  name     = "${var.project}-cluster"
  location = var.location

  network    = var.network
  subnetwork = var.subnetwork

  networking_mode = "VPC_NATIVE"

  ip_allocation_policy {
    cluster_secondary_range_name  = "${var.project}-cluster-range"
    services_secondary_range_name = "${var.project}-cluster-services"
  }

  master_auth {
    client_certificate_config {
      issue_client_certificate = true
    }
  }

  node_pool {
    node_count = 2

    network_config {
      enable_private_nodes = true
    }

    node_config {
      preemptible  = true
      machine_type = "e2-medium"
      disk_type    = "pd-standard"
      disk_size_gb = "30"



      service_account = google_service_account.k8s_svc_acc.email
      #oauth_scopes    = [
      #  "https://www.googleapis.com/auth/cloud-platform"
      #]
    }
  }

  cluster_autoscaling {
    enabled = true

    resource_limits {
      resource_type = "cpu"
      minimum = 12
      maximum = 18
    }

    resource_limits {
      resource_type = "memory"
      minimum = 24
      maximum = 30
    }

    auto_provisioning_defaults {
      management {
        auto_repair = true
      }
    }
  }

}



locals {
  context = "gke_${var.project}_${var.location}_${google_container_cluster.kube.name}"
}


data "template_file" "kubeconfig" {
  template = file("${path.module}/kubeconfig.tpl")
  vars = {
    server                     = google_container_cluster.kube.endpoint
    context                    = local.context
    certificate_authority_data = google_container_cluster.kube.master_auth.0.cluster_ca_certificate
    client_certificate_data    = google_container_cluster.kube.master_auth.0.client_certificate
    client_key_data            = google_container_cluster.kube.master_auth.0.client_key
  }
}



output "kubeconfig_output" {
  value = data.template_file.kubeconfig.rendered
}


output "kube_svc_account" {
  value = google_service_account.k8s_svc_acc.email
}

