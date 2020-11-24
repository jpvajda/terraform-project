terraform {
  required_version = "~> 0.13.0"

  required_providers {
    newrelic = {
      source  = "newrelic/newrelic"
      version = "~> 2.12"
    }
  }
}

provider "newrelic" {
  account_id = var.account_id
  api_key    = var.api_key
  region     = "US"
}

data "newrelic_entity" "example_app" {
  name   = "Tims-glorious-application"
  domain = "APM" # or BROWSER, INFRA, MOBILE, SYNTH, depending on your entity's domain
  type   = "APPLICATION"
}

resource "newrelic_alert_policy" "golden_signal_policy" {
  name = "Golden Signals - ${data.newrelic_entity.example_app.name}"
}

# Response time
resource "newrelic_alert_condition" "response_time_web" {
  policy_id       = newrelic_alert_policy.golden_signal_policy.id
  name            = "High Response Time (Web) - ${data.newrelic_entity.example_app.name}"
  type            = "apm_app_metric"
  entities        = [data.newrelic_entity.example_app.application_id]
  metric          = "response_time_web"
  runbook_url     = "https://www.example.com"
  condition_scope = "application"
  term {
    duration      = 5
    operator      = "above"
    priority      = "critical"
    threshold     = "5"
    time_function = "all"
  }
}

# Low throughput
resource "newrelic_alert_condition" "throughput_web" {
  policy_id       = newrelic_alert_policy.golden_signal_policy.id
  name            = "Low Throughput (Web)"
  type            = "apm_app_metric"
  entities        = [data.newrelic_entity.example_app.application_id]
  metric          = "throughput_web"
  condition_scope = "application"
  # Define a critical alert threshold that will
  # trigger after 5 minutes below 5 requests per minute.
  term {
    priority      = "critical"
    duration      = 5
    operator      = "below"
    threshold     = "5"
    time_function = "all"
  }
}

# Error percentage
resource "newrelic_alert_condition" "error_percentage" {
  policy_id       = newrelic_alert_policy.golden_signal_policy.id
  name            = "High Error Percentage"
  type            = "apm_app_metric"
  entities        = [data.newrelic_entity.example_app.application_id]
  metric          = "error_percentage"
  runbook_url     = "https://www.example.com"
  condition_scope = "application"

  # Define a critical alert threshold that will trigger after 5 minutes above a 5% error rate.
  term {
    duration      = 5
    operator      = "above"
    threshold     = "5"
    time_function = "all"
  }
}

# High CPU usage
resource "newrelic_infra_alert_condition" "high_cpu" {
  policy_id   = newrelic_alert_policy.golden_signal_policy.id
  name        = "High CPU usage"
  type        = "infra_metric"
  event       = "SystemSample"
  select      = "cpuPercent"
  comparison  = "above"
  runbook_url = "https://www.example.com"
  where       = "(`applicationId` = '${data.newrelic_entity.example_app.application_id}')"

  # Define a critical alert threshold that will trigger after 5 minutes above 90% CPU utilization.
  critical {
    duration      = 5
    value         = 90
    time_function = "all"
  }
}

resource "newrelic_alert_channel" "team_email" {
  name = "alert"
  type = "email"
  config {
    recipients              = "jvajda@newrelic.com"
    include_json_attachment = "1"
  }
}

resource "newrelic_alert_policy_channel" "golden_signals" {
  policy_id   = newrelic_alert_policy.golden_signal_policy.id
  channel_ids = [newrelic_alert_channel.team_email.id]
}

# example resource
resource "null_resource" "example" {}
