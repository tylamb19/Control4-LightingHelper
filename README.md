# Lighting Helper

## Welcome to Lighting Helper, the perfect companion to Control4’s Gen3 Lighting Devices.

This driver allows you to add a list of devices to monitor for ambient lighting changes, as well as helpful programming commands, such as adjustments to backlight and status light curves, direct dimming and brightening of all LEDs, replacement of status LED colors, and more.

Ambient lighting monitoring is completed by first selecting your devices in the properties screen, then making the proper connections in the connections menu. A driver level variable will be created for each of the devices you selected in the properties window. This variable will be updated each time the light level is updated by the system, which is usually within 5 seconds of ambient light level changing. These variables can be used for all supported arithmetic comparisons in Control4 programming (equal to, greater than, not equal to, etc).

**This driver is NOT endorsed or created by Control4. I am just a dealer and programmer who loves the product.**

### Installation

Head over to the releases page (https://github.com/tylamb19/Control4-LightingHelper/releases) and download the latest .c4z file. Add this driver to your Control4 system, and you should be good to go.

Any questions or issues, please open an issue or pull request at:
https://github.com/tylamb19/Control4-LightingHelper
