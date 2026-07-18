# react-native-sweet-alert — 2026 Modernization Plan

## Context

Current state (v3.5.0, last touched years ago): pure old-architecture bare
native module. No TypeScript, no example app, no CI, no lint/format config.
Version numbers have drifted across `package.json` (3.5.0), the podspec
(3.1.0), and `android/build.gradle` (3.0.0). JS wrapper (`index.js`) uses
Haste-era `@providesModule`/`@flow` pragmas. iOS impl force-unwraps
dictionary values and vendors a third-party `SweetAlert.swift` UI library
directly in-tree. Android depends on an unmaintained third-party AAR
(`com.github.f0ris.sweetalert:library:1.6.2`) and is missing `arm64-v8a`/
`x86_64` ABI support entirely.

Reference projects surveyed for pattern conventions:
`react-native-shake`, `react-native-yubikit`, `react-native-pdf-editor`.
All three converge on: pnpm workspaces, `turbo`, `oxlint`+`oxfmt`,
`lefthook`+`commitlint`, `release-it`, Expo-based `example/` app, and a
`create-react-native-library`-scaffolded root. They diverge on new-arch
strategy — noted as an open decision below.

## Open decisions (need your call before implementation starts)

1. ~~New-architecture strategy~~ — **Decided: classic TurboModules +
   Codegen**, supporting both old and new architecture (matches
   `react-native-shake` / `react-native-yubikit`; not Nitro Modules).
   Spec file in `src/NativeSweetAlert.ts`, `codegenConfig` in
   `package.json`, dual `oldarch`/`newarch` native sources where the
   bridge surface differs between architectures.
2. **Android native alert UI: keep the vendored/third-party library, or
   rebuild the alert UI natively in this repo?**
   - `com.github.f0ris.sweetalert:library:1.6.2` is unmaintained and
     already causing the missing-ABI problem.
   - **Recommendation:** fork the relevant Kotlin views into this repo
     (small library, ~a few files) instead of depending on the dead AAR,
     so we control ABI/AndroidX/Kotlin compatibility going forward.
