resource "google_compute_firewall" "default_http" {
  name    = "petclinic-allow-http-tf"
  network = google_compute_network.custom-test.id

  allow {
    protocol = "tcp"
    ports    = ["8080"]

  }
  source_ranges = ["0.0.0.0/0"]

  source_tags = ["web"]

}