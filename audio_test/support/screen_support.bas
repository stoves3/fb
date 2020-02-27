Const defaultDepth As Integer = 32
Const defaultPages As Integer = 2

dim shared as integer activePage, visiblePage, targetPage

Declare Sub screen_Setup(sWidth As Integer, sHeight As Integer, sFullScreen As Integer, sDepth As Integer = defaultDepth, sPages As Integer = defaultPages)
Declare Sub screen_Swap(activeIsBackground as integer = 1)
Declare Sub screen_Draw()
declare function screen_increment(currentPage as integer) as integer

Sub screen_Setup(sWidth As Integer, sHeight As Integer, sFullScreen As Integer, sDepth As Integer = defaultDepth, sPages As Integer = defaultPages)
    if (sPages < defaultPages) then
        sPages = defaultPages
    end if

    ScreenRes sWidth, sHeight, sDepth, sPages, sFullScreen
    
    visiblePage = 1
    activePage = 0
    
    'ScreenSet activePage, visiblePage
    ScreenSet activePage, activePage
End Sub

Sub screen_Swap(activeIsBackground as integer = 1)
    dim as integer tmpPage
    
    tmpPage = visiblePage
    visiblePage = activePage
    activePage = tmpPage
    
    if (activeIsBackground) then
        ScreenSet activePage, visiblePage
    else
        ScreenSet activePage, activePage
    end if
    
End Sub

Sub screen_Draw()
    ScreenCopy activePage, visiblePage
End Sub