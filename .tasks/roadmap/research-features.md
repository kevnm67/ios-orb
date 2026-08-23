# Research: features (2026-08-23)

| id | title | value | effort | design summary |
|---|---|---|---|---|
| F-1 | Simulator preboot | 5 | S | `preboot_simulator` bool on build_xcode/test_xcode/build_and_test_xcode → macos/preboot-simulator + wait; script parse_simulator_destination.sh (DESTINATION→SIMULATOR_NAME) |
| F-2 | upload_dsyms (Sentry) | 5 | S | cmd upload_dsyms: dsym_path, sentry_org, sentry_project, sentry_auth_token (env_var_name), skip_errors; sentry-cli via brew |
| F-3 | Swift Testing --xunit-output in test_spm | 4 | S | `test_framework` enum auto/xctest/swift-testing; swift test --parallel --xunit-output |
| F-4 | deploy_testflight (fastlane pilot) | 5 | M | ipa_path, app_identifier, api_key_path (env_var_name), skip_waiting..., groups |
| F-5 | swiftformat + periphery_scan cmds | 4 | S | mirror swiftlint pattern |
| F-6 | retry_on_failure / test_iterations on test_xcode | 3 | S | -retry-tests-on-failure -test-iterations N |
| F-7 | notarize_macos | 3 | S | notarytool submit --wait + stapler |
| F-8 | split_tests with circleci tests split | 5 | M | resolve_test_splits.sh → -only-testing/--filter |
| F-9 | DerivedData cache cmds | 4 | M | tar-based cache keyed on scheme+project+xcode |
| F-10 | notify_slack | 2 | S | webhook curl, on: always/fail/success |
| F-11 | junit_source xcresulttool alt | 3 | M | xcrun xcresulttool get test-results |
| F-12 | tuist_generate | 3 | M | mirror xcodegen; project_generator enum |
| F-13 | assert_xcode_channel beta guard | 2 | S | |
| F-14 | pipeline_parameters example | 2 | S | docs-only |
| F-15 | matrix destinations example | 1 | S | docs-only |
