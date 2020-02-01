#!/bin/bash
which goss

if [ $? -ne 0 ]; then
	echo "Please install goss from https://goss.rocks/install"
	echo "For a quick auto install run the following"
	echo "curl -fsSL https://goss.rocks/install | sh"
	exit $?
fi

docker build --tag lancachenet/ubuntu:goss-test .


case $1 in
  circleci)
	shift;
	mkdir -p ./reports/goss
	if [[ "$1" == "keepimage" ]]; then
		KEEPIMAGE=true
		shift
	fi
	export GOSS_OPTS="$GOSS_OPTS --format junit"
	export CONTAINER_LOG_OUTPUT="reports/goss/docker.log"
	dgoss run -e SUPERVISORD_LOGLEVEL=INFO $@ lancachenet/ubuntu:goss-test > reports/goss/report.xml
	echo \
"Container Output: 
$(cat reports/goss/docker.log)" \
	> reports/goss/docker.log
	#store result for exit code
	RESULT=$?
	#delete the junk that goss currently outputs :(
    sed -i '0,/^</d' reports/goss/report.xml
	#remove invalid system-err outputs from junit output so circleci can read it
	sed -i '/<system-err>.*<\/system-err>/d' reports/goss/report.xml
    ;;
  *)
	if [[ "$1" == "keepimage" ]]; then
		KEEPIMAGE=true
		shift
	fi
	echo $1
	if [[ "$1" == "showlog" ]]; then
		echo "Enabling showlog"
		SHOWLOG=true
		shift
		export CONTAINER_LOG_OUTPUT="docker.log"
	fi
	dgoss run -e SUPERVISORD_LOGLEVEL=INFO $@ lancachenet/ubuntu:goss-test
	if [[ "$SHOWLOG" ==  "true" ]]; then
		echo "Contianer Output:"
		cat "docker.log"
		rm "docker.log"
	fi
	RESULT=$?
    ;;
esac
[[ "$KEEPIMAGE" == "true" ]] || docker rmi lancachenet/ubuntu:goss-test

exit $RESULT
