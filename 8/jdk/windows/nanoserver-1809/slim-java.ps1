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
[CmdletBinding()]
Param(
  [Parameter(Position=0, Mandatory=$true)]
  [String]
  $Src
)

$ErrorActionPreference = "Stop"

$env:PATH = "$(Join-Path $Src 'bin');${env:PATH}"

$pwd = Get-Location

# Which major java version
function Get-JavaVersion() {
  $verstring = (Get-Command java.exe | Select-Object -ExpandProperty Version).ToString()

  switch -wildcard ($verstring) {
    "8.*" { return 8; break }
    "9.*" { return 9; break }
    "10*" { return 10; break }
    "11*" { return 11; break }
    "12*" { return 12; break }
    "13*" { return 13; break }
    "14*" { return 14; break }
    default {
      Write-Error "Unknown Java Version: $verstring"
      exit 1
    }
  }
}

function Test-CommandExists($command) {
  $oldPreference = $ErrorActionPreference
  $ErrorActionPreference = 'stop'
  $res = $false
  try {
      if(Get-Command $command) {
          $res = $true
      }
  } catch {
      $res = $false
  } finally {
      $ErrorActionPreference=$oldPreference
  }
  return $res
}

# Set the java major version that we are on right now.
$java_major_version = Get-JavaVersion

# Validate prerequisites(tools) necessary for making a slim build
$tools = @("jar", "jarsigner")
if($java_major_version -lt 14) {
  $tools += "pack200"
}

foreach($tool in $tools) {
	if(-not (Test-CommandExists $tool)) {
		Write-Error "${tool} not found, please add ${tool} into PATH"
		exit 1
	}
}

# Store necessary directories paths
$basedir=Split-Path -Parent $Src
$target=Join-Path $basedir "slim"

# Files for Keep and Del list of classes in rt.jar
$keep_list=Join-Path $PSScriptRoot "slim-java_rtjar_keep.list"
$del_list=Join-Path $PSScriptRoot "slim-java_rtjar_del.list"
# jmod files to be deleted
$del_jmod_list=Join-Path $PSScriptRoot "slim-java_jmod_del.list"
# bin files to be deleted
$del_bin_list=Join-Path $PSScriptRoot "slim-java_bin_del.list"
# lib files to be deleted
$del_lib_list=Join-Path $PSScriptRoot "slim-java_lib_del.list"

# We only support 64 bit builds now
$proc_type="64bit"

# Find the arch specific dir in jre/lib based on current arch
function Parse-PlatformSpecific() {
  return "amd64"
}

# Which vm implementation are we running on at the moment.
function Get-VMImplementation() {
  $impl=& cmd /c "java -version 2>&1"
  if($impl -match "OpenJ9") {
    return "OpenJ9"
  }
  return "Hotspot"
}

# Strip debug symbols from the given jar file.
function Strip-DebugFromJar([string] $jar) {
  $isSigned=(jarsigner -verify "${jar}" | Out-String).Contains('jar verified')
  if(!$isSigned) {
    Write-Host "        Stripping debug info in ${jar}"
    pack200 --repack --strip-debug -J-Xmx1024m "${jar}.new" "${jar}"
    Move-Item -Path "${jar}.new" -Destination "${jar}" -Force
  }
}

