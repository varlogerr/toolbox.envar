__iife() {
  unset __iife

  local toolname=envar
  local src_file="${BASH_SOURCE[0]}"
  local funcdir="$(dirname "$(realpath "${src_file}")")/func"

  # detect all function definitions
  {
    local func_re='^\s*(function\s+)?(__)?'${toolname}'\.[_\-0-9a-z\.]+\s*\(.*\)'
    local funcs="$(grep -Phio "${func_re}" "${funcdir}/${toolname}"*.sh \
      | sed -E 's/^[[:space:]]*(function[[:space:]]+)?//g' \
      | sed -E 's/[[:space:]]*\(.*\)[[:space:]]*$//g')"
  }

  local unknown_funcs="$( while read -r f; do
    [[ -z "${f}" ]] && continue
    [[ "$(type -t ${f})" != 'function' ]] && echo "${f}"
  done <<< "${funcs}" )"

  [[ -n "${unknown_funcs}" ]] && {
    while read -r f; do
      [[ -n "${f}" ]] && . "${f}"
    done <<< "$(
      find "${funcdir}" -mindepth 1 -maxdepth 1 \
      -name "${toolname}*.sh" -type f
    )"

    while read -r f; do
      [[ -n "${f}" ]] && export -f "${f}"
    done <<< "${unknown_funcs}"
  }

  # export basic dirs
  __ENVAR_TOOL_ROOTDIR="$(realpath "$(dirname "${src_file}")/..")"
  __ENVAR_TOOL_LIBDIR="${__ENVAR_TOOL_ROOTDIR}/lib"
  for var in \
    __ENVAR_TOOL_ROOTDIR \
    __ENVAR_TOOL_LIBDIR \
  ; do
    [[ -z "$(bash -c 'echo ${'${var}'+x}')" ]] \
      && export "${var}"
  done

  __envar.bootstrap
} && __iife
