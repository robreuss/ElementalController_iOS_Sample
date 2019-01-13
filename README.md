# ElementalController iOS Sample App
### Overview
This is an iOS client application created using [ElementalController](https://github.com/robreuss/ElementalController) for demo purposes.  It is designed to be used with it's server-side Linux counterpart [ElementalController Linux Sample App](https://github.com/robreuss/ElementalController_Linux_Sample.git), which has been tested to run under Ubuntu Mate on a Raspberry Pi as well as desktop Ubuntu 16.04.  Although it has not been tested on Raspbian, the framework has and it should work.    

The two apps mimic a scenario where an iOS app is being used to control a Raspberry Pi-based robot vehicle, by sending commands and a speed value.  

### Installation
Clone or download.

Use the command line to go into the project directory and update the frameworks using Carthage:

```
carthage update
```
Use Finder to go into the `Carthage/Build` directory and drag the `ElementalController.framework` file into the target "Embedded Binaries" section.

The app should build and run at that point.  Next step is to setup the [Linux counterpart](https://github.com/robreuss/ElementalController_Linux_Sample.git) and start sending data back and forth!

Please don't hesitate to create an issue if you need assitance.  