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

### 2. Android (old + new arch)
- [ ] Bump `compileSdk`/`targetSdk` to current stable, `minSdk` to a
      sane modern floor (e.g. 24), Kotlin + AGP versions current
- [ ] Add missing ABIs (`arm64-v8a`, `x86_64`) alongside existing ones
- [ ] Port `RNSweetAlertModule.java` → Kotlin, implement generated
      `NativeSweetAlertSpec`
- [ ] Split `src/oldarch` / `src/newarch` per the shake/yubikit pattern if
      the bridge method surface differs between architectures; otherwise
      keep a single `src/main` implementing the spec directly
- [ ] Resolve Android alert-UI dependency per open decision #2 (vendor
      the Kotlin views vs keep external AAR pinned+patched)
- [ ] Remove `SYSTEM_ALERT_WINDOW` permission unless actually required by
      the new implementation

### 3. iOS (old + new arch)
- [ ] Rewrite bridge: replace `RCT_EXTERN_MODULE`/`RCT_EXTERN_METHOD` +
      `RCTViewManager` subclass (currently a plain module miscast as a
      view manager) with generated TurboModule protocol conformance
- [ ] Clean up `SweetAlertManager.swift`: remove force-unwraps, add
      proper error/promise rejection paths
- [ ] Update `ios/Vendor/SweetAlert.swift` for modern Swift + dark mode
      per open decision #3
- [ ] Bump podspec deployment target to a current iOS floor (e.g. 15),
      sync version with `package.json` (fix the 3-way version drift),
      wire up `install_modules_dependencies(s)` for new-arch
- [ ] Delete manual bridging-header instructions from README once
      autolinking + codegen make them unnecessary

### 4. Build tooling
- [ ] `react-native-builder-bob` config (module + typescript targets,
      codegen prebuild step)
- [ ] `tsconfig.json` + `tsconfig.build.json`
- [ ] `babel.config.js`
- [ ] `del-cli` clean script

### 5. Lint / format
- [ ] `.oxlintrc.json` (mirror yubikit/pdf-editor: unicorn/typescript/
      react/jest plugins, jsPlugins bridging `@react-native/eslint-plugin`)
- [ ] `.oxfmtrc.json` (printWidth 80, singleQuote, trailingComma es5,
      tabWidth 2)
- [ ] `lefthook.yml` (pre-commit: lint + format check + tsc; commit-msg:
      commitlint)
- [ ] `commitlint.config.js` (conventional commits)

### 6. Tests
- [ ] `jest.config.js` + `@react-native/jest-preset`
- [ ] Unit tests for the JS API surface (mocked native module) — at least
      option-validation and Promise-resolution paths

### 7. Example app
- [ ] Scaffold `example/` as Expo ~57 project (`expo-dev-client`,
      React 19 / RN version matching the floor chosen in decision #5)
- [ ] `example/react-native.config.js` pointing autolinking at `..`
- [ ] Add `react-native-monorepo-config` dev dependency for Metro
      resolution of the local package
- [ ] Build a demo screen exercising every alert style (success, error,
      warning, normal, progress) and the Android-only progress/spinner
      controls, with buttons to trigger each
- [ ] Verify `expo prebuild` + `expo run:android` and `expo run:ios` both
      work against the local package

### 8. CI / release pipeline
- [ ] `.github/actions/setup/action.yml` composite action (pnpm + Node
      from `.nvmrc`, frozen-lockfile install)
- [ ] `.github/workflows/ci.yml`: on push/PR to `main` — jobs: `lint`
      (oxlint + oxfmt check + tsc), `test` (jest), `build-library` (bob
      build), `build-android` (Expo prebuild + Gradle assemble, turbo
      cached), `build-ios` (Expo prebuild + xcodebuild, turbo cached)
- [ ] `.github/workflows/release.yml`: triggered on tag push `v*` — lint,
      test, build, then `pnpm publish --no-git-checks` + `gh release
      create --generate-notes`
- [ ] `release-it` config (`.release-it.json` or package.json field):
      conventional-changelog/angular preset, `npm.publish: false`,
      `github.release: false` (npm/gh publish deferred to tag-triggered CI)
- [ ] `pnpm release` local script to bump version + tag + push

### 9. Docs & cleanup
- [ ] Rewrite `README.md`: autolinking-only install (no manual bridging
      headers), new TypeScript API, example app usage, old/new arch note
- [ ] Update screenshots/gif if the alert UI visuals change
- [ ] Remove obsolete files: `Example-Bridging-Header.h`,
      `ios/RNSweetAlert-Bridging-Header.h`, `ios/RNSweetAlert.xcodeproj`
      (no longer needed once autolinked)
- [ ] Sync version across `package.json`, podspec, `android/build.gradle`
      (single source of truth — derive others from package.json where
      possible)
- [ ] `.npmignore` review (ship `lib/`, `src/`, native source; exclude
      `example/`)

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
