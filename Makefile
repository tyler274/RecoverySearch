.PHONY: ci ci-list ci-job

## Run the full CI workflow locally (mirrors what GitHub runs on each push).
ci:
	act push --workflows .github/workflows/ci.yml

## List all jobs in the CI workflow without running them.
ci-list:
	act push --workflows .github/workflows/ci.yml --list

## Run a single job by name, e.g.: make ci-job JOB=check
ci-job:
	act push --workflows .github/workflows/ci.yml --job $(JOB)
