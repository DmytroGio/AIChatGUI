cmake_minimum_required(VERSION 3.16)

project(AIChatGUI VERSION 0.1 LANGUAGES CXX)

set(CMAKE_VERBOSE_MAKEFILE ON)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Compiler optimizations for Release builds
if(MSVC)
    set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} /O2 /Ob2 /Oi /Ot /GL /fp:fast")
    set(CMAKE_EXE_LINKER_FLAGS_RELEASE "${CMAKE_EXE_LINKER_FLAGS_RELEASE} /LTCG /OPT:REF /OPT:ICF")
    set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} /arch:AVX2")
    add_definitions(-D_CRT_SECURE_NO_WARNINGS)
else()
    set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} -O3 -march=native -ffast-math -funroll-loops")
endif()

# Build configuration info
message(STATUS "=== Build Configuration ===")
message(STATUS "Build type: ${CMAKE_BUILD_TYPE}")
if(CMAKE_BUILD_TYPE STREQUAL "Release")
    message(STATUS "Optimization flags: ENABLED")
    message(STATUS "CXX flags: ${CMAKE_CXX_FLAGS_RELEASE}")
else()
    message(STATUS "Optimization flags: DISABLED (Debug mode)")
endif()

# CUDA configuration
set(CUDAToolkit_ROOT "C:/Program Files/NVIDIA GPU Computing Toolkit/CUDA/v12.6")

find_package(Qt6 REQUIRED COMPONENTS Quick Network Sql)

set(BUILD_SHARED_LIBS OFF CACHE BOOL "Build static libraries" FORCE)
set(LLAMA_BUILD_SHARED OFF CACHE BOOL "Build llama as static library" FORCE)

set(LLAMA_PREBUILT_DIR "${CMAKE_SOURCE_DIR}/external/llama_prebuilt")

qt_standard_project_setup()

if(WIN32)
    set(APP_ICON_RC "${CMAKE_CURRENT_SOURCE_DIR}/app.rc")
endif()

qt_add_executable(AIChatGUI
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
    ${APP_ICON_RC}
)

qt_add_resources(AIChatGUI "icons"
    PREFIX "/"
    FILES
        icons/AiGui_Logo_small.png
        icons/AiGui_Logo_med.png
        icons/Ai_Icon.svg
        icons/Chat_Icon.svg
        icons/Chats_Icon.svg
        icons/Hardware_Icon.svg
        icons/Model_Icon.svg
        icons/NewChat_Icon.svg
        icons/RawOutput_Icon.svg
        icons/Send_Icon.svg
        icons/Stats_Icon.svg
        icons/Speed_Icon.svg
        icons/RescanFolder_Icon.svg
        icons/Folder_Icon.svg
        icons/Unload_Icon.svg
        icons/App_Icon_128.ico
        icons/App_Icon_256.ico
        icons/App_Icon_Invert_128.ico
)

qt_add_qml_module(AIChatGUI
    URI AIChatGUI
    VERSION 1.0
    RESOURCE_PREFIX "/"
    QML_FILES
        Main.qml
        ChatList.qml
        ModelPanel.qml
        SimpleMessageBubble.qml
    SOURCES
        syntaxhighlighter.h
        syntaxhighlighter.cpp
        modelinfo.h
        modelinfo.cpp
        messagelistmodel.h
        messagelistmodel.cpp
        message.h
)

# Include directories
target_include_directories(AIChatGUI PRIVATE
    ${CMAKE_SOURCE_DIR}/external/llama.cpp/include
    ${CMAKE_SOURCE_DIR}/external/llama.cpp/ggml/include
)

