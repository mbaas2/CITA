 lx arg;v;Env;subj;ext;r;z;s;cmd;y;log;wsFullReport;⎕RL;⎕ML;⎕IO;rc;path;NL;CITA_Log;dmx;NL
 ⍝ OFF with returncode 42: all is well, 43: error, 44: WS
 (0,⍳300)⎕TRACE'lx'
 Env←{2 ⎕NQ'.' 'GetEnvironment'⍵}  ⍝ get environment variable or cmdline
 DEBUG←1∨{((,'0')≢⍵)∧0<≢⍵:1 ⋄ 0}Env'CITADEBUG'
 :If DEBUG ⋄ ⎕←'TS.Start=',⎕TS ⋄ :EndIf
 :If DEBUG ⋄ ⎕←'PPID=' ⋄ ⎕SH'echo $PPID' ⋄ :EndIf
 :If DEBUG ⋄ ⎕←'CommandlineArgs:' ⋄ :EndIf
 :If DEBUG ⋄ ⎕←2 ⎕NQ'.' 'GetCommandlineArgs' ⋄ :EndIf
 :If (,'1')≡,2 ⎕NQ'.' 'GetEnvironment' 'WFR'
 :AndIf 14<+/1 0.1×2↑⊃(//)'.'⎕VFI 2⊃'.'⎕WG'APLVersion'   ⍝ RIDE Connections are detected from 14.1 onwards
     ⎕←'Waiting for RIDE'
     ai3←⎕AI[3]
     :Repeat
         z←(3501⌶)0
     :Until ⎕AI[3]>ai3+5000  ⍝ allow 5secs for RIDE to connect
     :OrIf z
     :If DEBUG ⋄ ⎕←'Waited ',(⍕⎕AI[3]-ai3),'ms, RIDE connected:',⍕z ⋄ :EndIf
 :EndIf

 :Trap DEBUG↓0
     :If 15<2 1⊃'.'⎕VFI 2⊃'.'⎕WG'aplversion'
        ⍝  2704⌶1   ⍝ save CONTINUE on "hang-up signals"  (suggested by AS, 210819)
        ⍝ disabled, because it causes "Cannot perform operation from within session namespace."
     :EndIf

     :If 0=⎕SE.⎕NC'UCMD'
         :If DEBUG ⋄ ⎕←'Loading session' ⋄ :EndIf
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
     :If DEBUG ⋄ ⎕←'COMMANDFOLDER=',Env'COMMANDFOLDER' ⋄ :EndIf
     :Trap DEBUG↓0
         :If DEBUG ⋄ ⎕←'COMMANDFOLDER=',⎕SE.Dyalog.Utils.Config'COMMANDFOLDER' ⋄ :EndIf
     :EndTrap
     d←Env'DYALOG'
     :Trap DEBUG↓0
         {}⎕SE.SALT.Set'cmddir ',(⎕SE.Dyalog.Utils.Config'COMMANDFOLDER'),(1⊃,⎕SE.SALTUtils.PATHDEL),d,'/SALT/spice'
     :Else
         ⍎'(⎕json⎕OPT''Compact''0) ⎕dmx'
     :EndTrap
     :If DEBUG ⋄ ⎕←'SALT.set cmddir=',⎕SE.SALT.Set'cmddir' ⋄ :EndIf
     :If DEBUG ⋄ ⎕←'lx. citaDEVT=',Env'citaDEVT' ⋄ :EndIf
 ⍝ set up ⎕SE._cita
     NL←⎕UCS 13
     :If 'on'≡⎕SE.SALTUtils.lCase Env'UDEBUG'
     :OrIf 1
         ⎕SE.UCMD'UDEBUG ON'
     :EndIf
     :If DEBUG ⋄ ⎕←'UDEBUG=',(1+⎕SE.SALTUtils.DEBUG)⊃'OFF' 'ON' ⋄ :EndIf
     :If DEBUG ⋄ ⎕←'Setting OUTPUT.Find' ⋄ :EndIf
     :Trap 0   ⍝ might not be present on older versions...
         :If DEBUG ⋄ ⎕←⎕SE.UCMD'output.find on -includequadoutput -timestamp' ⋄ :EndIf
     :Else
     ⎕←↑⎕dm
         ⍎'(⎕json⎕OPT''Compact''0) ⎕dmx'
     :EndTrap
     :trap 0
     ⎕SE.UCMD'GetTools4CITA ',⍕⎕THIS
     :else 
     ⎕←↑⎕dm
         ⍎'(⎕json⎕OPT''Compact''0) ⎕dmx'
     :endtrap
     ⎕ML←1
     ⎕IO←1
     ⎕PW←80  ⍝ seems to be the width of the Jenkins console
     rc←42  ⍝ returncode if everything was ok (errors will set rc to 43, ws FULL=44)
     CITA_Log←⎕SE._cita.GetCITA_Log 0 ⍝ initialise it with value from environment (later the var will override that...)
     path←{(⌽∨\⌽⍵∊'/\')/⍵}⎕WSID
     v←1⊃'.'⎕VFI 2⊃'.'⎕WG'aplversion'
     :If DEBUG ⋄ ⎕←'Cmdline: ',(∊' ',¨2 ⎕NQ'.' 'GetCommandLineArgs'),NL ⋄ :EndIf
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
         en=1:s ⎕SE._cita._LogStatus'wsfull' 44
         ⎕SE._cita.Error s
     }
     :If DEBUG ⋄ ⎕←'Deleting log-files...' ⋄ :EndIf
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
         :If DEBUG ⋄ ⎕←'ext=',ext ⋄ :EndIf
         :If DEBUG ⋄ ⎕←'mode=',Env'mode' ⋄ :EndIf
         :Select ext
         :CaseList '' '.dyalogtest',('DTest'≡Env'mode')/⊂ext
             :Trap DEBUG↓0
                 cmd←'DTest "',subj,'" -testlog="',(Env'testlog'),'" ',(Env'dtestmods '),' -off=2 -sessionlog=1' 
                 :If DEBUG ⋄ ⎕←'cmd=',cmd  ⋄ :endif
                 ⎕SE.UCMD cmd
                 :If DEBUG ⋄ ⎕←'subj=',subj ⋄ :EndIf
                 :If ⎕SE._cita.qNEXISTS s←(∊2↑⎕SE._cita.qNPARTS subj),'.log'
                     ⎕SE._cita.Failure 1⊃⎕SE._cita.qNGET s
                 :EndIf
                 ⎕SE._cita.Success''
             :Else
                 rc←21
                 ⎕←'Error executing test ',(1⊃⎕XSI),': '
                 ⎕←'⎕DMX='
                 ⎕←(⍎'(⎕json⎕OPT''Compact''0) ⎕dmx')    ⍝ avoid problems with 12.1 which can't tokenize ⎕DMX (saved in 12.1, executed in 18)
                 ⎕←'en=',⎕EN
                 subj HandleError' ]',cmd
             :EndTrap
             →0  ⍝ go back to 6 space prompt after running test
         :CaseList '.aplc' '.apln' '.dyalog'
             :If DEBUG ⋄ ⎕←']Load ',subj ⋄ :EndIf
             :Trap DEBUG↓ 0
                 r←⎕SE.SALT.Load subj   ⍝ load it
             :Else
                 subj HandleError']LOAD ',subj
             :EndTrap
             :If 3=⎕NC⍕r
                 →runFn
             :EndIf
             :If 3=⎕NC r,'.Run'
                 :Trap DEBUG↓0
                     :If 1=|1 1⊃(⎕AT r,'.Run')
                         :If DEBUG ⋄ ⎕←r,'.Run' ⋄ :EndIf
                         {}r⍎Run
                     :Else
                         :If DEBUG ⋄ ⎕←r,'⍎',Run ⋄ :EndIf
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
             :If DEBUG ⋄ ⎕←']LOAD ',subj ⋄ :EndIf
             :Trap DEBUG↓0
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
                 :Trap DEBUG↓0
                     :If DEBUG ⋄ ⎕←cmd ⋄ :EndIf
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
         :If DEBUG ⋄ ⎕←'No problems running user code' ⋄ :EndIf
         ⎕SE._cita.Success''
     :ElseIf 0<⎕SE._cita.tally subj←Env'RunUCMD'
         :If DEBUG ⋄ ⎕←'Executing UCMD >',subj,'<'
         ⎕←'tally=',⎕SE._cita.tally subj
         ⎕←'alt1: "',(2⎕nq'.' 'GetEnvironment' 'RunUCMD'),'"'
         ⎕←'alt2: "',(Env'RunUCMD'),'"'
         :EndIf
         :If DEBUG ⋄ ⎕←'CommandLineArgs:' ⋄  ⎕←2 ⎕NQ'.' 'GetCommandLineArgs' ⋄:EndIf
         :Trap DEBUG↓0
             :If DEBUG ⋄ ⎕←']',subj ⋄ :EndIf
             res←⎕SE.UCMD subj
             :If DEBUG ⋄ ⎕←'Log=',res ⋄ :EndIf
         :Else
             subj HandleError ⎕←'Error executing UCMD',NL,∊⎕DM,¨⊂NL
         :EndTrap
         :If DEBUG ⋄ ⎕←'The last commands...' ⋄ :EndIf
         :Trap DEBUG↓0
             ⎕←'res=',res
             :If res[1]='─'   ⍝ success indicator:⋄:endif
                 :If DEBUG ⋄ ⎕←'Calling cita.Success' ⋄ :EndIf
                 ⎕SE._cita.Success''
             :Else
                 :If DEBUG ⋄ ⎕←'Calling cita.Failure' ⋄ :EndIf
                 ⎕SE._cita.Failure''
             :EndIf
         :Else
             ⎕←⍎'(⎕json',(⍎(1+82=⎕DR' ')⊃'⎕ucs 9056' '⎕OPT'),'''Compact''0)⎕dmx'
         :EndTrap
     :Else
         ⎕←'No idea why you called me...!'
         ⎕←'Hint: could not find "CITAtest" in environment...'
         ∘∘∘
     :EndIf
 :Else
     ⎕←⍎'(⎕json',(⍎(1+82=⎕DR' ')⊃'⎕ucs 9056' '⎕OPT'),'''Compact''0)⎕dmx'
     ⎕OFF
 :EndTrap
