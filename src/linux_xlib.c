#include <stdlib.h>
#include <X11/Xlib.h>

#include "log.h"
int vulkan_init(void);
int vulkan_loop(float current_time);

#define VIDX 1280
#define VIDY 800

#include <sys/time.h>
static long timeGetTime( void ) // Thanks Inigo Quilez!
{
	struct timeval now, res;
	gettimeofday(&now, 0);
	return (long)((now.tv_sec*1000) + (now.tv_usec/1000));
}

Display *display;
Window window;

int main(int argc, char *argv[])
{
	log_init();
	log_debug("Program Start");

	display = XOpenDisplay(NULL);
	log_debug("XOpenDisplay");

	int screen = DefaultScreen(display);
	int white_pixel = WhitePixel(display, screen);
	int black_pixel = BlackPixel(display, screen);

	window = XCreateSimpleWindow( display, RootWindow(display, screen), 0, 0, VIDX, VIDY, 0, white_pixel, black_pixel );
	log_debug("XCreateSimpleWindow");

	XSetWindowAttributes winAttr;
	winAttr.override_redirect = 1;
	XChangeWindowAttributes(display, window, CWOverrideRedirect, &winAttr);

	XWarpPointer(display, None, window, 0, 0, 0, 0, VIDX, 0);
	XMapWindow(display, window);
	XMapRaised(display, window);
	XFlush(display);

	/* Vulkan Initialisation is here! */
	vulkan_init();

	XGrabKeyboard(display, window, True, GrabModeAsync,GrabModeAsync,CurrentTime);
	long last_time = timeGetTime();

	XEvent event;
	while( !XCheckTypedEvent(display, KeyPress, &event) )
	{

		/* main loop is here! */
		long time_now = timeGetTime();
		vulkan_loop( (time_now - last_time) * 0.0001 );
	}
	return 0;
}