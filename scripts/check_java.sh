#!/usr/bin/env bash

set -u

STATE_FILE="${XDG_STATE_HOME:-$HOME/.local/state}/dms-niri-toolbox/java-home"

JDK_PATH=""
SOURCE=""

if [[ -f "$STATE_FILE" ]]; then
    IFS= read -r JDK_PATH < "$STATE_FILE"

    if [[ -x "$JDK_PATH/bin/java" ]]; then
        SOURCE="Toolbox configuration"
    else
        JDK_PATH=""
    fi
fi

if [[ -z "$JDK_PATH" ]] &&
   [[ -n "${JAVA_HOME:-}" ]] &&
   [[ -x "$JAVA_HOME/bin/java" ]]; then

    JDK_PATH="$(readlink -f "$JAVA_HOME")"
    SOURCE="JAVA_HOME"
fi

if [[ -z "$JDK_PATH" ]]; then
    java_bin="$(command -v java 2>/dev/null || true)"

    if [[ -n "$java_bin" ]]; then
        java_bin="$(readlink -f "$java_bin")"
        JDK_PATH="$(dirname "$(dirname "$java_bin")")"
        SOURCE="PATH"
    fi
fi

if [[ -z "$JDK_PATH" ]] || [[ ! -x "$JDK_PATH/bin/java" ]]; then
    echo "No Java installation is currently configured." >&2
    exit 1
fi

echo "Source: $SOURCE"
echo
echo "JAVA_HOME:"
echo "$JDK_PATH"
echo
echo "java:"
"$JDK_PATH/bin/java" -version 2>&1

echo
echo "javac:"

if [[ -x "$JDK_PATH/bin/javac" ]]; then
    "$JDK_PATH/bin/javac" -version 2>&1
else
    echo "javac not found"
fi