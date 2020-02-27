#include once "fbmidi.bi"
#include once "windows.bi"
#include once "win\mmsystem.bi"

const midiSkipKey as string = chr(27)

declare function bgm_play(filename as string, loopEnabled as integer = 0) as string
declare sub bgm_stop()

declare function bgm_playWav(filename as string, loopEnabled as integer = 0) as string
declare sub bgm_stopWav()

declare sub bgm_init()
declare function bgm_playMid(filename as string) as string

dim shared as FBMIDI midi
dim shared as integer initComplete = 0

function bgm_play(filename as string, loopEnabled as integer = 0) as string
    dim as string fileExt
    
    fileExt = right(filename,3)
    
    if (fileExt = "wav") then return bgm_playWav(filename, loopEnabled)
    
    if (fileExt = "mid") then return bgm_playMid(filename)
    
    return ""    
end function

function bgm_playWav(filename as string, loopEnabled as integer = 0) as string
    if (loopEnabled = 1) then 
        sndPlaySound(filename,SND_ASYNC or SND_LOOP)
    else
        sndPlaySound(filename,SND_ASYNC)
    end if
    
    return ""
end function

sub bgm_stop()
    bgm_stopWav
end sub

sub bgm_stopWav()
    'sndPlaySound(NULL,SND_ASYNC)
    sndPlaySound(0,0)
end sub

sub bgm_init()    
    if (initComplete = 1) then return
    
    if (midi.setup() <> MMSYSERR_NOERROR) then return
    initComplete = 1    
end sub

function bgm_playMid(filename as string) as string
    dim as string keyPress = ""
    
    bgm_init
    'if (midi.setup() <> MMSYSERR_NOERROR) then return keyPress
    'midi.setup()
    midi.loadFile(filename)
    midi.readMidi()
    'if (midi.readMidi() <=1) then return keyPress
    
    midi.buildSequence()
    midi.windTo(0)
    Do
        midi.saveEnergy()
        keyPress = Inkey
        midi.playLoop()
    Loop Until midi.isEndOfMusic orelse keyPress = midiSkipKey
    
    midi.AllNotesOff
    midi.buildSequence()
    midi.windTo(0)    
    midi.deleteOldSong
end function