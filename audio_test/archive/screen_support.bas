Const defaultDepth As Integer = 32
Const defaultPages As Integer = 1

Declare Sub screen_Setup(sWidth As Integer, sHeight As Integer, sFullScreen As Integer, sDepth As Integer = defaultDepth, sPages As Integer = defaultPages)

Sub screen_Setup(sWidth As Integer, sHeight As Integer, sFullScreen As Integer, sDepth As Integer = defaultDepth, sPages As Integer = defaultPages)
    ScreenRes sWidth, sHeight, sDepth, sPages, sFullScreen
End Sub