# sun_baked

Application code for the sunbaked bricks solar oven project

## Getting Started

### Manual installation

As of now, this application is not available on the Google play store. However, you can install flutter and upload the app to your own phone manually.

- [Flutter Installation Guide](https://docs.flutter.dev/get-started/install)

You will also need to set your android device to developer mode in order to upload the application

- [Enable developer mode](https://developer.android.com/studio/debug/dev-options)

You will only need to reach step 3 of the flutter installation to upload the dev version of the application to your device.
After completing these steps, plug your desired device into your computer and select it as your development device on the option in the bottom right corner of the VS code editor before running the code.

### Raw apk dowload: 
Or download the raw apk builds for your device from the github release page.

## Application Description

This application monitors activity from a Node MCU 1 unit that is hosting a local wifi connection. Once the Node MCU is powered on and reading you should look in your wifi settings for a connection called "Node MCU" and connect to it, once you have done this the application will be functional.

## Functionality

The application reads live data from the Node MCU and persistently stores the results. This can be viewed via the history button.

To set the target temperature of the oven, select one of the plastic material options.

There is also a button labeled START that will send the signal to turn on the oven, this toggles to STOP which turns off the oven when pressed.
