[Setup]
AppName=MSYS2 Online Installer
AppVersion=1.0
SourceDir=Downloads\root
DefaultDirName=C:\msys2
Compression=lzma2/ultra
SolidCompression=yes
OutputDir=..\..
OutputBaseFilename=msys2-installer

[Dirs]
Name: "{app}\tmp"

[Files]
Source: "*"; Excludes: "*.gz"; DestDir: "{app}"; Flags: recursesubdirs ignoreversion onlyifdoesntexist sortfilesbyextension
Source: "*.gz"; DestDir: "{app}"; Flags: recursesubdirs ignoreversion onlyifdoesntexist nocompression

Source: "..\..\packages-*.*"; DestDir: "{app}"; Flags: deleteafterinstall

[Run]
Filename: "{app}\usr\bin\bash.exe"; Parameters: "-l /packages-install.sh"; WorkingDir: "{app}"

[UninstallDelete]
Type: filesandordirs; Name: "{app}\tmp"
