import { TurboModuleRegistry, type TurboModule } from 'react-native';

export type AlertStyle =
  | 'success'
  | 'error'
  | 'warning'
  | 'normal'
  | 'progress';

export interface AlertOptions {
  style: AlertStyle;
  title?: string;
  subTitle?: string;
  confirmButtonTitle?: string;
  confirmButtonColor?: string;
  otherButtonTitle?: string;
  otherButtonColor?: string;
  cancellable?: boolean;
  progress?: number;
  progressBarColor?: string;
  progressCircleRadius?: number;
  progressBarWidth?: number;
  progressRimWidth?: number;
  progressSpinSpeed?: number;
}

export interface AlertResult {
  confirmed: boolean;
}

export interface Spec extends TurboModule {
  showAlert(options: AlertOptions): Promise<AlertResult>;
  dismissAlert(): void;
  setProgress(progress: number): void;
}

export default TurboModuleRegistry.getEnforcing<Spec>('SweetAlert');
