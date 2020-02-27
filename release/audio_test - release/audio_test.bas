#include once "support\img_support.bas"
#include once "support\screen_support.bas"
#include once "support\audio_support.bas"

dim shared as integer sWidth, sHeight, sFullScreen

sWidth = 1920
sHeight = 1080
sFullScreen = 1

const as string imgFolder = "img/"
const as string bgmFolder = "bgm/"
const as string sfxFolder = "sfx/"

const as string midgarImgFilename = "Midgar.bmp"
const as string corelPrisonImgFilename = "Corel Prison Tall.bmp"
const as string outdoorReactorImgFilename = "Outdoor Reactor Tall.bmp"
const as string makoReactor01ImgFilename = "Mako Reactor 01 Tall.bmp"
const as string makoReactor02ImgFilename = "Mako Reactor 02 Tall.bmp"
const as string oldReactorImgFilename = "Old Reactor Tall.bmp"
const as string newMidgarImgFilename = "newMidgar.bmp"
const as string ff7SimpleLogoImgFilename = "FF7 Simple Logo.bmp"

const as string introMidFilename = "intro.mid"
const as string aerithMidFilename = "aerith.mid"
const as string graveReckoningWavFilename = "grave-reckoning.wav"
const as string windWavFilename = "wind.wav"
const as string rainforestWavFilename = "rainforest.wav"

dim as any ptr img, fgImg
dim as string filePath

screen_Setup sWidth, sHeight, sFullScreen

img = img_Get(imgFolder + midgarImgFilename)
put(0,0), img, pset
sleep(2000)

bgm_play(bgmFolder + introMidFilename)

img = img_Get(imgFolder + corelPrisonImgFilename)
bgm_play(sfxFolder + windWavFilename, 1)

img_FadeIn(img, 0, 0)
sleep(1000)

img_Scroll(img, 0, 0, 0, -1320)
sleep

img = img_Get(imgFolder + outdoorReactorImgFilename)
img_FadeIn(img, 0, 0)
bgm_play(bgmFolder + graveReckoningWavFilename)
sleep(1000)

img_Scroll(img, 0, 0, 0, -204)
sleep(500)

img = img_Get(imgFolder + makoReactor01ImgFilename)
img_FadeIn(img, 0, 0)
sleep(1000)

img_Scroll(img, 0, 0, 0, -840)
sleep(500)

img = img_Get(imgFolder + makoReactor02ImgFilename)
img_FadeIn(img, 0, 0)
sleep(1000)

img_Scroll(img, 0, 0, 0, -360)
sleep(500)

img = img_Get(imgFolder + oldReactorImgFilename)
img_FadeIn(img, 0, -778)
sleep(1000)

img_Scroll(img, 0, -778, 0, 778)
sleep

bgm_play(sfxFolder + rainforestWavFilename, 1)
img = img_Get(imgFolder + newMidgarImgFilename)
img_FadeIn(img, 0, 0)
sleep(3000)

fgImg = img_Get(imgFolder + ff7SimpleLogoImgFilename)
img_FadeIn(fgImg, 0, 0)

bgm_play(bgmFolder + aerithMidFilename)

imageDestroy img
imageDestroy fgImg
End