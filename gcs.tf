    provider "google" {
      project = "gcp-trt-training"
      region  = "us-east1"
    }

    resource "google_storage_bucket" "static" {
 name          = "BUCKET_NAME"
 location      = "US"
 storage_class = "STANDARD"

 uniform_bucket_level_access = true
}
