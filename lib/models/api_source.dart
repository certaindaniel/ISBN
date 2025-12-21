enum ApiSource {
  googleBooks,
  openLibrary,
  wikipedia,
  jikeFree,
}

class ApiSourceInfo {
  final ApiSource id;
  final String displayName;
  final String description;
  final bool enabledByDefault;
  final bool requiresKey;
  final String baseUrl;

  const ApiSourceInfo({
    required this.id,
    required this.displayName,
    required this.description,
    required this.enabledByDefault,
    required this.requiresKey,
    required this.baseUrl,
  });
}

class ApiSourceRegistry {
  static const List<ApiSourceInfo> all = [
    ApiSourceInfo(
      id: ApiSource.googleBooks,
      displayName: 'Google Books',
      description: '覆蓋面廣，含中文書，免金鑰查詢基本資訊。',
      enabledByDefault: true,
      requiresKey: false,
      baseUrl: 'https://www.googleapis.com/books/v1/volumes?q=isbn=',
    ),
    ApiSourceInfo(
      id: ApiSource.openLibrary,
      displayName: 'Open Library',
      description: '完全免費開放資料，補足封面與基本元資料。',
      enabledByDefault: true,
      requiresKey: false,
      baseUrl: 'https://openlibrary.org/api/books?bibkeys=ISBN:',
    ),
    ApiSourceInfo(
      id: ApiSource.wikipedia,
      displayName: 'Wikipedia',
      description: '維基百科參考書籍資訊，補充文獻數據。',
      enabledByDefault: false,
      requiresKey: false,
      baseUrl:
          'https://en.wikipedia.org/w/api.php?action=query&list=search&srsearch=',
    ),
    ApiSourceInfo(
      id: ApiSource.jikeFree,
      displayName: '中文第三方免費 API',
      description: '社群維護的中文書資訊，穩定度較低，預設關閉。',
      enabledByDefault: false,
      requiresKey: false,
      baseUrl: 'https://api.jike.xyz/situ/book/isbn/',
    ),

  ];

  static ApiSourceInfo info(ApiSource source) {
    return all.firstWhere((item) => item.id == source);
  }

  static List<ApiSource> defaultEnabled() {
    return all
        .where((item) => item.enabledByDefault)
        .map((item) => item.id)
        .toList();
  }

  static ApiSource? fromId(String raw) {
    try {
      return ApiSource.values.firstWhere((s) => s.name == raw);
    } catch (_) {
      return null;
    }
  }

  static String toId(ApiSource source) => source.name;
}
