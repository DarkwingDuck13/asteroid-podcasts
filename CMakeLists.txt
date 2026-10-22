cmake_minimum_required(VERSION 3.16)
project(asteroid-podcasts LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

find_package(Qt6 REQUIRED COMPONENTS Core Gui Quick Network Multimedia)

set(SOURCES
    src/main.cpp
    src/podcastengine.cpp
    src/podcastengine.h
    src/resources.qrc
)

add_executable(asteroid-podcasts ${SOURCES})

target_link_libraries(asteroid-podcasts PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Quick
    Qt6::Network
    Qt6::Multimedia
)

install(TARGETS asteroid-podcasts RUNTIME DESTINATION bin)
install(FILES asteroid-podcasts.desktop DESTINATION share/applications)
