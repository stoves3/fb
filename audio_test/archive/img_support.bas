#include once "fbgfx.bi"
#include once "datetime_support.bas"
#include once "formula_support.bas"

Const bmpWidthPos As Integer = 19
Const bmpHeightPos As Integer = 23
Const NULL As Any Ptr = 0

Const defaultScrollDuration = 2000
const defaultFadeInterval = 10
Const defaultStartInterval = 10
Const defaultEndInterval = 18

Declare Function img_Get(fileName As String) As Any Ptr
Declare Sub img_Scroll(img As Any Ptr, x1 As Integer, y1 As Integer, dX As Integer, dY As Integer, msMinInterval As Integer = defaultStartInterval, msMaxInterval As Integer = defaultEndInterval)
declare sub img_FadeIn(img as any ptr, x as integer, y as integer, msInterval as integer = defaultFadeInterval)
Declare Sub img_ScrollByDuration(img As Any Ptr, x1 As Integer, y1 As Integer, dX As Integer, dY As Integer, milliseconds As Integer = defaultScrollDuration)

Function img_Get(filePath As String) As Any Ptr
    Dim As Integer filenum, imgWidth, imgHeight
    Dim img As Any Ptr
    
    filenum = freefile()
    if open( filePath for binary access read as #filenum ) <> 0 then return NULL
    
    get #filenum, bmpWidthPos, imgWidth
    get #filenum, bmpHeightPos, imgHeight
        
    close #filenum
    
    img = ImageCreate(imgWidth,imgHeight)
    
    BLoad filePath, img
    
    return img
End Function

Sub img_Scroll(img As Any Ptr, x1 As Integer, y1 As Integer, dX As Integer, dY As Integer, msStartInterval As Integer = defaultStartInterval, msEndInterval As Integer = defaultEndInterval)
    dim as integer maxDelta, x, y, dXIsMax, dXSign, dYSign, dXProgress, dYProgress
    dim as integer interval, sInterval, eInterval, dInterval
    dim as double progress, intervalProgress
    
    sInterval = abs(msStartInterval)
    eInterval = abs(msEndInterval)
    if (sInterval >= eInterval) then
        eInterval = sInterval
        sInterval = abs(msEndInterval)
    end if
    dInterval = eInterval - sInterval
    
    dXSign = 1
    dYSign = 1
    if (dX < 0) then dXSign = -1
    if (dY < 0) then dYSign = -1
    
    dX = abs(dX)
    dY = abs(dY)
    maxDelta = dX
    dXIsMax = 1
    if (dY > maxDelta) then
        maxDelta = dY
        dXIsMax = 0
    end if    
    
    for i as integer = 0 to maxDelta
        if (Inkey = chr(13)) return
        
        progress = i/maxDelta
        intervalProgress = fx_blendExponential(progress)
        interval = sInterval + intervalProgress * dInterval
        
        if (dxIsMax = 1) then
            x = x1 + (i * dXSign)
            
            y = y1
            if (dY > 0) then
                dYProgress = dY * progress
                y = y1 + (dYProgress * dYSign)            
            end if
        else
            x = x1
            if (dX > 0) then
                dXProgress = dX * progress
                x = x1 + (dXProgress * dXSign)
            end if
            
            y = y1 + (i * dYSign)
        end if
        
        put(x,y), img, pset
        sleep(interval)
    next i
End Sub

sub img_FadeIn(img as any ptr, x as integer, y as integer, msInterval as integer = defaultFadeInterval)
    
    for i as integer = 0 to 255
        if (Inkey = chr(13)) return
        
        put (x,y), img, alpha, i
        sleep(msInterval)
    next i
    
end sub

sub img_FadeOut(img as any ptr, x as integer, y as integer, msInterval as integer = defaultFadeInterval)
    
    for i as integer = 255 to 0 step -1
        if (Inkey = chr(13)) return
        
        put (x,y), img, alpha, i
        sleep(msInterval)
    next i
    
end sub

Sub img_ScrollByDuration(img As Any Ptr, x1 As Integer, y1 As Integer, dX As Integer, dY As Integer, milliseconds As Integer = defaultScrollDuration)
    Dim As Integer x, y, pX, pY, x2, y2
    Dim As Double dNow, dStart, progress
    Dim As Integer elapsed = 0
    
    x = x1
    y = y1
    pX = x
    pY = y
    put (x,y), img, pset
    sleep(1)
    
    dNow = datetime_now
    dStart = dNow
    
    while milliseconds > elapsed
        if (Inkey = chr(13)) return
        
        elapsed = datetime_elapsedMilliseconds(datetime_now, dStart)
        progress = elapsed / milliseconds
        
        x = x1 + (dX * progress)
        y = y1 + (dY * progress)
        
        if (pX <> x or pY <> y) then
            put (x,y), img, pset
            sleep(1)
            pX = x
            pY = y
        end if
    wend
    
    x = x1 + dX
    y = y1 + dY
    put (x,y), img, pset
    sleep(1)
End Sub