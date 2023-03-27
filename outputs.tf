output "project_map" {
  value = {
    for project, settings in google_project.map : project => {
      id         = settings.id
      project_id = settings.project_id
      number     = settings.number
      name       = settings.name
    }
  }
}
