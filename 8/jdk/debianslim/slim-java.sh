#!/usr/bin/env bash
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
set -o pipefail

# Parse arguments
argc=$#
if [ ${argc} != 1 ]; then
  message=$(basename "$0")
	echo " Usage: ${message} Full-JDK-path"
	exit 1
fi

# Validate prerequisites(tools) necessary for making a slim build
tools="jar jarsigner pack200 strip"
for tool in ${tools};
do
  command -v "${tool}" >/dev/null 2>&1 || { echo >&2 "${tool} not found, please add ${tool} into PATH"; exit 1; }
done

# Set input of this script
src="$1"
# Store necessary directories paths
basedir=$(dirname "${src}")
scriptdir=$(dirname "$0")
target="${basedir}"/slim

# Files for Keep and Del list of classes in rt.jar
keep_list="${scriptdir}/slim-java_rtjar_keep.list"
del_list="${scriptdir}/slim-java_rtjar_del.list"
# jmod files to be deleted
del_jmod_list="${scriptdir}/slim-java_jmod_del.list"
# bin files to be deleted
del_bin_list="${scriptdir}/slim-java_bin_del.list"
# lib files to be deleted
del_lib_list="${scriptdir}/slim-java_lib_del.list"

# We only support 64 bit builds now
proc_type="64bit"

# Find the arch specific dir in jre/lib based on current arch
function parse_platform_specific() {
	arch_info=$(uname -m)

	case "${arch_info}" in
		aarch64)
			echo "aarch64";
			;;
		ppc64el|ppc64le)
			echo "ppc64le";
			;;
		s390x)
			echo "s390x";
			;;
		amd64|x86_64)
			echo "amd64";
			;;
		*)
			echo "ERROR: Unknown platform";
			exit 1;
			;;
	esac
}

# Which vm implementation are we running on at the moment.
function get_vm_impl() {
	impl="$(java -version 2>&1 | grep "OpenJ9")";
	if [ -n "${impl}" ]; then
		echo "OpenJ9";
	else
		echo "Hotspot";
	fi
}

# Strip debug symbols from the given jar file.
function strip_debug_from_jar() {
	jar=$1
	isSigned=$(jarsigner -verify "${jar}" | grep 'jar verified')
	if [ "${isSigned}" == "" ]; then
		echo "        Stripping debug info in ${jar}"
		pack200 --repack --strip-debug -J-Xmx1024m "${jar}".new "${jar}"
		mv "${jar}".new "${jar}"
	fi
}

# Trim the files in jre/lib dir
function jre_lib_files() {
	echo -n "INFO: Trimming jre/lib dir..."
	pushd "${target}"/jre/lib >/dev/null || return
		rm -rf applet/ boot/ ddr/ deploy desktop/ endorsed/
		rm -rf images/icons/ locale/ oblique-fonts/ security/javaws.policy aggressive.jar deploy.jar javaws.jar jexec jlm.src.jar plugin.jar
		pushd ext/ >/dev/null || return
			rm -f dnsns.jar dtfj*.jar nashorn.jar traceformat.jar
		popd >/dev/null || return
		# Derive arch from current platorm.
		lib_arch_dir=$(parse_platform_specific)
		if [ -d "${lib_arch_dir}" ]; then
			pushd "${lib_arch_dir}" >/dev/null || return
				rm -rf classic/ libdeploy.so libjavaplugin_* libjsoundalsa.so libnpjp2.so libsplashscreen.so
				# Only remove the default dir for 64bit versions
				if [ "${proc_type}" == "64bit" ]; then
					rm -rf default/
				fi
			popd >/dev/null || return
		fi
	popd >/dev/null || return
	echo "done"
}

# Trim the files in the jre dir
function jre_files() {
	echo -n "INFO: Trimming jre dir..."
	pushd "${target}"/jre >/dev/null || return
		rm -f ASSEMBLY_EXCEPTION LICENSE THIRD_PARTY_README
		rm -rf bin
		ln -s ../bin bin
	popd >/dev/null || return
	echo "done"
}

