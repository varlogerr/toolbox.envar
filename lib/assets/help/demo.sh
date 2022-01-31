help_dir="${__ENVAR_TOOL_LIBDIR}/assets/help"

echo "Initial directory structure:"
cat "${help_dir}/demo.dir-struct.txt" | sed 's/^/  /g'

echo
echo "Demo files content:"
. "${help_dir}/demo.files-content.sh" | sed 's/^/  /g'

echo
echo "Demo (anonymous):"
cat "${help_dir}/demo.code.anonymous.txt" | sed 's/^/  /g'

echo
echo "Demo (named):"
cat "${help_dir}/demo.code.named.txt" | sed 's/^/  /g'

echo
echo "Demo (pathfile):"
cat "${help_dir}/demo.code.pathfile.txt" | sed 's/^/  /g'

echo
echo "Demo (pending):"
cat "${help_dir}/demo.code.pending.txt" | sed 's/^/  /g'
