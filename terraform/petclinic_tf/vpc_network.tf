resource "google_compute_subnetwork" "network-with-private-secondary-ip-ranges" {
  name          = "petclinic-subnet-tf-eu-west1"
  ip_cidr_range = "10.24.5.0/24"
  region        = var.region
  network       = google_compute_network.custom-test.id
  secondary_ip_range {
    range_name    = "tf-test-secondary-range"
    ip_cidr_range = "192.168.10.0/24"
  }
}

resource "google_compute_network" "custom-test" {
  name                    = "petclinic-vpc-tf"
  auto_create_subnetworks = false
}