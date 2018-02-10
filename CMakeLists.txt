cmake_minimum_required(VERSION 3.2)

project(osdev-toolchain VERSION 1.0.0 LANGUAGES C CXX)

#setup various directory config options
set(TOOLCHAIN_DIST_DIR "${CMAKE_CURRENT_BINARY_DIR}/src/dist" CACHE PATH "Directory where toolchain source tarballs will be downloaded")
set(TOOLCHAIN_SRC_ROOT "${CMAKE_CURRENT_BINARY_DIR}/src" CACHE PATH "Directory where toochain sources will be extracted")
set(TOOLCHAIN_BUILD_ROOT "${CMAKE_CURRENT_BINARY_DIR}/build" CACHE PATH "Directory where toolchains will be built")


set(TOOLCHAIN_TMP_DIR "${CMAKE_BINARY_DIR}/tmp" CACHE PATH "Directory where temp stuff is put")
set(TOOLCHAIN_STAMP_DIR "${TOOLCHAIN_TMP_DIR}/stamps" CACHE PATH  "Directory where timestamps are put")

set(TOOLCHAIN_INSTALL_DIR "${CMAKE_CURRENT_BINARY_DIR}/toolchain" CACHE PATH "Directory where toolchain binaries will be installed")

set(TOOLCHAIN_TARGET i686-elf CACHE STRING "What architecture you want to target")

set(TOOLCHAIN_TARGETS i686-elf x86_64-elf)


find_program(MAKEINFO_PATH makeinfo)
if(NOT MAKEINFO_PATH)
	message(FATAL_ERROR "makeinfo executable not found. Try installing texinfo package")
endif()

find_program(FLEX_PATH flex)
if(NOT FLEX_PATH)
	message(FATAL_ERROR "flex is required to build binutils/gcc")
endif()

find_program(BISON_PATH bison)
if(NOT BISON_PATH)
	message(FATAL_ERROR "Bison is required to build binutils/gcc")
endif()


set_property(DIRECTORY PROPERTY EP_STEP_TARGETS onfigure build)

include("packages.cmake")
include("AddProject.cmake")



AddProject(gmp)
AddProject(mpfr DEPEND_LIBS gmp)
AddProject(mpc DEPEND_LIBS mpfr gmp)
AddProject(isl DEPEND_LIBS gmp)
#AddProject(nasm)

AddProject(binutils
	MULTI_ARCH
	DEPEND_LIBS
		gmp
	CONFIGURE_ARGS 
		--with-sysroot
		--disable-nls
		--disable-werror
)

AddProject(gcc
	MULTI_ARCH
	DEPENDS
		binutils
	DEPEND_LIBS
		gmp
		mpfr
		mpc
	CONFIGURE_ARGS
		 --disable-nls
		 --enable-languages=c,c++ 
		 --without-headers
	BUILD_TARGETS
		all-gcc
		all-target-libgcc
	INSTALL_TARGETS
		install-gcc
		install-target-libgcc
)

#AddProject(gcc
#[[
ExternalProject_Add( binutils
	URL ${BINUTILS_URL}
	URL_HASH MD5=${BINUTILS_HASH}

	#set up our directories
	TMP_DIR ${TOOLCHAIN_TMP_DIR}
	STAMP_DIR ${TOOLCHAIN_STAMP_ROOT}/binutils-${BINUTILS_VERSION}-stamp
	DOWNLOAD_DIR ${TOOLCHAIN_DIST_DIR}
	SOURCE_DIR ${TOOLCHAIN_SRC_ROOT}/binutils-${BINUTILS_VERSION}
	BINARY_DIR ${TOOLCHAIN_BUILD_ROOT}/binutils-${BINUTILS_VERSION}-${TOOLCHAIN_TARGET}
	INSTALL_DIR ${TOOLCHAIN_INSTALL_DIR}
	CONFIGURE_COMMAND  ${TOOLCHAIN_SRC_ROOT}/binutils-${BINUTILS_VERSION}/configure --prefix=${TOOLCHAIN_INSTALL_DIR} --target=${TOOLCHAIN_TARGET}  --with-sysroot --disable-nls --disable-werror

	BUILD_COMMAND "\$(MAKE)"
)



#we need to call configure with a relative path, otherwise it breaks windows builds
file(RELATIVE_PATH GCC_CONFIG_PATH ${TOOLCHAIN_BUILD_ROOT}/gcc  ${TOOLCHAIN_SRC_ROOT}/gcc-${GCC_VERSION}/configure)

ExternalProject_Add( gcc
	DEPENDS binutils
	URL ${GCC_URL}
	URL_HASH ${GCC_HASH}

	DEPENDS binutils
	#set up our directories
	TMP_DIR ${TOOLCHAIN_TMP_DIR}
	STAMP_DIR ${TOOLCHAIN_STAMP_ROOT}/gcc-stamp
	DOWNLOAD_DIR ${TOOLCHAIN_DIST_DIR}
	SOURCE_DIR ${TOOLCHAIN_SRC_ROOT}/gcc-${GCC_VERSION}
	BINARY_DIR ${TOOLCHAIN_BUILD_ROOT}/gcc-${GCC_VERSION}-${TOOLCHAIN_TARGET}
	INSTALL_DIR ${TOOLCHAIN_INSTALL_DIR}

	PATCH_COMMAND patch -N -p1 < "${CMAKE_CURRENT_SOURCE_DIR}/gcc-6.3.patch"
	CONFIGURE_COMMAND ${GCC_CONFIG_PATH} --prefix=$<SHELL_PATH:${TOOLCHAIN_INSTALL_DIR}> --target=${TOOLCHAIN_TARGET}  --disable-nls  --enable-languages=c,c++ --without-headers
	BUILD_COMMAND "\$(MAKE)" all-gcc all-target-libgcc
	INSTALL_COMMAND make install-gcc install-target-libgcc
)
ExternalProject_Add_Step( gcc download_prerequisites
	COMMAND "${TOOLCHAIN_SRC_ROOT}/gcc-${GCC_VERSION}/contrib/download_prerequisites"
	WORKING_DIRECTORY ${TOOLCHAIN_SRC_ROOT}/gcc-${GCC_VERSION}
	DEPENDEES download
	DEPENDERS configure
	COMMENT "Downloading GCC dependencies"
)


ExternalProject_Add_Step( nasm hack_version
	COMMAND "${CMAKE_COMMAND}" -E copy_if_different "${TOOLCHAIN_SRC_ROOT}/nasm-${NASM_VERSION}/version.mac" .
	WORKING_DIRECTORY ${TOOLCHAIN_BUILD_ROOT}/nasm-${NASM_VERSION}
	DEPENDEES download
	DEPENDERS build
)
]]