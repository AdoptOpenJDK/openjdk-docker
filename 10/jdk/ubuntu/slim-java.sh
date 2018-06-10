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

# We only support 64 bit builds now
proc_type="64bit"

# 1. Prepare Env to make a slim

# 1.1. Parse arguments
argc=$#
if [ ${argc} != 1 ]; then
	echo " Usage: `basename $0` IBM-full-JRE-path"
	exit 1
fi

# 1.2. Validate prerequisites(tools) necessary for making a slim
tools="jar jarsigner pack200 strip"
for tool in ${tools}; do
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

# 1.4. Store necessary directories paths
scriptdir=`dirname $0`
basedir=`pwd`
cd ${scriptdir}
scriptdir=`pwd`
cd ${basedir}
mkdir -p $target
echo "Copying ${src} to ${target}..."
cp -rf ${src}/* ${target}/
pushd ${target} >/dev/null
	root=`pwd`

	# 2. Start to trim full jre
	echo "Removing files..."

	rm -rf demo/ sample/ man/ src.zip
	pushd jre >/dev/null

		# 2.1 Remove unnecessary folders and files
		rm -f ASSEMBLY_EXCEPTION LICENSE THIRD_PARTY_README
		rm -rf bin
		ln -s ../bin bin

		pushd lib >/dev/null
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

	popd >/dev/null

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

	# 2.4 Remove classes in rt.jar
	echo "Removing classes in rt.jar..."
	mkdir -p ${root}/rt_class
	pushd ${root}/rt_class >/dev/null
		jar -xf ${root}/jre/lib/rt.jar
		mkdir -p ${root}/rt_remaining_class
		remainingClasses='com/sun/java/swing/plaf/motif/MotifLookAndFeel
				  sun/applet/AppletAudioClip
				  sun/awt/motif/MFontConfiguration
				  sun/awt/X11/OwnershipListener
				  sun/awt/X11/XAWTXSettings
				  sun/awt/X11/XAWTLookAndFeel
				  sun/awt/X11/XBaseWindow
				  sun/awt/X11/XCanvasPeer
				  sun/awt/X11/XComponentPeer
				  sun/awt/X11/XClipboard
				  sun/awt/X11/XCustomCursor
				  sun/awt/X11/XDataTransferer
				  sun/awt/X11/XEmbedCanvasPeer
				  sun/awt/X11/XEmbeddedFrame
				  sun/awt/X11/XEventDispatcher
				  sun/awt/X11/XFontPeer
				  sun/awt/X11/XMouseDragGestureRecognizer
				  sun/awt/X11/XMSelectionListener
				  sun/awt/X11/XRootWindow
				  sun/awt/X11/XToolkit
				  sun/awt/X11/XWindow
				  sun/java2d/opengl/GLXVolatileSurfaceManager'
		for class in ${remainingClasses};
		do
			cp --parents ${class}.class ${root}/rt_remaining_class/ >null 2>&1
			cp --parents ${class}\$*.class ${root}/rt_remaining_class/ >null 2>&1
		done

		deleteList='META-INF/services/com.sun.jdi.connect.Connector
			META-INF/services/com.sun.jdi.connect.spi.TransportService
			META-INF/services/com.sun.mirror.apt.AnnotationProcessorFactory
			META-INF/services/com.sun.tools.xjc.Plugin
			META-INF/services/com.sun.tools.attach.spi.AttachProvider
			META-INF/services/com.sun.jdi.connect.Connector
			META-INF/services/com.sun.jdi.connect.spi.TransportService
			com/sun/codemodel/
			com/sun/codemodel/
			com/sun/corba
			com/sun/crypto/provider/
			com/sun/istack/internal/tools/
			com/sun/istack/internal/ws/
			com/sun/javadoc/
			com/sun/jdi/
			com/sun/jarsigner/
			com/sun/java/swing/plaf/gtk
			com/sun/java/swing/plaf/motif
			com/sun/java/swing/plaf/nimbus
			com/sun/java/swing/plaf/windows
			com/sun/java/swing/plaf/com/sun/javadoc/
			com/sun/jdi/
			com/sun/mirror/
			com/sun/net/ssl/internal/ssl/
			com/sun/source/
			com/sun/tools/
			com/sun/tools/attach/
			com/sun/tools/classfile/
			com/sun/tools/javap/
			com/sun/tools/script/shell/
			com/sun/xml/internal/dtdparser/
			com/sun/xml/internal/rngom/
			com/sun/xml/internal/xsom/
			javax/crypto/
			org/relaxng/datatype/
			sun/applet/
			sun/awt/HKSCS.class
			sun/awt/motif/X11GB2312$Decoder.class
			sun/awt/motif/X11GB2312$Encoder.class
			sun/awt/motif/X11GB2312.class
			sun/awt/motif/X11GBK$Encoder.class
			sun/awt/motif/X11GBK.class
			sun/awt/motif/X11KSC5601$Decoder.class
			sun/awt/motif/X11KSC5601$Encoder.class
			sun/awt/motif/X11KSC5601.class
			sun/awt/motif/
			sun/awt/X11/
			sun/applet/
			sun/java2d/opengl/
			sun/jvmstat/
			sun/nio/cs/ext/
			sun/rmi/rmic/
			sun/security/internal/
			sun/security/ssl/
			sun/security/tools/JarBASE64Encoder.class
			sun/security/tools/JarSigner.class
			sun/security/tools/JarSignerParameters.class
			sun/security/tools/JarSignerResources*.class
			sun/security/tools/SignatureFile$Block.class
			sun/security/tools/SignatureFile.class
			sun/security/tools/TimestampedSigner.class
			sun/security/rsa/SunRsaSign.class
			sun/tools/asm/
			sun/tools/attach/
			sun/tools/java/
			sun/tools/javac/
			sun/tools/jcmd/
			sun/tools/jconsole/
			sun/tools/jinfo/
			sun/tools/jmap/
			sun/tools/jps/
			sun/tools/jstack/
			sun/tools/jstat/
			sun/tools/jstatd/
			sun/tools/native2ascii/
			sun/tools/serialver/
			sun/tools/tree/
			sun/tools/util/'

		for class in ${deleteList};
		do
			rm -rf ${class}
		done
		cp -rf ${root}/rt_remaining_class/* ./
		rm -rf ${root}/rt_remaining_class

		# 2.5. Restruct rt.jar
		jar -cfm ${root}/jre/lib/rt.jar META-INF/MANIFEST.MF *
	popd >/dev/null
	rm -rf rt_class

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

	# 2.8. Using strip to remove debug information in share library
	echo "Striping debug info in object files"
	find bin -type f ! -path */java-rmi.cgi -exec strip -s {} \;
	find . -name *.so* -exec strip -s {} \;
	find . -name jexec -exec strip -s {} \;

	# 2.9. Remove temp $root/jre/lib/slim folder
	rm -rf ${root}/jre/lib/slim

	# 3 Complete create slim
	rm -rf ${src}
	mv ${target} ${src}
	echo "Done"
popd >/dev/null
