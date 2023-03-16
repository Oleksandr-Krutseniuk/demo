resource "google_compute_global_address" "private_ip_address" { #ip for private connection
  provider = google-beta

  name          = "private-ip-address"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.custom-test.id
}

resource "google_service_networking_connection" "private_vpc_connection" { #private connection+allocated ip
  provider = google-beta

  network                 = google_compute_network.custom-test.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
}

resource "random_id" "db_name_suffix" {
  byte_length = 4
}
resource "google_sql_database_instance" "instance" { #database instance
  provider = google-beta

  name             = "petclinic-db-tf-${random_id.db_name_suffix.hex}"
  region           = var.region
  database_version = "MYSQL_5_7"

  depends_on = [google_service_networking_connection.private_vpc_connection]

  settings {
    tier = "db-f1-micro"
    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.custom-test.id
    }
  }
  deletion_protection = "false"
}

provider "google-beta" {}