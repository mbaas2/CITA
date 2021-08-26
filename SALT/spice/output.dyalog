:Namespace outputspec ⍝ V1.44
⍝ System user Command
⍝
⍝ 2015 05 21 Adam: NS header
⍝ 2016 05 29 DanB: added cmd LastResult and modified box to include a button
⍝ 2016 09 03 DanB: prevent VALERR line 7
⍝ 2016 10 28 DanB: changed SD to reflect better screen dimensions
⍝ 2017 02 21 Adam: Proper ]Box ToolButton and ]LastResult -pfkey → -button
⍝ 2017 02 22 Adam: 2 × -button → -pfkey=, ]?Box overhaul, install button at 1st call and keep it, ]?LastResult overhaul
⍝ 2017 02 23 Adam: Box added new fns and ops for 16.0 and ⎕Uhhhh, added hint and tip to button, do not check for button on non-win, help updates
⍝ 2017 03 02 Adam: disabled ]lastresult altogether and ]box -pfkey
⍝ 2017 03 06 Adam: fix missing trees
⍝ 2017 03 19 Adam: fix ]???rows
⍝ 2017 03 27 Adam: Silence ]rows
⍝ 2017 05 16 JohnS: ]box remove -chars, do not switch on when just changing settings, implement -t=def
⍝ 2017 05 26 Adam: ]???rows note about when cutting occurs
⍝ 2017 06 17 Adam: ]fn.findoutput → ]output.find
⍝ 2017 07 11 Adam: ]?display symbol legend
⍝ 2018 03 29 JohnS: ]rows: dots extend across whole window
⍝ 2018 04 04 Adam: Enable box button
⍝ 2018 04 18 Adam: ]??cmd → ]cmd -??
⍝ 2018 04 30 JohnS: limited length of ]rows folding dots ······ to ⎕PW
⍝ 2018 05 01 Adam: help tweaks
⍝ 2019 02 04 Adam: help
⍝ 2020 04 28 Adam: [17929] Fix train trees with spaces
⍝ 2020 05 26 Adam: [9376,18007] Filter when tracing and from ]output.find; remove doubled ... when interrupted
⍝ 2020 05 27 Adam: Add Hoof (○¨)
⍝ 2020 06 01 Adam: Add SessionTrace with ns path
⍝ 2020 06 02 Adam: [18126] normalise display of LF, make V17.1 compatible, allow output.find to say [0]
⍝ 2020 06 03 Adam: Handle missing stack frame, avoid trailing spaces
⍝ 2020 06 08 Adam: Make use of ⎕PW semi-global
⍝ 2020 06 11 Adam: [18236] Fix Box button callback
⍝ 2020 07 20 Adam: trap and resignal on WS FULL after error

    ⎕io← ⎕ml←1
    OUTSpace ← '⎕se.Dyalog.Out' ⋄ Var←{0::⍵ ⋄ ⎕se.SALTUtils.LastResultVarName}⍬⊤⍬
    enableLastResult←0
    enableBoxPfkey←0
    enableBoxButton←1

    ∇ r←List;cmds           ⍝ Name, group, short description and parsing rules
      cmds←'LastResult' 'Box' 'Boxing' 'Rows' 'Find'
      r←{⎕NS''}¨cmds        ⍝ space for each cmd.
      r.Name←cmds
      r.Group←⊂'Output'
     
      r[cmds⍳⊂'LastResult'].Desc←⊂'Record Last session output'
      r[cmds⍳'Box' 'Boxing'].Desc←⊂'Display output with borders indicating shape, type and structure'
      r[cmds⍳⊂'Rows'].Desc←'Cut, wrap, fold or extend the display of output lines to fit the Session window'
      r[cmds⍳⊂'Find'].Desc←'Precede output with a reference to the line of code that generated it'
     
      r[cmds⍳⊂'LastResult'].Parse←'1S  -pfkey='
      r[cmds⍳'Box' 'Boxing'].Parse←⊂'1S -fns="off on" -style="min mid max" -trains="box tree parens def"',enableBoxPfkey/' -pfkey='
      r[cmds⍳⊂'Rows'].Parse←'1S -fns="off on" -style="long cut wrap" -dots= -fold='
      r[cmds⍳⊂'Find'].Parse←'1 -includequadoutput'
     
      r/⍨←enableLastResult∨cmds≢¨⊂'LastResult'
    ∇

    ∇ r←Run(Cmd Input);arg;out;on;cb;O;U;subs;num;PFkey;cap;prev;band;obj
    ⍝ Setup a space for the callback program to run. If it does exist no new space will be created.
      O←⍎OUTSpace ⎕NS'Filter' 'Box' 'Rows' 'SD' 'Dft' 'pfnops' 'flipBox' 'SetCallback' 'OUTSpace' ⍝'BoxButtonCaptions'
      U←⎕SE.Dyalog.Utils                          ⍝ for lcase, disp, etc.
      r←'Was'                                     ⍝ fix for [12109]
     
      :If 0∊⎕NC↑subs←'O.B' 'O.R' 'O.L' 'O.F'      ⍝ spaces for Box, Rows, LastResult and Find
          ⎕NS∘''¨subs                             ⍝ create state-spaces.
          O.(B R).(state fns)←⊂⊂'off'             ⍝ all states OFF
          O.B.(style trains)←'min' 'box'          ⍝ default args for Boxing.
          O.R.(style fold dots)←'long' 'off' '·'  ⍝ default args for Rows.
          O.L.state←O.F.state←'off'               ⍝ don't show where output is produced in programs by default
          O.F.includequadoutput←0                 ⍝ don't show ⎕ output by default
          O.L.PFKey←0                             ⍝ no PF key associated with last result
      :EndIf
     
      :Select Cmd
      :CaseList 'Box' 'Boxing'
     
          :If 0=⎕NC'O.B.trains'                   ⍝ Update Tech Preview session
              O.B.trains←'box'                    ⍝ default to boxed fns
          :EndIf
     
          arg←U.lcase⊃Input.Arguments,⊂''         ⍝ single optional argument.
     
          :If enableBoxButton
          :AndIf ⎕SE.SALTUtils.WIN
          :AndIf 0=⎕SE.⎕NC Button ⍝ Add button to toolbar if missing (old BUILDSE)
              Button ⎕WC'ToolButton' 'Boxing'('Hint' 'Toggle boxed display')('Tip' 'Boxing on/off')('Style' 'Check')('State'(O.B.state≡'on'))('ImageIndex' 12)('Event' 'Select'(OUTSpace,'.flipBox'))
              ⎕←'Toolbar button added. Save your session to make permanent.'
          :EndIf
     
          :Select arg
          :CaseList 'off' 'on'
              r←'Was ',U.ucase O.B.state
              O.B.state←arg
              :If enableBoxButton
              :AndIf ⎕SE.SALTUtils.WIN
              :AndIf 0≠⎕NC Button
                  Button ⎕WS'State'(O.B.state≡'on')
              :EndIf
          :Case ,'?'
              r←']boxing ',U.ucase O.B.state
              r,←' -style=',O.B.style
              r,←' -trains=',O.B.trains
              r,←' -fns=',O.B.fns
              ⍝r,←' -chars=',O.B.chars
          :Case ''
              :If 0∧.≡Input.(style trains fns)
              ⍝:If 0∧.≡Input.(style trains chars fns)
                  r←'Is ',U.ucase O.B.state
              :EndIf
          :Case 'reset'
              O.B.(style trains fns)←'min' 'box' 'off'
              ⍝O.B.(style trains fns chars)←'min' 'box' 'off' 'regular'
              r←']boxing ',U.ucase O.B.state
              r,←' -style=',O.B.style
              r,←' -trains=',O.B.trains
              r,←' -fns=',O.B.fns
              ⍝r,←' -chars=',O.B.chars
          :Else
              r←'Arguments: ON OFF RESET ?'
          :EndSelect
     
          :If Input.style≢0                 ⍝ -style=min mid max
              r,←' -style=',O.B.style
              O.B.style←Input.style
              ⍝O.B.state←⊃(arg≡'off')⌽'on' 'off'
          :EndIf
     
          :If Input.trains≢0                ⍝ -trains=box tree parens
              r,←' -trains=',O.B.trains
              O.B.trains←Input.trains
              ⍝O.B.state←⊃(arg≡'off')⌽'on' 'off'
          :EndIf
     
