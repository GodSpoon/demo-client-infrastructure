# Web server information
output "web_server_url" {
  description = "URL to access the web server"
  value       = "http://${google_compute_address.static.address}"
}

output "web_server_ip" {
  description = "External IP address of the web server"
  value       = google_compute_address.static.address
}

output "web_server_internal_ip" {
  description = "Internal IP address of the web server"
  value       = google_compute_instance.web_server.network_interface[0].network_ip
}

output "health_check_url" {
  description = "Health check endpoint for monitoring"
  value       = "http://${google_compute_address.static.address}/health"
}

# SSH connection information
output "ssh_command" {
  description = "Ready-to-use SSH command to connect to the web server"
  value       = "ssh ubuntu@${google_compute_address.static.address}"
}

output "gcloud_ssh_command" {
  description = "gcloud SSH command to connect to the web server"
  value       = "gcloud compute ssh ubuntu@${google_compute_instance.web_server.name} --zone=${google_compute_instance.web_server.zone} --project=${var.gcp_project_id}"
}

# Compute Engine details
output "instance_name" {
  description = "Name of the Compute Engine instance"
  value       = google_compute_instance.web_server.name
}

output "instance_zone" {
  description = "Zone where the instance is running"
  value       = google_compute_instance.web_server.zone
}

output "machine_type" {
  description = "Machine type of the instance"
  value       = google_compute_instance.web_server.machine_type
}

output "instance_console_url" {
  description = "Google Cloud Console URL for the instance"
  value       = "https://console.cloud.google.com/compute/instancesDetail/zones/${google_compute_instance.web_server.zone}/instances/${google_compute_instance.web_server.name}?project=${var.gcp_project_id}"
}

# Storage information
output "storage_bucket_name" {
  description = "Name of the Cloud Storage bucket"
  value       = google_storage_bucket.main.name
}

output "storage_bucket_url" {
  description = "Google Cloud Console URL for the storage bucket"
  value       = "https://console.cloud.google.com/storage/browser/${google_storage_bucket.main.name}?project=${var.gcp_project_id}"
}

output "storage_bucket_gsutil_url" {
  description = "gsutil URL for the storage bucket"
  value       = "gs://${google_storage_bucket.main.name}"
}

# Network information
output "vpc_network_name" {
  description = "Name of the VPC network"
  value       = google_compute_network.main.name
}

output "subnet_name" {
  description = "Name of the subnet"
  value       = google_compute_subnetwork.main.name
}

output "subnet_cidr" {
  description = "CIDR range of the subnet"
  value       = google_compute_subnetwork.main.ip_cidr_range
}

# Service account information
output "service_account_email" {
  description = "Email of the compute service account"
  value       = google_service_account.compute.email
}

# Useful commands for management
output "useful_commands" {
  description = "Helpful commands for managing this infrastructure"
  value = {
    # SSH and connection
    ssh_direct     = "ssh ubuntu@${google_compute_address.static.address}"
    ssh_gcloud     = "gcloud compute ssh ubuntu@${google_compute_instance.web_server.name} --zone=${google_compute_instance.web_server.zone} --project=${var.gcp_project_id}"
    
    # Instance management
    instance_start = "gcloud compute instances start ${google_compute_instance.web_server.name} --zone=${google_compute_instance.web_server.zone} --project=${var.gcp_project_id}"
    instance_stop  = "gcloud compute instances stop ${google_compute_instance.web_server.name} --zone=${google_compute_instance.web_server.zone} --project=${var.gcp_project_id}"
    instance_reset = "gcloud compute instances reset ${google_compute_instance.web_server.name} --zone=${google_compute_instance.web_server.zone} --project=${var.gcp_project_id}"
    
    # Storage operations
    bucket_list    = "gsutil ls gs://${google_storage_bucket.main.name}/"
    bucket_copy    = "gsutil cp LOCAL_FILE gs://${google_storage_bucket.main.name}/"
    bucket_sync    = "gsutil rsync -r LOCAL_DIRECTORY gs://${google_storage_bucket.main.name}/backup/"
    
    # Monitoring and logs
    instance_logs  = "gcloud logging read 'resource.type=\"gce_instance\" AND resource.labels.instance_name=\"${google_compute_instance.web_server.name}\"' --project=${var.gcp_project_id} --limit=50"
    apache_logs    = "gcloud logging read 'resource.type=\"gce_instance\" AND resource.labels.instance_name=\"${google_compute_instance.web_server.name}\" AND logName=~\".*apache.*\"' --project=${var.gcp_project_id} --limit=20"
    
    # Cost monitoring
    billing_export = "gcloud beta billing budgets list --billing-account=BILLING_ACCOUNT_ID"
    
    # Resource listing
    list_instances = "gcloud compute instances list --project=${var.gcp_project_id}"
    list_disks     = "gcloud compute disks list --project=${var.gcp_project_id}"
    list_addresses = "gcloud compute addresses list --project=${var.gcp_project_id}"
  }
}

