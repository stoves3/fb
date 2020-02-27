' FBMIDI - MIDI Library for FreeBASIC by oog / Proog.de
'
' A FreeBASIC MIDI Player Library
' load / analyse / playmidi files
' copyright by oog/proog.de 2013-2018
'
' License: LGPL V3
'
'This program is free software: you can redistribute it and/or modify
'    it under the terms of the GNU Lesser Public License as published by
'    the Free Software Foundation, either version 3 of the License, Or
'    (at your option) any later version.
'
'    This program is distributed in the hope that it will be useful,
'    but WITHOUT ANY WARRANTY; without even the implied warranty of
'    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
'    GNU Lesser Public License for more details.
'
'    You should have received a copy of the GNU Lesser Public License
'    along with this program.  If not, see <http://www.gnu.org/licenses/>.
    
    
'first version in 2018 -> 1801
#define FBMIDIVERSION 1801


'---------- play MIDI ----------
'Thanks to Mysoft who explained, how to use MIDI on Windows
'Link : http://www.freebasic.net/forum/viewtopic.php?t=12995
'Title: QB like PLAY plus more...

#include once "windows.bi"
#include once "win/mmsystem.bi"

type MidiMessage field=1 
  Number as UByte
  ParmA as UByte
  ParmB as UByte
  Reserved as UByte
end Type


#define MidiSendMessage(MSGVAR) midiOutShortMsg(MYPLAYDEVICE, *cptr(integer ptr,@MSGVAR))


Type thdChunk
  startAddr    As Integer
  chunkID      As String
  chunkSize    As UInteger
  formatType   As Integer
  numOfTracks  As Integer
  timeDivision As Integer
End Type


Type ttrChunk
  startAddr   As Integer
  chunkID     As String
  chunkSize   As UInteger
End Type


Type ttrInfo
  'track info / analyse
  enabled     As Integer    'if 0, track will not be played
  'string events of the same type will be concatenated, separated by const stringSeparator
  Copyright   As String     'copyright information.
  stName      As String     'Sequence/Track Name
  instrument  As String     'Instrument Name
  lastTicks   As Integer    'ticks counter of last event (~track length)
  seqNumber   As Integer    'Sequence Number, pattern number of a Type 2 MIDI file 
                            'or the number of a sequence in a Type 0 
                            'or Type 1 MIDI file
  loNote      As Integer    'lowest note of track (to scale graphics)
  hiNote      As Integer    'highest note of track (to scale graphics)
  numEvents   As Integer    'count number of all events
  noteEvents  As Integer    'count number of note events
  useChannels As Integer    'bit0 = channel 0, bit15 = channel 15
  textEvents  As Integer    'meta FF01, track notes, comments, etc., usually ASCII
  lyrics      As Integer    'meta FF05, Karaoke, usually a syllable or group of works per quarter note.
  marker      As Integer    'Marker
  cuePoint    As Integer    'Cue Point
  prefix      As Integer    'MIDI Channel Prefix
  port        As Integer    'MIDI Port Select
  endOT       As Integer    'End Of Track
  tempo       As Integer    'Set Tempo
  sOffset     As Integer    'SMPTE Offset
  timeSig     As Integer    'Time Signature
  keySig      As Integer    'Key Signature
  seqSpec     As Integer    'Sequencer Specific
  sysEx       As Integer    'SysEx Event
  unknown     As Integer    'unkwown event
End Type


Enum ParameterType
  noParameter             ' 0: no Parameter
  channel_Para1           ' 1: EvPara1
  channel_Para1_Para2     ' 2: EvPara1, EvPara2
  vString                 ' 3: variable String on heap, evPara1=Heap Pointer
                          '    first byte is counter
  vData                   ' 4: variable data on heap, evPara1=Heap Pointer
                          '    first byte is counter
  bit7FlagData            ' 5: variable data on heap, evPara1=Heap Pointer
                          '    last byte has bit7=1
  vUndefined              ' 6: event code is undefined, so paraType is also
End Enum

Type tEvent
  evDTime As Integer      'time source (relative ticks / Quarternote)
  evTicks As Integer      'sum of ticks from start (absolute)
  evCode As Integer       '0x80-0xFF / 0xFF00-0xFFFF
  evAddr As Integer       'address of event in MIDI file (when load from file)
  setTempo As Integer     'Microseconds/Quarter-Note or 0
  pType As ParameterType  'see enum ParameterType
  evPara1 As Integer      '0x00-0x7F / Heap Pointer
  evPara2 As Integer      '0x00-0x7F / Data Index
  pNext As tEvent Ptr     'chain pointer
  pPrev As tEvent Ptr     'chain pointer
End Type

Type tSequence
  pEvent As tEvent Ptr    'MIDI event
  playTime As Double      'playtime in seconds
  trackIdx As Integer     'track index number (0 = Track 1...)
  pNext As tSequence Ptr  'chain pointer
End Type


Type tEventInfo
  paraType As ParameterType   'see enum ParameterType
  paraName As String          'Parameter Code Name
End Type


'---------- set global tempo ----------
'Set Tempo to default value 120 beats per minute.
'The value is set in Microseconds/Quarter-Note.
'---- Sonic Spot: ----
'The following formula's can be used to translate 
'the tempo from microseconds per quarter-note to 
'beats per minute and back.
'
'MICROSECONDS_PER_MINUTE = 60000000
'BPM = MICROSECONDS_PER_MINUTE / MPQN
'MPQN = MICROSECONDS_PER_MINUTE / BPM
'
#macro setGlobalTempo()
  globalTempo=60000000/120
