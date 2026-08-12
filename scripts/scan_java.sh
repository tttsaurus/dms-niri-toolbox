#!/usr/bin/env bash

set -u

SEARCH_ROOTS=(
    "/usr/lib/jvm"
    "/usr/lib64/jvm"
    "/usr/java"
    "/usr/local/lib/jvm"
    "/usr/local/java"
    "/opt/java"
    "/opt/jdk"
    "$HOME/.jdks"
    "$HOME/.sdkman/candidates/java"
)

declare -A SEEN

{
    for root in "${SEARCH_ROOTS[@]}"; do
        [[ -d "$root" ]] || continue

        while IFS= read -r -d '' candidate; do
            java_bin="$(readlink -f "$candidate" 2>/dev/null)" || continue

            jdk_path="$(dirname "$(dirname "$java_bin")")"

            [[ -x "$jdk_path/bin/java" ]] || continue
            [[ -x "$jdk_path/bin/javac" ]] || continue

            if [[ -n "${SEEN[$jdk_path]+x}" ]]; then
                continue
            fi

            SEEN["$jdk_path"]=1

            version_output="$("$jdk_path/bin/java" -version 2>&1)"
            version="${version_output%%$'\n'*}"

            label="$(basename "$jdk_path") — $version"

            label="${label//$'\t'/ }"

            printf '%s\t%s\n' "$label" "$jdk_path"
        done < <(
            find "$root" \
                -mindepth 2 \
                -maxdepth 4 \
                \( -type f -o -type l \) \
                -path '*/bin/java' \
                -print0 2>/dev/null
        )
    done
} | sort -f