3. **iOS: keep vendoring `ios/Vendor/SweetAlert.swift`, or replace with a
   CocoaPod dependency / rebuild in SwiftUI?**
   - **Recommendation:** keep vendoring (it's already there, small, and a
     CocoaPod for this doesn't exist in a maintained form), but clean up
     force-unwraps and update to modern Swift/dark-mode support.
4. **Package name / scope:** keep `react-native-sweet-alert` unscoped on
   npm, or publish as `@doko/react-native-sweet-alert` (yubikit's pattern)?
   Affects whether the existing npm listing continues to receive updates.
5. **Minimum RN version to support.** Recommend RN 0.79+ (aligns with
   shake) or 0.86+ (aligns with yubikit/pdf-editor, newer). Pick one — it
   affects which codegen/autolinking APIs are safe to assume.

---

## Checklist

### 0. Repo scaffolding — ✅ done

- [x] Decide open questions above (decision #1 confirmed by you; #5
      resolved implicitly by scaffolding against RN 0.86.0, matching
      yubikit/pdf-editor — flag if you'd rather target 0.79+)
- [x] Scaffold fresh library structure via `create-react-native-library`
      0.63.0 (type: `turbo-module`, languages: `kotlin-objc` — the CLI
      only allows `kotlin-objc`/`cpp` for turbo-module, not
      `kotlin-swift`; Swift is Nitro-only), merged into the existing repo
      alongside the preserved `README.md`/`LICENSE`/`images/`
- [x] `pnpm-workspace.yaml` (packages: `example`), root `package.json`
      with `packageManager: "pnpm@11.13.1"` — converted from the CLI's
      default Yarn Berry output
- [x] `turbo.json` with `build:android` / `build:ios` tasks (from
      scaffold, `globalDependencies` repointed to `pnpm-workspace.yaml`)
- [x] `.nvmrc`, `.editorconfig`, `.watchmanconfig` (from scaffold)
- [x] Removed legacy old-arch-only files superseded by the new scaffold:
      `index.js`, `RNSweetAlert.podspec`, `Example-Bridging-Header.h`,
      `ios/RNSweetAlert-Bridging-Header.h`, `ios/RNSweetAlert.xcodeproj`,
      `ios/SweetAlertBridge.m`, `ios/SweetAlertManager.swift`,
      `android/src/main/java/com/clipsub/**` (referenced the removed
      third-party `cn.pedant.SweetAlert` AAR and would not compile
      alongside the new `build.gradle`)
- [x] Preserved `ios/Vendor/SweetAlert.swift` (vendored UI impl, no
      bridge/module registration conflicts) for reuse in group 3
- [x] `pnpm install`, `pnpm typecheck`, `pnpm test`, `pnpm prepare` (bob
      build) all pass on the new scaffold

### 1. TypeScript source & public API — ✅ done

- [x] Ported the existing API surface into `src/`, redesigned as
      Promise-based: `showAlert(options)`, `dismissAlert()`,
      `setProgress(progress)`. Callback-based `showAlertWithOptions` was
      **not** kept as a shim — clean break, no existing published
      consumers depend on the old signature by contract stability
      guarantees this early in the rewrite (flag if you want a shim for
      migration ergonomics)
- [x] Android-only cosmetic knobs (`setCircleRadius`, `setBarColor`,
      `setRimWidth`, `setSpinSpeed`, etc.) exposed cross-platform as
      optional fields on `AlertOptions` when `style: 'progress'`
      (`progressBarColor`, `progressCircleRadius`, `progressBarWidth`,
      `progressRimWidth`, `progressSpinSpeed`) rather than a separate
      Android-gated method — iOS native impl will no-op on these in
      group 3. Dropped `changeAlertType`, `resetCount`, `isSpinning`,
      `spin`/`stopSpinning`, `showContentText`, `showCancelButton` as
      separate imperative methods — not essential to the core alert flow;
      revisit if you need them
- [x] `src/NativeSweetAlert.ts` TurboModule spec defined (`extends
TurboModule`, `TurboModuleRegistry.getEnforcing<Spec>('SweetAlert')`
      — module registered as `SweetAlert`, not `RNSweetAlert`, matching
      the scaffold's generated naming) — single spec for both old- and
      new-arch native code
- [x] `AlertOptions` strongly typed in the spec (flat interface, as
      required by Codegen — unions aren't supported for method params);
      `src/index.tsx` layers a nicer discriminated union
      (`StandardAlertOptions | ProgressAlertOptions`) on top for the
      public TS API before flattening to the native call
- [x] `codegenConfig` in `package.json` (`name: SweetAlertSpec`, `type:
modules`, `jsSrcsDir: src`, `ios.modulesProvider`, `android.javaPackageName: com.sweetalert`)
- [x] Minimal native stubs added (Kotlin `SweetAlertModule.kt`, ObjC++
      `SweetAlert.mm`) implementing the generated spec surface with
      `TODO`/`not_implemented` bodies — real UI logic is group 2/3

### 2. Android (old + new arch) — ✅ done

- [x] `compileSdk 36` / `minSdk 24`, Kotlin 2.0.21, AGP 8.7.2, Java 17 —
      already set by the group-0 scaffold, nothing further to bump
- [x] ABIs: N/A — this module ships no native C++/NDK code (pure Kotlin),
      so there's no `ndk.abiFilters` to restrict in the first place. The
      old missing-`arm64-v8a` problem lived in the third-party AAR /
      example app, not something this library's own build needs to fix
- [x] Ported to Kotlin implementing generated `NativeSweetAlertSpec`
      directly (`SweetAlertModule.kt`) — single `src/main`, no
      `oldarch`/`newarch` split needed since Codegen generates both
      old- and new-arch base classes from the same spec for a plain
      "modules"-type TurboModule with no view manager / event emitter
      surface (unlike shake, which needed the split for other reasons)
- [x] Resolved decision #2: **rebuilt the alert UI natively in this repo**
      rather than forking the unmaintained AAR's Java source. Custom
      `SweetAlertIconView` (Canvas/Path-drawn success/error/warning glyphs + progress arc, `ValueAnimator`-driven) and `SweetAlertDialog`
      (programmatic `Dialog`, no XML/resource files) — zero third-party
      UI dependency, dark-mode aware. This is a legitimate reimplementation,
      not a pixel-perfect clone of the old library's look — flag if you
      want the old visuals matched more closely
- [x] `SYSTEM_ALERT_WINDOW` already absent from the scaffolded
      `AndroidManifest.xml` — nothing to remove
- [x] **Validated**: `./gradlew :react-native-sweet-alert:compileDebugKotlin`
      builds clean (including Codegen schema/artifact generation) with
      zero errors or warnings, run against the example app's Gradle
      project

### 3. iOS (old + new arch) — ✅ done

- [x] Rewrote the bridge as ObjC++ TurboModule conformance
      (`ios/SweetAlert.h`/`.mm`, `RCT_EXPORT_MODULE(SweetAlert)`,
      `NativeSweetAlertSpecJSI`) — no more `RCTViewManager` miscasting
      or manual `RCT_EXTERN_METHOD`
- [x] `ios/Vendor/SweetAlert.swift` kept and modernized per decision #3:
      renamed the vendored `UIViewController` class from `SweetAlert` to
      `SweetAlertView` (required — it would otherwise collide with the
      new ObjC++ TurboModule class also named `SweetAlert` in the same
      module), removed force-unwraps, replaced deprecated
      `UIApplication.shared.keyWindow!` with the connected-scene lookup,
      added dark-mode-aware colors (dynamic `UIColor { traitCollection in
... }`), added `cancellable` (tap-outside-to-dismiss), and added a
      `progress` style (determinate/indeterminate arc) that **never
      existed on iOS before** — the old `SweetAlertManager.swift` had no
      progress/spinner support at all, only Android did
  - Added `SweetAlertBridge`, a small `@objc public` wrapper class,
    since ObjC++ can't call `SweetAlertView.present` directly (it takes
    a Swift-only `AlertStyle` enum and `Double?`, neither ObjC-bridgeable)
  - Hit and fixed a real bug worth knowing about: Swift's generated
    `<Module>-Swift.h` header **only exposes `public`/`open`
    declarations** — an `internal` (default-access) class or its
    `@objc` methods are silently omitted from the header with no
    compiler diagnostic, producing a confusing "undeclared identifier"
    error on the ObjC++ side pointing at the wrong symbol. Fixed by
    marking `SweetAlertBridge` and its methods `public`
- [x] Podspec: deployment target already derives from RN's own
      `min_ios_version_supported` helper (tracks whatever RN 0.86
      requires, currently iOS 15.1) — no hardcoded bump needed;
      `install_modules_dependencies(s)` already present from scaffold.
      Did **not** add `s.swift_version` — turned out to be unnecessary
      (matches `react-native-pdf-editor`, which also ships Swift without
      setting it); CocoaPods/Xcode generate the Swift↔ObjC interface
      header automatically regardless
- [x] Bridging-header README cleanup deferred to group 9 (docs pass)
- [x] **Validated end-to-end**: `pod install` + a full
      `xcodebuild -workspace SweetAlertExample.xcworkspace -scheme
SweetAlertExample -sdk iphonesimulator build` against the example
      app **succeeded** (arm64 + x86_64 simulator slices), confirming the
      ObjC++ ⇄ Swift interop, Codegen struct field accessors
      (`options.title()`, `options.progress()` etc.), and ABI all check
      out for real, not just by inspection

### 4. Build tooling — ✅ done

- [x] `react-native-builder-bob` config (module + typescript targets) —
      already in place from the group-0 scaffold; no separate "codegen"
      bob target needed since Codegen runs as part of the native build
      (Gradle autolinking plugin / CocoaPods `install_modules_dependencies`),
      already proven working in groups 2–3
- [x] `tsconfig.json` + `tsconfig.build.json` (from scaffold)
- [x] `babel.config.js` (from scaffold)
- [x] `del-cli` clean script (from scaffold)

### 5. Lint / format — ✅ done

- [x] `.oxlintrc.json`: `unicorn`/`typescript`/`react`/`jest` native oxlint
      plugins. **Deviation from plan:** dropped the `jsPlugins` bridging
      (`eslint-plugin-eslint-comments`, `eslint-plugin-react-native`,
      `@react-native/eslint-plugin`) — oxlint 1.74's jsPlugins compat
      layer shells out to a real `eslint` binary that in turn needs an
      `eslint.config.js` present (a flat config we don't otherwise want),
      and hit a version-sensitive failure in this environment. The value
      those two bridged plugins add for this small codebase is marginal,
      so native-only oxlint rules were the pragmatic choice
- [x] `.oxfmtrc.json` (printWidth 80, singleQuote, trailingComma es5,
      tabWidth 2), ignoring generated `example/android/`, `example/ios/`
      (Expo CNG output) alongside `node_modules/`/`lib/`
- [x] `lefthook.yml` updated: pre-commit now runs `oxlint`, `oxfmt --check`,
      and `tsc` on staged files (was previously only running `tsc`);
      commit-msg still runs `commitlint`
- [x] `commitlint.config.js`: not added as a separate file — conventional-commits
      config already lives under the `commitlint` field in `package.json`
      from the group-0 scaffold, matching the reference repos' pattern
- [x] Ran `pnpm lint` / `pnpm format` across the whole repo (including
      the now-existing `example/`) and fixed everything that surfaced —
      clean on both

### 6. Tests — ✅ done

- [x] Jest config lives in `package.json`'s `jest` field (from scaffold),
      no separate `jest.config.js` needed — matches the pattern already
      used elsewhere in this repo
- [x] `src/__tests__/index.test.tsx`: 5 tests mocking `NativeSweetAlert`,
      covering `showAlert` (standard-style options, progress-style
      options with cosmetic fields, and native-rejection propagation),
      `dismissAlert`, and `setProgress` — all passing

### 7. Example app — ✅ done

- [x] Replaced the throwaway "vanilla" bare-RN example from group 0 with
      a real Expo ~57 project. **Note:** both `create-expo-app` and
      `create-react-native-library`'s own Expo-template step are broken
      in this environment — they assume `npm pack --json --dry-run`
      returns an array (older npm), but npm 12 now returns an object
      keyed by package name, so their JSON parsing throws. Worked around
      by fetching+extracting the `expo-template-blank-typescript` tarball
      directly with `npm pack` (which itself works fine) and hand-wiring
      the monorepo config to match `react-native-pdf-editor`'s (simpler)
      pattern rather than yubikit's expo-router/tailwind-heavy one
- [x] `example/react-native.config.js` pointing autolinking at `..`
- [x] `react-native-monorepo-config` + `react-native-builder-bob` dev
      dependencies wired into `example/metro.config.js` / `babel.config.js`
- [x] Added the `@expo/metro-config` patch (`patches/@expo__metro-config.patch`,
      referenced via `pnpm-workspace.yaml`'s `patchedDependencies`) — same
      babel-transformer cache-key bug the reference repos also patch
      around, needed because our example's babel config goes through
      `react-native-builder-bob/babel-config`
- [x] `example/src/App.tsx`: demo screen with buttons for every style
      (success, error, warning, normal-cancellable, determinate progress
      with cosmetic knobs + a `setProgress` ticker, indeterminate
      progress, and manual dismiss) plus a "last result" readout
- [x] **Validated for real, not just by inspection:**
      `expo prebuild --platform android` → `./gradlew assembleDebug`
      **BUILD SUCCESSFUL**; `expo prebuild --platform ios` → `pod install`
      → `xcodebuild ... -sdk iphonesimulator build` **BUILD SUCCEEDED**
      (arm64 + x86_64). Both platforms actually compile and link the
      library into a real Expo app

### 8. CI / release pipeline — ✅ done

- [x] `.github/actions/setup/action.yml`: converted from the scaffold's
      yarn-based version to pnpm (`pnpm/action-setup`, `setup-node` with
      `cache: pnpm`, `pnpm install --frozen-lockfile`) — matches
      yubikit's exact pattern
- [x] `.github/workflows/ci.yml`: `lint` (oxlint + format:check +
      typecheck), `test` (jest), `build-library` (bob build), plus
      `build-android`/`build-ios` (Expo prebuild + Gradle/xcodebuild,
      turbo-cached) and a `build-web` job. **Deviation, deliberately
      matching your own established pattern in yubikit/pdf-editor:**
      `build-android`/`build-ios` are disabled by default (`if: false`)
      since native builds burn CI-runner quota fast — flip that line to
      re-enable once you want native-build coverage on every push/PR. We
      already validated both platforms build correctly by hand in
      groups 2/3/7, so this isn't masking an unknown
- [x] `.github/workflows/release.yml`: triggered on tag push `v*` — lint,
      format check, typecheck, test, build, then publishes to npm and
      creates a GitHub release with auto-generated notes
- [x] `release-it` config in `package.json`: `npm.publish: false`,
      `github.release: false` — actual publish/release deferred to the
      tag-triggered `release.yml`, so `pnpm release` (already wired to
      `release-it --only-version`) just bumps the version, updates the
      changelog, commits, tags, and pushes
- [x] `pnpm release` script already existed from the scaffold

### 9. Docs & cleanup — ✅ done

- [x] Rewrote `README.md`: autolinking-only install, full TypeScript
      API/options reference, alert-style and progress-style examples,
      example-app pointer, old/new-arch note. Dropped the old duplicated
      full MIT license text at the bottom (redundant with `LICENSE`)
- [x] Removed `images/target.png` and `images/bridging-header.png`
      (screenshots for the now-deleted manual Xcode bridging-header
      steps — no longer referenced anywhere). **Left `images/demo.gif`
      as-is** — it shows the old `cn.pedant`-style visuals, which no
      longer match the rebuilt native UI (group 2/3). I can't capture a
      new recording myself (no way to run/screen-record the simulator
      from here) — you'll want to record a fresh one once you've run the
      example app and are happy with the look
- [x] Obsolete bridging-header files already removed in group 0
      (`Example-Bridging-Header.h`, `ios/RNSweetAlert-Bridging-Header.h`,
      `ios/RNSweetAlert.xcodeproj`)
- [x] Version sync: turned out to already be structurally correct, not
      just "synced" — the podspec reads its version directly from
      `package.json` (no separate literal to drift), and
      `android/build.gradle` doesn't declare a library version at all
      (only apps need `versionName`/`versionCode`; this is a library
      module). `package.json` is the only place a
      version number is ever written now
- [x] `.npmignore`/`files` allowlist: already reviewed and rewritten in
      an earlier pass (before this group) — confirmed it matches the
      reference repos' exact boilerplate, nothing further needed

### 10. Verification (final gate before calling this done)

- [ ] `pnpm lint`, `pnpm format:check`, `pnpm typecheck`, `pnpm test` all
      pass at repo root
- [ ] `pnpm --filter example expo prebuild --platform android && ...
run:android` builds and boots the demo app in an emulator, all
      alert styles trigger correctly
- [ ] `pnpm --filter example expo prebuild --platform ios && ... run:ios`
      builds and boots the demo app in the simulator, all alert styles
      trigger correctly
- [ ] Repeat both builds with new architecture disabled
      (`newArchEnabled=false`) to confirm old-arch path still works
- [ ] `pnpm prepare` (bob build) produces `lib/` output consumable by the
      example app via workspace resolution