#endmacro

'---------- Calculate MIDI song tempo ----------
'Global Definition (Header Chunk): 
'globalDivision = n Ticks / qnote (for example 192)
'
'Tempo changes (MIDI event)
'Set Tempo = n µs/MIDI quarter-note (for example 500000)
'
'Count Ticks (dTime) of the MIDI events
'actual qNote position = actualTick / globalDivision
'actual time = actual qNote position * Tempo / 1E6


Type FBMIDI

  Public:
  
  '---------- global declarations ----------
  Const maxCounter=&H100000 'read max 1 MB file size
  Const maxEvents=999999
  Const maxTracks=999
  Const maskEventType       = &Hf0  'hi nibble=event type, lo nibble=channel
  Const evNoteOff           = &H80    'note number    velocity
  Const evNoteOn            = &H90    'note number    velocity
  Const evNoteAftertouch    = &HA0    'note number    aftertouch value
  Const evController        = &HB0    'controller number    controller value
  Const evProgramChange     = &HC0    'program number    not used
  Const evChannelAftertouch = &HD0    'aftertouch value    not used
  Const evPitchBend         = &HE0  'pitch value (LSB)    pitch value (MSB)
  Const maskChannel         = &H0f  'hi nibble=event type, lo nibble=channel
  Const cDrumtrack          = 9     'DrumTrack is channel 9 of 0..15 (or 10 of 1..16)
  Const stringSeparator = "|"
  
  '---------- global variables ----------
  As MidiMessage MidiMsg
  As HMIDIOUT MYPLAYDEVICE     '// MIDI device interface for sending MIDI output
  As String infile, outfile
  As UByte midiDat(maxCounter)
  As Integer addressCounter, filesize, outf
  As UInteger globalNumOfTracks
  As Integer globalFormatType
  As longint globalDivision
  As longint globalTempo
  As Double globalPlaytime
  Const heapMax=999999
  As Integer heap(heapMax)
  As Integer heapPtr
  Const textinfoMax=9999
  As String  textinfo(textinfoMax)
  As Integer textinfoPtr
  As tEvent Ptr track(maxTracks)
  As ttrInfo tInf(maxTracks)
  As tEvent Ptr playEvent(maxTracks)  'cursor to next event of this track
  As Integer trackPtr=1
  As Integer transpose

  '---------- Informations, used by playMidi() ----------
  As String globalInfInfo
  As String globalInfTitle

  '---------- Lyrics string array ----------
  Const maxLyrics=999
  As String lyrics(maxLyrics)
  As tSequence Ptr lyricsStartEvent(maxLyrics)
  As Integer lyricsCount

  ' variables for analyseKaraoke()
  As Integer globalKaraokeWordsTrack
  As Integer globalKaraokeTypeTrack
  As Integer globalKaraokeType
  As Integer globalLyricsTrack
  As Integer globalTextIsLyrics
  ' variables for playMidiEvent()
  As Integer cursX, cursY
  ' variables for playMidi()
  As tSequence Ptr nextSeq
  As Integer nextEvent
  As tEvent Ptr thisEvent
  As Double startTime
  As Double lastTime
  As tSequence Ptr seq
  '
  Declare Function setup() As Integer
  Declare Sub loadFile(fName As String)
  Declare Function intLeft(n As Integer, size As Integer) As String
  Declare Sub pr(s As String="")
  Declare Function nextByte() As UInteger
  Declare Function headerStr() As String
  Declare Function getTime() As String
  Declare Function num4() As UInteger
  Declare Function num2() As UInteger
  Declare Function getTrackChunk() As ttrChunk
  Declare Function getHeaderChunk() As thdChunk
  Declare Function vNum() As UInteger
  Declare Function eventInfo(eventCode As Integer) As tEventInfo
  Declare Sub readEventData(event As tEvent Ptr)
  Declare Function getEvPara(event As tEvent Ptr) As String
  Declare Function getEvString(event As tEvent Ptr) As String
  Declare Function isPlayable(eventCode As Integer) As Integer
  Declare Sub readTrackEvents(trkNum As Integer, trk As tEvent Ptr, startPos As Integer, endPos As Integer)
  Declare Sub readTrackChunk(trk As Integer)
  Declare Sub readHeaderChunk()
  Declare Function readMidi() As Integer
  Declare Sub retimeTrack()
  Declare Sub analyseLyrics()
  Declare Function isEndOfTrack(ev As tEvent Ptr) As Integer
  Declare Sub buildSequence()
  Declare Sub initLoop(songposition As Double)
  Declare Sub AllNotesOff()
  Declare Function getLyricsElement(nextSeq As tSequence Ptr, setGlob As Integer) As String
  Declare Sub readLyrics()
  Declare Sub saveEnergy()
  Declare Sub playMidiEvent(nextSeq As tSequence Ptr)
  Declare Function isEndOfMusic() As Integer
  Declare Sub windTo(songposition As Double)
  Declare Sub playLoop()
  Declare Sub deleteOldSong()
  Private:
End Type


