resource "google_compute_firewall" "default_ssh" {
  name    = "petclinic-allow-ssh-tf"
  network = google_compute_network.custom-test.id

  allow {
    protocol = "tcp"
    ports    = ["22"]

  }
  source_ranges = ["0.0.0.0/0"]

  source_tags = ["ssh"]

}