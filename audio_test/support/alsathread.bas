#include once "midisynth.bi"
#include once "instruments.bi"
common shared synth as synthesizer


    'Const EAGAIN                       = -11 ' Try again
    'Const EPIPE                        = -32 ' Broken pipe
    Const ESTRPIPE                     = -86 ' Streams pipe error

    Const BLOCK                        = 0
    Const NONBLOCK                     = 1
    Const ASYNC                        = 2

    Const SND_PCM_STREAM_PLAYBACK      = 0
    Const SND_PCM_STREAM_CAPTURE       = 1
    Const SND_PCM_FORMAT_S16_LE        = 2
    Const SND_PCM_ACCESS_RW_INTERLEAVED= 3

    #ifndef NULL
    #define NULL 0
    #endif

    Type snd_pcm_t           As Any Ptr
    Type snd_pcm_hw_params_t As Any Ptr
    Type snd_output_t        As Any Ptr

    ' PCM
    Declare Function snd_strerror Cdecl Alias "snd_strerror" ( _
    Byval ecode As Integer) As Zstring Ptr

    Declare Function snd_pcm_open Cdecl Alias "snd_pcm_open" ( _
    Byval pcm          As snd_pcm_t Ptr, _
    Byval device       As String, _
    Byval direction    As Integer, _
    Byval mode         As Integer) As Integer

    Declare Function snd_pcm_close Cdecl Alias "snd_pcm_close" ( _
    Byval pcm          As snd_pcm_t) As Integer

    Declare Function snd_pcm_start Cdecl Alias "snd_pcm_start" ( _
    Byval pcm          As snd_pcm_t) As Integer

    Declare Function snd_pcm_drain Cdecl Alias "snd_pcm_drain" ( _
    Byval pcm          As snd_pcm_t) As Integer

    Declare Function snd_pcm_hw_free Cdecl Alias "snd_pcm_hw_free" ( _
    Byval pcm          As snd_pcm_t) As Integer

    Declare Function snd_pcm_nonblock Cdecl Alias "snd_pcm_nonblock" ( _
    Byval pcm          As snd_pcm_t, _
    Byval nonblock     As Integer) As Integer

    Declare Function snd_pcm_prepare Cdecl Alias "snd_pcm_prepare" ( _
    Byval pcm          As snd_pcm_t) As Integer

    Declare Function snd_pcm_writei Cdecl Alias "snd_pcm_writei" ( _
    Byval pcm          As snd_pcm_t, _
    Byval buffer       As Any Ptr, _
    Byval size         As Integer) As Integer

    Declare Function snd_pcm_avail_update Cdecl Alias "snd_pcm_avail_update" ( _
    Byval pcm          As snd_pcm_t) As Integer

    Declare Function snd_pcm_wait Cdecl Alias "snd_pcm_wait" ( _
    Byval pcm          As snd_pcm_t, _
    Byval msec As Integer) As Integer

    Declare Function snd_pcm_resume Cdecl Alias "snd_pcm_resume" ( _
    Byval pcm          As snd_pcm_t) As Integer

    'hardware
    Declare Function snd_pcm_hw_params_malloc Cdecl Alias "snd_pcm_hw_params_malloc" ( _
    Byval hw           As snd_pcm_hw_params_t Ptr) As Integer

    Declare Function snd_pcm_hw_params_any Cdecl Alias "snd_pcm_hw_params_any" ( _
    Byval pcm          As snd_pcm_t, _
    Byval hw           As snd_pcm_hw_params_t) As Integer

    Declare Function snd_pcm_hw_params_set_access Cdecl Alias "snd_pcm_hw_params_set_access" ( _
    Byval pcm          As snd_pcm_t, _
    Byval hw           As snd_pcm_hw_params_t, _
    Byval mode         As Integer) As Integer

    Declare Function snd_pcm_hw_params_set_format Cdecl Alias "snd_pcm_hw_params_set_format" ( _
    Byval pcm          As snd_pcm_t, _
    Byval hw           As snd_pcm_hw_params_t, _
    Byval fmt          As Integer) As Integer

    Declare Function snd_pcm_hw_params_set_channels Cdecl Alias "snd_pcm_hw_params_set_channels" ( _
    Byval pcm          As snd_pcm_t, _
    Byval hw           As snd_pcm_hw_params_t, _
    Byval Channels     As Integer) As Integer

    Declare Function snd_pcm_hw_params_get_channels Cdecl Alias "snd_pcm_hw_params_get_channels" ( _
    Byval hw           As snd_pcm_hw_params_t, _
    Byval lpChannels   As Integer Ptr) As Integer

    Declare Function snd_pcm_hw_params_set_rate_near Cdecl Alias "snd_pcm_hw_params_set_rate_near" ( _
    Byval pcm          As snd_pcm_t, _
    Byval hw           As snd_pcm_hw_params_t, _
    Byval lpRate       As Integer Ptr, _
    Byval lpDir        As Integer Ptr) As Integer


    Declare Function snd_pcm_hw_params_get_periods Cdecl Alias "snd_pcm_hw_params_get_periods" ( _
    Byval hw           As snd_pcm_hw_params_t, _
    Byval lpValue      As Integer Ptr, _
    Byval lpDir        As Integer Ptr) As Integer

    Declare Function snd_pcm_hw_params_set_periods_near Cdecl Alias "snd_pcm_hw_params_set_periods_near" ( _
    Byval pcm          As snd_pcm_t, _
    Byval hw           As snd_pcm_hw_params_t, _
    Byval lpValue      As Integer Ptr, _
    Byval lpDir        As Integer Ptr) As Integer

    Declare Function snd_pcm_hw_params_get_period_size Cdecl Alias "snd_pcm_hw_params_get_period_size" ( _
    Byval params       As snd_pcm_hw_params_t, _
    Byval lpFrames     As Integer Ptr, _
    Byval lpDir        As Integer Ptr) As Integer

    'int  snd_pcm_hw_params_set_period_size_near (snd_pcm_t *pcm, snd_pcm_hw_params_t *params, snd_pcm_uframes_t *val, int *dir)
    Declare Function snd_pcm_hw_params_set_period_size_near Cdecl Alias "snd_pcm_hw_params_set_period_size_near" ( _
    Byval pcm          As snd_pcm_t Ptr, _
    Byval hw           As snd_pcm_hw_params_t, _
    Byval lpValue      As Integer Ptr, _
    Byval lpDir        As Integer Ptr) As Integer

    Declare Function snd_pcm_hw_params_set_buffer_size_near Cdecl Alias "snd_pcm_hw_params_set_buffer_size_near" ( _
    Byval pcm          As snd_pcm_t, _
    Byval hw           As snd_pcm_hw_params_t, _
    Byval lpFrames     As Integer Ptr) As Integer

    Declare Function snd_pcm_hw_params_get_buffer_size Cdecl Alias "snd_pcm_hw_params_get_buffer_size" ( _
    Byval hw           As snd_pcm_hw_params_t, _
    Byval lpFrames     As Integer Ptr) As Integer

    Declare Function snd_pcm_hw_params Cdecl Alias "snd_pcm_hw_params" ( _
    Byval pcm          As snd_pcm_t, _
    Byval hw           As snd_pcm_hw_params_t) As Integer

    Declare Sub snd_pcm_hw_params_free Cdecl Alias "snd_pcm_hw_params_free" ( _
    Byval hw           As snd_pcm_hw_params_t)

    #inclib "asound"



    #define device "hw:0,0"


    Dim Shared As snd_pcm_t Ptr           hDevice
    Dim Shared As snd_pcm_hw_params_t Ptr hw
    Dim Shared As Integer                 ret,value,direction,nbuffers,buffersize,nFrames,Periodsize
    Dim Shared As Zstring Ptr             strRet

    sub _SoundInit()
        
       ret = snd_pcm_open(@hDevice,device, SND_PCM_STREAM_PLAYBACK, NONBLOCK)
       ret=snd_pcm_nonblock(hDevice,NONBLOCK)
       snd_pcm_hw_params_malloc(@hw)
       ret = snd_pcm_hw_params_any(hDevice,hw)
       ret = snd_pcm_hw_params_set_access(hDevice, hw, SND_PCM_ACCESS_RW_INTERLEAVED)
       ret = snd_pcm_hw_params_set_format(hDevice,hw,2)
       ret = snd_pcm_hw_params_set_channels(hDevice,hw,2)
       value=44100 'set speed
       ret = snd_pcm_hw_params_set_rate_near(hDevice,hw,@value,@direction)
       nFrames=128 * 8 ' please try 8,7,6,5,4,3,2,1
       ret = snd_pcm_hw_params_set_period_size_near(hDevice, hw, @nFrames,0)
       Periodsize=nFrames\2
       ret = snd_pcm_hw_params_set_periods_near(hDevice, hw,@PeriodSize, 0)
       ret = snd_pcm_hw_params(hDevice,hw)
       snd_pcm_hw_params_free hw
       ret = snd_pcm_prepare(hDevice)
       BufferSize=nFrames*4
       nBuffers=PeriodSize
       ret=snd_pcm_avail_update(hDevice)
    end sub

    sub _SoundThread(ByVal userdata As Any Ptr )

       Dim As Short Ptr ptr lpBuffers




       Dim As Integer i,j,p

       dim as integer nSamples


       nSamples=44100*int(1600/18.2) ' seconds


       lpBuffers=callocate(nBuffers * sizeof(Short Ptr))
       For i=0 To nBuffers-1
         lpBuffers[i]=allocate(Buffersize)
       Next

       dim Waveform As byte

       i=0


       While i<nSamples
         For j=0 To nBuffers-1
      For p=0 To (Buffersize shr 1) - 2 step 2

        lpBuffers[j][p  ]=sin(6.28/44100*400*i)*10000*i/nsamples
        lpBuffers[j][p+1]=sin(6.28/44100*400*i)*10000*(1.0-i/nsamples)
        'i=i+1
      Next

           synth.synthesize(lpBuffers[j], Buffersize/4, 44100)

      ret=EAGAIN
      While ret=EAGAIN
        ret=snd_pcm_writei(hDevice,lpBuffers[j],nFrames)
      Wend
      ret=snd_pcm_wait(hDevice,1000)

         Next
       Wend

       If hDevice<>0 Then snd_pcm_close hDevice:hDevice=0
       If lpBuffers<>0 Then
         For i=0 To nBuffers-1
      If lpBuffers[i] <> 0 Then deallocate lpBuffers[i]:lpBuffers[i]=0
         Next
         deallocate lpBuffers:lpBuffers=0
       End If
    end sub