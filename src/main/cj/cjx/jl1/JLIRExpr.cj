package cjx.jl1

import cjx.jl1.JLIRCapture
import cjx.jl1.JLIRClass
import cjx.jl1.JLIRLocal
import cjx.jl1.JLIRFieldRef
import cjx.jl1.JLIRMethodRef
import cj.BigInt
import cjx.jl1.JLType
import cjx.jl1.JLMark

## jl1 expression
class JLIRExpr {

    union Data {
        case void()
        case bool(Bool)
        case char(Int)
        case int(Int)
        case long(BigInt)
        case float(Double)
        case double(Double)
        case string(String)
        case block(List[JLIRExpr])
        case call(JLIRMethodRef, List[JLIRExpr])
        case callnew(JLIRMethodRef, List[JLIRExpr])

        case declarelocal(JLIRLocal, JLIRExpr) # declare a local variable
        case getlocal(JLIRLocal) # get local variable
        case setlocal(JLIRLocal, JLIRExpr) # set local variable
        case getstatic(JLIRFieldRef) # get static field
        case setstatic(JLIRFieldRef, JLIRExpr) # set static field
        case getfield(JLIRFieldRef, JLIRExpr) # get instance field
        case setfield(JLIRFieldRef, JLIRExpr, JLIRExpr) # set instance field
        case getcapture(JLIRCapture)
        case not_(JLIRExpr)
        case and_(List[JLIRExpr])
        case or_(List[JLIRExpr])
        case if_(JLIRExpr, JLIRExpr, JLIRExpr)
        case while_(JLIRExpr, JLIRExpr)
        case throw_(JLIRExpr)
        case trycatch(JLIRExpr, List[Tuple[JLIRLocal, JLIRClass, JLIRExpr]])
        case tryfinally(JLIRExpr, JLIRExpr)
        case upcast(JLIRExpr)
        case downcast(JLIRExpr)
        case lambda(List[JLIRCapture], List[JLIRLocal], JLIRExpr)
        case operation(Operator, List[JLIRExpr])

        # ================================================================================
        # other
        # ================================================================================

        ## A hack, for supporting the common use case of '+=' for int fields.
        ## TODO: Remove this hacks
        case iaugfield(JLIRFieldRef, JLIRExpr, JLIRExpr)

        ## Creates an array initialized with the given values
        case array(List[JLIRExpr])

        ## Creates a new array with the given length
        case arraynew(JLIRExpr)

        ## Converts non-void results to void
        ## this is important for stack integrity when emitting bytecode
        case voidify(JLIRExpr)

        ## "Manually" call a Java method
        ##
        ## Allows invoking overloaded methods by specifying the full method signature
        ##
        ## (kind(static,virtual,interface,special), owner-type, method-name, signature, args)
        case javacall(String, String, String, String, List[JLIRExpr])

        ## "Manually" call 'new' on a Java class
        ##
        ## (owner-type, constructor-descriptor, args)
        case javanew(String, String, List[JLIRExpr])

        ## "Manually" get a Java static variable
        ## (owner-type, field-name, descriptor)
        case javagetstatic(String, String, String)

        ## "Manually" set a Java static variable
        ## (owner-type, field-name, descriptor, expr)
        case javasetstatic(String, String, String, JLIRExpr)

        ## "Manually" get a Java field
        ## (owner-type, field-name, descriptor, owner)
        case javagetfield(String, String, String, JLIRExpr)

        ## "Manually" set a Java field
        ## (owner-type, field-name, descriptor, owner, expr)
        case javasetfield(String, String, String, JLIRExpr, JLIRExpr)

        ## Initializes static and non-static fields.
        ## Must only appear within <clinit> and <init> methods.
        ## For non-static fields, the owner 'this' is implied.
        case initfield(JLIRFieldRef, JLIRExpr)
    }

    @derive(repr)
    union Operator {

        # int ops
        case iadd
        case isub
        case imul
        case idiv
        case irem
        case iand
        case ior
        case ixor
        case ishl
        case ishr
        case ishru
        case ineg
        case i2b
        case i2c
        case i2d
        case i2f
        case i2l
        case i2s
        case ilt
        case ile
        case igt
        case ige
        case ieq
        case ine

        # double ops
        case dadd

        # long ops
        case l2i

        # string ops
        case strcat

        # array ops
        case arrayget
        case arrayset
        case arrayclear
        case arraylen
        case arrayrealloc
    }

    val mark: JLMark
    val type: JLType
    val data: Data
    val terminatesFlow: Bool

    def(mark: JLMark, type: JLType, data: Data): Self {
        __malloc(mark, type, data, if type.isNoReturn() { true } else {
            when data {
                case if_(cond, lhs, rhs) = (
                    cond.terminatesFlow or (lhs.terminatesFlow and rhs.terminatesFlow))
                case upcast(inner) = inner.terminatesFlow
                case block(exprs) = exprs and exprs.last().terminatesFlow
                case voidify(inner) = inner.terminatesFlow
                else = false
            }
        })
    }

    def isEmpty(self): Bool = when data {
        case void() = true
        case block(exprs) = exprs.isEmpty()
        else = false
    }
}
