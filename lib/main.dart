import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gemma/core/domain/model_source.dart';
import 'package:flutter_gemma/core/utils/file_name_utils.dart';
import 'package:flutter_gemma/core/di/service_registry.dart';
import 'package:path_provider/path_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Ensure background downloader directory exists inside the Sandboxed Caches to avoid PathNotFoundException
  try {
    final tempDir = await getTemporaryDirectory();
    final pathSegments = tempDir.path.split('/');
    final containersIdx = pathSegments.indexOf('Containers');
    String bundleId = 'com.example.flutterGemma';
    if (containersIdx != -1 && containersIdx + 1 < pathSegments.length) {
      bundleId = pathSegments[containersIdx + 1];
    }
    
    final bDownloaderCacheDir = Directory('${tempDir.path}/$bundleId');
    if (!bDownloaderCacheDir.existsSync()) {
      bDownloaderCacheDir.createSync(recursive: true);
      debugPrint('📁 Prepared background downloader cache directory: ${bDownloaderCacheDir.path}');
    }
  } catch (e) {
    debugPrint('⚠️ Failed to prepare background downloader cache directory: $e');
  }
  
  // Load SharedPreferences early to get token
  final prefs = await SharedPreferences.getInstance();
  final hfToken = prefs.getString('hf_token') ?? '';
  
  // Initialize Flutter Gemma with token if exists
  await FlutterGemma.initialize(
    huggingFaceToken: hfToken.isNotEmpty ? hfToken : null,
  );

  runApp(const MyApp());
}

// ============================================================================
// DESIGN SYSTEM & THEME
// ============================================================================

class AppColors {
  static bool isDarkMode = true;

  static Color get background => isDarkMode ? const Color(0xFF0B0F19) : const Color(0xFFF8FAFC);
  static Color get sidebarBackground => isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);
  static Color get cardBackground => isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFFFFFFF);
  static Color get border => isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
  static Color get textPrimary => isDarkMode ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
  static Color get textSecondary => isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
  static Color get success => const Color(0xFF10B981);
  static Color get warning => const Color(0xFFF59E0B);
  static Color get error => const Color(0xFFEF4444);
  static Color get thinking => const Color(0xFF8B5CF6);

  // Dynamic Accents
  static const Map<String, Color> accents = {
    'purple': Color(0xFFD946EF),
    'blue': Color(0xFF3B82F6),
    'green': Color(0xFF10B981),
    'amber': Color(0xFFF59E0B),
    'red': Color(0xFFEF4444),
  };

  static Color getReadableAccent(Color color) {
    if (isDarkMode) return color;
    if (color.value == const Color(0xFFD946EF).value) return const Color(0xFF9D178D);
    if (color.value == const Color(0xFF3B82F6).value) return const Color(0xFF1D4ED8);
    if (color.value == const Color(0xFF10B981).value) return const Color(0xFF047857);
    if (color.value == const Color(0xFFF59E0B).value) return const Color(0xFFB45309);
    if (color.value == const Color(0xFFEF4444).value) return const Color(0xFFB91C1C);
    return color;
  }
}

class AppTheme {
  static ThemeData theme(Color accentColor, bool isDarkMode) {
    AppColors.isDarkMode = isDarkMode;
    return isDarkMode ? dark(accentColor) : light(accentColor);
  }

  static ThemeData dark(Color accentColor) {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.dark(
        primary: accentColor,
        secondary: accentColor.withOpacity(0.8),
        surface: AppColors.cardBackground,
        background: AppColors.background,
        error: AppColors.error,
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.border.withOpacity(0.4), width: 1),
        ),
        elevation: 0,
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: AppColors.textPrimary, fontSize: 15, height: 1.5, fontFamily: 'Outfit'),
        bodyMedium: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontFamily: 'Outfit'),
        titleMedium: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Outfit'),
        titleLarge: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 20, letterSpacing: -0.5, fontFamily: 'Outfit'),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.background.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border.withOpacity(0.5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accentColor, width: 1.5),
        ),
        hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 14),
      ),
    );
  }

  static ThemeData light(Color accentColor) {
    return ThemeData.light().copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.light(
        primary: accentColor,
        secondary: accentColor.withOpacity(0.8),
        surface: AppColors.cardBackground,
        background: AppColors.background,
        error: AppColors.error,
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.border.withOpacity(0.4), width: 1),
        ),
        elevation: 0,
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: AppColors.textPrimary, fontSize: 15, height: 1.5, fontFamily: 'Outfit'),
        bodyMedium: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontFamily: 'Outfit'),
        titleMedium: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Outfit'),
        titleLarge: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 20, letterSpacing: -0.5, fontFamily: 'Outfit'),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.background.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border.withOpacity(0.5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accentColor, width: 1.5),
        ),
        hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 14),
      ),
    );
  }
}

// ============================================================================
// MODEL REGISTRY & DATA STRUCTURES
// ============================================================================

class AppModelInfo {
  final String id;
  final String name;
  final String description;
  final ModelType modelType;
  final ModelFileType fileType;
  final String url;
  final double sizeGB;
  final bool supportImage;
  final bool supportThinking;
  final bool supportFunctionCalling;

  const AppModelInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.modelType,
    required this.fileType,
    required this.url,
    required this.sizeGB,
    this.supportImage = false,
    this.supportThinking = false,
    this.supportFunctionCalling = false,
  });

  String get filename => url.split('/').last;
}

const List<AppModelInfo> kSupportedModels = [
  AppModelInfo(
    id: 'qwen3_0.6b',
    name: 'Qwen3 0.6B Instruct',
    description: 'Ultra-lightweight 600M text-only model. Ideal for swift responses and lower memory systems, supports reasoning.',
    modelType: ModelType.qwen3,
    fileType: ModelFileType.litertlm,
    url: 'https://huggingface.co/litert-community/Qwen3-0.6B/resolve/main/Qwen3-0.6B.litertlm',
    sizeGB: 0.58,
    supportThinking: true,
  ),
  AppModelInfo(
    id: 'gemma4_e2b',
    name: 'Gemma 4 E2B IT',
    description: 'Google\'s 2B parameter multimodal model. Supports both image and text inputs, advanced reasoning, and on-device processing.',
    modelType: ModelType.gemma4,
    fileType: ModelFileType.litertlm,
    url: 'https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm/resolve/main/gemma-4-E2B-it.litertlm',
    sizeGB: 2.40,
    supportImage: true,
    supportThinking: true,
  ),
  AppModelInfo(
    id: 'qwen2.5_1.5b',
    name: 'Qwen 2.5 1.5B Instruct',
    description: 'Optimized 1.5B text-only model specializing in code syntax, math reasoning, and native structured tool calling.',
    modelType: ModelType.qwen,
    fileType: ModelFileType.litertlm,
    url: 'https://huggingface.co/litert-community/Qwen2.5-1.5B-Instruct/resolve/main/Qwen2.5-1.5B-Instruct_multi-prefill-seq_q8_ekv4096.litertlm',
    sizeGB: 1.60,
    supportFunctionCalling: true,
  ),
];

// Embedder config
const String kEmbedderModelUrl = 'https://huggingface.co/litert-community/Gecko-110m-en/resolve/main/Gecko_64_quant.tflite';
const String kEmbedderTokenizerUrl = 'https://huggingface.co/litert-community/Gecko-110m-en/resolve/main/sentencepiece.model';

// ============================================================================
// STATE PROVIDERS (Simple State Architecture)
// ============================================================================

class SettingsProvider extends ChangeNotifier {
  String _hfToken = '';
  PreferredBackend _backend = PreferredBackend.gpu;
  String _accentName = 'blue';
  bool _isDarkMode = true;

  String get hfToken => _hfToken;
  PreferredBackend get backend => _backend;
  String get accentName => _accentName;
  Color get accentColor => AppColors.accents[_accentName] ?? AppColors.accents['blue']!;
  bool get isDarkMode => _isDarkMode;

  SettingsProvider() {
    _loadSettings();
  }

  void _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _hfToken = prefs.getString('hf_token') ?? '';
    final backendIndex = prefs.getInt('preferred_backend') ?? PreferredBackend.gpu.index;
    _backend = PreferredBackend.values[backendIndex];
    _accentName = prefs.getString('accent_color') ?? 'blue';
    _isDarkMode = prefs.getBool('is_dark_mode') ?? true;
    notifyListeners();
  }

  Future<void> setHfToken(String token) async {
    _hfToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('hf_token', token);
    
    // Re-initialize Gemma engine dynamically with new token
    ServiceRegistry.reset();
    await FlutterGemma.initialize(
      huggingFaceToken: token.isNotEmpty ? token : null,
    );
    notifyListeners();
  }

  Future<void> setBackend(PreferredBackend b) async {
    _backend = b;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('preferred_backend', b.index);
    notifyListeners();
  }

  Future<void> setAccentColor(String colorName) async {
    if (AppColors.accents.containsKey(colorName)) {
      _accentName = colorName;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('accent_color', colorName);
      notifyListeners();
    }
  }

  Future<void> toggleThemeMode() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', _isDarkMode);
    notifyListeners();
  }
}

