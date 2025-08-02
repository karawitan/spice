Recommended Configuration for macOS
For a macOS client, your optimal configuration would be:

--enable-glib=yes (for utility library support)

--enable-gl=yes (for full OpenGL support)

--enable-glx=yes (essential for proper X11/OpenGL integration on macOS)

--enable-gles1=no and --enable-gles2=no (unless you specifically need embedded OpenGL support)

The GLX extension is particularly important on macOS because it handles the complex task of bridging OpenGL rendering with the X11 windowing system through XQuartz, ensuring proper graphics performance and compatibility.