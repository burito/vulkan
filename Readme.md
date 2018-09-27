Vulkan Example
==============
This is a basic Vulkan Fragment Shader Window example, with the intention that it compiles from the command line on Windows, Linux and MacOS.
So far Windows and Linux behave as intended, but MacOS, while it claims to initialise correctly, only displays a black window.

Windows and Linux
=================
* Download the LunarG Vulkan SDK.
* Ensure the VULKAN_PATH is correct in the Makefile
* ```make```


MacOS
=====
Check the MoltenVK Github Readme for up to date information, but as of now...

* ```git clone git@github.com:KhronosGroup/MoltenVK```
* ```cd MoltenVK```
* ```./fetchDependencies```
* ```xcodebuild -project MoltenVKPackaging.xcodeproj -scheme "MoltenVK Package (Release)" build```