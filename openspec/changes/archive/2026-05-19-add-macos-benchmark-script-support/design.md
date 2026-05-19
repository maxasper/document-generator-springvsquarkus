## Context

The repository compares Spring Boot and Quarkus through shell-driven JVM benchmarks, Compose runtime inspection, runtime load testing, and the automated container runtime matrix. Those scripts are written for Bash but currently use several GNU/Linux-specific features: Bash 4 `mapfile`, GNU `date +%s%3N`, GNU `du -sb`, GNU `stat -c`, Linux `/proc/meminfo`, and AWK's third `match` argument.

macOS ships an older system Bash and BSD userland tools, so developers on macOS cannot run the same documented benchmark commands without installing GNU replacements. The intended benchmark behavior should remain the same: same runtime scenarios, same Docker Compose paths, same load-test cases, and same report fields.

## Goals / Non-Goals

**Goals:**

- Allow the documented benchmark and load-test shell scripts to run under the default macOS Bash and BSD userland.
- Keep Ubuntu behavior unchanged for scenario execution, measured workload, configured resource limits, and generated report shape.
- Use small portable shell helpers rather than adding a new dependency on Homebrew GNU utilities.
- Preserve the existing Docker and k6 container execution model.

**Non-Goals:**

- Normalizing benchmark numbers across host operating systems.
- Changing Docker Desktop resource allocation or host-specific performance characteristics.
- Replacing shell scripts with another runner.
- Changing application code, API behavior, database schema, or benchmark workload definitions.

## Decisions

1. Replace Bash 4-only array loading with Bash 3.2-compatible `while read` logic.

   macOS still commonly uses Bash 3.2 as `/bin/bash`, where `mapfile` is unavailable. A `while IFS= read -r` loop preserves the scenario order emitted by `jq` and works on Ubuntu as well.

2. Use portable time and file-size helpers with Linux and Darwin branches where needed.

   `date +%s%3N`, `du -sb`, and `stat -c` are GNU-specific. The scripts should use a millisecond epoch implementation available on macOS and Ubuntu, and select BSD or GNU `stat` syntax based on `uname -s`.

3. Read macOS host memory from standard macOS tooling while retaining `/proc/meminfo` on Linux.

   JVM comparison reports still need environment memory metadata. Linux should continue to read `/proc/meminfo`; macOS should read the equivalent total memory value from macOS host information and convert it to kilobytes.

4. Avoid AWK extensions that are not present in the default macOS AWK.

   The default macOS AWK does not support `match(value, regex, array)`. Parsing Docker memory strings with `sub` keeps the same unit conversion behavior without requiring `gawk`.

## Risks / Trade-offs

- Host metrics are not identical across operating systems -> Reports include OS metadata so benchmark results can be interpreted as host-specific measurements.
- macOS Docker Desktop resource limits can differ from Linux Docker Engine behavior -> The scripts preserve configured container limits but do not attempt to make host virtualization overhead comparable.
- Directory-size calculation can differ in edge cases such as sparse files or symlinks -> Benchmark artifact outputs are regular build artifacts, and file-size summation is sufficient for the current report field.
