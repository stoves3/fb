#include once "windows.bi"
#include once "win/commctrl.bi"
#include once "win/ole2.bi"
#include once "movctrl.bas"

declare sub vid_play(filename as string, byval parentWnd as HWND, vWidth as integer, vHeight as integer)
declare function video_GethWnd() as HWND

sub vid_play(filename as string, byval parentWnd as HWND, vWidth as integer, vHeight as integer)
    dim as movctrl ptr movie
    
    movie = new movctrl(parentWnd, 0, 0, vWidth, vHeight)
    
    if (movie = null) then return
    
    if (movie->load(filename) = false) then
        delete movie
        return
    end if
    
    movie->play()
end sub

function video_GethWnd() as HWND
    Dim hWnd As HWND
    Dim ProcessID As HANDLE
    
    hWnd = GetForegroundWindow
    Do While hWnd
        If IsWindowVisible(hWnd) Then
            'GetWindowThreadProcessId(hWnd, @ProcessID)
            If ProcessID = GetCurrentProcessID() Then Return hWnd
        End If
        
        hWnd = GetWindow(hWnd, GW_HWNDNEXT)
    Loop
    
    return hWnd
end function

function video_GethWndOld() As HWND
    dim hWnd As HWND 
    dim  as HANDLE ProcessID 
    dim as integer res,mypid 
    dim wt as string * 256 
    mypid=GetCurrentProcessID
    hWnd=FindWindow(NULL,NULL) 
    do while hWnd 
        'GetWindowThreadProcessId(hWnd,@ProcessID) 
        if ProcessID = mypid Then 
            res=GetWindowText(hWnd,strptr(wt),255) 
            wt=trim(left(wt,res)) 
            if wt<>"DIEmWin" then 'don't ask
                return hWnd 
            end if 
        end if 
        hWnd = GetWindow(hWnd,GW_HWNDNEXT) 
    loop 
    return 0 
end function