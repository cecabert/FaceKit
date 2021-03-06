include(${PROJECT_SOURCE_DIR}/cmake/facekit_utils.cmake)

###############################################################################
# Add an option to build a subsystem or not.
# _var The name of the variable to store the option in.
# _name The name of the option's target subsystem.
# _desc The description of the subsystem.
# _default The default value (TRUE or FALSE)
# ARGV5 The reason for disabling if the default is FALSE.
macro(FACEKIT_SUBSYS_OPTION _var _name _desc _default)
    set(_opt_name "BUILD_${_name}")
    FACEKIT_GET_SUBSYS_HYPERSTATUS(subsys_status ${_name})
    if(NOT ("${subsys_status}" STREQUAL "AUTO_OFF"))
      option(${_opt_name} ${_desc} ${_default})
      if((NOT ${_default} AND NOT ${_opt_name}) OR ("${_default}" STREQUAL "AUTO_OFF"))
        set(${_var} FALSE)
        if(${ARGC} GREATER 4)
          set(_reason ${ARGV4})
        else(${ARGC} GREATER 4)
          set(_reason "Disabled by default.")
        endif(${ARGC} GREATER 4)
        FACEKIT_SET_SUBSYS_STATUS(${_name} FALSE ${_reason})
        FACEKIT_DISABLE_DEPENDIES(${_name})
      elseif(NOT ${_opt_name})
        set(${_var} FALSE)
        FACEKIT_SET_SUBSYS_STATUS(${_name} FALSE "Disabled manually.")
        FACEKIT_DISABLE_DEPENDIES(${_name})
      else(NOT ${_default} AND NOT ${_opt_name})
        set(${_var} TRUE)
        FACEKIT_SET_SUBSYS_STATUS(${_name} TRUE)
        FACEKIT_ENABLE_DEPENDIES(${_name})
      endif((NOT ${_default} AND NOT ${_opt_name}) OR ("${_default}" STREQUAL "AUTO_OFF"))
    endif(NOT ("${subsys_status}" STREQUAL "AUTO_OFF"))
    FACEKIT_ADD_SUBSYSTEM(${_name} ${_desc})
endmacro(FACEKIT_SUBSYS_OPTION)

###############################################################################
# Add an option to build a subsystem or not.
# _var The name of the variable to store the option in.
# _parent The name of the parent subsystem
# _name The name of the option's target subsubsystem.
# _desc The description of the subsubsystem.
# _default The default value (TRUE or FALSE)
# ARGV5 The reason for disabling if the default is FALSE.
macro(FACEKIT_SUBSUBSYS_OPTION _var _parent _name _desc _default)
  set(_opt_name "BUILD_${_parent}_${_name}")
  FACEKIT_GET_SUBSYS_HYPERSTATUS(parent_status ${_parent})
  if(NOT ("${parent_status}" STREQUAL "AUTO_OFF") AND NOT ("${parent_status}" STREQUAL "OFF"))
    FACEKIT_GET_SUBSYS_HYPERSTATUS(subsys_status ${_parent}_${_name})
    if(NOT ("${subsys_status}" STREQUAL "AUTO_OFF"))
      option(${_opt_name} ${_desc} ${_default})
      if((NOT ${_default} AND NOT ${_opt_name}) OR ("${_default}" STREQUAL "AUTO_OFF"))
        set(${_var} FALSE)
        if(${ARGC} GREATER 5)
          set(_reason ${ARGV5})
        else(${ARGC} GREATER 5)
          set(_reason "Disabled by default.")
        endif(${ARGC} GREATER 5)
        FACEKIT_SET_SUBSYS_STATUS(${_parent}_${_name} FALSE ${_reason})
        FACEKIT_DISABLE_DEPENDIES(${_parent}_${_name})
      elseif(NOT ${_opt_name})
        set(${_var} FALSE)
        FACEKIT_SET_SUBSYS_STATUS(${_parent}_${_name} FALSE "Disabled manually.")
        FACEKIT_DISABLE_DEPENDIES(${_parent}_${_name})
      else(NOT ${_default} AND NOT ${_opt_name})
        set(${_var} TRUE)
        FACEKIT_SET_SUBSYS_STATUS(${_parent}_${_name} TRUE)
        FACEKIT_ENABLE_DEPENDIES(${_parent}_${_name})
      endif((NOT ${_default} AND NOT ${_opt_name}) OR ("${_default}" STREQUAL "AUTO_OFF"))
    endif(NOT ("${subsys_status}" STREQUAL "AUTO_OFF"))
  endif(NOT ("${parent_status}" STREQUAL "AUTO_OFF") AND NOT ("${parent_status}" STREQUAL "OFF"))
  FACEKIT_ADD_SUBSUBSYSTEM(${_parent} ${_name} ${_desc})
endmacro(FACEKIT_SUBSUBSYS_OPTION)

