# AI Chat Assistant

A modern, native desktop application for running local AI models with GPU acceleration. Built with Qt6/QML and powered by llama.cpp.

![Version](https://img.shields.io/badge/version-0.1-blue)
![Qt](https://img.shields.io/badge/Qt-6-green)
![CUDA](https://img.shields.io/badge/CUDA-12.6-brightgreen)

## Features

- 🚀 **GPU Accelerated** - CUDA support for fast inference
- 💬 **Modern UI** - Clean, dark-themed interface with smooth animations
- 📝 **Code Highlighting** - Syntax highlighting for code blocks in responses
- 💾 **Chat History** - Persistent storage of conversations
- ⚡ **Real-time Streaming** - Token-by-token generation display
- 🎨 **Markdown Support** - Rich text formatting in messages

## Screenshots

*Coming soon*

## Requirements

- **OS**: Windows 10/11
- **GPU**: NVIDIA GPU with CUDA support (recommended)
- **RAM**: 8GB minimum, 16GB+ recommended
- **Qt**: 6.0 or higher
- **CUDA Toolkit**: 12.6 (for GPU acceleration)

## Building from Source

### Prerequisites

```bash
# Install Qt 6
# Download from: https://www.qt.io/download

# Install CUDA Toolkit (optional, for GPU support)
# Download from: https://developer.nvidia.com/cuda-downloads
```

### Build Steps

1. **Clone the repository**
```bash
git clone https://github.com/DmytroGio/AIChatGUI.git
cd AIChatGUI
```

2. **Prepare llama.cpp libraries**
   - Place pre-built llama.cpp libraries in `external/llama_prebuilt/lib/`
   - Separate Debug and Release builds
   - Required libs: `llama.lib`, `ggml.lib`, `ggml-base.lib`, `ggml-cpu.lib`, `ggml-cuda.lib`

3. **Configure and build**
```bash
mkdir build
cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
cmake --build . --config Release
```

> ⚠️ **Important**: Use Release build for 2-3x faster inference speed

## Usage

1. Launch the application
2. Click the Model panel (right side) to load a GGUF model
3. Start chatting with your local AI assistant
4. Use Shift+Enter for multiline input, Enter to send

### Keyboard Shortcuts

- `Enter` - Send message
- `Shift+Enter` - New line
- `Middle Mouse Button` - Auto-scroll in chat

## Configuration

Models are auto-loaded from the last session. Configure model parameters in the Model Panel:
- Context size
- Temperature
- Top-K, Top-P sampling
- GPU layers

## Project Structure

```
AIChatGUI/
├── main.cpp              # Application entry point
├── llamaconnector.*      # llama.cpp integration
├── chatmanager.*         # Chat history management
├── modelinfo.*           # Model configuration
├── Main.qml              # Main UI
├── ChatList.qml          # Sidebar with chats
├── ModelPanel.qml        # Model settings panel
└── SimpleMessageBubble.qml  # Message display
```

## Performance Tips

- Use Release build for optimal speed
- Enable GPU acceleration (set GPU layers > 0)
- Adjust context size based on available VRAM
- Use quantized models (Q4_K_M recommended)

## Technologies

- **Qt 6** - Cross-platform framework
- **QML** - Modern declarative UI
- **llama.cpp** - Fast LLM inference engine
- **CUDA** - GPU acceleration

## License

MIT License - see [LICENSE](LICENSE) file for details

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Acknowledgments

- [llama.cpp](https://github.com/ggerganov/llama.cpp) - LLM inference library
- Qt Project - UI framework

---

Made with ❤️ by DmytroVision