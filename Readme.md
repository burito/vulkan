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

    git clone git@github.com:KhronosGroup/MoltenVK
    cd MoltenVK
    ./fetchDependencies
    xcodebuild -project MoltenVKPackaging.xcodeproj -scheme "MoltenVK Package (Release)" build



Credits
=======
* lib/include/vulkan/* - Khronos Group
	* https://github.com/KhronosGroup/Vulkan-Headers
	* 2fd5a24ec4a6df303b2155b3f85b6b8c1d56f6c0
* lib/include/MoltenVK/* - Khronos Group
	* https://github.com/KhronosGroup/MoltenVK/
	* 4c5f7b8b0deeb11b8f72d1af6ffef882305170c3
* src/macos.m
	* based on the work of Dmytro Ivanov
	* https://github.com/jimon/osx_app_in_plain_c

For everything else, I am to blame.