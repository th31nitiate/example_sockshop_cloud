resource "google_pubsub_topic" "pubsub_topics" {
  count = length(var.src_repos)
  name  = "${var.project}-topic-${var.src_repos[count.index]}"
}


## There better data structure that can be used here
resource "google_pubsub_topic" "docker" {
  name = "${var.project}-topic-docker"
}

resource "google_cloudbuild_trigger" "build_containers" {
  location = var.region
  name     = "build-containers"

  pubsub_config {
    topic = google_pubsub_topic.pubsub_topics.0.id
  }

  source_to_build {
    uri       = google_sourcerepo_repository.repos.0.url
    repo_type = "CLOUD_SOURCE_REPOSITORIES"
    ref       = "main"
  }

  git_file_source {
    path      = "cloudbuild.yaml"
    repo_type = "CLOUD_SOURCE_REPOSITORIES"
  }

}

resource "google_cloudbuild_trigger" "deploy_svcs_kubernetes" {
  location = var.region
  name     = "deploy-kubernetes-svcs"

  pubsub_config {
    topic = google_pubsub_topic.pubsub_topics.1.id
  }

  source_to_build {
    uri       = google_sourcerepo_repository.repos.1.url
    repo_type = "CLOUD_SOURCE_REPOSITORIES"
    ref       = "main"
  }

  git_file_source {
    path      = "cloudbuild.yaml"
    repo_type = "CLOUD_SOURCE_REPOSITORIES"
  }

}