clear
echo "Welcome to the xstatix based blog manager!"
echo
echo "(select demo.sh for a quick demo)"
echo

while [ true ]; do
	# menu
	torun=$(ls scripts | fzy -p "run> ")
	if [ -z "$torun" ]; then
		exit 0
	fi

	# run
	./scripts/$torun
done
