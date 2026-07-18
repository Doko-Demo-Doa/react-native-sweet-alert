import NativeSweetAlert, {
  type AlertResult,
  type AlertStyle,
} from './NativeSweetAlert';

export type { AlertResult, AlertStyle };

interface BaseAlertOptions {
  title?: string;
  subTitle?: string;
  confirmButtonTitle?: string;
  confirmButtonColor?: string;
  otherButtonTitle?: string;
  otherButtonColor?: string;
  cancellable?: boolean;
}

export interface StandardAlertOptions extends BaseAlertOptions {
  style: 'success' | 'error' | 'warning' | 'normal';
}

export interface ProgressAlertOptions extends BaseAlertOptions {
  style: 'progress';
  progress?: number;
  progressBarColor?: string;
  progressCircleRadius?: number;
  progressBarWidth?: number;
}

export type SweetAlertOptions = StandardAlertOptions | ProgressAlertOptions;

export function showAlert(options: SweetAlertOptions): Promise<AlertResult> {
  return NativeSweetAlert.showAlert(options);
}

export function dismissAlert(): void {
  NativeSweetAlert.dismissAlert();
}

export function setProgress(progress: number): void {
  NativeSweetAlert.setProgress(progress);
}

const SweetAlert = { showAlert, dismissAlert, setProgress };

export default SweetAlert;
