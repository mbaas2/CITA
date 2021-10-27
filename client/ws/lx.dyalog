 lx arg;v;Env;subj;ext;r;z;s;cmd;y;log;wsFullReport;⎕RL;⎕ML;⎕IO;rc;path;NL;CITA_Log;dmx
 ⍝ OFF with returncode 42: all is well, 43: error, 44: WS
 ⎕←'TS.Start=',⎕TS
 ⎕←'PPID='⋄⎕sh'echo $PPID'
 :If (,'1')≡,2 ⎕NQ'.' 'GetEnvironment' 'WFR'
 :andif 14<+/1 .1×2↑⊃(//)'.'⎕vfi 2⊃'.'⎕wg'APLVersion'   ⍝ RIDE Connections are detected from 14.1 onwards
     ⎕←'Waiting for RIDE'
     ai3←⎕AI[3]
     :Repeat
         z←(3501⌶)0
     :Until ⎕AI[3]>ai3+5000  ⍝ allow 5secs for RIDE to connect
     :OrIf z
     ⎕←'Waited ',(⍕⎕AI[3]-ai3),'ms, RIDE connected:',⍕z
 :EndIf

⍝  (0,⍳200)⎕TRACE'lx'
 :Trap 0/0
     Env←{2 ⎕NQ'.' 'GetEnvironment'⍵}  ⍝ get environment variable or cmdline
     :If 15<2 1⊃'.'⎕VFI 2⊃'.'⎕WG'aplversion'
        ⍝  2704⌶1   ⍝ save CONTINUE on "hang-up signals"  (suggested by AS, 210819)
        ⍝ disabled, because it causes "Cannot perform operation from within session namespace."
     :EndIf

     :If 0=⎕SE.⎕NC'UCMD'
         ⎕←'Loading session'
         d←Env'DYALOG'
   ⍝⎕se.File←'/opt/mdyalog/18.0/64/unicode/default.dse'
         ⎕SE.File←d,'/default.dse'
         :If 0≠2 ⎕NQ'⎕se' 'FileRead'
             ⎕←s←'Problem reading session file ',⎕SE.File
             ⍞←s←'Problem reading session file ',⎕SE.File
             ⎕SE._cita.Error s
         :Else
             ⎕←'Successfully read session file ',⎕SE.File
             ⍞←'Successfully read session file ',⎕SE.File
         :EndIf
         ⎕DL 1 ⍝ make sure we don't have a timing issue
         ⎕SE.Dyalog.Callbacks.WSLoaded 1
         :If 0=⎕SE.⎕NC'UCMD'
             ⎕SE._cita.Error'⎕SE.UCMD not present - even though we loaded ',⎕SE.File
         :EndIf
     :EndIf
     ⎕←'COMMANDFOLDER=',Env'COMMANDFOLDER'
     :trap 0
     ⎕←'COMMANDFOLDER=',⎕SE.Dyalog.Utils.Config'COMMANDFOLDER'
     :endtrap
     :Trap 0
         {}⎕SE.SALT.Set'cmddir ',⎕SE.Dyalog.Utils.Config'COMMANDFOLDER'
     ⎕←'SALT.set ',⎕SE.SALT.Set'cmddir'
     :EndTrap
     ⎕←'lx. citaDEVT=',Env'citaDEVT'
 ⍝ set up ⎕SE._cita
     NL←⎕UCS 13
     :If 'on'≡⎕se.SALTUtils.lCase Env'UDEBUG'
         ⎕SE.UCMD'UDEBUG ON'
     :EndIf
     ⎕←'UDEBUG=',(1+⎕se.SALTUtils.DEBUG)⊃'OFF' 'ON'
     :Trap 0   ⍝ might not be present on older versions...
      ⎕SE.UCMD'output.find on -includequadoutput -ts'
     :EndTrap
     ⎕SE.UCMD'GetTools4CITA ',⍕⎕THIS
     ⎕ML←1
     ⎕IO←1
     ⎕PW←80  ⍝ seems to be the width of the Jenkins console
     rc←42  ⍝ returncode if everything was ok (errors will set rc to 43, ws FULL=44)
     CITA_Log←⎕SE._cita.GetCITA_Log 0 ⍝ initialise it with value from environment (later the var will override that...)
     path←{(⌽∨\⌽⍵∊'/\')/⍵}⎕WSID
     v←1⊃'.'⎕VFI 2⊃'.'⎕WG'aplversion'
     ⎕←'Cmdline: ',(∊' ',¨2 ⎕NQ'.' 'GetCommandLineArgs'),NL
     HandleError←{
         ⎕←'en=',en←⎕EN   ⍝ save it before any trapped errors inside this fn cvhange it
         s←'Loaded File "',⍺,'".',NL
         s,←'Cmdline: ',(∊' ',¨2 ⎕NQ'.' 'GetCommandLineArgs'),NL
         s,←'Executing "',⍵,'" crashed with a error: '
         sink←⎕EX'wsFullReport'
         s,←∊⎕DM,¨⎕TC[3]
         s,←{⎕ML←1 ⋄ ⍵≠1:'' ⋄ 1::'WS FULL gathering list of vars' ⋄ rep←res←⊃⍪/⊃,/{((⊂⍕⍵),¨'.',¨↓nl),[1.5]⍵.⎕SIZE nl←⍵.⎕NL⍳9}⎕SE._cita.swise¨# ⎕SE ⋄ j←(20⌊1↑⍴rep)↑⍒rep[;2] ⋄ ,⍕rep[j;],⊂NL}en
         dmx←{0::'' ⋄ ⍎'⎕DMX'}0  ⍝ can't use ⎕DMX because this code is saved with v12 that does not know ⎕DMX
         s,←{0::{0::'' ⋄ 'DMX=',∊dmx.({0::'' ⋄ ⍵,':',(⍎⍵),⎕TC[3]}¨⎕NL ¯2)}'' ⋄ 'DMX=',∊(⍎'(⎕JSON',((1+820 ⎕DR' ')⊃((⎕UCS 9055+80=⎕DR' ')'⎕OPT',),'''Compact''0) dmx'),NL}''   ⍝ various fallsbacks so that this code can execute even on v12 (where it does not do anything - but also does not fail)
         s,←'SALTUtils.dmx=',⍎'{0::''N/A'' ⋄ (⎕JSON',((1+82=⎕DR' ')⊃(⎕UCS 9056)'⎕OPT'),'''Compact''0)⎕se.SALTUtils.dmx}0'
         ⎕←'s=',s
         en=1:s ⎕SE._cita._LogStatus'wsfull' 44
         ⎕SE._cita.Error s
     }
     ⎕←'Deleting log-files...'
     1 ⎕SE._cita.qNDELETE ⎕←(∊2↑⎕SE._cita.qNPARTS CITA_Log),'.*'



     ⍝TODO: remove comment! | wsFullReport←(500⍴⊂'PlaceHolder'),[1.5]1000000     ⍝ reserve a few bytes for our wsfullreport - just in case...



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
             :Trap 0/0
                 ⎕←'cmd=',cmd←'DTest "',subj,'" -testlog="',(Env'testlog'),'" ',(Env'dtestmods '),' -off=2'
                 ⎕SE.UCMD cmd
                 ⎕←'lx.Testlog='
                 ⎕←⍎'0(⎕ninfo⎕OPT''Wildcard''1)((Env''testlog''),''.*'')'
                 :If ⎕SE._cita.qNEXISTS Env'testlog'  ⍝ test failed
                     ⎕SE._cita.Failure 1⊃⎕NGET Env'testlog'
                 :EndIf
                 ⎕SE._cita.Success''
             :Else
                 rc←21
                 ⎕←'Error executing test ',(1⊃⎕XSI),': ',
                 ⎕←'SALTUtils.dmx='
                 ⎕←(⍎'(⎕json⎕OPT''Compact''0) ⎕SE.SALTUtils.dmx')    ⍝ avoid problems with 12.1 which can't tokenize ⎕DMX (saved in 12.1, executed in 18)
                 ⎕←'en=',⎕EN
                 subj HandleError' ]',cmd
             :EndTrap
             →0  ⍝ go back to 6 space prompt after running test
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
         ⎕←'Executing UCMD ',subj
         ⎕←'CommandLineArgs:'
         ⎕←2 ⎕NQ'.' 'GetCommandLineArgs'
         :Trap 0/0
             ⎕←']',subj
             res←⎕SE.UCMD subj
             ⎕←'Log=',res
         :Else
             subj HandleError ⎕←'Error executing UCMD',NL,∊⎕DM,¨⊂NL
         :EndTrap
         ⎕←'The last commands...'
         :Trap 0/0
             ⎕←'res=',res
             :If res[1]='─'   ⍝ success indicator
                 ⎕←'Calling cita.Success'
                 ⎕SE._cita.Success''
             :Else
                 ⎕←'Calling cita.Failure'
                 ⎕SE._cita.Failure''
             :EndIf
         :Else
             (⊂⍎'(⎕json',(⍎(1+82=⎕DR' ')⊃'⎕ucs 9056' '⎕OPT'),'''Compact''0)⎕dmx')⎕NPUT(∊2↑⎕NPARTS ⎕WSID),,'<.error.>,ZI4,ZI2,ZI2,<_>,ZI2,ZI2,ZI3'⎕FMT 1 6⍴⎕TS
         :EndTrap
     :Else
         ⎕←'No idea why you called me...!'
         ∘∘∘
     :EndIf

 :Else
     (⊂⍎'(⎕json',(⍎(1+82=⎕DR' ')⊃'⎕ucs 9056' '⎕OPT'),'''Compact''0)⎕dmx')⎕NPUT(∊2↑⎕NPARTS ⎕WSID),,'<.error.>,ZI4,ZI2,ZI2,<_>,ZI2,ZI2,ZI3'⎕FMT 1 6⍴⎕TS
     ⎕OFF
 :EndTrap
