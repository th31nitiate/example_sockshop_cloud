## Make sure to change this docker
resource "google_sourcerepo_repository" "repos" {
  count = length(var.src_repos)
  name  = var.src_repos[count.index]
  pubsub_configs {
    topic                 = google_pubsub_topic.pubsub_topics[count.index].id
    message_format        = "JSON"
    service_account_email = var.service_account
  }
}