⍝          :If Input.chars≢0                 ⍝ -chars=regular ascii
⍝              r,←' -chars=',O.B.chars
⍝              O.B.chars←Input.chars
⍝          :EndIf
     
          :If Input.fns≢0                   ⍝ -fns=off on
              r,←' -fns=',O.B.fns
              O.B.fns←Input.fns
          :EndIf
     
          :If enableBoxPfkey
          :AndIf Input.pfkey≢0
              :If ⎕SE.SALTUtils.WIN
                  PFkey←{∨/⍵∊0 1:⍬ ⋄ 0=n←n×0 12≠.<n←⌊⊢/∊⎕VFI ⍵~ST←'sScCaA':⍬ ⋄ ⊂'Accelerator'((111+n),+/∪1 1 2 2 4 4 0[ST⍳⍵])}Input.Switch'pfkey'
                  Button ⎕WS PFkey
                  ⎕←'Function key has been assigned. Save your session to make permanent.'
              :Else
                  ⎕←'The modifier -pfkey only works under Windows'
              :EndIf
          :EndIf
     
      :Case 'Rows'                          ⍝ row wrapping/cropping.
          :If 0=⎕NC'O.R.style'              ⍝ Update Tech Preview session
              :Select O.R.state
              :CaseList 'cut' 'long' 'wrap'
                  O.R.(style state←state'on')
              :Else
                  O.R.(style state←'long' 'off')
              :EndSelect
          :EndIf
          arg←U.lcase⊃Input.Arguments,⊂''   ⍝ single optional argument.
     
          :Select arg
          :CaseList 'off' 'on'
              r←'Was ',U.ucase O.R.state
              O.R.state←arg
          :Case r←''
              :If 0∧.≡Input.(style fold dots fns)
                  r←'Is ',U.ucase O.R.state
              :EndIf
          :Case ,'?'
              r←']rows ',U.ucase O.R.state
              r,←' -style=',⍕O.R.style
              r,←' -fns=',O.R.fns
              r,←' -dots=',O.R.dots
              r,←' -fold=',⍕O.R.fold
          :Else
              r←'Arguments: ON OFF ?'
          :EndSelect
     
          :If Input.style≢0                 ⍝ -style=long cut wrap
              r,←(3××⍴r)↓'was -style=',O.R.style
              O.R.style←Input.style
              O.R.state←⊃(arg≡'off')⌽'on' 'off'
          :EndIf
     
          :If Input.fold≢0                 ⍝ -fold=off, 0..9
              :If ~(⊂Input.fold)∊,¨⎕D,⊂'off'
                  r←'* Command Execution Failed: fold must be: off, 0 .. 9'
                  :Return
              :End
              r,←(3××⍴r)↓'was -fold=',O.R.fold
              O.R.fold←Input.fold
              O.R.state←⊃(arg≡'off')⌽'on' 'off'
          :EndIf
     
          :If Input.dots≢0                  ⍝ -dots=.
              r,←(3××⍴r)↓'was -dots=',O.R.dots
              O.R.dots←⊃Input.dots,'·'      ⍝ -dots="" : restore default
          :EndIf
     
          :If Input.fns≢0                   ⍝ -fns=off on
              r,←(3××⍴r)↓'was -fns=',O.R.fns
              O.R.fns←Input.fns
          :EndIf
     
      :Case 'Find'
          arg←U.lcase⊃Input.Arguments,⊂''   ⍝ single optional argument.
          :Select arg
          :CaseList 'on' 'off'
              r←'Was ',O.F.state
              O.F.state←arg ⋄ O.F.includequadoutput←Input.includequadoutput
          :Case 0 1/¨'?'
              r←'Is ',O.F.state
          :Else
              r←'Arguments: ON OFF ?'
          :EndSelect
     
      :Case 'LastResult'
        ⍝ Set ⎕SE.<global var> to contain the last result and possibly recalled with a PFkey
          arg←U.lcase⊃Input.Arguments,⊂''   ⍝ single optional argument.
          :Select arg
          :CaseList 'on' 'off'
              r←'Was ',prev←O.L.state
              {⍵≠0:_←''⎕PFKEY ⍵}O.L.PFKey ⋄ O.L.PFKey←0 ⍝ disable previous PF key in case new one assigned
              :If 'on'≡O.L.state←arg
                  PFkey←{∨/⍵∊0 1:0 ⋄ 0=n←n×0 12≠.<n←⌊⊢/∊⎕VFI ⍵~ST←'sScCaA':0 ⋄ n+12×+/∪1 1 2 2 4 4 0[ST⍳⍵]}
                  :If 0≠num←PFkey Input.pfkey
                      O.L.PFKey←num⊣Var ⎕PFKEY num
                      ⎕←'PFkey has been set. Save your session to make permanent.'
                  :EndIf
                  ⍎(0∊⎕NC Var)/Var,'←⊂''(no result yet)'''
              :Else ⋄ ⎕EX Var
              :EndIf
          :Case 0 1/¨'?'
              r←'Is ',U.ucase O.L.state
          :Else
              r←'Arguments: ON OFF ? modifier -pfkey='
          :EndSelect
     
      :EndSelect
      on←O.(B R F L).state∨.≢⊂'off'             ⍝ any active?
     
      SetCallback on
    ∇

      SetCallback←{
          cb←⊃⍵↓0(OUTSpace,'.Filter')
          '⎕se'⎕WS'Event'('SessionPrint'cb),⎕SE.SALTUtils.V18/⊂'SessionTrace'cb
      }

    ∇ r←level Help Cmd;⎕ML;lev2;n;h;h1;h2
      r←⍬
      :Select Cmd
      :CaseList 'Box' 'Boxing'
          r,←⊂'Display output with borders indicating shape, type and structure'
          r,←⊂'    ]',Cmd,' [on|off|reset|?] [-style={min|mid|max}] [-trains={box|tree|parens|def}] [-fns={off|on}]',' [-pfkey=[S][C][A]<n>]'/⍨enableBoxPfkey∧⎕SE.SALTUtils.WIN
          r,←⊂''
          :If 0=level
              r,←⊂']',Cmd,' -?? ⍝ for more information and examples'
          :Else ⍝ 1≤level
              level+←1
              :If 1=level
                  r,←⊂'Argument is "" to query on/off state, "on" to activate, "off" to disable, "reset" to restore factory settings, "?" to query full state.'
              :Else
                  r,←⊂'Argument is one of:'
                  r,←⊂'    ""        query on/off state only'
                  r,←⊂'    "on"      activate boxing'
                  r,←⊂'    "off"     disable boxing'
                  r,←⊂'    "reset"   restore factory settings: -style=min -trains=box -fns=off'⍝ -chars=regular'
                  r,←⊂'    "?"       query current state including modifiers'
                  r,←⊂''
              :EndIf
              r,←⊂'-style={min|mid|max}  amount of diagram detail'
              :If 2≤level
                  r,←⊂'    ┌───┬──────┐    ┌→──┬──────┐    ┌→───────────────┐'
                  r,←⊂'    │min│boxing│    │mid│boxing│    │ ┌→──┐ ┌→─────┐ │'
                  r,←⊂'    └───┴──────┘    └──→┴─────→┘    │ │max│ │boxing│ │'
                  r,←⊂'                                    │ └───┘ └──────┘ │'
                  r,←⊂'    min:  no border decoration      └∊───────────────┘'
