//! License detection (LICENSE/SPDX/headers/metadata) and Green/Yellow/Red classification.
//!
//! Phase 0 placeholder. See `ROADMAP.md` for the phase that implements this crate.

/// Returns the human-readable name of this engine module.
pub fn module_name() -> &'static str {
    "graystone_license"
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn module_name_is_set() {
        assert_eq!(module_name(), "graystone_license");
    }
}
