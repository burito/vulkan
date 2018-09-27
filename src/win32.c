
#include <windows.h>

#include "log.h"

#define VIDX 1280
#define VIDY 800

int vulkan_init(void);
void vulkan_loop(float current_time);

HINSTANCE hInst;
HWND hWnd;
int killme = 0;

LRESULT CALLBACK WndProc(HWND hWndProc, UINT uMsg, WPARAM wParam, LPARAM lParam)
{
	switch(uMsg) {
	case WM_DESTROY:
		DestroyWindow(hWndProc);
		PostQuitMessage(0);
		break;
	case WM_PAINT:
		ValidateRect(hWndProc, NULL);
		break;
	case WM_CLOSE:
		killme = 1;
		return 0;
	}
	return DefWindowProc(hWndProc, uMsg, wParam, lParam);
}

char *winClassName = "Kittens";

int APIENTRY WinMain(HINSTANCE hCurrentInst, HINSTANCE hPrev,
	    LPSTR lpszCmdLine, int nCmdShow)
{
	hInst = hCurrentInst;

	log_init();
	log_info("program start");

	WNDCLASSEX wc;
	wc.cbSize	= sizeof(WNDCLASSEX);
	wc.style	= CS_HREDRAW | CS_VREDRAW;
	wc.lpfnWndProc	= WndProc;
	wc.cbClsExtra	= 0;
	wc.cbWndExtra	= 0;
	wc.hInstance	= hInst;
	wc.hIcon	= LoadIcon(hInst, MAKEINTRESOURCE(0));
	wc.hIconSm	= NULL; //LoadIcon(hInst, IDI_APPLICAITON);
	wc.hCursor	= LoadCursor(NULL, IDC_ARROW);
	wc.hbrBackground= (HBRUSH)GetStockObject(BLACK_BRUSH);
	wc.lpszMenuName	= NULL;
	wc.lpszClassName= winClassName;

	if(!RegisterClassEx(&wc))
	{
		log_fatal("RegisterClassEx()");
		return 1;
	}
	RECT wr = {0, 0, VIDX, VIDY};
	AdjustWindowRect(&wr, WS_OVERLAPPEDWINDOW, FALSE);
	hWnd = CreateWindowEx(0, winClassName, winClassName,
		WS_OVERLAPPEDWINDOW | WS_VISIBLE | WS_SYSMENU, // WS_TILEDWINDOW, //|WS_CLIPSIBLINGS|WS_CLIPCHILDREN,
		50,50,
		wr.right - wr.left,  // width
		wr.bottom - wr.top,  // height
		NULL,NULL,hInst,NULL);

	if(!hWnd)
	{
		log_fatal("CreateWindowEx()");
		return 2;
	}
//	ShowWindow(hWnd, nCmdShow);
//	UpdateWindow(hWnd);


//	HDC hDC = GetDC(hWnd);


	vulkan_init();

	long last_time = timeGetTime();

	MSG mesg;

	while(!killme)
	{
		while(PeekMessage(&mesg, NULL, 0, 0, PM_REMOVE))
		{
			if(mesg.message == WM_QUIT)
				killme=TRUE;
			else
			{
				TranslateMessage(&mesg);
				DispatchMessage(&mesg);
			}

		}
		long time_now = timeGetTime();

		vulkan_loop( (time_now - last_time) * 0.0001 );
//		SwapBuffers(hDC);
		RedrawWindow(hWnd, NULL, NULL, RDW_INTERNALPAINT);
	}
	return 0;
}