cmake_minimum_required(VERSION 3.16)

project(AIChatGUI VERSION 0.1 LANGUAGES CXX)

set(CMAKE_VERBOSE_MAKEFILE ON)

set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Явно указываем путь к CUDA 12.6 ПЕРЕД find_package
set(CUDAToolkit_ROOT "C:/Program Files/NVIDIA GPU Computing Toolkit/CUDA/v12.6")

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

# Добавляем CUDA include директории
target_include_directories(appAIChatGUI PRIVATE
    ${CUDAToolkit_INCLUDE_DIRS}
)

# Диагностика CUDA
message(STATUS "=== CUDA Configuration ===")
message(STATUS "CUDAToolkit_FOUND: ${CUDAToolkit_FOUND}")
message(STATUS "CUDAToolkit_VERSION: ${CUDAToolkit_VERSION}")
message(STATUS "CUDAToolkit_LIBRARY_DIR: ${CUDAToolkit_LIBRARY_DIR}")
message(STATUS "CUDAToolkit_INCLUDE_DIRS: ${CUDAToolkit_INCLUDE_DIRS}")
message(STATUS "CUDAToolkit_BIN_DIR: ${CUDAToolkit_BIN_DIR}")

# Диагностика библиотек llama
message(STATUS "=== LLAMA Libraries ===")
message(STATUS "LLAMA_LIB_DIR: ${LLAMA_LIB_DIR}")
file(GLOB LLAMA_LIBS "${LLAMA_LIB_DIR}/*.lib")
foreach(lib ${LLAMA_LIBS})
    message(STATUS "Found: ${lib}")
endforeach()

# Проверяем наличие cuda.lib
if(EXISTS "${CUDAToolkit_LIBRARY_DIR}/cuda.lib")
    message(STATUS "cuda.lib FOUND")
else()
    message(FATAL_ERROR "cuda.lib NOT FOUND in ${CUDAToolkit_LIBRARY_DIR}")
endif()

# Проверяем существование всех библиотек перед линковкой
message(STATUS "=== Checking library files ===")
foreach(lib llama ggml ggml-base ggml-cpu ggml-cuda)
    if(EXISTS "${LLAMA_LIB_DIR}/${lib}.lib")
        message(STATUS "${lib}.lib exists")
    else()
        message(FATAL_ERROR "${lib}.lib NOT FOUND in ${LLAMA_LIB_DIR}")
    endif()
endforeach()

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
    CUDA::cuda_driver
    CUDA::cublas
    CUDA::cublasLt
)

# Копируем CUDA DLL в папку сборки
if(WIN32)
    # Определяем правильную версию DLL на основе найденной CUDA
    if(CUDAToolkit_VERSION VERSION_GREATER_EQUAL "12.0" AND CUDAToolkit_VERSION VERSION_LESS "13.0")
        set(CUDA_DLL_SUFFIX "_12")
    elseif(CUDAToolkit_VERSION VERSION_GREATER_EQUAL "13.0")
        set(CUDA_DLL_SUFFIX "_13")
    else()
        set(CUDA_DLL_SUFFIX "")
    endif()

    add_custom_command(TARGET appAIChatGUI POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
        "${CUDAToolkit_BIN_DIR}/cudart64${CUDA_DLL_SUFFIX}.dll"
        "$<TARGET_FILE_DIR:appAIChatGUI>"
    )
    add_custom_command(TARGET appAIChatGUI POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
        "${CUDAToolkit_BIN_DIR}/cublas64${CUDA_DLL_SUFFIX}.dll"
        "$<TARGET_FILE_DIR:appAIChatGUI>"
    )
    add_custom_command(TARGET appAIChatGUI POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
        "${CUDAToolkit_BIN_DIR}/cublasLt64${CUDA_DLL_SUFFIX}.dll"
        "$<TARGET_FILE_DIR:appAIChatGUI>"
    )
endif()
