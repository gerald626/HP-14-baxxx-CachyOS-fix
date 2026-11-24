# HP-14-baxxx-CachyOS-fix
This script will install and enable the default on-screen keyboard, and fix the volume up/down buttons when in tablet mode when using CachyOS.

It installs libinput, libinput-tools and installs either maliit or plasma on-screen keyboards as needed. It then tries to figure out the volume up/down mappings when in tablet mode, since CachyOS just disables the PS/2 keyboard entirely, and the volume buttons are part of that hardware.

Created with the help of Gemini AI because it would have taken me forever to do this all myself. At least I'm doing something productive with it and not creating dumb videos.
