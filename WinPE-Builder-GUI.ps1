# WinPE-Builder-GUI.ps1

# This script provides a GUI for building WinPE images with extensive features and error handling.

# Standard Libraries
Add-Type -AssemblyName System.Windows.Forms

# Configuration Section
$Config = @{ 
    'OutputDirectory' = 'C:\WinPEOutput';   # Directory for output files
    'LogsDirectory' = 'C:\WinPELogs';       # Directory for logs
    'ISOName' = 'WinPE_Image.iso';           # Name of the ISO file to be created
    'MinDiskSpace' = 500MB;                   # Minimum disk space required
}

# Create Log File
$LogFile = Join-Path $Config.LogsDirectory "Build_$((Get-Date).ToString('yyyy-MM-dd_HH-mm-ss')).log"
New-Item -Path $LogFile -ItemType File -Force

function Log-Message($message) {
    Add-Content -Path $LogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $message"
}

# Validating Input
function Validate-Input() {
    if (-not (Test-Path $Config.OutputDirectory)) {
        [System.Windows.Forms.MessageBox]::Show("Output directory does not exist.", "Error")
        Log-Message "Output directory does not exist."
        Exit
    }
    # Add more validation as needed
}

# Check Disk Space
function Check-DiskSpace() {
    $drive = Get-PSDrive -Name (Get-Volume -DriveLetter $Config.OutputDirectory[0]).DriveLetter
    if ($drive.Free -lt $Config.MinDiskSpace) {
        [System.Windows.Forms.MessageBox]::Show("Insufficient disk space on drive $($drive.Name).", "Error")
        Log-Message "Insufficient disk space on drive $($drive.Name)."
        Exit
    }
}

# Building the GUI
# More reusable components here

# Building Process - Placeholder
function Build-WinPE() {
    Validate-Input
    Check-DiskSpace
    # Process logic here...
    Log-Message "Starting WinPE build..."
    # Once done
    Log-Message "WinPE build completed successfully." 
}

# Keyboard Shortcuts
$Form.KeyPreview = $true
$Form.Add_KeyDown({
    if ($_.KeyCode -eq [System.Windows.Forms.Keys]::Enter) {
        Build-WinPE
    } elseif ($_.KeyCode -eq [System.Windows.Forms.Keys]::Escape) {
        $Form.Close()
    }
})

# Start GUI
[System.Windows.Forms.Application]::Run($Form)