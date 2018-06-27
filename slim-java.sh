#!/bin/bash
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
set -o pipefail

# We only support 64 bit builds now
proc_type="64bit"

# Files for Keep and Del list of classes in rt.jar
keep_list="slim-java_rtjar_keep.list"
del_list="slim-java_rtjar_del.list"

function parse_platform_specific() {
	arch_info=$(uname -m)

	case "${arch}" in
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

function strip_debug_from_jar() {
	jar=$1
	isSigned=`jarsigner -verify ${jar} | grep 'jar verified'`
	if [ "${isSigned}" == "" ]; then
		echo "Striping debug info in ${jar}"
		pack200 --repack --strip-debug -J-Xmx1024m ${jar}.new ${jar}
		mv ${jar}.new ${jar}
	fi
}

# 1. Prepare Env to make a slim

# 1.1. Parse arguments
argc=$#
if [ ${argc} != 1 ]; then
	echo " Usage: `basename $0` Full-JDK-path"
	exit 1
fi

# 1.2. Validate prerequisites(tools) necessary for making a slim
tools="jar jarsigner pack200 strip"
for tool in ${tools};
do
	if [ "`which ${tool}`" == "" ]; then
		echo "${tool} not found, please add ${tool} into PATH"
		exit 1
	fi
done

# 1.3. Set input of this script
src=$1
basedir=$(dirname ${src})
target=${basedir}/slim

# 1.3.1. Derive arch from src arg
lib_arch_dir=$(parse_platform_specific)

function jre_lib_files() {
	pushd ${target}/jre/lib >/dev/null
		rm -rf applet/ boot/ ddr/ deploy desktop/ endorsed/
		rm -rf images/icons/ locale/ oblique-fonts/ security/javaws.policy aggressive.jar deploy.jar javaws.jar jexec jlm.src.jar plugin.jar
		pushd ext/ >/dev/null
			rm -f dnsns.jar dtfj*.jar nashorn.jar traceformat.jar
		popd >/dev/null
		# 2.2 Go on to remove unnecessary folders and files
		pushd ${lib_arch_dir} >/dev/null
			rm -rf classic/ libdeploy.so libjavaplugin_* libjsoundalsa.so libnpjp2.so libsplashscreen.so
			# Only remove the default dir for 64bit versions
			if [ "${proc_type}" == "64bit" ]; then
				rm -rf default/
			fi
		popd >/dev/null
	popd >/dev/null
}

function jre_files() {
	pushd ${target}/jre >/dev/null

		# 2.1 Remove unnecessary folders and files
		rm -f ASSEMBLY_EXCEPTION LICENSE THIRD_PARTY_README
		rm -rf bin
		ln -s ../bin bin

	popd >/dev/null
}

function charset_files() {
	# 2.3 Special treat for removing ZOS specific charsets
	echo "Removing charsets..."
	mkdir -p ${root}/charsets_class
	pushd ${root}/charsets_class >/dev/null
		jar -xf ${root}/jre/lib/charsets.jar
		ibmEbcdic="290 300 833 834 838 918 930 933 935 937 939 1025 1026 1046 1047 1097 1112 1122 1123 1364"

		# Generate slim-excludes-charsets list as well
		[ ! -e ${root}/jre/lib/slim/sun/nio/cs/ext/slim-excludes-charsets ] || rm -rf ${root}/jre/lib/slim/sun/nio/cs/ext/slim-excludes-charsets
		exclude_charsets=""

		for charset in ${ibmEbcdic}; do
			rm -f sun/nio/cs/ext/IBM${charset}.class
			rm -f sun/nio/cs/ext/IBM${charset}\$*.class

			exclude_charsets="${exclude_charsets} IBM${charset}"
		done
		mkdir -p $root/jre/lib/slim/sun/nio/cs/ext
		echo ${exclude_charsets} > ${root}/jre/lib/slim/sun/nio/cs/ext/slim-excludes-charsets
		cp ${root}/jre/lib/slim/sun/nio/cs/ext/slim-excludes-charsets sun/nio/cs/ext/

		jar -cfm ${root}/jre/lib/charsets.jar META-INF/MANIFEST.MF *
	popd >/dev/null
	rm -rf ${root}/charsets_class
}

function rt_jar_classes() {
	# 2.4 Remove classes in rt.jar
	echo "Removing classes in rt.jar..."
	mkdir -p ${root}/rt_class
	pushd ${root}/rt_class >/dev/null
		jar -xf ${root}/jre/lib/rt.jar
		mkdir -p ${root}/rt_keep_class
		for class in $(cat ${keep_list} | grep -v "^#");
		do
			cp --parents ${class}.class ${root}/rt_keep_class/ >null 2>&1
			cp --parents ${class}\$*.class ${root}/rt_keep_class/ >null 2>&1
		done

		for class in $(cat ${del_list} | grep -v "^#");
		do
			rm -rf ${class}
		done
		cp -rf ${root}/rt_keep_class/* ./
		rm -rf ${root}/rt_keep_class

		# 2.5. Restruct rt.jar
		jar -cfm ${root}/jre/lib/rt.jar META-INF/MANIFEST.MF *
	popd >/dev/null
	rm -rf rt_class
}

function strip_jar() {
	# 2.6. Using pack200 to strip debug info in jars
	list="`find . -name *.jar`"
	for jar in ${list};
	do
		strip_debug_from_jar ${jar}
	done

	# 2.7. strip debug info from ct.sym
	pushd lib >/dev/null
		mv ct.sym ct.jar
		strip_debug_from_jar ct.jar
		mv ct.jar ct.sym
	popd >/dev/null
}

function strip_bin() {
	# 2.8. Using strip to remove debug information in share library
	echo "Striping debug info in object files"
	find bin -type f ! -path */java-rmi.cgi -exec strip -s {} \;
	find . -name *.so* -exec strip -s {} \;
	find . -name jexec -exec strip -s {} \;
}

# 1.4. Store necessary directories paths
scriptdir=`dirname $0`
basedir=`pwd`
cd ${scriptdir}
scriptdir=`pwd`
cd ${basedir}
mkdir -p ${target}
echo "Copying ${src} to ${target}..."
cp -rf ${src}/* ${target}/
pushd ${target} >/dev/null
	root=`pwd`

	# 2. Start to trim full jre
	echo "Removing files..."

	rm -rf demo/ sample/ man/ src.zip

	jre_files

	jre_lib_files

	charset_files

	strip_jar

	strip_bin

	# Remove temp folders
	rm -rf ${root}/jre/lib/slim ${src}
popd >/dev/null
mv ${target} ${src}
echo "Done"
