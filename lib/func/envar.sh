##########
# This env vars are set from main.sh
# * __ENVAR_TOOL_ROOTDIR - envar tool root directory
# * __ENVAR_TOOL_LIBDIR - envar lib directory
#
# * __ENVAR_HASHMAP_PATHS - path hash to env path map
# * __ENVAR_REQUESTED_ENVS - requested env paths hashes
# * __ENVAR_REAL_ENVS - existing requested env paths hashes
#
# * __ENVAR_SESSION_FILES - current session env files hashes
# * __ENVAR_FILES - all sessions env files hashes
# * __ENVAR_LOADED_FILES - loaded to the current session files hashes
#
# * __ENVAR_HASHMAP_CONTENTS - env files hashs to their content map
#
# * __ENVAR_STACK - stack of loaded desks
##########

envar.source() {
  __envar.opts.func_help "${FUNCNAME[0]}" "${@}" && return

  declare -A OPTS=(
    [deskless]=0
    [gen_pathfile]=0
    [inval]=''
    [name]="${ENVAR_NAME}"
    [pathfiles]=''
    [req_envs]=''
  )
  __envar.opts.source "${@}"
  __envar.gen_pathfile "${OPTS[gen_pathfile]}" && return 0
  __envar.opts.fail_invalid "${OPTS[inval]}" || return 1
  __envar.opts.parse_pathfiles_to_global "${OPTS[pathfiles]}"

  local new_paths="$(__envar.path.abs "${OPTS[req_envs]}")"
  local new_paths_hashed="$(
    __envar.hashmap.hash_paths "${new_paths}"
  )"
  local new_paths_hashes="$(cut -d':' -f1 <<< "${new_paths_hashed}")"

  local paths_hashed="$(__envar.append_uniq \
    "${__ENVAR_HASHMAP_PATHS}" "${new_paths_hashed}")"
  local requested_envs="$(__envar.append_uniq \
    "${__ENVAR_REQUESTED_ENVS}" "${new_paths_hashes}")"

  [[ ${OPTS[deskless]} -eq 0 ]] && {
    local stack=""
    [[ -n "${ENVAR_BASE_PS1+x}" ]] && {
      local current_files="$(__envar.hashmap.paths_by_hashes "${__ENVAR_LOADED_FILES}")"
      local stack_entry="$(__envar.append "@${ENVAR_NAME}" "$(sed 's/^/  /g' <<< "${current_files}")")"
      stack="$(__envar.append "${stack_entry}" "${__ENVAR_STACK}")"
    }

    __ENVAR_HASHMAP_PATHS="${paths_hashed}" \
    __ENVAR_REQUESTED_ENVS="${requested_envs}" \
    __ENVAR_STACK="${stack}" \
    __ENVAR_FILES="${__ENVAR_FILES}" \
    ENVAR_NAME="${OPTS[name]}" \
    ENVAR_BASE_PS1="${ENVAR_BASE_PS1:-${PS1}}" bash
    return ${?}
  }

  if [[ -n "${ENVAR_BASE_PS1+x}" ]]; then
    # non-desk environment can't have a name
    ENVAR_NAME="${OPTS[name]}"
  fi

  __ENVAR_HASHMAP_PATHS="${paths_hashed}"
  __ENVAR_REQUESTED_ENVS="${requested_envs}"
  __envar.bootstrap
}

envar.changes() {
  __envar.opts.func_help "${FUNCNAME[0]}" "${@}" && return

  declare -A OPTS=(
    [verbose]=0
  )

  __envar.opts.changes "${@}"
  __envar.opts.fail_invalid "${OPTS[inval]}" || return 1

  local available_envs="$(__envar.path.real \
    "$(__envar.hashmap.req_env_paths)")"
  local current_files="$(__envar.path.envs_files "${available_envs}")"
  local loaded_files_hashed="$(__envar.hashmap.pathentries_by_hashes \
    "${__ENVAR_SESSION_FILES}")"
  local left_files="${current_files}"

  local added_files="$(grep -vFx -e "$(
    cut -d':' -f2- <<< "${loaded_files_hashed}"
  )" <<< "${left_files}")"
  left_files="$(grep -vFx -e "${added_files}" <<< "${left_files}")"

  local removed_files="$(cut -d':' -f2- <<< "${loaded_files_hashed}" \
    | grep -vFx -e "${left_files}")"
  left_files="$(grep -vFx -e "${removed_files}" <<< "${left_files}")"

  local left_files_hashes="$(__envar.hashmap.hash_paths \
    "${left_files}" | cut -d':' -f1)"
  local left_files_contents_map="$(__envar.hashmap.hash_contents \
    "${left_files_hashes}")"
  local changed_files_hashes="$(grep -vFx -e "${__ENVAR_HASHMAP_CONTENTS}" \
    <<< "${left_files_contents_map}" | cut -d':' -f1)"
  local changed_files="$(__envar.hashmap.paths_by_hashes \
    "${changed_files_hashes}")"
  left_files="$(grep -vFx -e "${changed_files}" <<< "${left_files}")"

  while read -r f; do
    [[ -n "${f}" ]] && echo "+${f}"
  done <<< "${added_files}"

  while read -r f; do
    [[ -n "${f}" ]] && echo "-${f}"
  done <<< "${removed_files}"

  while read -r f; do
    [[ -n "${f}" ]] && echo "*${f}"
  done <<< "${changed_files}"

  [[ ${OPTS[verbose]} -eq 0 ]] && return

  while read -r f; do
    [[ -n "${f}" ]] && echo " ${f}"
  done <<< "${left_files}"
}

