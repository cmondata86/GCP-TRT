    provider "google" {
      project = "gcp-trt-training"
      region  = "us-east1"
    }
resource "google_storage_bucket" "bucket1" {
 name          = "trt-bucket1"
 location      = "us-east1"
}

resource "google_alloydb_cluster" "trt_alloy_cluster" {
  cluster_id   = "trt_alloy_cluster"
  region       = "us-east1"
  location     = "us-east1-a"
  network      = "default"

  initial_user {
    username = "postgres"
    password = "postgres123" # Replace with a secure password
  }
}

resource "google_alloydb_instance" "trt_alloy_instance" {
  instance_id  = "trt_alloy_instance"
  cluster      = google_alloydb_cluster.trt_alloy_cluster.id
  region       = google_alloydb_cluster.trt_alloy_cluster.region
  instance_type = "PRIMARY"
  machine_config {
    cpu_count = 2
  }
}