#!/bin/bash

set -ex

# Tested with 
#   appimagecrafters/appimage-builder
# and
#   centos:centos-7

# config
if [ -z "$GAME_ID" ]; then
    if [ $# -gt 0 ]; then
        export GAME_ID="$1"
    else
        echo "Need GAME_ID set or passed as first argument"
        exit 1
    fi
fi
if [ -z "$GAME_NAME" ]; then
    if [ $# -gt 1 ]; then
        export GAME_NAME="$2"
    else
        echo "Need GAME_NAME set or passed as second argument"
        exit 1
    fi
fi
if [ -z "$GAME_VERSION" ]; then
    if [ $# -gt 2 ]; then
        export GAME_VERSION="$3"
    else
        export GAME_VERSION="$(head -1 debian/changelog | cut -f2 -d' ' | sed 's/(//' | sed 's/)//')"
    fi
fi
export GAME_ARCH=$(uname -m)

CENTOS=`cat /etc/centos-release || true`
if [ -n "$CENTOS" ]; then
    # centos (>= 7) build tools
    yum install -yy centos-release-scl && yum install -yy git devtoolset-7-toolchain
    yum install -yy zlib-devel file
    source /opt/rh/devtoolset-7/enable
    # centos SDL dependencies
    yum install -yy libX11-devel libXext-devel libXrandr-devel libXi-devel libXfixes-devel libXcursor-devel libpng-devel
    yum install -yy pulseaudio-libs-devel
    yum install -yy mesa-libGL-devel
    yum install -yy wayland-devel
else
    export DEBIAN_FRONTEND=noninteractive
    # ubuntu (>= 18.04) build tools
    apt-get update && apt-get install -yy git build-essential cmake wget curl imagemagick
    apt-get install -yy zlib1g-dev file libbz2-dev libpng-dev libopus-dev libtheora-dev
    # ubuntu SDL dependencies
    apt-get install -yy libx11-dev libxext-dev libxrandr-dev libxi-dev libxfixes-dev libxcursor-dev
    apt-get install -yy libpulse-dev
    apt-get install -yy libgl1-mesa-dev libgles2-mesa-dev
    apt-get install -yy libwayland-dev
fi

if [ -n "$CENTOS" ]; then
    # cmake
    curl -L -O https://cmake.org/files/v3.20/cmake-3.20.0.tar.gz
    tar zxf cmake-3.20.0.tar.gz
    pushd cmake-3.20.0
        sed -i 's/cmake_options="-DCMAKE_BOOTSTRAP=1"/cmake_options="-DCMAKE_BOOTSTRAP=1 -DCMAKE_USE_OPENSSL=OFF"/' bootstrap
        ./bootstrap --prefix=/usr/local
        make -j$(nproc)
        make install
        popd
fi

if [ "$GAME_ID" = stargus ]; then
    git clone https://github.com/ladislav-zezula/StormLib
    pushd StormLib
        git checkout v9.25
        cmake CMakeLists.txt
        make -j$(nproc)
        make install
        popd
fi


if [ -n "$GITHUB_REF" ]; then
    git clone https://github.com/Wargus/stratagus
    pushd stratagus
    git fetch origin "${GITHUB_REF}"
    git checkout FETCH_HEAD
fi

git clone --depth 1 https://github.com/Wargus/${GAME_ID}

# pushd stratagus
    git submodule update --init --recursive
    mkdir build
    pushd build
        cmake ..                                                        \
            -DBUILD_VENDORED_LUA=ON                                     \
            -DBUILD_VENDORED_SDL=ON                                     \
            -DBUILD_VENDORED_MEDIA_LIBS=ON                              \
            -DCMAKE_BUILD_TYPE=Release                                  \
            -DCMAKE_INSTALL_PREFIX=/usr                                 \
            -DGAMEDIR=/usr/bin
        make -j$(nproc) install DESTDIR=../AppDir
        popd
#    popd
pushd ${GAME_ID}
    git submodule update --init --recursive
    mkdir build
    pushd build
        cmake ..                                                        \
            -DENABLE_VENDORED_LIBS=ON                                   \
            -DCMAKE_BUILD_TYPE=Release                                  \
            -DSTRATAGUS_INCLUDE_DIR=$PWD/../../gameheaders              \
            -DSTRATAGUS=stratagus                                       \
            -DCMAKE_INSTALL_PREFIX=/usr                                 \
            -DDATA_PATH=../../share/games/stratagus/${GAME_ID}/         \
            -DGAMEDIR=/usr/bin                                          \
            -DICONDIR=/usr/share/pixmaps/                               \
            -DGAMEDIRABS=""
        make -j$(nproc) install DESTDIR=../../AppDir
        if ["$GAME_ID" = stargus]; then
            cp stargus-0.png stargus.png
        fi
        popd
    popd
if [ -n "$CENTOS" ]; then
    # using linuxdeploy
    echo '#!/bin/sh' > AppDir/AppRun
    echo -n 'exec $APPDIR/usr/bin/' >> AppDir/AppRun
    echo -n "${GAME_ID}" >> AppDir/AppRun
    echo -n ' --argv0=$APPDIR/usr/bin/' >> AppDir/AppRun
    echo -n "${GAME_ID}" >> AppDir/AppRun
    echo ' $@' >> AppDir/AppRun
    chmod +x AppDir/AppRun
    cat AppDir/AppRun
    curl -L -O "https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-x86_64.AppImage"
    chmod +x linuxdeploy-x86_64.AppImage
    ./linuxdeploy-x86_64.AppImage --appimage-extract-and-run --appdir AppDir --output appimage
    rm -f ./linuxdeploy-x86_64.AppImage
    if [ -n "$GITHUB_REF" ]; then
        cp *.AppImage "../${GAME_ID}-x86_64.AppImage"
        popd
    fi
else
    # using linuxdeploy
    echo '#!/bin/sh' > AppDir/AppRun
    echo -n 'exec $APPDIR/usr/bin/' >> AppDir/AppRun
    echo -n "${GAME_ID}" >> AppDir/AppRun
    echo -n ' --argv0=$APPDIR/usr/bin/' >> AppDir/AppRun
    echo -n "${GAME_ID}" >> AppDir/AppRun
    echo ' $@' >> AppDir/AppRun
    chmod +x AppDir/AppRun
    cat AppDir/AppRun
    curl -L -O "https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-x86_64.AppImage"
    chmod +x linuxdeploy-x86_64.AppImage
    ./linuxdeploy-x86_64.AppImage --appimage-extract-and-run --appdir AppDir --output appimage
    rm -f ./linuxdeploy-x86_64.AppImage
    if [ -n "$GITHUB_REF" ]; then
        cp *.AppImage "../${GAME_ID}-x86_64.AppImage"
        popd
    fi
fi
