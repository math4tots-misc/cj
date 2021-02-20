package compiler

import compiler.CJIR

union CJData {
    case fullName(String)
    case type(CJIR.Type)
}
