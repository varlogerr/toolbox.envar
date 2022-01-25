__envar.bootstrap() {
  [[ (-n "${ENVAR_BASE_PS1}" && -n "${ENVAR_NAME}") ]] \
    && PS1="${ENVAR_BASE_PS1}@${ENVAR_NAME} > "

  declare -A OPTS=(
    # force reload even if envfiles has not changed
    [force]=0
  )
  __envar.opts.bootstrap "${@}"

  local req_env_paths="$(__envar.hashmap.req_env_paths)"
  local real_env_paths="$(__envar.path.real "${req_env_paths}")"
  local session_files="$(__envar.path.envs_files "${real_env_paths}")"
  local session_files_hashed="$(__envar.hashmap.hash_paths "${session_files}")"

  __ENVAR_REAL_ENVS="$(__envar.hashmap.hash_paths "${real_env_paths}" \
    | cut -d':' -f1)"
  # put session files to hash-path keeper
  __ENVAR_HASHMAP_PATHS="$(__envar.append_uniq \
    "${__ENVAR_HASHMAP_PATHS}" "${session_files_hashed}")"
  __ENVAR_SESSION_FILES="$(cut -d':' -f1 <<< "${session_files_hashed}")"
  __ENVAR_FILES="$(__envar.append_uniq "${__ENVAR_FILES}" "${__ENVAR_SESSION_FILES}")"

  # if all session files has already been loaded
  # no need to do anything without force flug
  if \
    [[ ${OPTS[force]} -eq 0 ]] \
    && ! grep -qvFx -e "${__ENVAR_LOADED_FILES}" <<< "${__ENVAR_SESSION_FILES}" \
  ; then
    return 0
  fi

  local fpath
  local fhash
  __ENVAR_HASHMAP_CONTENTS=""
  while read -r f; do
    [[ -z "${f}" ]] && continue

    fpath="$(cut -d':' -f2- <<< "${f}")"
    fhash="$(cut -d':' -f1 <<< "${f}")"

    . "${fpath}"

    __ENVAR_HASHMAP_CONTENTS="$(__envar.append \
      "${__ENVAR_HASHMAP_CONTENTS}" \
      "$(__envar.hashmap.hash_contents "${fhash}")")"

    # keep track of loaded for the current environment files
    __ENVAR_LOADED_FILES="$(__envar.append_uniq \
      "${__ENVAR_LOADED_FILES}" "${fhash}")"
  done <<< "${session_files_hashed}"
}
