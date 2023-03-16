resource "google_sql_database" "petclinic" { # created DB
  provider = google-beta
  name     = "petclinic"
  instance = google_sql_database_instance.instance.name

  depends_on = [google_sql_database_instance.instance]

}




resource "google_sql_user" "users" { # created a user for DB
  name     = "petclinic"
  instance = google_sql_database_instance.instance.name
  password = "petclinic"

  depends_on = [google_sql_database_instance.instance]

}
