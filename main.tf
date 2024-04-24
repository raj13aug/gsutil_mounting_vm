data "google_compute_image" "demo" {
  family  = "ubuntu-2204-lts"
  project = "ubuntu-os-cloud"
}

locals {
  region            = "us-central1"
  availability_zone = "us-central1-a"
}

resource "tls_private_key" "ssh" {
  algorithm = "RSA"
}

resource "google_compute_address" "external-static-ip" {
  name   = "ip-${var.name}"
  region = var.region
}

# resource "random_string" "unique_suffix1" {
#   length  = 8
#   upper   = false
#   special = false
# }

resource "google_storage_bucket" "artifact_bucket" {
  name                        = "artifact-bucket-x1n1l5ev"
  location                    = var.region
  force_destroy               = true
  uniform_bucket_level_access = true
}

data "template_file" "client_userdata_script" {
  template = file("${path.root}/start_script.tpl")
  vars = {
    bucket_name = "artifact-bucket-x1n1l5ev"
  }
  depends_on = [google_storage_bucket.artifact_bucket]
}

resource "google_service_account" "default" {
  project      = var.project_id
  account_id   = "service-account-id"
  display_name = "Service Account"
}

resource "google_storage_bucket_iam_member" "buckets" {
  bucket     = google_storage_bucket.artifact_bucket.name
  role       = "roles/storage.objectAdmin"
  member     = "serviceAccount:${google_service_account.default.email}"
  depends_on = [google_service_account.default]
}


resource "google_compute_instance" "demo" {
  project = var.project_id

  name         = var.name
  machine_type = "e2-micro"
  zone         = "${local.region}-a"

  tags = ["demo"]

  boot_disk {
    auto_delete = true

    initialize_params {
      image = data.google_compute_image.demo.self_link

      labels = {
        managed_by = "terraform"
      }
    }
  }

  network_interface {
    network = "default"
    access_config {
      nat_ip = google_compute_address.external-static-ip.address
    }
  }

  service_account {
    email  = google_service_account.default.email
    scopes = ["storage-rw", "compute-rw"]
  }

  metadata = {
    sshKeys = "ubuntu:${tls_private_key.ssh.public_key_openssh}"
  }

  # We can install any tools we need for the demo in the startup script
  metadata_startup_script = data.template_file.client_userdata_script.rendered #file("${path.root}/start_script.sh")

  depends_on = [google_compute_address.external-static-ip, google_storage_bucket.artifact_bucket]

}


resource "google_compute_firewall" "demo-ssh-ipv4" {


  name    = "staging-demo-ssh-ipv4"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = [22]
  }

  allow {
    protocol = "udp"
    ports    = [22]
  }

  allow {
    protocol = "sctp"
    ports    = [22]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = google_compute_instance.demo.tags
}


resource "local_file" "local_ssh_key" {
  content  = tls_private_key.ssh.private_key_pem
  filename = "${path.root}/ssh-keys/ssh_key"
}

resource "local_file" "local_ssh_key_pub" {
  content  = tls_private_key.ssh.public_key_openssh
  filename = "${path.root}/ssh-keys/ssh_key.pub"
}

output "instance_ip" {
  value = google_compute_instance.demo.network_interface.0.access_config.0.nat_ip
}

output "instance_ssh_key" {
  value      = "${abspath(path.root)}/ssh_key"
  depends_on = [tls_private_key.ssh]
}
