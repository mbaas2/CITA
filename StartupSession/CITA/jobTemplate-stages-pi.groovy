stage ("pi_%CITA_VERSION%_%VERSION%") {
  node ("pi&&%CITA_VERSION%&&%VERSION%") {
    [%BITS%].each { BITS -> 
      [%EDITIONS%].each { EDITION ->
        // catchError(buildResult: "UNSTABLE", stageResult: "FAILURE") {
        try {
          echo "NODE_NAME = ${env.NODE_NAME}"            
          path = "/opt/mdyalog/%VERSION%/${BITS}/${EDITION}/mapl"
          E = EDITION.take(1)
          exists = fileExists(path)          
          if (!exists) {
            error "Found no interpreter for ${env.NODE_NAME}. Labels: ${env.NODE_LABELS}"
          }
          testPath="%xinD%pi_%VERSION%_${E}${BITS}/"
          cmdline = "%CMDLINE% citaDEVT=${citaDEVT} USERCONFIGFILE=${testPath}cita.dcfg CITA_Log=${testPath}CITA.log"
          cmdline = "$cmdline > ${testPath}ExecuteLocalTest.log"

          rjc = sh(script: "$path $cmdline" , returnStatus: true)
          exists = fileExists("${testPath}CITA.log.ok") 
          if (exists) {
            echo "Test succeeded"
            rc = 0
          } else {
            echo "Test did not end with status file ${testPath}ExecuteLocalTest.log"
            rc = 1
          }
        } catch (err)
        {
          echo "Caught error: ${err}"
          // unstable("Stage failed!")
          rc = 1
        }
        if (rc != 0)
        {
          unstable("Stage failed!")
          rc=0
        }
        echo "rc=$rc"
        sh "exit $rc"
      }
    }
  }
}