class DownloadState {
  final bool isDownloading;
  final int progress;
  final double speedMBs;
  final String eta;
  final String downloadedSize;
  final String statusText;
  final CancelToken? cancelToken;

  const DownloadState({
    this.isDownloading = false,
    this.progress = 0,
    this.speedMBs = 0.0,
    this.eta = '--:--',
    this.downloadedSize = '0 MB',
    this.statusText = '',
    this.cancelToken,
  });

  DownloadState copyWith({
    bool? isDownloading,
    int? progress,
    double? speedMBs,
    String? eta,
    String? downloadedSize,
    String? statusText,
    CancelToken? cancelToken,
  }) {
    return DownloadState(
      isDownloading: isDownloading ?? this.isDownloading,
      progress: progress ?? this.progress,
      speedMBs: speedMBs ?? this.speedMBs,
      eta: eta ?? this.eta,
      downloadedSize: downloadedSize ?? this.downloadedSize,
      statusText: statusText ?? this.statusText,
      cancelToken: cancelToken ?? this.cancelToken,
    );
  }
}

class ModelDownloadManager extends ChangeNotifier {
  final SettingsProvider _settings;
  Map<String, bool> _installedModels = {};
  Map<String, DownloadState> _downloads = {};
  bool _isCleaning = false;

  Map<String, bool> get installedModels => _installedModels;
  Map<String, DownloadState> get downloads => _downloads;
  bool get isCleaning => _isCleaning;

  ModelDownloadManager(this._settings) {
    refreshInstallationStatuses();
  }

  Future<void> refreshInstallationStatuses() async {
    for (final model in kSupportedModels) {
      final isInstalled = await FlutterGemma.isModelInstalled(model.filename);
      _installedModels[model.id] = isInstalled;
    }
    
    // Check embedder
    final embedderModelInstalled = await FlutterGemma.isModelInstalled('Gecko_64_quant.tflite');
    final embedderTokenizerInstalled = await FlutterGemma.isModelInstalled('sentencepiece.model');
    _installedModels['gecko_64'] = embedderModelInstalled && embedderTokenizerInstalled;
    
    notifyListeners();
  }

  DownloadState getDownloadState(String modelId) {
    return _downloads[modelId] ?? const DownloadState();
  }

  void cancelDownload(String modelId) {
    final state = _downloads[modelId];
    if (state != null && state.cancelToken != null) {
      state.cancelToken!.cancel('User cancelled download');
      _downloads[modelId] = const DownloadState(statusText: 'Cancelled');
      notifyListeners();
    }
  }

  Future<void> startModelDownload(AppModelInfo model) async {
    if (getDownloadState(model.id).isDownloading) return;

    final cancelToken = CancelToken();
    _downloads[model.id] = DownloadState(
      isDownloading: true,
      progress: 0,
      statusText: 'Connecting...',
      cancelToken: cancelToken,
    );
    notifyListeners();

    final startTime = DateTime.now();
    final totalSizeInBytes = model.sizeGB * 1024 * 1024 * 1024;

    try {
      await FlutterGemma.installModel(
        modelType: model.modelType,
        fileType: model.fileType,
      )
      .fromNetwork(model.url, token: _settings.hfToken.isNotEmpty ? _settings.hfToken : null)
      .withCancelToken(cancelToken)
      .withProgress((progressPercent) {
        final now = DateTime.now();
        final elapsedMs = now.difference(startTime).inMilliseconds;
        
        double speed = 0.0;
        String etaStr = '--:--';
        double downloadedBytes = 0;

        if (elapsedMs > 500) {
          downloadedBytes = (totalSizeInBytes * progressPercent) / 100;
          final speedBytesPerSec = (downloadedBytes / (elapsedMs / 1000));
          speed = speedBytesPerSec / (1024 * 1024); // MB/s
          
          if (speed > 0.01) {
            final remainingBytes = totalSizeInBytes - downloadedBytes;
            final remainingSeconds = (remainingBytes / speedBytesPerSec).round();
            if (remainingSeconds >= 60) {
              final minutes = remainingSeconds ~/ 60;
              final seconds = remainingSeconds % 60;
              etaStr = '$minutes m ${seconds}s';
            } else {
              etaStr = '${remainingSeconds}s';
            }
          }
        }

        final sizeDownloadedStr = '${(downloadedBytes / (1024 * 1024)).toStringAsFixed(0)} MB / ${(totalSizeInBytes / (1024 * 1024)).toStringAsFixed(0)} MB';

        _downloads[model.id] = DownloadState(
          isDownloading: true,
          progress: progressPercent,
          speedMBs: speed,
          eta: etaStr,
          downloadedSize: sizeDownloadedStr,
          statusText: 'Downloading model files...',
          cancelToken: cancelToken,
        );
        notifyListeners();
      })
      .install();

      _downloads[model.id] = const DownloadState(progress: 100, statusText: 'Installed');
      await refreshInstallationStatuses();
    } catch (e) {
      if (CancelToken.isCancel(e)) {
        _downloads[model.id] = const DownloadState(statusText: 'Cancelled');
      } else {
        _downloads[model.id] = DownloadState(statusText: 'Error: ${e.toString().split('\n').first}');
      }
      notifyListeners();
    }
  }

  Future<void> startEmbedderDownload() async {
    const embedderId = 'gecko_64';
    if (getDownloadState(embedderId).isDownloading) return;

    final cancelToken = CancelToken();
    _downloads[embedderId] = DownloadState(
      isDownloading: true,
      progress: 0,
      statusText: 'Connecting embedder...',
      cancelToken: cancelToken,
    );
    notifyListeners();

    int modelProg = 0;
    int tokProg = 0;
    final startTime = DateTime.now();
    const totalSizeInBytes = 111.0 * 1024 * 1024; // 110MB model + 1MB tokenizer

    void updateOverallProgress() {
      final overall = (modelProg + tokProg) ~/ 2;
      final now = DateTime.now();
      final elapsedMs = now.difference(startTime).inMilliseconds;
      
      double speed = 0.0;
      String etaStr = '--:--';
      double downloadedBytes = 0;

      if (elapsedMs > 500) {
        downloadedBytes = (totalSizeInBytes * overall) / 100;
        final speedBytesPerSec = (downloadedBytes / (elapsedMs / 1000));
        speed = speedBytesPerSec / (1024 * 1024);
        
        if (speed > 0.01) {
          final remainingBytes = totalSizeInBytes - downloadedBytes;
          final remainingSeconds = (remainingBytes / speedBytesPerSec).round();
          etaStr = remainingSeconds >= 60 ? '${remainingSeconds ~/ 60}m ${remainingSeconds % 60}s' : '${remainingSeconds}s';
        }
      }

      final sizeDownloadedStr = '${(downloadedBytes / (1024 * 1024)).toStringAsFixed(1)} MB / ${(totalSizeInBytes / (1024 * 1024)).toStringAsFixed(1)} MB';

      _downloads[embedderId] = DownloadState(
        isDownloading: true,
        progress: overall,
        speedMBs: speed,
        eta: etaStr,
        downloadedSize: sizeDownloadedStr,
        statusText: 'Model: $modelProg%, Tokenizer: $tokProg%',
        cancelToken: cancelToken,
      );
      notifyListeners();
    }

    try {
      await FlutterGemma.installEmbedder()
          .modelFromNetwork(kEmbedderModelUrl, token: _settings.hfToken.isNotEmpty ? _settings.hfToken : null)
          .tokenizerFromNetwork(kEmbedderTokenizerUrl, token: _settings.hfToken.isNotEmpty ? _settings.hfToken : null)
          .withCancelToken(cancelToken)
          .withModelProgress((p) {
            modelProg = p;
            updateOverallProgress();
          })
          .withTokenizerProgress((p) {
            tokProg = p;
            updateOverallProgress();
          })
          .install();

      _downloads[embedderId] = const DownloadState(progress: 100, statusText: 'Installed');
      await refreshInstallationStatuses();
    } catch (e) {
      if (CancelToken.isCancel(e)) {
        _downloads[embedderId] = const DownloadState(statusText: 'Cancelled');
      } else {
        _downloads[embedderId] = DownloadState(statusText: 'Error: ${e.toString().split('\n').first}');
      }
      notifyListeners();
    }
  }

