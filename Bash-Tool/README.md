# File/IOC Scanner

## 1. Tool Name
**File/IOC Scanner for Linux**

## 2. Objective
The File/IOC Scanner is a Bash tool designed to identify potentially suspicious files by calculating their SHA256 hashes and comparing them with known hashes stored in an IOC (Indicator of Compromise) file.

The tool helps users perform basic file-integrity checks and identify files whose hashes match the provided indicators.

## 3. Features
- Recursively scans files inside a specified directory.
- Calculates the SHA256 hash of each readable file.
- Compares file hashes against known IOC hashes.
- Supports a custom IOC file using the `-i` or `--ioc` option.
- Ignores empty lines and comments in the IOC file.
- Skips invalid IOC entries with a warning.
- Displays detected matches and a scan summary.
- Provides clear error messages.
- Supports a help option using `-h` or `--help`.
- Uses exit codes to indicate the scan result.
- Does not execute, modify, or delete scanned files.

## 4. Requirements
- Linux operating system, such as Kali Linux.
- Bash shell.
- `sha256sum` command.
- `find` command.
- `awk` command.
- `mktemp` command.

These utilities are generally available by default on Kali Linux.

## 5. Project Structure

Bash-Tool/
├── file_ioc_scanner.sh
├── ioc_hashes.txt
├── README.md
└── screenshots/
    ├── help.png
    ├── detection.png
    └── error-handling.png
    ├── ioc_test.png

## 6. Installation and Setup

### Step 1: Open the project directory

cd ~/File-IOC-Scanner/media/sf_Bash-Tool

### Step 2: Fix the Bash interpreter and line endings

The script must run with Bash because it uses Bash-specific syntax. If it is interpreted by `sh`, errors such as `Bad substitution`, `declare: not found`, and `Syntax error: redirection unexpected` may occur.

Run the following commands:

sed -i '1c\#!/usr/bin/env bash' file_ioc_scanner.sh
sed -i 's/\r$//' file_ioc_scanner.sh
chmod +x file_ioc_scanner.sh

These commands:
- Set the correct Bash shebang on the first line.
- Remove Windows-style carriage returns.
- Make the script executable.

### Step 3: Check the script syntax

bash -n file_ioc_scanner.sh

If the command returns no output, Bash has not detected a syntax error.

### Step 4: Prepare the IOC file

The `ioc_hashes.txt` file contains one SHA256 hash per line.

Example:

# Sample IOC file
0000000000000000000000000000000000000000000000000000000000000000
1111111111111111111111111111111111111111111111111111111111111111

These are test values, not confirmed malicious indicators. Replace them with valid hashes when testing hash matching. Invalid entries should be skipped with a warning.

## 7. How to Run

### Display the help message

./file_ioc_scanner.sh --help

### Scan the current directory

./file_ioc_scanner.sh .

### Scan a specific directory

./file_ioc_scanner.sh /home/kali/Downloads

### Scan using a custom IOC file

./file_ioc_scanner.sh -i ~/ioc-test/ioc_hashes.txt ~/ioc-test/files

The first path specifies the IOC file, and the second path specifies the directory to scan.

## 8. Testing and Example Usage

### Test 1: Help option

Command:

./file_ioc_scanner.sh --help

Expected result: The tool displays its description, usage, options, examples, and exit codes.

### Test 2: Suspicious hash detection

Create a test file:

mkdir -p ~/ioc-test/files
echo "IOC scanner test file" > ~/ioc-test/files/sample.txt

Calculate its SHA256 hash:

sha256sum ~/ioc-test/files/sample.txt

Copy the resulting 64-character hash into `~/ioc-test/ioc_hashes.txt`, with the hash on a separate line.

Run the scan:

./file_ioc_scanner.sh -i ~/ioc-test/ioc_hashes.txt ~/ioc-test/files
echo $?
Expected result: The scanner reports `MATCH DETECTED`, displays the file path and SHA256 hash, and returns exit code `1`.

**Note:** This test verifies hash matching only. It does not prove that the test file is malicious.

### Test 3: Invalid directory

Command:

./file_ioc_scanner.sh /path/does/not/exist
echo $?

Expected result: The tool displays an error because the directory does not exist and returns exit code `2`.

### Test 4: Invalid IOC entry

Add an invalid line to the IOC file:

not-a-valid-hash

Run the scanner again.

Expected result: The invalid IOC entry is skipped and a warning is displayed.

## 9. Exit Codes

| Exit Code | Meaning |
|---|---|
| `0` | No suspicious matches and no scan errors |
| `1` | One or more suspicious hash matches detected |
| `2` | Invalid input, fatal error, or scan warnings/errors |

## 10. Example Output

[INFO] Loaded 1 valid IOC hash(es)
[INFO] Starting scan of: /home/red/ioc-test/files
[INFO] Using IOC file: /home/red/ioc-test/ioc_hashes.txt

[!] MATCH DETECTED
    Path: /home/red/ioc-test/files/sample.txt
    SHA256: <matching SHA256 hash>

========== SCAN SUMMARY ==========
Files scanned:      1
Suspicious matches: 1
Warnings/errors:    0
==================================

[RESULT] Suspicious files were detected. Review the paths above.

## 11. Challenges Faced

- Bash-specific syntax caused errors when the script was interpreted by `sh`.
- Windows-style line endings could interfere with script execution in Linux.
- IOC entries needed validation to avoid processing invalid hashes.
- The scanner needed clear exit codes and error messages to make testing easier.

### Solutions
- Set the correct Bash shebang.
- Removed carriage-return characters from the script.
- Added validation for IOC hashes.
- Used test files and controlled SHA256 values to verify hash matching.

## 12. Future Improvements

- Support additional hash algorithms, such as SHA1 and MD5.
- Export scan results to a log file or CSV report.
- Add progress indicators for large directories.
- Integrate trusted threat-intelligence feeds.
- Add optional exclusion rules for directories and file types.

## 13. Security Note

This tool performs basic hash-based detection. A matching hash indicates that a file matches an IOC entry, but the reliability of the finding depends on the quality and trustworthiness of the IOC source.

The tool is intended for authorized security testing and defensive analysis. It does not replace a complete antivirus solution or a professional malware analysis workflow.

## 14. Screenshots

Add screenshots showing:
- Help output.
- Successful hash-match detection.
- Error handling for an invalid directory.

Store the screenshots in the `screenshots/` directory.

## 15. Conclusion

The File/IOC Scanner demonstrates Bash scripting, file traversal, SHA256 hashing, IOC validation, basic error handling, and exit-code management. It provides a simple foundation for Linux security automation.
