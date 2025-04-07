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

resource "google_project_service" "service_networking_api" {
  project = "gcp-trt-training" # Replace with your project ID
  service = "servicenetworking.googleapis.com"
  depends_on = [google_project_service.cloudresourcemanager_api]
}


resource "google_project_iam_member" "servicenetworking_admin_user1" {
  project = "gcp-trt-training"
  role    = "roles/servicenetworking.networksAdmin"
  member  = "user:trtjobs.mondal@gmail.com"
}

resource "google_project_iam_member" "servicenetworking_admin_sa1" {
  project = "gcp-trt-training"
  role    = "roles/servicenetworking.networksAdmin"
  member  = "serviceAccount:292380354815-compute@developer.gserviceaccount.com"
}

resource "google_project_iam_member" "servicenetworking_admin_sa2" {
  project = "gcp-trt-training"
  role    = "roles/servicenetworking.networksAdmin"
  member  = "serviceAccount:gcp-trt-training@gcp-trt-training.iam.gserviceaccount.com"
}

resource "google_project_iam_member" "compute_network_admin_user1" {
  project = "gcp-trt-training" # Replace with your project ID
  role    = "roles/compute.networkAdmin"
  member  = "user:trtjobs.mondal@gmail.com" # Replace with the user, service account, or group
}

resource "google_project_iam_member" "compute_network_admin_sa1" {
  project = "gcp-trt-training" # Replace with your project ID
  role    = "roles/compute.networkAdmin"
  member  = "serviceAccount:gcp-trt-training@gcp-trt-training.iam.gserviceaccount.com" # Replace with the user, service account, or group
}

resource "google_project_iam_member" "compute_network_admin_sa2" {
  project = "gcp-trt-training" # Replace with your project ID
  role    = "roles/compute.networkAdmin"
  member  = "serviceAccount:292380354815-compute@developer.gserviceaccount.com" # Replace with the user, service account, or group
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

resource "google_compute_global_address" "private_ip_range" {
  name          = "private-ip-range"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.private_network.id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.private_network.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_range.name]
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
    depends_on = [google_service_networking_connection.private_vpc_connection]
}




