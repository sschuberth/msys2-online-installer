@pushd %~dp0
@downloads\7z.exe x -so %1 | downloads\7z.exe x -o%2 -si -ttar -x!.INSTALL -x!.MTREE -x!.PKGINFO -y
@popd
