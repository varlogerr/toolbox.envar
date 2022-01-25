__envar.path.abs() {
  while read -r p; do
    [[ -n "${p}" ]] && realpath -qms -- "${p}"
  done <<< "${1}"
}

__envar.path.real() {
  while read -r p; do
    [[ -z "${p}" ]] && continue
    [[ -d "${p}" || -f "${p}" ]] && echo "${p}"
  done <<< "${1}"
}

__envar.path.envs_files() {
  local file
  while read -r env; do
    [[ -z "${env}" ]] && continue

    [[ -f "${env}" ]] && file="${env}" \
      || file="$(find -L "${env}" -readable -type f -name '*.sh' \
                 -or -name '*.env' -or -name '*.bash' | sort -n)"

    echo "${file}"
  done <<< "${1}"
}
