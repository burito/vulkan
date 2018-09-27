#include <stdlib.h>
#include <xcb/xcb.h>

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

xcb_connection_t *xcb;
xcb_window_t window;

int main(int argc, char *argv[])
{
	xcb_screen_t *screen;
	xcb_intern_atom_reply_t *atom_wm_delete_window;

	int scr;
	xcb = xcb_connect(NULL, &scr);
	const xcb_setup_t *setup;
	xcb_screen_iterator_t iter;

	setup = xcb_get_setup(xcb);
	iter = xcb_setup_roots_iterator(setup);
	while( scr-- > 0) xcb_screen_next(&iter);
	screen = iter.data;

	window = xcb_generate_id(xcb);

	uint32_t value_mask, value_list[32];
	value_mask = XCB_CW_BACK_PIXEL | XCB_CW_EVENT_MASK;
	value_list[0] = screen->black_pixel;
	value_list[1] = XCB_EVENT_MASK_KEY_RELEASE;

	xcb_create_window(xcb, XCB_COPY_FROM_PARENT, window, screen->root, 0, 0, VIDX, VIDY, 0,
	XCB_WINDOW_CLASS_INPUT_OUTPUT, screen->root_visual, value_mask, value_list);

	xcb_map_window(xcb, window);

	/* Vulkan Initialisation is here! */
	vulkan_init();
	/* Vulkan Initialisation ends here! */
	xcb_flush(xcb);
	long last_time = timeGetTime();
	int quit = 0;
	while(!quit) {
		xcb_generic_event_t *event = xcb_poll_for_event(xcb);
		while(event)
		{
			switch ( event->response_type & 0x7f) {
			case XCB_KEY_RELEASE:
			case XCB_DESTROY_NOTIFY:
			case XCB_DESTROY_WINDOW:
			case XCB_KILL_CLIENT:
				quit = 1;
			default:
				break;	
			}
			free(event);
			event = xcb_poll_for_event(xcb);
		}
		/* main loop is here! */

		int ret = 0;
		long time_now = timeGetTime();
		ret = vulkan_loop( (time_now - last_time) * 0.001 );

		if(ret)quit = 1;
		/* main loop ends here! */
	}
	return 0;
}
