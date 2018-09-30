#import <Cocoa/Cocoa.h>
#import <AppKit/AppKit.h>
#import <QuartzCore/CAMetalLayer.h>

#include <MoltenVK/mvk_vulkan.h>

#include "log.h"

int vulkan_init(void);
int vulkan_loop(float time);

int killme = 0;
long start_time = 0;
static CVDisplayLinkRef _displayLink;

NSWindow *window;
void * pView = NULL;
NSView * window_view = NULL;
#define VIDX 1280
#define VIDY 800

int we_have_vulkan = 0;

#include <sys/time.h>
static long timeGetTime( void ) // Thanks Inigo Quilez!
{
	struct timeval now, res;
	gettimeofday(&now, 0);
	return (long)((now.tv_sec*1000) + (now.tv_usec/1000));
}


//
// NSView
//

@interface View : NSView
@end

@implementation View

-(id) init
{
	log_debug("View:init");
	CVDisplayLinkCreateWithActiveCGDisplays(&_displayLink);
	CVDisplayLinkSetOutputCallback(_displayLink, &DisplayLinkCallback, NULL);
	return [super init];
}

static CVReturn DisplayLinkCallback(CVDisplayLinkRef displayLink,
					const CVTimeStamp *now,
					const CVTimeStamp *outputTime,
					CVOptionFlags flagsIn,
					CVOptionFlags *flagsOut,
					void *target)
{
//	log_debug("View:DisplayLinkCallback");
	vulkan_loop( (timeGetTime() - start_time) * 0.001 );
	return kCVReturnSuccess;
}

-(void) dealloc
{
	log_debug("View:dealloc");
	// main_shutdown();
	CVDisplayLinkRelease(_displayLink);
	[super dealloc];
}

-(BOOL) wantsUpdateLayer { return YES; }

+(Class) layerClass { return [CAMetalLayer class]; }

-(CALayer*) makeBackingLayer
{
//	log_debug("View:makeBackingLayer");
	CALayer *layer = [self.class.layerClass layer];
	CGSize viewScale = [self convertSizeToBacking: CGSizeMake(1.0, 1.0)];
	layer.contentsScale = MIN(viewScale.width, viewScale.height);
	return layer;
}
@end


//
// App Delegate
//
@interface AppDelegate : NSObject <NSApplicationDelegate>
@end

@implementation AppDelegate

- (id)init
{
	log_debug("AppDelegate:init");
	NSRect contentSize = NSMakeRect(100.0, 400.0, 640.0, 360.0);
	NSUInteger windowStyleMask = NSWindowStyleMaskTitled | NSWindowStyleMaskResizable | NSWindowStyleMaskClosable | NSWindowStyleMaskMiniaturizable;
	window = [[NSWindow alloc] initWithContentRect:contentSize styleMask:windowStyleMask backing:NSBackingStoreBuffered defer:YES];

	[window setCollectionBehavior:(NSWindowCollectionBehaviorFullScreenPrimary)];
	return [super init];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotifcation
{
	log_debug("AppDelegate:applicationDidFinishLaunching");
	// init
	start_time = timeGetTime();
	CVDisplayLinkStart(_displayLink);
	log_debug("no really, we did finish launching");
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
	log_debug("AppDelegate:applicationWillTerminate");
	// shutdown
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)x { return YES; }
@end


@interface WindowDelegate : NSObject<NSWindowDelegate>
-(void)windowWillClose:(NSNotification*)aNotification;
@end
@implementation WindowDelegate
-(void)windowWillClose:(NSNotification*)aNotification
{
	killme = 1;
}
@end

int main(int argc, const char * argv[])
{
	log_init();
	log_debug("main()");

	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	NSApplication * myapp = [NSApplication sharedApplication];
	AppDelegate * appd = [[AppDelegate alloc] init];
	[myapp setDelegate:appd];
	[myapp finishLaunching];

	// build menu
	id menubar = [[NSMenu alloc] init];
	id appMenuItem = [[NSMenuItem alloc] init];
	[menubar addItem:appMenuItem];
	[NSApp setMainMenu:menubar];
	id appMenu = [[NSMenu alloc] init];
	id appName = [[NSProcessInfo processInfo] processName];
	id quitTitle = [@"Quit " stringByAppendingString:appName];
	id quitMenuItem = [[NSMenuItem alloc] initWithTitle:quitTitle action:@selector(terminate:) keyEquivalent:@"q"];
	[appMenu addItem:quitMenuItem];
	[appMenuItem setSubmenu:appMenu];


	id window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, VIDX*0.5, VIDY*0.5)
		styleMask: NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskMiniaturizable | NSWindowStyleMaskResizable backing:NSBackingStoreBuffered defer:NO];
	[window setReleasedWhenClosed:NO];
	WindowDelegate * wdg = [[WindowDelegate alloc] init];
	[window setDelegate:wdg];
//	NSView * contentView = [window contentView];
//	[contentView setWantsBestResolutionOpenGLSurface:YES];	// retina support
	[window cascadeTopLeftFromPoint:NSMakePoint(20,20)];
	[window setTitle:@"sup"];

	// opengl init

	[window makeKeyAndOrderFront:window];
//	[window setAcceptsMouseMovedEvents:YES];
//	[window setBackgroundColor:[NSColor whiteColor]];
//	[NSApp activateIgnoringOtherApps:YES];


	NSView *view = [[View alloc] init];
	[window setContentView:view];
	log_info("we are here");
	view.wantsLayer = YES;
	pView = [view layer];

	vulkan_init();

	// main loop
	float time = 0.0;
	while(!killme)
	{
		NSEvent * event = [NSApp nextEventMatchingMask:NSEventMaskAny untilDate:[NSDate distantPast] inMode:NSDefaultRunLoopMode dequeue:YES];
		if(event)
		{
			NSEventType eventType = [event type];
			switch(eventType) {
			case NSEventTypeKeyDown:
				killme = 1;
				break;
			default:
				break;
			}
			[NSApp sendEvent:event];
			[NSApp updateWindows];
		}

		// opengl draw commands
	}

	[pool drain];
	log_debug("quit successfully");
	return 0;
}



