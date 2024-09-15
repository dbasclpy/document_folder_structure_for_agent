<#
.SYNOPSIS
    Documents the folder structure of a repository for an LLM.

.DESCRIPTION
    This script maps out the structure of the current working directory and its subdirectories,
    considering directory entries in the .gitignore file, module import tracking, and outputs the result in markdown format.

.PARAMETER Help
    Displays help information.

.PARAMETER Log
    Enables verbose logging and dynamic progress display.

.PARAMETER NoIgnore
    Disables .gitignore processing.

.PARAMETER NoImportTracking
    Disables module import tracking.

.PARAMETER OutputPath
    Specifies the output file path.

.EXAMPLE
    .\DocumentFolderStructure.ps1 -Log

.NOTES
    Author: Your Name
#>

[CmdletBinding()]
param(
    [switch]$Help,
    [switch]$Log,
    [switch]$NoIgnore,
    [switch]$NoImportTracking,
    [string]$OutputPath
)

# Function to display help information
function Show-Help {
    $helpText = @"
Usage: .\DocumentFolderStructure.ps1 [options]

Options:
  -Help                      Show this help message and exit.
  -Log                       Enable verbose logging and dynamic progress display.
  -NoIgnore                  Disable .gitignore processing.
  -NoImportTracking          Disable module import tracking.
  -OutputPath "path"         Specify the output file path.

Description:
  This script documents the folder structure of the current repository directory.
  It considers directory entries in the .gitignore file, tracks module imports in Python and Node.js files,
  and outputs the result in markdown format to /documentation/folder_structure.md
  unless an output path is specified.

Examples:
  .\DocumentFolderStructure.ps1
  .\DocumentFolderStructure.ps1 -NoIgnore -OutputPath "C:\output\structure.md"
"@
    Write-Host $helpText
}

# Function to log messages based on the -Log parameter
function Log-Message {
    param(
        [string]$Message
    )
    if ($Log) {
        Write-Host $Message
    }
}

# Function to parse .gitignore and return directory patterns with comments
function Get-GitIgnoreDirectoryPatterns {
    param(
        [string]$Path
    )
    $patterns = @()
    $lines = Get-Content $Path -ErrorAction SilentlyContinue
    $currentComment = $null

    foreach ($line in $lines) {
        $trimmedLine = $line.Trim()
        if ($trimmedLine -eq '' -or $trimmedLine.StartsWith('#')) {
            # This is a comment or empty line
            if ($trimmedLine.StartsWith('#')) {
                $currentComment = $trimmedLine.TrimStart('#').Trim()
            }
            continue
        } elseif ($trimmedLine.EndsWith('/')) {
            # This is a directory pattern
            $pattern = @{
                DirectoryName = $trimmedLine.TrimEnd('/')
                Comment = $currentComment
            }
            $patterns += $pattern
            $currentComment = $null
        } else {
            # Skip file patterns
            $currentComment = $null
            continue
        }
    }
    return $patterns
}

# Function to check if a directory should be ignored
function Should-IgnoreDirectory {
    param(
        [string]$DirectoryName,
        [array]$IgnorePatterns
    )
    foreach ($pattern in $IgnorePatterns) {
        if ($DirectoryName -ieq $pattern.DirectoryName) {
            return @{
                IsIgnored = $true
                Comment = $pattern.Comment
            }
        }
    }
    return @{
        IsIgnored = $false
        Comment = $null
    }
}

# Function to analyze imports in Python and Node.js files
function Analyze-Imports {
    param(
        [string]$FilePath
    )
    $imports = @()
    $content = Get-Content $FilePath -ErrorAction SilentlyContinue

    if (!$content) {
        return $null
    }

    $extension = [System.IO.Path]::GetExtension($FilePath).ToLower()

    foreach ($line in $content) {
        if ($extension -eq '.py') {
            # For Python files
            if ($line -match '^\s*import\s+(.+)') {
                $importedModules = $line -replace '^\s*import\s+', ''
                $modules = $importedModules -split ',\s*'
                $imports += $modules
            } elseif ($line -match '^\s*from\s+([^\s]+)\s+import\s+') {
                $importedModule = $matches[1]
                $imports += $importedModule
            }
        } elseif ($extension -eq '.js' -or $extension -eq '.ts') {
            # For JavaScript or TypeScript files
            if ($line -match "^\s*(?:var|let|const)?\s*[^\s]*\s*=\s*require\(['""](.+?)['""]\)") {
                $importedModule = $matches[1]
                $imports += $importedModule
            } elseif ($line -match "^\s*import\s+.*\s+from\s+['""](.+?)['""];?") {
                $importedModule = $matches[1]
                $imports += $importedModule
            }
        }
    }

    # Filter imports to local modules
    $localImports = @()
    foreach ($import in $imports) {
        # Sanitize the import name
        $import = $import.Trim()

        if ($import.StartsWith('.')) {
            # Relative import
            $localImports += $import
        } else {
            # Check if file exists in the project
            try {
                $parentDir = Split-Path $FilePath -Parent
                $possibleModulePath = Join-Path $parentDir "$import$extension"

                if (Test-Path -LiteralPath $possibleModulePath) {
                    $localImports += $import
                }
            } catch {
                # Handle invalid paths
                continue
            }
        }
    }

    if ($localImports.Count -gt 0) {
        $comment = "references " + ($localImports -join ', ') + " in imports"
        return $comment
    } else {
        return $null
    }
}

# Global counters for dynamic progress display
$global:FilesCrawled = 0
$global:DirectoriesCrawled = 0

