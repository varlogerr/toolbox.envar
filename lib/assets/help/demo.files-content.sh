current_dir="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
for f in \
  env1/env11.sh \
  env1/env12.sh \
  env2.sh \
  pathfile.envar \
; do
  echo "\$ cat ./${f}"
  cat "${current_dir}/demo.env/${f}"
done
