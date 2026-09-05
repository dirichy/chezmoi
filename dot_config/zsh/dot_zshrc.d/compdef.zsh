comp_ext() {
  local cmd=$1
  local -a extensions=("${@:2}")
  local pattern="*.${(j:|:)extensions}"
  (( ${#extensions} > 1 )) && pattern="*.(${(j:|:)extensions})"

  compdef _files "$cmd"
  zstyle ":completion:*:*:${cmd}:*:*" \
    file-patterns "$pattern:${cmd}\ files" '*(-/):directories'
}

comp_ext sioyek pdf
comp_ext zathura pdf
comp_ext mpv mp4 mkv webm avi mov m4v flv mpg mpeg png jpg jpeg gif webp
comp_ext imv png jpg jpeg gif webp bmp avif tiff
