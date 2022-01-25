__envar.hashmap.hash_paths() {
  while read -r f; do
    [[ -z "${f}" ]] && continue
    sha1sum <<< "${f}" | cut -d' ' -f1 \
    | tr -d '\n' | { cat; printf ':%s\n' "${f}"; }
  done <<< "${1}"
}

__envar.hashmap.hash_contents() {
  while read -r hash; do
    [[ -z "${hash}" ]] && continue
    fpath="$(__envar.hashmap.paths_by_hashes "${hash}")"
    printf '%s:%s\n' "${hash}" \
      $(sha1sum "${fpath}" | cut -d' ' -f1)
  done <<< "${1}"
}

__envar.hashmap.req_env_paths() {
  __envar.hashmap.paths_by_hashes \
    "${__ENVAR_REQUESTED_ENVS}"
}

__envar.hashmap.real_env_paths() {
  __envar.hashmap.paths_by_hashes \
    "${__ENVAR_REAL_ENVS}"
}

__envar.hashmap.files() {
  __envar.hashmap.paths_by_hashes \
    "${__ENVAR_FILES}"
}

__envar.hashmap.paths_by_hashes() {
  __envar.hashmap.pathentries_by_hashes \
    "${1}" | cut -d':' -f2-
}

__envar.hashmap.pathentries_by_hashes() {
  while read -r p; do
    [[ -z "${p}" ]] && continue
    grep -m 1 "^${p}:" <<< "${__ENVAR_HASHMAP_PATHS}"
  done <<< "${1}"
}
