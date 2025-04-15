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


resource "google_alloydb_instance" "alloy_instance" {
  instance_id   = "trt-alloy-instance"
  cluster       = google_alloydb_cluster.alloy_cluster.id
  #location        = "us-east1"
  instance_type = "PRIMARY"

  machine_config {
    cpu_count = 2
  }
  labels = {
    environment = "demo-trt" # Replace with your desired key-value pairs
    purpose     = "database"
  }
}


resource "google_alloydb_user" "alloy_user" {
  cluster   = google_alloydb_cluster.alloy_cluster.id
  user_id   = "postgres"
  password  = "postgres123" # Replace with a secure password
  user_type = "ALLOYDB_BUILT_IN"
  depends_on = [google_alloydb_instance.alloy_instance]
}


resource "google_compute_instance" "psql_instance" {
  name         = "psql-instance"
  machine_type = "e2-medium" # Adjust the machine type as needed
  zone         = "us-east1-b" # Replace with your desired zone

  boot_disk {
    initialize_params {
      image = "projects/debian-cloud/global/images/family/debian-11" # Debian 11 image
    }
  }

  network_interface {
    network    = google_compute_network.private_network.id
    subnetwork = google_compute_subnetwork.private_subnetwork.id
    access_config {
      # Ephemeral public IP
    }
  }

  metadata_startup_script = <<-EOT
    #!/bin/bash
    apt-get update
    apt-get install -y postgresql-client
  EOT

  tags = ["psql-instance"]

  service_account {
    email  = "gcp-trt-training@gcp-trt-training.iam.gserviceaccount.com" # Replace with a specific service account if needed
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }
}

resource "google_compute_firewall" "allow_ssh" {
  name    = "allow-ssh"
  network = google_compute_network.private_network.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["35.235.240.0/20"] # IAP IP range
  target_tags   = ["psql-instance"]   # Ensure the VM has this tag
}

# Create a VPC network
resource "google_compute_network" "psc_vpc" {
  name = "trt-psc-vpc"
  auto_create_subnetworks = false
}

# Create a subnetwork in the VPC
resource "google_compute_subnetwork" "psc_subnet" {
  name          = "trt-psc-subnet"
  ip_cidr_range = "10.10.0.0/24" # Adjust the CIDR range as needed
  region        = "us-east1"
  network       = google_compute_network.psc_vpc.id
}

# Reserve a static IP address for the load balancer
resource "google_compute_global_address" "alloydb_lb_ip" {
  name = "alloydb-lb-ip"
}

# Create a backend service for the AlloyDB instances
resource "google_compute_backend_service" "alloydb_backend_service" {
  name                  = "alloydb-backend-service"
  protocol              = "TCP"
  load_balancing_scheme = "EXTERNAL"
  region                = "us-east1" # Ensure this matches the region of the forwarding rule

  backend {
    group = google_compute_instance_group.alloydb_instance_group.self_link
  }

  health_checks = [google_compute_health_check.alloydb_health_check.self_link]
}

# Create a health check for the AlloyDB instances
resource "google_compute_health_check" "alloydb_health_check" {
  name               = "alloydb-health-check"
  check_interval_sec = 10
  timeout_sec        = 5
  tcp_health_check {
    port = 5432 # PostgreSQL default port
  }
}

# Create an instance group for AlloyDB instances
resource "google_compute_instance_group" "alloydb_instance_group" {
  name        = "alloydb-instance-group"
  zone        = "us-east1-b" # Replace with your desired zone
  instances   = [google_compute_instance.psql_instance.self_link]
  named_port {
    name = "postgres"
    port = 5432
  }
}

# Create a forwarding rule for the load balancer
resource "google_compute_forwarding_rule" "alloydb_forwarding_rule" {
  name                  = "alloydb-forwarding-rule"
  load_balancing_scheme = "EXTERNAL"
  ip_protocol           = "TCP"
  port_range            = "5432"
  backend_service       = google_compute_backend_service.alloydb_backend_service.self_link
  ip_address            = google_compute_global_address.alloydb_lb_ip.address
  region                = "us-east1" # Ensure this matches the region of the backend service
}