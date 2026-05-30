.PHONY: check ci ci-list ci-job

# Run a command inside the root Nix dev shell via direnv, whether or not
# direnv has already activated it in the current terminal.
NIX     := direnv exec .
# Run a command inside the web/ Nix dev shell.
NIX_WEB := direnv exec web

## Fast local check — runs typecheck, lint, and build directly (no Docker).
## Use this for day-to-day validation before pushing.
check:
	$(NIX_WEB) npm --prefix web run typecheck
	$(NIX_WEB) npm --prefix web run lint
	$(NIX_WEB) npm --prefix web run build

## Run the full CI workflow locally inside Docker (mirrors GitHub Actions exactly).
## Requires Docker. Uses a /var/run volume to work around the rootless-Docker
## "mkdirat var/run: file exists" bug in act 0.2.88.
ci:
	$(NIX) act push \
		--workflows .github/workflows/ci.yml \
		--container-options "-v /tmp/act-run:/var/run"

## List all jobs in the CI workflow without running them.
ci-list:
	$(NIX) act push --workflows .github/workflows/ci.yml --list

## Run a single job by name, e.g.: make ci-job JOB=check
ci-job:
	$(NIX) act push \
		--workflows .github/workflows/ci.yml \
		--job $(JOB) \
		--container-options "-v /tmp/act-run:/var/run"