# Trim the files in jre/lib dir
function Trim-JRELibFiles() {
  Write-Host -NoNewline "INFO: Trimming jre/lib dir..."
  $path = Join-Path $target "jre/lib"
  if(Test-Path $path) {
    Push-Location $path
    try {
      @("applet", "boot", "ddr", "deploy", "destkop", "endorsed", "images/icons", "locale", "oblique-fonts", "security/javaws.policy", "aggressive.jar", "deploy.jar", "javaws.jar", "jexec", "jlm.src.jar", "plugin.jar") | ForEach-Object {
        if(Test-Path $_) {
          Remove-Item -Force -Recurse $_
        }
      }

      Push-Location "ext"
      try {
        @("dnsns.jar", "dtfj*.jar", "nashorn.jar", "traceformat.jar") | ForEach-Object {
          if($_ -match '\*') {
              Remove-Item -Force -Recurse -Path .\* -Include $_
          } elseif(Test-Path $_) {
              Remove-Item -Force -Recurse -Path $_
          }
        }
      } finally {
          Pop-Location
      }

      # Derive arch from current platorm.
      $lib_arch_dir=Parse-PlatformSpecific
      if(Test-Path $lib_arch_dir) {
        Push-Location $lib_arch_dir
        try {
          #rm -rf classic/ libdeploy.so libjavaplugin_* libjsoundalsa.so libnpjp2.so libsplashscreen.so
          # Only remove the default dir for 64bit versions
          if($proc_type -eq "64bit" -and (Test-Path "default")) {
              Remove-Item -Recurse -Force "default"
          }
        } finally {
          Pop-Location
        }
      }
    } finally {
      Pop-Location
    }
  }
  Write-Host "done"
}

# Trim the files in the jre dir
function Trim-JREFiles() {
  Write-Host -NoNewline "INFO: Trimming jre dir..."
  $path = Join-Path $target "jre"
  if(Test-Path $path) {
    Push-Location $path
    try {
      @("ASSEMBLY_EXCEPTION", "LICENSE", "THIRD_PARTY_README") | ForEach-Object {
          if(Test-Path $_) {
              Remove-Item -Force -Recurse $_
          }
      }
#        rm -rf bin
#        ln -s ../bin bin
    } finally {
        Pop-Location
    }
  }
  Write-Host "done"
}

