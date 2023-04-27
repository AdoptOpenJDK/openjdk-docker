#!/bin/bash
versions=( 8 11 12)
packages=( jdk jre)
jvms=( hotspot openj9)
oss=( ubuntu alpine)
types=( full slim)
builds=( releases nightly)


body=""

for version in "${versions[@]}"
do 

	for package in "${packages[@]}"
	do 

		for jvm in "${jvms[@]}"
		do 

			for os in "${oss[@]}"
			do 
				for type in "${types[@]}"
				do 
					for build in "${builds[@]}"
					do 

					descr=$version.$package.$jvm.$os.$type.$build
					link=$version/$package/$os/Dockerfile.$jvm.$build.$type

					image="adoptopenjdk/openjdk"$version"-"$jvm
					image=${image//-hotspot/}

					tag=$os"-"$package"-"$build"-"$type
					tag=${tag//ubuntu-/}
					tag=${tag//jdk-/}
					tag=${tag//releases-/}
					tag=${tag//-full/}
					tag=${tag//full/latest}



					url="https://hub.docker.com/v2/repositories/$image/tags/$tag/"
					echo $url
					json=$(curl -s $url)
					echo $json
					size=$(echo $json | jq '.full_size')
					echo $size
					sizemb=$((size / 1024 /1024))
					
					body=$body"|[$image:$tag]($link)|$descr|$sizemb"$'\n'

					done
				done
			done
		done

	done


done


table="|Image|Description|Size"$'\n'
table=$table$'| --- | --- | --- \n'
table=$table$body
echo "$table"
