#!/bin/bash

source common_functions.sh 

REMOTE_UPSTREAM="upstream"
BRANCH_NAME="automated-branch-for-dockerfiles"

function proceed_to_update() {
	UPSTREAM=$(cat .git/config | grep -m 1 -B 1 "https://github.com/AdoptOpenJDK/openjdk-docker" | head -n 1 | cut -d '"' -f 2)
	if [ -z $UPSTREAM ]; then
		if cat .git/config | grep -Fxq "[remote \"upstream\"]"; then
			git remote add temp-upstream https://github.com/AdoptOpenJDK/openjdk-docker
			REMOTE_UPSTREAM="temp-upstream"
		else
			git remote add upstream https://github.com/AdoptOpenJDK/openjdk-docker
		fi
	else
		REMOTE_UPSTREAM="$UPSTREAM"
	fi
	git checkout master
	git fetch ${REMOTE_UPSTREAM}
	git merge ${REMOTE_UPSTREAM}/master
	local CHECK_LOCAL=$(git branch --list ${BRANCH_NAME})
	if [[ -z ${CHECK_LOCAL} ]]; then
		git checkout -b ${BRANCH_NAME}
	else
		git branch -D ${BRANCH_NAME}
		git checkout -b ${BRANCH_NAME}
	fi
	source update_all.sh releases
	git add ${supported_versions}
	git commit -m "$(date '+%d-%m-%Y %H:%M:%S') : Auto-updating dockerfiles for PR #${PR_NUM}" -s
	git push -f origin ${BRANCH_NAME}
	echo "Please raise a PR to AdoptOpenJDK/openjdk-docker master from branch ${BRANCH_NAME}"
	echo "Exiting."
	exit 0
}

function script_usage() {
	echo "USAGE:"
	echo ""
	echo "    update_dockerfiles_on_merge.sh <Pull request id/number >"
	echo ""
	echo "EXAMPLE:"
	echo ""
	echo "To update the dockerfiles if the PR 444 is merged, you need to ENTER the following command :"
	echo ""
	echo "    ./update_dockerfiles_on_merge.sh 444"
	echo ""
}


function check_for_result() {
	local RESULT=$(curl -fs https://api.github.com/repos/AdoptOpenJDK/openjdk-docker/pulls/${PR_NUM} | grep "\"merged\"" | tr ',' ' ' | tr -d " " | cut -d ":" -f 2)

	if [ -z $RESULT ]; then
		echo ""
		echo "INVALID PR. PLEASE CHECK AGAIN AND RUN THE SCRIPT"
		echo ""
		exit 1
	fi

	local ITERATION=1
	while [ "$RESULT" == "false" ]
	do
		echo "TRAIL : $ITERATION - PR Haven't been merged, Retrying after 1 minute"
		ITERATION=$(expr $ITERATION + 1)
		sleep 60
		RESULT=$(curl -fs https://api.github.com/repos/AdoptOpenJDK/openjdk-docker/pulls/${PR_NUM} | grep "\"merged\"" | tr ',' ' ' | tr -d " " | cut -d ":" -f 2)
	done

	if [ "$RESULT" != "true" ]; then
		echo "Unexpected Error. Exiting"
		exit 1
	fi
}

if [ "$#" -ne 1 ]; then
	echo "You must enter only the PR number as an argument. See the usage below."
	echo ""
	script_usage
	exit 1
fi

PR_NUM=$1

NUM_REGEX='^[0-9]+$'

if ! [[ $PR_NUM =~ $NUM_REGEX ]] ; then
	echo "Expected PR number as arg. See the usage below."
	echo ""
	script_usage
	exit 1
fi

NOCOLOR='\033[0m'	   # No Color - Color Reset

# Normal Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'

# Bold Colors
BRED='\033[1;31m'
BGREEN='\033[1;32m'
BBLUE='\033[1;34m'
BCYAN='\033[1;36m'

echo ""
echo -e "This script calls the ${BBLUE}'update_all.sh'${NOCOLOR} to update the dockerfiles"
echo ""
echo -e "It pulls ${BCYAN}AdoptOpenJDK/openjdk-docker${NOCOLOR} ${BLUE}master${NOCOLOR} branch latest changes and"
echo -e "merges local master. Later creates a new branch to update dockerfiles"
echo ""
echo -e "${BGREEN}New branch name${NOCOLOR} : ${BLUE}${BRANCH_NAME}${NOCOLOR}"
echo ""
echo -e "If the branch exists, it ${RED}deletes${NOCOLOR} existing branch and creates new"
echo -e "branch which is even with master"
echo ""
echo -e "${BRED}CAUTION${NOCOLOR} : Please run this script after saving your work (commiting) as ${RED}it may mess up your changes${NOCOLOR}."
echo ""
echo ""
check_for_result 
proceed_to_update
