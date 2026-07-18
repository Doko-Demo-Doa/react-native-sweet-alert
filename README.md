# react-native-sweet-alert

Cute, native alert dialogs for React Native — success, error, warning, normal,
and progress styles, on both the old and new architecture.

![Sweet Alert demo](https://raw.githubusercontent.com/Clip-sub/react-native-sweet-alert/master/images/demo.gif 'Sweet Alert')

## Installation

```sh
npm install react-native-sweet-alert
```

Autolinking handles the rest — no manual bridging headers, no
`AndroidManifest.xml` edits. Works with both the old and the new React
Native architecture (TurboModules), so there's nothing to configure either
way.

## Usage

```ts
import SweetAlert from 'react-native-sweet-alert';

const result = await SweetAlert.showAlert({
  style: 'success',
  title: 'Great job!',
  subTitle: 'Everything went smoothly.',
  confirmButtonTitle: 'OK',
});

// result.confirmed is `true` if the confirm button was pressed,
// `false` if the other button was pressed, the alert was dismissed
// (cancellable), or dismissAlert() was called.
```

You can also import the named functions directly:

```ts
import { showAlert, dismissAlert, setProgress } from 'react-native-sweet-alert';
```

### Alert styles

`style` is one of `'success' | 'error' | 'warning' | 'normal' | 'progress'`.

```ts
await showAlert({
  style: 'warning',
  title: 'Are you sure?',
  subTitle: "This can't be undone.",
  confirmButtonTitle: 'Delete',
  confirmButtonColor: '#F27474',
  otherButtonTitle: 'Cancel',
  otherButtonColor: '#8CC152',
});
```

Set `cancellable: true` to let the user dismiss the alert by tapping outside
it (resolves with `{ confirmed: false }`).

### Progress style

```ts
await showAlert({
  style: 'progress',
  title: 'Uploading…',
  progress: 0, // omit for an indeterminate spinner
  progressBarColor: '#4A90D9',
  progressCircleRadius: 36,
  progressBarWidth: 6,
  progressRimWidth: 6,
});

setProgress(50); // update the same alert's progress later
dismissAlert(); // dismiss it programmatically when done
```

### Full options reference

| Option                 | Type      | Notes                                                     |
| ---------------------- | --------- | --------------------------------------------------------- |
| `style`                | `string`  | Required. `success`/`error`/`warning`/`normal`/`progress` |
| `title`                | `string`  |                                                           |
| `subTitle`             | `string`  |                                                           |
| `confirmButtonTitle`   | `string`  |                                                           |
| `confirmButtonColor`   | `string`  | Hex color, e.g. `#4A90D9`                                 |
| `otherButtonTitle`     | `string`  | Omit to show a single-button alert                        |
| `otherButtonColor`     | `string`  | Hex color                                                 |
| `cancellable`          | `boolean` | Tap outside to dismiss                                    |
| `progress`             | `number`  | 0-100; `progress` style only. Omit for indeterminate      |
| `progressBarColor`     | `string`  | `progress` style only                                     |
| `progressCircleRadius` | `number`  | `progress` style only, in dp/pt                           |
| `progressBarWidth`     | `number`  | `progress` style only, in dp/pt                           |
| `progressRimWidth`     | `number`  | `progress` style only, in dp/pt (Android)                 |
| `progressSpinSpeed`    | `number`  | `progress` style only (Android)                           |

## Example app

See [`example/`](example) for a runnable Expo app exercising every alert
style. From the repo root:

```sh
pnpm install
pnpm example ios     # or: pnpm example android
```

## Contributing

- [Development workflow](CONTRIBUTING.md#development-workflow)
- [Sending a pull request](CONTRIBUTING.md#sending-a-pull-request)
- [Code of conduct](CODE_OF_CONDUCT.md)

## License

MIT

---
