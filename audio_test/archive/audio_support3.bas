#ifndef NULL
#define NULL 0
#endif

Const SND_SEQ_OPEN_DUPLEX As Integer = 3
Const SND_SEQ_PORT_TYPE_MIDI_GENERIC As Integer = 2
Const SND_SEQ_PORT_TYPE_APPLICATION As Integer = 1048576  '  (1<<20)

Const SND_SEQ_ADDRESS_UNKNOWN As Byte = 253
Const SND_SEQ_ADDRESS_SUBSCRIBERS As Byte = 254

Const SND_SEQ_EVENT_NOTEON As Byte = 6
Const SND_SEQ_EVENT_NOTEOFF As Byte = 7

const SND_SEQ_EVENT_PGMCHANGE = 11

const SIZE_OF_SEQEV=64

Dim As Any Ptr alsa = DyLibLoad("asound")

Dim Shared snd_seq_open as Function (byref handle As any ptr, name As zString ptr, streams As Integer, mode As Integer) As Integer
snd_seq_open= DyLibSymbol(alsa, "snd_seq_open")

Dim Shared snd_seq_set_client_name as Function (handle As any ptr, name As zString ptr) As Integer
snd_seq_set_client_name= DyLibSymbol(alsa, "snd_seq_set_client_name")

Dim Shared snd_seq_create_simple_port as Function (handle As any ptr, name As zString ptr, caps As Integer, type As Integer) As Integer
snd_seq_create_simple_port= DyLibSymbol(alsa, "snd_seq_create_simple_port")

Dim Shared snd_seq_client_id as Function (handle As any ptr) As Integer
snd_seq_client_id= DyLibSymbol(alsa, "snd_seq_client_id")

Dim Shared snd_seq_alloc_queue as Function(seq As any ptr, name As zString ptr) As Integer
snd_seq_alloc_queue= DyLibSymbol(alsa, "snd_seq_alloc_queue")

Dim Shared snd_seq_connect_to as Function (seq As any ptr, myport As Integer, src_client As Integer, src_port As Integer) As Integer
snd_seq_connect_to= DyLibSymbol(alsa, "snd_seq_connect_to")

Dim Shared snd_seq_event_output as Function (handle As any ptr, ev As any ptr) As Integer
snd_seq_event_output= DyLibSymbol(alsa, "snd_seq_event_output")

Dim Shared snd_seq_drain_output as Function (handle As any ptr) As Integer
snd_seq_drain_output= DyLibSymbol(alsa, "snd_seq_drain_output")

Dim Shared snd_midi_event_encode as Function(dev as any ptr,buf as zstring ptr, count as integer, ev as any ptr) as integer
snd_midi_event_encode= DyLibSymbol(alsa, "snd_midi_event_encode")

Dim Shared snd_midi_event_new as Function (bufsize as integer, rdev as any ptr ptr) as integer
snd_midi_event_new= DyLibSymbol(alsa, "snd_midi_event_new")

Dim Shared snd_midi_event_no_status as Function (dev as any ptr, onoff as integer) as integer
snd_midi_event_no_status= DyLibSymbol(alsa, "snd_midi_event_no_status")



dim shared MidiEvent as byte ptr
Midievent=allocate(SIZE_OF_SEQEV)
dim shared MidiParser as ubyte ptr
'dim shared MidiMessage as ubyte ptr
'MidiMessage=allocate(10)


Dim _err As Integer
dim shared id as integer, outport as integer, outq as integer
dim shared handle as any ptr
dim myname as string="test"


_err = snd_seq_open(handle, "default", SND_SEQ_OPEN_DUPLEX, 0)
Print "Opening alsa="; _err
If _err < 0 Then print "Error opening alsa"
  
snd_seq_set_client_name(handle, myname)
id = snd_seq_client_id(handle)
Print "Alsa ClientID="; id
  
_err = snd_seq_create_simple_port(handle, "Seq-Out", 0, SND_SEQ_PORT_TYPE_MIDI_GENERIC + SND_SEQ_PORT_TYPE_APPLICATION)
Print "My alsa client port="; _err
If _err < 0 Then print "Error creating alsa port"
outport = _err
  
_err = snd_seq_alloc_queue(handle, "outqueue")         ' per creare una coda di eventi
print "Creating queue", _err
If _err < 0 Then print "Error creating out queue"
outq = _err
  
' ev = Alloc(SIZE_OF_SEQEV)    ' alloca un evento nella zona di memoria riservata per lavorarci
' p = Memory ev For Write

_err = snd_seq_connect_to(handle, outport, 128, 0)
print "Subscribe", _err
If _err < 0 Then print"Error subscribe output device"

_err = snd_midi_event_new(10, @MidiParser)

snd_midi_event_no_status (MidiParser,1)

For i as integer = 0 To SIZE_OF_SEQEV-1
   MidiEvent[i]=0
Next

 
MidiEvent[3]= outq

MidiEvent[12]= id
MidiEvent[13]= outport

 
MidiEvent[14]= SND_SEQ_ADDRESS_SUBSCRIBERS   ' 254/dclient
MidiEvent[15]= SND_SEQ_ADDRESS_UNKNOWN   ' 253/dport



sub MidiSend(event as UByte, a as UByte, b as UByte) 

   Dim _err As Integer

   snd_midi_event_encode (MidiParser, chr(event)+chr(a)+chr(b), 3, MidiEvent)

   _err = snd_seq_event_output(handle, MidiEvent)
   snd_seq_drain_output(handle)

END sub


midiSend &H90, 60, 127         ' Note on
sleep
midiSend &H80, 60, 127         ' Note off