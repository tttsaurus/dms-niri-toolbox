#!/usr/bin/env bash

set -u

BASHRC="$HOME/.bashrc"

STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
STATE_FILE="$STATE_HOME/dms-niri-toolbox/java-home"

print_separator() {
    echo
    echo "============================================================"
    echo "$1"
    echo "============================================================"
}


print_file_matches() {
    local file="$1"
    local pattern="$2"

    echo "File: $file"

    if [[ ! -f "$file" ]]; then
        echo "[file does not exist]"
        return
    fi

    local total_lines
    total_lines="$(wc -l < "$file")"

    local matches
    matches="$(grep -nE "$pattern" "$file" 2>/dev/null || true)"

    if [[ -z "$matches" ]]; then
        echo "[no matching lines]"
        echo
        echo "Last 10 lines:"

        local start=$((total_lines - 9))

        if (( start < 1 )); then
            start=1
        fi

        sed -n "${start},${total_lines}p" "$file" \
            | nl -ba -v "$start"

        return
    fi

    local min_line
    local max_line

    min_line="$(
        printf '%s\n' "$matches" \
            | cut -d: -f1 \
            | head -n 1
    )"

    max_line="$(
        printf '%s\n' "$matches" \
            | cut -d: -f1 \
            | tail -n 1
    )"

    local start=$((min_line - 5))
    local end=$((max_line + 5))

    if (( start < 1 )); then
        start=1
    fi

    if (( end > total_lines )); then
        end="$total_lines"
    fi

    echo "Matched lines: $min_line-$max_line"
    echo "Showing lines: $start-$end"
    echo

    sed -n "${start},${end}p" "$file" \
        | nl -ba -v "$start"
}


print_full_file() {
    local file="$1"

    echo "File: $file"

    if [[ ! -f "$file" ]]; then
        echo "[file does not exist]"
        return
    fi

    if [[ ! -s "$file" ]]; then
        echo "[file is empty]"
        return
    fi

    nl -ba "$file"
}


print_separator "BASHRC JAVA CONFIG"

# shellcheck disable=SC2016
print_file_matches \
    "$BASHRC" \
    'JAVA_HOME|\$JAVA_HOME/bin|DMS Niri Toolbox Java Switch'


print_separator "TOOLBOX JAVA STATE"

print_full_file "$STATE_FILE"

print_separator "CURRENT ENVIRONMENT (DMS PROCESS)"

echo "JAVA_HOME:"
echo "${JAVA_HOME:-[not set]}"

echo
echo "PATH:"
echo "${PATH:-[not set]}"


print_separator "JAVA RESOLUTION (DMS PROCESS)"

java_path="$(command -v java 2>/dev/null || true)"
javac_path="$(command -v javac 2>/dev/null || true)"

echo "command -v java:"
echo "${java_path:-[not found]}"

if [[ -n "$java_path" ]]; then
    echo
    echo "resolved java:"
    readlink -f "$java_path" 2>/dev/null || echo "$java_path"
fi

echo
echo "command -v javac:"
echo "${javac_path:-[not found]}"

if [[ -n "$javac_path" ]]; then
    echo
    echo "resolved javac:"
    readlink -f "$javac_path" 2>/dev/null || echo "$javac_path"
fi


print_separator "JAVA VERSION (DMS PROCESS)"

if [[ -n "$java_path" ]]; then
    java -version 2>&1
else
    echo "[java not found]"
fi


print_separator "JAVAC VERSION (DMS PROCESS)"

if [[ -n "$javac_path" ]]; then
    javac -version 2>&1
else
    echo "[javac not found]"
fi


print_separator "ALL JAVA EXECUTABLES IN PATH (DMS PROCESS)"

type -a java 2>&1 || true


print_separator "ALL JAVAC EXECUTABLES IN PATH (DMS PROCESS)"

type -a javac 2>&1 || true