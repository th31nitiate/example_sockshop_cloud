## Kubernetes account to be assigned permissions
resource "google_service_account" "k8s_svc_acc" {
  account_id   = "kubernetes-default-svc"
  display_name = "kubernetes-default-svc"
}

## The permission here are ultimately pretty broad
## by reviewing the roles either via console or gcloud
## we are able to pick the correct finer grain roles

resource "google_project_iam_binding" "artifactory" {
  project = "peppy-glyph-388514"
  role    = "roles/artifactregistry.admin"

  members = [
    "serviceAccount:${google_service_account.k8s_svc_acc.email}",
    "serviceAccount:${google_project_service_identity.cloud_build.email}",
  ]
}

resource "google_project_iam_binding" "kube_pubsub" {
  project = var.project
  role    = "roles/pubsub.editor"

  members = [
    "serviceAccount:${google_service_account.k8s_svc_acc.email}",
  ]
}

resource "google_project_iam_binding" "funcation_secrets" {
  project = var.project
  role    = "roles/secretmanager.secretAccessor"

  members = [
    "serviceAccount:${google_service_account.k8s_svc_acc.email}",
  ]
}

resource "google_project_service_identity" "cloud_build" {
  provider = google-beta

  project = var.project
  service = "cloudbuild.googleapis.com"
}

## Double check container admin can pull for registry
resource "google_project_iam_binding" "build_to_container_admin" {
  project = var.project
  role    = "roles/container.admin"

  members = [
    "serviceAccount:${google_project_service_identity.cloud_build.email}"
  ]
}