set_target_properties(AIChatGUI PROPERTIES
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

# Select library directory based on build type
if(CMAKE_BUILD_TYPE STREQUAL "Debug")
    set(LLAMA_LIB_DIR "${LLAMA_PREBUILT_DIR}/lib/Debug")
else()
    set(LLAMA_LIB_DIR "${LLAMA_PREBUILT_DIR}/lib/Release")
endif()

# Find CUDA Toolkit
find_package(CUDAToolkit REQUIRED)

target_include_directories(AIChatGUI PRIVATE
    ${CUDAToolkit_INCLUDE_DIRS}
)

# CUDA diagnostics
message(STATUS "=== CUDA Configuration ===")
message(STATUS "CUDAToolkit_FOUND: ${CUDAToolkit_FOUND}")
message(STATUS "CUDAToolkit_VERSION: ${CUDAToolkit_VERSION}")
message(STATUS "CUDAToolkit_LIBRARY_DIR: ${CUDAToolkit_LIBRARY_DIR}")
message(STATUS "CUDAToolkit_INCLUDE_DIRS: ${CUDAToolkit_INCLUDE_DIRS}")
message(STATUS "CUDAToolkit_BIN_DIR: ${CUDAToolkit_BIN_DIR}")

# LLAMA libraries diagnostics
message(STATUS "=== LLAMA Libraries ===")
message(STATUS "LLAMA_LIB_DIR: ${LLAMA_LIB_DIR}")
file(GLOB LLAMA_LIBS "${LLAMA_LIB_DIR}/*.lib")
foreach(lib ${LLAMA_LIBS})
    message(STATUS "Found: ${lib}")
endforeach()

# Verify cuda.lib exists
if(EXISTS "${CUDAToolkit_LIBRARY_DIR}/cuda.lib")
    message(STATUS "cuda.lib FOUND")
else()
    message(FATAL_ERROR "cuda.lib NOT FOUND in ${CUDAToolkit_LIBRARY_DIR}")
endif()

# Verify all required libraries exist
message(STATUS "=== Checking library files ===")
foreach(lib llama ggml ggml-base ggml-cpu ggml-cuda)
    if(EXISTS "${LLAMA_LIB_DIR}/${lib}.lib")
        message(STATUS "${lib}.lib exists")
    else()
        message(FATAL_ERROR "${lib}.lib NOT FOUND in ${LLAMA_LIB_DIR}")
    endif()
endforeach()

target_link_libraries(AIChatGUI
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
    CUDA::cuda_driver
    CUDA::cublas
    CUDA::cublasLt
)

# Copy CUDA DLLs to build directory
if(WIN32)
    if(CUDAToolkit_VERSION VERSION_GREATER_EQUAL "12.0" AND CUDAToolkit_VERSION VERSION_LESS "13.0")
        set(CUDA_DLL_SUFFIX "_12")
    elseif(CUDAToolkit_VERSION VERSION_GREATER_EQUAL "13.0")
        set(CUDA_DLL_SUFFIX "_13")
    else()
        set(CUDA_DLL_SUFFIX "")
    endif()

    add_custom_command(TARGET AIChatGUI POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
        "${CUDAToolkit_BIN_DIR}/cudart64${CUDA_DLL_SUFFIX}.dll"
        "$<TARGET_FILE_DIR:AIChatGUI>"
    )
    add_custom_command(TARGET AIChatGUI POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
        "${CUDAToolkit_BIN_DIR}/cublas64${CUDA_DLL_SUFFIX}.dll"
        "$<TARGET_FILE_DIR:AIChatGUI>"
    )
    add_custom_command(TARGET AIChatGUI POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
        "${CUDAToolkit_BIN_DIR}/cublasLt64${CUDA_DLL_SUFFIX}.dll"
        "$<TARGET_FILE_DIR:AIChatGUI>"
    )
endif()

# Debug build reminder
if(CMAKE_BUILD_TYPE STREQUAL "Debug")
    message(STATUS "")
    message(STATUS "⚠️  WARNING: Building in Debug mode")
    message(STATUS "   For maximum performance, use Release build:")
    message(STATUS "   1. In Qt Creator: Projects → Build Settings → Release")
    message(STATUS "   2. Rebuild the project")
    message(STATUS "   This will increase token generation speed by 2-3x!")
    message(STATUS "")
endif()
