    provider "google" {
      project = "gcp-trt-training"
      region  = "us-east1"
    }
resource "google_storage_bucket" "bucket1" {
 name          = "trt-bucket1"
 location      = "us-east1"
}

resource "google_storage_bucket" "bucket2" {
 name          = "trt-bucket2"
 location      = "us-east1"
}

resource "google_storage_bucket" "bucket3" {
 name          = "trt-bucket3"
 location      = "us-east1"
}