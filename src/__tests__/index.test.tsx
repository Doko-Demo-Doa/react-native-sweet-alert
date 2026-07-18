import { describe, expect, it, jest, afterEach } from '@jest/globals';
import { dismissAlert, setProgress, showAlert } from '../index';
import NativeSweetAlert from '../NativeSweetAlert';

jest.mock('../NativeSweetAlert', () => ({
  __esModule: true,
  default: {
    showAlert: jest.fn(),
    dismissAlert: jest.fn(),
    setProgress: jest.fn(),
  },
}));

const mockedNativeSweetAlert = jest.mocked(NativeSweetAlert);

afterEach(() => {
  jest.clearAllMocks();
});

describe('showAlert', () => {
  it('forwards standard-style options to the native module and resolves with its result', async () => {
    mockedNativeSweetAlert.showAlert.mockResolvedValue({ confirmed: true });

    const result = await showAlert({
      style: 'success',
      title: 'Great job!',
      confirmButtonTitle: 'OK',
    });

    expect(mockedNativeSweetAlert.showAlert).toHaveBeenCalledWith({
      style: 'success',
      title: 'Great job!',
      confirmButtonTitle: 'OK',
    });
    expect(result).toEqual({ confirmed: true });
  });

  it('forwards progress-style options including cosmetic fields', async () => {
    mockedNativeSweetAlert.showAlert.mockResolvedValue({ confirmed: false });

    const result = await showAlert({
      style: 'progress',
      progress: 42,
      progressBarColor: '#ff0000',
    });

    expect(mockedNativeSweetAlert.showAlert).toHaveBeenCalledWith({
      style: 'progress',
      progress: 42,
      progressBarColor: '#ff0000',
    });
    expect(result).toEqual({ confirmed: false });
  });

  it('propagates native rejections', async () => {
    mockedNativeSweetAlert.showAlert.mockRejectedValue(
      new Error('no_activity')
    );

    await expect(showAlert({ style: 'error' })).rejects.toThrow('no_activity');
  });
});

describe('dismissAlert', () => {
  it('calls through to the native module', () => {
    dismissAlert();

    expect(mockedNativeSweetAlert.dismissAlert).toHaveBeenCalledTimes(1);
  });
});

describe('setProgress', () => {
  it('forwards the progress value to the native module', () => {
    setProgress(75);

    expect(mockedNativeSweetAlert.setProgress).toHaveBeenCalledWith(75);
  });
});
