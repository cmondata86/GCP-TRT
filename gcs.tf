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