## 2025-07-31
AI Chat GUI Development Plan
Phase 1: Backend Setup [done]

Create LMStudioConnector class for HTTP API communication
Implement JSON request/response handling (OpenAI format)
Connect to localhost:1234 LM Studio endpoint

Phase 2: Frontend UI [done]

Design dark theme chat interface with message bubbles
Add input field with send button functionality
Implement auto-scrolling chat view

Phase 3: Integration

Connect QML to C++ backend via signals/slots
Handle async AI responses and display in chat
Add error handling for network issues

Phase 4: Polish

Add animations and responsive design
Test with LM Studio and Llama models
Deploy and document

Tech Stack: Qt6, QML, C++, HTTP API, LM Studio

## 2025-08-15
- Resolve the issue of speed, eliminate long loading times

## 2025-09-22
- Planning the integration of SQLite and JSON solutions for chats - data management optimization

## 2025-09-29
- Project restructuring analysis and planning

## 2025-10-05
- Side panel planning - characteristics and model operation via llama.cpp

## 2025-10-12
- Planning to accelerate local models - using GPUs, number of threads, Flash Attention...

## 2025-10-19
- Planning and thinking about designs in Figma

## 2025-10-23
-🟢 Solved Critical LLM Backend Configuration: I resolved the persistent CUDA error: device kernel image is invalid and related runtime crashes by definitively fixing the llama.cpp CMake build configuration. This involved a complete rebuild after enforcing the correct CUDA Toolkit version (12.6) and setting the GPU architecture strictly to "86" (RTX 3070 Ti) using FORCE flags in CMakeLists.txt before the project() command, which finally eliminated conflicts and allowed the model to successfully offload all layers to VRAM for GPU-accelerated inference.

## 2025-10-26
- Working on the program’s design and outlining future development plans.

## 2025-11-17
- worked on the app icon design, focusing on creating a cohesive, recognizable, and scalable set of icons that align with the application's overall aesthetic and user experience.

## 2025-11-23
Work is ongoing on new program icon prototypes (focusing on clarity and modern appeal). The long-term development vector is currently being mapped, prioritizing performance optimization and core feature planning.

## 2025-11-26
- Icons development in Figma (WIP)

## 2025-11-30
- Planning further design development and direction.

## 2025-12-02
- Working on app Icon in figma

## 2025-12-07
- Preparation for project documentation. Planning.