#######################################################################################################
#
# Terraform does not have a easy way to check if the input parameters are in the correct format.
# On top of that, terraform will sometimes produce a valid plan but then fail during apply.
# To handle these errors beforehad, we're using the 'file' hack to throw errors on known mistakes.
#
#######################################################################################################
locals {
  # Regular expressions
  regex_project_name = "[a-zA-Z0-9\\-\"' !]*"
  regex_project_id   = "[a-z][a-z0-9\\-]*[a-z0-9]"

  # Terraform assertion hack
  assert_head = "\n\n-------------------------- /!\\ ASSERTION FAILED /!\\ --------------------------\n\n"
  assert_foot = "\n\n-------------------------- /!\\ ^^^^^^^^^^^^^^^^ /!\\ --------------------------\n"
  asserts = {
    for project, settings in local.projects : project => merge({
      projectid_too_long   = length(project) > 30 ? file(format("%sproject [%s]'s generated id is too long:\n%s > 30 chars!%s", local.assert_head, project, length(project), local.assert_foot)) : "ok"
      projectid_regex      = length(regexall("^${local.regex_project_id}$", project)) == 0 ? file(format("%sproject [%s]'s generated id does not match regex ^%s$%s", local.assert_head, project, local.regex_project_id, local.assert_foot)) : "ok"
      projectname_too_long = length(settings.gcp_project_name) > 30 ? file(format("%sproject [%s]'s generated name is too long:\n%s\n%s > 30 chars!%s", local.assert_head, project, settings.gcp_project_name, length(settings.gcp_project_name), local.assert_foot)) : "ok"
      projectname_regex    = length(regexall("^${local.regex_project_name}$", settings.gcp_project_name)) == 0 ? file(format("%sproject [%s]'s generated name [%s] does not match regex ^%s$%s", local.assert_head, project, settings.gcp_project_name, local.regex_project_name, local.assert_foot)) : "ok"
      project_host_svc     = settings.shared_vpc_service != 0 && settings.shared_vpc_host ? file(format("%sproject [%s] is set to be both a Shared VPC Host and Service project at the same time -- can not be active at the same time!\n%s\n%s", local.assert_head, project, settings.shared_vpc_service, local.assert_foot)) : "ok"
      # TODO: this assert should fail on 'projects/asd', but it does not yet.
      project_svc_project = settings.shared_vpc_service != null && length(regexall("^(?:(?:[-a-z0-9]{1,63}\\.)*(?:[a-z](?:[-a-z0-9]{0,61}[a-z0-9])?):)?(?:[0-9]{1,19}|(?:[a-z0-9](?:[-a-z0-9]{0,61}[a-z0-9])?))$", settings.shared_vpc_host)) == 0 ? file(format("%sproject [%s] is set to be a Shared VPC Service project, but the host project [%s] does not validate the gcp given regex!\n%s", local.assert_head, project, settings.shared_vpc_service, local.assert_foot)) : "ok"

    })
  }
}
