 lx;path;v;Env;subj;ext;r;z;s;cmd
 path←{(⌽∨\⌽⍵∊'/\')/⍵}⎕WSID
 v←1⊃'.'⎕VFI 2⊃'.'⎕WG'aplversion'
 Env←{2 ⎕NQ'.' 'GetEnvironment'⍵}  ⍝ get environment variable or cmdline
 HandleError←{
     s←'Loaded File "',⍺,'". Executing "',⍵,'" led to a trapped error: '
     s,←∊⎕DM,¨⎕TC[3]
     dmx←{0::'' ⋄ ⎕DMX}0  ⍝ can't use ⎕DMX. in next line because this code is saved with v12 that does not know ⎕DMX
     s,←{0::{0::''  ⋄ 'DMX=',∊dmx.({0::'' ⋄ ⍵,':',(⍎⍵),⎕TC[3]}¨⎕NL ¯2)}'' ⋄ 'DMX=',∊⎕JSON dmx}''   ⍝ various fallsbacks so that this code can execute even on v12 (where it does not do anything - but also does not fail)
     ⎕SE._cita.Failure s
 }

⍝ set up ⎕SE._cita
 {}⎕SE.UCMD'GetTools4CITA'
 {}⎕SE.UCMD'UDEBUG ON'  ⍝ only during testing...

⍝ run the code
 subj←Env'CITATest'   ⍝ get test subject

 ext←3⊃⎕SE._cita.qNPARTS subj
 :Select ext
 :CaseList '' '.dyalogtest',('DTest'≡Env'mode')/⊂ext
     ⎕SE.UCMD ⎕←'DTest "',subj,'" -testlog="',(Env'testlog'),'" ',(Env'dtestmods ')
     →End
 :CaseList '.aplc' '.apln' '.dyalog'
     r←⎕SE.SALT.Load subj   ⍝ load it
     :if 3= ⎕nc ⍕r 
     →runFn 
     :endif
     :If 3=⎕NC r,'.Run'
         :Trap 0
             :If 1=|1 1⊃(⎕AT r,'.Run')
                 {}r⍎Run
             :Else
                 r⍎Run
             :EndIf
         :Else
             subj HandleError r
         :EndTrap
     :Else
         s←'File "',subj,'" did not define "Run" function in ns/class'
         ⎕SE._cita.Failure s
     :EndIf
     →End
 :Case '.aplf'
     r←⎕SE.SALT.Load subj   ⍝ load it
     runFn:
     :If 3=⎕NC r
         :Select 1 2⊃(⎕AT r)
         :Case 0 ⋄ cmd←r
         :Case 1 ⋄ cmd←r,' ⍬'
         :Case 2 ⋄ cmd←'⍬ ',r,' ⍬'
         :EndSelect
         :Trap 0
             :If 1=|1 1⊃(⎕AT r)   ⍝ execute user's code. We don't care about its result - user should call LogStatus...
                 z←⍎cmd
             :Else
                 ⍎cmd
             :EndIf
         :Else
             subj HandleError r
         :EndTrap
     :Else
         s←'Loading File "',subj,'" did not give us a function. Result was: "',r,'"'
         ⎕SE._cita.Failure s
     :EndIf
     →End
 :Else
     ⎕←'Not sure what to do with ext=',ext
     ∘∘∘
 :EndSelect



End:
 ⎕se._cita.Success''