# Function to recursively get folder structure
function Get-FolderStructure {
    param(
        [string]$Path,
        [array]$IgnorePatterns,
        [switch]$NoImportTracking
    )
    $items = Get-ChildItem -Path $Path -Force -ErrorAction SilentlyContinue

    $structure = @()

    foreach ($item in $items) {
        # Skip .git folder
        if ($item.Name -eq '.git') {
            continue
        }

        # Check if the directory should be ignored
        if ($item.PSIsContainer) {
            if (-not $NoIgnore -and $IgnorePatterns.Count -gt 0) {
                $ignoreResult = Should-IgnoreDirectory -DirectoryName $item.Name -IgnorePatterns $IgnorePatterns
                if ($ignoreResult.IsIgnored) {
                    # Add the directory to the structure, mark it as ignored, include comment
                    $entry = @{
                        Name = $item.Name
                        IsDirectory = $true
                        IsIgnored = $true
                        Comment = $ignoreResult.Comment
                        Children = @()
                    }
                    $structure += $entry
                    # Do not crawl into this directory
                    continue
                }
            }
        }

        # Update progress
        if ($Log) {
            if ($item.PSIsContainer) {
                $global:DirectoriesCrawled++
            } else {
                $global:FilesCrawled++
            }
            $progressMessage = "Crawled $global:FilesCrawled files and $global:DirectoriesCrawled directories."
            Write-Progress -Activity "Processing Files" -Status $progressMessage
        }

        # Include the item and process children if directory
        $entry = @{
            Name = $item.Name
            IsDirectory = $item.PSIsContainer
            IsIgnored = $false
            Comment = $null
            Children = @()
        }

        if ($item.PSIsContainer) {
            $entry.Children = Get-FolderStructure -Path $item.FullName -IgnorePatterns $IgnorePatterns -NoImportTracking:$NoImportTracking
        } else {
            # Process import tracking
            if (-not $NoImportTracking -and ($item.Extension -eq '.py' -or $item.Extension -eq '.js' -or $item.Extension -eq '.ts')) {
                $imports = Analyze-Imports -FilePath $item.FullName
                $entry.Comment = $imports
            }
        }

        $structure += $entry
    }
    return $structure
}

# Function to write the folder structure to markdown
function Write-FolderStructure {
    param(
        [array]$Structure,
        [int]$IndentLevel = 0,
        [System.IO.StreamWriter]$Writer
    )

    foreach ($entry in $Structure) {
        $indent = ('    ' * $IndentLevel)
        $prefix = $indent + '├── '
        $line = $prefix + $entry.Name

        if ($entry.IsIgnored) {
            if ($entry.Comment) {
                $line += " #$($entry.Comment)"
            } else {
                $line += " #(ignored)"
            }
        } elseif ($entry.Comment) {
            $line += " #$($entry.Comment)"
        }

        $Writer.WriteLine($line)

        # Only process children if the entry is not ignored
        if ($entry.IsDirectory -and $entry.Children.Count -gt 0 -and -not $entry.IsIgnored) {
            Write-FolderStructure -Structure $entry.Children -IndentLevel ($IndentLevel + 1) -Writer $Writer
        }
    }
}

# Function to count files and directories
function Count-FilesAndDirectories {
    param(
        [array]$Structure
    )
    $fileCount = 0
    $dirCount = 0

    foreach ($entry in $Structure) {
        if ($entry.IsDirectory) {
            $dirCount++
            if (-not $entry.IsIgnored) {
                $childCounts = Count-FilesAndDirectories -Structure $entry.Children
                $fileCount += $childCounts.FileCount
                $dirCount += $childCounts.DirCount
            }
        } else {
            $fileCount++
        }
    }

    return @{
        FileCount = $fileCount
        DirCount = $dirCount
    }
}

# Main script execution starts here
if ($Help) {
    Show-Help
    exit
}

$rootPath = (Get-Location).Path
$gitignorePath = Join-Path $rootPath '.gitignore'
$ignorePatterns = @()

if (-not $NoIgnore -and (Test-Path $gitignorePath)) {
    $ignorePatterns = Get-GitIgnoreDirectoryPatterns -Path $gitignorePath
    Log-Message "Parsed .gitignore file."
}

Log-Message "Building folder structure..."
$folderStructure = Get-FolderStructure -Path $rootPath -IgnorePatterns $ignorePatterns -NoImportTracking:$NoImportTracking

# Count files and directories
$counts = Count-FilesAndDirectories -Structure $folderStructure
$filesFound = $counts.FileCount
$dirsFound = $counts.DirCount

Write-Host "Found $filesFound files and $dirsFound directories."

# Determine output path
if ($OutputPath) {
    $outputFile = $OutputPath
} else {
    # Search for 'documentation' or 'docs' folder
    $docFolder = Get-ChildItem -Path $rootPath -Directory -Force | Where-Object {
        $_.Name -match '^(?i)(documentation|docs)$'
    }

    if ($docFolder) {
        $docFolderPath = $docFolder[0].FullName
        Write-Host "Using existing documentation directory at $docFolderPath"
    } else {
        # Create 'documentation' folder
        $docFolderPath = Join-Path $rootPath 'documentation'
        New-Item -Path $docFolderPath -ItemType Directory -Force | Out-Null
        Write-Host "Created documentation directory at $docFolderPath"
    }

    $outputFile = Join-Path $docFolderPath 'folder_structure.md'
}

# Write the folder structure to the output file
$header = "This is the current folder structure of the repository's directory. # indicates comments clarifying what is in that folder or module that can be relevant`n"

$writer = New-Object System.IO.StreamWriter($outputFile, $false)
$writer.WriteLine($header)
Write-FolderStructure -Structure $folderStructure -Writer $writer
$writer.Close()

Write-Host "Folder structure documentation written to $outputFile"
