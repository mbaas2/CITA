 lx arg;v;Env;subj;ext;r;z;s;cmd;y;log;wsFullReport;⎕RL;⎕ML;⎕IO;rc;path;NL;CITA_Log
 ⍝ OFF with returncode 42: all is well, 43: error, 44: WS FULL
 :If 0∧arg=0  ⍝ setup a temp ns in ⎕SE and execute things there (to avoid problems with tests doing "DBuild -c")
     t←'tmp' ⋄ cnt←''
     :While 9=⎕SE.⎕NC t,cnt ⍝
         cnt←⍕1+2⊃⎕VFI'0',cnt
     :EndWhile
     ns←'⎕SE.',t,cnt
     ns ⎕NS(⎕NL-⍳9)
     {2 ⎕NQ'⎕se' 'Keypress'⍵}¨ns,'.lx 1',⊂'ER'   ⍝ ensure that we execute lx by triggering a "clean call"
     →0
 :EndIf
 :if 0=⎕se.⎕nc'UCMD'
   d←2⎕nq'.' 'GetEnvironment' 'DYALOG'
   ⍝⎕se.File←'/opt/mdyalog/18.0/64/unicode/default.dse'
   ⎕se.File←d,'/default.dse'
  2⎕nq'⎕se' 'FileRead'
  ⎕dl 1 ⍝ make sure we don't have a timing issue
⍝    ⎕←'cmddir=',⎕se.SALT.Set'cmddir'
⍝    ⎕←'COMMANDFOLDER=',⎕se.Dyalog.Utils.Config'COMMANDFOLDER'
⍝    ⎕se.SALT.Set'cmddir ',⎕se.Dyalog.Utils.Config'COMMANDFOLDER'
⍝ ⎕←'cmddir=',⎕se.SALT.Set'cmddir'
    ⎕SE.Dyalog.Callbacks.WSLoaded 1 
⍝  ⎕se.UCMD'ureset'
 ⍝⎕←⎕se.UCMD'-?'
⍝  ⎕←2⎕nq'.' 'GetEnvironment' 'COMMANDFOLDER'
⍝  ⎕←'exists=',⍕⍎'⎕nexists ''',(2⎕nq'.' 'GetEnvironment' 'COMMANDFOLDER'),''''
  :endif
 ⍝ set up ⎕SE._cita
 ⎕SE.UCMD'GetTools4CITA ',⍕⎕this
 NL←⎕UCS 13
 ⎕ML←1
 ⎕IO←1
 rc←42  ⍝ returncode if everything was ok (errors will set rc to 43, ws FULL=44)
 CITA_Log←⎕SE._cita.GetCITA_Log 0 ⍝ initialise it with value from environment (later the var will override that...)
 path←{(⌽∨\⌽⍵∊'/\')/⍵}⎕WSID
 v←1⊃'.'⎕VFI 2⊃'.'⎕WG'aplversion'
 Env←{2 ⎕NQ'.' 'GetEnvironment'⍵}  ⍝ get environment variable or cmdline
 HandleError←{
     ⎕←'en=',en←⎕EN   ⍝ save it before any trapped errors inside this fn cvhange it
     s←'Loaded File "',⍺,'". Executing "',⍵,'" crashed with a error: '
     sink←⎕EX'wsFullReport'
     s,←∊⎕DM,¨⎕TC[3]
     s,←{⎕ML←1 ⋄ ⍵≠1:'' ⋄ 1::'WS FULL gathering list of vars' ⋄ rep←res←⊃⍪/⊃,/{((⊂⍕⍵),¨'.',¨↓nl),[1.5]⍵.⎕SIZE nl←⍵.⎕NL⍳9}⎕SE._cita.swise¨# ⎕SE ⋄ j←(20⌊1↑⍴rep)↑⍒rep[;2] ⋄ ,⍕rep[j;],⊂NL}en
     dmx←{0::'' ⋄ ⎕DMX}0  ⍝ can't use ⎕DMX. in next line because this code is saved with v12 that does not know ⎕DMX
     s,←{0::{0::'' ⋄ 'DMX=',∊dmx.({0::'' ⋄ ⍵,':',(⍎⍵),⎕TC[3]}¨⎕NL ¯2)}'' ⋄ 'DMX=',∊⎕JSON dmx}''   ⍝ various fallsbacks so that this code can execute even on v12 (where it does not do anything - but also does not fail)
     en=1:s ⎕SE._cita._LogStatus'wsfull' 44
     ⎕SE._cita.Error s
 }
 ⎕←'Deleting log-files...'
 1 ⎕SE._cita.qNDELETE ⎕←(∊2↑⎕SE._cita.qNPARTS CITA_Log),'.*'
 wsFullReport←(500⍴⊂'PlaceHolder'),[1.5]1000000     ⍝ reserve a few bytes for our wsfullreport - just in case...
 :If udebug←'on'≡⎕SE._cita.lc Env'UDEBUG'
     {}⎕SE.UCMD'UDEBUG ON'  ⍝ only during testing...
 :EndIf

⍝ run the code
 :If 0<⎕SE._cita.tally subj←Env'CITATest'   ⍝ get test subject
     ext←3⊃⎕SE._cita.qNPARTS subj
     :If CITA_Log≡'.log'
         :If ~0∊⍴t←Env'testlog' ⋄ CITA_Log←t
         :Else ⋄ CITA_Log←∊2↑⎕SE._cita.qNPARTS subj
         :EndIf
     :EndIf
     ⎕←'ext=',ext
     ⎕←'mode=',Env'mode'
     :Select ext
     :CaseList '' '.dyalogtest',('DTest'≡Env'mode')/⊂ext
         :Trap 0
             ⎕←cmd←'DTest "',subj,'" -testlog="',(Env'testlog'),'" ',(Env'dtestmods ')
             ⎕SE.UCMD cmd
             rc←20
         :Else
             rc←21
             ⎕←'Error during ',(1⊃⎕xSI).,': ',(⍎'(⎕json⎕OPT''Compact''0) ⎕DMX')    ⍝ avoid problems with 12.1 which can't tokenize ⎕DMX (saved in 12.1, executed in 18)
             ⎕←'en=',⎕EN
             subj HandleError' ]',cmd
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
             :EndTrap
         :Else
             s←⎕←'File "',subj,'" did not define "Run" function in ns/class'
             ⎕SE._cita.Failure s
         :EndIf
     :Case '.aplf'
         ⎕←']LOAD ',subj
         :Trap 0
             r←⎕SE.SALT.Load subj   ⍝ load it
         :Else
             subj HandleError' ]LOAD ',subj
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
             :EndTrap
         :Else
             s←⎕←'Loading File "',subj,'" did not give us a function. Result was: "',r,'"'
             ⎕SE._cita.Failure s
         :EndIf
     :Else
         ⎕←'Not sure what to do with ext=',ext
         ∘∘∘
     :EndSelect
End:
     ⎕←'No problems running user code'
     ⎕SE._cita.Success''
 :ElseIf 0<⎕SE._cita.tally subj←Env'RunUCMD'
     :Trap udebug↓0
         ⎕←']',subj
         ⎕SE.UCMD subj
     :Else
         subj HandleError ⎕←'Error executing UCMD',NL,∊⎕DM,¨⊂NL
     :EndTrap
    ⍝ we produce no status-file after running a UCMD and we don't automatically )OFF!
 :Else
     ⎕←'No idea why you called me! :('
     ∘∘∘
 :EndIf