.PHONY: ci ci-list ci-job

# Run a command inside the root Nix dev shell, whether or not direnv has
# already activated it in the current terminal.
NIX := direnv exec .

## Run the full CI workflow locally (mirrors what GitHub runs on each push).
ci:
	$(NIX) act push --workflows .github/workflows/ci.yml

## List all jobs in the CI workflow without running them.
ci-list:
	$(NIX) act push --workflows .github/workflows/ci.yml --list

## Run a single job by name, e.g.: make ci-job JOB=check
ci-job:
	$(NIX) act push --workflows .github/workflows/ci.yml --job $(JOB)
