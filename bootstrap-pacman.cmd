@echo off

pushd downloads\root

usr\bin\bash --login -c '/usr/bin/pacman-key --init'
usr\bin\bash --login -c '/usr/bin/pacman -Syu'
usr\bin\bash --login -c '/usr/bin/pacman -Su'

popd
