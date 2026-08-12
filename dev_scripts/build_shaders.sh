#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"

DEFAULT_SHADER_DIR="${REPO_ROOT}/island/shaders"

FORCE=false
SHADER_DIR="${DEFAULT_SHADER_DIR}"

for arg in "$@"; do
    case "${arg}" in
        -f|--force)
            FORCE=true
            ;;
        -*)
            echo "Unknown option: ${arg}" >&2
            exit 1
            ;;
        *)
            SHADER_DIR="${arg}"
            ;;
    esac
done

QSB_ARGS=(
    --qt6
)

find_qsb() {
    if [[ -n "${QSB:-}" ]]; then
        if [[ ! -x "${QSB}" ]] && ! command -v "${QSB}" >/dev/null 2>&1; then
            echo "QSB is set but cannot be executed: ${QSB}" >&2
            exit 1
        fi

        printf '%s\n' "${QSB}"
        return
    fi

    local candidate

    for candidate in \
        qsb-qt6 \
        qsb6 \
        qsb
    do
        if command -v "${candidate}" >/dev/null 2>&1; then
            command -v "${candidate}"
            return
        fi
    done

    # Arch commonly installs qsb here instead of placing it directly in PATH
    if [[ -x "/usr/lib/qt6/bin/qsb" ]]; then
        printf '%s\n' "/usr/lib/qt6/bin/qsb"
        return
    fi

    print_qsb_install_hint
    exit 1
}

print_qsb_install_hint() {
    cat >&2 <<'MSG'
Could not find Qt's qsb shader baker.

Install Qt 6 Shader Tools and make `qsb` available in PATH,
or explicitly specify it:

    QSB=/path/to/qsb ./dev_scripts/build_shaders.sh

Typical installation:

  Fedora:
    sudo dnf install qt6-qtshadertools

  Arch Linux:
    sudo pacman -S qt6-shadertools

  Ubuntu / Debian:
    install the Qt 6 shader baker / Shader Tools package
    (commonly `qt6-shader-baker` on Ubuntu)
MSG
}

is_shader_source() {
    case "$1" in
        *.vert | \
        *.tesc | \
        *.tese | \
        *.geom | \
        *.frag | \
        *.comp)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

compile_shader() {
    local source="$1"
    local output="${source}.qsb"

    # skip if the output is newer than the source, unless forced
    if [[
        "${FORCE}" != true
        && -f "${output}"
        && "${output}" -nt "${source}"
    ]]; then
        printf 'Up to date: %s\n' \
            "${source#"${REPO_ROOT}/"}"
        return 2
    fi

    printf 'Building:   %s\n' \
        "${source#"${REPO_ROOT}/"}"

    if ! "${QSB_BIN}" \
        "${QSB_ARGS[@]}" \
        -o "${output}" \
        "${source}"
    then
        printf 'Failed:     %s\n' \
            "${source#"${REPO_ROOT}/"}" >&2
        return 1
    fi

    return 0
}

main() {
    if [[ ! -d "${SHADER_DIR}" ]]; then
        echo "Shader directory does not exist: ${SHADER_DIR}" >&2
        exit 1
    fi

    QSB_BIN="$(find_qsb)"

    printf 'Shader dir: %s\n' "${SHADER_DIR}"
    printf 'qsb:        %s\n' "${QSB_BIN}"
    printf '\n'

    local found=0
    local built=0
    local skipped=0
    local source

    while IFS= read -r -d '' source; do
        if ! is_shader_source "${source}"; then
            continue
        fi

        found=$((found + 1))

        if compile_shader "${source}"; then
            built=$((built + 1))
        else
            status=$?

            if (( status == 2 )); then
                skipped=$((skipped + 1))
            else
                exit "${status}"
            fi
        fi
    done < <(
        find "${SHADER_DIR}" \
            -type f \
            -print0
    )

    if (( found == 0 )); then
        echo "No shaders found in: ${SHADER_DIR}"
        exit 0
    fi

    printf '\n'
    printf 'Done: %d shader(s), %d built, %d up to date.\n' \
        "${found}" \
        "${built}" \
        "${skipped}"
}

main "$@"