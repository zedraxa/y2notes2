/// Type-safe route path constants.
///
/// Using these constants eliminates magic strings throughout the
/// codebase and makes route changes a single-point edit.
abstract final class AppRoutes {
  // ── Top-level ─────────────────────────────────────────────────────────────
  static const String library = '/';
  static const String workspace = '/workspace';
  static const String scanner = '/scanner';
  static const String graph = '/graph';

  // ── Notebook ──────────────────────────────────────────────────────────────
  static String notebook(String id) => '/notebook/$id';
  static String notebookPage(String id, int pageNum) =>
      '/notebook/$id/page/$pageNum';

  // ── Canvas ────────────────────────────────────────────────────────────────
  static String infiniteCanvas(String id) => '/canvas/infinite/$id';
  static String canvas(String id) => '/canvas/$id';

  // ── Rich text ─────────────────────────────────────────────────────────────
  static String richText(String elementId) => '/richtext/$elementId';

  // ── PDF annotation ────────────────────────────────────────────────────────
  static const String pdfAnnotate = '/pdf/annotate';

  // ── Flash cards ───────────────────────────────────────────────────────────
  static const String flashcards = '/flashcards';
  static String deck(String deckId) => '/flashcards/deck/$deckId';
  static String deckAdd(String deckId) =>
      '/flashcards/deck/$deckId/add';
  static String deckEdit(String deckId, String cardId) =>
      '/flashcards/deck/$deckId/edit/$cardId';
  static String deckStudy(String deckId) =>
      '/flashcards/deck/$deckId/study';
  static String deckQuiz(String deckId) =>
      '/flashcards/deck/$deckId/quiz';
  static String deckStats(String deckId) =>
      '/flashcards/deck/$deckId/stats';

  // ── Settings ──────────────────────────────────────────────────────────────
  static const String settings = '/settings';
  static const String settingsGeneral = '/settings/general';
  static const String settingsCanvas = '/settings/canvas';
  static const String settingsEffects = '/settings/effects';
  static const String settingsStylus = '/settings/stylus';
  static const String settingsRecognition = '/settings/recognition';
  static const String settingsBackup = '/settings/backup';
  static const String settingsCloudSync = '/settings/cloud-sync';
  static const String settingsAbout = '/settings/about';
}
