//stage ("win_%CITA_VERSION%_%VERSION%") {
//  node ("win&&%CITA_VERSION%&&%VERSION%") {
stage ("win_%VERSION%") {
  node ("win&&%VERSION%") {
    [%BITS%].each { BITS -> 
      [%EDITIONS%].each { EDITION ->
        // catchError(buildResult: "UNSTABLE", stageResult: "FAILURE") {
        try {
            echo "NODE_NAME = ${env.NODE_NAME}"   
            E = EDITION.take(1)
            def ed = EDITION.capitalize()
            echo "ed=$ed"
            EDITION=ed
            if ("%BITS%" == "32")
            {
                path = "${env.PROGRAMFILES(X86)}/Dyalog/Dyalog APL %VERSION% $EDITION/dyalog.exe"
            }
            else 
            {
                path = "${env.PROGRAMFILES}/Dyalog/Dyalog APL %VERSION% $EDITION/dyalog.exe"
            }
            echo "path=$path"
            exists = fileExists(path)          
            if (!exists) {
                error "Found no interpreter for ${env.NODE_NAME} in path '$path' Labels: ${env.NODE_LABELS}"
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