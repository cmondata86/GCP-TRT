    provider "google" {
      project = "gcp-trt-training"
      region  = "us-east1"
    }
resource "google_storage_bucket" "bucket1" {
 name          = "trt-bucket1"
 location      = "us-east1"
}

resource "google_project_service" "cloudresourcemanager_api" {
  project = "gcp-trt-training" # Replace with your project ID
  service = "cloudresourcemanager.googleapis.com"
}

resource "google_project_service" "alloydb_api" {
  project = "gcp-trt-training" # Replace with your project ID
  service = "alloydb.googleapis.com"
}

resource "google_alloydb_cluster" "trt_alloy_cluster" {
  cluster_id   = "trt_alloy_cluster"
  #region       = "us-east1"
  location     = "us-east1-a"
  #network      = "default"
}

resource "google_alloydb_user" "trt_alloy_user" {
  cluster  = google_alloydb_cluster.trt_alloy_cluster.id
  user_id  = "postgres"
  password = "postgres123" # Replace with a secure password
  user_type = "ALLOYDB_BUILT_IN" # Specify the user type
}

resource "google_alloydb_instance" "trt_alloy_instance" {
  instance_id  = "trt_alloy_instance"
  cluster      = google_alloydb_cluster.trt_alloy_cluster.id
 # region       = google_alloydb_cluster.trt_alloy_cluster.region
  instance_type = "PRIMARY"
  machine_config {
    cpu_count = 2
  }
}