⍝                  r,←⊂'    min:  no border decoration'
                  r,←⊂'    mid:  axes are indicated as follows:'
                  r,←⊂'            ↓  leading axis   (length>0)'
                  r,←⊂'            →  trailing axis  (length>0)'
                  r,←⊂'            ⌽  leading axis   (length=0)'
                  r,←⊂'            ⊖  trailing axis  (length=0)'
                  r,←⊂'            ⍒  multiple leading axes'
                  r,←⊂'          content types are indicated as follows:'
                  r,←⊂'            ~  numeric'
                  r,←⊂'            ─  character'
                  r,←⊂'            #  namespace'
                  r,←⊂'            ∇  ⎕OR'
                  r,←⊂'            +  mixed'
                  r,←⊂'    max:  axes are indicated as follows:'
                  r,←⊂'            ↓  leading axes   (length>0)'
                  r,←⊂'            →  trailing axis  (length>0)'
                  r,←⊂'            ⌽  leading axes   (length=0)'
                  r,←⊂'            ⊖  trailing axis  (length=0)'
                  r,←⊂'          content types are indicated as follows:'
                  r,←⊂'            ∊  nested'
                  r,←⊂'            ~  numeric'
                  r,←⊂'            ─  character'
                  r,←⊂'            #  namespace'
                  r,←⊂'            ∇  ⎕OR'
                  r,←⊂'            +  mixed'
                  ⍝r,←⊂''
                  r,←⊂'NOTES:'
                  r,←⊂'    ∘  For mid and max, content is prototypical if any axis has length=0.'
                  r,←⊂'    ∘  -style=mid is similar to always using ]Disp'
                  r,←⊂'    ∘  -style=max is similar to always using ]Display'
                  r,←⊂''
              :EndIf
              r,←⊂'-trains={box|tree|parens|def}  display style of trains and derived functions'
              :If 2≤level
                  r,←⊂'    Display of +⌿÷≢ with -trains=...'
                  r,←⊂'        box          tree     parens    def '
                  r,←⊂'    ┌─────┬─┬─┐      ┌─┼─┐    (+⌿)÷≢   +⌿÷≢'
                  r,←⊂'    │┌─┬─┐│÷│≢│      ⌿ ÷ ≢'
                  r,←⊂'    ││+│⌿││ │ │    ┌─┘'
                  r,←⊂'    │└─┴─┘│ │ │    +'
                  r,←⊂'    └─────┴─┴─┘'
                  r,←⊂'    NOTE:  -trains=parens uses default form if any component needs multiple lines to display.'
                  r,←⊂''
              :EndIf
              r,←⊂'-fns={off|on}  diagram output from running functions'
              :If 2≤level
                  r,←⊂'    Display of {⌽⎕←⍵}''hello'' ''world'' with -fns=...'
                  r,←⊂'         off               on'
                  r,←⊂'     hello  world    ┌─────┬─────┐'
                  r,←⊂'    ┌─────┬─────┐    │hello│world│'
                  r,←⊂'    │world│hello│    └─────┴─────┘'
                  r,←⊂'    └─────┴─────┘    ┌─────┬─────┐'
                  r,←⊂'                     │world│hello│'
                  r,←⊂'                     └─────┴─────┘'
                  r,←⊂''
              :EndIf
