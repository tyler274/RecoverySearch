# RecoverySearch Infrastructure (Terraform, multi-cloud)

Deploy RecoverySearch — the Next.js app **and** the full self-hosted Supabase
stack (root `docker-compose.yml`) — to **Azure, AWS, or GCP** from a single,
portable Terraform codebase.

The same architecture targets any of the three clouds: a VM per cloud running
the *identical* Docker Compose stack, brought up by a shared bootstrap script.
Secrets come from a pluggable backend — **HashiCorp Vault**, **Doppler**, or
the **cloud-native store** (Azure Key Vault / AWS Secrets Manager / GCP Secret
Manager) — selected with a single variable.

```
infra/
  modules/
    secrets/     # generate secrets + write to Vault or Doppler (cloud_native handled per-cloud)
    bootstrap/   # render the portable VM bootstrap script (Azure custom_data / AWS user_data / GCP startup-script)
    azure/       # resource group, VNet, NSG, VM, data disk, public IP, optional DNS, Key Vault
    aws/         # VPC, security group, EC2, EBS, Elastic IP, optional Route53, Secrets Manager
    gcp/         # network, firewall, Compute Engine, persistent disk, static IP, optional Cloud DNS, Secret Manager
  envs/
    azure/  aws/  gcp/   # thin root configs: pick the cloud + secrets backend, configure providers + state
```

## How it works

1. `modules/secrets` generates all stack secrets (`random_password`) once.
   - `vault`   -> writes them to a Vault KV v2 path + creates a read policy and an AppRole.
   - `doppler` -> creates a Doppler project/config, writes the secrets, mints a read-only service token.
   - `cloud_native` -> the per-cloud module writes a single JSON secret to the cloud store.
2. The per-cloud module allocates a **static public IP first**, renders the
   bootstrap script (via `modules/bootstrap`) with that IP, then creates the VM.
3. At boot the VM: installs Docker, mounts the persistent data disk at
   `/opt/recoverysearch`, clones this repo, fetches secrets from the chosen
   backend, mints the `ANON_KEY`/`SERVICE_ROLE_KEY` JWTs from `JWT_SECRET`,
   writes `.env`, and runs:

   ```bash
   docker compose -f docker-compose.yml -f docker-compose.app.yml up -d --build
   ```

> `ANON_KEY` and `SERVICE_ROLE_KEY` are HS256 JWTs derived from `JWT_SECRET`, so
> they are minted on the VM and never stored in any secrets backend.

## Prerequisites

- Terraform >= 1.5 (provided by the repo's Nix dev shell: `direnv allow` / `nix develop`).
- Cloud credentials for your target:
  - **Azure**: `az login` and `export ARM_SUBSCRIPTION_ID=...`
  - **AWS**: standard provider chain (`AWS_PROFILE`, env vars, or assumed role)
  - **GCP**: `gcloud auth application-default login`
- An SSH public key.
- The VM clones this repo over HTTPS, so `app_repo_url` must be reachable
  (public repo, or a clone URL with an embedded token for private repos).
- For the chosen secrets backend:
  - **Vault**: a reachable Vault with a KV v2 mount; `VAULT_ADDR` + `VAULT_TOKEN`
    in your env (or `vault_address` / `vault_token` vars). HCP Vault works well
    to avoid operating Vault yourself.
  - **Doppler**: a Doppler token (`doppler_token`) with permission to manage projects.
  - **cloud_native**: no extra config — the matching cloud store is created for you.

## Deploy

Pick the environment directory for your cloud and go. Example for Azure:

```bash
cd infra/envs/azure
cp terraform.tfvars.example terraform.tfvars   # then edit
export ARM_SUBSCRIPTION_ID="<your-subscription>"

terraform init
terraform plan
terraform apply
```

AWS and GCP are identical except for the directory and provider auth:

```bash
cd infra/envs/aws   # or infra/envs/gcp
cp terraform.tfvars.example terraform.tfvars
terraform init && terraform apply
```

Outputs include `app_url`, `supabase_api_url`, `public_ip`, and `ssh_command`.
First boot takes a few minutes (Docker install + image builds); follow along with:

```bash
ssh <user>@<public_ip>
sudo tail -f /var/log/recoverysearch-bootstrap.log
```

## Choosing the secrets backend

Set `secrets_backend` in `terraform.tfvars` to one of:

| Value          | Where secrets live              | VM fetches via                         |
| -------------- | ------------------------------- | -------------------------------------- |
| `vault`        | Vault KV v2                     | AppRole login (role_id/secret_id)      |
| `doppler`      | Doppler config                  | Doppler CLI + read-only service token  |
| `cloud_native` | Key Vault / Secrets Mgr / Secret Mgr | Cloud CLI using the VM's identity |

Switching backends is just changing this variable (and providing that backend's
credentials). The recommended default is **Vault** for a single cloud-agnostic
source of truth across all three clouds; **Doppler** is a low-ops managed
alternative; **cloud_native** keeps everything inside one cloud's IAM boundary.

### cloud_native identity

For `cloud_native`, the VM reads its secret using a cloud identity provisioned
by Terraform — an Azure system-assigned managed identity (Key Vault access
policy), an AWS instance profile (`secretsmanager:GetSecretValue`), or a GCP
service account (`roles/secretmanager.secretAccessor`). The bootstrap retries
the fetch to ride out IAM propagation on first boot.

## Remote state (recommended)

Each env defaults to local state. To use remote state, uncomment the `backend`
block in that env's `versions.tf`, copy `backend.hcl.example` to `backend.hcl`,
fill it in, and run `terraform init -backend-config=backend.hcl`.

## Notes & limitations

- **v1 uses HTTP on the public IP** (`:3000` app, `:8000` Supabase API/Studio).
  For TLS, point a domain at the IP (the optional DNS inputs create the record)
  and front the stack with the repo's `docker-compose.caddy.yml`/nginx overlay.
- Lock down `ssh_allowed_cidr` / `web_allowed_cidr` to your own ranges in production.
- The instance sizes default to ~8 GB RAM, the practical minimum for the full
  Supabase stack plus the app.
- Vault cloud IAM auth (Azure MSI / AWS IAM / GCP IAM) is a documented extension
  point; the portable AppRole method is wired by default to avoid a circular
  dependency on the VM identity.

## Tear down

```bash
cd infra/envs/<cloud>
terraform destroy
```

The persistent data disk is deleted with the stack; back up Postgres first if
you need to keep data.
