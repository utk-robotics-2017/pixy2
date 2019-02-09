#!/bin/bash

# "set if unset":
# export these in your own ENV to override them
CMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE:-'Debug'} # should be case-insensitive
BUILDDIR=${BUILDDIR:-"build"}

set -E
set +v

while [[ "$1" != "" ]]; do
  case "$1" in
    "--")
      # stop parsing args and let cmake take the rest
      shift
      break
      ;;
    "--scriptdebug")
      set -v
      ;;
    "--clean"|"-c")
      if [ -d "$BUILDDIR" ]; then
        echo "Removing $(pwd)/${BUILDDIR}/"
        rm -r "$(pwd)/${BUILDDIR}/"
      else
        echo "No $(pwd)/${BUILDDIR}/ to remove."
      fi
      ;;
    "--no-cd"|"-n")
      echo "Building project: $(pwd)"
      NO_CD="true"
      ;;
    "--no-build"|"--configure-only")
      EXIT_AFTER_CONFIGURE="yes"
      ;;
    "--production"|"-p")
      echo "Building production executables."
      echo " CMAKE BUILD TYPE -> RELEASE"
      CMAKE_BUILD_TYPE="RELEASE"
      ;;
    "--testing")
      echo "Building debug release with ENABLE_TESTING..."
      CMAKE_BUILD_TYPE="Debug"
      CMAKE_CONFIGURE_OPTS="$CMAKE_CONFIGURE_OPTS -DENABLE_TESTING:BOOL=ON"
      ;;
    "--time"|"-t")
      if command -v /usr/bin/time && [ "$(uname)" == 'Linux' ] ; then
        BUILD_WRAPCOMMAND="/usr/bin/time --verbose "
      else
        echo "/usr/bin/time is not available! using less-cool '$(type time)'"
        BUILD_WRAPCOMMAND="time"
      fi
      ;;
    "--nprocs"|"--nproc"|"-j")
      TABTEAHYNW="$1"
      shift
      if [[ "$1" != "" ]]; then
        nprocs="$1"
      else
        echo -e " \033[0;35m$TABTEAHYNW\033[0;0m requires a number of threads, like make -j N"
        exit 1
      fi
      ;;
    "-h"|"--help")
      while IFS="" read -r line; do printf '%b\n' "$line"; done << EOF
Cmake project build script for linux / compatible Unix.

usage: ./build-linux.sh [options] [--] [extra args passed to cmake]

Creates the build directory.
Sets useful build variables, adds options for others.
Runs Cmake with whatever extra args you gave it after \033[0;35m--\033[0;0m.
Attempts a multithreaded build using your generator.

Cool tips:
  \033[0;35m-- -G "Ninja"\033[0;0m
  \033[0;35m-- -G "Unix Makefiles"\033[0;0m
  \033[0;35m-- -G "YOUR_GENERATOR"\033[0;0m
          If you have ninja installed and want to use it instead of your default
          build generator tool, you can pass that through to cmake.
          Internally, we use \033[0;35mcmake --build .\033[0;0m so you should
          be able to use any generator you have available to cmake.

Overridable Environment Variables:
  \033[0;35mNO_CD\033[0;0m
          If set, acts like the \033[0;35m--no-cd\033[0;0m option was specified.

Options:
  \033[0;35m-h | --help\033[0;0m
          Display this message and exit.
          Mixed short-form options (eg. -cpt) are \033[0;31mNOT\033[0;0m supported.
  \033[0;35m-c | --clean\033[0;0m
          Remove the build folder before starting the build. (rm)
  \033[0;35m-n | --no-cd\033[0;0m
          Do not CD into this scripts' own directory when building.
          (Perform the same build steps on the current directory.)
  \033[0;35m--no-build | --configure-only\033[0;0m
          Prevents running the build step, exit after cmake configures.
  \033[0;35m--testing\033[0;0m
          Sets the Cmake build type to Debug and sets ENABLE_TESTING.
  \033[0;35m-p | --production\033[0;0m
          Sets the Cmake build type to 'RELEASE'
          (Default build type is 'Debug')
  \033[0;35m-t | --time\033[0;0m
          Enables the usage of the 'time' utility around the compilation step.
  \033[0;35m-j N | --nproc N\033[0;0m
          Sets the parallelism flag on the Make tool.
          N: number of threads to use.
          When not specified, attempts to autodetect thread count. (Spare 1)
EOF
      exit 0
      ;;
    *)
      echo "Build Script: Unknown option: $1"
      exit 1
      ;;
  esac
  shift
done

if [ -z "$NO_CD" ]; then
  # push into own dir
  pushd "$(dirname "$0" )"
fi

mkdir -p $BUILDDIR
pushd $BUILDDIR

if [ -z ${MAKEFLAGS+x} ]; then
  nprocs=$(nproc --ignore=1 )
  export MAKEFLAGS="-j${nprocs}"
fi

cleanup() {
  exit $SIGNAL;
}

# catch errors during configure/build steps
trap 'SIGNAL=$?;cleanup' ERR
trap 'cleanup' SIGINT

# build with support commands
CMAKE_CONFIGURE_COMMAND=`cat<< EOF
cmake .. -L \
 -DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE \
 -DCMAKE_EXPORT_COMPILE_COMMANDS=1 \
 ${CMAKE_CONFIGURE_OPTS} \
 $@
EOF
`

CMAKE_BUILD_COMMAND=`cat<< EOF
cmake --build . \
  $CMAKE_BUILD_OPTS
EOF
`

echo "CMake configure being run:"
echo -e "\033[0;96m${CMAKE_CONFIGURE_COMMAND}\033[0;0m"
$CMAKE_CONFIGURE_COMMAND

if [[ "${EXIT_AFTER_CONFIGURE}" =~ ^(yes|exit|true|1)$ ]]; then
  echo -e "CMake \033[0;92mconfigured successfully\033[0;0m, not performing build step."
  exit 0
fi

# echo "Building with $nprocs threads."
echo "CMake build being run:"
echo -e "\033[0;96m${CMAKE_BUILD_COMMAND}\033[0;0m"

make_retval=1
trap '' ERR
${BUILD_WRAPCOMMAND} ${CMAKE_BUILD_COMMAND}
build_retval=$?
trap 'SIGNAL=$?;cleanup' ERR

if [ ${build_retval} -eq 0 ]; then
  echo -e "Build \033[0;92mcompleted.\033[0;0m"
else
  echo -e "\033[0;31m !!! Compilation failed. \033[0m"
  exit $make_retval
fi
