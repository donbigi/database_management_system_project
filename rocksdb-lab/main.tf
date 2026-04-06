provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

resource "google_compute_instance" "rocksdb_vm" {
  name         = "rocksdb-exp"
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 50
      type  = "pd-ssd"
    }
  }

  network_interface {
    network = "default"
    access_config {}
  }

  metadata = {
    setup_rocksdb   = file("scripts/shared/setup_rocksdb.sh")
    load_dataset    = file("scripts/shared/load_dataset.sh")
    run_workload    = file("scripts/shared/run_workload.sh")
    collect_metrics = file("scripts/shared/collect_metrics.py")
    apply_config    = file("scripts/baseline/apply_config.py")
    run_experiment  = file("scripts/baseline/run_experiment.sh")
  }

  metadata_startup_script = file("scripts/shared/startup.sh")

  service_account {
    scopes = ["cloud-platform"]
  }
}
