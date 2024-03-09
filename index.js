/**
 * @providesModule RNSweetAlert
 * @author Doko
 * @flow
 */

'use strict';

import React, { NativeModules, Platform } from 'react-native';

const Native = Platform.OS === 'android' ? NativeModules.RNSweetAlert : NativeModules.SweetAlertManager;

const DEFAULT_OPTIONS = {
  title: '',
  subTitle: '',
  confirmButtonTitle: 'OK',
  confirmButtonColor: '#000000',
  barColor: '',
  otherButtonTitle: '',
  otherButtonColor: '',
  style: 'success',
  cancellable: true
}

const SweetAlert = {
  showAlertWithOptions: (options, callback = () => { }) => {
    Native.showAlertWithOptions(options ? options : DEFAULT_OPTIONS, callback)
  },
  dismissAlert: () => Native.hideSweetAlert(),
};

export default SweetAlert;