###############################################################################
# Make one subsystem depend on one or more other subsystems, and disable it if
# they are not being built.
# _var The cumulative build variable. This will be set to FALSE if the
#   dependencies are not met.
# _name The name of the subsystem.
# ARGN The subsystems and external libraries to depend on.
macro(FACEKIT_SUBSYS_DEPEND _var _name)
    set(options)
    set(oneValueArgs)
    set(multiValueArgs DEPS EXT_DEPS OPT_DEPS)
    cmake_parse_arguments(SUBSYS "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN} )
    if(SUBSYS_DEPS)
        SET_IN_GLOBAL_MAP(FACEKIT_SUBSYS_DEPS ${_name} "${SUBSYS_DEPS}")
    endif(SUBSYS_DEPS)
    if(SUBSYS_EXT_DEPS)
        SET_IN_GLOBAL_MAP(FACEKIT_SUBSYS_EXT_DEPS ${_name} "${SUBSYS_EXT_DEPS}")
    endif(SUBSYS_EXT_DEPS)
    if(SUBSYS_OPT_DEPS)
        SET_IN_GLOBAL_MAP(FACEKIT_SUBSYS_OPT_DEPS ${_name} "${SUBSYS_OPT_DEPS}")
    endif(SUBSYS_OPT_DEPS)
    GET_IN_MAP(subsys_status FACEKIT_SUBSYS_HYPERSTATUS ${_name})
    if(${_var} AND (NOT ("${subsys_status}" STREQUAL "AUTO_OFF")))
        if(SUBSYS_DEPS)
        foreach(_dep ${SUBSYS_DEPS})
            FACEKIT_GET_SUBSYS_STATUS(_status ${_dep})
            if(NOT _status)
                set(${_var} FALSE)
                FACEKIT_SET_SUBSYS_STATUS(${_name} FALSE "Requires ${_dep}.")
            else(NOT _status)
                FACEKIT_GET_SUBSYS_INCLUDE_DIR(_include_dir ${_dep})
                STRING(REGEX MATCH "(.?cuda_)" match ${_include_dir})
                # Not needed anymore with CMake targets
                # IF(match)
                #     STRING(REGEX REPLACE "^([^_]*)\\_(.*)" "\\1/\\2" _cuda_include_dir ${_include_dir})
                #     include_directories(${PROJECT_SOURCE_DIR}/modules/${_cuda_include_dir}/include)
                # ELSE(match)
                #     include_directories(${PROJECT_SOURCE_DIR}/modules/${_include_dir}/include)
                # ENDIF(match)
            endif(NOT _status)
        endforeach(_dep)
        endif(SUBSYS_DEPS)
        if(SUBSYS_EXT_DEPS)
        foreach(_dep ${SUBSYS_EXT_DEPS})
            string(TOUPPER "${_dep}_found" EXT_DEP_FOUND)
            if(NOT ${EXT_DEP_FOUND} OR (NOT (${EXT_DEP_FOUND} STREQUAL "TRUE")))
                set(${_var} FALSE)
                FACEKIT_SET_SUBSYS_STATUS(${_name} FALSE "Requires external library ${_dep}.")
            endif(NOT ${EXT_DEP_FOUND} OR (NOT (${EXT_DEP_FOUND} STREQUAL "TRUE")))
        endforeach(_dep)
        endif(SUBSYS_EXT_DEPS)
    endif(${_var} AND (NOT ("${subsys_status}" STREQUAL "AUTO_OFF")))
endmacro(FACEKIT_SUBSYS_DEPEND)

###############################################################################
# Make one subsystem depend on one or more other subsystems, and disable it if
# they are not being built.
# _var The cumulative build variable. This will be set to FALSE if the
#   dependencies are not met.
# _parent The parent subsystem name.
# _name The name of the subsubsystem.
# ARGN The subsystems and external libraries to depend on.
# macro(FACEKIT_SUBSUBSYS_DEPEND _var _parent _name)
#     set(options)
#     set(parentArg)
#     set(nameArg)
#     set(multiValueArgs DEPS EXT_DEPS OPT_DEPS)
#     cmake_parse_arguments(SUBSYS "${options}" "${parentArg}" "${nameArg}" "${multiValueArgs}" ${ARGN} )
#     if(SUBSUBSYS_DEPS)
#         SET_IN_GLOBAL_MAP(FACEKIT_SUBSYS_DEPS ${_parent}_${_name} "${SUBSUBSYS_DEPS}")
#     endif(SUBSUBSYS_DEPS)
#     if(SUBSUBSYS_EXT_DEPS)
#         SET_IN_GLOBAL_MAP(FACEKIT_SUBSYS_EXT_DEPS ${_parent}_${_name} "${SUBSUBSYS_EXT_DEPS}")
#     endif(SUBSUBSYS_EXT_DEPS)
#     if(SUBSUBSYS_OPT_DEPS)
#         SET_IN_GLOBAL_MAP(FACEKIT_SUBSYS_OPT_DEPS ${_parent}_${_name} "${SUBSUBSYS_OPT_DEPS}")
#     endif(SUBSUBSYS_OPT_DEPS)
#     GET_IN_MAP(subsys_status FACEKIT_SUBSYS_HYPERSTATUS ${_parent}_${_name})
#     if(${_var} AND (NOT ("${subsys_status}" STREQUAL "AUTO_OFF")))
#         if(SUBSUBSYS_DEPS)
#         foreach(_dep ${SUBSUBSYS_DEPS})
#             FACEKIT_GET_SUBSYS_STATUS(_status ${_dep})
#             if(NOT _status)
#                 set(${_var} FALSE)
#                 FACEKIT_SET_SUBSYS_STATUS(${_parent}_${_name} FALSE "Requires ${_dep}.")
#             else(NOT _status)
#                 FACEKIT_GET_SUBSYS_INCLUDE_DIR(_include_dir ${_dep})
#                 include_directories(${PROJECT_SOURCE_DIR}/${_include_dir}/include)
#             endif(NOT _status)
#         endforeach(_dep)
#         endif(SUBSUBSYS_DEPS)
#         if(SUBSUBSYS_EXT_DEPS)
#         foreach(_dep ${SUBSUBSYS_EXT_DEPS})
#             string(TOUPPER "${_dep}_found" EXT_DEP_FOUND)
#             if(NOT ${EXT_DEP_FOUND} OR (NOT ("${EXT_DEP_FOUND}" STREQUAL "TRUE")))
#                 set(${_var} FALSE)
#                 FACEKIT_SET_SUBSYS_STATUS(${_parent}_${_name} FALSE "Requires external library ${_dep}.")
#             endif(NOT ${EXT_DEP_FOUND} OR (NOT ("${EXT_DEP_FOUND}" STREQUAL "TRUE")))
#         endforeach(_dep)
#         endif(SUBSUBSYS_EXT_DEPS)
#     endif(${_var} AND (NOT ("${subsys_status}" STREQUAL "AUTO_OFF")))
# endmacro(FACEKIT_SUBSUBSYS_DEPEND)

###############################################################################
# Add a set of include files to install.
# _component The part of FACEKIT that the install files belong to.
# _subdir The sub-directory for these include files.
# ARGN The include files.
macro(FACEKIT_ADD_INCLUDES _component _subdir)
    install(FILES ${ARGN} 
            DESTINATION ${INCLUDE_INSTALL_DIR}/${_subdir}
            COMPONENT facekit_${_component})
endmacro(FACEKIT_ADD_INCLUDES)


###############################################################################
# Add a library target.
# _name The library name.
# _component The part of FACEKIT that this library belongs to.
# 
# ARGN:
#   FILES       The source files for the library.
#   PROTO_FILES The protobuf files that need to be generated
#   PUBLIC_LINK    List Of library to link against (PUBLIC)
#   PRIVATE_LINK    List Of library to link against (PRIVATE)
macro(FACEKIT_ADD_LIBRARY _name _component)
  # parse arguments
  SET(options)
  SET(oneValueArgs)
  SET(multiValueArgs FILES PROTO_FILES PUBLIC_LINK PRIVATE_LINK)
  cmake_parse_arguments(FACEKIT_ADD_LIBRARY "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN} )
  # Check if protobuf class need to be generated
  SET(PROTO_GEN_FILES)
  IF(FACEKIT_ADD_LIBRARY_PROTO_FILES)
    # Generate files
    PROTOBUF_GENERATE_CPP(PROTO_SRCS PROTO_HDRS ${FACEKIT_ADD_LIBRARY_PROTO_FILES})
    # Copy to <build>/proto
    FOREACH(_f ${PROTO_SRCS} ${PROTO_HDRS})
      GET_FILENAME_COMPONENT(_fname ${_f} NAME)
      GET_FILENAME_COMPONENT(_folder ${_f} DIRECTORY)
      SET(_dest_file "${FACEKIT_OUTPUT_PROTO_DIR}/${_fname}")
      ADD_CUSTOM_COMMAND(OUTPUT ${_dest_file}
                         COMMAND ${CMAKE_COMMAND} -E copy ${_f} ${_dest_file}
                         DEPENDS ${_f}
                         COMMENT "Copying generated protobuf file ${_fname}"
                         VERBATIM)
                         SET(PROTO_GEN_FILES ${PROTO_GEN_FILES} ${_dest_file})
    ENDFOREACH()
  ENDIF()
  # Create libbrary
  ADD_LIBRARY(${_name} ${FACEKIT_LIB_TYPE} ${FACEKIT_ADD_LIBRARY_FILES} ${PROTO_GEN_FILES})
  TARGET_INCLUDE_DIRECTORIES(${_name} PRIVATE ${FACEKIT_OUTPUT_PROTO_DIR})
  # Add link
  TARGET_LINK_LIBRARIES(${_name} PUBLIC ${FACEKIT_ADD_LIBRARY_PUBLIC_LINK} PRIVATE ${FACEKIT_ADD_LIBRARY_PRIVATE_LINK})

  IF((UNIX AND NOT ANDROID) OR MINGW)
    TARGET_LINK_LIBRARIES(${_name} PRIVATE m)
  ENDIF()

  IF (MINGW)
    TARGET_LINK_LIBRARIES(${_name} PRIVATE gomp)
  ENDIF()
  IF(MSVC)
    TARGET_LINK_LIBRARIES(${_name} PRIVATE delayimp.lib)  # because delay load is enabled for openmp.dll
  ENDIF()

  SET_TARGET_PROPERTIES(${_name} PROPERTIES
    VERSION ${FACEKIT_VERSION}
    SOVERSION ${FACEKIT_MAJOR_VERSION}.${FACEKIT_MINOR_VERSION})

  install(TARGETS ${_name}
    EXPORT facekit-export
    RUNTIME DESTINATION ${BIN_INSTALL_DIR} COMPONENT facekit_${_component}
    LIBRARY DESTINATION ${LIB_INSTALL_DIR} COMPONENT facekit_${_component}
    ARCHIVE DESTINATION ${LIB_INSTALL_DIR} COMPONENT facekit_${_component})
endmacro(FACEKIT_ADD_LIBRARY)


###############################################################################
# Add a cuda library target.
# _name The library name.
# _component The part of FACEKIT that this library belongs to.
# ARGN The source files for the library.
macro(FACEKIT_CUDA_ADD_LIBRARY _name _component)
    REMOVE_VTK_DEFINITIONS()
    if(FACEKIT_SHARED_LIBS)
      # to overcome a limitation in cuda_add_library, we add manually FACEKITAPI_EXPORTS macro
      cuda_add_library(${_name} ${FACEKIT_LIB_TYPE} ${ARGN} OPTIONS -DFACEKITAPI_EXPORTS)
    else(FACEKIT_SHARED_LIBS)
      cuda_add_library(${_name} ${FACEKIT_LIB_TYPE} ${ARGN})
    endif(FACEKIT_SHARED_LIBS)

    set_target_properties(${_name} PROPERTIES
      VERSION ${FACEKIT_VERSION}
      SOVERSION ${FACEKIT_MAJOR_VERSION})

    install(TARGETS ${_name}
      EXPORT facekit-export
      RUNTIME DESTINATION ${BIN_INSTALL_DIR} COMPONENT facekit_${_component}
      LIBRARY DESTINATION ${LIB_INSTALL_DIR} COMPONENT facekit_${_component}
      ARCHIVE DESTINATION ${LIB_INSTALL_DIR} COMPONENT facekit_${_component})
endmacro(FACEKIT_CUDA_ADD_LIBRARY)


###############################################################################
# Add an executable target.
# _name The executable name.
# _component The part of FACEKIT that this library belongs to.
# ARGN the source files for the library.
macro(FACEKIT_ADD_EXECUTABLE _name _component)
  add_executable(${_name} ${ARGN})
  if(WIN32 AND MSVC)
    set_target_properties(${_name} PROPERTIES DEBUG_OUTPUT_NAME ${_name}${CMAKE_DEBUG_POSTFIX}
                                              RELEASE_OUTPUT_NAME ${_name}${CMAKE_RELEASE_POSTFIX})
  endif()

  set(FACEKIT_EXECUTABLES ${FACEKIT_EXECUTABLES} ${_name})
  install(TARGETS ${_name} RUNTIME DESTINATION ${BIN_INSTALL_DIR}
      COMPONENT facekit_${_component})
endmacro(FACEKIT_ADD_EXECUTABLE)

###############################################################################
# Add an executable target.
# _name The executable name.
# _component The part of FACEKIT that this library belongs to.
# ARGN the source files for the library.
macro(FACEKIT_CUDA_ADD_EXECUTABLE _name _component)
  # Add executable
  cuda_add_executable(${_name} ${ARGN})
  if(WIN32 AND MSVC)
    set_target_properties(${_name} PROPERTIES DEBUG_OUTPUT_NAME ${_name}${CMAKE_DEBUG_POSTFIX}
                                              RELEASE_OUTPUT_NAME ${_name}${CMAKE_RELEASE_POSTFIX})
  endif()

  set(FACEKIT_EXECUTABLES ${FACEKIT_EXECUTABLES} ${_name})
  install(TARGETS ${_name} RUNTIME DESTINATION ${BIN_INSTALL_DIR}
      COMPONENT facekit_${_component})
endmacro(FACEKIT_CUDA_ADD_EXECUTABLE)

###############################################################################
# Add a test target.
# _name The test name.
# _exename The exe name.
# ARGN :
#    FILES the source files for the test
#    ARGUMENTS Arguments for test executable
#    LINK_WITH link test executable with libraries
#    INC_FOLDER Extra include folder
macro(FACEKIT_ADD_TEST _name _exename)
    set(options)
    set(oneValueArgs)
    set(multiValueArgs FILES ARGUMENTS WORKING_DIR LINK_WITH INC_FOLDER)
    cmake_parse_arguments(FACEKIT_ADD_TEST "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN} )
    # Add google test framework if not already build
    IF(NOT TARGET google::gtest)
      ADD_SUBDIRECTORY(${FACEKIT_SOURCE_DIR}/3rdparty/gtest ${FACEKIT_OUTPUT_3RDPARTY_LIB_DIR}/google EXCLUDE_FROM_ALL)
      MARK_AS_ADVANCED(BUILD_GMOCK BUILD_GTEST BUILD_SHARED_LIBS INSTALL_GTEST INSTALL_GMOCK gmock_build_tests gtest_build_samples gtest_build_tests
                       gtest_disable_pthreads gtest_force_shared_crt gtest_hide_internal_symbols)
    ENDIF(NOT TARGET google::gtest)
    # Add test executable
    add_executable(facekit_ut_${_exename} ${FACEKIT_ADD_TEST_FILES})
    # Add folder where proto files are generated
    target_include_directories(facekit_ut_${_exename} 
      PRIVATE 
        ${FACEKIT_OUTPUT_PROTO_DIR} 
        $<TARGET_PROPERTY:google::gtest,INCLUDE_DIRECTORIES>
        $<TARGET_PROPERTY:google::gmock,INCLUDE_DIRECTORIES>
        ${FACEKIT_ADD_TEST_INC_FOLDER})
    # Link extra library
    target_link_libraries(facekit_ut_${_exename} PRIVATE ${FACEKIT_ADD_TEST_LINK_WITH} google::gtest google::gmock ${CLANG_LIBRARIES})
    # Only link if needed
    if(CMAKE_SYSTEM_NAME STREQUAL "Darwin")
      if(NOT CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
        set_target_properties(facekit_ut_${_exename} PROPERTIES LINK_FLAGS -Wl)
      endif()
      target_link_libraries(facekit_ut_${_exename} PRIVATE pthread)
    elseif(UNIX AND NOT ANDROID)
      set_target_properties(facekit_ut_${_exename} PROPERTIES LINK_FLAGS -Wl,--as-needed)
      # GTest >= 1.5 requires pthread and CMake's 2.8.4 FindGTest is broken
      target_link_libraries(facekit_ut_${_exename} PRIVATE pthread)
    elseif(CMAKE_COMPILER_IS_GNUCXX AND MINGW)
      set_target_properties(facekit_ut_${_exename} PROPERTIES LINK_FLAGS "-Wl,--allow-multiple-definition -Wl,--as-needed")
    elseif(WIN32)
      set_target_properties(facekit_ut_${_exename} PROPERTIES LINK_FLAGS_RELEASE /OPT:REF)
    endif()
    # Register new text
    add_test(NAME ${_name} COMMAND facekit_ut_${_exename} ${FACEKIT_ADD_TEST_ARGUMENTS} WORKING_DIRECTORY ${FACEKIT_ADD_TEST_WORKING_DIR})
endmacro(FACEKIT_ADD_TEST)

###############################################################################
# Add an example target.
# _name The example name.
# ARGN :
#    FILES the source files for the example
#    LINK_WITH link example executable with libraries
macro(FACEKIT_ADD_EXAMPLE _name)
    set(options)
    set(oneValueArgs)
    set(multiValueArgs FILES LINK_WITH)
    cmake_parse_arguments(FACEKIT_ADD_EXAMPLE "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN} )
    add_executable(facekit_ex_${_name} ${FACEKIT_ADD_EXAMPLE_FILES})
    target_link_libraries(facekit_ex_${_name} PRIVATE ${FACEKIT_ADD_EXAMPLE_LINK_WITH} ${CLANG_LIBRARIES})
    if(WIN32 AND MSVC)
      set_target_properties(facekit_ex_${_name} PROPERTIES DEBUG_OUTPUT_NAME ${_name}${CMAKE_DEBUG_POSTFIX}
                                                           RELEASE_OUTPUT_NAME ${_name}${CMAKE_RELEASE_POSTFIX})
    else(WIN32 AND MSVC)
      target_link_libraries(facekit_ex_${_name} PRIVATE pthread)
    endif(WIN32 AND MSVC)
endmacro(FACEKIT_ADD_EXAMPLE)

###############################################################################
# Add compile flags to a target (because CMake doesn't provide something so
# common itself).
# _name The target name.
# _flags The new compile flags to be added, as a string.
macro(FACEKIT_ADD_CFLAGS _name _flags)
    get_target_property(_current_flags ${_name} COMPILE_FLAGS)
    if(NOT _current_flags)
        set_target_properties(${_name} PROPERTIES COMPILE_FLAGS ${_flags})
    else(NOT _current_flags)
        set_target_properties(${_name} PROPERTIES
            COMPILE_FLAGS "${_current_flags} ${_flags}")
    endif(NOT _current_flags)
endmacro(FACEKIT_ADD_CFLAGS)


###############################################################################
# Add link flags to a target (because CMake doesn't provide something so
# common itself).
# _name The target name.
# _flags The new link flags to be added, as a string.
macro(FACEKIT_ADD_LINKFLAGS _name _flags)
    get_target_property(_current_flags ${_name} LINK_FLAGS)
    if(NOT _current_flags)
        set_target_properties(${_name} PROPERTIES LINK_FLAGS ${_flags})
    else(NOT _current_flags)
        set_target_properties(${_name} PROPERTIES
            LINK_FLAGS "${_current_flags} ${_flags}")
    endif(NOT _current_flags)
endmacro(FACEKIT_ADD_LINKFLAGS)

###############################################################################
# PRIVATE

###############################################################################
# Reset the subsystem status map.
macro(FACEKIT_RESET_MAPS)
    foreach(_ss ${FACEKIT_SUBSYSTEMS})
        string(TOUPPER "FACEKIT_${_ss}_SUBSYS" FACEKIT_SUBSYS_SUBSYS)
	if (${FACEKIT_SUBSYS_SUBSYS})
            string(TOUPPER "FACEKIT_${_ss}_SUBSYS_DESC" FACEKIT_PARENT_SUBSYS_DESC)
	    set(${FACEKIT_SUBSYS_SUBSYS_DESC} "" CACHE INTERNAL "" FORCE)
	    set(${FACEKIT_SUBSYS_SUBSYS} "" CACHE INTERNAL "" FORCE)
	endif (${FACEKIT_SUBSYS_SUBSYS})
    endforeach(_ss)

    set(FACEKIT_SUBSYS_HYPERSTATUS "" CACHE INTERNAL
        "To Build Or Not To Build, That Is The Question." FORCE)
    set(FACEKIT_SUBSYS_STATUS "" CACHE INTERNAL
        "To build or not to build, that is the question." FORCE)
    set(FACEKIT_SUBSYS_REASONS "" CACHE INTERNAL
        "But why?" FORCE)
    set(FACEKIT_SUBSYS_DEPS "" CACHE INTERNAL "A depends on B and C." FORCE)
    set(FACEKIT_SUBSYS_EXT_DEPS "" CACHE INTERNAL "A depends on B and C." FORCE)
    set(FACEKIT_SUBSYS_OPT_DEPS "" CACHE INTERNAL "A depends on B and C." FORCE)
    set(FACEKIT_SUBSYSTEMS "" CACHE INTERNAL "Internal list of subsystems" FORCE)
    set(FACEKIT_SUBSYS_DESC "" CACHE INTERNAL "Subsystem descriptions" FORCE)
endmacro(FACEKIT_RESET_MAPS)


###############################################################################
# Register a subsystem.
# _name Subsystem name.
# _desc Description of the subsystem
macro(FACEKIT_ADD_SUBSYSTEM _name _desc)
    set(_temp ${FACEKIT_SUBSYSTEMS})
    list(APPEND _temp ${_name})
    set(FACEKIT_SUBSYSTEMS ${_temp} CACHE INTERNAL "Internal list of subsystems"
        FORCE)
    SET_IN_GLOBAL_MAP(FACEKIT_SUBSYS_DESC ${_name} ${_desc})
endmacro(FACEKIT_ADD_SUBSYSTEM)

###############################################################################
# Register a subsubsystem.
# _name Subsystem name.
# _desc Description of the subsystem
macro(FACEKIT_ADD_SUBSUBSYSTEM _parent _name _desc)
  string(TOUPPER "FACEKIT_${_parent}_SUBSYS" FACEKIT_PARENT_SUBSYS)
  string(TOUPPER "FACEKIT_${_parent}_SUBSYS_DESC" FACEKIT_PARENT_SUBSYS_DESC)
  set(_temp ${${FACEKIT_PARENT_SUBSYS}})
  list(APPEND _temp ${_name})
  set(${FACEKIT_PARENT_SUBSYS} ${_temp} CACHE INTERNAL "Internal list of ${_parenr} subsystems"
    FORCE)
  set_in_global_map(${FACEKIT_PARENT_SUBSYS_DESC} ${_name} ${_desc})
endmacro(FACEKIT_ADD_SUBSUBSYSTEM)


###############################################################################
# Set the status of a subsystem.
# _name Subsystem name.
# _status TRUE if being built, FALSE otherwise.
# ARGN[0] Reason for not building.
macro(FACEKIT_SET_SUBSYS_STATUS _name _status)
    if(${ARGC} EQUAL 3)
        set(_reason ${ARGV2})
    else(${ARGC} EQUAL 3)
        set(_reason "No reason")
    endif(${ARGC} EQUAL 3)
    SET_IN_GLOBAL_MAP(FACEKIT_SUBSYS_STATUS ${_name} ${_status})
    SET_IN_GLOBAL_MAP(FACEKIT_SUBSYS_REASONS ${_name} ${_reason})
endmacro(FACEKIT_SET_SUBSYS_STATUS)

###############################################################################
# Set the status of a subsystem.
# _name Subsystem name.
# _status TRUE if being built, FALSE otherwise.
# ARGN[0] Reason for not building.
macro(FACEKIT_SET_SUBSUBSYS_STATUS _parent _name _status)
    if(${ARGC} EQUAL 4)
        set(_reason ${ARGV2})
    else(${ARGC} EQUAL 4)
        set(_reason "No reason")
    endif(${ARGC} EQUAL 4)
    SET_IN_GLOBAL_MAP(FACEKIT_SUBSYS_STATUS ${_parent}_${_name} ${_status})
    SET_IN_GLOBAL_MAP(FACEKIT_SUBSYS_REASONS ${_parent}_${_name} ${_reason})
endmacro(FACEKIT_SET_SUBSUBSYS_STATUS)


###############################################################################
# Get the status of a subsystem
# _var Destination variable.
# _name Name of the subsystem.
macro(FACEKIT_GET_SUBSYS_STATUS _var _name)
    GET_IN_MAP(${_var} FACEKIT_SUBSYS_STATUS ${_name})
endmacro(FACEKIT_GET_SUBSYS_STATUS)

###############################################################################
# Get the status of a subsystem
# _var Destination variable.
# _name Name of the subsystem.
macro(FACEKIT_GET_SUBSUBSYS_STATUS _var _parent _name)
    GET_IN_MAP(${_var} FACEKIT_SUBSYS_STATUS ${_parent}_${_name})
endmacro(FACEKIT_GET_SUBSUBSYS_STATUS)


###############################################################################
# Set the hyperstatus of a subsystem and its dependee
# _name Subsystem name.
# _dependee Dependant subsystem.
# _status AUTO_OFF to disable AUTO_ON to enable
# ARGN[0] Reason for not building.
macro(FACEKIT_SET_SUBSYS_HYPERSTATUS _name _dependee _status)
    SET_IN_GLOBAL_MAP(FACEKIT_SUBSYS_HYPERSTATUS ${_name}_${_dependee} ${_status})
    if(${ARGC} EQUAL 4)
        SET_IN_GLOBAL_MAP(FACEKIT_SUBSYS_REASONS ${_dependee} ${ARGV3})
    endif(${ARGC} EQUAL 4)
endmacro(FACEKIT_SET_SUBSYS_HYPERSTATUS)

###############################################################################
# Get the hyperstatus of a subsystem and its dependee
# _name IN subsystem name.
# _dependee IN dependant subsystem.
# _var OUT hyperstatus
# ARGN[0] Reason for not building.
macro(FACEKIT_GET_SUBSYS_HYPERSTATUS _var _name)
    set(${_var} "AUTO_ON")
    if(${ARGC} EQUAL 3)
        GET_IN_MAP(${_var} FACEKIT_SUBSYS_HYPERSTATUS ${_name}_${ARGV2})
    else(${ARGC} EQUAL 3)
        foreach(subsys ${FACEKIT_SUBSYS_DEPS_${_name}})
            if("${FACEKIT_SUBSYS_HYPERSTATUS_${subsys}_${_name}}" STREQUAL "AUTO_OFF")
                set(${_var} "AUTO_OFF")
                break()
            endif("${FACEKIT_SUBSYS_HYPERSTATUS_${subsys}_${_name}}" STREQUAL "AUTO_OFF")
        endforeach(subsys)
    endif(${ARGC} EQUAL 3)
endmacro(FACEKIT_GET_SUBSYS_HYPERSTATUS)

###############################################################################
# Set the hyperstatus of a subsystem and its dependee
macro(FACEKIT_UNSET_SUBSYS_HYPERSTATUS _name _dependee)
    unset(FACEKIT_SUBSYS_HYPERSTATUS_${_name}_${dependee})
endmacro(FACEKIT_UNSET_SUBSYS_HYPERSTATUS)

###############################################################################
# Set the include directory name of a subsystem.
# _name Subsystem name.
# _includedir Name of subdirectory for includes
# ARGN[0] Reason for not building.
macro(FACEKIT_SET_SUBSYS_INCLUDE_DIR _name _includedir)
    SET_IN_GLOBAL_MAP(FACEKIT_SUBSYS_INCLUDE ${_name} ${_includedir})
endmacro(FACEKIT_SET_SUBSYS_INCLUDE_DIR)


###############################################################################
# Get the include directory name of a subsystem - return _name if not set
# _var Destination variable.
# _name Name of the subsystem.
macro(FACEKIT_GET_SUBSYS_INCLUDE_DIR _var _name)
    GET_IN_MAP(${_var} FACEKIT_SUBSYS_INCLUDE ${_name})
    if(NOT ${_var})
      set (${_var} ${_name})
    endif(NOT ${_var})
endmacro(FACEKIT_GET_SUBSYS_INCLUDE_DIR)


###############################################################################
# Write a report on the build/not-build status of the subsystems
macro(FACEKIT_WRITE_STATUS_REPORT)
    message(STATUS "The following subsystems will be built:")
    foreach(_ss ${FACEKIT_SUBSYSTEMS})
        FACEKIT_GET_SUBSYS_STATUS(_status ${_ss})
        if(_status)
	    set(message_text "  ${_ss}")
	    string(TOUPPER "FACEKIT_${_ss}_SUBSYS" FACEKIT_SUBSYS_SUBSYS)
	    if (${FACEKIT_SUBSYS_SUBSYS})
	        set(will_build)
		foreach(_sub ${${FACEKIT_SUBSYS_SUBSYS}})
		    FACEKIT_GET_SUBSYS_STATUS(_sub_status ${_ss}_${_sub})
		    if (_sub_status)
		        set(will_build "${will_build}\n       |_ ${_sub}")
		    endif (_sub_status)
		endforeach(_sub)
		if (NOT ("${will_build}" STREQUAL ""))
		  set(message_text  "${message_text}\n       building: ${will_build}")
		endif (NOT ("${will_build}" STREQUAL ""))
		set(wont_build)
		foreach(_sub ${${FACEKIT_SUBSYS_SUBSYS}})
		    FACEKIT_GET_SUBSYS_STATUS(_sub_status ${_ss}_${_sub})
		    FACEKIT_GET_SUBSYS_HYPERSTATUS(_sub_hyper_status ${_ss}_${sub})
		    if (NOT _sub_status OR ("${_sub_hyper_status}" STREQUAL "AUTO_OFF"))
		        GET_IN_MAP(_reason FACEKIT_SUBSYS_REASONS ${_ss}_${_sub})
		        set(wont_build "${wont_build}\n       |_ ${_sub}: ${_reason}")
		    endif (NOT _sub_status OR ("${_sub_hyper_status}" STREQUAL "AUTO_OFF"))
		endforeach(_sub)
		if (NOT ("${wont_build}" STREQUAL ""))
		    set(message_text  "${message_text}\n       not building: ${wont_build}")
		endif (NOT ("${wont_build}" STREQUAL ""))
	    endif (${FACEKIT_SUBSYS_SUBSYS})
	    message(STATUS "${message_text}")
        endif(_status)
    endforeach(_ss)

    message(STATUS "The following subsystems will not be built:")
    foreach(_ss ${FACEKIT_SUBSYSTEMS})
        FACEKIT_GET_SUBSYS_STATUS(_status ${_ss})
        FACEKIT_GET_SUBSYS_HYPERSTATUS(_hyper_status ${_ss})
        if(NOT _status OR ("${_hyper_status}" STREQUAL "AUTO_OFF"))
            GET_IN_MAP(_reason FACEKIT_SUBSYS_REASONS ${_ss})
            message(STATUS "  ${_ss}: ${_reason}")
        endif(NOT _status OR ("${_hyper_status}" STREQUAL "AUTO_OFF"))
    endforeach(_ss)
endmacro(FACEKIT_WRITE_STATUS_REPORT)

##############################################################################
# Collect subdirectories from dirname that contains filename and store them in
#  varname.
# WARNING If extra arguments are given then they are considered as exception
# list and varname will contain subdirectories of dirname that contains
# fielename but doesn't belong to exception list.
# dirname IN parent directory
# filename IN file name to look for in each subdirectory of parent directory
# varname OUT list of subdirectories containing filename
# exception_list OPTIONAL and contains list of subdirectories not to account
macro(collect_subproject_directory_names dirname filename names dirs)
    file(GLOB globbed RELATIVE "${dirname}" "${dirname}/*/${filename}")
    if(${ARGC} GREATER 4)
        set(exclusion_list ${ARGN})
        foreach(file ${globbed})
            get_filename_component(dir ${file} PATH)
            list(FIND exclusion_list ${dir} excluded)
            if(excluded EQUAL -1)
                set(${dirs} ${${dirs}} ${dir})
            endif(excluded EQUAL -1)
        endforeach()
    else(${ARGC} GREATER 4)
        foreach(file ${globbed})
            get_filename_component(dir ${file} PATH)
            set(${dirs} ${${dirs}} ${dir})
        endforeach(file)
    endif(${ARGC} GREATER 4)
    foreach(subdir ${${dirs}})
        file(STRINGS ${dirname}/${subdir}/CMakeLists.txt name REGEX "[setSET ]+\\(.*SUBSYS_NAME .*\\)$")
        string(REGEX REPLACE "[setSET ]+\\(.*SUBSYS_NAME[ ]+([A-Za-z0-9_]+)[ ]*\\)" "\\1" name "${name}")
        set(${names} ${${names}} ${name})
        file(STRINGS ${dirname}/${subdir}/CMakeLists.txt DEPENDENCIES REGEX "set.*SUBSYS_DEPS .*\\)")
        string(REGEX REPLACE "set.*SUBSYS_DEPS" "" DEPENDENCIES "${DEPENDENCIES}")
        string(REPLACE ")" "" DEPENDENCIES "${DEPENDENCIES}")
        string(STRIP "${DEPENDENCIES}" DEPENDENCIES)
        string(REPLACE " " ";" DEPENDENCIES "${DEPENDENCIES}")
        if(NOT("${DEPENDENCIES}" STREQUAL ""))
            list(REMOVE_ITEM DEPENDENCIES "#")
            string(TOUPPER "FACEKIT_${name}_DEPENDS" SUBSYS_DEPENDS)
            set(${SUBSYS_DEPENDS} ${DEPENDENCIES})
            foreach(dependee ${DEPENDENCIES})
                string(TOUPPER "FACEKIT_${dependee}_DEPENDIES" SUBSYS_DEPENDIES)
                set(${SUBSYS_DEPENDIES} ${${SUBSYS_DEPENDIES}} ${name})
            endforeach(dependee)
        endif(NOT("${DEPENDENCIES}" STREQUAL ""))
    endforeach(subdir)
endmacro()

########################################################################################
# Macro to disable subsystem dependies
# _subsys IN subsystem name
macro(FACEKIT_DISABLE_DEPENDIES _subsys)
    string(TOUPPER "facekit_${_subsys}_dependies" FACEKIT_SUBSYS_DEPENDIES)
    if(NOT ("${${FACEKIT_SUBSYS_DEPENDIES}}" STREQUAL ""))
        foreach(dep ${${FACEKIT_SUBSYS_DEPENDIES}})
            FACEKIT_SET_SUBSYS_HYPERSTATUS(${_subsys} ${dep} AUTO_OFF "Disabled: ${_subsys} missing.")
            set(BUILD_${dep} OFF CACHE BOOL "Disabled: ${_subsys} missing." FORCE)
        endforeach(dep)
    endif(NOT ("${${FACEKIT_SUBSYS_DEPENDIES}}" STREQUAL ""))
endmacro(FACEKIT_DISABLE_DEPENDIES subsys)

########################################################################################
# Macro to enable subsystem dependies
# _subsys IN subsystem name
macro(FACEKIT_ENABLE_DEPENDIES _subsys)
    string(TOUPPER "facekit_${_subsys}_dependies" FACEKIT_SUBSYS_DEPENDIES)
    if(NOT ("${${FACEKIT_SUBSYS_DEPENDIES}}" STREQUAL ""))
        foreach(dep ${${FACEKIT_SUBSYS_DEPENDIES}})
            FACEKIT_GET_SUBSYS_HYPERSTATUS(dependee_status ${_subsys} ${dep})
            if("${dependee_status}" STREQUAL "AUTO_OFF")
                FACEKIT_SET_SUBSYS_HYPERSTATUS(${_subsys} ${dep} AUTO_ON)
                GET_IN_MAP(desc FACEKIT_SUBSYS_DESC ${dep})
                set(BUILD_${dep} ON CACHE BOOL "${desc}" FORCE)
            endif("${dependee_status}" STREQUAL "AUTO_OFF")
        endforeach(dep)
    endif(NOT ("${${FACEKIT_SUBSYS_DEPENDIES}}" STREQUAL ""))
endmacro(FACEKIT_ENABLE_DEPENDIES subsys)

########################################################################################
# Macro to build subsystem centric documentation
# _subsys IN the name of the subsystem to generate documentation for
macro (FACEKIT_ADD_DOC _subsys)
  string(TOUPPER "${_subsys}" SUBSYS)
  set(doc_subsys "doc_${_subsys}")
  GET_IN_MAP(dependencies FACEKIT_SUBSYS_DEPS ${_subsys})
  if(DOXYGEN_FOUND)
    if(HTML_HELP_COMPILER)
      set(DOCUMENTATION_HTML_HELP YES)
    else(HTML_HELP_COMPILER)
      set(DOCUMENTATION_HTML_HELP NO)
    endif(HTML_HELP_COMPILER)
    if(DOXYGEN_DOT_EXECUTABLE)
      set(HAVE_DOT YES)
    else(DOXYGEN_DOT_EXECUTABLE)
      set(HAVE_DOT NO)
    endif(DOXYGEN_DOT_EXECUTABLE)
    if(NOT "${dependencies}" STREQUAL "")
      set(STRIPPED_HEADERS "${FACEKIT_SOURCE_DIR}/${dependencies}/include")
      string(REPLACE ";" "/include \\\n\t\t\t\t\t\t\t\t\t\t\t\t ${FACEKIT_SOURCE_DIR}/"
             STRIPPED_HEADERS "${STRIPPED_HEADERS}")
    endif(NOT "${dependencies}" STREQUAL "")
    set(DOC_SOURCE_DIR "\"${CMAKE_CURRENT_SOURCE_DIR}\"\\")
    foreach(dep ${dependencies})
      set(DOC_SOURCE_DIR
          "${DOC_SOURCE_DIR}\n\t\t\t\t\t\t\t\t\t\t\t\t \"${FACEKIT_SOURCE_DIR}/${dep}\"\\")
    endforeach(dep)
    file(MAKE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/html")
    set(doxyfile "${CMAKE_CURRENT_BINARY_DIR}/doxyfile")
    configure_file("${FACEKIT_SOURCE_DIR}/doc/doxygen/doxyfile.in" ${doxyfile})
    add_custom_target(${doc_subsys} ${DOXYGEN_EXECUTABLE} ${doxyfile})
    if(USE_PROJECT_FOLDERS)
      set_target_properties(${doc_subsys} PROPERTIES FOLDER "Documentation")
    endif(USE_PROJECT_FOLDERS)
  endif(DOXYGEN_FOUND)
endmacro(FACEKIT_ADD_DOC)

###############################################################################
# Add a dependency for a grabber
# _name The dependency name.
# _description The description text to display when dependency is not found.
# This macro adds on option named "WITH_NAME", where NAME is the capitalized
# dependency name. The user may use this option to control whether the
# corresponding grabber should be built or not. Also an attempt to find a
# package with the given name is made. If it is not successfull, then the
# "WITH_NAME" option is coerced to FALSE.
macro(FACEKIT_ADD_GRABBER_DEPENDENCY _name _description)
    string(TOUPPER ${_name} _name_capitalized)
    option(WITH_${_name_capitalized} "${_description}" TRUE)
    if(WITH_${_name_capitalized})
      find_package(${_name})
      if (NOT ${_name_capitalized}_FOUND)
        set(WITH_${_name_capitalized} FALSE CACHE BOOL "${_description}" FORCE)
        message(WARNING "${_description}: not building because ${_name} not found")
      else()
        set(HAVE_${_name_capitalized} TRUE)
        include_directories(SYSTEM "${${_name_capitalized}_INCLUDE_DIRS}")
      endif()
    endif()
endmacro(FACEKIT_ADD_GRABBER_DEPENDENCY)
