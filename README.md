# Kernel.asm Analysis & Documentation

## Overview
This is a basic x86 real-mode kernel implementing a simple file system with Unix-like commands. It loads at memory address `0x8000` and provides an interactive shell interface.

## Architecture

### Memory Layout
- **Code Origin**: `0x8000`
- **File Table**: Starts after code section (~1600 bytes reserved)
- **File Data**: 25600 bytes allocated storage
- **Buffer**: 256 bytes for command input

### File System Structure

#### File Table Entry (80 bytes each)
```
Offset | Size | Description
-------|------|------------
0-7    | 8    | File name (null-padded)
8-71   | 64   | Parent directory path
72-73  | 2    | Start position in file_data
74-75  | 2    | File size in bytes
76     | 1    | Type (0=file, 1=folder)
77     | 1    | Flags (reserved)
78-79  | 2    | Reserved
```

#### Pre-initialized Files
1. **file1**: Located at `/`, position 1, size 50 bytes
2. **code**: Located at `/folder`, position 51, size 8 bytes
3. **folder**: Root directory entry

## Supported Commands

### 1. `ls [path]`
Lists files and directories in current or specified path.
- Shows files with `.txt` extension
- Shows directories with `/` suffix
- Supports absolute paths starting with `/`

### 2. `cd <directory>`
Changes current directory.
- `cd /` - Go to root
- `cd folder` - Relative path
- `cd /folder` - Absolute path

### 3. `mkdir <name> [parent]`
Creates a new directory.
- Parent defaults to current directory if not specified
- Sets file_type to 1 (folder)

### 4. `mk <name> [pos] [size] [parent]`
Creates a new file.
- `pos`: Starting position in file_data (use `s` suffix for sectors: 512 bytes)
- `size`: File size (use `s` suffix for sectors)
- Example: `mk test 1s 512` creates file at sector 1 with 512 bytes

### 5. `cat <filename>`
Displays file information (incomplete implementation - doesn't show content).

### 6. `nano <filename> [content]`
Basic text editor functionality.
- Writes content to existing files
- Handles both absolute and relative paths

### 7. `rm <filename>`
Deletes a file or directory.
- Removes entry from file table
- Shifts remaining entries to fill gap

### 8. `sh <script_file>`
Executes commands from a script file.
- Commands separated by `-` character
- Recursively processes each command

### 9. `clear`
Clears the screen (sets video mode 3).

## Key Functions

### File Operations

#### `get_siz_pos`
Searches file table for a file by name and parent path, returns:
- `file_pos`: Starting position
- `file_size`: File size
- `file_type`: File or folder

#### `get_name_path`
Parses a full path into:
- `file_name`: The filename (last component)
- `file_parent_name`: Parent directory path

#### `get_file_content`
Retrieves file data pointer and size.
Returns `SI` pointing to file data, `CX` containing size.

### Directory Operations

#### `check_folder_iroot`
Verifies if a folder exists in specified parent.
Returns `AX=1` if found, `AX=0` otherwise.

#### `find_folder_end`
Finds the null terminator in the folder path.

#### `print_file_table`
Lists all files in current directory (`folder` variable).
- Filters by parent directory
- Formats output with file extensions

### Utility Functions

#### `clear_rig`
Resets registers AX, BX, CX, DX to zero.

#### `new_laen`
Prints carriage return and line feed (newline).

#### `print`
Prints null-terminated string pointed to by SI.

#### `input`
Main command loop:
1. Displays prompt with current directory
2. Reads user input
3. Parses and dispatches commands

## Known Issues & Limitations

### 1. File Content Display
The `cat` command doesn't actually display file contents - it only retrieves file metadata.

### 2. Hard-coded Limits
- File names: 8 characters (no extension support)
- Parent paths: 64 characters
- Command buffer: 50 characters
- File data: 25600 bytes total
- Maximum files: Limited by file_table space

### 3. No Path Validation
- No checking for duplicate filenames
- No prevention of circular directory references
- No validation of file positions or sizes

### 4. Memory Management
- Fixed file_data array - no dynamic allocation
- Files can overlap if positions not carefully managed
- Deleted file data not reclaimed

### 5. Script Execution
The `sh` command uses `-` as delimiter, which is unconventional.

### 6. No Error Messages
Most operations fail silently without user feedback.

## Technical Details

### String Comparison
Uses `repe cmpsb` (repeat while equal, compare string bytes) for:
- File name matching
- Parent directory validation
- Command parsing

### Video Services
Uses BIOS interrupt `0x10`:
- `AH=0x00`: Set video mode
- `AH=0x0E`: Teletype output (print character)

### Keyboard Input
Uses BIOS interrupt `0x16`:
- `AH=0x00`: Wait for and read keystroke

## Potential Improvements

1. **Add error handling and user feedback**
2. **Implement actual file content reading for `cat`**
3. **Add file extension support**
4. **Implement proper memory allocation**
5. **Add file permission system**
6. **Support longer filenames (using multiple entries)**
7. **Add command history**
8. **Implement tab completion**
9. **Add recursive directory listing (`ls -R`)**
10. **Better script syntax (use newlines instead of `-`)**

## Example Usage

```
┌─[/]
└─> mkdir test
┌─[/]
└─> cd test
┌─[/test]
└─> mk file1 0 100
┌─[/test]
└─> ls
file1.txt
┌─[/test]
└─> cd /
┌─[/]
└─> ls
test/
```

## Boot Process

1. Disables interrupts (`cli`)
2. Sets data segment to 0
3. Prints "Kernel loaded!"
4. Sets video mode to text mode 3 (80x25)
5. Initializes path to `/folder/code`
6. Increments file count by 3
7. Sets current folder to `/`
8. Enters main input loop

## Code Quality Notes

- **Registers not always preserved**: Functions don't consistently save/restore registers
- **Inconsistent error handling**: Some functions return error codes, others don't
- **Magic numbers**: Hardcoded values (80, 64, 8) scattered throughout
- **No stack frame usage**: All functions use global variables
- **Testing code**: `test` function at line 253 appears to be debug code
