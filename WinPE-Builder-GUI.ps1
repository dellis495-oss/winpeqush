# PowerShell WinForms GUI for WinPE Builder

# Load .NET WinForms assembly
Add-Type -AssemblyName System.Windows.Forms

# Create the form
$form = New-Object System.Windows.Forms.Form
$form.Text = 'WinPE Builder GUI'
$form.Size = New-Object System.Drawing.Size(400,300)
$form.StartPosition = 'CenterScreen'

# Drive selection
$driveLabel = New-Object System.Windows.Forms.Label
$driveLabel.Text = 'Select Drive:'
$driveLabel.Location = New-Object System.Drawing.Point(10,20)
$form.Controls.Add($driveLabel)

$driveDropdown = New-Object System.Windows.Forms.ComboBox
$driveDropdown.Location = New-Object System.Drawing.Point(10,40)
$driveDropdown.Width = 360
$driveDropdown.Items.AddRange([System.IO.DriveInfo]::GetDrives() | ForEach-Object { $_.Name })
$form.Controls.Add($driveDropdown)

# Component selection
$componentLabel = New-Object System.Windows.Forms.Label
$componentLabel.Text = 'Select Components:'
$componentLabel.Location = New-Object System.Drawing.Point(10,80)
$form.Controls.Add($componentLabel)

$componentList = New-Object System.Windows.Forms.CheckedListBox
$componentList.Location = New-Object System.Drawing.Point(10,100)
$componentList.Size = New-Object System.Drawing.Size(360,100)
$componentList.Items.AddRange(@('Component A', 'Component B', 'Component C'))
$form.Controls.Add($componentList)

# Progress tracking
$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Location = New-Object System.Drawing.Point(10,210)
$progressBar.Size = New-Object System.Drawing.Size(360,20)
$form.Controls.Add($progressBar)

# Start Button
$startButton = New-Object System.Windows.Forms.Button
$startButton.Text = 'Start'
$startButton.Location = New-Object System.Drawing.Point(280,240)
$form.Controls.Add($startButton)

# Log
$logOutput = New-Object System.Windows.Forms.TextBox
$logOutput.Multiline = $true
$logOutput.ScrollBars = 'Vertical'
$logOutput.Location = New-Object System.Drawing.Point(10,240)
$logOutput.Size = New-Object System.Drawing.Size(250,50)
$form.Controls.Add($logOutput)

# Function to start process
$startButton.Add_Click({
    # Clear log
    $logOutput.Clear()
    $progressBar.Value = 0
    $selectedDrive = $driveDropdown.SelectedItem
    $selectedComponents = $componentList.CheckedItems | ForEach-Object { $_.ToString() }
    
    # Here you would run your script logic, e.g., using the received selections
    # For the sake of example, we will simulate progress:
    foreach ($i in 1..100) {
        Start-Sleep -Milliseconds 50
        $progressBar.Value = $i
        $logOutput.AppendText("Progress: $i%`r")
    }
    $logOutput.AppendText('Process completed!`r')
})

# Show form
$form.Add_Shown({$form.Activate()})
[Void] $form.ShowDialog()