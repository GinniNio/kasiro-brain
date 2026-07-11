[CmdletBinding()]
param(
    [string]$DevRoot = 'C:\Dev',
    [string]$ArchiveRoot = 'C:\Archive',
    [string]$ClaudeProjectsRoot = 'C:\Users\hp\OneDrive\Documents\Claude\Projects',
    [string[]]$ArtifactRoots = @(
        'C:\Users\hp\Downloads',
        'C:\Users\hp\Desktop',
        'C:\Users\hp\OneDrive\Documents'
    )
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$outputRoot = Join-Path $DevRoot '_workspace-audit'
New-Item -ItemType Directory -Path $outputRoot -Force | Out-Null

$reportPath = Join-Path $outputRoot "workspace-audit-$timestamp.json"
$csvPath = Join-Path $outputRoot "artifact-duplicates-$timestamp.csv"

$expectedProjects = @(
    @{ Name = 'Kasiro'; Path = (Join-Path $DevRoot 'Kasiro'); Repo = 'GinniNio/Predicto' },
    @{ Name = 'GbegeBall'; Path = (Join-Path $DevRoot 'GbegeBall'); Repo = 'GinniNio/GbegeBall' },
    @{ Name = 'kasiro-brain'; Path = (Join-Path $DevRoot 'kasiro-brain'); Repo = 'GinniNio/kasiro-brain' },
    @{ Name = 'kasiro-RSS'; Path = (Join-Path $DevRoot 'kasiro-RSS'); Repo = 'GinniNio/kasiro-RSS' },
    @{ Name = 'gochat-dropz-private'; Path = (Join-Path $DevRoot 'gochat-dropz-private'); Repo = 'GinniNio/gochat-dropz-private' },
    @{ Name = 'pcbf-brain'; Path = (Join-Path $DevRoot 'pcbf-brain'); Repo = 'GinniNio/pcbf-brain' }
)

$projectResults = foreach ($project in $expectedProjects) {
    $exists = Test-Path -LiteralPath $project.Path
    $gitDir = Join-Path $project.Path '.git'
    [pscustomobject]@{
        name = $project.Name
        path = $project.Path
        repository = $project.Repo
        exists = $exists
        is_git_repository = ($exists -and (Test-Path -LiteralPath $gitDir))
    }
}

$legacyPaths = @(
    (Join-Path $ClaudeProjectsRoot 'Predicto'),
    (Join-Path $ClaudeProjectsRoot 'Prolego1'),
    (Join-Path $ClaudeProjectsRoot 'Prolego2')
)

$legacyResults = foreach ($path in $legacyPaths) {
    [pscustomobject]@{
        path = $path
        exists = (Test-Path -LiteralPath $path)
        recommended_action = 'archive'
    }
}

$artifactExtensions = @('.pptx', '.xlsx', '.xlsm', '.pdf', '.docx')
$artifactFiles = foreach ($root in $ArtifactRoots) {
    if (-not (Test-Path -LiteralPath $root)) { continue }
    Get-ChildItem -LiteralPath $root -File -Recurse -ErrorAction SilentlyContinue |
        Where-Object { $artifactExtensions -contains $_.Extension.ToLowerInvariant() } |
        Select-Object FullName, Name, Extension, Length, LastWriteTimeUtc
}

$hashRecords = foreach ($file in $artifactFiles) {
    try {
        $hash = Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256
        [pscustomobject]@{
            Hash = $hash.Hash
            FullName = $file.FullName
            Name = $file.Name
            Extension = $file.Extension
            Length = $file.Length
            LastWriteTimeUtc = $file.LastWriteTimeUtc
        }
    } catch {
        Write-Warning "Could not hash $($file.FullName): $($_.Exception.Message)"
    }
}

$duplicates = $hashRecords |
    Group-Object Hash |
    Where-Object { $_.Count -gt 1 } |
    ForEach-Object { $_.Group }

$duplicates | Sort-Object Hash, FullName | Export-Csv -LiteralPath $csvPath -NoTypeInformation -Encoding UTF8

$namingProblems = $artifactFiles |
    Where-Object {
        $_.Name -match '\(\d+\)' -or
        $_.Name -match '(?i)final[-_ ]?final' -or
        $_.Name -match '(?i)copy of' -or
        $_.Name -match '(?i)_v?\d+_v?\d+'
    } |
    Select-Object FullName, Name, LastWriteTimeUtc

$generatedFolderNames = @('node_modules', 'dist', 'build', '.vite', 'coverage', '.turbo', '.next', 'out')
$generatedFolders = @()
foreach ($project in $expectedProjects) {
    if (-not (Test-Path -LiteralPath $project.Path)) { continue }
    $generatedFolders += Get-ChildItem -LiteralPath $project.Path -Directory -Recurse -Force -ErrorAction SilentlyContinue |
        Where-Object { $generatedFolderNames -contains $_.Name } |
        Select-Object FullName, Name, LastWriteTimeUtc
}

$report = [pscustomobject]@{
    generated_at = (Get-Date).ToString('o')
    dev_root = $DevRoot
    archive_root = $ArchiveRoot
    expected_projects = $projectResults
    legacy_workspaces = $legacyResults
    exact_duplicate_artifact_count = @($duplicates).Count
    duplicate_csv = $csvPath
    naming_problem_count = @($namingProblems).Count
    naming_problems = $namingProblems
    generated_folder_count = @($generatedFolders).Count
    generated_folders = $generatedFolders
}

$report | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $reportPath -Encoding UTF8

Write-Host "Audit report: $reportPath"
Write-Host "Exact duplicate list: $csvPath"
Write-Host "Naming problems: $(@($namingProblems).Count)"
Write-Host "Generated folders: $(@($generatedFolders).Count)"
Write-Host 'No files were changed.'
