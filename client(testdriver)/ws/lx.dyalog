 lx;path;v;Env;subj;ext;r;z;s;cmd;y;log;randomstring;wsFullReport;⎕RL;⎕ML;⎕IO;rc
 ⍝ OFF with returncode 42: all is well, 43: error, 44: WS FULL
 NL←⎕UCS 13
 ⎕RL←2
 ⎕ML←1
 ⎕IO←1
 rc←42  ⍝ returncode if everything was ok (errors will set rc to 43, ws FULL=44)
 randomstring←(⎕A,⎕D)[?32⍴36]
 ⎕←'┌─────────────────────────────────────────────────────────────────────┐'
 ⎕←'↓↓↓ This output indicates the start of a new session                ↓↓↓'
 ⎕←'↓↓↓ so that you can see what happened while executing your code...  ↓↓↓'
 ⎕←randomstring
 ⎕←'Session started at ',(⍕⎕TS)
 ⎕←,'<WA=>,CI15,< bytes>'⎕FMT ⎕WA
 path←{(⌽∨\⌽⍵∊'/\')/⍵}⎕WSID
 v←1⊃'.'⎕VFI 2⊃'.'⎕WG'aplversion'
 Env←{2 ⎕NQ'.' 'GetEnvironment'⍵}  ⍝ get environment variable or cmdline
 HandleError←{
     rc←43
     en←⎕EN   ⍝ save it before any trapped errors inside this fn cvhange it
     s←'Loaded File "',⍺,'". Executing "',⍵,'" crashed with a error: '
     sink←⎕EX'wsFullReport'
     s,←∊⎕DM,¨⎕TC[3]
     s,←{⎕ML←1 ⋄ ⍵≠1:'' ⋄ 1::'WS FULL gathering list of vars' ⋄ rep←res←⊃⍪/⊃,/{((⊂⍕⍵),¨'.',¨↓nl),[1.5]⍵.⎕SIZE nl←⍵.⎕NL⍳9}⎕SE._cita.swise¨# ⎕SE ⋄ j←(20⌊1↑⍴rep)↑⍒rep[;2] ⋄ ,⍕rep[j;],⊂NL}⎕EN
     dmx←{0::'' ⋄ ⎕DMX}0  ⍝ can't use ⎕DMX. in next line because this code is saved with v12 that does not know ⎕DMX
     s,←{0::{0::'' ⋄ 'DMX=',∊dmx.({0::'' ⋄ ⍵,':',(⍎⍵),⎕TC[3]}¨⎕NL ¯2)}'' ⋄ 'DMX=',∊⎕JSON dmx}''   ⍝ various fallsbacks so that this code can execute even on v12 (where it does not do anything - but also does not fail)
     en=1:rc←44+0×''⍴⍴s ⎕SE._cita._LogStatus'wsfull'
     ⎕SE._cita.Error s
 }

 wsFullReport←(500⍴⊂'PlaceHolder'),[1.5]1000000     ⍝ reserve a few bytes for our wsfullreport - just in case...
⍝ set up ⎕SE._cita
 {}⎕SE.UCMD'GetTools4CITA'
 :If 'on'≡⎕SE._cita.lc Env'UDEBUG'
     {}⎕SE.UCMD'UDEBUG ON'  ⍝ only during testing...
 :EndIf

⍝ run the code
 :If 0<⎕SE._cita.tally subj←Env'CITATest'   ⍝ get test subject

     ext←3⊃⎕SE._cita.qNPARTS subj
     :Select ext
     :CaseList '' '.dyalogtest',('DTest'≡Env'mode')/⊂ext
         :Trap 0
             ⎕SE.UCMD ⎕←r←'DTest "',subj,'" -testlog="',(Env'testlog'),'" ',(Env'dtestmods ')
         :Else
             subj HandleError' ]',r
             →Done
         :EndTrap
         →End
     :CaseList '.aplc' '.apln' '.dyalog'
         ⎕←']Load ',subj
         :Trap 0
             r←⎕SE.SALT.Load subj   ⍝ load it
         :Else
             subj HandleError']LOAD ',subj
         :EndTrap
         :If 3=⎕NC⍕r
             →runFn
         :EndIf
         :If 3=⎕NC r,'.Run'
             :Trap 0
                 :If 1=|1 1⊃(⎕AT r,'.Run')
                     ⎕←r,'.Run'
                     {}r⍎Run
                 :Else
                     ⎕←r,'⍎',Run
                     r⍎Run
                 :EndIf
             :Else
                 subj HandleError r
                 →Done
             :EndTrap
         :Else
             s←⎕←'File "',subj,'" did not define "Run" function in ns/class'
             ⎕SE._cita.Failure s
         :EndIf
         →Done
         →End
     :Case '.aplf'
         ⎕←']LOAD ',subj
         :Trap 0
             r←⎕SE.SALT.Load subj   ⍝ load it
         :Else
             subj HandleError' ]LOAD ',subj
             →Done
         :EndTrap
runFn:
         :If 3=⎕NC r
             :Select 1 2⊃(⎕AT r)
             :Case 0
                 cmd←r
             :Case 1
                 cmd←r,' ⍬'
             :Case 2
                 cmd←'⍬ ',r,' ⍬'
             :EndSelect
             :Trap 0
                 ⎕←cmd
                 :If 1=|1 1⊃(⎕AT r)   ⍝ execute user's code. We don't care about its result - user should call LogStatus...
                     z←⍎cmd
                 :Else
                     ⍎cmd
                 :EndIf
             :Else
                 subj HandleError r
                 →Done
             :EndTrap
         :Else
             s←⎕←'Loading File "',subj,'" did not give us a function. Result was: "',r,'"'
             ⎕SE._cita.Failure s
         :EndIf
         →Done
     :Else
         ⎕←'Not sure what to do with ext=',ext
         ∘∘∘
     :EndSelect
End:
     ⎕←'No problems running user code'
     ⎕SE._cita.Success''
 :ElseIf 0<⎕SE._cita.tally subj←Env'RunUCMD'
     :Trap 0
         ⎕←']',subj
         ⎕SE.UCMD subj
     :Else
         subj HandleError ⎕←'Error executing UCMD',NL,∊⎕DM,¨⊂NL
     :EndTrap
 :Else
     ⎕←'No idea why you called me! :('
     ∘∘∘
 :EndIf

Done:
 :Trap 0
     log←⎕SE ⎕WG'Log'
     log←∊log,¨⊂NL
     :If 1∊y←randomstring⍷log
         log←(y⍳1)↓log
         log←((NL⍷log)⍳1)↓log
     :EndIf
     log ⎕SE._cita._LogStatus'sessionlog.txt'
 :Else
     ⎕←'*** Error while attempting to write sessionlog to a file:'
     ⎕←⎕DM
 :EndTrap
 ⎕OFF rc
