# Cybersecurity Tools

A collection of cybersecurity tools developed using Python and Bash to support file integrity verification, file analysis, and defensive security tasks.

## Projects

### 1. SentinelFile – File Integrity Checker

A Python-based tool that calculates SHA-256 hashes to verify file integrity and detect modifications.

**Features**
- Calculate SHA-256 file hashes.
- Compare two files to detect differences.
- Scan directories and calculate file hashes.
- Interactive command-line menu.
- Basic error handling.

**Technologies:** Python 3, SHA-256, Linux.

**How to Run**

```bash
cd SentinelFile
python3 sentinelfile.py --help
```

### 2. File-IOC-Scanner – File Indicator of Compromise Scanner

A Bash-based tool designed to scan files for Indicators of Compromise (IOCs), such as suspicious file hashes or patterns, depending on the implemented detection rules.

**Features**
- File and IOC scanning.
- Command-line execution.
- Basic error handling.
- Scan results displayed in the terminal.

**Technologies:** Bash, Linux, Cybersecurity.

**How to Run**

```bash
cd File-IOC-Scanner
chmod +x file_ioc_scanner.sh
./file_ioc_scanner.sh --help
```

*Note: The available options depend on the script's implementation.*

## Repository Structure

```text
Cybersecurity-Tools/
├── SentinelFile/
│   ├── sentinelfile.py
│   └── README.md
├── File-IOC-Scanner/
│   ├── file_ioc_scanner.sh
│   └── README.md
└── README.md
```

## Requirements

- Linux environment (Kali Linux recommended).
- Python 3 for SentinelFile.
- Bash for File-IOC-Scanner.
- Git to clone the repository.

## Learning Objectives

- Practice Python and Bash scripting.
- Understand file integrity verification using cryptographic hashes.
- Develop command-line cybersecurity tools.
- Improve Linux command-line and error-handling skills.
- Explore defensive security concepts
