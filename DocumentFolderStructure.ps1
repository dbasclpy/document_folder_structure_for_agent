<# 
.SYNOPSIS
    Documents the folder structure of a repository for an LLM.

.DESCRIPTION
    This script maps out the structure of the current working directory and its subdirectories,
    considering .gitignore rules, module import tracking, and outputs the result in markdown format.

.PARAMETER log
    Enables verbose logging.

.PARAMETER noignore
    Disables .gitignore processing.

.PARAMETER noimporttracking
    Disables module import tracking.

.PARAMETER outputpath
    Specifies the output file path.

.PARAMETER help
    Displays help information.

.EXAMPLE
    .\DocumentFolderStructure.ps1 --log

.NOTES
    Author: Your Name
#>

[CmdletBinding()]
param(
    [switch]$help,
    [switch]$log,
    [switch]$noignore,
    [switch]$noimporttracking,
    [string]$outputpath
)

# Function to display help information
function Show-Help {
    $helpText = @"
Usage: .\DocumentFolderStructure.ps1 [options]

Options:
  --help                Show this help message and exit.
  --log                 Enable verbose logging.
  --noignore            Disable .gitignore processing.
  --noimporttracking    Disable module import tracking.
  --outputpath "path"   Specify the output file path.

Description:
  This script documents the folder structure of the current repository directory.
  It considers .gitignore files, tracks module imports in Python and Node.js files,
  and outputs the result in markdown format to /documentation/folder_structure.md
  unless an output path is specified.

Examples:
  .\DocumentFolderStructure.ps1
  .\DocumentFolderStructure.ps1 --noignore --outputpath "C:\output\structure.md"
"@
    Write-Host $helpText
}

# Function to log messages based on the --log parameter
function Log-Message {
    param(
        [string]$Message
    )
    if ($log) {
        Write-Host $Message
    }
}

# Function to convert .gitignore patterns to regex
function Convert-GitIgnorePatternToRegex {
    param(
        [string]$Pattern
    )

    # Escape regex special characters
    $escapedPattern = [Regex]::Escape($Pattern)

    # Replace escaped '*' with '.*'
    $escapedPattern = $escapedPattern -replace '\\\*', '.*'

    # Replace escaped '?' with '.'
    $escapedPattern = $escapedPattern -replace '\\\?', '.'

    # Handle '**' patterns
    $escapedPattern = $escapedPattern -replace '(\.\*){2,}', '.*'

    # Handle patterns starting with '/'
    if ($Pattern.StartsWith('/')) {
        $regexPattern = '^' + $escapedPattern.TrimStart('/')
    } else {
        $regexPattern = '(^|.*/)' + $escapedPattern
    }

    # Patterns ending with '/' should match directories
    if ($Pattern.EndsWith('/')) {
        $regexPattern += '(/.*)?$'
    } else {
        $regexPattern += '(/.*)?$'
    }

    return $regexPattern
}

# Function to parse .gitignore and return patterns with comments
function Get-GitIgnorePatterns {
    param(
        [string]$Path
    )
    $patterns = @()
    $lines = Get-Content $Path
    $currentComment = $null

    foreach ($line in $lines) {
        $trimmedLine = $line.Trim()
        if ($trimmedLine -eq '' -or $trimmedLine.StartsWith('#')) {
            # This is a comment or empty line
            if ($trimmedLine.StartsWith('#')) {
                $currentComment = $trimmedLine.TrimStart('#').Trim()
            }
            continue
        } else {
            # This is a pattern
            $regexPattern = Convert-GitIgnorePatternToRegex $trimmedLine
            $pattern = @{
                Pattern = $trimmedLine
                RegexPattern = $regexPattern
                Comment = $currentComment
            }
            $patterns += $pattern
            $currentComment = $null
        }
    }
    return $patterns
}

