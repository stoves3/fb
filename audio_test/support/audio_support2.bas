#include once "midisynth.bi"
#include once "instruments.bi"

dim thread_handle as any ptr
dim thread_count as uinteger ptr
declare sub _SoundThread(ByVal userdata As Any Ptr )
declare sub _SoundInit()

_SoundInit
thread_handle = threadcreate( @_SoundThread)

common shared synth as synthesizer

synth.reset
synth.channels(9).program=120 shl 14      'Set percussion mode










    #ifndef NULL
    #define NULL 0
    #endif

    Const SND_SEQ_OPEN_DUPLEX As Integer = 3
    Const SND_SEQ_PORT_TYPE_MIDI_GENERIC As Integer = 2
    Const SND_SEQ_PORT_TYPE_APPLICATION As Integer = 1048576  '  (1<<20)
    Const SND_SEQ_PORT_CAP_WRITE =2
    Const SND_SEQ_PORT_CAP_SUBS_WRITE = 64

    Const SND_SEQ_ADDRESS_UNKNOWN As Byte = 253
    Const SND_SEQ_ADDRESS_SUBSCRIBERS As Byte = 254

    Const SND_SEQ_EVENT_NOTEON As Byte = 6
    Const SND_SEQ_EVENT_NOTEOFF As Byte = 7

    const SIZE_OF_SEQEV=64


    declare function snd_seq_open cdecl alias "snd_seq_open" (byref handle As any ptr, name As zString ptr, streams As Integer, mode As Integer) As Integer

    declare function snd_seq_set_client_name cdecl alias "snd_seq_set_client_name" (handle As any ptr, name As zString ptr) As Integer

    declare function snd_seq_create_simple_port cdecl alias "snd_seq_create_simple_port" (handle As any ptr, name As zString ptr, caps As Integer, type As Integer) As Integer

    declare function snd_seq_client_id cdecl alias "snd_seq_client_id" (handle As any ptr) As Integer

    declare function snd_seq_alloc_queue cdecl alias "snd_seq_alloc_queue" (seq As any ptr, name As zString ptr) As Integer

    declare function snd_seq_connect_to cdecl alias "snd_seq_connect_to"(seq As any ptr, myport As Integer, src_client As Integer, src_port As Integer) As Integer

    declare function snd_seq_connect_from cdecl alias "snd_seq_connect_from"(seq As any ptr, myport As Integer, src_client As Integer, src_port As Integer) As Integer

    declare function snd_seq_event_output cdecl alias "snd_seq_event_output"(handle As any ptr, ev As any ptr ptr) As Integer

    declare function snd_seq_event_input cdecl alias "snd_seq_event_input"(handle As any ptr, ev As any ptr) As Integer

    declare function snd_seq_drain_output cdecl alias "snd_seq_drain_output" (handle As any ptr) As Integer

    declare function snd_midi_event_decode cdecl alias "snd_midi_event_decode"(dev as any ptr,buf as zstring ptr, count as integer, ev as any ptr) as integer

    declare function snd_midi_event_new cdecl alias "snd_midi_event_new"(bufsize as integer, rdev as any ptr ptr) as integer

    declare function snd_midi_event_no_status cdecl alias "snd_midi_event_no_status"  (dev as any ptr, onoff as integer) as integer

    #inclib "asound"



    dim shared MidiEvent as byte ptr
    Midievent=allocate(SIZE_OF_SEQEV)
    dim shared MidiParser as ubyte ptr
    dim shared MidiMessage as ubyte ptr
    MidiMessage=allocate(10)


    Dim _err As Integer
    dim shared id as integer, outport as integer, outq as integer
    dim shared handle as any ptr
    dim myname as string="FM Midi"


    _err = snd_seq_open(handle, "default", SND_SEQ_OPEN_DUPLEX, 0)
    If _err < 0 Then print "Error opening alsa"
     
    snd_seq_set_client_name(handle, myname)
    id = snd_seq_client_id(handle)
    Print "Alsa ClientID="; id
     
    _err = snd_seq_create_simple_port(handle, "Seq-Out", 66, SND_SEQ_PORT_TYPE_MIDI_GENERIC + SND_SEQ_PORT_TYPE_APPLICATION)
    If _err < 0 Then print "Error creating alsa port"
    outport = _err

    _err = snd_seq_connect_from(handle, outport, 128, 0)
    If _err < 0 Then print"Error subscribe output device"

    _err = snd_midi_event_new(10, @MidiParser)

    snd_midi_event_no_status MidiParser,1
do
   dim l as integer
   _err = snd_seq_event_input(handle, @MidiEvent)
   l=snd_midi_event_decode (MidiParser, MidiMessage, 3, MidiEvent)

   ?hex( MidiMessage[0]), MidiMessage[1], MidiMessage[2]
   synth.midi_event MidiMessage[0], MidiMessage[1], MidiMessage[2]
   synth.channels(9).program=120 shl 14      'Set percussion mode

loop until inkey<>""