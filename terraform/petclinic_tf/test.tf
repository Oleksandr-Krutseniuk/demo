resource "google_compute_address" "static" { # public_IP
  name   = "petclinic-public-ip-tf"
  region = var.region
}

data "google_compute_image" "petclinic-instance-image-v2" {
  family  = "petclinic"
  project = "feisty-grid-366306"
}

data "google_service_account" "petclinic-sa" { #added data for sevice account
  account_id = "petclinic-sa"

}

resource "google_compute_instance" "instance_with_ip" {
  name                      = "petclinic-app-tf"
  machine_type              = "f1-micro"
  zone                      = "europe-west1-c"
  allow_stopping_for_update = true

  tags = ["ssh", "web"]

  boot_disk {
    initialize_params {
      image = data.google_compute_image.petclinic-instance-image-v2.self_link
    }
  }

  network_interface {
    network    = google_compute_network.custom-test.id
    subnetwork = google_compute_subnetwork.network-with-private-secondary-ip-ranges.id
    access_config {
      nat_ip = google_compute_address.static.address

    }
  }

  service_account {
    email  = data.google_service_account.petclinic-sa.email
    scopes = ["cloud-platform"]

  }
}

