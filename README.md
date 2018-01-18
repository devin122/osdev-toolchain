## Quickstart
``` bash
git clone ttps://github.com/devin122/osdev-toolchain.git`
cd osdev-toolchain
mkdir build
cd build
cmake ../
make
```

## Configuration Variables
- `TOOLCHAIN_DIST_DIR` Directory where source tarballs will be downloaded. Defaults to `${CMAKE_CURRENT_BINARY_DIR}/src/dist`
- `TOOLCHAIN_SRC_ROOT` Directory where sources will be extracted. Defaults to `${CMAKE_CURRENT_BINARY_DIR}/src`
- `TOOLCHAIN_BUILD_ROOT` Directory where the build directories will be placed. Defaults to `${CMAKE_CURRENT_BINARY_DIR}/src/build`
- `TOOLCHAIN_PREFIX` Where the toolchain will be installed. Defaults to `${CMAKE_CURRENT_BINARY_DIR}`
- `TOOLCHAIN_TARGET` What platform the toolchain will target. Defaults to `i686-elf`
