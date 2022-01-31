#
# parse input options to global OPTS dict
#

__envar.opts.source() {
  local eopt=0
  local opt

  while :; do
    # break on end of params
    [[ -z "${1+x}" ]] && break

    opt="${1}"
    shift

    grep -qx '\s*' <<< "${opt}" && continue

    # add path
    [[ (${eopt} == 1 || ${opt:0:1} != '-') ]] && {
      # borrowed from here:
      # https://stackoverflow.com/questions/965053/extract-filename-and-extension-in-bash
      [[ (-f "${opt}" && "${opt##*.}" == 'envar') ]] && {
        OPTS[pathfiles]+="${OPTS[pathfiles]:+$'\n'}${opt}"
      } || {
        OPTS[req_envs]+="${OPTS[req_envs]:+$'\n'}${opt}"
      }

      continue
    }

    # parse options
    case "${opt}" in
      -D|--deskless)
        OPTS[deskless]=1
        ;;
      --name=*)
        OPTS[name]="${opt#*=}"
        ;;
      -n|--name)
        OPTS[name]="${1}"
        shift
        ;;
      --pathfile=*)
        OPTS[pathfiles]+="${OPTS[pathfiles]:+$'\n'}${opt#*=}"
        ;;
      -f|--pathfile)
        OPTS[pathfiles]+="${OPTS[pathfiles]:+$'\n'}${1}"
        shift
        ;;
      --gen-pathfile)
        OPTS[gen_pathfile]=1
        ;;
      --)
        eopt=1
        ;;
      *)
        OPTS[inval]+="${OPTS[inval]:+$'\n'}${opt}"
        ;;
    esac
  done

  OPTS[pathfiles]="$(__envar.uniq "${OPTS[pathfiles]}")"
  OPTS[req_envs]="$(__envar.uniq "${OPTS[req_envs]}")"
}

__envar.opts.stack() {
  while :; do
    # break on end of params
    [[ -z "${1+x}" ]] && break

    # parse options
    case "${1}" in
      --limit=*)
        OPTS[limit]="${1#*=}"
        ;;
      -l|--limit)
        shift
        OPTS[limit]="${1}"
        ;;
      -v|--verbose)
        OPTS[verbose]=1
        ;;
      *)
        OPTS[inval]+="${OPTS[inval]:+$'\n'}${1}"
        ;;
    esac

    shift
  done
}

__envar.opts.changes() {
  while :; do
    # break on end of params
    [[ -z "${1+x}" ]] && break

    # parse options
    case "${1}" in
      -v|--verbose)
        OPTS[verbose]=1
        ;;
      *)
        OPTS[inval]+="${OPTS[inval]:+$'\n'}${1}"
        ;;
    esac

    shift
  done
}

# parse input options to global OPTS dict
__envar.opts.bootstrap() {
  local opt

  while :; do
    # break on end of params
    [[ -z "${1+x}" ]] && break

    opt="${1}"
    shift

    # parse options
    case "${opt}" in
      -f|--force)
        OPTS[force]=1
        ;;
      *)
        OPTS[inval]+="${OPTS[inval]:+$'\n'}${opt}"
        ;;
    esac
  done
}

__envar.opts.func_help() {
  local funcname="${1}"
  local help_file="${__ENVAR_TOOL_LIBDIR}/assets/help/func.${funcname}.txt"
  shift

  while :; do
    [[ -z "${1+x}" ]] && break

    case "${1}" in
      -h|-\?|--help)  cat "${help_file}"; return 0 ;;
    esac
    shift
  done

  return 1
}

__envar.opts.help() {
  while :; do
    # break on end of params
    [[ -z "${1+x}" ]] && break

    # parse options
    case "${1}" in
      -d|--demo)      OPTS[demo]=1 ;;
      --gen-demo=*)   OPTS[gen-demo]="${1#*=}" ;;
      --gen-demo)     shift; OPTS[gen-demo]="${1}" ;;
      *)
        OPTS[inval]+="${OPTS[inval]:+$'\n'}${1}"
        ;;
    esac

    shift
  done
}

__envar.opts.fail_invalid() {
  [[ -n "${1}" ]] && {
    echo "Invalid options:"
    while read -r o; do
      printf -- '%-2s%s\n' '' "${o}" >&2
    done <<< "${1}"
    return 1
  }
  return 0
}

__envar.opts.parse_pathfiles_to_global() {
  local content="$( while read -r pathfile; do
    [[ -z "${pathfile}" ]] && continue
    [[ ! -f "${pathfile}" ]] && continue

    pathfile="$(realpath "${pathfile}")"

    # exclude empty lines and lines
    # starting with '#'
    grep -v '^#' "${pathfile}" | grep -vFx '' \
    | while read -r envfile; do
      [[ "${envfile:0:1}" != ':' ]] && {
        echo "${envfile}"
        continue
      }

      local pathfile_dir="$(dirname "$(realpath -qms "${pathfile}")")"
      echo "${pathfile_dir}/${envfile:1}"
    done
  done <<< "${1}" | grep -vFx '' )"

  OPTS[req_envs]="$(__envar.append_uniq "${OPTS[req_envs]}" "${content}")"
}
