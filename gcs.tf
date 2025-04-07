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