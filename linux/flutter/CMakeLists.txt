cmake_minimum_required(VERSION 3.13)

set(EPHEMERAL_DIR "${CMAKE_CURRENT_SOURCE_DIR}/ephemeral")

# Configuration provided via flutter tool.
include(${EPHEMERAL_DIR}/generated_config.cmake)

# TODO: Move the rest of this into files in ephemeral. See
# https://github.com/flutter/flutter/issues/57146.
set(WRAPPER_ROOT "${EPHEMERAL_DIR}/cpp_client_wrapper")

# Set fallback configurations for older versions of the flutter tool.
if (NOT DEFINED FLUTTER_TARGET_PLATFORM)
  set(FLUTTER_TARGET_PLATFORM "linux-x64")
endif()

# === Flutter Library ===
# System-level dependencies.
find_package(PkgConfig REQUIRED)
pkg_check_modules(GTK REQUIRED IMPORTED_TARGET gtk+-3.0)
pkg_check_modules(GLIB REQUIRED IMPORTED_TARGET glib-2.0)
pkg_check_modules(GIO REQUIRED IMPORTED_TARGET gio-2.0)

set(FLUTTER_LIBRARY "${EPHEMERAL_DIR}/libflutter_linux_gtk.so")

# Published to parent scope for install step.
set(FLUTTER_LIBRARY ${FLUTTER_LIBRARY} PARENT_SCOPE)
set(FLUTTER_ICU_DATA_FILE "${EPHEMERAL_DIR}/icudtl.dat" PARENT_SCOPE)
set(PROJECT_BUILD_DIR "${PROJECT_BINARY_DIR}/" PARENT_SCOPE)
set(AOT_LIBRARY "${PROJECT_BINARY_DIR}/lib/libapp.so" PARENT_SCOPE)

list(APPEND FLUTTER_LIBRARY_HEADERS
  "fl_basic_message_channel.h"
  "fl_binary_codec.h"
  "fl_binary_messenger.h"
  "fl_dart_project.h"
  "fl_engine.h"
  "fl_event_channel.h"
  "fl_json_message_codec.h"
  "fl_json_method_codec.h"
  "fl_message_codec.h"
  "fl_method_call.h"
  "fl_method_channel.h"
  "fl_method_codec.h"
  "fl_method_error_response.h"
  "fl_method_not_implemented_response.h"
  "fl_method_response.h"
  "fl_plugin_registrar.h"
  "fl_plugin_registry.h"
  "fl_standard_message_codec.h"
  "fl_standard_method_codec.h"
  "fl_string_codec.h"
  "fl_value.h"
  "fl_view.h"
  "flutter_linux.h"
)
list_transform_prepend(FLUTTER_LIBRARY_HEADERS "${EPHEMERAL_DIR}/")
add_library(flutter INTERFACE)
target_include_directories(flutter INTERFACE
  "${EPHEMERAL_DIR}"
)
target_link_libraries(flutter INTERFACE "${FLUTTER_LIBRARY}.1.0.0")
add_dependencies(flutter flutter_assemble)

# === Wrapper ===
list(APPEND CPP_WRAPPER_SOURCES_CORE
  "core_implementations.cc"
  "plugin_registrar.cc"
)
list_transform_prepend(CPP_WRAPPER_SOURCES_CORE "${WRAPPER_ROOT}/")

list(APPEND CPP_WRAPPER_SOURCES_PLUGIN
  "flutter_plugin_registrar.cc"
)
list_transform_prepend(CPP_WRAPPER_SOURCES_PLUGIN "${WRAPPER_ROOT}/")

list(APPEND CPP_WRAPPER_SOURCES_APP
  "flutter_engine.cc"
  "flutter_view_controller.cc"
)
list_transform_prepend(CPP_WRAPPER_SOURCES_APP "${WRAPPER_ROOT}/")

add_library(flutter_wrapper_app STATIC
  ${CPP_WRAPPER_SOURCES_CORE}
  ${CPP_WRAPPER_SOURCES_APP}
)
apply_standard_settings(flutter_wrapper_app)
set_target_properties(flutter_wrapper_app PROPERTIES
  POSITION_INDEPENDENT_CODE ON)
set_target_properties(flutter_wrapper_app PROPERTIES
  CXX_VISIBILITY_PRESET hidden)
target_link_libraries(flutter_wrapper_app PUBLIC flutter)
target_link_libraries(flutter_wrapper_app PUBLIC PkgConfig::GTK)
add_dependencies(flutter_wrapper_app flutter_assemble)

add_library(flutter_wrapper_plugin STATIC
  ${CPP_WRAPPER_SOURCES_CORE}
  ${CPP_WRAPPER_SOURCES_PLUGIN}
)
apply_standard_settings(flutter_wrapper_plugin)
set_target_properties(flutter_wrapper_plugin PROPERTIES
  POSITION_INDEPENDENT_CODE ON)
set_target_properties(flutter_wrapper_plugin PROPERTIES
  CXX_VISIBILITY_PRESET hidden)
target_link_libraries(flutter_wrapper_plugin PUBLIC flutter)
add_dependencies(flutter_wrapper_plugin flutter_assemble)

# === Flutter tool backend ===
# These targets are used to forward calls to the Flutter tool backend's
# temporary build setup scripts. See also the `tmp_dependency_registrar`
# defined in linux/runner/CMakeLists.txt.
# Only targets with INPUTS or OUTPUTS are required until then.
# See also //flutter/sky/tools/create_full_icu_data.py for ICU data.
set(PHONY_OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/phony_output")
set_source_files_properties("${PHONY_OUTPUT}" PROPERTIES SYMBOLIC TRUE)
add_custom_command(OUTPUT ${FLUTTER_LIBRARY} ${FLUTTER_LIBRARY}.1.0.0
    ${CPP_WRAPPER_SOURCES_CORE} ${CPP_WRAPPER_SOURCES_PLUGIN}
    ${CPP_WRAPPER_SOURCES_APP}
    ${FLUTTER_ICU_DATA_FILE} ${FLUTTER_LIBRARY_HEADERS}
    ${PHONY_OUTPUT}
  COMMAND ${CMAKE_COMMAND} -E env
    FLUTTER_ROOT="${FLUTTER_ROOT}"
    FLUTTER_LINUX_FLUTTER_ROOT="${FLUTTER_ROOT}"
    SOURCE_DIR="${CMAKE_SOURCE_DIR}"
    BINARY_DIR="${CMAKE_BINARY_DIR}"
    PUB_CACHE="${PUB_CACHE}"
    FLUTTER_WEB_AUTO_DETECT=false
    ${CMAKE_COMMAND} -P
      "${EPHEMERAL_DIR}/flutter_linux_cmake_macros.cmake"
  VERBATIM
)
add_custom_target(flutter_assemble DEPENDS
  "${FLUTTER_LIBRARY}"
  "${FLUTTER_ICU_DATA_FILE}"
)
