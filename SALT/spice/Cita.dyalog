:Namespace Cita
   ⍝ UCMDs for CITA.
   ⍝ The individual commands and their syntax are API-Fns,
   ⍝ whose comments describe syntax and provide documentation.
   ⍝ So this file will hopefully never need to be updated!

    ∇ r←List
      Init
      r←⎕SE.CITA.UCMD.List
    ∇

    ∇ r←level Help cmd
      Init
      r←level ⎕SE.CITA.UCMD.Help cmd
    ∇

    ∇ r←Run(cmd args)
      Init
      r←⎕SE.CITA.UCMD.Run(cmd args)
    ∇

    ∇ Init
      :If 0=⎕NC'⎕SE.CITA.UCMD._List'
          :If 0=⎕NC'⎕SE.CITA'
              ⎕←'Could not find ⎕SE.CITA - please check your StartupSession-Folder!'
              →0
          :EndIf
          ⎕SE.CITA.API._InitUCMDs
      :EndIf
    ∇

:endnamespace
