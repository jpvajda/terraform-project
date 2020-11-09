terraform {
  required_version = "~> 0.13.0"

  required_providers {
    newrelic = {
      source  = "newrelic/newrelic"
      version = "~> 2.12"
    }
  }
  provider "newrelic" {
    account_id = var.account_id
    api_key    = var.api_key
    region     = "US"
  }
}



