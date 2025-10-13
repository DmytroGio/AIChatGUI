cmake_minimum_required(VERSION 3.16)

project(AIChatGUI VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Quick Network Sql)

set(BUILD_SHARED_LIBS OFF CACHE BOOL "Build static libraries" FORCE)
set(LLAMA_BUILD_SHARED OFF CACHE BOOL "Build llama as static library" FORCE)

set(GGML_CUDA ON CACHE BOOL "Enable CUDA" FORCE)
set(GGML_CUDA_NO_PEER_COPY ON CACHE BOOL "Disable peer copy" FORCE)
set(CMAKE_CUDA_ARCHITECTURES "86" CACHE STRING "CUDA arch" FORCE)
set(CMAKE_CUDA_COMPILER "C:/Program Files/NVIDIA GPU Computing Toolkit/CUDA/v13.0/bin/nvcc.exe" CACHE FILEPATH "CUDA compiler" FORCE)

add_subdirectory(external/llama.cpp)

qt_standard_project_setup()

qt_add_executable(appAIChatGUI
    main.cpp
    llamaconnector.h
    llamaconnector.cpp
    chatmanager.h
    chatmanager.cpp
    clipboardhelper.h
    clipboardhelper.cpp
    syntaxhighlighter.h
    syntaxhighlighter.cpp
    modelinfo.h
    modelinfo.cpp
)

qt_add_qml_module(appAIChatGUI
    URI AIChatGUI
    VERSION 1.0
    RESOURCE_PREFIX "/"
    QML_FILES
        Main.qml
        MessageBubble.qml
        ChatList.qml
        ModelPanel.qml
    SOURCES
        syntaxhighlighter.h
        syntaxhighlighter.cpp
        SOURCES modelinfo.h modelinfo.cpp
)


# Qt for iOS sets MACOSX_BUNDLE_GUI_IDENTIFIER automatically since Qt 6.1.
# If you are developing for iOS or macOS you should consider setting an
# explicit, fixed bundle identifier manually though.
set_target_properties(appAIChatGUI PROPERTIES
#    MACOSX_BUNDLE_GUI_IDENTIFIER com.example.appAIChatGUI
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_link_libraries(appAIChatGUI
    PRIVATE Qt6::Quick Qt6::Network Qt6::Sql llama ggml
)

include(GNUInstallDirs)
install(TARGETS appAIChatGUI
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
