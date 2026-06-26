//! `graystone_core` — orchestration and the public FFI surface for the Graystone
//! engine.
//!
//! The Flutter UI talks to the engine exclusively through the functions exposed
//! in [`api`] (bound to Dart via flutter_rust_bridge). The UI holds no business
//! or safety logic; this crate is the authority.
//!
//! Phase 0 ships a minimal surface (version + health check). Later phases add
//! the License Gate, crawler, patch engine, and repair engine on top.

pub mod api;
mod frb_generated;
