# Sets up swig for a .i file and encode .tcl files
# Arguments
#   NAME <library>: the generated library name
#   I_FILE <file>: the .i file input to swig
#   NAMESPACE <name>: the namespace prefix in TCL
#   SWIG_INCLUDES <dir>* : optional list of include dirs for swig
#   SCRIPTS <file>* : tcl files to encode
#
# The intention is that this will create a library target with the
# generated code in it.  Additional c++ source will be added to the
# target with target_sources() afterwards.

function(tcl_lib)

  # Parse args
  set(options "")
  set(oneValueArgs I_FILE NAME NAMESPACE)
  set(multiValueArgs SWIG_INCLUDES SCRIPTS)
  
  cmake_parse_arguments(
      ARG  # prefix on the parsed args
      "${options}"
      "${oneValueArgs}"
      "${multiValueArgs}"
      ${ARGN}
  )

  # Validate args
  if (DEFINED ARG_UNPARSED_ARGUMENTS)
     message(FATAL_ERROR "Unknown argument(s) to tcl_commands: ${ARG_UNPARSED_ARGUMENTS}")
  endif()

  if (DEFINED ARG_KEYWORDS_MISSING_VALUES)
     message(FATAL_ERROR "Missing value for argument(s) to tcl_commands: ${ARG_KEYWORDS_MISSING_VALUES}")
  endif()

  foreach(arg I_FILE NAME NAMESPACE)
    if (NOT DEFINED ARG_${arg})
       message(FATAL_ERROR "${arg} argument must be provided to tcl_commands")
    endif()
  endforeach()

  set_source_files_properties(${ARG_I_FILE} PROPERTIES CPLUSPLUS ON)

  if (DEFINED ARG_SWIG_INCLUDES)
    set_property(SOURCE ${ARG_I_FILE}
                 PROPERTY INCLUDE_DIRECTORIES ${ARG_SWIG_INCLUDES})
  endif()

  # Setup swig of I_FILE.
  set_property(SOURCE ${ARG_I_FILE}
               PROPERTY COMPILE_OPTIONS -namespace
                                        -prefix ${ARG_NAMESPACE}
                                        -w317,325,378,401,402,467,472,503,509)

  swig_add_library(${ARG_NAME}
    LANGUAGE tcl
    TYPE     STATIC
    SOURCES  ${ARG_I_FILE}
  )

  # Disable problematic compiler warnings on generated files.
  # At this point the only the swig generated sources are present.
  get_target_property(GEN_SRCS ${ARG_NAME} SOURCES)

  foreach(GEN_SRC ${GEN_SRCS})
    set_source_files_properties(${GEN_SRC}
      PROPERTIES
        COMPILE_OPTIONS "-Wno-cast-qual"
    )
  endforeach()

  # These includes are always needed.
  target_include_directories(${ARG_NAME}
    PRIVATE
      ${TCL_INCLUDE_PATH}
      ${OPENROAD_HOME}/include
  )

  # Generate the encoded of the tcl files.
  if (DEFINED ARG_SCRIPTS)
    set(TCL_INIT ${CMAKE_CURRENT_BINARY_DIR}/${ARG_NAME}-TclInitVar.cc)

    add_custom_command(OUTPUT ${TCL_INIT}
      COMMAND ${OPENSTA_HOME}/etc/TclEncode.tcl ${TCL_INIT} ${ARG_NAME}_tcl_inits ${ARG_SCRIPTS}
      WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
      DEPENDS ${ARG_SCRIPTS}
    )

    target_sources(${ARG_NAME}
      PRIVATE
        ${TCL_INIT}                  
    )
  endif()     
endfunction()
