#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$script_dir/jvm-benchmark-common.sh"

output_dir="$(benchmark_prepare_output_dir comparison)"
spring_output_dir="$output_dir/spring"
quarkus_output_dir="$output_dir/quarkus"

"$script_dir/benchmark-jvm-runtime.sh" spring "$spring_output_dir"
"$script_dir/benchmark-jvm-runtime.sh" quarkus "$quarkus_output_dir"

jq -s '{
    schemaVersion: 1,
    benchmarkName: "jvm-runtime-comparison",
    generatedAtUtc: (.[1].generatedAtUtc // .[0].generatedAtUtc),
    workloadFile: .[0].workloadFile,
    environment: .[0].environment,
    runs: (map(.runs) | add)
}' \
    "$spring_output_dir/report.json" \
    "$quarkus_output_dir/report.json" >"$output_dir/report.json"

jq -r '
    "JVM runtime comparison summary",
    (.runs[] | "\(.runtime): build=\(.buildDurationMs)ms startup=\(.startupDurationMs)ms rss=\(.steadyStateRssKb)kb generate(avg)=\(.generateLatencyMs.avg)ms history(avg)=\(.historyLatencyMs.avg)ms artifact=\(.artifactSizeBytes)B")
' "$output_dir/report.json" >"$output_dir/summary.txt"

echo "Combined JVM comparison report: $output_dir/report.json"
echo "Human-readable summary: $output_dir/summary.txt"
