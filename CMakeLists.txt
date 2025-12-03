cmake_minimum_required(VERSION 3.16)

project(AIChatGUI VERSION 0.1 LANGUAGES CXX)

set(CMAKE_VERBOSE_MAKEFILE ON)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# ===================================================================
# ✅ ПРАВИЛЬНАЯ НАСТРОЙКА ОПТИМИЗАЦИЙ (только для Release)
# ===================================================================
if(MSVC)
    # Debug: оставляем дефолтные флаги Qt
    # Release: добавляем агрессивные оптимизации
    set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} /O2 /Ob2 /Oi /Ot /GL /fp:fast")
    set(CMAKE_EXE_LINKER_FLAGS_RELEASE "${CMAKE_EXE_LINKER_FLAGS_RELEASE} /LTCG /OPT:REF /OPT:ICF")

    # AVX2 только если процессор поддерживает (большинство современных поддерживают)
    set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} /arch:AVX2")

    # Отключаем предупреждения о небезопасных функциях
    add_definitions(-D_CRT_SECURE_NO_WARNINGS)
else()
    # Linux/Mac оптимизации
    set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} -O3 -march=native -ffast-math -funroll-loops")
endif()

# Выводим информацию о режиме сборки
message(STATUS "=== Build Configuration ===")
message(STATUS "Build type: ${CMAKE_BUILD_TYPE}")
if(CMAKE_BUILD_TYPE STREQUAL "Release")
    message(STATUS "Optimization flags: ENABLED")
    message(STATUS "CXX flags: ${CMAKE_CXX_FLAGS_RELEASE}")
else()
    message(STATUS "Optimization flags: DISABLED (Debug mode)")
endif()

# ===================================================================
# CUDA Configuration
# ===================================================================
set(CUDAToolkit_ROOT "C:/Program Files/NVIDIA GPU Computing Toolkit/CUDA/v12.6")

find_package(Qt6 REQUIRED COMPONENTS Quick Network Sql)

set(BUILD_SHARED_LIBS OFF CACHE BOOL "Build static libraries" FORCE)
set(LLAMA_BUILD_SHARED OFF CACHE BOOL "Build llama as static library" FORCE)

# Путь к предсобранным библиотекам
set(LLAMA_PREBUILT_DIR "${CMAKE_SOURCE_DIR}/external/llama_prebuilt")

qt_standard_project_setup()

if(WIN32)
    set(APP_ICON_RC "${CMAKE_CURRENT_SOURCE_DIR}/app.rc")
endif()

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
    ${APP_ICON_RC}
)

# Добавляем ресурсы отдельно
qt_add_resources(appAIChatGUI "icons"
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
        icons/App_Icon_128.ico
        icons/App_Icon_256.ico
        icons/App_Icon_Invert_128.ico
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

# Заголовочные файлы llama.cpp
target_include_directories(appAIChatGUI PRIVATE
    ${CMAKE_SOURCE_DIR}/external/llama.cpp/include
    ${CMAKE_SOURCE_DIR}/external/llama.cpp/ggml/include
)

set_target_properties(appAIChatGUI PROPERTIES
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

# ===================================================================
# ✅ ПОДСКАЗКА ПОЛЬЗОВАТЕЛЮ
# ===================================================================
if(CMAKE_BUILD_TYPE STREQUAL "Debug")
    message(STATUS "")
    message(STATUS "⚠️  ВНИМАНИЕ: Сборка в Debug режиме")
    message(STATUS "   Для максимальной производительности используй Release:")
    message(STATUS "   1. В Qt Creator: Projects → Build Settings → Release")
    message(STATUS "   2. Пересобери проект")
    message(STATUS "   Это увеличит скорость генерации токенов в 2-3 раза!")
    message(STATUS "")
endif()
