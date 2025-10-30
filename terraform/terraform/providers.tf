terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "0.141.0"
    }
  }

  required_version = ">=1.8.4"
}

provider "yandex" {
  # token                    = "do not use!!!"
  cloud_id                 = var.cloud_id
  folder_id                = var.folder_id
  zone = "ru-central1-b"
  service_account_key_file = file("~/.authorized_key.json")
}
