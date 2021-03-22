:Namespace Cita
   ⍝ UCMD-File for CITA. This just makes API-Functions available as UCMDs.
   ⍝ The syntax of the fns etc. is determined in the fn-header (StartupSession/CITA/API.apln > ExecuteLocalTest)

    :section UCMD

    ∇ r←List;findLine;nr;fn;ns;hd;maxH
      FetchAPI
      r←⎕JSON ⎕SE.CITA.UCMD._List
    ∇

    ∇ r←level Help cmd
      FetchAPI
      r←⎕SE.CITA.UCMD._Help{(⍺[;⍳2]∧.≡⍵)⌿⍺[;3]}cmd level
      :If ∨/⎕SE.CITA.UCMD._Help[;⍳2]∧.≡cmd(level+1)
          r,←(⊂''),(⊂']CITA.',cmd,' -',((level+2)⍴'?'),'    ⍝ for more details')
      :EndIf
    ∇

    ∇ {r}←Run(cmd args);res;⎕ML
      ⎕ML←1
      FetchAPI
      :If 3=⎕NC'⎕SE.CITA.API.',cmd        ⍝ if function exists in ⎕SE.CITA...
          (rc log)←⍎'⎕SE.CITA.API.',cmd,' args' ⍝ execute it...
          r←cmd,': ',{⍵=0:'success' ⋄ ('*** '/⍨0≠rc),'FAILURE (return code=',(⍕⍵),')'},rc
          r←l r(l←(⌈/(≢r),≢¨log)⍴'-─'[1+0=rc])
          r←r,⊆log
          r←∊r,¨⊂⎕UCS 13
      :Else
          ⎕←↑⎕DMX
          r←''
      :EndIf
    ∇
    :endsection

    :section SecretSauce
    ∇ FetchAPI;findLine;quote;j;maxH;nr;hd;r;fn;AT;h
       :If 0=⎕NC'⎕SE.CITA' ⋄ 'CITA'⎕SE.⎕NS'' ⋄ :endif
      :If 0=⎕NC'⎕SE.CITA.UCMD'
      :OrIf 0=⎕NC'⎕SE.CITA.UCMD._Help'
          ⍝ the bad news is that this needs the API-ns which will be brought in later (during regular boot)
          ⍝ so we do it now...
          'CITA'⎕SE.⎕NS''
          'UCMD'⎕SE.CITA.⎕NS''
          :if (,'1')≡,2⎕nq'.' 'GetEnvironment' 'DYALOGSTARTUPKEEPLINK'
          :trap 0 ⋄ {}⎕SE.Link.Create ⎕SE.CITA(FindCITA,'/API.apln') ⋄ :endtrap ⍝ depending on the timing this might complain when API is present already
          :else 
          :trap 0 ⋄ {}⎕SE.Link.Import ⎕SE.CITA(FindCITA,'/API.apln') ⋄ :endtrap ⍝ depending on the timing this might complain when API is present already
          :endif
          ⍝ Build list & help and construct stub-fns in ⎕SE.CITA
          ⍝ based on fns we find in ⎕SE.CITA.API
          ⎕SE.CITA.UCMD._List←'['
          ⎕SE.CITA.UCMD._Help←0 3⍴0  ⍝ [;1]=name, [;2]=Level, [;3]=line
          findLine←{{(+/∧\⍵=' ')↓⍵}¨l↓¨(((l←2+≢⍵)↑¨⍺)≡¨⊂'⍝',⍵,':')/⍺}
          quote←{'"',⍵,'"'}
          :For fn :In {('_'≠1⊃¨⍵)/⍵}⎕SE.CITA.API.⎕NL-3  ⍝ only for fns NOT starting with '_'
              nr←⎕SE.CITA.API.⎕NR fn
              'ns'⎕NS''
              j←'{'
              j,←'"Name":',quote fn
              j,←',"Desc":',quote∊nr findLine':'
              j,←',"Parse":',quote∊nr findLine'Parse'
              j,←',"Group":"CITA"'
              j,←'}'
              ⎕SE.CITA.UCMD._List,←j,','
              maxH←⌈/0,∊('⍝(\?*):'⎕S{¯1↑⍵.Lengths})nr
              :For h :In ⍳maxH
                  ⎕SE.CITA.UCMD._Help⍪←(⊂fn),(h-1),[1.5]nr findLine h⍴'?'
              :EndFor
              :Select 2⊃1⊃AT←⎕SE.CITA.API.⎕AT fn
              :Case 0 ⍝ niladic or not a fn
                  hd←fn
              :Case 1 ⍝ monadic
                  hd←fn,' rarg'
              :CaseList ¯2 2
                  hd←'larg ',fn,' rarg'
              :EndSelect
              :Select 1⊃1⊃⎕SE.CITA.API.⎕AT fn
              :Case 1 ⋄ hd←'R←',hd
              :Case ¯1 ⋄ hd←'{R}←',hd
              :EndSelect
              r←'←'∊hd
              hd←(⊂hd),⊂':if 2=⎕nc''larg''⋄',(r/'R←'),'larg _getAPI ''',fn,''' rarg'
              hd,←⊂':else⋄',(r/'R←'),'_getAPI ''',fn,''' rarg'
              hd,←⊂':endif'
              {}⎕SE.CITA.⎕FX hd
          :EndFor
          ⎕SE.CITA.UCMD._List←(¯1↓⎕SE.CITA.UCMD._List),']'
          :If 1  ⍝ MB
              'Fetched CITA⋄API!'
              ⎕←2↑⎕SI,[1.5]⎕LC
          :EndIf
      :Else
          :If 0  ⍝ MB
              ⎕←'API not loaded because present!'
              ⎕←⎕SI,[1.5]⎕LC
          :EndIf
      :EndIf
    ∇

    ∇ R←FindCITA
    ⍝ I had expected this would turn out to be more complicated...
    ⍝ but doing it this way we don't even need the environment variable!
      :If 3=⎕SE.⎕NC'CITA._getArg'
      :AndIf 0<≢R←4⊃5179⌶'⎕SE.CITA._getArg'      ⍝ default (and preferred) approach
          R←1⊃⎕NPARTS R
      :ElseIf 0<{0::0 ⋄ ≢R←4⊃5179⌶⎕SE.CITA.API}0  ⍝ also acceptable...
          R←1⊃⎕NPARTS R
      :ElseIf 2=##.⎕NC't'   ⍝ during List
          R←∊1 ⎕NPARTS(##.t~'"'),'/../../../StartupSession/CITA'
      :ElseIf 2=##.##.⎕NC't'   ⍝ saw that stack as well during spc.List
          R←∊1 ⎕NPARTS(##.##.t~'"'),'/../../../StartupSession/CITA'
      :Else  ⍝ take out before going into production...
          600⌶1
          ∘∘∘
          600⌶0
      :EndIf
    ∇
    :endsection
:EndNamespace
