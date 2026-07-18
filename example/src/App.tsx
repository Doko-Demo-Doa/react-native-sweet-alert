import { Button, StyleSheet, View } from 'react-native';
import { showAlert } from 'react-native-sweet-alert';

export default function App() {
  return (
    <View style={styles.container}>
      <Button
        title="Show alert"
        onPress={() => {
          showAlert({
            style: 'success',
            title: 'Great job!',
            confirmButtonTitle: 'OK',
          });
        }}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
});
