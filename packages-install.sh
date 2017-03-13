#!/bin/bash

for p in /packages-*.txt; do
    pacman -S --needed --noconfirm - < $p
done
