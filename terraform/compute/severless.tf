resource "google_secret_manager_secret" "kubeconfig" {
  secret_id = "config"

  labels = {
    label = "kubeconfig-secret"
  }

  replication {
    automatic = true
  }
}


resource "google_secret_manager_secret_version" "kubeconfig" {
  secret = google_secret_manager_secret.kubeconfig.id

  secret_data = data.template_file.kubeconfig.rendered
}



resource "google_cloudfunctions2_function" "grafana_provision" {
  name        = "${var.project}-funcation"
  location    = "us-central1"
  description = "Initial funcation for provisioning grafana"

  build_config {
    runtime     = "go120"
    entry_point = "PubSubTrigger"
    source {
      storage_source {
        bucket = var.cloud_func_bucket
        object = var.cloud_func_file
      }
    }
  }

  service_config {
    max_instance_count = 1
    available_memory   = "256M"
    timeout_seconds    = 60
    all_traffic_on_latest_revision = false


    service_account_email = google_service_account.k8s_svc_acc.email
    secret_volumes {
      secret     = google_secret_manager_secret.kubeconfig.secret_id
      mount_path = "/kube"
      project_id = var.project
    }

  }

  event_trigger {
    event_type   = "google.cloud.pubsub.topic.v1.messagePublished"
    pubsub_topic = google_pubsub_topic.funcation.id
  }

  depends_on = [google_secret_manager_secret.kubeconfig, google_secret_manager_secret_version.kubeconfig]
}


resource "google_pubsub_topic" "funcation" {
  name = "${var.project}-topic-funcation"

}