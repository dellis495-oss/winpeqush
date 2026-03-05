[System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
[System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") | Out-Null

# ============================================================
# WinPE Builder GUI Application
# ============================================================

$script:selectedComponents = @()
$script:selectedDrive = ""
$script:buildLog = @()

function Add-LogEntry {
    param([string]$Message)
    $timestamp = Get-Date -Format "HH:mm:ss"
    $entry = "[$timestamp] $Message"
    $script:buildLog += $entry
    $logBox.AppendText($entry + "`r`n")
    $logBox.SelectionStart = $logBox.Text.Length
    $logBox.ScrollToCaret()
}

function Show-HelpDialog {
    param([string]$Topic)
    
    $helpWindow = New-Object System.Windows.Forms.Form
    $helpWindow.Text = "Help: $Topic"
    $helpWindow.Size = New-Object System.Drawing.Size(600, 400)
    $helpWindow.StartPosition = "CenterParent"
    
    $helpText = New-Object System.Windows.Forms.TextBox
    $helpText.Multiline = $true
    $helpText.ScrollBars = "Vertical"
    $helpText.ReadOnly = $true
    $helpText.Dock = "Fill"
    $helpText.Font = New-Object System.Drawing.Font("Courier New", 10)
    
    $content = switch($Topic) {
        "Drive_Selection" { @" 
DRIVE SELECTION HELP
====================

This dropdown allows you to select which USB drive to write the 
bootable WinPE image to.

IMPORTANT: Double-check that you've selected the correct drive!
This operation will ERASE and FORMAT the selected drive.

Prerequisites:
- USB drive must be at least 8GB
- USB drive will be completely wiped
- Ensure no important data is on the drive

The drive list shows all currently connected drives on your system.
"@ }
        "Components" { @"
OPTIONAL COMPONENTS HELP
========================

These are Windows PE Optional Components that add functionality
to your WinPE image.

Core Components (Recommended):
- WinPE-WMI: Windows Management Instrumentation support
- WinPE-StorageWMI: Storage and disk management via WMI
- WinPE-Scripting: VBScript and JavaScript support
- WinPE-NetFX: .NET Framework support
- WinPE-PowerShell: PowerShell scripting environment
- WinPE-DismCmdlets: DISM command-line tools
- WinPE-SecureStartup: Secure boot and startup features

Additional Components (Optional):
- WinPE-WDS-Tools: Windows Deployment Services tools
- WinPE-RNDIS: Remote Network Driver Interface Spec support
- WinPE-FMAPI: File Management API support

Installation Requirements:
- Windows ADK must be installed
- WinPE add-on must be installed
- All components must match your Windows version/build

Note: Some components have dependencies on others and must be 
installed in a specific order.
"@ }
        "Work_Directory" { @"
WORK DIRECTORY HELP
===================

The work directory is where the WinPE image will be built and 
prepared before being written to your USB drive.

Default Location: C:\WinPE

This directory will be created if it doesn't exist and will contain:
- media/: WinPE boot files
- mount/: Temporary mount point for the boot.wim image
- Other temporary files during the build process

The build process requires approximately 1-2GB of free disk space
on your C: drive (or wherever you specify the work directory).

NOTE: Any existing work directory will be removed and recreated
during the build process to ensure a clean build.
"@ }
        "Advanced_Options" { @"
ADVANCED OPTIONS HELP
===================== 

Architecture:
- amd64: For 64-bit systems (recommended)
- x86: For 32-bit systems (legacy)

Custom Apps/Scripts:
You can add custom applications or scripts to your WinPE image.
Place .exe, .bat, .ps1, or .cmd files in the "CustomApps" folder
in your work directory before building.

Custom startnet.cmd:
The startnet.cmd script runs when WinPE boots. By default it runs:
- wpeinit: Initializes network and services
You can customize this file after the build but before writing to USB.

Build Options:
- Verify Components: Checks all OC files before building
- Keep Work Directory: Preserves working files after build
- Verbose Logging: Detailed output during build process
"@ }
        "Build_Process" { @"
BUILD PROCESS HELP
==================

The build process follows these steps:

[1/7] Sanity Checks
Verifies that Windows ADK and WinPE components are installed

[2/7] Create Working Files
Copies base WinPE files to the work directory using copype

[3/7] Mount boot.wim
Mounts the Windows PE boot image for modification

[4/7] Add Optional Components
Installs selected Optional Components (OCs) into the image

[5/7] Configure Startup
Sets up startnet.cmd for network initialization

[6/7] Commit and Unmount
Saves changes to boot.wim and unmounts the image

[7/7] Write to USB
Creates a bootable USB drive using MakeWinPEMedia

Total time: 5-15 minutes depending on components selected

If any step fails, the process will stop and log the error.
Check the log output for troubleshooting information.
"@ }
        default { "No help available for this topic." }
    }
    
    $helpText.Text = $content
    $helpWindow.Controls.Add($helpText)
    $helpWindow.ShowDialog()
}

# Create main form
$form = New-Object System.Windows.Forms.Form
$form.Text = "WinPE Builder - GUI Edition"
$form.Size = New-Object System.Drawing.Size(900, 700)
$form.StartPosition = "CenterScreen"
$form.Font = New-Object System.Drawing.Font("Segoe UI", 10)

# ============================================================
# Tab Control
# ============================================================
$tabControl = New-Object System.Windows.Forms.TabControl
$tabControl.Dock = "Fill"

# Tab 1: Basic Settings
$tabBasic = New-Object System.Windows.Forms.TabPage
$tabBasic.Text = "Basic Settings"

$driveLabel = New-Object System.Windows.Forms.Label
$driveLabel.Text = "Target USB Drive:"
$driveLabel.Location = New-Object System.Drawing.Point(20, 20)
$driveLabel.Size = New-Object System.Drawing.Size(150, 25)
$tabBasic.Controls.Add($driveLabel)

$driveDropdown = New-Object System.Windows.Forms.ComboBox
$driveDropdown.Location = New-Object System.Drawing.Point(180, 20)
$driveDropdown.Size = New-Object System.Drawing.Size(150, 25)
$driveDropdown.DropDownStyle = "DropDownList"
Get-Volume | ForEach-Object { $driveDropdown.Items.Add($_.DriveLetter + ":") } | Out-Null
$tabBasic.Controls.Add($driveDropdown)

$driveHelpBtn = New-Object System.Windows.Forms.Button
$driveHelpBtn.Text = "?"
$driveHelpBtn.Location = New-Object System.Drawing.Point(340, 20)
$driveHelpBtn.Size = New-Object System.Drawing.Size(30, 25)
$driveHelpBtn.Add_Click({ Show-HelpDialog "Drive_Selection" })
$tabBasic.Controls.Add($driveHelpBtn)

$workDirLabel = New-Object System.Windows.Forms.Label
$workDirLabel.Text = "Work Directory:"
$workDirLabel.Location = New-Object System.Drawing.Point(20, 60)
$workDirLabel.Size = New-Object System.Drawing.Size(150, 25)
$tabBasic.Controls.Add($workDirLabel)

$workDirBox = New-Object System.Windows.Forms.TextBox
$workDirBox.Text = "C:\WinPE"
$workDirBox.Location = New-Object System.Drawing.Point(180, 60)
$workDirBox.Size = New-Object System.Drawing.Size(150, 25)
$tabBasic.Controls.Add($workDirBox)

$workDirHelpBtn = New-Object System.Windows.Forms.Button
$workDirHelpBtn.Text = "?"
$workDirHelpBtn.Location = New-Object System.Drawing.Point(340, 60)
$workDirHelpBtn.Size = New-Object System.Drawing.Size(30, 25)
$workDirHelpBtn.Add_Click({ Show-HelpDialog "Work_Directory" })
$tabBasic.Controls.Add($workDirHelpBtn)

$tabControl.TabPages.Add($tabBasic)

# Tab 2: Components
$tabComponents = New-Object System.Windows.Forms.TabPage
$tabComponents.Text = "Components"

$compLabel = New-Object System.Windows.Forms.Label
$compLabel.Text = "Select Optional Components:"
$compLabel.Location = New-Object System.Drawing.Point(20, 20)
$compLabel.Size = New-Object System.Drawing.Size(200, 25)
$tabComponents.Controls.Add($compLabel)

$compHelpBtn = New-Object System.Windows.Forms.Button
$compHelpBtn.Text = "Help"
$compHelpBtn.Location = New-Object System.Drawing.Point(220, 20)
$compHelpBtn.Size = New-Object System.Drawing.Size(60, 25)
$compHelpBtn.Add_Click({ Show-HelpDialog "Components" })
$tabComponents.Controls.Add($compHelpBtn)

$componentList = New-Object System.Windows.Forms.CheckedListBox
$componentList.Location = New-Object System.Drawing.Point(20, 55)
$componentList.Size = New-Object System.Drawing.Size(700, 300)
$componentList.CheckOnClick = $true
$componentList.Items.AddRange(@(
    "WinPE-WMI",
    "WinPE-StorageWMI",
    "WinPE-Scripting",
    "WinPE-NetFX",
    "WinPE-PowerShell",
    "WinPE-DismCmdlets",
    "WinPE-SecureStartup"
))

# Check default components
$componentList.SetItemChecked(0, $true)
$componentList.SetItemChecked(1, $true)
$componentList.SetItemChecked(2, $true)
$componentList.SetItemChecked(3, $true)
$componentList.SetItemChecked(4, $true)
$componentList.SetItemChecked(5, $true)
$componentList.SetItemChecked(6, $true)

$tabComponents.Controls.Add($componentList)

$tabControl.TabPages.Add($tabComponents)

# Tab 3: Advanced
$tabAdvanced = New-Object System.Windows.Forms.TabPage
$tabAdvanced.Text = "Advanced"

$advHelpBtn = New-Object System.Windows.Forms.Button
$advHelpBtn.Text = "Advanced Help"
$advHelpBtn.Location = New-Object System.Drawing.Point(20, 20)
$advHelpBtn.Size = New-Object System.Drawing.Size(100, 25)
$advHelpBtn.Add_Click({ Show-HelpDialog "Advanced_Options" })
$tabAdvanced.Controls.Add($advHelpBtn)

$verifyCheckbox = New-Object System.Windows.Forms.CheckBox
$verifyCheckbox.Text = "Verify Components Before Build"
$verifyCheckbox.Location = New-Object System.Drawing.Point(20, 60)
$verifyCheckbox.Size = New-Object System.Drawing.Size(250, 25)
$verifyCheckbox.Checked = $true
$tabAdvanced.Controls.Add($verifyCheckbox)

$keepDirCheckbox = New-Object System.Windows.Forms.CheckBox
$keepDirCheckbox.Text = "Keep Work Directory After Build"
$keepDirCheckbox.Location = New-Object System.Drawing.Point(20, 90)
$keepDirCheckbox.Size = New-Object System.Drawing.Size(250, 25)
$tabAdvanced.Controls.Add($keepDirCheckbox)

$verboseCheckbox = New-Object System.Windows.Forms.CheckBox
$verboseCheckbox.Text = "Verbose Logging"
$verboseCheckbox.Location = New-Object System.Drawing.Point(20, 120)
$verboseCheckbox.Size = New-Object System.Drawing.Size(250, 25)
$verboseCheckbox.Checked = $true
$tabAdvanced.Controls.Add($verboseCheckbox)

$tabControl.TabPages.Add($tabAdvanced)

# Tab 4: Log
$tabLog = New-Object System.Windows.Forms.TabPage
$tabLog.Text = "Build Log"

$logBox = New-Object System.Windows.Forms.TextBox
$logBox.Multiline = $true
$logBox.ScrollBars = "Vertical"
$logBox.ReadOnly = $true
$logBox.Dock = "Fill"
$logBox.Font = New-Object System.Drawing.Font("Courier New", 9)
$tabLog.Controls.Add($logBox)

$tabControl.TabPages.Add($tabLog)

$form.Controls.Add($tabControl)

# ============================================================
# Bottom Button Panel
# ============================================================
$buttonPanel = New-Object System.Windows.Forms.Panel
$buttonPanel.Dock = "Bottom"
$buttonPanel.Height = 60
$buttonPanel.BackColor = [System.Drawing.Color]::LightGray

$startButton = New-Object System.Windows.Forms.Button
$startButton.Text = "Start Build"
$startButton.Location = New-Object System.Drawing.Point(700, 15)
$startButton.Size = New-Object System.Drawing.Size(100, 30)
$startButton.BackColor = [System.Drawing.Color]::Green
$startButton.ForeColor = [System.Drawing.Color]::White
$startButton.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)

$startButton.Add_Click({
    $tabControl.SelectedIndex = 3
    Add-LogEntry "=== WinPE Build Started ==="
    Add-LogEntry "Selected Drive: $($driveDropdown.SelectedItem)"
    Add-LogEntry "Work Directory: $($workDirBox.Text)"
    Add-LogEntry "Selected Components: $(($componentList.CheckedItems | ForEach-Object { $_.ToString() }) -join ', ')"
    Add-LogEntry "Verify Components: $($verifyCheckbox.Checked)"
    Add-LogEntry "Keep Work Dir: $($keepDirCheckbox.Checked)"
    Add-LogEntry "Verbose: $($verboseCheckbox.Checked)"
    
    # Call actual build script here with parameters
    Add-LogEntry "Starting build process..."
    Add-LogEntry "This will take 5-15 minutes..."
})

$buttonPanel.Controls.Add($startButton)

$exitButton = New-Object System.Windows.Forms.Button
$exitButton.Text = "Exit"
$exitButton.Location = New-Object System.Drawing.Point(810, 15)
$exitButton.Size = New-Object System.Drawing.Size(80, 30)

$exitButton.Add_Click({
    $form.Close()
})

$buttonPanel.Controls.Add($exitButton)

$form.Controls.Add($buttonPanel)

# Show form
$form.ShowDialog() | Out-Null