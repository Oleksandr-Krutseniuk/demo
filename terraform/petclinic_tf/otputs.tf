output "external_ip" {
  value = google_compute_address.static.address
}

output "cloud_sql_name" {
  value = google_sql_database_instance.instance.name
}