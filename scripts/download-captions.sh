#!/usr/bin/env bash
# A simple script that uses yt-dlp to download captions
# Usage: ./download-captions.sh [--locale=locale] <video-url>




# Formats: vtt/ttml/srv3/srv2/srv1/json3

yt-dlp --write-auto-sub --skip-download --sub-langs fr --sub-format srv1 --output "subtitles.%(ext)s" "$1"