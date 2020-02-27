#include once "windows.bi"

'midi sub-system
Dim Shared As uinteger midihandle
Dim Shared As Any Ptr winmm_dll
Dim Shared midiOutOpen1 As Function(handle As UInteger Ptr,devid As UInteger,c0 As UInteger,c1 As UInteger,c2 As UInteger) As Integer
Dim Shared midiOutClose1 As Function(handle As UInteger) As Integer
Dim Shared midiOutShortMsg1 As Function (handle As UInteger,msg As UInteger) As Integer
Dim Shared As Single tr2,trc

Sub init_midi()
   #Ifdef __FB_WIN32__
   If winmm_dll<>0 Then 
      DylibFree(winmm_dll)
      winmm_dll=0
   EndIf
   winmm_dll=DylibLoad("winmm.dll")
   If winmm_dll<>0 Then
      midiOutOpen1=DylibSymbol(winmm_dll,"midiOutOpen")
      midiOutClose1=DylibSymbol(winmm_dll,"midiOutClose")
      midiOutShortMsg1=DylibSymbol(winmm_dll,"midiOutShortMsg")
      If midiOutOpen1=0 Then
         winmm_dll=0
         Exit Sub
      EndIf
      If midiOutOpen1(@midihandle,-1,0,0,0)<>0 Then
         midihandle=0
      EndIf
   EndIf
   #EndIf
End Sub
Sub close_midi()
   If midihandle<>0 Then 
      midiOutClose1(midihandle)
      midihandle=0
   EndIf
End Sub
Sub play_noise(noise As UInteger)
   #Ifdef __FB_WIN32__
   If noise=1 Then
      midiOutShortMsg1(midihandle,&hc0 Or (123 Shl 8))
      midiOutShortMsg1(midihandle,&h403f90)
      tr2=Timer
      trc=1
      Exit Sub
   ElseIf noise=2 Then
      midiOutShortMsg1(midihandle,&h403f80)
      midiOutShortMsg1(midihandle,&hc0 Or (124 Shl 8))
      midiOutShortMsg1(midihandle,&h403f90)
      tr2=Timer
      trc=1
      Exit Sub
      
   EndIf
end sub
Sub test_time2stop()
   If tr2<>0 Then
      If CSng(Timer)-tr2>trc Then
         midiOutShortMsg1(midihandle,&h403f80)
         tr2=0
      EndIf
   EndIf
End Sub

Dim As String a
Dim As Integer i

Print "#init_midi :";
init_midi()
Print "done"

Print
Print "Press [1] for first sound [2] for the second [hand] sound; press [ESC] to exit"
Do
   a=InKey:While a="":i+=1:i=IIf(i>200,200,i):Sleep i:test_time2stop():a=InKey:Wend
   play_noise(ValInt(a))
   test_time2stop()
Loop Until a=Chr(27)
close_midi()
Print "#close_midi done"
Sleep