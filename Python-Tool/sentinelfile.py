#!/usr/bin/env python3
"""SentinelFile - A beginner-friendly file integrity checker.

SentinelFile calculates SHA-256 hashes, compares two files, and scans
directories without ever modifying the files it inspects. It can be used
interactively or from the command line.
"""

import argparse
import hashlib
import os
import sys
from pathlib import Path

# Size (in bytes) of each chunk read from a file.
# Reading in chunks keeps memory usage low, even for very large files.
CHUNK_SIZE = 65536


def validate_file_path(path_string):
    """Validate that a path points to a readable file.

    Args:
        path_string (str): The file path supplied by the user.

    Returns:
        Path: A resolved pathlib.Path object.

    Raises:
        FileNotFoundError: If the file does not exist.
        ValueError: If the path is not a file.
        PermissionError: If the file is not readable.
    """
    file_path = Path(path_string).expanduser().resolve()

    if not file_path.exists():
        raise FileNotFoundError(f"File not found: {file_path}")
    if not file_path.is_file():
        raise ValueError(f"Not a file: {file_path}")
    if not os.access(str(file_path), os.R_OK):
        raise PermissionError(f"Permission denied or file unreadable: {file_path}")

    return file_path


def validate_directory_path(path_string):
    """Validate that a path points to a readable directory.

    Args:
        path_string (str): The directory path supplied by the user.

    Returns:
        Path: A resolved pathlib.Path object.

    Raises:
        FileNotFoundError: If the directory does not exist.
        ValueError: If the path is not a directory.
        PermissionError: If the directory is not readable.
    """
    dir_path = Path(path_string).expanduser().resolve()

    if not dir_path.exists():
        raise FileNotFoundError(f"Directory not found: {dir_path}")
    if not dir_path.is_dir():
        raise ValueError(f"Not a directory: {dir_path}")
    if not os.access(str(dir_path), os.R_OK | os.X_OK):
        raise PermissionError(
            f"Permission denied or directory unreadable: {dir_path}"
        )

    return dir_path


def hash_file(file_path):
    """Return the SHA-256 hex digest of a file.

    The file is read in fixed-size chunks so that very large files do not
    need to be loaded entirely into memory.

    Args:
        file_path (Path): Path to the file to hash.

    Returns:
        str: The SHA-256 hash of the file as a hexadecimal string.
    """
    sha256 = hashlib.sha256()

    # Open in binary read mode ('rb') to guarantee the file is never modified.
    with open(file_path, "rb") as file_handle:
        # iter() calls file_handle.read(CHUNK_SIZE) until an empty bytes
        # object is returned, which means the end of the file has been reached.
        for chunk in iter(lambda: file_handle.read(CHUNK_SIZE), b""):
            sha256.update(chunk)

    return sha256.hexdigest()


def compare_files(file_path1, file_path2):
    """Compare two files by their SHA-256 hashes.

    Args:
        file_path1 (Path): First file to compare.
        file_path2 (Path): Second file to compare.

    Returns:
        tuple: (identical, hash1, hash2) where identical is a bool.
    """
    hash1 = hash_file(file_path1)
    hash2 = hash_file(file_path2)
    identical = hash1 == hash2
    return identical, hash1, hash2


def scan_directory(dir_path):
    """Recursively scan a directory and hash every file found.

    Args:
        dir_path (Path): The directory to scan.

    Returns:
        list: A list of tuples (relative_path, hash_or_none, error_or_none).
    """
    results = []

    # rglob('*') walks the directory recursively. Sorting the results makes
    # the output consistent and easier to read.
    for file_path in sorted(dir_path.rglob("*")):
        if not file_path.is_file():
            continue

        relative = file_path.relative_to(dir_path)

        try:
            validate_file_path(str(file_path))
            digest = hash_file(file_path)
            results.append((relative, digest, None))
        except (OSError, ValueError, PermissionError, FileNotFoundError) as err:
            # Store the error message instead of stopping the whole scan.
            results.append((relative, None, str(err)))

    return results


def display_hash(file_path, digest):
    """Print the hash result for a single file."""
    print(f"[+] SHA-256 hash for {file_path}")
    print(f"    {digest}")


def display_compare(file_path1, file_path2, hash1, hash2, identical):
    """Print a comparison result for two files."""
    print(f"[*] File 1: {file_path1}")
    print(f"    SHA-256: {hash1}")
    print(f"[*] File 2: {file_path2}")
    print(f"    SHA-256: {hash2}")

    if identical:
        print("[+] Result: Files are IDENTICAL.")
    else:
        print("[-] Result: Files are DIFFERENT.")


