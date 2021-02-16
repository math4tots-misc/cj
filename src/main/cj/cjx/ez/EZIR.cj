package cjx.ez

import cjx.ez.EZMark

class EZIR {

    @derive(new)
    class Class {
        val mark: EZMark
        val id: Int
        val modifiers: List[String]
        val name: String
        val _fields: List[Field] = []
        val _methods: List[Method] = []

        def addField(self, field: Field) {
            _fields.add(field)
        }

        def addMethod(self, method: Method) {
            _methods.add(method)
        }

        def isNative(self): Bool = "native" in modifiers
    }

    @derive(new)
    class Field {
        val mark: EZMark
        val modifiers: List[String]
        val name: String
        val type: Type
        def isStatic(self): Bool = "static" in modifiers
        def isMutable(self): Bool = "var" in modifiers
    }

    @derive(new)
    class Method {
        val mark: EZMark
        val modifiers: List[String]
        val name: String
        val parameters: List[Local]
        val returnType: Type
        var body: Nullable[Expr] = null
    }

    @derive(new)
    class Local {
        val mark: EZMark
        val id: Int
        val name: String
        val type: Type
        def repr(self): String = "local(" + id + "," + name + ")"
    }

    union Type: Repr {
        case klass(String)
        def new(name: String): Self = klass(name)
        def __get_name(self): String = when self { case klass(name) = name }
        def isNoReturn(self): Bool = name == "jl1.NoReturn"
        def isUnit(self): Bool = name == "jl1.Unit"
        def isBool(self): Bool = name == "jl1.Bool"
        def isInt(self): Bool = name == "jl1.Int"
        def isDouble(self): Bool = name == "jl1.Double"
        def __eq(self, other: Self): Bool = repr() == other.repr()
        def repr(self): String = name
    }

    @derive(new)
    class MethodType: Repr {
        val parameterTypes: List[Type]
        val returnType: Type
        def repr(self): String = (
            "(" + ",".join(parameterTypes.map(t -> t.repr())) + ")" + returnType)
    }

    class Expr {
        val mark: EZMark
        val type: Type
        val data: ExprData
        val terminatesFlow: Bool
        def new(mark: EZMark, type: Type, data: ExprData): Self {
            __malloc(mark, type, data, type.isNoReturn())
        }
    }

    union ExprData {
        case unit
        case int(Int)
        case string(String)
        case block(List[Expr])
        case call(Type, String, MethodType, List[Expr])
        case java(Java)
    }

    union Java {
        case getstatic(String, String, String)
        case callinstance(String, String, String, List[Expr])
    }
}
