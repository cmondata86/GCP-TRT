    provider "google" {
      project = "gcp-trt-training"
      region  = "us-east1"
    }

#    terraform {
#  backend "remote" {
#    hostname = "app.terraform.io"
#    organization = "Demo_GCP-TRT"
#
#    workspaces {
#      name = "GCP-TRT-Tera-Cloud"
#    }
#  }
#}
resource "google_storage_bucket" "bucket1" {
 name          = "trt-bucket1"
 location      = "us-east1"
}