# Local Workspace Cleanup

This package audits and reorganises the Windows workspace described in `ops/WORKSPACE_MANIFEST.yaml`.

## Safety model

- `audit-workspace.ps1` is read-only.
- `cleanup-workspace.ps1` defaults to dry-run mode.
- No generated folders are deleted unless both `-Apply` and `-RemoveGeneratedFolders` are supplied.
- Legacy project folders are moved to `C:\Archive`; they are not deleted.
- Existing destinations are never overwritten.
- Applied actions are written to a JSONL log under `C:\Dev\_workspace-cleanup-logs`.

## 1. Pull the control repository

From PowerShell:

```powershell
cd C:\Dev\kasiro-brain
git pull
```

If the repository is not cloned:

```powershell
cd C:\Dev
git clone https://github.com/GinniNio/kasiro-brain.git
```

## 2. Run the read-only audit

```powershell
Set-ExecutionPolicy -Scope Process Bypass
cd C:\Dev\kasiro-brain\ops\local-cleanup
.\audit-workspace.ps1
```

The audit writes:

```text
C:\Dev\_workspace-audit\workspace-audit-<timestamp>.json
C:\Dev\_workspace-audit\artifact-duplicates-<timestamp>.csv
```

Review these before applying changes.

## 3. Preview cleanup actions

```powershell
.\cleanup-workspace.ps1
```

This prints intended actions and changes nothing.

## 4. Apply directory creation and legacy archiving

```powershell
.\cleanup-workspace.ps1 -Apply
```

This will:

- create the standard project directories under `C:\Dev`;
- archive known legacy Predicto, Prolego1, and Prolego2 Claude workspaces when present;
- write `C:\Dev\WORKSPACE_MANIFEST.local.yaml`;
- record every applied action.

It does not clone repositories or delete generated folders.

## 5. Remove reproducible build folders

Run this only after reviewing the audit:

```powershell
.\cleanup-workspace.ps1 -Apply -RemoveGeneratedFolders
```

Eligible folder names:

```text
node_modules
build
dist
.vite
coverage
.turbo
.next
out
```

These folders are reproducible from project dependencies and builds. The script does not remove source files, `.env` files, Git metadata, databases, uploads, or arbitrary temporary folders.

## Intended local structure

```text
C:\Dev\
├── Kasiro\
├── GbegeBall\
├── kasiro-brain\
├── kasiro-RSS\
├── gochat-dropz-private\
├── pcbf-brain\
├── WORKSPACE_MANIFEST.local.yaml
├── _workspace-audit\
└── _workspace-cleanup-logs\

C:\Archive\
└── workspace-cleanup-YYYY-MM-DD\
    ├── Predicto-legacy\
    ├── Prolego1-legacy\
    └── Prolego2-legacy\
```

## Repository cloning

After cleanup, clone only missing active repositories into their declared directories. Do not clone over a non-empty folder.

```powershell
git clone https://github.com/GinniNio/GbegeBall.git C:\Dev\GbegeBall
git clone https://github.com/GinniNio/kasiro-brain.git C:\Dev\kasiro-brain
git clone https://github.com/GinniNio/kasiro-RSS.git C:\Dev\kasiro-RSS
```

`GinniNio/Predicto` maps to `C:\Dev\Kasiro`.

The proposed `gochat-dropz-private` and `pcbf-brain` repositories must exist before cloning.

## Rollback

Moves can be reversed using the action log. For each completed `move` record, move the recorded destination back to its source after confirming the source path is free.

The script deliberately does not provide an automatic destructive rollback because a later user-created folder could occupy the old location. Manual confirmation prevents overwriting new data.