def display_scan(dir_path, results):
    """Print the scan results for a directory."""
    print(f"[+] Scanning directory: {dir_path}")

    if not results:
        print("[!] No files found in the directory.")
        return

    for relative, digest, error in results:
        if error:
            print(f"  [!] {relative} -> ERROR: {error}")
        else:
            print(f"  [+] {relative} -> {digest}")

    print(f"[*] Scanned {len(results)} item(s).")


def command_hash(file_argument):
    """Handle the 'hash' subcommand."""
    file_path = validate_file_path(file_argument)
    digest = hash_file(file_path)
    display_hash(file_path, digest)


def command_compare(file_argument1, file_argument2):
    """Handle the 'compare' subcommand."""
    file_path1 = validate_file_path(file_argument1)
    file_path2 = validate_file_path(file_argument2)
    identical, hash1, hash2 = compare_files(file_path1, file_path2)
    display_compare(file_path1, file_path2, hash1, hash2, identical)


def command_scan(directory_argument):
    """Handle the 'scan' subcommand."""
    dir_path = validate_directory_path(directory_argument)
    results = scan_directory(dir_path)
    display_scan(dir_path, results)


def interactive_mode():
    """Run SentinelFile in interactive mode.

    This mode is used when the script is run without command-line arguments.
    """
    print("=" * 50)
    print("Welcome to SentinelFile - File Integrity Checker")
    print("=" * 50)
    print("Choose an option:")
    print("  1. Calculate SHA-256 hash of a file")
    print("  2. Compare two files")
    print("  3. Scan a directory")
    print("  q. Quit")
    print("=" * 50)

    while True:
        try:
            choice = input("\nEnter choice [1/2/3/q]: ").strip().lower()

            if choice == "q":
                print("[+] Exiting SentinelFile. Stay safe!")
                break

            if choice == "1":
                file_input = input("Enter the file path: ").strip()
                command_hash(file_input)

            elif choice == "2":
                file1 = input("Enter the first file path: ").strip()
                file2 = input("Enter the second file path: ").strip()
                command_compare(file1, file2)

            elif choice == "3":
                directory = input("Enter the directory path: ").strip()
                command_scan(directory)

            else:
                print("[!] Invalid choice. Please enter 1, 2, 3, or q.")

        except (EOFError, KeyboardInterrupt):
            print("\n[!] Exiting SentinelFile.")
            break
        except Exception as err:
            print(f"[-] Error: {err}")


def build_parser():
    """Build and return the argparse command-line parser."""
    parser = argparse.ArgumentParser(
        prog="SentinelFile",
        description=(
            "A simple file integrity checker using SHA-256. "
            "Run with no arguments to enter interactive mode."
        ),
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""\
Examples:
  python3 sentinelfile.py hash file1.txt
  python3 sentinelfile.py compare file1.txt file2.txt
  python3 sentinelfile.py scan ./test_directory
  python3 sentinelfile.py --help

No files are ever modified or deleted by SentinelFile.
""",
    )

    subparsers = parser.add_subparsers(
        dest="command",
        title="Available commands",
        metavar="COMMAND",
    )

    # Subcommand: hash
    hash_parser = subparsers.add_parser(
        "hash",
        help="Calculate the SHA-256 hash of a single file.",
    )
    hash_parser.add_argument(
        "file",
        help="Path to the file to hash.",
    )

    # Subcommand: compare
    compare_parser = subparsers.add_parser(
        "compare",
        help="Compare two files to see if their contents are identical.",
    )
    compare_parser.add_argument(
        "file1",
        help="Path to the first file.",
    )
    compare_parser.add_argument(
        "file2",
        help="Path to the second file.",
    )

    # Subcommand: scan
    scan_parser = subparsers.add_parser(
        "scan",
        help="Recursively scan a directory and hash every file.",
    )
    scan_parser.add_argument(
        "directory",
        help="Path to the directory to scan.",
    )

    return parser


def main():
    """Main entry point for SentinelFile."""
    parser = build_parser()

    # If no arguments are provided, run the interactive menu instead of
    # printing the help text.
    if len(sys.argv) == 1:
        interactive_mode()
        return 0

    args = parser.parse_args()

    try:
        if args.command == "hash":
            command_hash(args.file)
        elif args.command == "compare":
            command_compare(args.file1, args.file2)
        elif args.command == "scan":
            command_scan(args.directory)
        else:
            parser.print_help()
            return 1
    except (FileNotFoundError, ValueError, PermissionError, OSError) as err:
        print(f"[-] Error: {err}")
        return 1
    except KeyboardInterrupt:
        print("\n[!] Operation cancelled by user.")
        return 130

    return 0


if __name__ == "__main__":
    sys.exit(main())

