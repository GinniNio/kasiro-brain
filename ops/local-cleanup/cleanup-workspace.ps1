[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [string]$DevRoot = 'C:\Dev',
    [string]$ArchiveRoot = 'C:\Archive',
    [string]$ClaudeProjectsRoot = 'C:\Users\hp\OneDrive\Documents\Claude\Projects',
    [switch]$Apply,
    [switch]$RemoveGeneratedFolders
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$logRoot = Join-Path $DevRoot '_workspace-cleanup-logs'
$logFile = Join-Path $logRoot "cleanup-$timestamp.jsonl"

function Ensure-Directory {
    param([Parameter(Mandatory)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) {
        if ($Apply) {
            New-Item -ItemType Directory -Path $Path -Force | Out-Null
        }
        Write-Host "CREATE DIR: $Path"
    }
}

function Write-ActionLog {
    param(
        [string]$Action,
        [string]$Source,
        [string]$Destination,
        [string]$Status,
        [string]$Reason
    )
    if ($Apply) {
        Ensure-Directory -Path $logRoot
        [pscustomobject]@{
            timestamp   = (Get-Date).ToString('o')
            action      = $Action
            source      = $Source
            destination = $Destination
            status      = $Status
            reason      = $Reason
        } | ConvertTo-Json -Compress | Add-Content -LiteralPath $logFile -Encoding UTF8
    }
}

function Move-Safely {
    param(
        [Parameter(Mandatory)][string]$Source,
        [Parameter(Mandatory)][string]$Destination,
        [Parameter(Mandatory)][string]$Reason
    )

    if (-not (Test-Path -LiteralPath $Source)) {
        return
    }

    if (Test-Path -LiteralPath $Destination) {
        Write-Warning "SKIP: Destination already exists: $Destination"
        Write-ActionLog -Action 'move' -Source $Source -Destination $Destination -Status 'skipped' -Reason 'destination_exists'
        return
    }

    Write-Host "MOVE: $Source -> $Destination [$Reason]"
    if ($Apply -and $PSCmdlet.ShouldProcess($Source, "Move to $Destination")) {
        Ensure-Directory -Path (Split-Path -Parent $Destination)
        Move-Item -LiteralPath $Source -Destination $Destination
        Write-ActionLog -Action 'move' -Source $Source -Destination $Destination -Status 'completed' -Reason $Reason
    }
}

function Remove-GeneratedFolder {
    param([Parameter(Mandatory)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        return
    }

    Write-Host "REMOVE GENERATED: $Path"
    if ($Apply -and $RemoveGeneratedFolders -and $PSCmdlet.ShouldProcess($Path, 'Remove generated folder')) {
        Remove-Item -LiteralPath $Path -Recurse -Force
        Write-ActionLog -Action 'remove_generated' -Source $Path -Destination '' -Status 'completed' -Reason 'reproducible_build_output'
    }
}

Ensure-Directory -Path $DevRoot
Ensure-Directory -Path $ArchiveRoot
Ensure-Directory -Path $logRoot

$activeProjects = @(
    @{ Name = 'Kasiro'; Repo = 'GinniNio/Predicto'; Target = (Join-Path $DevRoot 'Kasiro') },
    @{ Name = 'GbegeBall'; Repo = 'GinniNio/GbegeBall'; Target = (Join-Path $DevRoot 'GbegeBall') },
    @{ Name = 'kasiro-brain'; Repo = 'GinniNio/kasiro-brain'; Target = (Join-Path $DevRoot 'kasiro-brain') },
    @{ Name = 'kasiro-RSS'; Repo = 'GinniNio/kasiro-RSS'; Target = (Join-Path $DevRoot 'kasiro-RSS') },
    @{ Name = 'gochat-dropz-private'; Repo = 'GinniNio/gochat-dropz-private'; Target = (Join-Path $DevRoot 'gochat-dropz-private') },
    @{ Name = 'pcbf-brain'; Repo = 'GinniNio/pcbf-brain'; Target = (Join-Path $DevRoot 'pcbf-brain') }
)

foreach ($project in $activeProjects) {
    Ensure-Directory -Path $project.Target
}

$archiveStamp = Get-Date -Format 'yyyy-MM-dd'
$archiveBase = Join-Path $ArchiveRoot "workspace-cleanup-$archiveStamp"

$legacyCandidates = @(
    @{ Source = (Join-Path $ClaudeProjectsRoot 'Predicto'); Destination = (Join-Path $archiveBase 'Predicto-legacy'); Reason = 'deprecated_workspace' },
    @{ Source = (Join-Path $ClaudeProjectsRoot 'Prolego1'); Destination = (Join-Path $archiveBase 'Prolego1-legacy'); Reason = 'deprecated_workspace' },
    @{ Source = (Join-Path $ClaudeProjectsRoot 'Prolego2'); Destination = (Join-Path $archiveBase 'Prolego2-legacy'); Reason = 'deprecated_workspace' }
)

foreach ($item in $legacyCandidates) {
    Move-Safely -Source $item.Source -Destination $item.Destination -Reason $item.Reason
}

$generatedNames = @('node_modules', 'dist', 'build', '.vite', 'coverage', '.turbo', '.next', 'out')
$scanRoots = @(
    (Join-Path $DevRoot 'Kasiro'),
    (Join-Path $DevRoot 'GbegeBall'),
    (Join-Path $DevRoot 'kasiro-RSS')
)

foreach ($root in $scanRoots) {
    if (-not (Test-Path -LiteralPath $root)) { continue }
    foreach ($generatedName in $generatedNames) {
        Get-ChildItem -LiteralPath $root -Directory -Recurse -Force -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -eq $generatedName } |
            ForEach-Object { Remove-GeneratedFolder -Path $_.FullName }
    }
}

$manifestPath = Join-Path $DevRoot 'WORKSPACE_MANIFEST.local.yaml'
$manifest = @"
version: 1.0
generated_at: $(Get-Date -Format 'yyyy-MM-ddTHH:mm:ssK')
active_root: $DevRoot
archive_root: $ArchiveRoot
projects:
  kasiro:
    local_path: $(Join-Path $DevRoot 'Kasiro')
    repository: GinniNio/Predicto
    status: active
  gbegeball:
    local_path: $(Join-Path $DevRoot 'GbegeBall')
    repository: GinniNio/GbegeBall
    status: active
  kasiro_brain:
    local_path: $(Join-Path $DevRoot 'kasiro-brain')
    repository: GinniNio/kasiro-brain
    status: active
  kasiro_rss:
    local_path: $(Join-Path $DevRoot 'kasiro-RSS')
    repository: GinniNio/kasiro-RSS
    status: active
  gochat_dropz:
    local_path: $(Join-Path $DevRoot 'gochat-dropz-private')
    repository: GinniNio/gochat-dropz-private
    status: pending_repository
  pcbf:
    local_path: $(Join-Path $DevRoot 'pcbf-brain')
    repository: GinniNio/pcbf-brain
    status: pending_repository
"@

Write-Host "WRITE MANIFEST: $manifestPath"
if ($Apply -and $PSCmdlet.ShouldProcess($manifestPath, 'Write local workspace manifest')) {
    $manifest | Set-Content -LiteralPath $manifestPath -Encoding UTF8
    Write-ActionLog -Action 'write_manifest' -Source '' -Destination $manifestPath -Status 'completed' -Reason 'workspace_source_map'
}

Write-Host ''
if ($Apply) {
    Write-Host "Cleanup applied. Log: $logFile"
} else {
    Write-Host 'Dry run only. No files were moved or deleted.'
    Write-Host 'Run with -Apply to create directories, archive legacy workspaces, and write the manifest.'
    Write-Host 'Add -RemoveGeneratedFolders to remove reproducible build folders.'
}
