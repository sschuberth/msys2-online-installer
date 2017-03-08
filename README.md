# MSYS2 Online Installer

The default [installer](https://github.com/msys2/msys2-installer) for [MSYS2](http://www.msys2.org/) is quite large (~70 MiB) as it bundles a lot of packages that you might or might not need.

On the other hand, there are installers for customized MSYS2 environments like the [Git for Windows SDK](https://github.com/git-for-windows/build-extra/releases/latest) or the [RubyInstaller2](https://github.com/larskanis/rubyinstaller2/releases/latest) that install packages at the time the installer is run by executing `pacman`.

The MSYS2 Online Installer project follows the approach of the latter two, but is more generic by only bundling the very minimum to be able to run `pacman`, and then allowing to install sets of packages by chosing from presets.
