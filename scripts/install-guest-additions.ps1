# Install VirtualBox Guest Additions to enable shared folders, clipboard sync, and better display support
Write-Host "Installing VirtualBox Guest Additions..."

# Poll for the Guest Additions ISO to finish mounting
$maxAttempts = 30
$sleepSeconds = 10
$attempt = 0
$guestAdditionsExe = $null

while ($attempt -lt $maxAttempts -and -not $guestAdditionsExe) {
    $candidateDrives = Get-PSDrive -PSProvider FileSystem | Where-Object {
        Test-Path "$($_.Root)VBoxWindowsAdditions.exe" -or
        Test-Path "$($_.Root)VBoxWindowsAdditions-amd64.exe"
    }

    if ($candidateDrives) {
        $drive = $candidateDrives[0].Root
        if (Test-Path "$drive\VBoxWindowsAdditions-amd64.exe") {
            $guestAdditionsExe = "$drive\VBoxWindowsAdditions-amd64.exe"
        } else {
            $guestAdditionsExe = "$drive\VBoxWindowsAdditions.exe"
        }
    } else {
        $attempt++
        Write-Host "Guest Additions ISO not mounted yet. Attempt $attempt of $maxAttempts. Waiting $sleepSeconds seconds..."
        Start-Sleep -Seconds $sleepSeconds
    }
}

if (-not $guestAdditionsExe) {
    throw "VirtualBox Guest Additions executable could not be located. Ensure guest_additions_mode is set to 'attach'."
}

Write-Host "Found Guest Additions installer at $guestAdditionsExe"

# Run the installer silently
$arguments = "/S"
$process = Start-Process -FilePath $guestAdditionsExe -ArgumentList $arguments -Wait -PassThru

if ($process.ExitCode -ne 0) {
    throw "Guest Additions installation failed with exit code $($process.ExitCode)"
}

Write-Host "VirtualBox Guest Additions installed successfully. A reboot will be performed by subsequent steps."
