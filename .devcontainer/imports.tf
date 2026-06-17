# # These resources already exist in Azure from a prior deployment.
# # Terraform 1.5+ import blocks bring them under state management during plan/apply.
# # Once imported, subsequent runs silently ignore these blocks (resource already in state).

# import {
#   to = azurerm_bastion_host.bastion[0]
#   id = "/subscriptions/91607e02-215d-4dc0-b0e1-01554294ae00/resourceGroups/rg-trezure/providers/Microsoft.Network/bastionHosts/bas-trezure"
# }

# import {
#   to = azurerm_key_vault_secret.cosmos_mongo_connstr
#   id = "https://kv-trezure.vault.azure.net/secrets/porter-db-connection-string/0b0b6f5aa2ac455687d71de31b19b337"
# }

# import {
#   to = azurerm_key_vault_secret.api_client_id
#   id = "https://kv-trezure.vault.azure.net/secrets/api-client-id/d5298ae8cab843f0878ea6c52783a95e"
# }

# import {
#   to = azurerm_key_vault_secret.api_client_secret
#   id = "https://kv-trezure.vault.azure.net/secrets/api-client-secret/6520f9ef5b394b0ea31b7d0db121bb94"
# }

# import {
#   to = azurerm_key_vault_secret.auth_tenant_id
#   id = "https://kv-trezure.vault.azure.net/secrets/auth-tenant-id/d24802770567445ca10f2bfe9c1c5d3b"
# }

# import {
#   to = azurerm_key_vault_secret.application_admin_client_id
#   id = "https://kv-trezure.vault.azure.net/secrets/application-admin-client-id/f28a27ada8034fe3837d76428b364ae2"
# }

# import {
#   to = azurerm_key_vault_secret.application_admin_client_secret
#   id = "https://kv-trezure.vault.azure.net/secrets/application-admin-client-secret/15242c75ab5049229109e4917b93763e"
# }

# import {
#   to = azurerm_monitor_diagnostic_setting.kv
#   id = "/subscriptions/91607e02-215d-4dc0-b0e1-01554294ae00/resourceGroups/rg-trezure/providers/Microsoft.KeyVault/vaults/kv-trezure|diagnostics-kv-trezure"
# }

# import {
#   to = azurerm_monitor_diagnostic_setting.sb
#   id = "/subscriptions/91607e02-215d-4dc0-b0e1-01554294ae00/resourceGroups/rg-trezure/providers/Microsoft.ServiceBus/namespaces/sb-trezure|diagnostics-sb-trezure"
# }

# import {
#   to = module.airlock_resources.azurerm_monitor_diagnostic_setting.eventgrid_custom_topics["evgt-airlock-notification-v2-trezure"]
#   id = "/subscriptions/91607e02-215d-4dc0-b0e1-01554294ae00/resourceGroups/rg-trezure/providers/Microsoft.EventGrid/topics/evgt-airlock-notification-v2-trezure|evgt-airlock-notification-v2-trezure-diagnostics"
# }

# import {
#   to = module.airlock_resources.azurerm_monitor_diagnostic_setting.eventgrid_custom_topics["evgt-airlock-scan-result-v2-trezure"]
#   id = "/subscriptions/91607e02-215d-4dc0-b0e1-01554294ae00/resourceGroups/rg-trezure/providers/Microsoft.EventGrid/topics/evgt-airlock-scan-result-v2-trezure|evgt-airlock-scan-result-v2-trezure-diagnostics"
# }

# import {
#   to = module.airlock_resources.azurerm_monitor_diagnostic_setting.eventgrid_custom_topics["evgt-airlock-step-result-v2-trezure"]
#   id = "/subscriptions/91607e02-215d-4dc0-b0e1-01554294ae00/resourceGroups/rg-trezure/providers/Microsoft.EventGrid/topics/evgt-airlock-step-result-v2-trezure|evgt-airlock-step-result-v2-trezure-diagnostics"
# }

# import {
#   to = module.airlock_resources.azurerm_monitor_diagnostic_setting.eventgrid_custom_topics["evgt-airlock-status-changed-v2-trezure"]
#   id = "/subscriptions/91607e02-215d-4dc0-b0e1-01554294ae00/resourceGroups/rg-trezure/providers/Microsoft.EventGrid/topics/evgt-airlock-status-changed-v2-trezure|evgt-airlock-status-changed-v2-trezure-diagnostics"
# }

