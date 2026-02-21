/// 路徑工具類別
///
/// 解決 iOS 等平台上，每次更新或重新編譯應用程式時 Sandbox UUID 改變，
/// 導致儲存在資料庫中的絕對路徑失效的問題。
class PathUtils {
  static late final String _documentsDir;

  static void init(String documentsDir) {
    _documentsDir = documentsDir;
  }

  /// 將可能會因 Sandbox 變動而失效的絕對路徑，轉換為當下有效的絕對路徑。
  static String resolveSandboxPath(String savedPath) {
    if (savedPath.isEmpty) return savedPath;

    // 對於網路 URL 直接返回
    if (savedPath.startsWith('http')) return savedPath;

    // 將路徑重新指向目前的 documents 目錄
    final fileName = savedPath.split('/').last;
    return '$_documentsDir/$fileName';
  }
}
