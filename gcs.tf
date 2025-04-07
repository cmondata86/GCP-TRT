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
  depends_on = [google_project_service.cloudresourcemanager_api]
}

resource "google_project_service" "psc_api" {
  project = "gcp-trt-training"
  service = "vpcaccess.googleapis.com"
  depends_on = [google_project_service.cloudresourcemanager_api]
}

resource "google_compute_network" "private_network" {
  name = "trt-private-network"
}

resource "google_compute_subnetwork" "private_subnetwork" {
  name          = "trt-private-subnetwork"
  ip_cidr_range = "10.0.0.0/24"
  region        = "us-east1"
  network       = google_compute_network.private_network.id
}

resource "google_alloydb_cluster" "alloy_cluster" {
  cluster_id = "trt-alloy-cluster"
  location   = "us-east1"
 # network    = google_compute_network.private_network.id

  network_config {
    network = google_compute_network.private_network.id
  }

  continuous_backup_config {
    enabled = true
  }

  automated_backup_policy {
    enabled = true
    weekly_schedule {
      days_of_week = ["MONDAY", "WEDNESDAY", "FRIDAY"]
      start_times {
        hours   = 2
        minutes = 0
      }
    }
  }
}

resource "google_project_service" "service_networking_api" {
  project = "gcp-trt-training" # Replace with your project ID
  service = "servicenetworking.googleapis.com"
  depends_on = [google_project_service.cloudresourcemanager_api]
}

resource "google_alloydb_instance" "alloy_instance" {
  instance_id   = "trt-alloy-instance"
  cluster       = google_alloydb_cluster.alloy_cluster.id
  #location        = "us-east1"
  instance_type = "PRIMARY"

  machine_config {
    cpu_count = 2
  }
}

resource "google_alloydb_user" "alloy_user" {
  cluster   = google_alloydb_cluster.alloy_cluster.id
  user_id   = "postgres"
  password  = "postgres123" # Replace with a secure password
  user_type = "ALLOYDB_BUILT_IN"
  depends_on = [google_alloydb_instance.alloy_instance]
}
