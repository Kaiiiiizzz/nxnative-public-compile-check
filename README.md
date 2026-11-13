# Public-source iOS compile check

This standalone orchestration repository checks the pinned NXNativeWindows commit 269d61ff974b2e8e073d7357466ae130c3f6812f. It is intentionally separate from the Windows checkout and its local fixes.

Run manually on the standard GitHub-hosted xcode-27 runner. The workflow requires the operator to review the applicable Apple terms and set apple_terms_reviewed=true. It never accepts a license, signs a program, downloads extra Apple components, or packages a game.

Checks: exact source commit, Xcode/SDK versions, upstream Metal compiler lock, upstream iOS C/Objective-C/assembly sources, the Windows UIKit front end compiled with Apple clang, and an original synthetic Metal shader. A pass is compilation only: no game execution, device testing, Windows LLVM parity, Swift launcher build, final app link, or performance claim is implied. Missing Xcode 27.1, SDK or Metal components cause a failure rather than an automatic installation or license acceptance.

Only public source is checked out. No game paths, keys, user uploads or secrets are accepted. Only named diagnostic log files and results.json are returned; the SDK, object files and Metal libraries are not uploaded. Build scratch data lives in a temporary directory.

Use a public repository and the standard runner for the documented free compute tier. Private repositories, larger runners and artifact allowances can have separate charges; no paid service has been enabled. Logs expire after seven days. A 20-minute timeout bounds each manual run.

Local verification: run scripts/run_checks.py --source ../NXNativeWindows --logs ../logs/cloud-check --plan. Execution is rejected outside macOS. Publishing and cloud execution have not happened because GitHub CLI is not authenticated.
