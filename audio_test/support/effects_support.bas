#include once "crt.bi"
#include once "fbgfx.bi"
#include once "formula_support.bas"
#include once "debug_support.bas"

const as double defaultNegYFreqPct = .1
const as double defautlWaveOffsetPct = .02
const efxSkipKey as string = chr(27)

'dim shared as any ptr offscreenImg
dim shared as integer sW, sH, sD, sBpp

dim shared as any ptr img_rows(1079)

declare sub efx_setupWorkspace()
declare sub efx_cleanupOffScreenImg()
declare sub efx_wavyEffect(bgImg as any ptr, fxImg as any ptr, fxX as integer, fxY as integer, fgImg as any ptr, fgX as integer, fgY as integer, negYFreqPct as double = defaultNegYFreqPct, waveOffsetPct as double = defautlWaveOffsetPct)

declare sub efx_drawCenteredXEffect(img as any ptr, oX as integer, oY as integer, offset as integer, rad as double)
declare sub efx_drawNegativeYEffect(img as any ptr, oX as integer, oY as integer, offset as integer, rad as double)

'declare sub efx_drawEffect(img as any ptr, oX as integer, oY as integer, offset as integer, rad as double, isHorizontal as integer)

sub efx_setupOffScreenImg()
    
    screeninfo(sW, sH, sD, sBpp)
    debug_console("sW: " & sW & ", sH: " & sH & ", sD: " & sD & ", sBpp: " & sBpp)
    'offscreenImg = imagecreate(sW, sH, bpp)
end sub

sub efx_cleanupOffScreenImg()
    'imagedestroy(offscreenImg)
end sub

sub efx_wavyEffect(bgImg as any ptr, fxImg as any ptr, fxX as integer, fxY as integer, fgImg as any ptr, fgX as integer, fgY as integer, negYFreqPct as double = defaultNegYFreqPct, waveOffsetPct as double = defautlWaveOffsetPct)
    'dim as integer w, h, bpp, pitch, size, result, y
    'dim as byte ptr pixdata
    dim as double xRadShift, yRadShift
    dim as double nextXRad, nextNegYRad, maxRadians
    dim as integer waveXOffset, fxNegYOffset, bgX, row
    dim as string keyPress
    dim as any ptr nextImgRow
    
    maxRadians = fx_maxRadians()
    
    'result = imageinfo(offscreenImg, w, h, bpp, pitch, pixdata, size)
    
    if (waveOffsetPct > 1.0) then waveOffsetPct = waveOffsetPct / 100
    if (negYFreqPct > 1.0) then negYFreqPct = negYFreqPct / 100
    
    waveXOffset = waveOffsetPct * sW
    fxNegYOffset = negYFreqPct * sH
    
    xRadShift = maxRadians / waveXOffset
    yRadShift = maxRadians / fxNegYOffset
    
    bgX = fx_ellipseX(waveXOffset, 0) * -1
    
    nextXRad = 0
    nextNegYRad = 0
    
    debug_console("Height: " & sH & ", Width: " & sW & ", Depth: " & sD & ", Bpp: " & sBpp)
    
    row = 0
    
    'do
        
    for i as integer = 0 to 253 ' sH - 2
        
        'debug_console("Line: " & i)
        'efx_drawEffect(bgImg, bgX, 0, waveXOffset, nextXRad, 1)
        'efx_drawEffect(fxImg, fxX, fxY, fxNegYOffset, nextNegYRad, 0)
        
        efx_drawCenteredXEffect(bgImg, bgX, 0, waveXOffset, nextXRad)
        efx_drawNegativeYEffect(fxImg, fxX, fxY, fxNegYOffset, nextNegYRad)
        put (fgX,fgY), fgImg, alpha, 200
        'screen_Swap
        
        nextXRad = nextXRad + xRadShift
        nextNegYRad = nextNegYRad + yRadShift
        if (nextXRad > maxRadians) then nextXRad = 0
        if (nextNegYRad > maxRadians) then nextNegYRad = 0
        
        'img_transfer(offscreenImg, row, w, bpp)
        nextImgRow = imagecreate(sW + 1, 2, , sD)
        get screenptr, (0,i)-(sW,i), nextImgRow
        img_rows(i) = nextImgRow
        
        sleep(1)
        
        'keyPress = inkey
        
        'row = row + 1
        
        'screen_Draw
    
        if (keyPress = efxSkipKey) then
            i = sH - 1
        end if
    next i
    
    debug_console("Image Composition Complete")
    
    'screen_Swap
    cls
    'put (0,0), offscreenImg, pset
    for y as integer = 0 to 253 'sH - 2
        put (0,y), img_rows(y), alpha, 255
    next y
    'screen_Draw
    
    debug_console("Image Draw Complete")
            
    'redim as any ptr img_rows(1079)        
    
    'loop until keyPress = efxSkipKey
    
