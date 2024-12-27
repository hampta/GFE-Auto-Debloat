# Description: This script will install the latest version of GeForce Experience and modify the hosts file to block telemetry.
Import-Module BitsTransfer

$TEMP_PATH = $env:TEMP

$ASCII_ART = @"

   __________________     ___         __              ____       __    __            __ 
  / ____/ ____/ ____/    /   | __  __/ /_____        / __ \___  / /_  / /___  ____ _/ /_
 / / __/ /_  / __/______/ /| |/ / / / __/ __ \______/ / / / _ \/ __ \/ / __ \/ __ `/ __/
/ /_/ / __/ / /__/_____/ ___ / /_/ / /_/ /_/ /_____/ /_/ /  __/ /_/ / / /_/ / /_/ / /_  
\____/_/   /_____/    /_/  |_\__,_/\__/\____/     /_____/\___/_.___/_/\____/\__,_/\__/  
                                                                                      
"@
Write-Host $ASCII_ART

# Get NVIDIA driver version
$nvidia_smi_process = New-Object System.Diagnostics.ProcessStartInfo
$nvidia_smi_process.FileName = "nvidia-smi"
$nvidia_smi_process.RedirectStandardOutput = $true
$nvidia_smi_process.UseShellExecute = $false
$nvidia_smi_process.CreateNoWindow = $true
$nvidia_smi_process.WindowStyle = "Hidden"
$nvidia_smi_process.Arguments = "--query-gpu=driver_version --format=csv,noheader --id=0"
$nvidia_smi = New-Object System.Diagnostics.Process
$nvidia_smi.StartInfo = $nvidia_smi_process
$nvidia_smi.Start() | Out-Null
$nvidia_smi.WaitForExit()
$nvidia_smi_output = $nvidia_smi.StandardOutput.ReadToEnd().Trim()
Write-Host "-----------------------------------------"
Write-Host "NVIDIA driver version: $nvidia_smi_output"
Write-Host "-----------------------------------------"

if ($nvidia_smi_output -ge "425.31") {
    $GEFORCE_EXPERIENCE_VERSION = "3.26.0.154"
    $APP_JS_DOWNLOAD_URL = "https://raw.githubusercontent.com/0x-FADED/GeForceExpLogin-Removal/master/app.js"
}
else {
    $GEFORCE_EXPERIENCE_VERSION = "3.18.0.94"
    $APP_JS_DOWNLOAD_URL = "https://github.com/AntiGuide/BaiGfe/raw/refs/heads/master/app.js"
}

$EXE_DOWNLOAD_URL = "https://us.download.nvidia.com/GFE/GFEClient/$GEFORCE_EXPERIENCE_VERSION/GeForce_Experience_v$GEFORCE_EXPERIENCE_VERSION.exe"

$answer = Read-Host "Do you want to use the LITE hosts blocklist? (recommended) (y/n)"

if ($answer -ne "y") {
    $HOSTS_FILE = "
    0.0.0.0 ls.dtrace.nvidia.com
    0.0.0.0 telemetry.gfe.nvidia.com
    0.0.0.0 accounts.nvgs.nvidia.com
    0.0.0.0 accounts.nvgs.nvidia.cn
    0.0.0.0 nvidia.tt.omtrdc.net
    0.0.0.0 api.commune.ly
    0.0.0.0 login.nvgs.nvidia.com
    0.0.0.0 login.nvgs.nvidia.cn
    "
}
else {
    $HOSTS_FILE = "
    0.0.0.0 telemetry.gfe.nvidia.com
    0.0.0.0 gfe.nvidia.com
    0.0.0.0 gfwsl.geforce.com
    0.0.0.0 services.gfe.nvidia.com
    0.0.0.0 accounts.nvgs.nvidia.com
    0.0.0.0 accounts.nvgs.nvidia.cn
    0.0.0.0 events.gfe.nvidia.com
    0.0.0.0 img.nvidiagrid.net
    0.0.0.0 images.nvidiagrid.net
    0.0.0.0 images.nvidia.com
    0.0.0.0 ls.dtrace.nvidia.com
    0.0.0.0 ota.nvidia.com
    0.0.0.0 ota-downloads.nvidia.com
    0.0.0.0 rds-assets.nvidia.com
    0.0.0.0 assets.nvidiagrid.net
    0.0.0.0 nvidia.tt.omtrdc.net
    0.0.0.0 api.commune.ly
    0.0.0.0 login.nvgs.nvidia.com
    0.0.0.0 login.nvgs.nvidia.cn
"
}

function Invoke-DownloadFile($url, $targetFile)
{
    Write-Host "Downloading $url"
    Start-BitsTransfer -Source $url -Destination $targetFile
}

function Install-GeForceExperience {
    Invoke-DownloadFile $EXE_DOWNLOAD_URL "$TEMP_PATH\GeForce_Experience_v$GEFORCE_EXPERIENCE_VERSION.exe"
    Start-Process -FilePath "$TEMP_PATH\GeForce_Experience_v$GEFORCE_EXPERIENCE_VERSION.exe" -ArgumentList "-s -i -noreboot -noeula" -Wait
}

function Invoke-ModifyHostsFile {

    Write-Host "Downloading app.js"
    Invoke-DownloadFile $APP_JS_DOWNLOAD_URL "$TEMP_PATH\app.js"

    Write-Host "Backing up hosts file"
    Copy-Item "C:\Windows\System32\drivers\etc\hosts" "C:\Windows\System32\drivers\etc\hosts.bak"

    Write-Host "Modifying hosts file"
    $hosts = Get-Content "C:\Windows\System32\drivers\etc\hosts"
    if ($hosts.Contains("0.0.0.0 ls.dtrace.nvidia.com")) {
        Write-Host "Hosts file already modified"
    } else {
        Add-Content "C:\Windows\System32\drivers\etc\hosts" $HOSTS_FILE
    }
}

function Invoke-PatchAppJs {
    Write-Host "Copying app.js"
    Copy-Item "C:\Program Files\NVIDIA Corporation\NVIDIA GeForce Experience\www\app.js" "C:\Program Files\NVIDIA Corporation\NVIDIA GeForce Experience\www\app.js.bak"
    Copy-Item "$TEMP_PATH\app.js" "C:\Program Files\NVIDIA Corporation\NVIDIA GeForce Experience\www\app.js"
}

$answer = Read-Host "Do you want to update/reinstall GeForce Experience? (y/n)"
if ($answer -eq "y") {
    Install-GeForceExperience
}
else{
    # Kill GeForce Experience
    Write-Host "Killing GeForce Experience"
    Stop-Process -Name "NVIDIA Share" -Force -ErrorAction SilentlyContinue
    Stop-Process -Name "NVIDIA Web Helper" -Force -ErrorAction SilentlyContinue
    Stop-Process -Name "NVIDIA GeForce Experience" -Force -ErrorAction SilentlyContinue
}

Invoke-PatchAppJs

Invoke-ModifyHostsFile

Write-Host "Flushing DNS"
ipconfig /flushdns

Write-Host "Opening GeForce Experience"
Start-Process -FilePath "C:\Program Files\NVIDIA Corporation\NVIDIA GeForce Experience\NVIDIA GeForce Experience.exe"

Write-Host "Done!"