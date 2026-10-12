#!/usr/bin/env bash
#!/usr/bin/env bash

# =============================================================================
# File/IOC Scanner for Linux
# Recursively scans files, calculates SHA256 hashes, and compares them
# against known Indicators of Compromise (IOCs).
#
# Usage:
#   ./file_ioc_scanner.sh [OPTIONS] <directory_to_scan>
# =============================================================================

# Exit codes
readonly EXIT_CLEAN=0
readonly EXIT_MATCHES=1
readonly EXIT_ERROR=2

# Default IOC file path
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly DEFAULT_IOC_FILE="${SCRIPT_DIR}/ioc_hashes.txt"

# Runtime variables
TARGET_DIR=""
IOC_FILE="${DEFAULT_IOC_FILE}"

# Counters
MATCH_COUNT=0
SCANNED_COUNT=0
ERROR_COUNT=0

# -----------------------------------------------------------------------------
# Display help
# -----------------------------------------------------------------------------
show_help() {
    cat <<'EOF'
File/IOC Scanner for Linux

Scans files recursively, calculates SHA256 hashes, and compares them
against known suspicious hashes stored in an IOC file.

Usage:
  ./file_ioc_scanner.sh [OPTIONS] <directory_to_scan>

Arguments:
  <directory_to_scan>   Directory to scan recursively

Options:
  -h, --help            Display this help message
  -i, --ioc <file>      Path to IOC hash file

Examples:
  ./file_ioc_scanner.sh .
  ./file_ioc_scanner.sh -i ./ioc_hashes.txt /home/kali/Downloads
  ./file_ioc_scanner.sh --help

Exit codes:
  0  No suspicious files detected and no errors
  1  One or more suspicious files detected
  2  Error or scan completed with warnings/errors

The tool only reads scanned files. It does not execute, modify,
or delete them.
EOF
}

# -----------------------------------------------------------------------------
# Print an error message
# -----------------------------------------------------------------------------
print_error() {
    printf "\n[ERROR] %s\n" "$1" >&2
}

# -----------------------------------------------------------------------------
# Validate SHA256 hash format
# -----------------------------------------------------------------------------
is_valid_sha256() {
    [[ "$1" =~ ^[a-fA-F0-9]{64}$ ]]
}

# -----------------------------------------------------------------------------
# Load IOC hashes
# -----------------------------------------------------------------------------
declare -A IOC_HASHES

