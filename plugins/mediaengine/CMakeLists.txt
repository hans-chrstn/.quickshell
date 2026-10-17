cmake_minimum_required(VERSION 3.21)
project(qs-mediaengine LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Core Qml)
find_package(SQLite3 REQUIRED)
qt_standard_project_setup(REQUIRES 6.5)

qt_add_library(qs_mediaengine SHARED)
qt_add_qml_module(qs_mediaengine
    URI MediaEngine
    VERSION 1.0
    OUTPUT_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/MediaEngine"
    SOURCES
        MediaEngine.h
        MediaEngine.cpp
)

target_link_libraries(qs_mediaengine PRIVATE Qt6::Core Qt6::Qml SQLite3::SQLite3)
target_include_directories(qs_mediaengine PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}")

install(TARGETS qs_mediaengine qs_mediaengineplugin
    LIBRARY DESTINATION "lib/qt-6/qml/MediaEngine"
)
install(FILES
    "${CMAKE_CURRENT_BINARY_DIR}/MediaEngine/qmldir"
    "${CMAKE_CURRENT_BINARY_DIR}/MediaEngine/MediaEngine.qmltypes"
    DESTINATION "lib/qt-6/qml/MediaEngine"
    OPTIONAL
)
