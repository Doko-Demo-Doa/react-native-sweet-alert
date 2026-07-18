import { useRef, useState } from 'react';
import {
  Pressable,
  SafeAreaView,
  ScrollView,
  StyleSheet,
  Text,
} from 'react-native';
import SweetAlert, { type SweetAlertOptions } from 'react-native-sweet-alert';

interface Demo {
  title: string;
  onPress: () => void | Promise<void>;
}

export default function App() {
  const [lastResult, setLastResult] = useState<string>('—');
  const progressTimer = useRef<ReturnType<typeof setInterval> | null>(null);

  const runAlert = async (options: SweetAlertOptions) => {
    const result = await SweetAlert.showAlert(options);
    setLastResult(JSON.stringify(result));
  };

  const stopProgressTimer = () => {
    if (progressTimer.current != null) {
      clearInterval(progressTimer.current);
      progressTimer.current = null;
    }
  };

  const demos: Demo[] = [
    {
      title: 'Success',
      onPress: () =>
        runAlert({
          style: 'success',
          title: 'Great job!',
          subTitle: 'Everything went smoothly.',
          confirmButtonTitle: 'OK',
        }),
    },
    {
      title: 'Error',
      onPress: () =>
        runAlert({
          style: 'error',
          title: 'Something went wrong',
          subTitle: 'Please try again.',
          confirmButtonTitle: 'Retry',
          confirmButtonColor: '#F27474',
        }),
    },
    {
      title: 'Warning (with cancel)',
      onPress: () =>
        runAlert({
          style: 'warning',
          title: 'Are you sure?',
          subTitle: "This can't be undone.",
          confirmButtonTitle: 'Delete',
          confirmButtonColor: '#F8BB86',
          otherButtonTitle: 'Cancel',
          otherButtonColor: '#8CC152',
        }),
    },
    {
      title: 'Normal (cancellable)',
      onPress: () =>
        runAlert({
          style: 'normal',
          title: 'Heads up',
          subTitle: 'Tap outside this alert to dismiss it.',
          cancellable: true,
        }),
    },
    {
      title: 'Progress (determinate + cosmetics)',
      onPress: () => {
        stopProgressTimer();
        runAlert({
          style: 'progress',
          title: 'Uploading...',
          progress: 0,
          progressBarColor: '#4A90D9',
          progressCircleRadius: 36,
          progressBarWidth: 6,
        });

        let progress = 0;
        progressTimer.current = setInterval(() => {
          progress += 10;
          SweetAlert.setProgress(progress);
          if (progress >= 100) {
            stopProgressTimer();
            SweetAlert.dismissAlert();
          }
        }, 300);
      },
    },
    {
      title: 'Progress (indeterminate)',
      onPress: () =>
        runAlert({
          style: 'progress',
          title: 'Loading...',
        }),
    },
    {
      title: 'Dismiss current alert',
      onPress: () => {
        stopProgressTimer();
        SweetAlert.dismissAlert();
      },
    },
  ];

  return (
    <SafeAreaView style={styles.container}>
      <ScrollView contentContainerStyle={styles.content}>
        <Text style={styles.heading}>react-native-sweet-alert</Text>
        <Text style={styles.result}>Last result: {lastResult}</Text>
        {demos.map((demo) => (
          <Pressable
            key={demo.title}
            style={styles.button}
            onPress={demo.onPress}
          >
            <Text style={styles.buttonText}>{demo.title}</Text>
          </Pressable>
        ))}
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#fff',
  },
  content: {
    padding: 24,
    gap: 12,
  },
  heading: {
    fontSize: 22,
    fontWeight: '600',
    marginBottom: 4,
  },
  result: {
    fontSize: 14,
    color: '#666',
    marginBottom: 12,
  },
  button: {
    backgroundColor: '#4A90D9',
    borderRadius: 8,
    paddingVertical: 14,
    paddingHorizontal: 16,
  },
  buttonText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: '600',
    textAlign: 'center',
  },
});
