cmake_minimum_required(VERSION 3.16)

project(AIChatGUI VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Quick Network Sql)

set(BUILD_SHARED_LIBS OFF CACHE BOOL "Build static libraries" FORCE)
set(LLAMA_BUILD_SHARED OFF CACHE BOOL "Build llama as static library" FORCE)

# Убираем add_subdirectory(external/llama.cpp) и CUDA настройки
# Теперь используем предсобранные библиотеки

# Путь к предсобранным библиотекам
set(LLAMA_PREBUILT_DIR "${CMAKE_SOURCE_DIR}/external/llama_prebuilt")


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


# Заголовочные файлы llama.cpp
target_include_directories(appAIChatGUI PRIVATE
    ${CMAKE_SOURCE_DIR}/external/llama.cpp/include
    ${CMAKE_SOURCE_DIR}/external/llama.cpp/ggml/include
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

# Выбираем правильную папку с библиотеками
if(CMAKE_BUILD_TYPE STREQUAL "Debug")
    set(LLAMA_LIB_DIR "${LLAMA_PREBUILT_DIR}/lib/Debug")
else()
    set(LLAMA_LIB_DIR "${LLAMA_PREBUILT_DIR}/lib/Release")
endif()

# Находим CUDA Toolkit
find_package(CUDAToolkit REQUIRED)

target_link_libraries(appAIChatGUI
    PRIVATE
    Qt6::Quick
    Qt6::Network
    Qt6::Sql
    ${LLAMA_LIB_DIR}/llama.lib
    ${LLAMA_LIB_DIR}/ggml.lib
    ${LLAMA_LIB_DIR}/ggml-base.lib
    ${LLAMA_LIB_DIR}/ggml-cpu.lib
    ${LLAMA_LIB_DIR}/ggml-cuda.lib
    CUDA::cudart
    CUDA::cublas
    CUDA::cuda_driver
)

include(GNUInstallDirs)
install(TARGETS appAIChatGUI
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
