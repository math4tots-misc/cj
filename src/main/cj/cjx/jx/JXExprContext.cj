package cjx.jx

import cjx.jx.JXType

union JXExprContext {
    case none
    case expectedType(JXType)
}
