# NXNative public-source validation

This repository checks NXNativeWindows at commit `269d61ff974b2e8e073d7357466ae130c3f6812f`, applying the reviewed `patches/xcode-data-help.patch` to its Xcode project input generator. The patch includes the shared data-import UI and ZIP implementation in generated projects and links their framework/zlib dependencies. It fixes a reproduced undefined `_nxw_show_data_help` symbol; it does not stub the feature.

The manual workflow uses the standard `xcode-27` runner and Xcode 27.1, read-only repository permissions and a 20-minute timeout. The operator must review and be able to comply with the applicable Apple terms before setting `apple_terms_reviewed=true`. The workflow never accepts licenses, signs applications or installs on devices.

Checks include the pinned source commit, SDK versions, upstream iOS source compilation, the Windows UIKit front end compiled by Apple clang, an original synthetic shader, and the production Xcode smoke project including Swift. The production smoke project uses zero-filled original modules and tiny synthetic resources; it is an intentionally non-runnable compile/link fixture. It remains on the runner and is not returned as an application artifact.

The Windows branch locks Windows Metal 32023.850; the Mac toolchain is 32023.921. That mismatch is retained as a non-required compatibility diagnostic for this source/synthetic-only check. No upstream lock is changed, no game shader cache is generated, and cross-compiler game shader compatibility is not claimed.

The separate `probe/` application is original code: an ARM64 UIKit/Metal triangle plus device name, drawable dimensions and submitted frames per second. It has no game inputs, keys, network code or private data access. Submitted frame rate is a probe statistic, not a claim about game performance. Its unsigned IPA is the sole application artifact returned. It requires separate user-controlled signing and installation before device behavior can be tested.

Artifacts contain only named diagnostic logs/results and `NXNativeProbe-unsigned.ipa`, retained for seven days. No SDK, certificates, provisioning profiles, game files or game-derived code are uploaded. No game directory or key is accepted as input. Public repositories with standard runners use GitHub's documented free compute tier; private/larger runners and excess artifact allowances may have charges and are not configured here.

Successful full-link run: https://github.com/Kaiiiiizzz/nxnative-public-compile-check/actions/runs/43370072972
Successful full-link plus original probe run: https://github.com/Kaiiiiizzz/nxnative-public-compile-check/actions/runs/43370773011

These passes establish compilation and unsigned linking only. Real game linking, device execution, hardware GPU correctness, memory stability, signing and 1440p/60FPS remain separate validation steps. Windows still has no Apple SDK installed.