  Future<void> deleteModelFiles(String modelId) async {
    if (modelId == 'gecko_64') {
      final spec = EmbeddingModelSpec(
        name: 'Gecko_64_quant',
        modelSource: ModelSource.network(kEmbedderModelUrl),
        tokenizerSource: ModelSource.network(kEmbedderTokenizerUrl),
      );
      await FlutterGemmaPlugin.instance.modelManager.deleteModel(spec);
    } else {
      final model = kSupportedModels.firstWhere((m) => m.id == modelId);
      final spec = InferenceModelSpec(
        name: FileNameUtils.getBaseName(model.filename),
        modelSource: ModelSource.network(model.url),
        modelType: model.modelType,
        fileType: model.fileType,
      );
      await FlutterGemmaPlugin.instance.modelManager.deleteModel(spec);
    }
    await refreshInstallationStatuses();
  }

  Future<void> runOrphanedCleanup() async {
    _isCleaning = true;
    notifyListeners();
    try {
      await FlutterGemmaPlugin.instance.modelManager.cleanupStorage();
    } catch (_) {}
    _isCleaning = false;
    notifyListeners();
  }
}

class ChatPlaygroundProvider extends ChangeNotifier {
  final SettingsProvider _settings;
  final ModelDownloadManager _downloadManager;
  
  InferenceModel? _activeModel;
  InferenceChat? _activeChat;
  AppModelInfo? _activeModelInfo;
  
  List<Message> _messages = [];
  bool _isLoading = false;
  bool _isStreaming = false;
  
  // Custom states for rich visualizations
  String _thinkingText = '';
  bool _isCurrentlyThinking = false;
  Uint8List? _selectedImageBytes;
  String? _selectedImagePath;
  
  // Function Call overlay state
  String? _executingToolName;
  Map<String, dynamic>? _executingToolArgs;
  bool _showToolOverlay = false;

  InferenceChat? get activeChat => _activeChat;
  AppModelInfo? get activeModelInfo => _activeModelInfo;
  List<Message> get messages => _messages;
  bool get isLoading => _isLoading;
  bool get isStreaming => _isStreaming;
  String get thinkingText => _thinkingText;
  bool get isCurrentlyThinking => _isCurrentlyThinking;
  Uint8List? get selectedImageBytes => _selectedImageBytes;
  String? get selectedImagePath => _selectedImagePath;
  
  String? get executingToolName => _executingToolName;
  Map<String, dynamic>? get executingToolArgs => _executingToolArgs;
  bool get showToolOverlay => _showToolOverlay;

  ChatPlaygroundProvider(this._settings, this._downloadManager) {
    _checkAndLoadActiveModel();
  }

  void _checkAndLoadActiveModel() async {
    if (FlutterGemma.hasActiveModel()) {
      final spec = FlutterGemmaPlugin.instance.modelManager.activeInferenceModel as InferenceModelSpec?;
      if (spec != null) {
        final match = kSupportedModels.cast<AppModelInfo?>().firstWhere(
          (m) => m != null && FileNameUtils.getBaseName(m.filename) == spec.name,
          orElse: () => null,
        );
        if (match != null) {
          await loadInferenceModel(match);
        }
      }
    }
  }

