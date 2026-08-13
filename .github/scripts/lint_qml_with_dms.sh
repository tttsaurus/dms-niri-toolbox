#!/usr/bin/env bash

set -euo pipefail

DMS_DIR="${1:?DMS directory required}"
PLUGIN_DIR="${2:?Plugin directory required}"

DMS_DIR="$(realpath "$DMS_DIR")"
PLUGIN_DIR="$(realpath "$PLUGIN_DIR")"

QMLLS_CONFIG="$DMS_DIR/quickshell/.qmlls.ini"


resolve_qmllint() {
    local candidate

    for candidate in \
        qmllint6 \
        qmllint-qt6 \
        /usr/lib/qt6/bin/qmllint \
        qmllint
    do
        if command -v "$candidate" >/dev/null 2>&1; then
            printf '%s\n' "$candidate"
            return
        fi
    done

    return 1
}


read_ini_value() {
    local key="$1"
    local file="$2"

    local value

    value="$(
        sed -n "s/^${key}=//p" "$file" |
            head -n 1
    )"

    value="${value#\"}"
    value="${value%\"}"

    printf '%s\n' "$value"
}


if [[ ! -f "$QMLLS_CONFIG" ]]; then
    echo "ERROR: .qmlls.ini not found:"
    echo "$QMLLS_CONFIG"
    exit 1
fi


QMLLINT="$(resolve_qmllint)" || {
    echo "ERROR: Qt 6 qmllint not found"
    exit 1
}


BUILD_DIR="$(read_ini_value "buildDir" "$QMLLS_CONFIG")"
IMPORT_PATHS="$(read_ini_value "importPaths" "$QMLLS_CONFIG")"


if [[ -z "$BUILD_DIR" ]]; then
    echo "ERROR: buildDir missing from .qmlls.ini"
    exit 1
fi


if [[ ! -d "$BUILD_DIR" ]]; then
    echo "ERROR: Quickshell tooling build directory missing:"
    echo "$BUILD_DIR"
    exit 1
fi


echo "DMS:"
echo "  $DMS_DIR"

echo
echo "Plugin:"
echo "  $PLUGIN_DIR"

echo
echo "qmllint:"
echo "  $QMLLINT"

echo
echo "Quickshell tooling:"
echo "  $BUILD_DIR"


QMLLINT_ARGS=(
    --ignore-settings
    -W 0

    -I "$BUILD_DIR"
    -I "$PLUGIN_DIR"
)


IFS=':' read -r -a PATHS <<< "$IMPORT_PATHS"

for path in "${PATHS[@]}"; do
    if [[ -n "$path" ]]; then
        QMLLINT_ARGS+=(
            -I "$path"
        )
    fi
done


mapfile -d '' QML_FILES < <(
    find "$PLUGIN_DIR" \
        -type f \
        -name '*.qml' \
        -print0 |
        sort -z
)


if (( ${#QML_FILES[@]} == 0 )); then
    echo "ERROR: no QML files found"
    exit 1
fi


echo
echo "Checking ${#QML_FILES[@]} QML files..."
echo


"$QMLLINT" \
    "${QMLLINT_ARGS[@]}" \
    "${QML_FILES[@]}"


echo
echo "QML compatibility check passed."