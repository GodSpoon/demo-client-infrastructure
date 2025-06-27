# Random suffix for unique resource names
resource "random_id" "suffix" {
  byte_length = 4
}

# VPC Network
resource "google_compute_network" "main" {
  name                    = "${var.client_name}-${var.environment}-vpc"
  auto_create_subnetworks = false
  mtu                     = 1460
}

# Subnet
resource "google_compute_subnetwork" "main" {
  name          = "${var.client_name}-${var.environment}-subnet"
  ip_cidr_range = "10.0.1.0/24"
  region        = var.gcp_region
  network       = google_compute_network.main.id

  # Enable private Google access so instances can reach Google APIs without external IP
  private_ip_google_access = true
}

# Firewall rule to allow HTTP traffic
resource "google_compute_firewall" "allow_http" {
  name    = "${var.client_name}-${var.environment}-allow-http"
  network = google_compute_network.main.name

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["web-server"]
}

# Firewall rule to allow SSH from MSP IP range
resource "google_compute_firewall" "allow_ssh" {
  name    = "${var.client_name}-${var.environment}-allow-ssh"
  network = google_compute_network.main.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = [var.msp_ip_range]
  target_tags   = ["ssh-access"]
}

# Static IP address
resource "google_compute_address" "static" {
  name   = "${var.client_name}-${var.environment}-static-ip"
  region = var.gcp_region
}

# Startup script to install and configure Apache
locals {
  startup_script = <<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y apache2
    
    # Create a simple index page
    cat <<HTML > /var/www/html/index.html
    <!DOCTYPE html>
    <html>
    <head>
        <title>${var.client_name} - ${var.environment}</title>
        <style>
            body { 
                font-family: Arial, sans-serif; 
                margin: 40px;
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                color: white;
            }
            .container { 
                background: rgba(255,255,255,0.1);
                padding: 30px;
                border-radius: 10px;
                text-align: center;
            }
            .spoon { font-size: 2em; }
        </style>
    </head>
    <body>
        <div class="container">
            <h1><span class="spoon">🥄</span> Welcome to ${var.client_name}</h1>
            <h2>Environment: ${var.environment}</h2>
            <p>This infrastructure is managed by your MSP using OpenTofu and Scalr!</p>
            <p>Deployed on: $(date)</p>
            <p>Instance: $(hostname)</p>
            <p>Region: ${var.gcp_region}</p>
            <hr>
            <p><em>Spoon-fed infrastructure, just the way you like it! 🥄</em></p>
        </div>
    </body>
    </html>
HTML

    # Start Apache and enable it
    systemctl start apache2
    systemctl enable apache2
    
    # Install Google Cloud Logging agent
    curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
    sudo bash add-google-cloud-ops-agent-repo.sh --also-install
    
    # Configure basic logging
    mkdir -p /var/log/msp-demo
    echo "$(date): MSP Demo instance started" >> /var/log/msp-demo/startup.log
    
    # Set up a simple health check endpoint
    cat <<HEALTH > /var/www/html/health
    {
      "status": "healthy",
      "timestamp": "$(date -Is)",
      "service": "msp-demo-web",
      "client": "${var.client_name}",
      "environment": "${var.environment}"
    }
HEALTH
  EOF
}

# Compute Engine instance
resource "google_compute_instance" "web_server" {
  name         = "${var.client_name}-${var.environment}-web"
  machine_type = var.machine_type
  zone         = "${var.gcp_region}-a"

  # Use the latest Ubuntu LTS image
  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 10  # 10GB is within free tier (30GB limit)
      type  = "pd-standard"
    }
  }

  # Network configuration
  network_interface {
    network    = google_compute_network.main.id
    subnetwork = google_compute_subnetwork.main.id

    # Assign the static IP
    access_config {
      nat_ip = google_compute_address.static.address
    }
  }

  # SSH key for access
  metadata = {
    ssh-keys = "ubuntu:${var.ssh_public_key}"
  }

  # Startup script
  metadata_startup_script = local.startup_script

  # Network tags for firewall rules
  tags = ["web-server", "ssh-access"]

  # Service account for the instance
  service_account {
    email  = google_service_account.compute.email
    scopes = ["cloud-platform"]
  }

  # Labels for organization
  labels = {
    client      = var.client_name
    environment = var.environment
    managed_by  = "msp-opentofu"
    project     = "demo-infrastructure"
  }
}

# Service account for the compute instance
resource "google_service_account" "compute" {
  account_id   = "${var.client_name}-${var.environment}-compute"
  display_name = "${var.client_name} ${var.environment} Compute Service Account"
  description  = "Service account for ${var.client_name} ${var.environment} compute instances"
}

# Grant logging permissions to the service account
resource "google_project_iam_member" "compute_logging" {
  project = var.gcp_project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.compute.email}"
}

# Grant monitoring permissions to the service account
resource "google_project_iam_member" "compute_monitoring" {
  project = var.gcp_project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.compute.email}"
}

# Cloud Storage bucket for backups and file storage
resource "google_storage_bucket" "main" {
  name     = "${var.client_name}-${var.environment}-storage-${random_id.suffix.hex}"
  location = var.gcp_region

  # Enable uniform bucket-level access
  uniform_bucket_level_access = true

  # Lifecycle rule to manage costs
  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type = "Delete"
    }
  }

  # Enable versioning
  versioning {
    enabled = true
  }

  # Labels for organization
  labels = {
    client      = var.client_name
    environment = var.environment
    managed_by  = "msp-opentofu"
    project     = "demo-infrastructure"
  }
}

# IAM binding to allow the compute service account to use the bucket
resource "google_storage_bucket_iam_member" "compute_storage" {
  bucket = google_storage_bucket.main.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.compute.email}"
}

# Create a sample file in the bucket
resource "google_storage_bucket_object" "readme" {
  name   = "README.txt"
  bucket = google_storage_bucket.main.name
  content = <<-EOF
    Welcome to ${var.client_name} ${var.environment} storage!
    
    This bucket is managed by your MSP using Infrastructure as Code.
    
    Created: ${timestamp()}
    Client: ${var.client_name}
    Environment: ${var.environment}
    
    Use this bucket for:
    - Application backups
    - Log file archives
    - Static file storage
    - Data exchange
    
    Questions? Contact your MSP team!
  EOF
}

# Log sink to capture application logs
resource "google_logging_project_sink" "msp_demo_sink" {
  name = "${var.client_name}-${var.environment}-app-logs"

  # Send logs to Cloud Storage for long-term retention
  destination = "storage.googleapis.com/${google_storage_bucket.main.name}/logs"

  # Filter for application logs from our instance
  filter = <<-EOF
    resource.type="gce_instance"
    AND resource.labels.instance_name="${google_compute_instance.web_server.name}"
    AND (
      jsonPayload.message=~".*msp-demo.*"
      OR logName=~".*apache.*"
      OR logName=~".*syslog.*"
    )
  EOF

  # Use a unique writer identity
  unique_writer_identity = true
}

# Grant the log sink permission to write to the bucket
resource "google_storage_bucket_iam_member" "log_sink_writer" {
  bucket = google_storage_bucket.main.name
  role   = "roles/storage.objectCreator"
  member = google_logging_project_sink.msp_demo_sink.writer_identity
}