end sub

sub efx_drawCenteredXEffect(img as any ptr, oX as integer, oY as integer, offset as integer, rad as double)
    dim as integer x
    
    x = oX + fx_ellipseX(offset, rad)
    
    put (x, oY), img, alpha, 255
end sub

sub efx_drawNegativeYEffect(img as any ptr, oX as integer, oY as integer, offset as integer, rad as double)
    dim as integer y
    
    y = oY + fx_ellipseY(offset, rad)
    
    put (oX, y), img, alpha, 130
end sub

'sub efx_drawEffect(img as any ptr, oX as integer, oY as integer, offset as integer, rad as double, isHorizontal as integer)
    'if (isHorizontal = 1) then 
        'efx_drawCenteredXEffect(img, oX, oY, offset, rad)
    'else
        'efx_drawNegativeYEffect(img, oX, oY, offset, rad)
    'end if
'end sub

'declare sub efx_wavybackground(img as any ptr, offsetPct as double = defautlOffsetPct)

'declare sub efx_wavybackground(img as any ptr, fgImg as any ptr, fgX as integer = 0, fgY as integer = 0, frequencyPct as double = defaultFreqPct, offsetPct as double = defautlOffsetPct)
'declare sub efx_drawWavyFrame(imag as any ptr, w as integer, r as double, radShift as double, rad as double)
'declare function efx_pixelptr(byval img as any ptr, byval x as integer, byval y as integer) as any ptr

'sub efx_drawWavyFrame(img as any ptr, pixdata as byte ptr, pitch as integer, bpp as integer, w as integer, r as double, radShift as double, rad as double)
    'dim as integer xOffset
    'dim as double nextRad, maxRad
    'dim as byte ptr pp
    
    'maxRad = fx_maxRadians()
    
    'lines = fx_maxRadians() / radShift
    'nextRad = rad
    
    'for y as integer = 0 to lines - 1
        'xOffset = fx_ellipseX(r, nextRad)
        
        'for x as integer = 0 + xOffset to w + xOffset - 1
            'if (x > -1 and x < w) then
                'pp = pixdata + y * pitch + x * bpp
                '*pp = offscreenImg
            'end if            
        'next x
        
        'nextRad = nextRad + radShift
        
        'if (nextRad > maxRad) nextRad = 0
    'next y
        
'end sub

'sub efx_wavybackground(img as any ptr, offsetPct as double = defautlOffsetPct)
    'dim as integer xOffset
    'dim as integer w, h, bpp, pitch, size, result
    'dim as double radShift, r, nextRad
    'dim as byte ptr pixdata
    
    'if (offsetPct > 1.0) then v = offsetPct / 100
    
    'result = ImageInfo(img, w, h, bpp, pitch, pixdata, size)
    'offscreenImg = imagecreate(w, h)
    
    'xOffset = offsetPct * w
    ''yFrequency = yFrequencyPct * h
    'r = xOffset / fx_maxRadians()
    'radShift = fx_maxRadians() / h
    
    'nextRad = 0
    'do
        'nextRad = efx_drawWavyFrame(img, pixdata, pitch, bpp, w, r, radShift, nextRad)
        'nextRad = nextRad + radShift
        'keyPress = Inkey
        
    'loop until keyPress = efxSkipKey
    
'end sub

'function efx_pixelptr(byval img as any ptr, byval x as integer, byval y as integer) as any ptr
    'Dim As Integer w, h, bypp, pitch
    'Dim As Any Ptr pixdata
    'Dim As Integer success
    
    'success = (imageinfo(img, w, h, bypp, pitch, pixdata) = 0)
    
    'If success Then
        'If x < 0 Or x >= w Then Return 0
        'If y < 0 Or y >= h Then Return 0
        'Return pixdata + y * pitch + x * bypp
    'Else
        'Return 0
    'End If
'end function