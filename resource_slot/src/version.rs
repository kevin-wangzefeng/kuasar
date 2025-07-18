/*
Copyright 2025 The Kuasar Authors.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

pub fn print_version_info() {
    println!(
        "
{}
Version: {}
Built: {}
Git commit: {}
Rustc version: {}
",
        built_info::PKG_NAME,
        built_info::PKG_VERSION,
        built_info::BUILT_TIME_UTC,
        built_info::GIT_COMMIT_HASH.unwrap_or("unknown"),
        built_info::RUSTC_VERSION
    );
}

pub mod built_info {
    include!(concat!(env!("OUT_DIR"), "/built.rs"));
}
