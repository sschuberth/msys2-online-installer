# This script creates a minimal MSYS2 "root file system" that contains just enough to run pacman
# in order to use it to install more packages later.

$is_64bit = (Get-WMIObject Win32_OperatingSystem).OSArchitecture.equals('64-bit')
$arch = @('i686', 'x86_64')[$is_64bit]

# Returns the URL and file name to the latest matching release as announced in the RSS feed.
function GetLatestRelease($project, $path, $pattern, $limit = 200) {
    # Generate a cache file name to save the feed to.
    $file = [string]($project + $path)
    foreach ($invalid in [System.IO.Path]::GetInvalidFileNameChars()) {
        $file = $file.replace($invalid, '-')
    }
    $file = "$PSScriptRoot\downloads\feed-$file.xml"

    if (!(Test-Path $file) -or ((Get-Date) - (Get-Item $file).LastWriteTime) -gt (New-TimeSpan -Days 1)) {
        $url = "http://sourceforge.net/projects/$project/rss?path=$path&limit=$limit"
        $feed = [xml](Invoke-WebRequest $url)
        $feed.save($file)
    } else {
        Write-Host "Using cached $project feed to look for pattern '$pattern'."
        $feed = [xml](Get-Content $file)
    }

    $item = $feed.rss.channel.item | Where-Object { $_.title.InnerText -CMatch $pattern } | Select-Object -First 1
    if ($item) {
        return $item.link, [System.IO.Path]::GetFileName($item.title.InnerText)
    } else {
        return $null
    }
}

# Downloads the file from the given URL if it does not yet exist locally.
function DownloadIfNotExists($url, $file) {
    if (!(Test-Path $file)) {
        try {
            # Use a fake UserAgent to make the SourceForge redirection work.
            Invoke-WebRequest $url -OutFile $file -UserAgent [Microsoft.PowerShell.Commands.PSUserAgent]::FireFox -Verbose
        } catch {
            return $null
        }
    } else {
        Write-Host "Skipping download, $([System.IO.Path]::GetFileName($file)) already exists."
    }

    return $file
}

# Determines the URL for the given package and downloads it.
function DownloadMSYS2Package($package) {
    $pattern = "[.*/^]$package-r?[0-9\.a-z]+-[0-9]+-($arch|any)\.pkg\.tar\.xz$"
    $release = GetLatestRelease 'msys2' "/REPOS/MSYS2/$arch" $pattern 5000
    if ($release) {
        # Try to download from the faster repo.msys2.org server first, and only use SourceForge as the fallback.
        $file = DownloadIfNotExists "http://repo.msys2.org/msys/$arch/$($release[1])" ($PSScriptRoot + '\downloads\' + $release[1])
        if (!$file) {
            $file = DownloadIfNotExists $release[0] ($PSScriptRoot + '\downloads\' + $release[1])
        }
        return $file
    }

    return $null
}

function ExtractMSYS2Package($file) {
    Write-Host "Extracting package $([System.IO.Path]::GetFileName($file))..."
    & "$PSScriptRoot\7z-extract-tar.cmd" $file "$PSScriptRoot\downloads\root"
}

# Download 7-Zip and extract 7z.exe for unpacking *.tar.xz archives.
$pattern = @('[.*/^]7z[0-9]+\.exe$', '[.*/^]7z[0-9]+-x64\.exe$')[$is_64bit]
$release = GetLatestRelease 'sevenzip' '/7-Zip' $pattern
$7zip = DownloadIfNotExists $release[0] ($PSScriptRoot + '\downloads\' + $release[1])
if (!$7zip) {
    Write-Error "Downloading 7-Zip failed."
    exit 1
}

# Wait until the 7-Zip installer has finished to extract the required files, copy them
# and clean up afterwards.
Start-Process -FilePath "$7zip" -ArgumentList /D="$PSScriptRoot\downloads\7z-tmp",/S -Wait
Copy-Item "$PSScriptRoot\downloads\7z-tmp\7z.*" "$PSScriptRoot\downloads"

& "$PSScriptRoot\downloads\7z-tmp\Uninstall.exe" /S

# Download core packages and their dependencies (as determined by 'pactree -u <package> | sort').
$packages = Get-Content "$PSScriptRoot\dependencies-*.txt" | Sort-Object -Unique

foreach ($package in $packages) {
    $file = DownloadMSYS2Package $package
    if ($file) {
        ExtractMSYS2Package $file
    } else {
        Write-Error "Downloading the '$package' package failed."
    }
}
