include(ExternalProject)

function(AddProject name)

	set(options 
		MULTI_ARCH
	)
	set(oneValueArgs
	)
	set(multiValueArgs 
		DEPEND_LIBS
		DEPENDS
		CONFIGURE_ARGS
		BUILD_TARGETS
		INSTALL_TARGETS
	)
	cmake_parse_arguments(OPT "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN} )

	# build up list of --with-LIBNAME=XYZ configure args
	set(CONFIGURE_LIBS )
	foreach(lib IN LISTS OPT_DEPEND_LIBS)
		list(APPEND CONFIGURE_LIBS "--with-${lib}=${TOOLCHAIN_INSTALL_DIR}")
	endforeach()
	
	# If no install targets set, default to "install"
	if(NOT DEFINED OPT_INSTALL_TARGETS)
		set(OPT_INSTALL_TARGETS "install")
	endif()
	
	string(TOUPPER "${name}" uname)
	set(PROJ_VERSION "${${uname}_VERSION}")
	set(PROJ_SOURCE_DIR "${TOOLCHAIN_SRC_ROOT}/${name}-${PROJ_VERSION}")
	set(PROJ_BINARY_DIR "${TOOLCHAIN_BUILD_ROOT}/${name}-${PROJ_VERSION}")
	set(PROJ_CONFIG_ARGS --prefix=${TOOLCHAIN_INSTALL_DIR} ${CONFIGURE_LIBS} ${OPT_CONFIGURE_ARGS})
	set(PROJ_MAKE_COMMAND "\$(MAKE)" ${OPT_BUILD_TARGETS})
	set(PROJ_INSTALL_COMMAND "\$(MAKE)" ${OPT_INSTALL_TARGETS})
	


	# for GCC we need to call configure with a relative path, otherwise it breaks windows builds
	file(RELATIVE_PATH CONFIG_PATH ${PROJ_BINARY_DIR} ${PROJ_SOURCE_DIR}/configure)

	# If we are building a MULTI_ARCH build a dummy target that only grabs the source
	if(OPT_MULTI_ARCH)
		set(config_command "")
		set(make_command "")
		set(install_command "")
	else()
		set(config_command  ${CONFIG_PATH} ${PROJ_CONFIG_ARGS})
		set(make_command ${PROJ_MAKE_COMMAND})
		set(install_command ${PROJ_INSTALL_COMMAND})
	endif()
	
	ExternalProject_Add( ${name}
		DEPENDS ${OPT_DEPENDS} ${OPT_DEPEND_LIBS}

		URL ${${uname}_URL}
		URL_HASH ${${uname}_HASH}

		#set up our directories
		TMP_DIR ${TOOLCHAIN_TMP_DIR}
		STAMP_DIR ${TOOLCHAIN_STAMP_DIR}
		DOWNLOAD_DIR ${TOOLCHAIN_DIST_DIR}
		SOURCE_DIR ${PROJ_SOURCE_DIR}
		#TODO this is somewhat broken for MULTI_ARCH
		BINARY_DIR ${PROJ_BINARY_DIR}
		INSTALL_DIR ${TOOLCHAIN_INSTALL_DIR}
		
		# Hack to work arround broken arg parsing
		CONFIGURE_COMMAND ""
		BUILD_COMMAND ""
		INSTALL_COMMAND ""

		CONFIGURE_COMMAND ${config_command}
		BUILD_COMMAND ${make_command}
		INSTALL_COMMAND ${install_command}
	)
	
	# if we aren't building MULTI_ARCH we are done here
	if(NOT OPT_MULTI_ARCH)
		return()
	endif()
	
	foreach(arch IN LISTS TOOLCHAIN_TARGETS)
		ExternalProject_Add_Step(${name} ${arch}-mkdir
			COMMAND "${CMAKE_COMMAND}" -E make_directory "$<SHELL_PATH:${PROJ_BINARY_DIR}/${arch}>"
		)
		
		file(RELATIVE_PATH CONFIG_PATH "${PROJ_BINARY_DIR}/${arch}" "${PROJ_SOURCE_DIR}/configure")
		ExternalProject_Add_Step(${name} ${arch}-configure
			DEPENDEES ${arch}-mkdir patch
			DEPENDERS configure
			EXCLUDE_FROM_MAIN 1
			COMMAND "${CONFIG_PATH}" ${PROJ_CONFIG_ARGS} --target=${arch}
			WORKING_DIRECTORY "${PROJ_BINARY_DIR}/${arch}"
		)
		message(STATUS "${name}-${arch} config args = ${PROJ_CONFIG_ARGS}")
		
		ExternalProject_Add_Step(${name} ${arch}-build
			DEPENDEES ${arch}-configure
			DEPENDERS build
			EXCLUDE_FROM_MAIN 1
			COMMAND ${PROJ_MAKE_COMMAND}
			WORKING_DIRECTORY "${PROJ_BINARY_DIR}/${arch}"
		)
		
		ExternalProject_Add_Step(${name} ${arch}-install
			DEPENDEES ${arch}-build
			DEPENDERS install
			EXCLUDE_FROM_MAIN 1
			COMMAND ${PROJ_INSTALL_COMMAND}
			WORKING_DIRECTORY "${PROJ_BINARY_DIR}/${arch}"
		)
		
		ExternalProject_Add_StepTargets(${name} ${arch}-build)
	endforeach()

endfunction(AddProject)