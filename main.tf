locals {
  prefix = var.prefix

  projects = { for key, settings in var.projects : key => merge(
    settings,
    {
      services       = distinct(concat(var.default_services, settings.services))
      gcp_project_id = lower(replace(format("%s-%s", local.prefix, key), " ", "-"))
      labels = merge(
        { for key, value in var.default_labels : key => substr(replace(lower(value), "/[^\\p{Ll}\\p{Lo}\\p{N}_-]+/", "_"), 0, 63) },
        { for key, value in settings.labels : key => substr(replace(lower(value), "/[^\\p{Ll}\\p{Lo}\\p{N}_-]+/", "_"), 0, 63) }
      )
    })
  }

  project_services = flatten([for project, data in google_project.map :
    [
      for service in local.projects[project].services : { "${project}|${service}" = { service = service, project = data.project_id } }
    ]
  ])

  project_audit_configs = flatten([for project, data in google_project.map :
    [
      for service, settings in local.projects[project].audit_log_config : { "${project}|${service}" = { service = service, project = data.project_id, audit_log_config = settings } }
    ]
  ])
}

# ==========================================
# Project creation
# ==========================================
resource "google_project" "map" {
  for_each = local.projects

  project_id      = each.value.gcp_project_id
  name            = each.value.gcp_project_name
  folder_id       = each.value.gcp_folder_id
  billing_account = each.value.gcp_billing_account

  labels = each.value.labels

  auto_create_network = false
}

# Also enable project services
resource "google_project_service" "map" {
  for_each = { for service in local.project_services : keys(service)[0] => values(service)[0] }

  project = each.value.project
  service = each.value.service
}

# ==========================================
# Audit config
# ==========================================
resource "google_project_iam_audit_config" "map" {
  for_each = { for service in local.project_audit_configs : keys(service)[0] => values(service)[0] }

  project = each.value.project
  service = each.value.service

  dynamic "audit_log_config" {
    for_each = each.value.audit_log_config
    iterator = config

    content {
      log_type         = config.key
      exempted_members = [for member, type in try(config.value.exempted_members, {}) : format("%s:%s", type, member)]
    }
  }
}

# ==========================================
# Project lien
# ==========================================
resource "google_resource_manager_lien" "lien" {
  for_each = { for project, settings in local.projects : project => settings if settings.can_delete == false }

  parent       = "projects/${google_project.map[each.key].number}"
  restrictions = ["resourcemanager.projects.delete"]
  origin       = "Arrow Air - project module"
  reason       = "Arrow Air - protect projects from delete"
}

# ==========================================
# Enable Shared VPC Host or Service project
# ==========================================
resource "google_compute_shared_vpc_host_project" "host" {
  for_each = { for project, settings in local.projects : project => settings if settings.shared_vpc_host == true }
  project  = google_project.map[each.key].project_id
}

resource "google_compute_shared_vpc_service_project" "service" {
  for_each        = { for project, settings in local.projects : project => settings if settings.shared_vpc_service != null }
  service_project = google_project.map[each.key].project_id
  host_project    = each.value.shared_vpc_service
}