load_ioc_file() {
    if [[ ! -e "$IOC_FILE" ]]; then
        print_error "IOC file not found: $IOC_FILE"
        return 1
    fi

    if [[ ! -f "$IOC_FILE" ]]; then
        print_error "IOC path is not a regular file: $IOC_FILE"
        return 1
    fi

    if [[ ! -r "$IOC_FILE" ]]; then
        print_error "IOC file is not readable: $IOC_FILE"
        return 1
    fi

    local line_number=0
    local loaded=0
    local invalid=0
    local line

    while IFS= read -r line || [[ -n "$line" ]]; do
        ((line_number++))

        # Remove leading and trailing whitespace
        line="${line#"${line%%[![:space:]]*}"}"
        line="${line%"${line##*[![:space:]]}"}"

        # Ignore empty lines and comments
        if [[ -z "$line" || "$line" == \#* ]]; then
            continue
        fi

        # Validate each hash
        if ! is_valid_sha256 "$line"; then
            printf "[WARNING] Invalid SHA256 hash on line %d: %s\n" \
                "$line_number" "$line" >&2
            ((invalid++))
            continue
        fi

        # Normalize hashes to lowercase
        IOC_HASHES["${line,,}"]=1
        ((loaded++))
    done < "$IOC_FILE"

    if (( loaded == 0 )); then
        print_error "No valid SHA256 hashes found in IOC file: $IOC_FILE"
        return 1
    fi

    printf "[INFO] Loaded %d valid IOC hash(es)" "$loaded"

    if (( invalid > 0 )); then
        printf " (%d invalid line(s) skipped)" "$invalid"
    fi

    printf "\n"
    return 0
}

# -----------------------------------------------------------------------------
# Scan directory and compare file hashes
# -----------------------------------------------------------------------------
scan_directory() {
    printf "[INFO] Starting scan of: %s\n" "$TARGET_DIR"
    printf "[INFO] Using IOC file:  %s\n\n" "$IOC_FILE"

    # Create a temporary file for the list of discovered files
    local find_output

    find_output=$(mktemp) || {
        print_error "Unable to create temporary file."
        ((ERROR_COUNT++))
        return
    }

    # Capture find's exit status directly
    find "$TARGET_DIR" -type f -print0 > "$find_output" 2>/dev/null
    local find_status=$?

    local file_path
    local hash_output
    local file_hash

    # Read null-separated paths safely
    while IFS= read -r -d '' file_path; do
        ((SCANNED_COUNT++))

        # Check read permissions
        if [[ ! -r "$file_path" ]]; then
            printf "[WARNING] Skipping unreadable file: %s\n" \
                "$file_path" >&2
            ((ERROR_COUNT++))
            continue
        fi

        # Calculate SHA256
        if ! hash_output=$(sha256sum "$file_path" 2>/dev/null); then
            printf "[WARNING] Failed to hash file: %s\n" \
                "$file_path" >&2
            ((ERROR_COUNT++))
            continue
        fi

        file_hash=$(awk '{print $1}' <<< "$hash_output")

        # Compare against known IOC hashes
        if [[ -n "${IOC_HASHES["${file_hash,,}"]+x}" ]]; then
            ((MATCH_COUNT++))

            printf "[!] MATCH DETECTED\n"
            printf "    Path:  %s\n" "$file_path"
            printf "    SHA256: %s\n\n" "$file_hash"
        fi

        # Display progress every 100 files
        if (( SCANNED_COUNT % 100 == 0 )); then
            printf "[INFO] Scanned %d file(s) so far...\n" \
                "$SCANNED_COUNT"
        fi
    done < "$find_output"

    # Remove the temporary file
    rm -f -- "$find_output"

    # Report actual find errors
    if (( find_status != 0 )); then
        print_error "find command exited with status ${find_status}. Some files or directories may be inaccessible."
        ((ERROR_COUNT++))
    fi
}

# -----------------------------------------------------------------------------
# Print summary and return the appropriate exit code
# -----------------------------------------------------------------------------
print_summary_and_exit() {
    printf "\n========== SCAN SUMMARY ==========\n"
    printf "Directory scanned:  %s\n" "$TARGET_DIR"
    printf "IOC file used:      %s\n" "$IOC_FILE"
    printf "Files scanned:      %d\n" "$SCANNED_COUNT"
    printf "Suspicious matches: %d\n" "$MATCH_COUNT"
    printf "Warnings/errors:    %d\n" "$ERROR_COUNT"
    printf "==================================\n"

    if (( MATCH_COUNT > 0 )); then
        printf "\n[RESULT] Suspicious files were detected. Review the paths above.\n"
        exit "$EXIT_MATCHES"
    elif (( ERROR_COUNT > 0 )); then
        printf "\n[RESULT] Scan completed with warnings/errors; no suspicious files detected.\n"
        exit "$EXIT_ERROR"
    else
        printf "\n[RESULT] No suspicious files found.\n"
        exit "$EXIT_CLEAN"
    fi
}

# -----------------------------------------------------------------------------
# Parse command-line arguments
# -----------------------------------------------------------------------------
parse_args() {
    if [[ $# -eq 0 ]]; then
        print_error "No directory specified."
        show_help
        exit "$EXIT_ERROR"
    fi

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_help
                exit "$EXIT_CLEAN"
                ;;
            -i|--ioc)
                if [[ $# -lt 2 || -z "${2:-}" ]]; then
                    print_error "Option $1 requires a path to an IOC file."
                    exit "$EXIT_ERROR"
                fi

                IOC_FILE="$2"
                shift 2
                ;;
            -i=*|--ioc=*)
                IOC_FILE="${1#*=}"

                if [[ -z "$IOC_FILE" ]]; then
                    print_error "IOC file path cannot be empty."
                    exit "$EXIT_ERROR"
                fi

                shift
                ;;
            -*)
                print_error "Unknown option: $1"
                show_help
                exit "$EXIT_ERROR"
                ;;
            *)
                if [[ -n "$TARGET_DIR" ]]; then
                    print_error "Only one target directory is allowed."
                    show_help
                    exit "$EXIT_ERROR"
                fi

                TARGET_DIR="$1"
                shift
                ;;
        esac
    done

    if [[ -z "$TARGET_DIR" ]]; then
        print_error "No directory specified."
        show_help
        exit "$EXIT_ERROR"
    fi
}

# -----------------------------------------------------------------------------
# Validate target directory
# -----------------------------------------------------------------------------
validate_target() {
    if [[ ! -e "$TARGET_DIR" ]]; then
        print_error "Directory does not exist: $TARGET_DIR"
        exit "$EXIT_ERROR"
    fi

    if [[ ! -d "$TARGET_DIR" ]]; then
        print_error "Path is not a directory: $TARGET_DIR"
        exit "$EXIT_ERROR"
    fi

    if [[ ! -r "$TARGET_DIR" || ! -x "$TARGET_DIR" ]]; then
        print_error "Directory cannot be accessed: $TARGET_DIR"
        exit "$EXIT_ERROR"
    fi
}

# -----------------------------------------------------------------------------
# Main execution
# -----------------------------------------------------------------------------
main() {
    parse_args "$@"
    validate_target
    load_ioc_file || exit "$EXIT_ERROR"
    scan_directory
    print_summary_and_exit
}

main "$@"