envar.files() {
  __envar.opts.func_help "${FUNCNAME[0]}" "${@}" && return

  __envar.hashmap.files
}

envar.pending() {
  __envar.opts.func_help "${FUNCNAME[0]}" "${@}" && return

  __envar.hashmap.req_env_paths \
  | grep -vFx -e "$(__envar.hashmap.real_env_paths)"
}

envar.purge() {
  __envar.opts.func_help "${FUNCNAME[0]}" "${@}" && return

  [[ -z "${__ENVAR_REQUESTED_ENVS}" ]] && return
  __ENVAR_REQUESTED_ENVS="${__ENVAR_REAL_ENVS}"
  __envar.bootstrap
}

envar.stack() {
  __envar.opts.func_help "${FUNCNAME[0]}" "${@}" && return

  declare -A OPTS=(
    [limit]=3
    [verbose]=0
    [inval]=''
  )

  __envar.opts.stack "${@}"
  __envar.opts.fail_invalid "${OPTS[inval]}" || return 1

  [[ -z "${ENVAR_BASE_PS1+x}" ]] && return

  local re='^[0-9]+$'
  ! [[ "${OPTS[limit]}" =~ ${re} ]] && OPTS[limit]=3

  local stack=""
  local current_files="$(__envar.hashmap.paths_by_hashes "${__ENVAR_LOADED_FILES}")"

  stack="$(__envar.append "@${ENVAR_NAME}" "$(sed 's/^/  /g' <<< "${current_files}")")"

  [[ -n "${__ENVAR_STACK}" ]] && \
    stack="$(__envar.append "${stack}" "${__ENVAR_STACK}")"

  [[ ${OPTS[limit]} -gt 0 ]] && {
    local stack_titles="$(grep -n '^@' <<< "${stack}")"
    [[ $(wc -l <<< "${stack_titles}") -gt ${OPTS[limit]} ]] && {
      local found_line="$(head -n $((OPTS[limit] + 1)) <<< "${stack_titles}" \
          | tail -n 1 | cut -d':' -f1)"
      stack="$(head -n $((found_line - 1)) <<< "${stack}")"
    }

  }

  [[ ${OPTS[verbose]} -ne 1 ]] && stack="$(grep '^@' <<< "${stack}")"

  echo "${stack}"
}

envar.reload() {
  __envar.opts.func_help "${FUNCNAME[0]}" "${@}" && return

  [[ -n "${__ENVAR_REQUESTED_ENVS}" ]] && __envar.bootstrap -f
}

envar.req() {
  __envar.opts.func_help "${FUNCNAME[0]}" "${@}" && return

  __envar.hashmap.req_env_paths
}

envar.help() {
  local help_dir="${__ENVAR_TOOL_LIBDIR}/assets/help"

  declare -A OPTS=(
    [demo]=0
    [gen-demo]=''
    [inval]=''
  )
  __envar.opts.help "${@}"
  __envar.opts.fail_invalid "${OPTS[inval]}" || return 1

  [[ ${OPTS[demo]} -eq 1 ]] && {
    . "${help_dir}/demo.sh"
    return
  }

  [[ (-n ${OPTS[gen-demo]} && -d ${OPTS[gen-demo]}) ]] && {
    cp -r "${help_dir}/demo.env"/* ${OPTS[gen-demo]}
    return
  }

  while read -r l; do
    [[ -n "${l}" ]] && echo "${l}"
  done <<< "
  For each function \`<func> --help\` prints
  detailed help.
  Issue \`envar.help --demo\` to see usage demos.
  Issue \`envar.help --gen-demo .\` to generate
  demo playground to the current directory
  "

  echo
  echo "Available functions:"
  for f in $(ls "${help_dir}"/func.envar.*.txt); do
    basename ${f} | cut -d'.' -f2- | cut -d'.' -f-2
    sed -e '/^$/,$d' "${f}" | sed 's/^/  /g'
  done | sed 's/^/  /g'
}
