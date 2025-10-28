// lib/core/constants/app_constants.dart
class AppConstants {
  // 앱 정보
  static const String appName = 'Vibe Code';
  static const String appVersion = '1.0.0';

  // 파일 제한
  static const int maxFileSize = 100 * 1024 * 1024; // 100MB

  // ✅ 신규: 메시지 히스토리 제한
  static const int defaultMaxHistoryMessages = 20;
  static const int maxHistoryTokens = 8000;

  // ✅ 신규: 첨부 파일 제한
  static const int maxCharsPerTextFile = 3000; // 약 750 토큰 (텍스트 파일 요약)
  static const int maxCachedAttachments = 10; // 이미지 캐시 최대 개수

  // 데이터베이스
  static const String cacheDbName = 'cache.db';

  // 설정 키
  static const String settingsKeyApiKey = 'api_key';
  static const String settingsKeyModelPipeline = 'model_pipeline';
  static const String settingsKeyThemeMode = 'theme_mode';
  static const String settingsKeyPromptPresets = 'prompt_presets';
  static const String settingsKeySelectedPresetId = 'selected_preset_id';
  static const String settingsKeyMaxHistoryMessages = 'max_history_messages';

  // 모델 파이프라인 제한
  static const int maxPipelineModels = 5;
  static const int minPipelineModels = 1;

  // 코드 하이라이팅 언어 매핑
  static const Map<String, String> languageMap = {
    // Dart
    'dart': 'dart',
    'dartlang': 'dart',

    // JavaScript/TypeScript
    'javascript': 'javascript',
    'js': 'javascript',
    'jsx': 'javascript',
    'typescript': 'typescript',
    'ts': 'typescript',
    'tsx': 'typescript',

    // Python
    'python': 'python',
    'py': 'python',
    'python3': 'python',

    // Java/JVM
    'java': 'java',
    'kotlin': 'kotlin',
    'kt': 'kotlin',
    'scala': 'scala',
    'groovy': 'groovy',

    // C Family
    'c': 'c',
    'c++': 'cpp',
    'cpp': 'cpp',
    'cxx': 'cpp',
    'cc': 'cpp',
    'c#': 'cs',
    'csharp': 'cs',
    'cs': 'cs',
    'objectivec': 'objectivec',
    'objc': 'objectivec',

    // Swift
    'swift': 'swift',

    // Go
    'go': 'go',
    'golang': 'go',

    // Rust
    'rust': 'rust',
    'rs': 'rust',

    // PHP
    'php': 'php',

    // Ruby
    'ruby': 'ruby',
    'rb': 'ruby',

    // R
    'r': 'r',

    // Lua
    'lua': 'lua',

    // Perl
    'perl': 'perl',
    'pl': 'perl',

    // Haskell
    'haskell': 'haskell',
    'hs': 'haskell',

    // Elixir/Erlang
    'elixir': 'elixir',
    'ex': 'elixir',
    'erlang': 'erlang',
    'erl': 'erlang',

    // Web
    'html': 'xml',
    'htm': 'xml',
    'xml': 'xml',
    'css': 'css',
    'scss': 'scss',
    'sass': 'sass',
    'less': 'less',

    // Data formats
    'json': 'json',
    'yaml': 'yaml',
    'yml': 'yaml',
    'toml': 'ini',
    'ini': 'ini',

    // Markdown
    'markdown': 'markdown',
    'md': 'markdown',

    // Shell
    'bash': 'bash',
    'sh': 'bash',
    'shell': 'bash',
    'zsh': 'bash',
    'powershell': 'powershell',
    'ps1': 'powershell',
    'cmd': 'dos',
    'bat': 'dos',

    // SQL
    'sql': 'sql',
    'mysql': 'sql',
    'postgresql': 'sql',
    'postgres': 'sql',
    'sqlite': 'sql',
    'plsql': 'sql',

    // Functional
    'lisp': 'lisp',
    'scheme': 'scheme',
    'clojure': 'clojure',
    'ocaml': 'ocaml',
    'fsharp': 'fsharp',
    'f#': 'fsharp',

    // Assembly
    'assembly': 'x86asm',
    'asm': 'x86asm',
    'nasm': 'x86asm',

    // Mobile
    'gradle': 'gradle',
    'cmake': 'cmake',

    // DevOps
    'dockerfile': 'dockerfile',
    'docker': 'dockerfile',
    'makefile': 'makefile',
    'make': 'makefile',

    // LaTeX
    'latex': 'latex',
    'tex': 'latex',

    // Diff
    'diff': 'diff',
    'patch': 'diff',

    // GraphQL
    'graphql': 'graphql',
    'gql': 'graphql',

    // Protobuf
    'protobuf': 'protobuf',
    'proto': 'protobuf',

    // WASM
    'wasm': 'wasm',
    'wat': 'wasm',

    // Solidity (Blockchain)
    'solidity': 'solidity',
    'sol': 'solidity',

    // V Lang
    'v': 'v',
    'vlang': 'v',

    // Zig
    'zig': 'zig',

    // Nim
    'nim': 'nim',

    // Crystal
    'crystal': 'crystal',
    'cr': 'crystal',

    // Julia
    'julia': 'julia',
    'jl': 'julia',

    // MATLAB
    'matlab': 'matlab',
    'm': 'matlab',

    // Fortran
    'fortran': 'fortran',
    'f90': 'fortran',
    'f95': 'fortran',

    // COBOL
    'cobol': 'cobol',
    'cob': 'cobol',

    // Verilog/VHDL
    'verilog': 'verilog',
    'vhdl': 'vhdl',

    // Prolog
    'prolog': 'prolog',

    // SAS
    'sas': 'sas',

    // Smalltalk
    'smalltalk': 'smalltalk',

    // Plain text
    'text': 'plaintext',
    'txt': 'plaintext',
    'plain': 'plaintext',
  };

  // Private constructor
  AppConstants._();
}
