# Mission Control - Jobs configuration
# This gem provides a web interface for monitoring Solid Queue jobs

# Configure Mission Control authentication
# Use a custom base controller that checks Current.user.admin?
MissionControl::Jobs.base_controller_class = "MissionControlBaseController"

# Disable built-in HTTP Basic since we use app auth
MissionControl::Jobs.http_basic_auth_enabled = false
