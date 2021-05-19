 r←test_WSFULL dummy;myapl;rc
 r←''
 x←⎕SE.CITA.API.ExecuteLocalTest ##.TESTSOURCE,'WSFULL\CITA.json5 -keep='

 :If (,2)Check x.⎕NC'testMat'
     →0 Because'Namespace result of ExecuteLocalTest did not contain testMat' ⋄ :EndIf
 :If 2 2 Check⍴x.testMat
     →0 Because'testMat did not have expected ⍴  (but ',(⍕⍴x.testMat),' instead)' ⋄ :EndIf
 :If 'w'Check x.testMat[2;2]
     →0 Because'testMat[2;2] did not contain expected value "w" (but "',(⍕x.testMat[2;2]),'" instead)' ⋄ :EndIf
