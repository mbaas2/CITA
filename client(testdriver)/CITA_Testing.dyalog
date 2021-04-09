:namespace _cita

        ∇ Write2Log txt
          ⍝ needs name of test
          file←'.log',⍨2 ⎕NQ'.' 'GetEnvironment' 'CITA_Log'
          :If ~qNEXISTS file
              txt qNPUT file
          :Else ⍝ q&d "append":
              old←qNGET file
              (old,⊂txt)qNPUT file 1
          :EndIf
        ∇


        ∇ {msg}LogStatus status;file
⍝ a step (setup|test|teardown) is finished, report its status to the engine
⍝ msg allows inject of a message into the file, otherwise an empty file will be created.
⍝ options:
⍝ fail  | ok
⍝ err   | success
⍝ no    | yes
⍝ 0     | 1
          :If 0=⎕NC'step' ⋄ step←'test' ⋄ :EndIf
          :if 0=⎕nc'msg' ⋄ msg←'' ⋄ :endif
          file←2 ⎕NQ'.' 'GetEnvironment' 'CITA_Log'
          :If isChar status  ⍝ decode status from character-string
              :If ∨/(⊂lc status){(0<''⍴⍴⍺)∧⍺≡(''⍴⍴⍺)↑⍵}¨'failure' 'error' 'no'
                  status←0
              :ElseIf ∨/(⊂lc status){(0<''⍴⍴⍺)∧⍺≡(''⍴⍴⍺)↑⍵}¨'success' 'ok' 'yes'
                  status←1
              :Else
              :EndIf
          :Else
              status←1∊status
          :EndIf
          status←(1+status)⊃'err' 'ok'
          msg qNPUT file,'.',status
        ∇

:endnamespace        