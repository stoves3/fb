#include once "support\img_support.bas"
#include once "support\screen_support.bas"
#include once "support\effects_support.bas"
'#include once "support\audio_support.bas"
'#include once "support\video_support.bas"

'const as string midgarImgFilename = "Midgar.bmp"
'const as string corelPrisonImgFilename = "Corel Prison Tall.bmp"
'const as string outdoorReactorImgFilename = "Outdoor Reactor Tall.bmp"
'const as string makoReactor01ImgFilename = "Mako Reactor 01 Tall.bmp"
'const as string makoReactor02ImgFilename = "Mako Reactor 02 Tall.bmp"
'const as string oldReactorImgFilename = "Old Reactor Tall.bmp"
'const as string newMidgarImgFilename = "newMidgar.bmp"
'const as string ff7SimpleLogoImgFilename = "FF7 Simple Logo.bmp"

'const as string introMidFilename = "intro.mid"
'const as string aerithMidFilename = "aerith.mid"
'const as string graveReckoningWavFilename = "grave-reckoning.wav"
'const as string windWavFilename = "wind.wav"
'const as string rainforestWavFilename = "rainforest.wav"

'const as string sqlogoAviFilename = "sqlogo.AVI"

'dim shared as HWND hWnd

'filename as string, byval parentWnd as HWND, vWidth as integer, vHeight as integer
'hWnd = GetForegroundWindow
'vid_play(vidFolder + sqlogoAviFilename, null, sWidth, sHeight)

dim shared as integer sWidth, sHeight, sFullScreen

sWidth = 1920
sHeight = 1080
sFullScreen = 0

screen_Setup sWidth, sHeight, sFullScreen

const as string imgFolder = "img/"
const as string bgmFolder = "bgm/"
const as string sfxFolder = "sfx/"
const as string vidFolder = "video/"

const as string sephirothImgFilename = "Sephiroth.bmp"
const as string fireImgFilename = "Fire.bmp"
const as string rocketTownImgFilename = "Rocket Town Background Large.bmp"

dim as any ptr img, fxImg, bgImg, fgImg
dim as string filePath

bgImg = img_Get(imgFolder + rocketTownImgFilename)
fxImg = img_Get(imgFolder + fireImgFilename)
fgImg = img_Get(imgFolder + sephirothImgFilename)

'efx_wavyEffect(bgImg as any ptr, fxImg as any ptr, fxX as integer, fxY as integer, fgImg as any ptr, fgX as integer, fgY as integer, negYFreqPct as double = defaultNegYFreqPct, waveOffsetPct as double = defautlWaveOffsetPct)
efx_setupOffScreenImg()
efx_wavyEffect(bgImg, fxImg, 0, 200, fgImg, 300, 550)

sleep

efx_cleanupOffScreenImg
imageDestroy bgImg
imageDestroy fxImg
imageDestroy fgImg
end

'img = img_Get(imgFolder + midgarImgFilename)
'put(0,0), img, pset
'sleep(2000)

'bgm_play(bgmFolder + introMidFilename)

'img = img_Get(imgFolder + corelPrisonImgFilename)
'bgm_play(sfxFolder + windWavFilename, 1)

'img_FadeIn(img, 0, 0)
'sleep(1000)

'img_Scroll(img, 0, 0, 0, -1320)
'sleep

'img = img_Get(imgFolder + outdoorReactorImgFilename)
'img_FadeIn(img, 0, 0)
'bgm_play(bgmFolder + graveReckoningWavFilename)
'sleep(1000)

'img_Scroll(img, 0, 0, 0, -204)
'sleep(500)

'img = img_Get(imgFolder + makoReactor01ImgFilename)
'img_FadeIn(img, 0, 0)
'sleep(1000)

'img_Scroll(img, 0, 0, 0, -840)
'sleep(500)

'img = img_Get(imgFolder + makoReactor02ImgFilename)
'img_FadeIn(img, 0, 0)
'sleep(1000)

'img_Scroll(img, 0, 0, 0, -360)
'sleep(500)

'img = img_Get(imgFolder + oldReactorImgFilename)
'img_FadeIn(img, 0, -778)
'sleep(1000)

'img_Scroll(img, 0, -778, 0, 778)
'sleep

'bgm_play(sfxFolder + rainforestWavFilename, 1)
'img = img_Get(imgFolder + newMidgarImgFilename)
'img_FadeIn(img, 0, 0)
'sleep(3000)

'fgImg = img_Get(imgFolder + ff7SimpleLogoImgFilename)
'img_FadeIn(fgImg, 0, 0)

'bgm_play(bgmFolder + aerithMidFilename)

'imageDestroy img
'imageDestroy fgImg
'End