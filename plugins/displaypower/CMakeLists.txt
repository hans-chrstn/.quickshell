cmake_minimum_required(VERSION 3.21)
project(qs-displaypower LANGUAGES C CXX)
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
find_package(Qt6 REQUIRED COMPONENTS Core Qml)
find_package(PkgConfig REQUIRED)
pkg_check_modules(WAYLAND REQUIRED IMPORTED_TARGET wayland-client)
find_program(WAYLAND_SCANNER wayland-scanner REQUIRED)
set(POWER_XML "${WLR_PROTOCOLS}/unstable/wlr-output-power-management-unstable-v1.xml")
add_custom_command(OUTPUT power-client.h power-protocol.c
    COMMAND ${WAYLAND_SCANNER} client-header ${POWER_XML} power-client.h
    COMMAND ${WAYLAND_SCANNER} private-code ${POWER_XML} power-protocol.c
    DEPENDS ${POWER_XML})
qt_standard_project_setup(REQUIRES 6.5)
qt_add_library(qs_displaypower SHARED)
qt_add_qml_module(qs_displaypower URI DisplayPower VERSION 1.0
    OUTPUT_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/DisplayPower"
    SOURCES DisplayPowerObserver.h DisplayPowerObserver.cpp power-client.h power-protocol.c)
target_include_directories(qs_displaypower PRIVATE "${CMAKE_CURRENT_BINARY_DIR}")
target_link_libraries(qs_displaypower PRIVATE Qt6::Core Qt6::Qml PkgConfig::WAYLAND)
target_compile_options(qs_displaypower PRIVATE -Wall -Wextra -Werror)
install(TARGETS qs_displaypower qs_displaypowerplugin LIBRARY DESTINATION "lib/qt-6/qml/DisplayPower")
install(FILES "${CMAKE_CURRENT_BINARY_DIR}/DisplayPower/qmldir"
    "${CMAKE_CURRENT_BINARY_DIR}/DisplayPower/DisplayPower.qmltypes"
    DESTINATION "lib/qt-6/qml/DisplayPower" OPTIONAL)