# Function to check if a file/folder matches a .gitignore pattern
function MatchesGitIgnorePattern {
    param(
        [System.IO.FileSystemInfo]$Item,
        [string]$RegexPattern
    )
    # Normalize paths to use '/' as separator
    $rootPath = (Get-Location).Path
    $relativePath = $Item.FullName.Substring($rootPath.Length + 1).Replace('\', '/')

    if ([Regex]::IsMatch($relativePath, $RegexPattern)) {
        return $true
    } else {
        return $false
    }
}

# Function to analyze imports in Python and Node.js files
function Analyze-Imports {
    param(
        [string]$FilePath
    )
    $imports = @()
    $content = Get-Content $FilePath

    $extension = [System.IO.Path]::GetExtension($FilePath).ToLower()

    foreach ($line in $content) {
        if ($extension -eq '.py') {
            # For Python files
            if ($line -match '^\s*import\s+([^\s]+)') {
                $importedModule = $matches[1]
                $imports += $importedModule
            } elseif ($line -match '^\s*from\s+([^\s]+)\s+import\s+([^\s]+)') {
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
        if ($import.StartsWith('.')) {
            # Relative import
            $localImports += $import
        } else {
            # Check if file exists in the project
            $possibleModulePath = Join-Path (Split-Path $FilePath -Parent) "$import$extension"
            if (Test-Path $possibleModulePath) {
                $localImports += $import
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

# Function to recursively get folder structure
function Get-FolderStructure {
    param(
        [string]$Path,
        [array]$GitIgnorePatterns,
        [switch]$NoImportTracking
    )
    $items = Get-ChildItem -Path $Path -Force

    $structure = @()

    foreach ($item in $items) {
        # Skip .git folder
        if ($item.Name -eq '.git') {
            continue
        }

        # Check if the item matches any .gitignore pattern
        $isIgnored = $false
        $matchedComment = $null

        if (-not $noignore -and $GitIgnorePatterns.Count -gt 0) {
            foreach ($pattern in $GitIgnorePatterns) {
                if (MatchesGitIgnorePattern -Item $item -RegexPattern $pattern.RegexPattern) {
                    $isIgnored = $true
                    $matchedComment = $pattern.Comment
                    break
                }
            }
        }

        if ($isIgnored) {
            # Include top-level folder/file with comment
            $structure += @{
                Name = $item.Name
                IsDirectory = $item.PSIsContainer
                IsIgnored = $true
                Comment = $matchedComment
                Children = @()
            }
        } else {
            # Include the item and process children if directory
            $entry = @{
                Name = $item.Name
                IsDirectory = $item.PSIsContainer
                IsIgnored = $false
                Comment = $null
                Children = @()
            }

            if ($item.PSIsContainer) {
                $entry.Children = Get-FolderStructure -Path $item.FullName -GitIgnorePatterns $GitIgnorePatterns -NoImportTracking:$NoImportTracking
            } else {
                # Process import tracking
                if (-not $NoImportTracking -and ($item.Extension -eq '.py' -or $item.Extension -eq '.js' -or $item.Extension -eq '.ts')) {
                    $imports = Analyze-Imports -FilePath $item.FullName
                    $entry.Comment = $imports
                }
            }

            $structure += $entry
        }
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

        if ($entry.Comment) {
            $line += " #$($entry.Comment)"
        } elseif ($entry.IsIgnored -and $entry.Comment) {
            $line += " #$($entry.Comment)"
        } elseif ($entry.IsIgnored) {
            $line += " #(ignored)"
        }

        $Writer.WriteLine($line)

        if ($entry.IsDirectory -and $entry.Children.Count -gt 0) {
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
            $childCounts = Count-FilesAndDirectories -Structure $entry.Children
            $fileCount += $childCounts.FileCount
            $dirCount += $childCounts.DirCount
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
if ($help) {
    Show-Help
    exit
}

$rootPath = Get-Location
$gitignorePath = Join-Path $rootPath '.gitignore'
$gitignorePatterns = @()

if (-not $noignore -and (Test-Path $gitignorePath)) {
    $gitignorePatterns = Get-GitIgnorePatterns -Path $gitignorePath
    Log-Message "Parsed .gitignore file."
}

Log-Message "Building folder structure..."
$folderStructure = Get-FolderStructure -Path $rootPath -GitIgnorePatterns $gitignorePatterns -NoImportTracking:$noimporttracking

# Count files and directories
$counts = Count-FilesAndDirectories -Structure $folderStructure
$filesFound = $counts.FileCount
$dirsFound = $counts.DirCount

Write-Host "Found $filesFound files and $dirsFound directories."

# Determine output path
if ($outputpath) {
    $outputFile = $outputpath
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