# Trim the rt.jar classes. The classes deleted are as per slim-java_rtjar_del.list
function Trim-RTJarClasses() {
  # 2.4 Remove classes in rt.jar
  Write-Host -NoNewline "INFO: Trimming classes in rt.jar..."
  $path = Join-Path $root "rt_class"
  New-Item -ItemType Directory -Path $path -Force | Out-Null
  Push-Location $path
  try {
    jar -xf (Join-Path $root "jre/lib/rt.jar")
    New-Item -ItemType Directory -Path (Join-Path $root "rt_keep_class") -Force | Out-Null
    if(Test-Path $keep_list) {
      Get-Content $keep_list | Where-Object { $_ -notmatch '^#' -and ![string]::IsNullOrWhitespace($_) } | ForEach-Object {
        if(Test-Path "${_}.class") {
          Copy-Item -Path "${_}.class" -Recurse -Destination (Join-Path $root "rt_keep_class")
        }
      }
    }

    if(Test-Path $del_list) {
      Get-Content $del_list | Where-Object { $_ -notmatch '^#' -and ![string]::IsNullOrWhitespace($_) } | ForEach-Object {
        if(Test-Path $_) {
          Remove-Item -Force -Recurse -Path $_
        }
      }
    }
    Copy-Item -Recurse -Force -Path "$(Join-Path $root "rt_keep_class")/*" -Destination .
    Remove-Item -Force -Recurse -Path (Join-Path $root "rt_keep_class")

    # 2.5. Restruct rt.jar
    jar -cfm (Join-Path $root "jre\lib\rt.jar") META-INF/MANIFEST.MF ./*
  } finally {
    Pop-Location
  }
  if(Test-Path $path) {
      Remove-Item -Force -Recurse $path
  }
  Write-Host "done"
}

# Strip the debug info from all jar files
function Strip-Jar() {
  # pack200 is not available from Java 14 onwards
  if($java_major_version -ge 14) {
    return
  }

  # Using pack200 to strip debug info in jars
  Write-Host "INFO: Strip debug info from jar files"
  Get-ChildItem -Recurse -Include *.jar -Path .\* | ForEach-Object {
    Strip-DebugFromJar $_
  }
}

# Remove all debuginfo files
function Remove-DebugInfoFiles() {
  Write-Host -NoNewline "INFO: Removing all .debuginfo files..."
  Get-ChildItem -Path .\* -Include *.debuginfo -Recurse | ForEach-Object {
      Remove-Item -Force $_.FullName
  }
  Write-Host "done"
}

# Remove all src.zip files
function Remove-SrcZipFiles() {
  Write-Host -NoNewline "INFO: Removing all src.zip files..."
  Get-ChildItem -Path .\* -Include *src*zip -Recurse | ForEach-Object {
      Remove-Item -Force $_.FullName
  }
  Write-Host "done"
}

# Remove unnecessary jmod files
function Remove-JmodFiles() {
  $path = Join-Path $target "jmods"
  if(Test-Path $path) {
    Push-Location $path
    try {
        if(Test-Path $del_jmod_list) {
        Get-Content $del_jmod_list | Where-Object { $_ -notmatch '^#' -and ![String]::IsNullOrWhitespace($_) } | ForEach-Object {
            if(Test-Path $_) {
            Remove-Item -Recurse -Force $_
            }
        }
        }
    } finally {
        Pop-Location
    }
  }
}

# Remove unnecessary tools
function Remove-BinFiles() {
  Write-Host -NoNewline "INFO: Trimming bin dir..."
  $path = Join-Path $target "bin"
  if(Test-Path $path) {
    Push-Location $path
    try {
      Get-Content $del_bin_list | Where-Object { $_ -notmatch '^#' -and ![String]::IsNullOrWhitespace($_) } | ForEach-Object {
        if(Test-Path $_) {
          Remove-Item -Recurse -Force $_
        }
      }
    } finally {
        Pop-Location
    }
  }
  Write-Host "done"
}

# Remove unnecessary tools and jars from lib dir
function Remove-LibFiles() {
  Write-Host -NoNewline "INFO: Trimming lib dir..."
  $path = Join-Path $target "lib"
  if(Test-Path $path) {
    Push-Location $path
    try {
      Get-Content $del_lib_list | Where-Object { $_ -notmatch '^#' -and ![String]::IsNullOrWhitespace($_) } | ForEach-Object {
        if(Test-Path $_) {
            Remove-Item -Recurse -Force $_
        }
      }
    } finally {
        Pop-Location
    }
  }
  Write-Host "done"
}

# Create a new target directory and copy over the source contents.
Set-Location $basedir
New-Item -ItemType Directory $target -Force | Out-Null
Write-Host "Copying ${src} to ${target}..."
Copy-Item -Recurse -Force -Path $src\* -Destination $target

Push-Location $target
try{
  $root=Get-Location
  Write-Host "Trimming files..."

  # Remove examples documentation and sources.
  @("demo", "sample", "man") | ForEach-Object {
      if(Test-Path $_) {
          Remove-Item -Recurse -Force -Path $_
      }
  }

  # jre dir may not be present on all builds.
  if(Test-Path (Join-Path $target "jre")) {
    # Trim file in jre dir.
    Trim-JREFiles

    # Trim file in jre/lib dir.
	  Trim-JRELibFiles

    # Trim unneeded rt.jar classes.
    Trim-RTJarClasses
  }

  # Strip all remaining jar files of debug info.
  Strip-Jar

  # Remove all debuginfo files
  Remove-DebugInfoFiles

  # Remove all src.zip files
  Remove-SrcZipFiles

  # Remove unnecessary jmod files
  Remove-JmodFiles

  # Remove unnecessary tools and jars from lib dir
  Remove-LibFiles

  # Remove unnecessary tools
  Remove-BinFiles

  # Remove temp folders
  @((Join-Path $root "jre\lib\slim"), $src) | ForEach-Object {
      if(Test-Path $_) {
          Remove-Item -Force -Recurse $_
      }
  }
} finally {
  Pop-Location
}

Move-Item -Path $target -Destination $src -Force
Set-Location $pwd
Write-Host "Done"