# Exclude the zOS specific charsets
function charset_files() {

	# 2.3 Special treat for removing ZOS specific charsets
	echo -n "INFO: Trimming charsets..."
	mkdir -p "${root}"/charsets_class
	pushd "${root}"/charsets_class >/dev/null || return
		jar -xf "${root}"/jre/lib/charsets.jar
		ibmEbcdic="290 300 833 834 838 918 930 933 935 937 939 1025 1026 1046 1047 1097 1112 1122 1123 1364"

		# Generate sfj-excludes-charsets list as well. (OpenJ9 expects the file to be named sfj-excludes-charsets).
		[ ! -e "${root}"/jre/lib/slim/sun/nio/cs/ext/sfj-excludes-charsets ] || rm -rf "${root}"/jre/lib/sfj/sun/nio/cs/ext/sfj-excludes-charsets
		exclude_charsets=""

		for charset in ${ibmEbcdic};
		do
			rm -f sun/nio/cs/ext/IBM"${charset}".class
			rm -f sun/nio/cs/ext/IBM"${charset}"\$*.class

			exclude_charsets="${exclude_charsets} IBM${charset}"
		done
		mkdir -p "${root}"/jre/lib/slim/sun/nio/cs/ext
		echo "${exclude_charsets}" > "${root}"/jre/lib/slim/sun/nio/cs/ext/sfj-excludes-charsets
		cp "${root}"/jre/lib/slim/sun/nio/cs/ext/sfj-excludes-charsets sun/nio/cs/ext/

		jar -cfm "${root}"/jre/lib/charsets.jar META-INF/MANIFEST.MF ./*
	popd >/dev/null || return
	rm -rf "${root}"/charsets_class
	echo "done"
}

# Trim the rt.jar classes. The classes deleted are as per slim-java_rtjar_del.list
function rt_jar_classes() {
	# 2.4 Remove classes in rt.jar
	echo -n "INFO: Trimming classes in rt.jar..."
	mkdir -p "${root}"/rt_class
	pushd "${root}"/rt_class >/dev/null || return
		jar -xf "${root}"/jre/lib/rt.jar
		mkdir -p "${root}"/rt_keep_class
		grep -v '^#' < "${keep_list}" | while IFS= read -r class
		do
			cp --parents "${class}".class "${root}"/rt_keep_class/ >null 2>&1
			cp --parents "${class}"\$*.class "${root}"/rt_keep_class/ >null 2>&1
		done

    grep -v '^#' < "${del_list}" | while IFS= read -r class
		do
			rm -rf "${class}"
		done
		cp -rf "${root}"/rt_keep_class/* ./
		rm -rf "${root}"/rt_keep_class

		# 2.5. Restruct rt.jar
		jar -cfm "${root}"/jre/lib/rt.jar META-INF/MANIFEST.MF ./*
	popd >/dev/null || return
	rm -rf rt_class
	echo "done"
}

# Strip the debug info from all jar files
function strip_jar() {
	# Using pack200 to strip debug info in jars
	echo "INFO: Strip debug info from jar files"
	list=$(find . -name "*.jar")
	for jar in ${list};
	do
		strip_debug_from_jar "${jar}"
	done
}

# Strip debug information from share libraries
function strip_bin() {
	echo -n "INFO: Stripping debug info in object files..."
	find bin -type f ! -path "./*"/java-rmi.cgi -exec strip -s {} \;
	find . -name "*.so*" -exec strip -s {} \;
	find . -name jexec -exec strip -s {} \;
	echo "done"
}

# Remove all debuginfo files
function debuginfo_files() {
	echo -n "INFO: Removing all .debuginfo files..."
	find . -name "*.debuginfo" -exec rm -f {} \;
	echo "done"
}

# Remove all src.zip files
function srczip_files() {
	echo -n "INFO: Removing all src.zip files..."
	find . -name "*src*zip" -exec rm -f {} \;
	echo "done"
}

# Remove unnecessary jmod files
function jmod_files() {
	if [ ! -d "${target}"/jmods ]; then
		return;
	fi
	pushd "${target}"/jmods >/dev/null || return
	  grep -v '^#' < "${del_jmod_list}" | while IFS= read -r jfile
		do
			rm -rf "${jfile}"
		done
	popd >/dev/null || return
}

# Remove unnecessary tools
function bin_files() {
	echo -n "INFO: Trimming bin dir..."
	pushd "${target}"/bin >/dev/null || return
	  grep -v '^#' < "${del_bin_list}" | while IFS= read -r binfile
		do
			rm -rf "${binfile}"
		done
	popd >/dev/null || return
}

# Remove unnecessary tools and jars from lib dir
function lib_files() {
	echo -n "INFO: Trimming bin dir..."
	pushd "${target}"/lib >/dev/null || return
	  grep -v '^#' < "${del_lib_list}" | while IFS= read -r libfile
		do
			rm -rf "${libfile}"
		done
	popd >/dev/null || return
}

# Create a new target directory and copy over the source contents.
cd "${basedir}" || exit
mkdir -p "${target}"
echo "Copying ${src} to ${target}..."
cp -rf "${src}"/* "${target}"/

pushd "${target}" >/dev/null || exit
	root=$(pwd)
	echo "Trimming files..."

	# Remove examples documentation and sources.
	rm -rf demo/ sample/ man/

	# jre dir may not be present on all builds.
	if [ -d "${target}"/jre ]; then
		# Trim file in jre dir.
		jre_files

		# Trim file in jre/lib dir.
		jre_lib_files

		# Remove IBM zOS charset files.
		# This needs extra code in sun/nio/cs/ext/ExtendedCharsets.class to
		# ignore the charset files that are removed. Disabling for now until
		# this gets added in the upstream openjdk project.
		# charset_files

		# Trim unneeded rt.jar classes.
		rt_jar_classes
	fi

	# Strip all remaining jar files of debug info.
	strip_jar

	# Strip object files of debug info.
	strip_bin

	# Remove all debuginfo files
	debuginfo_files

	# Remove all src.zip files
	srczip_files

	# Remove unnecessary jmod files
	jmod_files

	# Remove unnecessary tools and jars from lib dir
	lib_files

	# Remove unnecessary tools
	bin_files

	# Remove temp folders
	rm -rf "${root}"/jre/lib/slim "${src}"
popd >/dev/null || exit

mv "${target}" "${src}"
echo "Done"
