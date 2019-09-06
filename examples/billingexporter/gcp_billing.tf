provider "google" {
  credentials = "${file("account.json")}"
  project     = "s3billing"
  region      = "us-central1"
}

provider "aws" {
  region  = "${var.aws_region}"
}

module "awsbilling" {
  source = "./awsbilling"
}

resource "google_storage_bucket" "billingbucket" {
  name     = "${module.awsbilling.billingbucket}"
}

data "google_storage_transfer_project_service_account" "default" {
  project       = "${var.project}"
}

resource "google_storage_bucket_iam_member" "billingbucket" {
  bucket        = "${google_storage_bucket.billingbucket.name}"
  role          = "roles/storage.admin"
  member        = "serviceAccount:${data.google_storage_transfer_project_service_account.default.email}"
  depends_on    = [
    "google_storage_bucket.billingbucket"
  ]
}

resource "google_storage_transfer_job" "s3-bucket-nightly-backup" {
    description = "Backup S3 Billing Data to GS"
    project     = "${var.project}"

    transfer_spec {
        object_conditions {
            max_time_elapsed_since_last_modification = "600s"
        }
        transfer_options {
            delete_objects_unique_in_sink = false
        }
        aws_s3_data_source {
            bucket_name = "${module.awsbilling.billingbucket}"
            aws_access_key {
                access_key_id       = "${var.aws_access_key}"
                secret_access_key   = "${var.aws_secret_key}"
            }
        }
        gcs_data_sink {
            bucket_name = "${google_storage_bucket.billingbucket.name}"
        }
    }

    schedule {
        schedule_start_date {
            year    = 2019
            month   = 8
            day     = 1
        }
        schedule_end_date {
            year    = 2019
            month   = 10
            day     = 1
        }
        start_time_of_day {
            hours   = 12
            minutes = 0
            seconds = 0
            nanos   = 0
        }
    }

    depends_on = [
        "google_storage_bucket_iam_member.billingbucket"
    ]
}

resource "google_storage_bucket" "cloudfunctionbucket" {
  name = "${var.cloud_function_bucket}"
}

resource "google_storage_bucket" "report_destination_bucket" {
  name = "${var.report_destination_bucket}"
}

data "archive_file" "cloud_storage_trigger" {
  type        = "zip"
  output_path = "${path.module}/files/cloud_storage_trigger.zip"
  source {
    content  = "${file("${path.module}/files/main.py")}"
    filename = "main.py"
  }
source {
    content  = "${file("${path.module}/files/requirements.txt")}"
    filename = "requirements.txt"
  }
}

resource "google_storage_bucket_object" "archive" {
  name   = "cloud_storage_trigger.zip"
  bucket = "${google_storage_bucket.cloudfunctionbucket.name}"
  source = "${path.module}/files/cloud_storage_trigger.zip"
  depends_on = ["data.archive_file.cloud_storage_trigger"]
}

resource "google_cloudfunctions_function" "gcs_fetch_function" {
  name                  = "gcs_fetch_function"
  description           = "Function downloads, decompresses and uploads the file to a different bucket"
  runtime               = "python37"
  entry_point           = "hello_gcs"
  available_memory_mb   = 256
  source_archive_bucket = "${google_storage_bucket.cloudfunctionbucket.name}"
  source_archive_object = "${google_storage_bucket_object.archive.name}"
  event_trigger {
      event_type = "google.storage.object.finalize"
      resource = "${google_storage_bucket.billingbucket.name}"
  }
  timeout = 60
  environment_variables = {
    sourcebucket = "${google_storage_bucket.billingbucket.name}"
    destinationbucket = "${google_storage_bucket.report_destination_bucket.name}"
  }
}