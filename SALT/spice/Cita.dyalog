:Namespace Cita
   ⍝ UCMDs for CITA.
   ⍝ The individual commands and their syntax are API-Fns,
   ⍝ whose comments describe syntax and provide documentation.
   ⍝ So this file will hopefully never need to be updated!
    DEBUG←0

    ∇ r←List
      :If DEBUG
          600⌶1
      :EndIf
      ⎕←'Cita.List!'
      :If 0=⎕NC'⎕SE.CITA.UCMD._List'
           ⎕←'Set Home=',⎕SE.CITA.Home← 1⊃1⎕nparts ##.t,'/../../../'
          ⎕SE.CITA.API._InitUCMDs
          :else 
          ⎕←'Home was already set: ',⎕se.CITA.Home
      :EndIf
      r←⎕SE.CITA.UCMD.List
      :If DEBUG 
      600⌶0
      :EndIf
    ∇

    ∇ r←level Help cmd
      :If DEBUG
          600⌶1
      :EndIf
      :If 0=⎕NC'⎕SE.CITA.UCMD._Help'
          ⎕SE.CITA.API._InitUCMDs
      :EndIf
      r←level ⎕SE.CITA.UCMD.Help
      :If DEBUG
          600⌶0
      :EndIf
    ∇

    ∇ r←Run(cmd args)
      :If DEBUG
          600⌶1
      :EndIf
      :If 0=⎕NC'⎕SE.CITA.UCMD._Help'
          ⎕SE.CITA.API._InitUCMDs
      :EndIf
      r←⎕SE.CITA.UCMD.Run(cmd args)
      :If DEBUG
          600⌶1
      :EndIf
    ∇

:endnamespace
