help_dir="${__ENVAR_TOOL_LIBDIR}/assets/help"

echo "Initial directory structure:"
cat "${help_dir}/demo.dir-struct.txt" | sed 's/^/  /g'

echo
echo "Demo files content:"
. "${help_dir}/demo.files-content.sh" | sed 's/^/  /g'

declare -A demos_map=(
  [anonymous]="anonymous"
  [named]="named"
  [pathfile]="pathfile"
  [pending]="pending"
  [deskname]="desk name"
)

for k in \
  anonymous named pathfile \
  pending deskname \
; do
  echo
  echo "Demo (${demos_map[${k}]}):"
  cat "${help_dir}/demo.code.${k}.txt" | sed 's/^/  /g'
done
