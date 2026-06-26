//! Phase 0 FFI surface: enough for the UI to confirm it can reach the engine.

/// Semantic version of the Graystone engine (matches the cargo package version).
pub const ENGINE_VERSION: &str = env!("CARGO_PKG_VERSION");

/// A health snapshot the UI can render to confirm the engine is reachable.
pub struct HealthReport {
    /// Always `true` when the engine responds; present so the UI has an explicit
    /// liveness flag rather than inferring it from a successful call.
    pub ok: bool,
    /// Engine version string.
    pub version: String,
    /// Names of the engine modules compiled into this build.
    pub modules: Vec<String>,
}

/// Returns the engine version string.
#[flutter_rust_bridge::frb(sync)]
pub fn engine_version() -> String {
    ENGINE_VERSION.to_string()
}

/// Returns the list of engine modules linked into this build.
#[flutter_rust_bridge::frb(sync)]
pub fn list_modules() -> Vec<String> {
    vec![
        graystone_policy::module_name().to_string(),
        graystone_license::module_name().to_string(),
        graystone_readme::module_name().to_string(),
        graystone_project_scan::module_name().to_string(),
        graystone_index::module_name().to_string(),
        graystone_search::module_name().to_string(),
        graystone_profiles::module_name().to_string(),
        graystone_ast::module_name().to_string(),
        graystone_cst::module_name().to_string(),
        graystone_patch::module_name().to_string(),
        graystone_diff::module_name().to_string(),
        graystone_backup::module_name().to_string(),
        graystone_restore::module_name().to_string(),
        graystone_update::module_name().to_string(),
        graystone_build::module_name().to_string(),
        graystone_ai_bridge::module_name().to_string(),
        graystone_logs::module_name().to_string(),
    ]
}

/// Returns a full health snapshot for the UI's engine-status view.
#[flutter_rust_bridge::frb(sync)]
pub fn health_check() -> HealthReport {
    HealthReport {
        ok: true,
        version: ENGINE_VERSION.to_string(),
        modules: list_modules(),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn version_matches_package() {
        assert_eq!(engine_version(), env!("CARGO_PKG_VERSION"));
    }

    #[test]
    fn lists_all_seventeen_modules() {
        assert_eq!(list_modules().len(), 17);
    }

    #[test]
    fn health_check_is_ok() {
        let report = health_check();
        assert!(report.ok);
        assert_eq!(report.version, ENGINE_VERSION);
        assert_eq!(report.modules.len(), 17);
    }
}
