## We create a repo for docker containers

resource "google_artifact_registry_repository" "kube_deployments" {
  count         = length(var.services)
  location      = var.region
  repository_id = var.services[count.index]
  description   = "Docker repository for ${var.services[count.index]}"
  format        = "DOCKER"
}