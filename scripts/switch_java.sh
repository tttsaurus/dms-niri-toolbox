#!/usr/bin/env bash

set -euo pipefail

JDK_PATH="${1:-}"

if [[ -z "$JDK_PATH" ]]; then
    echo "No JDK path provided." >&2
    exit 1
fi

JDK_PATH="$(readlink -f "$JDK_PATH")"

if [[ ! -x "$JDK_PATH/bin/java" ]]; then
    echo "Invalid JDK: java executable not found." >&2
    echo "$JDK_PATH/bin/java" >&2
    exit 1
fi

if [[ ! -x "$JDK_PATH/bin/javac" ]]; then
    echo "Invalid JDK: javac executable not found." >&2
    echo "$JDK_PATH/bin/javac" >&2
    exit 1
fi


BASHRC="$HOME/.bashrc"

BEGIN_MARKER="# >>> DMS Niri Toolbox Java Switch >>>"
END_MARKER="# <<< DMS Niri Toolbox Java Switch <<<"

touch "$BASHRC"

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

awk \
    -v begin="$BEGIN_MARKER" \
    -v end="$END_MARKER" '
    $0 == begin {
        skip = 1
        next
    }

    $0 == end {
        skip = 0
        next
    }

    !skip {
        print
    }
' "$BASHRC" > "$tmp"

{
    echo
    echo "$BEGIN_MARKER"
    printf 'export JAVA_HOME=%q\n' "$JDK_PATH"
    # shellcheck disable=SC2016
    echo 'export PATH="$JAVA_HOME/bin:$PATH"'
    echo "$END_MARKER"
} >> "$tmp"

cat "$tmp" > "$BASHRC"



STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/dms-niri-toolbox"
STATE_FILE="$STATE_DIR/java-home"

mkdir -p "$STATE_DIR"
printf '%s\n' "$JDK_PATH" > "$STATE_FILE"



java_output="$("$JDK_PATH/bin/java" -version 2>&1)" || {
    echo "java test failed." >&2
    exit 1
}

javac_output="$("$JDK_PATH/bin/javac" -version 2>&1)" || {
    echo "javac test failed." >&2
    exit 1
}

java_version="${java_output%%$'\n'*}"
javac_version="${javac_output%%$'\n'*}"

echo "Java switched successfully."
echo
echo "JAVA_HOME:"
echo "$JDK_PATH"
echo
echo "java:"
echo "$java_version"
echo
echo "javac:"
echo "$javac_version"
echo
echo "New terminal sessions will use this JDK."