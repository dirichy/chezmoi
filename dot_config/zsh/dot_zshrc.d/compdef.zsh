comp_ext() {
  local cmd="$1"
  shift
  local pattern
  if [[ -z $2 ]]; then
    pattern="*.${(j:|:)@}"
  else
    pattern="*.(${(j:|:)@})"
  fi

  local func="_comp_ext_${cmd}"
  functions[$func]="
    _arguments '*:file:_files -g \"$pattern\"'
  "
  compdef $func $cmd
}
comp_ext sioyek pdf
comp_ext mpv mp4 png jpg
