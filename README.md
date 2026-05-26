# ⚡️ Offline AI (Powered by flutter_gemma)

**Offline AI** is a premium Flutter-based playground designed for local-first, secure, and high-performance AI inference on macOS. Built on top of the `flutter_gemma` package, it leverages **Apple Silicon Metal (GPU) acceleration** to provide a private environment for chatting with large language models, analyzing images, and performing semantic knowledge searches—entirely without an internet connection.

---

## ✨ Key Features

- **🚀 Native Performance**: Full Metal/GPU acceleration for Apple Silicon, ensuring low latency and high token throughput.
- **🧠 Reasoning & Thinking**: Support for modern "thinking" models (like Qwen3 and Gemma 4) that visualize their internal logic before responding.
- **🖼️ Multimodal Vision**: Analyze images locally using Gemma 4, enabling secure vision tasks without cloud uploads.
- **🛠️ Function Calling (Tool Use)**: Integrates with the macOS environment to perform actions like changing the app theme, triggering system dialogs, and retrieving real-time system data.
- **📚 Local RAG (Vector Knowledge Base)**: Features a high-performance vector store using **Qdrant-Edge (FFI)** and the **Gecko 110M** embedder for semantic document retrieval.
- **📦 Model Manager**: A built-in registry to discover, download, and manage quantized `.litertlm` and `.tflite` model weights directly from HuggingFace.

---

## 🛠️ Technical Stack

- **Framework**: Flutter (Dart)
- **Core Engine**: `flutter_gemma` (MediaPipe / LiteRT / TFLite backend)
- **Acceleration**: Metal (GPU) / CPU Fallback
- **Vector DB**: Qdrant-Edge (Local FFI)
- **UI Architecture**: Provider-based state management with a custom sidebar-driven workspace.
- **Persistence**: SharedPreferences for tokens and app state.

---

## 🤖 Supported Models

The app includes a pre-configured registry for the following optimized models:

| No. | Model Name          | Type       | Size     | Features                      |
|:----|:--------------------|:-----------|:---------|:------------------------------|
| 1   | **Qwen3 0.6B**      | Text       | ~580 MB  | Ultra-lightweight, Reasoning  |
| 2   | **Gemma 4 E2B IT**  | Multimodal | ~2.40 GB | Vision, Advanced Reasoning    |
| 3   | **Qwen 2.5 1.5B**   | Text       | ~1.60 GB | Structured Tool Calling, Code |
| 4   | **Gecko 110M**      | Embedding  | ~111 MB  | Semantic Search (RAG)         |

---

## 🚀 Getting Started

### 1. Prerequisites
- **macOS Hardware**: Apple Silicon (M1/M2/M3/M4) is highly recommended for GPU acceleration.
- **Flutter SDK**: Ensure you have the latest stable Flutter version installed.
- **HuggingFace Token**: Accessing models like Gemma 4 requires a [HuggingFace Read Token](https://huggingface.co/settings/tokens) as the models are gated.

### 2. Setup
1. Clone the repository.
2. Run `flutter pub get`.
3. Launch the application: `flutter run -d macos`.

### 3. Model Installation
1. Navigate to the **Settings** tab.
2. Paste your HuggingFace Access Token and click **Save**.
3. Go to the **Model Manager** tab.
4. Download the **Gecko Embedder** (required for RAG) and at least one **Chat Model**.
5. Click **Load Model** on an installed model to start chatting.

---

## 🏗️ Project Structure

- `lib/main.dart`: The unified entry point containing the full UI suite and state providers.
- **Providers**:
    - `SettingsProvider`: Manages HF tokens, theme colors, and hardware backends.
    - `ModelDownloadManager`: Handles multi-threaded downloads and disk maintenance.
    - `ChatPlaygroundProvider`: Manages inference sessions, tool execution, and vision pipelines.
    - `RAGProvider`: Interfaces with the native Qdrant-edge vector database.
- **Design System**: A custom `AppColors` and `AppTheme` system with dynamic accent switching and Markdown-ready message components.

---

## 🔒 Privacy & Security

Everything in this project happens **on-device**. 
- **Inference**: Your prompts and image data never leave your computer.
- **Knowledge Base**: The vector database is stored locally in the application's support directory.
- **Analytics**: Zero tracking or telemetry is implemented.

---

## 📜 License
This project is licensed under the MIT License. Models are subject to their respective licenses (Google Gemma, Alibaba Qwen).
