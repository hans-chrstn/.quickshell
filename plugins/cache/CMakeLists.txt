cmake_minimum_required(VERSION 3.21)
project(qs-cache LANGUAGES CXX)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
find_package(Qt6 REQUIRED COMPONENTS Core Qml)
find_package(SQLite3 REQUIRED)
qt_standard_project_setup(REQUIRES 6.5)
qt_add_library(qs_cache SHARED)
qt_add_qml_module(qs_cache URI Cache VERSION 1.0
    OUTPUT_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/Cache"
    SOURCES CacheDatabase.h CacheDatabase.cpp)
target_link_libraries(qs_cache PRIVATE Qt6::Core Qt6::Qml SQLite3::SQLite3)
install(TARGETS qs_cache qs_cacheplugin LIBRARY DESTINATION "lib/qt-6/qml/Cache")
install(FILES "${CMAKE_CURRENT_BINARY_DIR}/Cache/qmldir"
    "${CMAKE_CURRENT_BINARY_DIR}/Cache/Cache.qmltypes"
    DESTINATION "lib/qt-6/qml/Cache" OPTIONAL)
