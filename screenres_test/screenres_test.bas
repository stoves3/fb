#include once "fbgfx.bi"

Declare Sub DisplayImage(img As Any Ptr, sizeInfo As String, nextStep as String, fullScreen As Long, setScreen As Long)
Declare Sub GetImgDimensions(filePath As String) 

Const bmpWidthPos As Integer = 19
Const bmpHeightPos As Integer = 23
Const subFolder As String = "images/"

Dim Shared As Integer sWidth, sHeight, sDepth, sPages, imgWidth, imgHeight
Dim Shared As Integer nextImgWidth, nextImgHeight

sWidth = 1920
sHeight = 1080
sDepth = 32
sPages = 1


ScreenRes sWidth,sHeight,sDepth,sPages,1

Dim img As Any Ptr
nextImgWidth = 0
nextImgHeight = 0
img = ImageCreate(nextImgWidth,nextImgHeight)

Const NULL As Any Ptr = 0

Dim as string filename
filename = dir(subFolder + "*.bmp")
do while len(filename)
    GetImgDimensions(subFolder + filename)
    
    BLoad subFolder + filename, img
    DisplayImage(img, STR(nextImgWidth) + " x " + STR(nextImgHeight), "For Next Image", 1, 0)
    
    filename = dir()
    img = NULL
loop

'DisplayImage(cityimg01, "626 x 626", "For 1920 x 1080 Image", 1, 1)
'DisplayImage(cityimg02, "1920 x 1080", "to Switch to Windowed Mode", 1, 0)
imageDestroy img
End

Sub GetImgDimensions(filePath As String)
    Dim As Integer filenum
    
    filenum = freefile()
    if open( filePath for binary access read as #filenum ) <> 0 then return
    
    get #filenum, bmpWidthPos, nextImgWidth
    get #filenum, bmpHeightPos, nextImgHeight
    
    nextImgWidth = nextImgWidth
    nextImgHeight = nextImgHeight
    
    close #filenum
    
End Sub

Sub DisplayImage(img As Any Ptr, sizeInfo As String, nextStep as String, fullScreen As Long, setScreen As Long)
Dim As String screenMode

If (fullScreen = 1) Then
    screenMode = "FULL SCREEN Mode"
Else
    screenMode = "Windowed Mode"
End If

if (setScreen = 1) Then
    ScreenRes sWidth,sHeight,sDepth,sPages,fullScreen
End If

PUT (0,0), img, pset
Locate 20, 20

'Print sizeInfo; " Image on Screen "; sWidth; " x "; sHeight; " ("; STR(sDepth); "-bit depth) "; screenMode
Print "Screen Info: " + Str(sWidth) + " x " + Str(sHeight) + " (" + Str(sDepth) + "-bit depth) " + screenMode
Locate 22, 20
Print "Hit Enter " + nextStep

sleep

End Sub