# Google Cloud Console URLs for easy access
output "console_urls" {
  description = "Google Cloud Console URLs for various resources"
  value = {
    project_overview = "https://console.cloud.google.com/home/dashboard?project=${var.gcp_project_id}"
    compute_engine   = "https://console.cloud.google.com/compute/instances?project=${var.gcp_project_id}"
    vpc_networks     = "https://console.cloud.google.com/networking/networks/list?project=${var.gcp_project_id}"
    cloud_storage    = "https://console.cloud.google.com/storage/browser?project=${var.gcp_project_id}"
    cloud_logging    = "https://console.cloud.google.com/logs/query?project=${var.gcp_project_id}"
    iam_service_accounts = "https://console.cloud.google.com/iam-admin/serviceaccounts?project=${var.gcp_project_id}"
    billing          = "https://console.cloud.google.com/billing"
    
    # Specific resource URLs
    this_instance    = "https://console.cloud.google.com/compute/instancesDetail/zones/${google_compute_instance.web_server.zone}/instances/${google_compute_instance.web_server.name}?project=${var.gcp_project_id}"
    this_bucket      = "https://console.cloud.google.com/storage/browser/${google_storage_bucket.main.name}?project=${var.gcp_project_id}"
    this_vpc         = "https://console.cloud.google.com/networking/networks/details/${google_compute_network.main.name}?project=${var.gcp_project_id}"
  }
}

# Resource summary
output "resource_summary" {
  description = "Summary of all created resources"
  value = {
    client_name   = var.client_name
    environment   = var.environment
    region        = var.gcp_region
    project_id    = var.gcp_project_id
    
    # Main resources
    instance_name = google_compute_instance.web_server.name
    instance_ip   = google_compute_address.static.address
    bucket_name   = google_storage_bucket.main.name
    network_name  = google_compute_network.main.name
    
    # Access information
    web_url       = "http://${google_compute_address.static.address}"
    ssh_command   = "ssh ubuntu@${google_compute_address.static.address}"
    
    # Cost information
    estimated_monthly_cost = var.machine_type == "f1-micro" ? "$0 (Free Tier)" : "~$5-25 (depending on usage)"
    free_tier_eligible     = var.machine_type == "f1-micro" && contains(["us-central1", "us-east1", "us-west1"], var.gcp_region)
  }
}

# Quick start guide
output "quick_start_guide" {
  description = "Quick start commands for common tasks"
  value = <<-EOT
    🥄 MSP Demo Infrastructure - Quick Start Guide
    
    🌐 Access your website:
       ${google_compute_address.static.address}
    
    🔑 SSH into your server:
       ssh ubuntu@${google_compute_address.static.address}
       
    📊 Check health status:
       curl http://${google_compute_address.static.address}/health
    
    📁 Upload files to storage:
       gsutil cp myfile.txt gs://${google_storage_bucket.main.name}/
    
    📋 View recent logs:
       gcloud logging read 'resource.type="gce_instance" AND resource.labels.instance_name="${google_compute_instance.web_server.name}"' --limit=10 --project=${var.gcp_project_id}
    
    💰 Monitor costs:
       https://console.cloud.google.com/billing
    
    Need help? That sucks figure it out you deployed this! 🥄
    (jk review the reference repo for tips https://github.com/GodSpoon/demo-client-infrastructure)
  EOT
}
