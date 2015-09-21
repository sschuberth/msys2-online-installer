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
        Write-Host "Using cached feed for $project."
        $feed = [xml](Get-Content $file)
    }

    $item = $feed.rss.channel.item | Where-Object { $_.title.InnerText -CMatch $pattern } | Select-Object -First 1
    return $item.link, [System.IO.Path]::GetFileName($item.title.InnerText)
}

function DownloadIfNotExists($url, $file) {
    if (!(Test-Path $file)) {
        # Use a fake UserAgent to make the SourceForge redirection work.
        Invoke-WebRequest $url -OutFile $file -UserAgent [Microsoft.PowerShell.Commands.PSUserAgent]::FireFox -Verbose
    } else {
        Write-Host "Skipping download, $([System.IO.Path]::GetFileName($file)) already exists."
    }

    return $file
}

function DownloadMSYS2Package($package) {
    $pattern = "$package-[0-9\.]+-[0-9]+-$arch\.pkg\.tar\.xz$"
    $release = GetLatestRelease 'msys2' "/REPOS/MSYS2/$arch" $pattern 5000
    return DownloadIfNotExists $release[0] ($PSScriptRoot + '\downloads\' + $release[1])
}

function ExtractMSYS2Package($file) {
    & "$PSScriptRoot\7z-extract-tar.cmd" $file "$PSScriptRoot\downloads\root"
}

# Download 7-Zip and extract 7z.exe for unpacking *.tar.xz archives.
$pattern = @('7z[0-9]+\.exe$', '7z[0-9]+-x64\.exe$')[$is_64bit]
$release = GetLatestRelease 'sevenzip' '/7-Zip' $pattern
$7zip = DownloadIfNotExists $release[0] ($PSScriptRoot + '\downloads\' + $release[1])

# Wait until the installer has finished to copy the required files.
Start-Process -FilePath "$7zip" -ArgumentList /D="$PSScriptRoot\downloads\7z-tmp",/S -Wait
Copy-Item "$PSScriptRoot\downloads\7z-tmp\7z.*" "$PSScriptRoot\downloads"

& "$PSScriptRoot\downloads\7z-tmp\Uninstall.exe" /S

# Download pacman and its dependencies (as determined by 'pactree -u pacman').
$packages = Get-Content "$PSScriptRoot\pacman-dependencies.txt"

foreach ($package in $packages) {
    $file = DownloadMSYS2Package $package
    ExtractMSYS2Package $file
}
