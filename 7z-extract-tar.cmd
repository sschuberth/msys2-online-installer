@echo off

rem This script extracts an MSYS2-style "*.pkg.tar.*" package file to the given directory.

pushd %~dp0
downloads\7z.exe x -so %1 | downloads\7z.exe x -o%2 -si -ttar -x!.INSTALL -x!.MTREE -x!.PKGINFO -y > nul
popd
