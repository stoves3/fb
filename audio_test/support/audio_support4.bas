#include once "windows.bi"
#include once "win\mmsystem.bi"

#Include "windows.bi"
#Include "win/mmsystem.bi"

Const As Integer Lenght = 7200 ' maximum 2 hours

Type WaveFileHeader
   riff(3) As Byte = {82,73,70,70}
   Len_ As  Integer
   cWavFmt(7) As Byte = {87,65,86,69,102,109,116,32}
   dwHdrLen As Integer = 16
   wFormat As Short = 1
   wNumChannels As Short = 1
   dwSampleRate As Integer = 11000
   dwBytesPerSec As Integer = 22000
   wBlockAlign As Short = 4
   wBitsPerSample As Short = 16
   cData(3) As Byte = {100,97,116,97}
   dwDataLen As Integer
End Type

Type Sound
   As WAVEHDR hdr
   As HWAVEIN hWaveIn
   As HWAVEOUT hWaveOut
   As WAVEFORMATEX wfx
   As WaveFileHeader Wavehdr
   As Byte buffer(11000*Lenght*2)
   Declare Function Rec() As BOOL
   Declare Sub RecStop()
   Declare Function Play() As BOOL
   Declare Sub PlayStop()
   Declare Sub SaveSound()
End Type

Dim Shared obj As Sound

Sub Sound.SaveSound()
   Var Hfile=CreateFile("SoundTest.wav",GENERIC_WRITE Or GENERIC_READ, FILE_SHARE_READ or FILE_SHARE_WRITE,0, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL,0)
   Dim buff As Integer
   WriteFile(Hfile,Cast(LPCVOID,@Wavehdr),SizeOf(WaveFileHeader),@buff,0)
   WriteFile(Hfile,Cast(LPCVOID,@buffer(0)),Wavehdr.dwDataLen,@buff,0)
   CloseHandle(Hfile)
End Sub

Function Sound.Rec() As BOOL
   ZeroMemory(@buffer(0),UBound(buffer)+1)
   With wfx
      .wFormatTag = WAVE_FORMAT_PCM
      .nChannels = 1
      .nSamplesPerSec = 11000
      .wBitsPerSample = 16
      .nBlockAlign = .nChannels * (.wBitsPerSample \ 8)
      .nAvgBytesPerSec = .nSamplesPerSec * .nBlockAlign
      .cbSize = SizeOf(WAVEFORMATEX)
   End With
   With hdr
      .lpData = @buffer(0)
      .dwBufferLength = UBound(buffer)+1
   End With
   If waveInOpen(@hWaveIn, Cast(UInteger, -1), @wfx, 0, 0, CALLBACK_NULL)<> MMSYSERR_NOERROR Then
      MessageBox(0,"Unable to mount device","Error",0)
      Return FALSE
   EndIf
   waveInPrepareHeader(hWaveIn, @hdr, SizeOf(WAVEHDR))
   waveInAddBuffer(hWaveIn, @hdr, SizeOf(WAVEHDR))

   If waveInStart(hWaveIn)<> MMSYSERR_NOERROR Then
      MessageBox(0,"A bad start recording","Error",0)
      Return FALSE
   EndIf
   Return TRUE
End Function

Sub Sound.RecStop()
   waveInReset(hWaveIn)
   waveInUnprepareHeader(hWaveIn, @hdr, SizeOf(WAVEHDR))
   waveInClose(hWaveIn)
End Sub

Function Sound.Play() As BOOL
   If waveOutOpen(@hWaveOut, Cast(UInteger, -1), @wfx, 0, 0, CALLBACK_NULL)<> MMSYSERR_NOERROR Then
      MessageBox(0,"Unable to mount device","Error",0)
      Return FALSE
   EndIf
   waveOutPrepareHeader(hWaveOut, @hdr, SizeOf(WAVEHDR))
   waveOutWrite(hWaveOut, @hdr, SizeOf(WAVEHDR))
   Return TRUE
End Function

Sub Sound.PlayStop()
   waveOutReset(hWaveOut)
   waveOutUnprepareHeader(hWaveOut, @hdr, SizeOf(WAVEHDR))
   waveOutClose(hWaveOut)
End Sub
