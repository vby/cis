cmake_minimum_required(VERSION 3.3 FATAL_ERROR)

include(CMakeParseArguments)
include(ExternalProject)

macro(_xcm_Append_Option args prefix name default_val)
	if(NOT "${prefix}_${name}")
		list(APPEND args "${name}" "${default_val}")
	else()
		list(APPEND args "${name}" "${${prefix}_${name}}")
	endif()
endmacro()

function(_xcm_External_Boot source_dir_var name ep_base args)
	set(source_dir "${ep_base}/Boot/${name}")
	set(ep_add_args_str "")
	set(key TRUE)
	foreach(arg ${args})
		if(${key}) 
			set(ep_add_args_str "${ep_add_args_str}\t\t${arg}")
			set(key FALSE)
		else()
			set(ep_add_args_str "${ep_add_args_str} \"${arg}\"\n")
			set(key TRUE)
		endif()
	endforeach()
	file(WRITE "${source_dir}/CMakeLists.txt" 
"cmake_minimum_required(VERSION 3.3)\n
project(${name}_boot NONE)\n
include(ExternalProject)
set_property(DIRECTORY PROPERTY EP_BASE \"${ep_base}\")\n 
ExternalProject_Add(\"${name}\" 
${ep_add_args_str}\t)
")
	set(${source_dir_var} ${source_dir} PARENT_SCOPE)
endfunction()

# xcm_Find_Libraries(
#		<VAR>
#		PATHS path1 [path2 ...]
#		[PATH_SUFFIXES suffix1 [suffix2 ...]]
#		[EXTENTIONS extension1 [extension2 ...]]
#		[NO_DEFAULT_PATH_SUFFIXES]
#		[NO_PATH_ROOT]
#		[NO_DEFAULT_EXTENTIONS]
#		[NAME name]
#		[NO_NAME_PATH_SUFFIX]
#		[NO_LEFT_NAME_PATH_SUFFIXES]
#		[NO_RIGHT_NAME_PATH_SUFFIXES]
#		[NO_LEFT_RIGHT_NAME_PATH_SUFFIXES]
#		)
function(xcm_Find_Libraries locations_var)
	set(opt_args 
			NO_DEFAULT_PATH_SUFFIXES 
			NO_PATH_ROOT
			NO_DEFAULT_EXTENTIONS
			NO_NAME_PATH_SUFFIX 
			NO_LEFT_NAME_PATH_SUFFIXES 
			NO_RIGHT_NAME_PATH_SUFFIXES 
			NO_LEFT_RIGHT_NAME_PATH_SUFFIXES
		)
	set(s_args NAME)
	set(m_args PATHS PATH_SUFFIXES EXTENTIONS)
	cmake_parse_arguments(arg "${opt_args}" "${s_args}" "${m_args}" ${ARGN})

	set(path_suffixes ${arg_PATH_SUFFIXES})
	if(NOT ${arg_NO_DEFAULT_PATH_SUFFIXES})
		list(APPEND path_suffixes lib share)
		if(CMAKE_LIBRARY_ARCHITECTURE)
			list(APPEND path_suffixes "lib/${CMAKE_LIBRARY_ARCHITECTURE}")
		endif()
	endif()

	if(DEFINED arg_NAME)
		if(NOT ${arg_NO_NAME_PATH_SUFFIX})
			set(name_path_suffixes "${name}*")
		endif()
		foreach(path_suffix ${path_suffixes})
			if(NOT ${arg_NO_LEFT_NAME_PATH_SUFFIXES})
				list(APPEND name_path_suffixes "${name}*/${path_suffix}")
			endif()
			if(NOT ${arg_NO_RIGHT_NAME_PATH_SUFFIXES})
				list(APPEND name_path_suffixes "${path_suffix}/${name}*")
			endif()
			if(NOT ${arg_NO_LEFT_RIGHT_NAME_PATH_SUFFIXES})
				list(APPEND name_path_suffixes "${name}*/${path_suffix}/${name}*")
			endif()
		endforeach()
		list(APPEND path_suffixes ${name_path_suffixes})
	endif()

	set(paths)
	if(NOT ${arg_NO_PATH_ROOT})
		list(APPEND paths "${path}")
	endif()
	foreach(path ${arg_PATHS})
		foreach(path_suffix ${path_suffixes})
			list(APPEND paths "${path}/${path_suffix}")
		endforeach()
	endforeach()

	set(exts ${arg_EXTENTIONS})
	if(NOT ${arg_NO_DEFAULT_EXTENTIONS})
		list(APPEND exts .a .so .lib .dll)
	endif()

	set(globs)
	foreach(path ${paths})
		foreach(ext ${exts})
			list(APPEND globs "${path}/*${ext}")
		endforeach()
	endforeach()

	file(GLOB locations LIST_DIRECTORIES false ${globs})
	set(${locations_var} ${locations} PARENT_SCOPE)
endfunction()

# xcm_Traits_Library(<VAR> <path>)
function(xcm_Traits_Library var path)
	get_filename_component(filename ${path} NAME)
	get_filename_component(filename_ext ${filename} EXT)
	if("${filename_ext}" STREQUAL ".a")
		set(types STATIC)
		set(name_reg "lib([^.]+).*")
	elseif("${filename_ext}" STREQUAL ".so")
		set(types SHARED)
		set(name_reg "lib([^.]+).*")
	elseif("${filename_ext}" STREQUAL ".lib")
		set(types STATIC SHARED)
		set(name_reg "([^.]+).*")
	elseif("${filename_ext}" STREQUAL ".dll")
		set(types MODULE)
		set(name_reg "([^.]+).*")
	elseif("${filename_ext}" STREQUAL ".o" OR "${filename_ext}" STREQUAL ".obj")
		set(types OBJECT)
		set(name_reg "([^.]+).*")
	else()
		set(types UNKNOWN)
		set(name_reg "([^.]+).*")
	endif()
	string(REGEX REPLACE "${name_reg}" "\\1" lib_name ${filename})
	set("${var}_NAME" "${lib_name}" PARENT_SCOPE) 
	set("${var}_TYPES" "${types}" PARENT_SCOPE)
endfunction()

# xcm_Import_Library(
#		<name> 
#		<SHARED|STATIC|INTERFACE|OBJECT|MODULE|UNKNOWN> 
#		[LOCATION location]
#		[INCLUDE_DIRECTORIES inc_dir1 [inc_dir2 ...]]
#		[NO_GLOBAL]
#		)
function(xcm_Import_Library name type)
	cmake_parse_arguments(arg "NO_GLOBAL" "LOCATION" "INCLUDE_DIRECTORIES" ${ARGN})
	if(${arg_NO_GLOBAL})
		add_library("${name}" ${type} IMPORTED)
	else()
		add_library("${name}" ${type} IMPORTED GLOBAL)
	endif()
	if(DEFINED arg_LOCATION)
		set_target_properties("${name}" PROPERTIES IMPORTED_LOCATION "${arg_LOCATION}")
	endif()
	if(NOT ("${arg_INCLUDE_DIRECTORIES}" STREQUAL ""))
		set_target_properties("${name}" PROPERTIES INTERFACE_INCLUDE_DIRECTORIES "${arg_INCLUDE_DIRECTORIES}")
	endif()
endfunction()

function(_xcm_External_Import_Library namespace name type)
	cmake_parse_arguments(arg "" "LOCATION" "INCLUDE_DIRECTORIES" ${ARGN})
	if("${name}" STREQUAL "")
		set(target "${namespace}-${type}")
	else()
		set(target "${namespace}::${name}-${type}")
	endif()
	if(TARGET "${target}")
		get_target_property(location "${target}" IMPORTED_LOCATION)
		if(NOT ${location})
			get_target_property(location "${target}" LOCATION)
		endif()
		message(STATUS "Failed to import ${target}: ${arg_LOCATION}")
		message(STATUS "* ${target}: ${location}")
		return()
	endif()
	xcm_Import_Library("${target}" "${type}" ${ARGN})
	set_property(GLOBAL APPEND PROPERTY xcm_External_Library_Targets "${target}")
	set_property(GLOBAL PROPERTY "xcm_External_Target_${target}_Namespace" "${namespace}")
	set_property(GLOBAL PROPERTY "xcm_External_Target_${target}_Name" "${name}")
	if(DEFINED arg_LOCATION)
		message(STATUS "Import ${target}: ${arg_LOCATION}")
	else()
		message(STATUS "Import ${target}: ${arg_INCLUDE_DIRECTORIES}")
	endif()
endfunction()

# xcm_External_Import_Libraries(
#		<path>
#		<name>
#		[... pass to xcm_Find_Libraries]
#		)
function(xcm_External_Import_Libraries path name)
	xcm_Find_Libraries(locations PATHS "${path}" NAME "${name}" ${ARGN})
	if(EXISTS "${path}/include")
		set(inc_dirs "${path}/include")
	endif()
	foreach(location ${locations})
		xcm_Traits_Library(lib "${location}")
		foreach(type ${lib_TYPES})
			_xcm_External_Import_Library("${name}" "${lib_NAME}" "${type}" 
					LOCATION "${location}" INCLUDE_DIRECTORIES ${inc_dirs})
		endforeach()
	endforeach()
	_xcm_External_Import_Library("${name}" "" INTERFACE
			INCLUDE_DIRECTORIES ${inc_dirs})
endfunction()

function(xcm_Build_CMake_Project name source_dir binary_dir)
	execute_process(
			COMMAND ${CMAKE_COMMAND} "${source_dir}"
			WORKING_DIRECTORY "${binary_dir}"
			OUTPUT_FILE "${name}-configure-out.log"
			ERROR_FILE "${name}-configrue-err.log" 
			RESULT_VARIABLE error_code
		)
	if(error_code)
		message(FATAL_ERROR "Failed to configure \"${source_dir}\" See also \"${binary_dir}/${name}-configure-*.log\".")
	endif()
	execute_process(
			COMMAND ${CMAKE_COMMAND} --build "${binary_dir}"
			WORKING_DIRECTORY "${binary_dir}"
			OUTPUT_FILE "${name}-build-out.log"
			ERROR_FILE "${name}-build-err.log" 
			RESULT_VARIABLE error_code
		)
	if(error_code)
		message(FATAL_ERROR "Failed to build \"${source_dir}\" See also \"${binary_dir}/${name}-build-*.log\".")
	endif()
endfunction()

# xcm_External_Add => ExternalProject_Add
function(xcm_External_Add name)
	set(sargs GIT_SHALLOW GIT_PROGRESS LOG_DOWNLOAD UPDATE_DISCONNECTED)
	set(margs LIBRARY)
	cmake_parse_arguments(arg "" "${sargs}" "${margs}" ${ARGN})

	set(args ${arg_UNPARSED_ARGUMENTS})
	_xcm_Append_Option(args arg GIT_SHALLOW TRUE)
	_xcm_Append_Option(args arg GIT_PROGRESS TRUE)
	_xcm_Append_Option(args arg LOG_DOWNLOAD TRUE)
	_xcm_Append_Option(args arg UPDATE_DISCONNECTED TRUE)

	set(ep_base "${CMAKE_BINARY_DIR}/external")
	set(install_path "${ep_base}/Install/${name}")
	list(APPEND args CMAKE_ARGS "-DCMAKE_INSTALL_PREFIX=${install_path}")

	_xcm_External_Boot(source_dir "${name}" "${ep_base}" "${args}")
	message(STATUS "Building ${name}: ${ep_base}/Source/${name}")
	xcm_Build_CMake_Project("${name}" "${source_dir}" "${source_dir}")
	message(STATUS "Building ${name} done")
	xcm_External_Import_Libraries("${install_path}" "${name}")
endfunction()

# xcm_External_Get_Libraries(
#		<VAR> 
#		[STATIC|SHARED|INTERFACE|MODULE ...]
#		[NAMESPACES ns1 [ns2 ...]]
#		[EXCLUDE_NAMESPACES ns1 [ns2 ...]]
#		[NAMES ns1::name1 [ns2::name2 ...]]
#		[EXCLUDE_NAMES ns1::name1 [ns2::name2 ...]]
#		)
function(xcm_External_Get_Libraries libs_var)
	set(opt_args STATIC SHARED INTERFACE)
	set(m_args NAMESPACES EXCLUDE_NAMESPACES NAMES EXCLUDE_NAMES)
	cmake_parse_arguments(arg "${opt_args}" "" "${m_args}" ${ARGN})

	set(types)
	if(${arg_STATIC})
		list(APPEND types STATIC_LIBRARY)
	endif()
	if(${arg_SHARED})
		list(APPEND types SHARED_LIBRARY)
	endif()
	if(${arg_INTERFACE})
		list(APPEND types INTERFACE_LIBRARY)
	endif()
	if(${arg_MODULE})
		list(APPEND types MODULE_LIBRARY)
	endif()

	foreach(name ${arg_NAMES})
		string(REPLACE "::" ";" ns_name "${name}")
		list(GET ns_name 0 ns)
		list(APPEND names_namespaces "${ns}")
	endforeach()
	if(NOT ("${names_namespaces}" STREQUAL ""))
		list(REMOVE_DUPLICATES names_namespaces)
	endif()

	get_property(targets GLOBAL PROPERTY xcm_External_Library_Targets)
	foreach(target ${targets})
		if(NOT ("${types}" STREQUAL ""))
			get_property(type TARGET "${target}" PROPERTY TYPE)
			if(NOT (type IN_LIST types))
				continue()
			endif()
		endif()

		get_property(ns GLOBAL PROPERTY "xcm_External_Target_${target}_Namespace")
		get_property(name GLOBAL PROPERTY "xcm_External_Target_${target}_Name")
		if("${name}" STREQUAL "")
			set(ns_name "${ns}")
		else()
			set(ns_name "${ns}::${name}")
		endif()

		if(ns IN_LIST names_namespaces)
			if(ns_name IN_LIST arg_NAMES)
				list(APPEND libs "${target}")
			endif()
			continue()
		elseif(ns_name IN_LIST arg_EXCLUDE_NAMES)
			continue()
		endif()

		if(NOT ("${arg_NAMESPACES}" STREQUAL "") AND NOT (ns IN_LIST arg_NAMESPACES))
			continue()
		elseif(ns IN_LIST arg_EXCLUDE_NAMESPACES)
			continue()
		endif()
		list(APPEND libs "${target}")
	endforeach()
	set("${libs_var}" ${libs} PARENT_SCOPE)
endfunction()

# xcm_External_Link_Libraries(
#		<target> 
#		[STATIC|SHARED|INTERFACE|MODULE ...]
#		[NAMESPACES ns1 [ns2 ...]]
#		[EXCLUDE_NAMESPACES ns1 [ns2 ...]]
#		[NAMES ns1::name1 [ns2::name2 ...]]
#		[EXCLUDE_NAMES ns1::name1 [ns2::name2 ...]]
#		)
function(xcm_External_Link_Libraries target)
	xcm_External_Get_Libraries(libs ${ARGN})
	target_link_libraries(${target} ${libs})
endfunction()