'---------- load file into midiDat() array ----------
' 
Sub FBMIDI.loadFile(fName As String)
  erase(midiDat)

  var filenum = FreeFile()
  If Open(fName For Binary Access Read As #filenum )=0 Then
    While Not EOF(filenum)
      Get #filenum, , midiDat(filesize)
      filesize += 1
      If filesize>maxCounter Then
        Print "File too long error."
        End
      EndIf
    Wend
    Close #filenum
  EndIf
End Sub


'---------- setup MIDI interface ----------
' 
Function FBMIDI.setup() As Integer
  Return midiOutOpen(@MYPLAYDEVICE, MIDI_MAPPER, 0, 0, null)
End Function


'---------- string function - intLeft ----------
'format decimal number, add spaces to reach 'size'
Function FBMIDI.intLeft(n As Integer, size As Integer) As String
Dim As String r
  r=Str(n)
  If Len(r) < size Then
    r=Left(r+Space(size),size)
  EndIf
  Return r
End Function


'---------- get next byte ----------
Function FBMIDI.nextByte() As UInteger
Dim As UByte d
  d=midiDat(addressCounter)
  addressCounter+=1
  Return d
End Function


'---------- get next 4 character string ----------
' chunk ID
Function FBMIDI.headerStr() As String
Dim As String r
  For i As Integer= 1 To 4
    r += Chr(nextByte)
  Next i
  Return r
End Function


'---------- get next n byte v_time value ----------
' add lower 7 bits in a loop
' last byte ist marked with bit7=0
' maximum possible value is signed 16 bit
' 
Function FBMIDI.getTime() As String
Dim As UInteger t, d
Dim As String s
  d=nextByte
  s=Hex(d,2)
  t+=d And 127
  While (d And 128) > 0
    t=t Shl 7
    d=nextByte
    s+=" "+Hex(d,2)
    t+=d And 127
  Wend
  Return s+" = "+Str(t)+" Ticks"
End Function


'---------- get next 4 byte number ----------
Function FBMIDI.num4() As UInteger
  Return (nextByte Shl 24) _
       + (nextByte Shl 16) _
       + (nextByte Shl 8) _
       + (nextByte)
End Function


'---------- get next 2 byte number ----------
Function FBMIDI.num2() As UInteger
  Return (nextByte Shl 8) _
       + (nextByte)
End Function


'---------- get next track chunk ----------
Function FBMIDI.getTrackChunk() As ttrChunk
Dim As ttrChunk trChunk
  trChunk.startAddr    =addressCounter
  trChunk.chunkID      =headerStr
  trChunk.chunkSize    =num4
  addressCounter=trChunk.startAddr+trChunk.chunkSize+8
  Return trChunk
End Function


'---------- get next header chunk ----------
' a header chunk is the first chunk in the MIDI file
' set global variables:
'   UInteger chunkNumOfTracks
'   Integer chunkDivision
Function FBMIDI.getHeaderChunk() As thdChunk
Dim As thdChunk hdChunk
  hdChunk.startAddr    =addressCounter
  hdChunk.chunkID      =headerStr
  hdChunk.chunkSize    =num4
  hdChunk.formatType   =num2
  hdChunk.numOfTracks  =num2
  hdChunk.timeDivision =num2
  Return hdChunk
End Function


'---------- sequencer ----------

'---------- get next variable size number (vtime) ----------
Function FBMIDI.vNum() As UInteger
Dim As UInteger n, d
  d=nextByte
  n+=(d And 127)
  While (d And 128) = 128
    n=n Shl 7
    d=nextByte
    n+=(d And 127)
  Wend
  Return n
End Function


'---------- get infos about a MIDI event ----------
' 
Function FBMIDI.eventInfo(eventCode As Integer) As tEventInfo
Dim As tEventInfo r
  '1 - define parameter type (pType)
  Select Case eventCode
    Case &H80 to &H8F:  'Note Off
      'r.paraName="Note Off"
      r.paraName="NoteOff"
      r.paraType = channel_Para1_Para2
    Case &H90 to &H9F:  'Note On
      'r.paraName="Note On"
      r.paraName="NoteOn"
      r.paraType = channel_Para1_Para2
    Case &HA0 to &HAF:  'Polyphonic Key Pressure (Aftertouch)
      'r.paraName="Polyphonic Key Pressure (Aftertouch)"
      r.paraName="PolyPress"
      r.paraType = channel_Para1_Para2
    Case &HB0 to &HBF:  'Controller / Channel Mode Messages
      'r.paraName="Controller / Channel Mode Messages"
      r.paraName="Controller"
      r.paraType = channel_Para1_Para2
    Case &HC0 to &HCF:  'Program Change
      'r.paraName="Program Change"
      r.paraName="ProgChange"
      r.paraType = channel_Para1
    Case &HD0 to &HDF:  'Channel Pressure (Aftertouch)
      'r.paraName="Channel Pressure (Aftertouch)"
      r.paraName="ChanPress"
      r.paraType = channel_Para1
    Case &HE0 to &HEF:  'Pitch Bend
      'r.paraName="Pitch Bend"
      r.paraName="PitchBend"
      r.paraType = channel_Para1_Para2
    'System Common Messages
    Case &HF0:      'System Exclusive
      'r.paraName="System Exclusive"
      r.paraName="SysEx"
      r.paraType = vData
    Case &HF1:      'MIDI Time Code Quarter Frame (0nnndddd )
      'r.paraName="MIDI Time Code Quarter Frame"
      r.paraName="TCQF"
      r.paraType = channel_Para1
    Case &HF2:      'Song Position Pointer
      'r.paraName="Song Position Pointer"
      r.paraName="SongPosPt"
      r.paraType = channel_Para1_Para2
    Case &HF3:      'Song Select (0.127)
      'r.paraName="Song Select"
      r.paraName="SongSelect"
      r.paraType = channel_Para1
    Case &HF6:      'Tune Request
      'r.paraName="Tune Request"
      r.paraName="TuneReqest"
      r.paraType = noParameter
    Case &HF7:      'End of System Exclusive (EOX)
      'r.paraName="End of System Exclusive (EOX)"
      r.paraName="EOX"
      r.paraType = noParameter
    'System Real Time Messages - Don't expect in a MIDI file
    Case &HF8:      'Timing Clock
      'r.paraName="Timing Clock"
      r.paraName="TimingClock"
      r.paraType = noParameter
    Case &HFA:      'Start
      'r.paraName="Start"
      r.paraName="Start"
      r.paraType = noParameter
    Case &HFB:      'Continue
      'r.paraName="Continue"
      r.paraName="Continue"
      r.paraType = noParameter
    Case &HFC:      'Stop
      'r.paraName="Stop"
      r.paraName="Stop"
      r.paraType = noParameter
    Case &HFE:      'Active Sensing
      'r.paraName="Active Sensing"
      r.paraName="ActiveSens"
      r.paraType = noParameter
    Case &HFF:      'System Reset
      'r.paraName="System Reset"
      r.paraName="SystemReset"
      r.paraType = noParameter
    'Meta Events
    Case &HFF00:    'Sequence Number
      'Sequence Number - pattern number of a Type 2 MIDI file 
      'or the number of a sequence in a Type 0 or Type 1 MIDI file
      'r.paraName="Sequence Number"
      r.paraName="SeqNumber"
      r.paraType = channel_Para1_Para2
    Case &HFF01:    'Text Event
      'r.paraName="Text Event"
      r.paraName="Text"
      r.paraType = vString
    Case &HFF02:    'Copyright Notice
      'r.paraName="Copyright Notice"
      r.paraName="Copyright"
      r.paraType = vString
    Case &HFF03:    'Sequence/Track Name
      'r.paraName="Sequence/Track Name"
      r.paraName="Trackname"
      r.paraType = vString
    Case &HFF04:    'Instrument Name
      'r.paraName="Instrument Name"
      r.paraName="Instrument"
      r.paraType = vString
    Case &HFF05:    'Lyrics
      'r.paraName="Lyrics"
      r.paraName="Lyrics"
      r.paraType = vString
    Case &HFF06:    'Marker
      'r.paraName="Marker"
      r.paraName="Marker"
      r.paraType = vString
    Case &HFF07:    'Cue Point
      'r.paraName="Cue Point"
      r.paraName="CuePoint"
      r.paraType = vString
    Case &HFF20:    'MIDI Channel Prefix - associate channel with next meta events
      'r.paraName="MIDI Channel Prefix (obsolete)"
      r.paraName="ChannelPrefix"
      r.paraType = vData
    Case &HFF21:    'MIDI Port
      'r.paraName="MIDI Port (obsolete)"
      r.paraName="MIDIPort"
      r.paraType = vData
    Case &HFF2F:    'End Of Track
      'r.paraName="End Of Track"
      r.paraName="EndOfTrack"
      r.paraType = vData
    Case &HFF51:    'Set Tempo
      'r.paraName="Set Tempo"
      r.paraName="SetTempo"
      r.paraType = vData
    Case &HFF54:    '
      'r.paraName="SMPTE Offset"
      r.paraName="SMPTEOffset"
      r.paraType = vData
    Case &HFF58:    '
      'r.paraName="Time Signature"
      r.paraName="TimeSignature"
      r.paraType = vData
    Case &HFF59:    '
      'r.paraName="Key Signature"
      r.paraName="KeySignature"
      r.paraType = vData
    Case &HFF7F:    '
      'r.paraName="Sequencer Specific"
      r.paraName="Sequencer"
      r.paraType = vData
    Case Else:    '
      'r.paraName="Undefined"
      r.paraName="Undefined"
      r.paraType = vUndefined
  End Select
  Return r
End Function


'---------- read event data ----------
' 
Sub FBMIDI.readEventData(event As tEvent Ptr)
Dim As UByte b
Dim As Integer d
  '1 - define parameter type (pType)
  event->pType = eventInfo(event->evCode).paraType
  '2 - read parameters
  Select Case event->pType
    Case noParameter:
      'no Parameter
      '- nothing to do
    Case channel_Para1:
      'EvPara1
      event->evPara1=nextByte
    Case channel_Para1_Para2:
      'EvPara1, EvPara2
      event->evPara1=nextByte
      event->evPara2=nextByte
    Case vString:
      'variable String on heap, evPara1=Heap Pointer
      'first byte is counter
      d=nextByte
      event->evPara2=textinfoPtr
      For i As Integer=1 To d
        textinfo(textinfoPtr)+=Chr(nextByte)
      Next i
      textinfoPtr+=1
    Case vData:
      'variable data on heap, evPara1=Heap Pointer
      'first byte is counter
      d=nextByte
      event->evPara2=heapPtr
      heap(heapPtr)=d       'size counter byte
      heapPtr+=1
      For i As Integer=1 To d
        heap(heapPtr)=nextByte
        heapPtr+=1
      Next i
      'if event is "Set Tempo" then store tempo change
      If event->evCode = &HFF51 Then 
        event->setTempo=(heap(heapPtr-3)Shl 16)_
          +(heap(heapPtr-2)Shl 8)+heap(heapPtr-1)
      EndIf
    Case bit7FlagData:
      'variable data on heap, evPara1=Heap Pointer
      'last byte has bit7=1
      event->evPara2=heapPtr
      Do
        b=nextByte
        heap(heapPtr)=b
        heapPtr+=1
      Loop Until ((b And 128) = 128)
  End Select
End Sub


'---------- get event parameter as string ----------
' 
Function FBMIDI.getEvPara(event As tEvent Ptr) As String
Dim As UByte b
Dim As Integer d
Dim As String s
  Select Case event->pType
    Case noParameter:
      'no Parameter
      '- nothing to do
      s="--"
    Case channel_Para1:
      'EvPara1
      s=Hex(event->evCode,1)+" "+Hex(event->evPara1,2)
    Case channel_Para1_Para2:
      'EvPara1, EvPara2
      s=Hex(event->evCode,1)+" "+Hex(event->evPara1,2)+" "+Hex(event->evPara2,2)
    Case vString:
      'variable String on heap, evPara1=Heap Pointer
      'first byte is counter
      s=Chr(34)+textinfo(event->evPara2)+Chr(34)
    Case vData:
      'variable data on heap, evPara1=Heap Pointer
      'first byte is counter
      d=event->evPara2
      s="["+Hex(heap(d))+"]"
      For i As Integer=1 To heap(d)
        s+=" "+Hex(heap(event->evPara2+i),2)
      Next i
    Case bit7FlagData:
      'variable data on heap, evPara1=Heap Pointer
      'last byte has bit7=1
      d=event->evPara2
      Do
        b=heap(d)
        d+=1
        s+=Hex(b,2)+" "
      Loop Until ((b And 128) = 128)
  End Select
  Return s
End Function


'---------- get event string-parameter without string delimiters "" ----------
' 
Function FBMIDI.getEvString(event As tEvent Ptr) As String
Dim As UByte b
Dim As Integer d
Dim As String s
  s=""
  Select Case event->pType
    Case vString:
      'variable String on heap, evPara1=Heap Pointer
      'first byte is counter
      s=textinfo(event->evPara2)
  End Select
  Return s
End Function


'---------- MIDI event is playable (note on, off...) ----------
' 
Function FBMIDI.isPlayable(eventCode As Integer) As Integer
Dim r As Integer = 0
  '1 - define parameter type (pType)
  Select Case eventCode
    Case &H80 to &HEF:
      r=-1
  End Select
  Return r
End Function


'---------- read all events in a chunk ----------
' 
Sub FBMIDI.readTrackEvents(trkNum As Integer, trk As tEvent Ptr, startPos As Integer, endPos As Integer)
Dim As tEvent Ptr actEvent
Dim As tEvent Ptr newEvent
Dim As UInteger eventDTime
Dim As UInteger eventCode, runningStatus
Dim As Integer eventAddress
Dim As String s
  addressCounter=startPos
  actEvent=trk
  While addressCounter<endPos
    eventDTime=vNum
    eventAddress=addressCounter
    eventCode=nextByte
    If eventCode=&HFF Then eventCode=&HFF00 Or nextByte
    'Running Status is a data-thinning technique. 
    'It allows for the omision of status bytes if the current 
    'message to be transmitted has the same status byte 
    '(ie the same command and MIDI channel) as the previous 
    'message. It thus only applies to Channel (Voice and Mode) 
    'messages (0x8n - 0xEn).
    'allow "runnung status" repeat codes
    If (eventCode And &HFF80)=0 Then
      addressCounter-=1
      If runningStatus<>0 Then
        eventCode=runningStatus       'save the running status
      Else
        Print
        Print("ERROR: Running Status is zero at @"+Hex(addressCounter))
      EndIf
    EndIf
    newEvent=new tEvent
    newEvent->pNext=0
    newEvent->pPrev=actEvent
    actEvent->pNext=newEvent
    actEvent=newEvent
    newEvent->evDTime=eventDTime
    newEvent->evCode=eventCode
    newEvent->evAddr=eventAddress
    readEventData(newEvent)
    tInf(trackPtr).enabled=1      'track is enabled by default
    'track info / analyse
    If isPlayable(eventCode) Then
      runningStatus=eventCode       'save the running status
      tInf(trackPtr).noteEvents += 1    'count number of note events
      var ch=1 Shl(eventCode And maskChannel) 'bit0 = channel 0, bit15 = channel 15
      tInf(trackPtr).useChannels = tInf(trackPtr).useChannels Or ch
      If (eventCode And maskEventType) = evNoteOn Then
        'store first note as lowest and highest note
        If tInf(trackPtr).hiNote<0 Then
          tInf(trackPtr).loNote=newEvent->evPara1
          tInf(trackPtr).hiNote=newEvent->evPara1
        Else
          If newEvent->evPara1 < tInf(trackPtr).loNote Then
            tInf(trackPtr).loNote=newEvent->evPara1
          ElseIf newEvent->evPara1 > tInf(trackPtr).hiNote Then
            tInf(trackPtr).hiNote=newEvent->evPara1
          EndIf
        EndIf
      EndIf
    Else
      Select Case eventCode
        Case &H00F0:    'SysEx Event
          tInf(trackPtr).sysEx+=1       'count events
          runningStatus=0               'clear the running status
        Case &H00F0 To &H00F7: 'System Common and System Exclusive messages
          runningStatus=0               'clear the running status
        Case &HFF00:    'Sequence Number
          tInf(trackPtr).seqNumber=newEvent->evPara1 Shl 8 + newEvent->evPara2
        Case &HFF01:    'Text Event: track notes, comments...
          tInf(trackPtr).textEvents+=1  'count events
        Case &HFF02:    'Copyright Notice
          If tInf(trackPtr).Copyright<>"" Then tInf(trackPtr).Copyright += stringSeparator
          tInf(trackPtr).Copyright+=textinfo(newEvent->evPara2)
        Case &HFF03:    'Sequence/Track Name
          If tInf(trackPtr).stName<>"" Then tInf(trackPtr).stName += stringSeparator
          tInf(trackPtr).stName+=textinfo(newEvent->evPara2)
        Case &HFF04:    'Instrument Name
          If tInf(trackPtr).instrument<>"" Then tInf(trackPtr).instrument += stringSeparator
          tInf(trackPtr).instrument+=textinfo(newEvent->evPara2)
        Case &HFF05:    'Karaoke, usually a syllable or group of works per quarter note.
          tInf(trackPtr).lyrics+=1    'count events
        Case &HFF06:    'Marker
          tInf(trackPtr).marker+=1    'count events
        Case &HFF07:    'Cue Point
          tInf(trackPtr).cuePoint+=1  'count events
        Case &HFF20:    'MIDI Channel Prefix
          tInf(trackPtr).prefix+=1    'count events
        Case &HFF21:    'MIDI Port
          tInf(trackPtr).port+=1      'count events
        Case &HFF2F:    'End Of Track
          tInf(trackPtr).endOT+=1     'count events
        Case &HFF51:    'Set Tempo
          tInf(trackPtr).tempo+=1     'count events
        Case &HFF54:    'SMPTE Offset
          tInf(trackPtr).sOffset+=1   'count events
        Case &HFF58:    'Time Signature
          tInf(trackPtr).timeSig+=1   'count events
        Case &HFF59:    'Key Signature
          tInf(trackPtr).keySig+=1    'count events
        Case &HFF7F:    'Sequencer Specific
          tInf(trackPtr).seqSpec+=1   'count events
        Case Else:
          tInf(trackPtr).unknown+=1   'count events
      End Select
    EndIf
    tInf(trackPtr).numEvents += 1       'count number of all events
  Wend
End Sub


'---------- track chunk ----------
Sub FBMIDI.readTrackChunk(trk As Integer)
Dim As tEvent Ptr newEvent
Dim As ttrChunk trChunk
  trChunk=getTrackChunk
  If (trChunk.chunkID <> "MTrk") Then
    Print ("ERROR - invalid Track Chunk "+Str(trk)+":"+trChunk.chunkID)
    'End
  EndIf
  newEvent=new tEvent
  track(trackPtr)=newEvent
  If trackPtr>maxTracks Then
    Print "ERROR: Too much tracks"
    Sleep 
    End
  EndIf
  newEvent->pPrev=0
  newEvent->pNext=0
  newEvent->evCode=-1   'track start
  readTrackEvents(trk, newEvent, trChunk.startAddr+8, trChunk.startAddr+trChunk.chunkSize+7)
  trackPtr+=1
End Sub


'---------- header chunk ----------
Sub FBMIDI.readHeaderChunk()
Dim As thdChunk hdChunk
  hdChunk=getHeaderChunk
  globalFormatType=hdChunk.formatType
  globalNumOfTracks=hdChunk.numOfTracks
  globalDivision=hdChunk.timeDivision
  If (globalDivision And &H8000) <> 0 Then
    Print 
    Print ("time division="+Str(globalDivision And &H7FFF)+" frames per second")
    Print ("ERROR - Format not supported")
  EndIf
  If (hdChunk.chunkID <> "MThd") OrElse (hdChunk.formatType>2) Then
    Print
    Print ("ERROR - invalid Header Chunk")
    'End
  EndIf
End Sub


'---------- read file from midiDat() array into sequencer ----------
' 
Function FBMIDI.readMidi() As Integer
  addressCounter=0
  readHeaderChunk()
  For t As Integer=1 To globalNumOfTracks
    readTrackChunk(t)
  Next t
  'prepare midi sequence for playing
  If trackPtr>1 Then
    retimeTrack()
    initLoop(0)
  EndIf
  Return trackPtr
End Function


'---------- retime midi tracks ----------
'
'calculate absolute tick counter for every event
'from the relative counter dTime
'Call this Sub
' - after song loading and
' - after track-editing
' 
Sub FBMIDI.retimeTrack()
Dim As Integer ticksCounter
Dim As tEvent Ptr thisEvent
Dim As String s
  For t As Integer=1 To trackPtr-1
    ticksCounter=0
    thisEvent=track(t)
    While thisEvent<>0
      ticksCounter+=thisEvent->evDTime
      thisEvent->evTicks=ticksCounter
      thisEvent = thisEvent->pNext
    Wend
    'store track lenght (ticksCounter of last event)
    tInf(t).lastTicks=ticksCounter
  Next t
End Sub


'---------- Find out if midi file contains karaoke lyrics ----------
' set globalKaraokeType to 1/2 if format 1/2 has been detected
' set globalKaraokeTypeTrack to the track number with lyrics
' Detect 2 formats
' Format 1: Soft karaoke / WinKaraoke Creator
' Format 2: KarMaker
'
Sub FBMIDI.analyseLyrics()
Dim As tEvent Ptr thisEvent
Dim As String s
  For t As Integer=1 To trackPtr-1
    'Find "Words" Track
    if (tInf(t).stName = "Words") Then globalKaraokeWordsTrack=t
    'Find Track with most lyrics events
    If tInf(t).lyrics>0 Then
      If globalLyricsTrack=0 Then
        globalLyricsTrack=t
        globalTextIsLyrics=(1=1)
      Else
        If tInf(globalLyricsTrack).lyrics < tInf(t).lyrics Then
          globalLyricsTrack=t
        EndIf
      EndIf
    EndIf
    'Karaoke Format 1: Soft karaoke / WinKaraoke Creator
    If (LCase(tInf(t).stName) = "soft karaoke") Then
      globalKaraokeTypeTrack=t
      globalKaraokeType=1
    EndIf
    'Karaoke Format 2: KarMaker
    If (LCase(Left(tInf(t).stName,12)) = "(c) karmaker") Then
      globalKaraokeTypeTrack=t
      globalKaraokeType=2
    EndIf
  Next t
End Sub


'---------- detect end of track by event code or zero pointer ----------
' 
Function FBMIDI.isEndOfTrack(ev As tEvent Ptr) As Integer
  If (ev=0) OrElse (ev->evCode=&hFF2F) Then
    Return -1
  Else
    Return 0
  EndIf
End Function


'---------- build sequence "seq" ----------
' 
Sub FBMIDI.buildSequence()
Dim As Integer nextEvent
Dim As tEvent Ptr thisEvent
Dim As tSequence Ptr nextSeq
Dim As Double playTime
Dim As Double lastTime
Dim As Integer lastTicks

  nextSeq = 0
  setGlobalTempo()  ' set to default value
  While seq<>0
    var cleanup=seq
    seq=seq->pNext
    DELETE cleanup
  Wend
  seq=new tSequence
  nextSeq=seq
  'set playCursors to track start (get first event with pNext)
  For t As Integer=1 To trackPtr-1
    playEvent(t)=track(t)->pNext  '->pNext, because first element is dummy
  Next t
  playTime=0
  lastTime=0
  lastTicks=0
  Do
    'search all tracks for next to play event (time)
    For t As Integer=1 To trackPtr-1
      '1) set nextEvent to a valid track
      If isEndOfTrack(playEvent(nextEvent))_
      AndAlso Not(isEndOfTrack(playEvent(t))) Then
        nextEvent=t
      EndIf
      '2) set what track has the next event in time
      '   but ignore "end of track" event
      If (playEvent(t)<>0)_
      AndAlso (playEvent(t)->evCode <>&HFF2F) _
      AndAlso (playEvent(t)->evTicks <= playEvent(nextEvent)->evTicks) Then
        nextEvent=t
      EndIf
    Next t
    'store next event in sequence
    nextSeq->trackIdx = nextEvent
    nextSeq->pEvent   = playEvent(nextEvent)
    nextSeq->pnext    = new tSequence
    'calculate playtime of actual MIDI event
    playTime=lastTime+(nextSeq->pEvent->evTicks-lastTicks)*globalTempo _
            /globalDivision /1e6
    nextSeq->playTime = playTime
    If playTime>globalPlaytime Then globalPlaytime=playTime
    'if tempo changes -> set new tempo
    If nextSeq->pEvent->setTempo>0 Then
      'MICROSECONDS_PER_MINUTE = 60000000
      'BPM = MICROSECONDS_PER_MINUTE / MPQN
      'MPQN = MICROSECONDS_PER_MINUTE / BPM
      globalTempo=nextSeq->pEvent->setTempo
      lastTicks=nextSeq->pEvent->evTicks
      lastTime=playTime
    EndIf
'    var qNote=nextSeq->pEvent->evTicks / globalDivision
    nextSeq=nextSeq->pnext
    If playEvent(nextEvent)<>0 Then playEvent(nextEvent)=playEvent(nextEvent)->pNext
  Loop Until playEvent(nextEvent)=0
End Sub


'---------- init sequence, prepare for playing loop ----------
' 
Sub FBMIDI.initLoop(songposition As Double)
  nextSeq=seq
  startTime=Timer - songposition
  lastTime=startTime
End Sub


'---------- send "All Notes Off" to all channels ----------
' 
Sub FBMIDI.AllNotesOff()
  MidiMsg.ParmA  = 123    'All Notes Off
  MidiMsg.ParmB  = 0      'All Notes Off
  For i As Integer=0 To 15
    MidiMsg.Number = evController Or i
    MidiSendMessage(MidiMsg)
  Next i
End Sub


'---------- get next line of lyrics from "seq" ----------
' 
Function FBMIDI.getLyricsElement(nextSeq As tSequence Ptr, setGlob As Integer) As String
Dim As String txt
  If (nextSeq <> 0)_
  AndAlso (nextSeq->pEvent <> 0) Then
    If globalTextIsLyrics Then
      If (nextSeq->pEvent->evCode=&HFF05) Then
        txt=getEvString(nextSeq->pEvent)
        If txt<" " Then txt="/"
      EndIf
    Else
      If (nextSeq->pEvent->evCode=&HFF01) Then
        txt=getEvString(nextSeq->pEvent)
        var infoType=Left(txt,2)
        var infoTxt=Right(txt,Len(txt)-2)
        Select Case infoType
          Case "@I":  'Information
            txt=""
            If setGlob Then globalInfInfo+=Chr(13,10)+"  "+infoTxt
          Case "@T":  'Title
            txt=""
            If setGlob Then globalInfTitle+=Chr(13,10)+"  "+infoTxt
          Case "@K":  'ignore (Karaoke Type Info)
            txt=""
          Case "@L":  'ignore (Karaoke Lyrics Language)
            txt=""
          Case "@V":  'ignore (Karaoke File Version)
            txt=""
        End Select
      EndIf
    EndIf
  EndIf
  'Handle KarMaker vocal strings
  '(they might include 0x00 and some additional codes)
  If InStr(txt,Chr(0)) Then
    txt=Left(txt,InStr(txt,Chr(0))-1)
  EndIf
  Return txt
End Function


'---------- read Lyrics into string array ----------
' read lyrics from sequence "seq"
'
Sub FBMIDI.readLyrics()
  nextSeq=seq
  Do
    'wait until next event has to be played
    If nextSeq<>0 _
    AndAlso (nextSeq->pEvent<>0) Then
      var txt=getLyricsElement(nextSeq, 1)
      Select Case Left(txt,1)
        Case "/","\":
          lyricsCount += 1
          lyricsStartEvent(lyricsCount) = nextSeq
          txt=Right(txt,Len(txt)-1)
      End Select
      'print lyrics
      If txt<>"" Then
        lyrics(lyricsCount) += txt
      EndIf
      nextSeq=nextSeq->pNext
    EndIf
    If lyricsCount>=maxLyrics Then
      Print "ERROR: too much lyrics lines"
      End
    EndIf
  Loop Until (nextSeq=0) OrElse (nextSeq->pEvent=0)
  If globalInfTitle="" Then globalInfTitle="- not defined -"
  If globalInfInfo="" Then globalInfInfo="- not defined -"
End Sub


'---------- save energy, sleep while nothing to play ----------
' 
Sub FBMIDI.saveEnergy()
  'wait for next event to be played
  'but no longer than 20 ms to prevent blocking user interface
  If nextSeq<>0 _
  AndAlso (nextSeq->pEvent<>0) Then
    If nextSeq->playTime - (Timer-lastTime) > 0.025 Then
      Sleep 20
    Else
      While nextSeq->playTime > (Timer-lastTime)
        Sleep 1
      Wend
    EndIf
  EndIf
End Sub


'---------- play MIDI file (with karaoke text) from "seq" ----------
' 
'Dim Shared As Integer cursX, cursY

Sub FBMIDI.playMidiEvent(nextSeq As tSequence Ptr)
  'play next MIDI event
  'if tempo changes -> set new tempo
  If nextSeq->pEvent->setTempo>0 Then
    globalTempo=nextSeq->pEvent->setTempo
  EndIf
  'play note, if channel is enabled
  If tInf(nextSeq->trackIdx).enabled _
  AndAlso isPlayable(nextSeq->pEvent->evCode) Then
    MidiMsg.Number = nextSeq->pEvent->evCode
    MidiMsg.ParmA  = nextSeq->pEvent->evPara1
    MidiMsg.ParmB  = nextSeq->pEvent->evPara2
    'transpose note, but leave drums untouched
    If (MidiMsg.Number And maskChannel) = cDrumtrack Then
      'drums
      MidiSendMessage(MidiMsg)
    Else
      'transpose other instruments
      MidiMsg.ParmA+=transpose
      'play if notes are in a valid range
      If (MidiMsg.ParmA>=0) AndAlso (MidiMsg.ParmA<=127) Then
        'play NoteOn
        MidiSendMessage(MidiMsg)
      EndIf
    EndIf
  EndIf
End Sub


'---------- check if no more to play ----------
' 
Function FBMIDI.isEndOfMusic() As Integer
  Return (nextSeq=0) OrElse (nextSeq->pEvent=0)
End Function


'---------- play next MIDI event from "seq" in a loop ----------
' 
Sub FBMIDI.windTo(songposition As Double)
  initLoop(songposition)
  If songposition>0 Then
    'search for event to be played
    While nextSeq->playTime <= songposition'(startTime+songposition)
      If (nextSeq=0) _
      OrElse (nextSeq->pEvent=0) Then Exit While
      nextSeq=nextSeq->pNext
    Wend
  EndIf
End Sub


'---------- play next MIDI event from "seq" in a loop ----------
' 
Sub FBMIDI.playLoop()
  'wait until next event has to be played
  While nextSeq->playTime <= (Timer-lastTime)
    If (nextSeq=0) _
    OrElse (nextSeq->pEvent=0) Then Exit While
    'play next MIDI event
    playMidiEvent(nextSeq)
    nextSeq=nextSeq->pNext
  Wend
End Sub


'---------- delete infos from last song ----------
' 
Sub FBMIDI.deleteOldSong()
  addressCounter=0
  heapPtr=0
  trackPtr=1
  transpose=0
  filesize=0
  For i As Integer=0 To textinfoPtr
    textinfo(i)=""
  next i
  textinfoPtr=0
  For i As Integer=0 To lyricsCount
    lyrics(i)=""
  next i
  lyricsCount=0
  globalInfInfo=""
  globalInfTitle=""
End Sub