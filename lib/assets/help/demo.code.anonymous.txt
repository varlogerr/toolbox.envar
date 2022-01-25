# create anonymous environment
# (doesn't change the prompt)
# with paths ./env1 and ./env2.sh
envar.source ./env1 ./env2.sh
# validate envs are loaded
echo "${E11}"
# exit environment
exit
