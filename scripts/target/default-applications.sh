#!/usr/bin/env bash

# Browser
xdg-settings set default-web-browser google-chrome.desktop

# File manager
xdg-mime default spacefm.desktop inode/directory

# PDF
xdg-mime default evince.desktop application/pdf

# Image viewer
xdg-mime default gpicview.desktop image/jpeg
xdg-mime default gpicview.desktop image/gif
xdg-mime default gpicview.desktop image/png
xdg-mime default gpicview.desktop image/svg+xml
xdg-mime default gpicview.desktop image/tiff
