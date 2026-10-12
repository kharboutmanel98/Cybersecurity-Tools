# SentinelFile – File Integrity Checker

## 1. Tool Name

**SentinelFile – File Integrity Checker**

## 2. Objective

SentinelFile is a Python-based cybersecurity tool designed to verify file integrity using SHA-256 hashing. It helps users detect file modifications by calculating and comparing file hashes. It can also scan directories and calculate the hashes of files.

## 3. Features

- **SHA-256 Hashing:** Calculate the SHA-256 hash of a file.
- **File Comparison:** Compare two files using their SHA-256 hashes.
- **Directory Scanning:** Recursively scan a directory and calculate file hashes.
- **Interactive Menu:** Run the tool using a simple command-line menu.
- **Command-Line Interface:** Execute specific operations directly from the terminal.
- **Error Handling:** Handle invalid paths, missing files, and common file access errors.
- **Help Option:** Display usage instructions and available commands.
- **No External Dependencies:** Uses Python standard libraries only.

## 4. Requirements

- Linux, Windows, or macOS
- Python 3.8 or later
- Terminal or command prompt
- No additional Python packages required

## 5. How to Run

### Step 1: Clone or Download the Project

Download the project files and open a terminal in the project directory.

### Step 2: Navigate to the Project Directory

cd SentinelFile

Make sure `sentinelfile.py` is present in the directory.

### Step 3: Check Python Installation

python3 --version

### Step 4: Display the Help Menu

python3 sentinelfile.py --help

### Step 5: Run the Interactive Menu

python3 sentinelfile.py

Follow the instructions displayed in the terminal to select an operation.

## 6. Example Usage

### A. Calculate a File Hash

python3 sentinelfile.py hash test_directory/file1.txt

### B. Compare Two Files

python3 sentinelfile.py compare test_directory/file1.txt test_directory/file2.txt

### C. Scan a Directory

python3 sentinelfile.py scan ./test_directory

### D. Display Help

python3 sentinelfile.py --help

### E. Create Test Files

Use the following commands to create sample files:

mkdir -p test_directory

echo "Hello Cybersecurity" > test_directory/file1.txt
echo "Hello Cybersecurity" > test_directory/file2.txt
echo "Different content" > test_directory/file3.txt

## 7. Example Output

### A. File Hash

File: test_directory/file1.txt
SHA-256: <calculated SHA-256 hash>

The actual hash is calculated automatically by the tool.

### B. Comparing Identical Files

Files are identical.

### C. Comparing Different Files

Files are different.

### D. Scanning a Directory

Scanning directory: ./test_directory

File: test_directory/file1.txt
SHA-256: <calculated SHA-256 hash>

File: test_directory/file2.txt
SHA-256: <calculated SHA-256 hash>

File: test_directory/file3.txt
SHA-256: <calculated SHA-256 hash>

## 8. Challenges Faced

- Calculating file hashes efficiently, including for large files.
- Handling invalid file paths and missing files.
- Comparing files reliably using SHA-256 hashes.
- Scanning directories and processing multiple files.
- Providing clear error messages and a simple command-line interface.

## 9. Future Improvements

- Export scan results to a text, CSV, or JSON report.
- Save baseline hashes and detect changes over time.
- Monitor files and directories for unauthorized modifications.
- Add logging and timestamps for scan activities.
- Support additional hash algorithms such as SHA-512.
- Add file filtering and exclusion options.
- Generate a detailed file integrity report.

**Disclaimer:** SentinelFile is intended for educational and defensive cybersecurity purposes. It helps identify file changes but does not independently determine whether a file is malicious.