# import {
#   to = module.airlock_resources.azurerm_monitor_diagnostic_setting.eventgrid_custom_topics["evgt-airlock-data-deletion-v2-trezure"]
#   id = "/subscriptions/91607e02-215d-4dc0-b0e1-01554294ae00/resourceGroups/rg-trezure/providers/Microsoft.EventGrid/topics/evgt-airlock-data-deletion-v2-trezure|evgt-airlock-data-deletion-v2-trezure-diagnostics"
# }

# import {
#   to = module.airlock_resources.azurerm_monitor_diagnostic_setting.eventgrid_system_topics["evgt-airlock-import-in-progress-v2-trezure"]
#   id = "/subscriptions/91607e02-215d-4dc0-b0e1-01554294ae00/resourceGroups/rg-trezure/providers/Microsoft.EventGrid/systemTopics/evgt-airlock-import-in-progress-v2-trezure|evgt-airlock-import-in-progress-v2-trezure-diagnostics"
# }

# import {
#   to = module.airlock_resources.azurerm_monitor_diagnostic_setting.eventgrid_system_topics["evgt-airlock-import-rejected-v2-trezure"]
#   id = "/subscriptions/91607e02-215d-4dc0-b0e1-01554294ae00/resourceGroups/rg-trezure/providers/Microsoft.EventGrid/systemTopics/evgt-airlock-import-rejected-v2-trezure|evgt-airlock-import-rejected-v2-trezure-diagnostics"
# }

# import {
#   to = module.airlock_resources.azurerm_monitor_diagnostic_setting.eventgrid_system_topics["evgt-airlock-import-blocked-v2-trezure"]
#   id = "/subscriptions/91607e02-215d-4dc0-b0e1-01554294ae00/resourceGroups/rg-trezure/providers/Microsoft.EventGrid/systemTopics/evgt-airlock-import-blocked-v2-trezure|evgt-airlock-import-blocked-v2-trezure-diagnostics"
# }

# import {
#   to = module.airlock_resources.azurerm_monitor_diagnostic_setting.eventgrid_system_topics["evgt-airlock-export-approved-v2-trezure"]
#   id = "/subscriptions/91607e02-215d-4dc0-b0e1-01554294ae00/resourceGroups/rg-trezure/providers/Microsoft.EventGrid/systemTopics/evgt-airlock-export-approved-v2-trezure|evgt-airlock-export-approved-v2-trezure-diagnostics"
# }

# import {
#   to = module.resource_processor_vmss_porter[0].azurerm_key_vault_secret.resource_processor_vmss_password
#   id = "https://kv-trezure.vault.azure.net/secrets/resource-processor-vmss-password/26c302ef5f734c048a461410b429aae4"
# }

# import {
#   to = module.appgateway.azurerm_key_vault_certificate.tlscert
#   id = "https://kv-trezure.vault.azure.net/certificates/letsencrypt/30e73c313de742549adb67499edb0e88"
# }

# import {
#   to = module.appgateway.azurerm_monitor_diagnostic_setting.agw
#   id = "/subscriptions/91607e02-215d-4dc0-b0e1-01554294ae00/resourceGroups/rg-trezure/providers/Microsoft.Network/applicationGateways/agw-trezure|diagnostics-agw-trezure"
# }

# import {
#   to = azurerm_monitor_diagnostic_setting.webapp_api
#   id = "/subscriptions/91607e02-215d-4dc0-b0e1-01554294ae00/resourceGroups/rg-trezure/providers/Microsoft.Web/sites/api-trezure|diag-trezure"
# }

# import {
#   to = module.firewall.azurerm_monitor_diagnostic_setting.firewall
#   id = "/subscriptions/91607e02-215d-4dc0-b0e1-01554294ae00/resourceGroups/rg-trezure/providers/Microsoft.Network/azureFirewalls/fw-trezure|diagnostics-fw-trezure"
# }

# import {
#   to = module.airlock_resources.azurerm_monitor_diagnostic_setting.airlock_function_app
#   id = "/subscriptions/91607e02-215d-4dc0-b0e1-01554294ae00/resourceGroups/rg-trezure/providers/Microsoft.Web/sites/func-airlock-processor-trezure|diagnostics-airlock-function-trezure"
# }
