import '../src/rust/api/engine.dart';
import '../src/rust/frb_generated.dart';

/// Thin Dart wrapper around the Graystone Rust engine (`engine/graystone_core`).
///
/// Phase 0 exposes only a liveness/health surface. The native library is loaded
/// lazily; if it isn't bundled in the current build the service degrades
/// gracefully ([available] stays `false`) instead of crashing the app, so the
/// UI can show an "engine unavailable" state.
class EngineService {
  EngineService._();

  static final EngineService instance = EngineService._();

  bool _initialized = false;
  bool _available = false;

  /// Whether the Rust engine loaded successfully.
  bool get available => _available;

  /// Loads the native engine library once. Safe to call multiple times.
  Future<void> ensureInitialized() async {
    if (_initialized) return;
    _initialized = true;
    try {
      await RustLib.init();
      _available = true;
    } catch (_) {
      // Native library not bundled in this build yet (see ROADMAP Phase 0
      // native-bundling follow-up). Leave [available] false.
      _available = false;
    }
  }

  /// Returns the engine health snapshot, or `null` if the engine is unavailable.
  HealthReport? health() {
    if (!_available) return null;
    return healthCheck();
  }
}
