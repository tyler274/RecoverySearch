locals {
  cloud_native   = var.secrets_backend == "cloud_native"
  cn_secret_name = "${var.name_prefix}-stack"
  data_device    = "/dev/disk/by-id/google-${var.name_prefix}-data"

  supabase_public_url = "http://${google_compute_address.this.address}:8000"
  site_url            = "http://${google_compute_address.this.address}:${var.web_http_port}"

  cloud_native_access = local.cloud_native ? {
    provider    = "gcp"
    secret_name = local.cn_secret_name
    gcp_project = var.project
  } : null
}

# --- Network ---

resource "google_compute_network" "this" {
  name                    = "${var.name_prefix}-net"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "this" {
  name          = "${var.name_prefix}-subnet"
  ip_cidr_range = "10.42.1.0/24"
  region        = var.region
  network       = google_compute_network.this.id
}

resource "google_compute_firewall" "ssh" {
  name          = "${var.name_prefix}-allow-ssh"
  network       = google_compute_network.this.id
  source_ranges = [var.ssh_allowed_cidr]
  target_tags   = ["${var.name_prefix}-vm"]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}

resource "google_compute_firewall" "web" {
  name          = "${var.name_prefix}-allow-web"
  network       = google_compute_network.this.id
  source_ranges = [var.web_allowed_cidr]
  target_tags   = ["${var.name_prefix}-vm"]

  allow {
    protocol = "tcp"
    ports    = ["80", "443", "3000", "8000", "8443"]
  }
}

resource "google_compute_address" "this" {
  name   = "${var.name_prefix}-ip"
  region = var.region
}

# --- Cloud-native secrets (Secret Manager + service account) ---

resource "google_service_account" "vm" {
  count = local.cloud_native ? 1 : 0

  account_id   = "${var.name_prefix}-vm"
  display_name = "RecoverySearch VM"
}

resource "google_secret_manager_secret" "stack" {
  count = local.cloud_native ? 1 : 0

  secret_id = local.cn_secret_name
  labels    = var.labels

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "stack" {
  count = local.cloud_native ? 1 : 0

  secret      = google_secret_manager_secret.stack[0].id
  secret_data = jsonencode(var.secret_values)
}

resource "google_secret_manager_secret_iam_member" "vm" {
  count = local.cloud_native ? 1 : 0

  secret_id = google_secret_manager_secret.stack[0].id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.vm[0].email}"
}

# --- Bootstrap ---

module "bootstrap" {
  source = "../bootstrap"

  supabase_public_url      = local.supabase_public_url
  site_url                 = local.site_url
  additional_redirect_urls = var.additional_redirect_urls
  app_repo_url             = var.app_repo_url
  app_repo_ref             = var.app_repo_ref
  web_http_port            = var.web_http_port
  data_device              = local.data_device

  secrets_backend = var.secrets_backend
  vault           = try(var.external_secrets_access.vault, null)
  doppler         = try(var.external_secrets_access.doppler, null)
  cloud_native    = local.cloud_native_access
}

# --- Instance + data disk ---

resource "google_compute_disk" "data" {
  name = "${var.name_prefix}-data"
  type = "pd-ssd"
  zone = var.zone
  size = var.data_disk_size_gb
}

resource "google_compute_instance" "this" {
  name         = "${var.name_prefix}-vm"
  machine_type = var.instance_size
  zone         = var.zone
  tags         = ["${var.name_prefix}-vm"]
  labels       = var.labels

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2404-lts-amd64"
      size  = var.os_disk_size_gb
      type  = "pd-ssd"
    }
  }

  attached_disk {
    source      = google_compute_disk.data.id
    device_name = "${var.name_prefix}-data"
  }

  network_interface {
    subnetwork = google_compute_subnetwork.this.id

    access_config {
      nat_ip = google_compute_address.this.address
    }
  }

  metadata = {
    ssh-keys       = "${var.admin_username}:${var.ssh_public_key}"
    startup-script = module.bootstrap.user_data
  }

  dynamic "service_account" {
    for_each = local.cloud_native ? [1] : []
    content {
      email  = google_service_account.vm[0].email
      scopes = ["cloud-platform"]
    }
  }
}

# --- Optional DNS ---

resource "google_dns_record_set" "this" {
  count = var.dns_managed_zone != "" ? 1 : 0

  name         = var.dns_record_name
  managed_zone = var.dns_managed_zone
  type         = "A"
  ttl          = 300
  rrdatas      = [google_compute_address.this.address]
}
