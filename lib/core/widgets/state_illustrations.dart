abstract final class StateIllustrations {
  static const emptyGeneral = 'assets/animations/empty_general.json';
  static const emptySearch = 'assets/animations/empty_search.json';
  static const loadingMinimal = 'assets/animations/loading_minimal.json';
  static const error = 'assets/animations/error.json';

  static String resolve(String assetPath) {
    // Centralized indirection so themed illustration sets can switch here
    // later without changing every call site.
    return assetPath;
  }
}
