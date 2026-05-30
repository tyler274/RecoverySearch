output "user_data" {
  description = "Rendered bootstrap shell script. Pass as Azure custom_data, AWS user_data, or GCP startup-script metadata."
  value       = local.rendered
  sensitive   = true # contains the Vault secret_id / Doppler token used to fetch secrets
}
