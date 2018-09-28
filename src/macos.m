#import <Cocoa/Cocoa.h>
#import <AppKit/AppKit.h>
#import <QuartzCore/CAMetalLayer.h>

#include <MoltenVK/mvk_vulkan.h>

#include "log.h"

int vulkan_init(void);
int vulkan_loop(float time);

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


long start_time = 0;

static CVDisplayLinkRef _displayLink;


//
// NSView
//

@interface MyView : NSView
@end

@implementation MyView

-(id) init
{
	log_debug("MyView:init");
	window_view = self;
//	vulkan_init();

	CVDisplayLinkCreateWithActiveCGDisplays(&_displayLink);
	CVDisplayLinkSetOutputCallback(_displayLink, &DisplayLinkCallback, NULL);
//	CVDisplayLinkSetOutputCallback(_displayLink, &DisplayLinkCallback, void* ptr);
//	CVDisplayLinkStart(_displayLink);
	return [super init];


}

static CVReturn DisplayLinkCallback(CVDisplayLinkRef displayLink,
					const CVTimeStamp *now,
					const CVTimeStamp *outputTime,
					CVOptionFlags flagsIn,
					CVOptionFlags *flagsOut,
					void *target)
{
//	log_debug("MyViewController:DisplayLinkCallback");
//	if(we_have_vulkan)
	vulkan_loop( (timeGetTime() - start_time) * 0.001 );
	return kCVReturnSuccess;
}



-(void) dealloc
{
	log_debug("MyViewController:dealloc");
	// main_shutdown();
	CVDisplayLinkRelease(_displayLink);
	[super dealloc];
}


-(BOOL) wantsUpdateLayer
{
//	log_debug("MyView:wantsUpdateLayer");
	return YES;
}


+(Class) layerClass
{
//	log_debug("MyView:layerClass");
//	CAMetalLater * metal_layer = [CAMetalLayer class]
//	pView = metal_layer;
	return [CAMetalLayer class];
}

-(CALayer*) makeBackingLayer
{
//	log_debug("MyView:makeBackingLayer");
//	return [self.class.layerClass layer];
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
//	window.backgroundColor = [NSColor whiteColor];
	window.title = @"Kittens";

	[window setCollectionBehavior:(NSWindowCollectionBehaviorFullScreenPrimary)];
	return [super init];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotifcation
{
	log_debug("AppDelegate:applicationDidFinishLaunching");
	// init
//	my_View.wantsLayer = YES;
	vulkan_init();
	start_time = timeGetTime();
	CVDisplayLinkStart(_displayLink);
	
	log_debug("no really, we did finish launching");
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
	log_debug("AppDelegate:applicationWillTerminate");
	// shutdown

}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
	return YES;
}
@end


bool terminated = false;


@interface WindowDelegate : NSObject<NSWindowDelegate>
-(void)windowWillClose:(NSNotification*)aNotification;
@end
@implementation WindowDelegate
-(void)windowWillClose:(NSNotification*)aNotification
{
	terminated = true;
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

//	id window = [[NSWindow alloc] init contentViewController:viewcontroller];

//	MyViewController *viewcontroller = [[MyViewController alloc] init];
//	[window contentViewController] = viewcontroller;


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


	MyView *view = [[MyView alloc] init];
	[window setContentView:view];
	log_info("we are here");
	view.wantsLayer = YES;
	pView = [window_view layer];

	log_warning("we have a layer = %s", [[[window_view layer] description] cStringUsingEncoding:typeUTF8Text]);
//	vulkan_init();
	we_have_vulkan = 1;

	// main loop
	float time = 0.0;
	while(!terminated)
	{
		NSEvent * event = [NSApp nextEventMatchingMask:NSEventMaskAny untilDate:[NSDate distantPast] inMode:NSDefaultRunLoopMode dequeue:YES];
		if(event)
		{
			NSEventType eventType = [event type];
			switch(eventType) {
			case NSEventTypeKeyDown:
				terminated = 1;
				break;
			default:
				break;
			}
			[NSApp sendEvent:event];
			[NSApp updateWindows];
		}

//		NSRect rect = [contentView frame];
//		rect = [contentView convertRectToBacking:rect];

		// opengl draw commands
//		time += 0.00001;
//		vulkan_loop(time);
	}
	log_warning("view layer = %p", [window_view layer]);

	[pool drain];
	log_debug("quit successfully");
//	[myapp run];
//	[myapp setDelegate:nil];
	return 0;
//	return NSApplicationMain(argc, argv);
}


#ifdef DONT_USE

- (void)applicationWillFinishLaunching:(NSNotification *)aNotification
{
	log_debug("AppDelegate:applicationWillFinishLaunching");
	// Create the menu that goes on the Apple Bar
	NSMenu * mainMenu = [[NSMenu alloc] initWithTitle:@"MainMenu"];
	NSMenuItem * menuTitle;
	NSMenu * aMenu;

	menuTitle = [mainMenu addItemWithTitle:@"Apple" action:NULL keyEquivalent:@""];
	aMenu = [[NSMenu alloc] initWithTitle:@"Apple"];
	[NSApp performSelector:@selector(setAppleMenu:) withObject:aMenu];

	// generate contents of menu
	NSMenuItem * menuItem;
	NSString * applicationName = @"tiny";
	menuItem = [aMenu addItemWithTitle:[NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"About", nil), applicationName]
				    action:@selector(orderFrontStandardAboutPanel:)
			     keyEquivalent:@""];
	[menuItem setTarget:NSApp];
	[aMenu addItem:[NSMenuItem separatorItem]];

	menuItem = [aMenu addItemWithTitle:NSLocalizedString(@"Fullscreen", nil)
				    action:@selector(toggleFullScreen:)
			     keyEquivalent:@"f"];
	[menuItem setKeyEquivalentModifierMask:NSEventModifierFlagCommand | NSEventModifierFlagControl];
	menuItem.target = nil;

	[aMenu addItem:[NSMenuItem separatorItem]];

	menuItem = [aMenu addItemWithTitle:[NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"Quit", nil), applicationName]
				    action:@selector(terminate:)
			     keyEquivalent:@"q"];
	[menuItem setTarget:NSApp];

	// attach generated menu to menuitem
	[mainMenu setSubmenu:aMenu forItem:menuTitle];
	[NSApp setMainMenu:mainMenu];

	// Because this is where you do it?
	log_debug("added menu ok");
	pView = [[MyView alloc] init];


	[window setContentView:pView];
	log_debug("set content view");

}
#endif