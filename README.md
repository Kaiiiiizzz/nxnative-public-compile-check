# Public-source iOS compile check

This standalone orchestration repository checks the pinned NXNativeWindows commit 269d61ff974b2e8e073d7357466ae130c3f6812f. It is intentionally separate from the Windows checkout and its local fixes.

Run manually on the standard GitHub-hosted xcode-27 runner. The workflow requires the operator to review the applicable Apple terms and set apple_terms_reviewed=true. It never accepts a license, signs a program, downloads extra Apple components, or packages a game.

Checks: exact source commit, Xcode/SDK versions, upstream Metal compiler lock diagnostic, upstream iOS C/Objective-C/assembly sources, the Windows UIKit front end compiled with Apple clang, and an original synthetic Metal shader. A pass is compilation only: no game execution, device testing, Windows LLVM parity, Swift launcher build, real-game app link, device execution, or performance claim is implied. Missing Xcode 27.1, SDK or Metal components cause a failure rather than an automatic installation or license acceptance.

Only public source is checked out. No game paths, keys, user uploads or secrets are accepted. Only named diagnostic log files and results.json are returned; the SDK, object files and Metal libraries are not uploaded. Build scratch data lives in a temporary directory.

Use a public repository and the standard runner for the documented free compute tier. Private repositories, larger runners and artifact allowances can have separate charges; no paid service has been enabled. Logs expire after seven days. A 20-minute timeout bounds each manual run.

Local verification: run scripts/run_checks.py --source ../NXNativeWindows --logs ../logs/cloud-check --plan. Execution is rejected outside macOS. Cloud validation succeeded on 2026-11-13: https://github.com/Kaiiiiizzz/nxnative-public-compile-check/actions/runs/43368668895 . Upstream iOS compile: 180 sources, zero failures. Windows UIKit front end with Apple clang: 183 sources, zero failures. Synthetic Metal compile and library creation passed. The Windows Metal lock mismatch remains recorded as a non-required diagnostic.

The pinned Windows branch locks the Windows Metal compiler. A Mac compiler mismatch is recorded as a non-required diagnostic for this source/synthetic-only check. The upstream lock is not changed and no game shader cache is built or declared compatible.

The extended check also invokes the upstream production Xcode smoke build with original zero-filled synthetic modules and tiny original resources. CODE_SIGNING_ALLOWED=NO and CODE_SIGNING_REQUIRED=NO are enforced by the upstream script, which rejects a code signature directory or provisioning profile. It links the real iOS project, including Swift, but produces an intentionally non-runnable fixture. No app bundle is returned as an artifact.
