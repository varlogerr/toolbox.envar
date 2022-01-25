__envar.append() {
  local keep="${1}"
  shift

  while [[ -n "${1+x}" ]]; do
    [[ (-n "${keep}" && -n "${1}") ]] && keep+=$'\n'
    keep+="${1}"; shift
  done

  echo "${keep}"
}

__envar.uniq() {
  [[ -z "${1}" ]] && return

  # uniq without sorting, grabbed from here:
  # https://unix.stackexchange.com/questions/194780/remove-duplicate-lines-while-keeping-the-order-of-the-lines
  cat -n <<< "${1}" | sort -k2 -k1n \
  | uniq -f1 | sort -nk1,1 | cut -f2-
}

__envar.append_uniq() {
  __envar.uniq "$(__envar.append "${@}")"
}

__envar.gen_pathfile() {
  [[ ${1} -ne 1 ]] && return 1

  local assetsdir="$(
    dirname "${BASH_SOURCE[0]}"
  )/../assets"

  grep -vFx '' "${assetsdir}/pathfile.envar" \
  | sed 's/^/# /g'
  return 0
}
