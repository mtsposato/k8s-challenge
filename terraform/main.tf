data "google_client_openid_userinfo" "me" {
}

resource "google_os_login_ssh_public_key" "cache" {
  user = data.google_client_openid_userinfo.me.email
  key  = var.ssh_key
}

resource "google_compute_network" "network" {
  name                    = "challenge-network"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name          = "challenge-subnet"
  ip_cidr_range = "10.0.0.0/29"
  region        = var.region
  network       = google_compute_network.network.id
}

resource "google_compute_firewall" "rules" {
  name = "allow-ssh-http"
  allow {
    ports    = ["22", "80"]
    protocol = "tcp"
  }
  direction     = "INGRESS"
  network       = google_compute_network.network.id
  priority      = 1000
  source_ranges = [var.ip_range]
  target_tags   = ["allow-ssh-http"]
}

resource "google_compute_firewall" "management-rules" {
  name = "allow-k8s-api"
  allow {
    ports    = ["6443"]
    protocol = "tcp"
  }
  direction     = "INGRESS"
  network       = google_compute_network.network.id
  priority      = 1000
  source_ranges = [var.ip_range]
  target_tags   = ["allow-k8s-api"]
}

resource "google_compute_instance" "master" {
  name           = "master"
  machine_type   = var.machine_type
  desired_status = "RUNNING"
  zone           = var.zone

  tags = ["allow-ssh-http", "allow-k8s-api"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  metadata_startup_script = "sudo apt-get update; sudo apt-get upgrade -y"
  metadata = {
    ssh-keys = "${var.ssh_user}:${file(var.ssh_key)}"
  }
  network_interface {
    subnetwork = google_compute_subnetwork.subnet.id

    access_config {
    }
  }
}

resource "google_compute_instance" "slave" {
  name           = "slave-0${count.index + 1}"
  count          = 2
  desired_status = "RUNNING"
  zone           = var.zone

  machine_type = var.machine_type

  tags = ["allow-ssh-http"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  metadata = {
    ssh-keys = "${var.ssh_user}:${file(var.ssh_key)}"
  }
  metadata_startup_script = "sudo apt-get update; sudo apt-get upgrade -y"

  network_interface {
    subnetwork = google_compute_subnetwork.subnet.id

    access_config {
    }
  }
}

