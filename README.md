# Windows Repair Tool

A small, auditable PowerShell wrapper around Windows' built-in repair tools:

- **DISM** repairs the Windows component store and can retrieve official replacement content through Windows Update.
- **SFC** verifies and repairs protected Windows system files.
- **CHKDSK** performs an online scan of the system filesystem.

The project installs no services, includes no telemetry, and downloads no third-party executables.

## Requirements

- Windows 10 or Windows 11
- Windows PowerShell 5.1 or PowerShell 7+
- An elevated Administrator session
- Internet access when DISM needs replacement content from Windows Update

## Run

Open PowerShell as Administrator, change to the cloned repository, and run:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\Invoke-WindowsRepair.ps1
```

Logs and machine-readable JSON results are written to:

```text
C:\ProgramData\WindowsRepairTool
```

Use a different output directory:

```powershell
.\Invoke-WindowsRepair.ps1 -OutputDirectory C:\RepairLogs
```

Skip individual checks when embedding the tool in another workflow:

```powershell
.\Invoke-WindowsRepair.ps1 -SkipChkdsk
.\Invoke-WindowsRepair.ps1 -SkipDism -SkipSfc
```

## Application integration

Run the script from an already elevated application process and inspect its exit code. Exit code `0` means every selected command returned success; exit code `1` means at least one selected check failed.

Example from .NET:

```csharp
using System.Diagnostics;

var process = Process.Start(new ProcessStartInfo
{
    FileName = "powershell.exe",
    Arguments = "-NoProfile -ExecutionPolicy Bypass -File Invoke-WindowsRepair.ps1 -SkipChkdsk",
    UseShellExecute = false,
    CreateNoWindow = true,
});

process!.WaitForExit();
Console.WriteLine($"Repair exit code: {process.ExitCode}");
```

For a desktop application that is not already elevated, request elevation through the operating system before running the script. Do not attempt to bypass UAC.

## Notes

- DISM and SFC can take a long time. Do not terminate them while Windows servicing is active.
- CHKDSK `/scan` is an online, read-compatible scan and normally does not require a restart.
- A successful CHKDSK scan does not replace hardware diagnostics when an SSD reports SMART or controller errors.
- Review the generated transcript and JSON result before deciding whether a restart or further repair is needed.

## License

MIT
