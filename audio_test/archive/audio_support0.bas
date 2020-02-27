#include once "midisynth.bi"
#include once "instruments.bi"
#include once "alsathread.bas"

'based on RealMIDI 2.00, by Sebastian Mate


dim thread_handle as any ptr
dim thread_count as uinteger ptr
'declare sub _SoundThread(ByVal userdata As Any Ptr )
'declare sub _SoundInit()

_SoundInit
thread_handle = threadcreate( @_SoundThread)

'common shared synth as synthesizer

synth.reset
synth.channels(9).program=120 shl 14      'Set percussion mode







sub MidiMessage (a as ubyte, b as byte, c as byte)
synth.midi_event (a,b,c)
end sub



DIM SHARED Header AS STRING * 4
DIM SHARED TweeByte AS STRING * 2
DIM SHARED VierByte AS STRING * 4
DIM SHARED FileType AS STRING * 2


FUNCTION NextNumber as ubyte
 dim a as ubyte
 GET #1, , a
 NextNumber = a
END FUNCTION


FUNCTION ReadVarLen as integer
 dim a as ubyte
 GET #1, , a
 dim as integer Value, Value2
 Value = a
 IF (Value AND 128) THEN
  Value = (Value AND 127)
  DO
   GET #1, , a
   Value2 = a
   Value = (Value * (2 ^ 7)) + (Value2 AND 127)
  LOOP WHILE (Value2 AND 128)
 END IF
 return Value
END FUNCTION


FUNCTION ReadBPM as long
 DIM temp AS LONG
 dim a as ubyte
 GET #1, , a
 IF a = 3 THEN
  FOR i as integer = 1 TO 3
   GET #1, , a
   temp = (temp * 256) + a
  NEXT i
 END IF
 return temp
END FUNCTION

FUNCTION ReadFourBytes as long
 dim t as long
 dim a as ubyte
 GET #1, , a
 t = a * 2 ^ 8
 GET #1, , a
 t = (a + t) * 2 ^ 8
 GET #1, , a
 t = (a + t) * 2 ^ 8
 GET #1, , a
 ReadFourBytes = t + a
END FUNCTION

sub ReadText 
 dim a as ubyte
 dim as integer Lengte = ReadVarLen
 FOR tt as integer= 1 TO Lengte
  GET #1, , a
 NEXT tt
END sub


FUNCTION ReadTwoBytes as short
 dim a as ubyte
 dim t as integer
 GET #1, , a
 t = a * 2 ^ 8
 GET #1, , a
 return t + a
END FUNCTION


sub playMidiFile(file as String)

 OPEN file FOR BINARY AS #1
 GET #1, , Header
 IF Header <> "MThd" THEN PRINT "Not a valid MIDI file": STOP
 GET #1, , VierByte
 GET #1, , FileType
' IF ASC(RIGHT(FileType, 1)) = 0 THEN
' ELSE
'   PRINT "Multy tracks, this file type is not supported.": END
' END IF

 dim Tracks as integer, Divisions as integer, Tempo as integer=60000000/120
 Tracks = ReadTwoBytes
 Divisions = ReadTwoBytes

 dim Track as String
 dim Sequence(Tracks) as String
dim LastPos as integer
for tr as integer=0 to Tracks
    if eof(1) then exit for
    GET #1, , Header

    Track=""
    var TrkLength = ReadFourBytes

    LastPos=LOC(1)-2

    dim a as ubyte, status as ubyte
    dim as integer tl
 

    dim SeqTime as Double
    dim i as integer
    do
        if LOC(1)-LastPos>TrkLength orelse eof (1) then exit do
        tl = ReadVarLen ' Read the delay until we do anything and delay:
        'dim as double startDelay=timer

        'do:loop until timer>=StartDelay+(tl / tempo/1.5)
        SeqTime+=(tl * tempo/Divisions/1e6)
        

        GET #1, , a ' Get the MIDI-command...

        IF a = 255 THEN '... we have a meta-command!
          GET #1, , a
          SELECT CASE a
      CASE 47: NextNumber 'End of track
      CASE 81: tempo = ReadBPM
      CASE ELSE
        ReadText ' Unkown Meta Event
          END SELECT
         ELSEIF a = &HF0 OR a = &HF7 THEN
      ReadText
         ELSE

          if a>127 then status=a: GET #1, , a
          SELECT CASE status shr 4
          case &H8, &H9, &HA, &HB, &HE  
      Track+=mkd(SeqTime)
      Track+=chr(status)
      Track+=chr(a)
      Track+=chr(NextNumber)



          case &HC, &HD
      Track+=mkd(SeqTime)
      Track+=chr(status)
      Track+=chr(a)
      Track+=chr(0)
          case else
      exit do



          End Select




      END IF
    loop


    Sequence(tr)=Track
next


dim as double startDelay=timer
dim p(Tracks) as integer

for i as integer=0 to Tracks
   p(i)=1
next
dim as integer isPlaying
do
   isPlaying=0
   for i as integer=0 to Tracks
      
      if p(i)<len(Sequence(i)) then
           isPlaying=1
           dim SeqTime as Double=cvd(mid(Sequence(i),p(i)))

           if timer>=StartDelay+SeqTime then
             dim a as ubyte, b as ubyte, c as ubyte
             a=asc(mid(Sequence(i),p(i)+8))
             b=asc(mid(Sequence(i),p(i)+9))
             c=asc(mid(Sequence(i),p(i)+10))

             if a<>&H99 orelse (b>=35 andalso b<=81) then MidiMessage(a,b,c)
             synth.channels(9).program=120 shl 14      'Set percussion mode
             p(i)+=11
           end if
      end if
   next
      

loop while isPlaying

end sub