⍝              r,←⊂'-chars={regular|ascii} selects character set for drawing'
⍝              :If 2≤level
⍝                  r,←⊂'    ┌───────┬─────┐    .-----.-----.'
⍝                  r,←⊂'    │regular│chars│    |ascii|chars|'
⍝                  r,←⊂'    └───────┴─────┘    ''-----''-----'''
⍝              :EndIf
              :If enableBoxPfkey
              :AndIf ⎕SE.SALTUtils.WIN
                  :If 2≤level
                      r,←⊂''
                  :EndIf
                  r,←⊂'-pfkey=[S][C][A]<n>  toggle boxing on/off with function key <n>, while zero or more of with C(ontrol), S(hift), A(lt) are held depressed'
                  :If 2≤level
                      r,←⊂'    ]',Cmd,' -pfkey=12   ⍝ assign to F12'
                      r,←⊂'    ]',Cmd,' -pfkey=CSA6 ⍝ assign to Ctrl+Shift+Alt+F6'
                  :EndIf
              :EndIf
              :If 1=level
                  r,←⊂''
                  r,←⊂']',Cmd,' -??? ⍝ for details'
              :EndIf
          :EndIf
     
      :Case 'Rows'
          r←⊂'Cut, wrap, fold or extend the display of output lines to fit the Session window'
          r,←⊂'    ]',Cmd,' [on|off|?] [-style=<s>] [-fold=<f>] [-fns={on|off}] [-dots=<c>]'
          r,←⊂''
          :Select level
          :Case 0
              r,←⊂']',Cmd,' -??   ⍝ for more information and examples'
          :Case 1
              r,←⊂'Argument:'
              r,←⊂'    ""      query main state (on/off)'
              r,←⊂'    "on"    enable row-processing'
              r,←⊂'    "off"   restore native ⎕PW block-wrapping'
              r,←⊂'    "?"     query full state, including modifiers'
              r,←'' 'Modifiers:' '' '-style=<s>'
              r,←⊂'    "long"  rows extended beyond screen width (default)'
              r,←⊂'    "cut"   rows truncated at screen width'
              r,←⊂'    "wrap"  each row wrapped at screen width'
              r,←'' '-fold=<f>'
              r,←⊂'    <n>     number of trailing rows after fold (must be 0 through 9). Ignored when -style=wrap'
              r,←⊂'    "off"   no folding; all rows displayed (default)'
              r,←'' '-fns={on|off}'
              r,←⊂'    "on"    also format output from running functions'
              r,←⊂'    "off"   only format session results (default)'
              r,←'' '-dots=<c>'
              r,←⊂'    <c>     character to use for ellipses (default is "·", shown as "···")'
              r,←'' 'NOTES:'
              h←'    ∘  -fold=<n> replaces rows towards the end of multi-row '
              h,←'output with a line of <c> characters so that the expression that generated '
              h,←'the output, together with some leading and trailing '
              h,←'rows of its output, remain visible in the session window. -fold=<n> '
              h,←'may be appropriate for session-based demonstrations.'
              r,←⊂h
              r,←⊂'    ∘  -fold=<n> is incompatible with -style=wrap. If both are specified, -style=wrap prevails and -fold=<n> is ignored.'
              r,←⊂'    ∘  -fold implies enabling row-processing, even if ]',Cmd,' "on" was not specified.'
              h←'    ∘  By default, only output from expressions typed into the session is '
              h,←'processed. To include output from running functions, set -fns=on.'
              r,←h'' 'Example:'
              r,←⊂'      ]',Cmd,' -fold=3'
              r,←⊂'was -fold=off'
              r,←⊂'      ⍳10 4   ⍝ this assumes that the session window is 13 lines high'
              r,←⊂'┌→───┬────┬────┬────┐'
              r,←⊂'↓1 1 │1 2 │1 3 │1 4 │'
              r,←⊂'├~──→┼~──→┼~──→┼~──→┤'
              r,←⊂'│2 1 │2 2 │2 3 │2 4 │'
              r,←⊂'├~──→┼~──→┼~──→┼~──→┤'
              r,←⊂'│3 1 │3 2 │3 3 │3 4 │'
              r,←⊂'├~──→┼~──→┼~──→┼~──→┤'
              r,←⊂'·····················'
              r,←⊂'├~──→┼~──→┼~──→┼~──→┤'
              r,←⊂'│10 1│10 2│10 3│10 4│'
              r,←⊂'└~──→┴~──→┴~──→┴~──→┘'
          :EndSelect
     
      :Case 'Find'
          r←⊂'Precede output with a reference to the line of code that generated it'
          r,←⊂'    ]OUTPUT.',Cmd,' {on|off|?} [-includequadoutput]'
          r,←⊂''
          :If level=0
              r,←⊂']OUTPUT.',Cmd,' -?? ⍝ for more information and examples'
          :Else
              r,←⊂'on   enable reports'
              r,←⊂'off  disable reports'
              r,←⊂'?    query current state'
              r,←⊂''
              r,←⊂'-includequadoutput  also report on output caused by ⎕←. By default, only implicit output (without ⎕←) causes reporting.'
              r,←'' 'NOTE:  Reports begin with ">>" for implicit output and with "⎕←" for explicit output.'
              r,←'' 'Example:'
              r,←⊂'        ∇ foo'
              r,←⊂'    [1]   ''Line not starting with ⎕'''
              r,←⊂'    [2]   ⎕←''Line with ⎕←'''
              r,←⊂'        ∇'
              r,←⊂''
              r,←⊂'        foo'
              r,←⊂'    Line not starting with ⎕'
              r,←⊂'    Line with ⎕←'
              r,←⊂''
              r,←⊂'        ]OUTPUT.',Cmd,'  on  -includequadoutput'
              r,←⊂'    Was off'
              r,←⊂'        foo'
              r,←⊂'    >> Output from #.foo[1]'
              r,←⊂'    Line not starting with ⎕'
              r,←⊂'    ⎕← Output from #.foo[2]'
              r,←⊂'    Line with ⎕←'
     
          :EndIf
     
      :Case 'LastResult'
          r←⊂'Automatically store the last printed result in ',Var,' (variable name may change in a future release).'
          :If 1≤level
              r,←⊂'    ]',Cmd,' [on|off|?] ⍝ ? queries current state'
              r,←'' 'Speed up typing the variable name by assigning it to a function key using the modifier -pfkey=[S][C][A]<n> where <n> is 1 to 12 and optionally preceeded by S for Shift, C for Control and/or A for Alt:'
              r,←⊂'        ]',Cmd,' on -pfkey=S6 ⍝ store the name in Shift+F6'
              r,←⊂'        ?10⍴100' ⋄ ⎕RL←⍬
              r,←⊂'    ',⍕n←?10⍴100
              r,←⊂'        +/',Var,' ⍝ Use Shift+F6 to type this'
              r,←⊂'    ',⍕,+/n
              r,←'' 'Retain settings across sessions by saving the session.'
          :EndIf
          r,←'' 'If the last printed result was a ref, certain workspace actions be may be temporarily blocked (this restriction may disappear in a future release). To unblock, simply enter a non ref expression in the session.'
          :If 1≤level
              r,←⊂'        ⎕NS ⍬'
              r,←⊂'    #.[Namespace]'
              r,←⊂'        )clear'
              r,←⊂'    Cannot perform operation when # is referenced by session namespace.'
              r,←⊂'        0'
              r,←⊂'    0'
              r,←⊂'        )clear'
              r,←⊂'    clear ws'
          :Else
              r,←''(']',Cmd,' -?? ⍝ for details')
          :EndIf
     
      :EndSelect
    ∇

    ∇ r←flipBox dummy;c;band;obj
      B.state←'offon'↑⍨3-5×c←B.state≢'on' ⍝ determine new state
      band←⊃⌽'b'⎕SE.cbtop.⎕NL ¯9
      obj←'⎕SE.cbtop.',band,'.tb.boxing'
      obj ⎕WS'State'c  ⍝ change button
      SetCallback c
      r←1
    ∇

    ∇ {A}Filter event                     ⍝ various output filters.
      ;susp;rand;⎕PP;monad;∆_;text;DispFmt;trace;⎕PW
      ⎕PP←⍬⍴⎕RSI.⎕PP                      ⍝ current space's precision.
      :Trap 0 1000                        ⍝ catching errors & interrupts.
          event↑⍨←4                       ⍝ ensure enough args
          :If monad←900⌶0
              A←0
          :EndIf
          :If trace←event[2]∊'SessionTrace' 527
              text←(2⊃⎕XSI),'[',(⍕4⊃event),']'
              ∆_←{⍞←text ⍵↓⍨-monad ⋄ ⍞←⎕UCS 13}
          :Else
              ∆_←{⎕←⍵}
          :EndIf
          susp←2=-/(,⎕STACK)⍳'*' '⎕DQ'    ⍝ execution suspended.
          susp∨←event≡1                   ⍝ simulate suspension?
          A{⍎'rand←⍺⍺' ⋄ ⍺⍺}0             ⍝ naming of fn/var "rand".
          DispFmt←{                       ⍝ display formatted output.
              isa←2 9∨.=⎕NC'rand'         ⍝ operand is array or namespace.
              O U←⎕SE.Dyalog.(Out Utils)  ⍝ output and utils namespaces.
              rb←'off'∘≢¨(R B).state      ⍝ rows and boxing states.
              oon←(2<⍴⎕XSI)∧susp<F.state≡'on' ⍝ output on?
              CaptureResult←{
                  ⍵:⍎⎕SE.SALTUtils.LastResultVarName,'←⍺'
                  0
              }
              _←⍵ CaptureResult isa∧O.L.state≡'on' ⍝ capture result?
              0 0 0≡rb,oon:∆_ ⍵           ⍝ all off: no formatting.
              FindOutput←{
                  trace:0
                  0 ''∊⍨⍬⍴⍵:0
                  ~oon:0
                  (fn lc)←⍵
                  ⍝ lc←1⌈lc ⍝ why was this here?
                  F.includequadoutput<'⎕'∊qo←'⎕←>>'/⍨2/⍲\2/'⎕←'≡2↑{(+/∧\' '=⍵)↓⍵}(1+lc)⌷⎕CR fn:0
                  ⊢⎕←qo,' Output from ',fn,1⌽'][',⍕lc
              }
              _←FindOutput 3⊃¨⎕XSI ⎕LC,¨0
              fmt←{                               ⍝ formatting style.
                  box←{susp ⍺(⍵⌶Box)⍵}            ⍝ regular boxing.
                  isa:1 box ⍵                     ⍝ array boxing.
                  simp←(⎕NC⊂'rand')∊3.1 3.2       ⍝ simple non-derv.
                  simp:0 box ⍵                    ⍝ box-formatting array.
                  nkd←tacit'rand'                 ⍝ nkd-struct for local derv
                  B.trains≡'box':0 box⊃⌽nkd       ⍝ boxing of tacit fn
                  B.trains≡'tree':' '@(0=⎕UCS)Dft nkd ⍝ tree-formatting.
                  0(B.trains≡'parens')U.expr⊂nkd  ⍝ linear display of tacit fn
              }
              tacit←{                                     ⍝ nkd struct for 'rand'
                  this←⊃U.nkds ⎕NS'rand'                  ⍝ raw nkd for 'rand'
                  tnames←O.{0=⎕NC'tnames':0 ⋄ tnames}0    ⍝ tnames, default off
                  ⊃tnames U.nabs(⊂this),U.nkds ⍬⍴3↓⎕RSI   ⍝ rand names wrt current ns
              }
              0 1≡rb:∆_ fmt ⍵             ⍝ boxing only:
              long←O.R.style≡'long'       ⍝ unrestricted screen width.
              _ ⎕PW⊢←SD⌈32767×long        ⍝ ⎕pw temp set to screen width.
              CropOnly←{                  ⍝ cropping only:
                  isa:susp Rows ⎕FMT ⍵    ⍝ array: cropped.
                  ⊂⍵                      ⍝ fn: force ' ∇name'
              }
              1 0≡rb:∆_ CropOnly ⍵
              ∆_ susp Rows ⎕FMT fmt ⍵     ⍝ cropping if larger than window.
          }                               ⍝ :: ∇ *
          DispFmt A
      :Else
          :If ⎕EN<1000
              :Trap 1 ⍝ WS FULL
                  ∆_ A                        ⍝ error
              :Else
                  ⎕SIGNAL 1
              :EndTrap
          :EndIf
      :EndTrap
    ∇

      Box←{⎕ML ⎕IO←0                      ⍝ Boxed session output.
     
          susp isa←⍺                      ⍝ from fun and array display.
          susp<B.fns≡'off':⍵              ⍝ no boxing from fn output: done.
          simp←⍵{~isa:0 ⋄ 1=≡,⍺⍺}0        ⍝ is an array and is simple.
     
          fn←{                            ⍝ formatted function.
              isa:1 box ⍵                 ⍝ top level is array.
              (⊂,⍵)∊pfns:1/⍵              ⍝ primitive fn.
              isprimop ⍵:1/⍵              ⍝ primitive op.
              cls←⍺ class ⍵               ⍝ class of function ⍵.
              cls∊+3.1 4.1:tfn ⍺          ⍝ tradfn or tradop:
              cls∊+3.2 4.2:ndfn ⍵         ⍝ named dfn or dop:
              cls∊-3.2 4.2:↑⍵             ⍝ unnamed dfn or dop:
              ~⍺ isderv ⍵:1 box ⍵         ⍝ not derived fn: give up.
              '['≡1⊃⍵:⍺{                  ⍝ +/[1 → +/[1]
                  ax←'[',(⍕2⊃⍵),']'       ⍝ formatted axis
                  (⊃⍺)ax fn(⊃⍵)ax         ⍝ axis as monadic operator
              }⍵
              ~'.'≡1⊃⍵:⍺ ∇¨⍵              ⍝ derived fn.
              0::⍺ ∇¨⍵                    ⍝ error:
              ⍙←⍎⊃⍵                       ⍝ naming left operand,
              9≠⎕NC'⍙':⍺ ∇¨⍵              ⍝ not a space ref:
              (2⊃⍺)∇ 2⊃⍵                  ⍝ dropping space-tagging.
          }                               ⍝ :: C[;] ← vr ∇ nr
     
          tfn←{'    ∇ ',(6↓¯2↓⍵),'∇'}     ⍝ nice 1970s-style display.
     
          isderv←{                        ⍝ looks like a derived fn.
              ~(⊂⍴⍵)∊,¨2 3:0              ⍝ not a 2- or 3-vector: no
              isprimop 1⊃⍵:1              ⍝ primitive operator.
              ∧/(¯2↑⍺)isfn¨¯2↑⍵:1         ⍝ fork
              4=⌊|(1⊃⍺)class 1⊃⍵          ⍝ defined operator
          }
     
          isfn←{                          ⍝ is a function?
              (⊂,⍵)∊pfns:1                ⍝ primitive fn:
              isname ⍵:1                  ⍝ for late-binding.
              3=⌊⍺ class ⍵:1              ⍝ class is 3:
              ⍺ isderv ⍵                  ⍝ derived fn.
          }                               ⍝ :: yes ← vr ∇ cr
     
          isname←{                        ⍝ valid name.
              ~ischarvec ⍵:0              ⍝ non-starter.
              0≤⎕NC ⍵                     ⍝ possible.
          }
     
          ischarvec←{(1=⍴⍴⍵)∧(⎕DR ⍵)∊82 80 160 320}  ⍝ char vector.
     
          isprimop←{                         ⍝ is a primitive operator.
              u←80=⎕DR''                     ⍝ Unicode
              kvrs←⎕UCS u/9000+16 56 60 18   ⍝ key, variant, paw, stencil
              kvrs←⎕UCS 9061/⍨u∧⎕SE.SALTUtils.V18 ⍝ hoof ⍝NEWGLYPH⍝
              pops←'/\⌿⍀.¨∘⍨&⍣[⌶@'           ⍝ classic primitive ops
              sops←'⎕S' '⎕R' '⎕OPT'          ⍝ system ops
              sops,←'⎕U2338' '⎕U2360' '⎕U2364' '⎕U233A' ⍝ ⎕= ⎕: ∘¨ ⎕⋄
              sops,←⎕SE.SALTUtils.V18/⊆'⎕U2365' ⍝ ○¨ ⍝NEWGLYPH⍝
              (⊂⍵)∊pops,kvrs,sops            ⍝ is a primitive operator.
          }
     
          ndfn←{                          ⍝ named dfn: removal of name←.
              a←⊃⍵                        ⍝ first line.
              x←a⍳'{'                     ⍝ length of 'name←'.
              ~'⍝'∊a:↑(⊂x↓a),1↓⍵          ⍝ no comment: without name.
              c←a⍳'⍝'                     ⍝ position of line[0] comment.
              d←x↓(c↑a),(x⍴' '),c↓a       ⍝ name← removed, comment adjusted.
              ↑(⊂d),1↓⍵                   ⍝ raw dfn matrix rep.
          }
     
          class←{
              ~ischarvec ⍺:¯1                     ⍝ not a char vector.
              ~'∇     ∇'≡7↑¯1⌽⍺:¯1                ⍝ not ⎕vr
              fx←(⎕NS'').{11::¯1 ⋄ ⎕NC⊂⎕FX ⍵}     ⍝ fix in tmp space.
              (cls←fx ⍵)∊3 4∘.+0.1 0.2:cls        ⍝ trad or named dfn or op:
              -fx,⊂('⍙←',⊃⍵),1↓⍵                  ⍝ unnamed dfn or failure.
          }
     
          box←{                                   ⍝ boxing of ⍵
              U B←⎕SE.Dyalog.(Utils Out.B)        ⍝ handy refs.
              style←B.style                       ⍝ min mid max
              smooth←1⍝B.chars≡'regular'            ⍝ box-drawing chars?
              simp∧(⎕UCS 10)∊⍕⍵:⍺ ∇'\r?\n'⎕R'\r'⍠'Mode' 'D'⍤1⍕⍵ ⍝ normalise EOLs
              simp∧~style≡'max':⎕FMT ⍵            ⍝ no boxing.
              style≡'min':0 smooth 0 1 ⎕PP U.disp ⍵   ⍝ min: undecorated disp
              style≡'mid':⍺ smooth 0 1 ⎕PP U.disp ⍵   ⍝ mid: ⍺-decorated disp
              ⍺:smooth ⎕PP U.display ⍵            ⍝ max: ⍺: display
              0 smooth 0 1 U.disp ⍵               ⍝ max: undecorated disp.
          }
     
          uni←80=⎕DR''                            ⍝ unicode interpreter
          pf0←'+-×÷⌊⌈|*⍟<≤=≥>≠∨∧⍱⍲!?~○'           ⍝ scalar fns.
          pf1←'⌷/⌿\⍀∊⍴↑↓⍳⊂⊃∩∪⊣⊢⊥⊤,⍒⍋⍉⌽⊖⌹⍕⍎⍪≡≢⍷'   ⍝ other fns.
          pfu←⎕UCS uni/8838 9080                  ⍝ ⊂_ and ⍳_.
          pfns←,¨pf0,pf1,pfu                      ⍝ primitive fns.
     
          ⍙←⍺⍺ ⋄ 0 box(⊃⎕VR'⍙')fn⊃⎕NR'⍙'          ⍝ boxed output.
      }

      Dft←{⎕IO ⎕ML←0 1                            ⍝ Display of function tree.
     
          trav←{                                  ⍝ traverse, accumulating subtrees.
              0=≡⍺:⍺ leaf ⍵                       ⍝ not a derv or train: done.
              '['≡1⊃⍵:(2↑⍺)∇(⊃⍵)('[',(⍕2⊃⍵),']')  ⍝ axis: special treatment
              ~4∊|⍺:train ⍺ ∇¨⍵                   ⍝ train
              {                                   ⍝ operator-derived fn:
                  2=⍴⍵:mop ⍵                      ⍝ monadic operator
                  3=⍴⍵:dop ⍵                      ⍝ dyadic operator.
              }⍺ ∇¨⍵                              ⍝ formatted subtrees.
          }                                       ⍝ ::
     
          train←{                                 ⍝ function train.
              subs←↑mesh/⍵                        ⍝ enmeshed subtrees.
              tops←apts⊃↓subs                     ⍝ anchor points.
              jpts←mid⍣(2=+/tops),tops            ⍝ joining points.
              xvec←{(3×⍵)++\⍵}jpts                ⍝ character index vector.
              deco←(¯2+⍴⍵)⊃' ── ┌┴┐ ' ' ── ┌┼┐ '  ⍝ plumbing chars.
              (xvec⊃¨⊂deco)⍪subs                  ⍝ subtree matrix.
          }
     
          mop←{                                   ⍝ operator with one operand.
              land oper←↓¨⍵                       ⍝ derived function components.
              tab←+/∧\(⊃land)∊' ┌─┐'              ⍝ indentation for top line.
              pad←(tab+2)/' '                     ⍝ padding for operator.
              topr←pad∘,¨oper                     ⍝ tabbed operator.
              deco←' ┌─┘'                         ⍝ plumbing chars.
              join←tab 1 1 1/deco                 ⍝ dog-leg or straight join.
              ↑(topr,↓join),land                  ⍝ subtree matrix.
          }
     
          dop←{                                   ⍝ operator with two operands.
              land oper rand←⍵                    ⍝ derived function components.
              subs←land mesh rand                 ⍝ merged subtrees.
              tops←mid apts⊃↓subs                 ⍝ anchor points.
              xvec←{(3×⍵)++\⍵}tops                ⍝ character index vector.
              head←xvec⊃¨⊂' ── ┌┴┐ '              ⍝ forked subtree joiner.
              otab←(head⍳'┴')/' '                 ⍝ operator padding.
              ↑(otab∘,¨↓oper),↓head⍪subs          ⍝ subtree matrix.
          }
     
          mesh←{                                  ⍝ meshed left and right subtrees.
              lbr rbr←⊂[1 2]↑⎕FMT¨(⌽⍺)⍵                ⍝ sub branches with same no of rows.
              lft rgt←{+/∧\' '=⍵}¨lbr rbr         ⍝ left and rgt adjacent blanks.
              sep←⌊/lft+rgt                       ⍝ narrowest separation.
              dpl←lft⌊sep                         ⍝ chars to drop from left subtree.
              dpr←0⌈sep-dpl                       ⍝   ..      ..      right   ..
              lvec←⌽¨dpl↓¨↓lbr                    ⍝ left rows.
              rvec←dpr↓¨' '∘,¨↓rbr                ⍝ right rows, padded with min gap.
              trim←{(~∧\∧⌿⍵=' ')/⍵}               ⍝ trim off outer blank cols.
              ⌽trim⌽trim↑lvec,¨rvec               ⍝ meshed subtrees.
          }
     
          leaf←{                                  ⍝ leaf formatting
              ⍺∊2 9:(⎕UCS 0)@(=∘' ')1 ⎕SE.Dyalog.Utils.repObj ⍵   ⍝ array: linear representation
              1∊'←{'⍷⊃↓⍵:∇↑noname↓⍵               ⍝ dfn without name
              '·'@(' '=⊢)⎕FMT ⍵                   ⍝ dots for blanks in char matrix
          }
     
          noname←{                                ⍝ without dfn name
              a←⊃⍵                                ⍝ first line
              x←a⍳'{'                             ⍝ length of 'name←'
              ~'⍝'∊a:(⊂x↓a),1↓⍵                   ⍝ no comment: without name
              c←a⍳'⍝'                             ⍝ position of line[0] comment
              d←x↓(c↑a),(x⍴' '),c↓a               ⍝ name← removed, comment adjusted
              (⊂d),1↓⍵
          }
     
          mid←{⍵∨(⍳⍴⍵){⍺=⌊(+/⍵/⍺)÷2}⍵}            ⍝ mask with midpoint
          trim←{⍵-¯1⌽1 1⍷⍵}⍣≡                     ⍝ for ('abc',)
          apts←trim∘(~∘(∊∘' ┌─┐'))                ⍝ anchor points for sub-trees.
          dfnop←{'}'≡⊃⌽~∘' ',⍵}                   ⍝ dfn or dop
     
          N K D←⍵                                 ⍝ name, kind-tree, defn
          K trav D                                ⍝ display of function tree.
      }

      pfnops←{                                    ⍝ primitive fns and ops.
          pf0←'+-×÷⌊⌈|*⍟<≤=≥>≠∨∧⍱⍲!?~○'           ⍝ scalar fns.
          pf1←'⌷/⌿\⍀∊⍴↑↓⍳⊂⊃∩∪⊣⊢⊥⊤,⍒⍋⍉⌽⊖⌹⍕⍎⍪≡≢⍷'   ⍝ other fns.
          pfu←⎕UCS ⍵/8838 9080                    ⍝ ⊂_ and ⍳_ ⍝NEWGLYPH⍝
          pfns←pf0,pf1,pfu                        ⍝ primitive fns.
     
          kvrs←⎕UCS ⍵/9000+16 56 60 18            ⍝ key, variant, paw, stencil
          kvrs←⎕UCS 9061/⍨⍵∧⎕SE.SALTUtils.V18     ⍝ hoof ⍝NEWGLYPH⍝
          pops←'/\⌿⍀.¨∘⍨&⍣[⌶@'                    ⍝ classic primitive ops
          sops←'⎕S' '⎕R' '⎕OPT'                   ⍝ system ops. ⎕= ⎕: ∘¨ ⎕⋄
          sops,←'⎕U2338' '⎕U2360' '⎕U2364' '⎕U233A' ⍝ ⎕= ⎕: ∘¨ ⎕⋄
          sops,←⎕SE.SALTUtils.V18/⊆'⎕U2365'       ⍝ ○¨ ⍝NEWGLYPH⍝
          ops←pops,kvrs,sops                      ⍝ operators.
          pfns ops                                ⍝ fns & ops.
      }

      Rows←{                               ⍝ Cropped to fit session window.
          R←⎕SE.Dyalog.Out.R               ⍝ ref for params.
          ⍺<R.fns≡'off':⍵                  ⍝ no cropping from fn output: done.
          R.style≡'wrap':{0 0⍴''}{⎕←⍵}¨↓⍵  ⍝ ⎕PW-wrap each line.
          rows cols←⍴⍵                     ⍝ raw output size.
          long←R.style≡'long'              ⍝ extend output beyond print-width
          sr sc←SD⌈long×0,⎕PW⌈cols⌊32767   ⍝ screen_rows screen_cols
          coldots←{                        ⍝ with column dots.
              cols≤sc:⍵                    ⍝ no column cropping: done.
              1≠rows:(0 ¯1↓⍵),R.dots       ⍝ single column of dots on right
              (0 ¯3↓⍵),1 3⍴R.dots          ⍝ single row: stuff ···
          }
          dc←cols⌊sc                       ⍝ number of cols to display.
          fold←(R.fold≢'off')∧rows>sr-2    ⍝ must fold rows?
          ~fold:coldots rows dc↑⍵          ⍝ no: row cropping only.
          tail←⍎R.fold                     ⍝ 0..9
          t←0⌈tail⌊sr-3                    ⍝ no of trailing rows.
          h←0⌈sr-3+t                       ⍝ input + brk + fold + prompt.
          brk←sc⍴R.dots                    ⍝ fold marker: ··················
          top←h sc↑⍵                       ⍝ retained upper part of output.
          bot←(t sc×¯1 1)↑⍵                ⍝    ..    lower  ..     ..
          mat←top⍪brk⍪bot                  ⍝ dots-broken matrix
          dr _←⍴mat                        ⍝ number of rows to display.
          coldots dr sc↑mat                ⍝ cropped.
      }

    ∇ rc←SD;handle;GetDlgItem;GetClientRect;GetDC;ReleaseDC;GetDeviceCapsdlg;r;c;v;h;_;scal;hdc  ⍝ session window size
      :Trap 0
          ⎕NA'u user32|GetDlgItem u u'
          ⎕NA'u user32|GetClientRect u >{u u u u}'
          handle←'⎕se'⎕WG'Handle'
          dlg←GetDlgItem handle 0
          _(_ _ c r)←GetClientRect dlg(0 0 0 0)
          scal←1
          v h←2 ⎕NQ'⎕se' 'GetTextSize' 'X'
          :If (,'1')≡2 ⎕NQ'.' 'GetEnvironment' 'AutoDPI'
              ⎕NA'u user32|GetDC U'
              ⎕NA'u user32|ReleaseDC U U'
              ⎕NA'u gdi32|GetDeviceCaps U U'
              scal←96÷⍨GetDeviceCaps(hdc←GetDC 0)88
              {}ReleaseDC 0 hdc
          :End
     
          rc←⌊r c÷v h×scal
      :Else
          rc←⎕SD-1 0  ⍝ Unix version?
      :EndTrap
    ∇

    ∇ obj←Button;band ⍝ name of ]boxing button for ⎕W_
      band←⊃⌽'b'⎕SE.cbtop.⎕NL ¯9
      obj←'⎕SE.cbtop.',band,'.tb.boxing'
    ∇

:EndNamespace

 ⍝ outputspec  $Revision: 1607 $
