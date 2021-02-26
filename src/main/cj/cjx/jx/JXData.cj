package cjx.jx

import cjx.jx.JXTaskManager
import cjx.jx.JXJSGen
import cj.StringBuilder

union JXData {
    case string(String)
    case stringList(List[String])
    case codeGen(JXJSGen)
    case taskManager(JXTaskManager)
}
