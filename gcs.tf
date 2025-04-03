    provider "google" {
      project = "gcp-trt-training"
      region  = "us-east1"
    }
resource "google_storage_bucket" "bucket" {
 name          = "TRT-BUCKET1"
 location      = "us-east1"
}
resource "google_storage_bucket" "bucket" {
 name          = "TRT-BUCKET2"
 location      = "us-east1"
}