  Future<void> selectImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
      if (result != null && result.files.single.path != null) {
        _selectedImagePath = result.files.single.path;
        _selectedImageBytes = await File(_selectedImagePath!).readAsBytes();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error selecting image: $e');
    }
  }

  void clearSelectedImage() {
    _selectedImageBytes = null;
    _selectedImagePath = null;
    notifyListeners();
  }

  Future<void> loadInferenceModel(AppModelInfo modelInfo) async {
    _isLoading = true;
    _activeModelInfo = null;
    _activeChat = null;
    _messages = [];
    notifyListeners();

    try {
      // Step 1: Set model active in the model manager
      final spec = InferenceModelSpec(
        name: FileNameUtils.getBaseName(modelInfo.filename),
        modelSource: ModelSource.network(modelInfo.url),
        modelType: modelInfo.modelType,
        fileType: modelInfo.fileType,
      );
      FlutterGemmaPlugin.instance.modelManager.setActiveModel(spec);

      // Step 2: Get active model instance
      _activeModel = await FlutterGemma.getActiveModel(
        maxTokens: 2048,
        preferredBackend: _settings.backend,
        supportImage: modelInfo.supportImage,
      );

      // Step 3: Define tools for function calling
      final tools = modelInfo.supportFunctionCalling ? _getAppTools() : <Tool>[];

      // Step 4: Create chat session
      _activeChat = await _activeModel!.createChat(
        supportsFunctionCalls: modelInfo.supportFunctionCalling,
        modelType: modelInfo.modelType,
        isThinking: modelInfo.supportThinking,
        tools: tools,
        systemInstruction: "You are a helpful local assistant named Offline AI, running entirely offline on macOS using flutter_gemma and Metal acceleration.",
      );

      _activeModelInfo = modelInfo;
      _messages = [
        Message.systemInfo(text: 'System: Initialized ${_activeModelInfo!.name} successfully. Ready for prompt.', icon: 'offline_bolt')
      ];
    } catch (e) {
      _messages = [
        Message.systemInfo(text: 'Error initializing model: $e', icon: 'error_outline')
      ];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<Tool> _getAppTools() {
    return const [
      Tool(
        name: 'change_app_theme',
        description: 'Changes the app\'s dynamic primary theme color to a new accent color.',
        parameters: {
          'type': 'OBJECT',
          'properties': {
            'color': {
              'type': 'STRING',
              'description': 'The new color name. Must be one of: purple, blue, green, amber, red.',
            }
          },
          'required': ['color']
        },
      ),
      Tool(
        name: 'show_system_dialog',
        description: 'Displays a popup warning or information dialog to the user with a title and content body.',
        parameters: {
          'type': 'OBJECT',
          'properties': {
            'title': {
              'type': 'STRING',
              'description': 'The title header of the system warning popup.',
            },
            'message': {
              'type': 'STRING',
              'description': 'The detail description message explaining the alert.',
            }
          },
          'required': ['title', 'message']
        },
      ),
      Tool(
        name: 'get_current_time',
        description: 'Retrieves the current date and local system time formatted nicely.',
        parameters: {
          'type': 'OBJECT',
          'properties': {}
        },
      ),
    ];
  }

  Future<void> sendMessage(String text) async {
    if (_activeChat == null || _isStreaming || (text.trim().isEmpty && _selectedImageBytes == null)) return;

    final userText = text.trim();
    Message userMessage;
    
    if (_selectedImageBytes != null) {
      userMessage = Message.withImage(
        text: userText.isNotEmpty ? userText : 'Analyze this image.',
        imageBytes: _selectedImageBytes!,
        isUser: true,
      );
    } else {
      userMessage = Message.text(text: userText, isUser: true);
    }

    _messages.add(userMessage);
    _isStreaming = true;
    _selectedImageBytes = null;
    _selectedImagePath = null;
    notifyListeners();

    try {
      await _activeChat!.addQueryChunk(userMessage);
      await _generateResponseLoop();
    } catch (e) {
      _messages.add(Message.systemInfo(text: 'Generation Error: $e', icon: 'error'));
      _isStreaming = false;
      notifyListeners();
    }
  }

  Future<void> _generateResponseLoop() async {
    debugPrint('=== [Gemma Demo] _generateResponseLoop started ===');
    _thinkingText = '';
    _isCurrentlyThinking = _activeModelInfo?.supportThinking ?? false;
    debugPrint('  supportThinking: $_isCurrentlyThinking');
    
    bool addedBotMessage = false;
    final answerBuffer = StringBuffer();
    notifyListeners();

    ModelResponse? finalResponseEvent;

    try {
      final responseStream = _activeChat!.generateChatResponseAsync();
      int eventCount = 0;

      await for (final event in responseStream) {
        eventCount++;
        finalResponseEvent = event;
        debugPrint('  [Event #$eventCount] Type: ${event.runtimeType}, Details: $event');
        
        if (event is ThinkingResponse) {
          _thinkingText += event.content;
        } else if (event is TextResponse) {
          if (_isCurrentlyThinking) {
            debugPrint('    Transitioning from thinking to text.');
            _isCurrentlyThinking = false; // Model has transitioned to text
          }
          
          answerBuffer.write(event.token);
          
          if (!addedBotMessage) {
            _messages.add(Message(text: answerBuffer.toString(), isUser: false));
            addedBotMessage = true;
            debugPrint('    Added botMsg to _messages list. Text length: ${answerBuffer.length}');
          } else {
            _messages[_messages.length - 1] = Message(text: answerBuffer.toString(), isUser: false);
            debugPrint('    Updated botMsg at index ${_messages.length - 1}. Text length: ${answerBuffer.length}');
          }
        }
        notifyListeners();
      }

      debugPrint('  Stream finished. Total events: $eventCount. Final event: $finalResponseEvent');
    } catch (e, stack) {
      debugPrint('  ERROR in stream loop: $e');
      debugPrint('$stack');
      rethrow;
    }

    _isCurrentlyThinking = false;
    _isStreaming = false;
    notifyListeners();
    debugPrint('=== [Gemma Demo] _generateResponseLoop finished ===');

    // Check if the final event is a Tool Call response
    if (finalResponseEvent is FunctionCallResponse) {
      await _executeToolCall(finalResponseEvent);
    } else if (finalResponseEvent is ParallelFunctionCallResponse) {
      for (final call in finalResponseEvent.calls) {
        await _executeToolCall(call);
      }
    }
  }

  Future<void> _executeToolCall(FunctionCallResponse call) async {
    _executingToolName = call.name;
    _executingToolArgs = call.args;
    _showToolOverlay = true;
    notifyListeners();

    // Visual pause to let the user see the overlay
    await Future.delayed(const Duration(milliseconds: 1500));

    Map<String, dynamic> result = {};
    
    try {
      if (call.name == 'change_app_theme') {
        final color = call.args['color']?.toString().toLowerCase() ?? 'blue';
        await _settings.setAccentColor(color);
        result = {'status': 'success', 'message': 'Accent color changed to $color successfully'};
      } else if (call.name == 'show_system_dialog') {
        final title = call.args['title']?.toString() ?? 'Notification';
        final msg = call.args['message']?.toString() ?? '';
        result = {'status': 'success', 'dialog_title': title, 'dialog_message': msg};
        
        // Show dialog globally (via app key or simply using navigator context)
        _messages.add(Message.systemInfo(text: 'Tool: Raised Dialog "$title" - $msg', icon: 'announcement'));
      } else if (call.name == 'get_current_time') {
        result = {
          'status': 'success',
          'current_time': DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
        };
      } else {
        result = {'error': 'Unknown tool name'};
      }
    } catch (e) {
      result = {'error': e.toString()};
    }

    _showToolOverlay = false;
    _messages.add(Message.systemInfo(text: 'System: Tool "${call.name}" returned $result', icon: 'terminal'));
    notifyListeners();

    // Feed back to the chat and prompt next response
    if (_activeChat != null) {
      _isStreaming = true;
      notifyListeners();
      
      final responseMsg = Message.toolResponse(toolName: call.name, response: result);
      await _activeChat!.addQueryChunk(responseMsg);
      await _generateResponseLoop();
    }
  }

  Future<void> clearHistory() async {
    if (_activeChat == null || _isStreaming) return;
    await _activeChat!.clearHistory();
    _messages = [
      Message.systemInfo(text: 'System: Conversation history cleared.', icon: 'refresh')
    ];
    notifyListeners();
  }

  @override
  void dispose() {
    _activeChat?.close();
    super.dispose();
  }
}

class RAGProvider extends ChangeNotifier {
  final ModelDownloadManager _downloadManager;
  bool _isInitialized = false;
  bool _isLoading = false;
  
  int _documentCount = 0;
  int _dimension = 0;
  
  List<RetrievalResult> _searchResults = [];

  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  int get documentCount => _documentCount;
  int get dimension => _dimension;
  List<RetrievalResult> get searchResults => _searchResults;

  RAGProvider(this._downloadManager) {
    _checkInit();
  }

  void _checkInit() async {
    // If Gecko embedder is installed, initialize vector store automatically
    if (_downloadManager.installedModels['gecko_64'] == true) {
      await initializeRAG();
    }
  }

  Future<void> initializeRAG() async {
    _isLoading = true;
    notifyListeners();
    try {
      // 1. Activate embedder model
      final spec = EmbeddingModelSpec(
        name: 'Gecko_64_quant',
        modelSource: ModelSource.network(kEmbedderModelUrl),
        tokenizerSource: ModelSource.network(kEmbedderTokenizerUrl),
      );
      FlutterGemmaPlugin.instance.modelManager.setActiveModel(spec);
      
      // Load active embedder
      await FlutterGemma.getActiveEmbedder(preferredBackend: PreferredBackend.cpu);
      
      // 2. Init Qdrant store
      await FlutterGemmaPlugin.instance.initializeVectorStore('rag_database');
      _isInitialized = true;
      
      await refreshStats();
    } catch (e) {
      debugPrint('Error initializing RAG: $e');
      _isInitialized = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshStats() async {
    if (!_isInitialized) return;
    try {
      final stats = await FlutterGemmaPlugin.instance.getVectorStoreStats();
      _documentCount = stats.documentCount;
      _dimension = stats.vectorDimension;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> addDocument(String id, String content, String category) async {
    if (!_isInitialized) return;
    _isLoading = true;
    notifyListeners();

    try {
      final metadata = jsonEncode({
        'category': category,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      await FlutterGemmaPlugin.instance.addDocument(
        id: id,
        content: content,
        metadata: metadata,
      );
      
      await refreshStats();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> performSearch(String query, {String? categoryFilter, int topK = 3}) async {
    if (!_isInitialized) return;
    _isLoading = true;
    notifyListeners();

    try {
      Filter? filter;
      if (categoryFilter != null && categoryFilter.isNotEmpty && categoryFilter != 'All') {
        filter = Filter(
          must: [FieldEquals(key: 'category', value: categoryFilter)]
        );
      }

      _searchResults = await FlutterGemmaPlugin.instance.searchSimilar(
        query: query,
        topK: topK,
        filter: filter,
      );
    } catch (e) {
      debugPrint('Search error: $e');
      _searchResults = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> clearDatabase() async {
    if (!_isInitialized) return;
    _isLoading = true;
    notifyListeners();
    try {
      await FlutterGemmaPlugin.instance.clearVectorStore();
      _searchResults = [];
      await refreshStats();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

// ============================================================================
// MAIN APPLICATION ROOT WIDGET
// ============================================================================

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      child: const MainAppWrapper(),
    );
  }
}

class MultiProvider extends StatefulWidget {
  final Widget child;
  const MultiProvider({super.key, required this.child});

  @override
  State<MultiProvider> createState() => _MultiProviderState();

  static T of<T>(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<_InheritedMultiProvider>();
    if (provider == null) {
      throw Exception('MultiProvider not found in context');
    }
    if (T == SettingsProvider) return provider.settings as T;
    if (T == ModelDownloadManager) return provider.downloadManager as T;
    if (T == ChatPlaygroundProvider) return provider.chatPlayground as T;
    if (T == RAGProvider) return provider.rag as T;
    throw Exception('Provider of type $T not found');
  }
}

class _InheritedMultiProvider extends InheritedWidget {
  final SettingsProvider settings;
  final ModelDownloadManager downloadManager;
  final ChatPlaygroundProvider chatPlayground;
  final RAGProvider rag;
  final int updateCounter;

  const _InheritedMultiProvider({
    required this.settings,
    required this.downloadManager,
    required this.chatPlayground,
    required this.rag,
    required this.updateCounter,
    required super.child,
  });

  @override
  bool updateShouldNotify(_InheritedMultiProvider oldWidget) {
    return oldWidget.updateCounter != updateCounter;
  }
}

class _MultiProviderState extends State<MultiProvider> {
  late final SettingsProvider _settings;
  late final ModelDownloadManager _downloadManager;
  late final ChatPlaygroundProvider _chatPlayground;
  late final RAGProvider _rag;
  int _updateCounter = 0;

  @override
  void initState() {
    super.initState();
    _settings = SettingsProvider();
    _downloadManager = ModelDownloadManager(_settings);
    _chatPlayground = ChatPlaygroundProvider(_settings, _downloadManager);
    _rag = RAGProvider(_downloadManager);
    
    _settings.addListener(_onStateChanged);
    _downloadManager.addListener(_onStateChanged);
    _chatPlayground.addListener(_onStateChanged);
    _rag.addListener(_onStateChanged);
  }

  void _onStateChanged() {
    setState(() {
      _updateCounter++;
    });
  }

  @override
  void dispose() {
    _settings.removeListener(_onStateChanged);
    _downloadManager.removeListener(_onStateChanged);
    _chatPlayground.removeListener(_onStateChanged);
    _rag.removeListener(_onStateChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _InheritedMultiProvider(
      settings: _settings,
      downloadManager: _downloadManager,
      chatPlayground: _chatPlayground,
      rag: _rag,
      updateCounter: _updateCounter,
      child: widget.child,
    );
  }
}

class MainAppWrapper extends StatelessWidget {
  const MainAppWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = MultiProvider.of<SettingsProvider>(context);
    return MaterialApp(
      title: 'OFFLINE AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme(settings.accentColor, settings.isDarkMode),
      home: const MainLayoutScreen(),
    );
  }
}

// ============================================================================
// MAIN SIDEBAR NAVIGATION SYSTEM
// ============================================================================

enum NavigationTab { models, chat, rag, settings }

class MainLayoutScreen extends StatefulWidget {
  const MainLayoutScreen({super.key});

  @override
  State<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends State<MainLayoutScreen> {
  NavigationTab _activeTab = NavigationTab.models;

  @override
  Widget build(BuildContext context) {
    final settings = MultiProvider.of<SettingsProvider>(context);
    final chatProvider = MultiProvider.of<ChatPlaygroundProvider>(context);
    
    return Scaffold(
      body: Stack(
        children: [
          Row(
            children: [
              // 1. Sleek Navigation Sidebar
              Container(
                width: 250,
                color: AppColors.sidebarBackground,
                child: Column(
                  children: [
                    // Brand / Logo Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: settings.accentColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.blur_on_rounded, color: settings.accentColor, size: 28),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'OFFLINE AI',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Loaded Model Info Badge
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: chatProvider.activeModelInfo != null ? AppColors.success : AppColors.textSecondary,
                                boxShadow: chatProvider.activeModelInfo != null ? [
                                  BoxShadow(
                                    color: AppColors.success.withOpacity(0.4),
                                    blurRadius: 6,
                                    spreadRadius: 2,
                                  )
                                ] : [],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                chatProvider.activeModelInfo != null
                                    ? chatProvider.activeModelInfo!.name
                                    : 'No model loaded',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, overflow: TextOverflow.ellipsis),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Sidebar Navigation Links
                    _buildNavItem(NavigationTab.models, Icons.developer_board_rounded, 'Model Manager'),
                    _buildNavItem(NavigationTab.chat, Icons.forum_rounded, 'AI Chat Playground'),
                    _buildNavItem(NavigationTab.rag, Icons.menu_book_rounded, 'Vector Knowledge'),
                    _buildNavItem(NavigationTab.settings, Icons.settings_suggest_rounded, 'Settings'),
                    
                    const Spacer(),
                    
                    // User metadata & macOS Platform indicator
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Row(
                        children: [
                          Icon(Icons.apple, color: AppColors.textSecondary.withOpacity(0.7), size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'macOS Apple Silicon',
                            style: TextStyle(fontSize: 11, color: AppColors.textSecondary.withOpacity(0.7)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // 2. Primary Workspace Panel
              Expanded(
                child: Container(
                  color: AppColors.background,
                  child: _buildActiveTabWidget(),
                ),
              ),
            ],
          ),
          
          // 3. Custom Function Calling Execution Overlay
          if (chatProvider.showToolOverlay)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.6),
                child: Center(
                  child: Container(
                    width: 380,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: settings.accentColor.withOpacity(0.4), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: settings.accentColor.withOpacity(0.2),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.terminal_rounded, color: settings.accentColor, size: 24),
                            const SizedBox(width: 10),
                            const Text(
                              'Executing System Tool',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.border.withOpacity(0.4)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Function: ${chatProvider.executingToolName}',
                                style: const TextStyle(fontFamily: 'Courier', fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Args: ${jsonEncode(chatProvider.executingToolArgs)}',
                                style: TextStyle(fontFamily: 'Courier', color: AppColors.textSecondary, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNavItem(NavigationTab tab, IconData icon, String title) {
    final settings = MultiProvider.of<SettingsProvider>(context);
    final isSelected = _activeTab == tab;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _activeTab = tab),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            decoration: BoxDecoration(
              color: isSelected ? settings.accentColor.withOpacity(0.12) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected ? settings.accentColor : AppColors.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: 14),
                Text(
                  title,
                  style: TextStyle(
                    color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveTabWidget() {
    switch (_activeTab) {
      case NavigationTab.models:
        return const ModelManagerView();
      case NavigationTab.chat:
        return const ChatPlaygroundView();
      case NavigationTab.rag:
        return const RAGView();
      case NavigationTab.settings:
        return const SettingsView();
    }
  }
}

// ============================================================================
// TAB VIEW 1: MODEL MANAGER VIEW
// ============================================================================

class ModelManagerView extends StatelessWidget {
  const ModelManagerView({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = MultiProvider.of<SettingsProvider>(context);
    final dm = MultiProvider.of<ModelDownloadManager>(context);
    final chat = MultiProvider.of<ChatPlaygroundProvider>(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(40.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Row(
                  children: [
                    Text('Model Manager', style: Theme.of(context).textTheme.titleLarge),
                    const Spacer(),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: settings.accentColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onPressed: () => dm.refreshInstallationStatuses(),
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const TextStyle(fontWeight: FontWeight.bold).buildText('Refresh Status'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text('Download and activate local LLM weight files to run secure on-device AI inference.'),
                const SizedBox(height: 32),
                
                // Embedded Vector Model Card (RAG core dependency)
                _buildEmbedderCard(context, settings, dm),
                const SizedBox(height: 24),
                
                Text('Available Chat Models', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 16),
              ]),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                mainAxisExtent: 260,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final model = kSupportedModels[index];
                  return _buildModelCard(context, settings, dm, chat, model);
                },
                childCount: kSupportedModels.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildEmbedderCard(BuildContext context, SettingsProvider settings, ModelDownloadManager dm) {
    final isInstalled = dm.installedModels['gecko_64'] == true;
    final dState = dm.getDownloadState('gecko_64');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: settings.accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.hub, color: settings.accentColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('Gecko 110M Embedding Model & Tokenizer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(width: 10),
                          _buildBadge(isInstalled ? 'Installed' : 'Not Downloaded', isInstalled ? AppColors.success : AppColors.textSecondary),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text('Required model configuration for local semantic databases (RAG). Extracts concepts into mathematical coordinate structures.'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (dState.isDownloading) ...[
              _buildDownloadProgress(context, settings, dm, 'gecko_64', dState),
            ] else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('Size: ~111 MB', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                  const Spacer(),
                  if (isInstalled)
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onPressed: () => _confirmDelete(context, dm, 'gecko_64'),
                      icon: const Icon(Icons.delete_sweep, size: 16),
                      label: const Text('Delete Files'),
                    )
                  else
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: settings.accentColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onPressed: () => dm.startEmbedderDownload(),
                      icon: const Icon(Icons.download_rounded, size: 16),
                      label: const Text('Download Embedder'),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildModelCard(BuildContext context, SettingsProvider settings, ModelDownloadManager dm, ChatPlaygroundProvider chat, AppModelInfo model) {
    final isInstalled = dm.installedModels[model.id] == true;
    final dState = dm.getDownloadState(model.id);
    final isActive = chat.activeModelInfo?.id == model.id;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    model.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, overflow: TextOverflow.ellipsis),
                  ),
                ),
                _buildBadge(isInstalled ? 'Ready' : 'Downloadable', isInstalled ? AppColors.success : AppColors.warning),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Text(
                model.description,
                style: const TextStyle(fontSize: 12, height: 1.4),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            
            // Capability Row Badges
            Row(
              children: [
                if (model.supportImage) _buildTag('Multimodal'),
                if (model.supportThinking) _buildTag('Thinking'),
                if (model.supportFunctionCalling) _buildTag('Tool Use'),
              ],
            ),
            
            const SizedBox(height: 16),
            if (dState.isDownloading) ...[
              _buildDownloadProgress(context, settings, dm, model.id, dState),
            ] else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Size: ${model.sizeGB.toStringAsFixed(2)} GB', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  Row(
                    children: [
                      if (isInstalled) ...[
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: BorderSide(color: AppColors.error),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                          onPressed: () => _confirmDelete(context, dm, model.id),
                          child: const Icon(Icons.delete_outline, size: 16),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isActive ? AppColors.success : settings.accentColor,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: isActive ? null : () => chat.loadInferenceModel(model),
                          child: Text(isActive ? 'Active' : 'Load Model'),
                        ),
                      ] else ...[
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: settings.accentColor,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => dm.startModelDownload(model),
                          icon: const Icon(Icons.download_rounded, size: 14),
                          label: const Text('Download'),
                        ),
                      ],
                    ],
                  )
                ],
              )
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadProgress(BuildContext context, SettingsProvider settings, ModelDownloadManager dm, String modelId, DownloadState dState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                '${dState.statusText} (${dState.progress}%)',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: Icon(Icons.cancel_rounded, color: AppColors.error, size: 18),
              onPressed: () => dm.cancelDownload(modelId),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: dState.progress / 100.0,
            backgroundColor: AppColors.border,
            color: settings.accentColor,
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Speed: ${dState.speedMBs.toStringAsFixed(1)} MB/s', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            Text('ETA: ${dState.eta}', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ],
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildTag(String label) {
    return Container(
      margin: const EdgeInsets.only(right: 6, top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.textPrimary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 9.5, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
      ),
    );
  }

  void _confirmDelete(BuildContext context, ModelDownloadManager dm, String modelId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.cardBackground,
          title: const Text('Delete Model Weights'),
          content: const Text('This will delete all downloaded model weights on disk. You can download them again later.'),
          actions: [
            TextButton(
              child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Delete', style: TextStyle(color: AppColors.error)),
              onPressed: () {
                dm.deleteModelFiles(modelId);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}

// ============================================================================
// TAB VIEW 2: AI PLAYGROUND CHAT
// ============================================================================

class ChatPlaygroundView extends StatefulWidget {
  const ChatPlaygroundView({super.key});

  @override
  State<ChatPlaygroundView> createState() => _ChatPlaygroundViewState();
}

class _ChatPlaygroundViewState extends State<ChatPlaygroundView> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = MultiProvider.of<SettingsProvider>(context);
    final chat = MultiProvider.of<ChatPlaygroundProvider>(context);

    // Trigger scroll to bottom on new message
    if (chat.messages.isNotEmpty) {
      _scrollToBottom();
    }

    if (chat.activeChat == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline_rounded, size: 64, color: settings.accentColor.withOpacity(0.4)),
            const SizedBox(height: 20),
            const Text('No model is active.', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Head to the Model Manager to download and load a model.', style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          // Chat Workspace Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(chat.activeModelInfo!.name, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 4),
                    const Text('Secure, local conversation pipeline accelerated via Metal (GPU)'),
                  ],
                ),
                const Spacer(),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: BorderSide(color: AppColors.border.withOpacity(0.5)),
                  ),
                  onPressed: () => chat.clearHistory(),
                  icon: const Icon(Icons.delete_sweep_rounded, size: 16),
                  label: const Text('Clear Chat'),
                ),
              ],
            ),
          ),
          
          Divider(color: AppColors.border, height: 1),

          // Message Stream Area
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
              itemCount: chat.messages.length + (chat.isCurrentlyThinking ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == chat.messages.length) {
                  return _buildMessageRow(
                    context,
                    settings,
                    chat,
                    Message.thinking(text: chat.thinkingText),
                  );
                }
                final message = chat.messages[index];
                return _buildMessageRow(context, settings, chat, message);
              },
            ),
          ),

          // Input Bar / Compose Widget
          _buildComposeArea(context, settings, chat),
        ],
      ),
    );
  }

  Widget _buildMessageRow(BuildContext context, SettingsProvider settings, ChatPlaygroundProvider chat, Message msg) {
    if (msg.type == MessageType.systemInfo) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.cardBackground.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_getSystemIcon(msg.toolName), size: 14, color: settings.accentColor),
                const SizedBox(width: 8),
                Text(msg.text, style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontFamily: 'Courier')),
              ],
            ),
          ),
        ),
      );
    }

    if (msg.type == MessageType.thinking) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.thinking.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.thinking.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.psychology_outlined, size: 18, color: AppColors.thinking),
                  const SizedBox(width: 8),
                  Text('Reasoning Process...', style: TextStyle(color: AppColors.thinking, fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                msg.text.isNotEmpty ? msg.text : 'Thinking...',
                style: TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 12,
                  color: AppColors.textPrimary.withOpacity(0.8),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final isUser = msg.isUser;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              backgroundColor: settings.accentColor.withOpacity(0.15),
              radius: 16,
              child: Icon(Icons.blur_on_rounded, color: settings.accentColor, size: 18),
            ),
            const SizedBox(width: 14),
          ],
          
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SelectionArea(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isUser ? settings.accentColor : AppColors.cardBackground,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: isUser ? const Radius.circular(16) : Radius.zero,
                        bottomRight: isUser ? Radius.zero : const Radius.circular(16),
                      ),
                      border: isUser ? null : Border.all(color: AppColors.border.withOpacity(0.4)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Image Attachment Preview inside chat bubble
                        if (msg.hasImage) ...[
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 320, maxHeight: 200),
                                child: Image.memory(
                                  msg.imageBytes!,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        ],
                        
                        // Main message body with markdown & code support
                        FormattedMessageView(
                          text: msg.text,
                          isUser: isUser,
                          accentColor: settings.accentColor,
                        ),
                      ],
                    ),
                  ),
                ),
                // Small Action Row below the bubble for quick copying
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _SmallCopyIconButton(textToCopy: msg.text),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          if (isUser) ...[
            const SizedBox(width: 14),
            CircleAvatar(
              backgroundColor: AppColors.border,
              radius: 16,
              child: Icon(Icons.person, color: AppColors.textPrimary, size: 18),
            ),
          ],
        ],
      ),
    );
  }

  IconData _getSystemIcon(String? iconKey) {
    switch (iconKey) {
      case 'offline_bolt':
        return Icons.offline_bolt_rounded;
      case 'terminal':
        return Icons.terminal_rounded;
      case 'announcement':
        return Icons.announcement_rounded;
      case 'refresh':
        return Icons.refresh_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }

  Widget _buildComposeArea(BuildContext context, SettingsProvider settings, ChatPlaygroundProvider chat) {
    void handleSend() {
      if (_controller.text.trim().isNotEmpty || chat.selectedImageBytes != null) {
        chat.sendMessage(_controller.text);
        _controller.clear();
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border.all(color: AppColors.border.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Selected attachment indicator
          if (chat.selectedImageBytes != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border.withOpacity(0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.memory(
                        chat.selectedImageBytes!,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text('Image Attachment Ready', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                    const SizedBox(width: 10),
                    IconButton(
                      icon: Icon(Icons.close, size: 16, color: AppColors.error),
                      onPressed: chat.clearSelectedImage,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ),
            
          Row(
            children: [
              // Multimodal Attachment Button
              if (chat.activeModelInfo?.supportImage == true)
                IconButton(
                  icon: Icon(Icons.add_photo_alternate_rounded, color: settings.accentColor),
                  tooltip: 'Pick image for analysis',
                  onPressed: chat.selectImage,
                ),
                
              const SizedBox(width: 10),
              
              // Text Compose field with Enter key logic
              Expanded(
                child: Focus(
                  onKeyEvent: (node, event) {
                    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.enter) {
                      if (HardwareKeyboard.instance.isShiftPressed) {
                        return KeyEventResult.ignored;
                      } else {
                        handleSend();
                        return KeyEventResult.handled;
                      }
                    }
                    return KeyEventResult.ignored;
                  },
                  child: TextField(
                    controller: _controller,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    style: const TextStyle(fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: 'Ask your local AI a question or supply an image...',
                    ),
                    onSubmitted: (val) => handleSend(),
                  ),
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Submit button
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: settings.accentColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(12),
                ),
                icon: const Icon(Icons.send_rounded, size: 20),
                onPressed: handleSend,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// TAB VIEW 3: VECTOR STORE (RAG) VIEW
// ============================================================================

class RAGView extends StatefulWidget {
  const RAGView({super.key});

  @override
  State<RAGView> createState() => _RAGViewState();
}

class _RAGViewState extends State<RAGView> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  
  String _selectedCategory = 'General';
  String _selectedSearchFilter = 'All';

  final List<String> _categories = ['General', 'Tech', 'Health', 'Finance', 'Travel'];

  @override
  Widget build(BuildContext context) {
    final settings = MultiProvider.of<SettingsProvider>(context);
    final dm = MultiProvider.of<ModelDownloadManager>(context);
    final rag = MultiProvider.of<RAGProvider>(context);

    // Force unique ID on load if empty
    if (_idController.text.isEmpty) {
      _idController.text = 'doc_${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
    }

    if (!dm.installedModels['gecko_64']!) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.sd_card_alert_rounded, size: 64, color: settings.accentColor.withOpacity(0.4)),
              const SizedBox(height: 20),
              const Text('Embedder Model Required', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
               Text(
                'RAG relies on Gecko 64 to encode text. Please download the Gecko embedder in the Model Manager.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    if (!rag.isInitialized) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(),
            ),
            const SizedBox(height: 16),
            const Text('Configuring native Qdrant-edge vector database...'),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => rag.initializeRAG(),
              child: const Text('Retry Setup'),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Vector Knowledge Base (RAG)', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 4),
                    const Text('On-device vector database using fast native qdrant-edge.'),
                  ],
                ),
                const Spacer(),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: BorderSide(color: AppColors.error.withOpacity(0.5)),
                  ),
                  onPressed: () => _confirmClear(context, rag),
                  icon: const Icon(Icons.delete_forever_rounded, size: 16),
                  label: const Text('Purge Database'),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Database Statistics Panel
            Row(
              children: [
                _buildStatCard('Total Documents', '${rag.documentCount}', Icons.description_rounded, settings),
                const SizedBox(width: 20),
                _buildStatCard('Vector Dimensions', '${rag.dimension} D', Icons.grid_goldenratio_rounded, settings),
                const SizedBox(width: 20),
                _buildStatCard('Backend Store', 'Qdrant-Edge FFI', Icons.security_rounded, settings),
              ],
            ),
            
            const SizedBox(height: 40),
            
            // Core Workspace Split: Left (Add), Right (Search)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Workspace Left: Insert Document
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Add Document Segment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _idController,
                        style: const TextStyle(fontSize: 13, fontFamily: 'Courier'),
                        decoration: const InputDecoration(labelText: 'Unique ID'),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Text('Category Tag: ', style: TextStyle(color: AppColors.textSecondary)),
                          const SizedBox(width: 10),
                          DropdownButton<String>(
                            value: _selectedCategory,
                            dropdownColor: AppColors.cardBackground,
                            underline: const SizedBox(),
                            items: _categories.map((c) {
                              return DropdownMenuItem(value: c, child: Text(c));
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedCategory = val);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _contentController,
                        maxLines: 6,
                        style: const TextStyle(fontSize: 13.5),
                        decoration: const InputDecoration(
                          hintText: 'Type or paste document segment content...',
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: settings.accentColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        ),
                        onPressed: rag.isLoading ? null : () async {
                          final id = _idController.text.trim();
                          final content = _contentController.text.trim();
                          if (id.isNotEmpty && content.isNotEmpty) {
                            await rag.addDocument(id, content, _selectedCategory);
                            _contentController.clear();
                            // Generate new ID
                            _idController.text = 'doc_${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Document ingested successfully!')),
                            );
                          }
                        },
                        icon: const Icon(Icons.add_task_rounded, size: 16),
                        label: const Text('Ingest & Compute Embeddings'),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 40),
                
                // Workspace Right: Semantic Search
                Expanded(
                  flex: 6,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Semantic Similarity Search', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              style: const TextStyle(fontSize: 13.5),
                              decoration: const InputDecoration(
                                hintText: 'Query search (e.g. "Google Gemma features")',
                              ),
                              onSubmitted: (val) {
                                if (val.trim().isNotEmpty) {
                                  rag.performSearch(val, categoryFilter: _selectedSearchFilter);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          DropdownButton<String>(
                            value: _selectedSearchFilter,
                            dropdownColor: AppColors.cardBackground,
                            underline: const SizedBox(),
                            items: ['All', ..._categories].map((c) {
                              return DropdownMenuItem(value: c, child: Text(c));
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedSearchFilter = val);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: settings.accentColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        ),
                        onPressed: rag.isLoading ? null : () {
                          final query = _searchController.text.trim();
                          if (query.isNotEmpty) {
                            rag.performSearch(query, categoryFilter: _selectedSearchFilter);
                          }
                        },
                        icon: const Icon(Icons.search_rounded, size: 16),
                        label: const Text('Similarity Search'),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Search Results list
                      if (rag.searchResults.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppColors.cardBackground.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border.withOpacity(0.3)),
                          ),
                          child: Center(
                            child: Text('No matching records. Run a search to test.', style: TextStyle(color: AppColors.textSecondary)),
                          ),
                        )
                      else
                        ...rag.searchResults.map((result) {
                          // Try decoding metadata
                          String category = 'General';
                          try {
                            if (result.metadata != null) {
                              final meta = jsonDecode(result.metadata!);
                              category = meta['category'] ?? 'General';
                            }
                          } catch (_) {}

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(result.id, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Courier')),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: settings.accentColor.withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(category, style: TextStyle(color: settings.accentColor, fontSize: 10, fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Text(result.content, style: const TextStyle(fontSize: 13)),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Icon(Icons.query_stats_rounded, size: 14, color: AppColors.success),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Cosine Similarity: ${(result.similarity * 100).toStringAsFixed(1)}%',
                                          style: TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, SettingsProvider settings) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border.withOpacity(0.5)),
        ),
        child: Row(
          children: [
            Icon(icon, color: settings.accentColor, size: 28),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            )
          ],
        ),
      ),
    );
  }

  void _confirmClear(BuildContext context, RAGProvider rag) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.cardBackground,
          title: const Text('Purge Database'),
          content: const Text('Are you sure you want to clear all documents inside the vector store?'),
          actions: [
            TextButton(
              child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Purge', style: TextStyle(color: AppColors.error)),
              onPressed: () {
                rag.clearDatabase();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}

// ============================================================================
// TAB VIEW 4: APPLICATION SETTINGS
// ============================================================================

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final TextEditingController _tokenController = TextEditingController();
  bool _obscureToken = true;

  @override
  Widget build(BuildContext context) {
    final settings = MultiProvider.of<SettingsProvider>(context);
    final dm = MultiProvider.of<ModelDownloadManager>(context);

    if (_tokenController.text.isEmpty && settings.hfToken.isNotEmpty) {
      _tokenController.text = settings.hfToken;
    }

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Settings', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            const Text('Configure credentials, hardware preference, and accent theme colors.'),
            
            const SizedBox(height: 40),
            
            // HuggingFace Token Config
            const Text('HuggingFace Access Token', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            Text(
              'Required to verify credentials when downloading gated model repositories (e.g. Gemma 4). Your token is saved securely in your macOS application preferences.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tokenController,
                    obscureText: _obscureToken,
                    style: const TextStyle(fontSize: 13, fontFamily: 'Courier'),
                    decoration: InputDecoration(
                      hintText: 'Enter your hf_... token',
                      suffixIcon: IconButton(
                        icon: Icon(_obscureToken ? Icons.visibility_off : Icons.visibility, color: AppColors.textSecondary),
                        onPressed: () => setState(() => _obscureToken = !_obscureToken),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: settings.accentColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                  ),
                  onPressed: () async {
                    await settings.setHfToken(_tokenController.text.trim());
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('HuggingFace Token saved successfully!')),
                    );
                  },
                  child: const Text('Save Token'),
                ),
              ],
            ),
            
            const SizedBox(height: 40),
            
            // Hardware Backend Preference
            const Text('Preferred Hardware Acceleration', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            Text(
              'Select Metal GPU for fast parallel tensor computations, or fallback to CPU if GPU memory is constrained.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildRadioTile('Metal GPU (Recommended)', PreferredBackend.gpu, settings),
                const SizedBox(width: 20),
                _buildRadioTile('Standard CPU', PreferredBackend.cpu, settings),
              ],
            ),
            
            const SizedBox(height: 40),

            // Theme Mode
            const Text('App Theme Mode', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            Text(
              'Switch between Light Mode and Dark Mode for the application workspace.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildThemeTile('Dark Mode', Icons.dark_mode_rounded, true, settings),
                const SizedBox(width: 20),
                _buildThemeTile('Light Mode', Icons.light_mode_rounded, false, settings),
              ],
            ),
            
            const SizedBox(height: 40),
            
            // Theme Accent color
            const Text('App Theme Accent Color', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            Row(
              children: AppColors.accents.keys.map((colorName) {
                final color = AppColors.accents[colorName]!;
                final isSelected = settings.accentName == colorName;
                return GestureDetector(
                  onTap: () => settings.setAccentColor(colorName),
                  child: Container(
                    margin: const EdgeInsets.only(right: 16),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
                      boxShadow: isSelected ? [
                        BoxShadow(
                          color: color.withOpacity(0.5),
                          blurRadius: 10,
                          spreadRadius: 2,
                        )
                      ] : [],
                    ),
                  ),
                );
              }).toList(),
            ),
            
            const SizedBox(height: 48),
            Divider(color: AppColors.border),
            const SizedBox(height: 24),
            
            // Disk cleanup stats
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Storage Maintenance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 4),
                    const Text('Clean temporary cache archives and remove unreferenced package downloads.', style: TextStyle(fontSize: 12)),
                  ],
                ),
                const Spacer(),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.border,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: dm.isCleaning ? null : () => dm.runOrphanedCleanup(),
                  icon: dm.isCleaning
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.cleaning_services_rounded, size: 14),
                  label: Text(dm.isCleaning ? 'Cleaning...' : 'Prune Storage'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRadioTile(String label, PreferredBackend value, SettingsProvider settings) {
    final isSelected = settings.backend == value;
    return GestureDetector(
      onTap: () => settings.setBackend(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? settings.accentColor.withOpacity(0.08) : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? settings.accentColor : AppColors.border.withOpacity(0.4),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              color: isSelected ? settings.accentColor : AppColors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeTile(String label, IconData icon, bool targetDarkMode, SettingsProvider settings) {
    final isSelected = settings.isDarkMode == targetDarkMode;
    return GestureDetector(
      onTap: () {
        if (settings.isDarkMode != targetDarkMode) {
          settings.toggleThemeMode();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? settings.accentColor.withOpacity(0.08) : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? settings.accentColor : AppColors.border.withOpacity(0.4),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? settings.accentColor : AppColors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// HELPER EXTENSIONS
// ============================================================================

extension TextBuilder on TextStyle {
  Widget buildText(String text) {
    return Text(text, style: this);
  }
}

// ============================================================================
// FORMATTED MARKDOWN & CODE BLOCKS
// ============================================================================

class FormattedMessageView extends StatelessWidget {
  final String text;
  final bool isUser;
  final Color? accentColor;

  const FormattedMessageView({
    super.key,
    required this.text,
    required this.isUser,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = [];
    final RegExp codeBlockRegex = RegExp(r'```(\w*)\r?\n([\s\S]*?)(?:```|$)');
    
    int lastIndex = 0;
    for (final match in codeBlockRegex.allMatches(text)) {
      // Add preceding text segment
      if (match.start > lastIndex) {
        final textSegment = text.substring(lastIndex, match.start);
        if (textSegment.isNotEmpty) {
          children.add(_buildTextSegment(context, textSegment));
        }
      }
      
      // Add code block segment
      final language = match.group(1) ?? '';
      final code = match.group(2) ?? '';
      children.add(_buildCodeBlock(context, language, code));
      
      lastIndex = match.end;
    }
    
    // Add remaining text
    if (lastIndex < text.length) {
      final textSegment = text.substring(lastIndex);
      if (textSegment.isNotEmpty) {
        children.add(_buildTextSegment(context, textSegment));
      }
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }

  Widget _buildTextSegment(BuildContext context, String text) {
    final lines = text.split('\n');
    final List<Widget> lineWidgets = [];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final trimmedLine = line.trimLeft();
      
      // Header check
      if (trimmedLine.startsWith('### ')) {
        lineWidgets.add(Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 4),
          child: Text.rich(
            TextSpan(
              children: _parseInlineMarkdown(trimmedLine.substring(4)),
              style: TextStyle(
                color: isUser ? Colors.white : AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
            ),
          ),
        ));
      } else if (trimmedLine.startsWith('## ')) {
        lineWidgets.add(Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 6),
          child: Text.rich(
            TextSpan(
              children: _parseInlineMarkdown(trimmedLine.substring(3)),
              style: TextStyle(
                color: isUser ? Colors.white : AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
            ),
          ),
        ));
      } else if (trimmedLine.startsWith('# ')) {
        lineWidgets.add(Padding(
          padding: const EdgeInsets.only(top: 18, bottom: 8),
          child: Text.rich(
            TextSpan(
              children: _parseInlineMarkdown(trimmedLine.substring(2)),
              style: TextStyle(
                color: isUser ? Colors.white : AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
            ),
          ),
        ));
      } 
      // Bullet list item check
      else if (trimmedLine.startsWith('- ') || trimmedLine.startsWith('* ') || trimmedLine.startsWith('• ')) {
        final content = trimmedLine.substring(2);
        lineWidgets.add(Padding(
          padding: const EdgeInsets.only(left: 12, top: 4, bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '• ',
                style: TextStyle(
                  color: isUser ? Colors.white : accentColor ?? AppColors.success,
                  fontSize: 14.5,
                  height: 1.45,
                ),
              ),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: _parseInlineMarkdown(content),
                    style: TextStyle(
                      color: isUser ? Colors.white : AppColors.textPrimary,
                      fontSize: 14.5,
                      height: 1.45,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ));
      }
      // Numbered list item check
      else if (RegExp(r'^\d+\.\s+').hasMatch(trimmedLine)) {
        final match = RegExp(r'^(\d+\.\s+)').firstMatch(trimmedLine)!;
        final prefix = match.group(1)!;
        final content = trimmedLine.substring(prefix.length);
        lineWidgets.add(Padding(
          padding: const EdgeInsets.only(left: 12, top: 4, bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                prefix,
                style: TextStyle(
                  color: isUser ? Colors.white : accentColor ?? AppColors.success,
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                  height: 1.45,
                ),
              ),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: _parseInlineMarkdown(content),
                    style: TextStyle(
                      color: isUser ? Colors.white : AppColors.textPrimary,
                      fontSize: 14.5,
                      height: 1.45,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ));
      }
      // Normal paragraph line
      else {
        if (line.isEmpty) {
          if (i < lines.length - 1) {
            lineWidgets.add(const SizedBox(height: 8));
          }
        } else {
          lineWidgets.add(Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text.rich(
              TextSpan(
                children: _parseInlineMarkdown(line),
                style: TextStyle(
                  color: isUser ? Colors.white : AppColors.textPrimary,
                  fontSize: 14.5,
                  height: 1.45,
                ),
              ),
            ),
          ));
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: lineWidgets,
    );
  }

  List<InlineSpan> _parseInlineMarkdown(String text) {
    final List<InlineSpan> spans = [];
    final RegExp inlineRegex = RegExp(
      r'(\*\*([^*]+)\*\*)|(\*([^*]+)\*)|((`{1,2})([^`]+)\6)|([^`*]+|[*`])',
      multiLine: true,
    );

    final matches = inlineRegex.allMatches(text);
    for (final match in matches) {
      if (match.group(2) != null) {
        // Bold: **text**
        spans.add(TextSpan(
          children: _parseInlineMarkdown(match.group(2)!),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ));
      } else if (match.group(4) != null) {
        // Italic: *text*
        spans.add(TextSpan(
          children: _parseInlineMarkdown(match.group(4)!),
          style: const TextStyle(fontStyle: FontStyle.italic),
        ));
      } else if (match.group(7) != null) {
        // Inline code: `code` or ``code``
        spans.add(TextSpan(
          text: '\u2009${match.group(7)}\u2009',
          style: TextStyle(
            fontFamily: 'Courier',
            backgroundColor: isUser 
                ? Colors.black.withOpacity(0.25) 
                : AppColors.textPrimary.withOpacity(0.08),
            color: isUser 
                ? Colors.white 
                : AppColors.getReadableAccent(accentColor ?? AppColors.success),
            fontWeight: FontWeight.w600,
          ),
        ));
      } else {
        // Plain text or unmatched punctuation
        spans.add(TextSpan(text: match.group(0)));
      }
    }
    
    if (spans.isEmpty && text.isNotEmpty) {
      spans.add(TextSpan(text: text));
    }
    return spans;
  }

  Widget _buildCodeBlock(BuildContext context, String language, String code) {
    final cleanCode = code.trimRight();
    final displayLanguage = language.isNotEmpty ? language : 'code';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E), // Premium dark editor background
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header of Code Block: Language & Copy Button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF2D2D2D),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
              border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  displayLanguage.toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFFCCCCCC),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Courier',
                  ),
                ),
                _CopyButton(textToCopy: cleanCode),
              ],
            ),
          ),
          
          // Code Display Area
          Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Text(
                cleanCode,
                style: const TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 13,
                  color: Color(0xFFD4D4D4),
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CopyButton extends StatefulWidget {
  final String textToCopy;
  const _CopyButton({required this.textToCopy});

  @override
  State<_CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<_CopyButton> {
  bool _copied = false;

  void _copy() {
    Clipboard.setData(ClipboardData(text: widget.textToCopy));
    setState(() => _copied = true);
    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _copied = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _copy,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _copied ? Icons.check : Icons.copy_rounded,
              size: 14,
              color: _copied ? AppColors.success : const Color(0xFFCCCCCC),
            ),
            const SizedBox(width: 6),
            Text(
              _copied ? 'Copied' : 'Copy',
              style: TextStyle(
                color: _copied ? AppColors.success : const Color(0xFFCCCCCC),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SmallCopyIconButton extends StatefulWidget {
  final String textToCopy;
  const _SmallCopyIconButton({required this.textToCopy});

  @override
  State<_SmallCopyIconButton> createState() => _SmallCopyIconButtonState();
}

class _SmallCopyIconButtonState extends State<_SmallCopyIconButton> {
  bool _copied = false;

  void _copy() {
    Clipboard.setData(ClipboardData(text: widget.textToCopy));
    setState(() => _copied = true);
    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _copied = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: _copied ? 'Copied!' : 'Copy message',
      child: InkWell(
        onTap: _copy,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(6.0),
          child: Icon(
            _copied ? Icons.check_circle_outline : Icons.content_copy_rounded,
            size: 14,
            color: _copied ? AppColors.success : AppColors.textSecondary.withOpacity(0.7),
          ),
        ),
      ),
    );
  }
}
