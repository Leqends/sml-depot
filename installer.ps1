param (
    [Parameter()]
    [string]$Action = (Read-Host -Prompt 'Select an action: 1 to Install, 2 to Uninstall')
)

# Function to find the game directory from the registry
function Find-GameDirFromRegistry {
    Write-Host "Searching for game directory in the registry..."
    try {
        $gameDir = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Steam App 2325290" -ErrorAction SilentlyContinue).InstallLocation
        if (-Not (Test-Path $gameDir)) {
            return $null
        }
    } catch {
        return $null
    }
    return $gameDir
}

# Function to find the game directory from the running process
function Find-GameDirFromProcess {
    Write-Host "Game directory not found in the registry."
    $launchGame = Read-Host -Prompt "Would you like to launch Sky to determine the directory? (Y/N)"
    if ($launchGame -eq 'Y') {
        Write-Host "Launching Sky via Steam..."
        Start-Process -FilePath "steam://rungameid/2325290"
        Write-Host "Waiting for the game to start..."
    }

    $maxAttempts = 30
    $attempt = 0
    $gameRunning = $false

    while ($attempt -lt $maxAttempts -and -not $gameRunning) {
        try {
            $process = Get-Process -Name "Sky" -ErrorAction SilentlyContinue
            if ($null -ne $process) {
                $gameRunning = $true
                break
            }
        } catch {
            Write-Host "Error accessing game process."
            Pause
            exit 1
        }
        
        Write-Host "Game not detected, retrying in 5 seconds..."
        Start-Sleep -Seconds 5
        $attempt++
    }

    if (-not $gameRunning) {
        Write-Host "Game process not found after multiple attempts. Exiting script."
        Pause
        exit 1
    }

    $gameDir = $process.Path
    Stop-Process -Name "Sky"
    return $gameDir
}


# Function to download and extract files
function Download-And-Extract {
    param (
        [string]$url,
        [string]$destinationPath,
        [string]$extractTo
    )

    Write-Host "Downloading $url ..."
    try {
        Invoke-WebRequest -Uri $url -OutFile $destinationPath
    } catch {
        Write-Host "Failed to download $url"
        Pause
        exit 1
    }

    Write-Host "Extracting $destinationPath ..."
    try {
        Expand-Archive -Path $destinationPath -DestinationPath $extractTo -Force
    } catch {
        Write-Host "Failed to extract $destinationPath"
        Pause
        exit 1
    }
}

# Function to clean up downloaded files
function Clean-Up {
    param (
        [string[]]$files
    )

    Write-Host "Cleaning up..."
    foreach ($file in $files) {
        Remove-Item $file -ErrorAction SilentlyContinue
    }
    Write-Host "Cleanup complete."
}

# Function to install SML
function Install-SML {
    $URL = "https://github.com/lukas0x1/sml-pc/releases/latest/download/sml-pc.zip"
    $DOWNLOAD_PATH = "$env:USERPROFILE\Downloads\sml-pc.zip"

    Download-And-Extract -url $URL -destinationPath $DOWNLOAD_PATH -extractTo $gameDir
    Clean-Up -files @($DOWNLOAD_PATH)

    Write-Host "SML installation successful."
}

# Function to install TSM
function Install-TSM {
    $MODS_URL = "https://github.com/TheSR007/That_Sky_Mod_Release/releases/latest/download/TSM.zip"
    $MODS_DOWNLOAD_PATH = "$env:USERPROFILE\Downloads\TSM.zip"

    Download-And-Extract -url $MODS_URL -destinationPath $MODS_DOWNLOAD_PATH -extractTo $gameDir
    Clean-Up -files @($MODS_DOWNLOAD_PATH)

    Write-Host "TSM installation successful."
}

# Function to uninstall mods
function Uninstall-Mods {
    Remove-Item "$gameDir\mods\TSM_PC.dll" -ErrorAction SilentlyContinue
    $removeSML = Read-Host "Do you want to uninstall SML (powrprof.dll and sml_config.json)? (y/n)"
    if ($removeSML -eq 'y') {
        Remove-Item "$gameDir\powrprof.dll" -ErrorAction SilentlyContinue
        Remove-Item "$gameDir\sml_config.json" -ErrorAction SilentlyContinue
        Write-Host "SML files removed."
    } else {
        Write-Host "SML not uninstalled."
    }

    $removeTSM = Read-Host "Do you want to remove TSM Resources? (y/n)"
    if ($removeTSM -eq 'y') {
        Remove-Item "$gameDir\mods\TSM Resources" -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "TSM Resources removed."
    } else {
        Write-Host "TSM Resources not removed."
    }
    Pause
}

# Main script
$gameDir = Find-GameDirFromRegistry

if (-not $gameDir) {
    Write-Host "Game directory not found in the registry."
    $gameDir = Find-GameDirFromProcess
}

if (-not $gameDir) {
    Write-Host "Game directory could not be determined. Exiting script."
    Pause
    exit 1
}

Write-Host "Game directory found at: $gameDir"

switch ($Action) {
    '1' {
        Install-SML
        $installTSM = Read-Host "Do you want to install TSM? (y/n)"
        if ($installTSM -eq 'y') {
            Install-TSM
        } else {
            Write-Host "TSM not installed."
        }
        Write-Host "Starting Sky, enjoy the mods ;)"
        Start-Process -FilePath "steam://rungameid/2325290"
        Pause
    }
    '2' {
        Uninstall-Mods
    }
    default {
        Write-Host "Invalid action selected. Exiting script."
        Pause
        exit 1
    }
}
