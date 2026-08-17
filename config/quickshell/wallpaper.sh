#!/bin/bash
pgrep -f "WallpaperPicker.qml" && exit 0
UNIT3_WALLPAPER_FAST=1 QT_MEDIA_BACKEND=ffmpeg qs -p ~/.config/quickshell/widgets/WallpaperPicker.qml
