//! Structured, append-only operation log.
//!
//! Phase 0 placeholder. See `ROADMAP.md` for the phase that implements this crate.

/// Returns the human-readable name of this engine module.
pub fn module_name() -> &'static str {
    "graystone_logs"
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn module_name_is_set() {
        assert_eq!(module_name(), "graystone_logs");
    }
}
