//! Feature Finder: multi-strategy search across names, content, symbols, and docs.
//!
//! Phase 0 placeholder. See `ROADMAP.md` for the phase that implements this crate.

/// Returns the human-readable name of this engine module.
pub fn module_name() -> &'static str {
    "graystone_search"
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn module_name_is_set() {
        assert_eq!(module_name(), "graystone_search");
    }
}
