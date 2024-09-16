# DocumentFolderStructure.ps1

A PowerShell script to document the folder structure of a repository, considering .gitignore rules and module imports, outputting the result in markdown format suitable for use with Large Language Models (LLMs).

## Table of Contents

1. [Introduction](#introduction)
2. [Features](#features)
3. [Installation](#installation)
4. [Usage](#usage)
   - [Parameters](#parameters)
   - [Examples](#examples)
5. [Planned Features](#planned-features)
6. [License](#license)
7. [Acknowledgments](#acknowledgments)

## Introduction

DocumentFolderStructure.ps1 is a versatile PowerShell script designed to map out the folder structure of a repository, considering .gitignore rules and tracking module imports in Python and Node.js files. The script outputs the result in a markdown file, making it suitable for documentation purposes and for use with Large Language Models (LLMs).

This tool is particularly useful for developers and teams who want to:

- Provide a clear overview of their project's structure.
- Automatically generate up-to-date documentation.
- Assist LLMs in understanding the context of the codebase.

## Features

- **.gitignore Processing**: Skips files and directories specified in .gitignore, ensuring that ignored content is not included in the output.
- **Module Import Tracking**: Analyzes Python (.py), JavaScript (.js), and TypeScript (.ts) files to identify and document local module imports.
- **Customizable Output**: Outputs the folder structure in markdown format to a specified location, defaulting to /documentation/folder_structure.md.
- **Verbose Logging**: Provides detailed logging when the --log parameter is used.
- **Extensibility**: Organized code structure allows for easy expansion and addition of new features.
- **Help Documentation**: Includes a comprehensive help section accessible via the --help parameter.

## Installation

1. **Download the Script**: Save DocumentFolderStructure.ps1 to your repository's root directory.

2. **Set Execution Policy** (if necessary):

   To allow the execution of PowerShell scripts on your system, you may need to adjust the execution policy:

   ```powershell
   Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
   ```

   > Note: Running scripts may pose security risks. Ensure you understand the implications before changing execution policies.

3. **Permissions**:

   Ensure you have the necessary permissions to create directories and write files in the target location.

## Usage

Run the script from the root directory of your repository:

```powershell
.\DocumentFolderStructure.ps1 [options]
```

### Parameters

- `--help`: Displays help information and exits.
- `--log`: Enables verbose logging during script execution.
- `--noignore`: Disables .gitignore processing. All files and directories will be included.
- `--noimporttracking`: Disables module import tracking in Python and Node.js files.
- `--outputpath "path"`: Specifies a custom output file path for the markdown file.

### Examples

1. **Default Execution**:

   Generates the folder structure, considering .gitignore and import tracking, and outputs to /documentation/folder_structure.md.

   ```powershell
   .\DocumentFolderStructure.ps1
   ```

2. **Enable Verbose Logging**:

   ```powershell
   .\DocumentFolderStructure.ps1 --log
   ```

3. **Disable .gitignore Processing**:

   Includes all files and directories, regardless of .gitignore rules.

   ```powershell
   .\DocumentFolderStructure.ps1 --noignore
   ```

4. **Disable Import Tracking**:

   Skips analysis of module imports in code files.

   ```powershell
   .\DocumentFolderStructure.ps1 --noimporttracking
   ```

5. **Specify Custom Output Path**:

   Outputs the markdown file to a specified location.

   ```powershell
   .\DocumentFolderStructure.ps1 --outputpath "C:\path\to\output\structure.md"
   ```

6. **Display Help Information**:

   ```powershell
   .\DocumentFolderStructure.ps1 --help
   ```

## Planned Features

We are continuously working to enhance the functionality of DocumentFolderStructure.ps1. Here are some intelligent features planned for future releases:

1. **Language Agnostic Import Tracking**:
   Extend module import tracking to support additional programming languages such as Ruby, Go, and Java, increasing the script's versatility.

2. **Graphical Visualization**:
   Generate graphical representations of the folder structure and module dependencies, providing an intuitive visual aid for developers.

3. **Integration with CI/CD Pipelines**:
   Automate the execution of the script within Continuous Integration/Continuous Deployment pipelines to keep documentation up-to-date with each commit.

4. **Enhanced .gitignore Parsing**:
   Improve the parsing of complex .gitignore patterns, including support for nested .gitignore files within subdirectories.

5. **Configuration File Support**:
   Allow users to define settings and preferences in a configuration file (e.g., JSON or YAML), facilitating easier customization without modifying the script directly.

6. **Interactive Mode**:
   Introduce an interactive mode where users can select options and parameters through prompts, making the script more accessible to those less familiar with command-line interfaces.

7. **Error Handling and Reporting**:
   Implement robust error handling to capture and report issues encountered during execution, providing users with actionable feedback.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

#

For any questions, issues, or contributions, please feel free to open an issue or submit a pull request on GitHub.
