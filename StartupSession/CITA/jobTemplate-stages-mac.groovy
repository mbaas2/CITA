stage ("mac_%CITA_VERSION%_%VERSION%") {
  node ("mac&&%CITA_VERSION%&&%VERSION%") {
    // no looping over bits/editions - mac is always unicode 64 
    // catchError(buildResult: "UNSTABLE", stageResult: "FAILURE") {
    try {
      echo "NODE_NAME = ${env.NODE_NAME}"            
      path = "/Dyalog/Dyalog-%VERSION%.app/Contents/Resources/Dyalog/mapl"
      exists = fileExists(path)      
      if (!exists) {
        path = "/Applications/Dyalog-%VERSION%.app/Contents/Resources/Dyalog/mapl"
        exists = fileExists(path)          
        if (!exists) {
          error "PLATFORM=mac, path=${path}: File does not exist, giving it up!"
        }
      }
      testPath="%xinD%mac_%VERSION%_u64/"
      cmdline = "%CMDLINE% USERCONFIGFILE=${testPath}cita.dcfg CITA_Log=${testPath}CITA.log citaDEVT=${citaDEVT}"

      if ("${env.NODE_NAME}"=="mac3") {
        testPath = testPath.replaceAll("(^|=)/devt/","\$1/Volumes/devt/")
        cmdline = cmdline.replaceAll("(^|=)/devt/","\$1/Volumes/devt/")
        citaDEVT="/Volumes/devt/"
        echo "citaDEVT=$citaDEVT"
      } else {
        citaDEVT="/devt/"
      }
      cmdline = "$cmdline > ${testPath}ExecuteLocalTest.log"
      CITAlog="${testPath}CITA.log"
      rcj = sh(script: "$path $cmdline" , returnStatus: true)
      echo "CITAlog=$CITAlog|${CITAlog}"
      echo "rcj=$rcj"
      sh "ls ${testPath}"
      exists = fileExists("${CITAlog}.ok") 
      if (exists) {
        echo "Test succeeded"
        rc = 0
      } else {
        echo "Test did not end with status file ${CITAlog}.ok"
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