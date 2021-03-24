package cjx.n2

import cj.Deque
import cj.Error
import cjx.n2.N2Error
import cjx.parser.Mark

class N2IR {

    class Program {
        val funcs: List[Func] = []
        val funcMap: Map[String, Int] = MapOf()
        val constMap: Map[String, Int] = MapOf()
        val structs: List[Struct] = []
        val funcTemplateMap: Map[String, FuncTemplate] = MapOf()
        val structTemplateMap: Map[String, StructTemplate] = MapOf()
        val typeMap: Map[String, Tuple[Mark, Type]] = MapOf(
            "unreachable": (Default(), Type.unreachable),
            "void": (Default(), Type.void),
            "bool": (Default(), Type.bool),
            "int": (Default(), Type.int),
            "str": (Default(), Type.str),
            "var": (Default(), Type.var_),
        )
        val traits: List[Trait] = []
        val traitMap: Map[String, Trait] = MapOf()

        def addFunc(self, func: Func) {
            if func.name in funcMap {
                throw N2Error(
                    "Duplicate function definition",
                    [func.mark, funcs[funcMap[func.name]].mark])
            }
            funcMap[func.name] = funcs.size()
            funcs.add(func)
        }

        def updateFunc(self, func: Func) {
            funcs[funcMap[func.name]] = func
        }

        def getFuncOrNull(self, funcName: String): Func? {
            funcMap.getOrNull(funcName).map(i -> funcs[i])
        }

        def addFuncTemplate(self, ft: FuncTemplate) {
            if ft.name in funcTemplateMap {
                throw N2Error(
                    "Duplicate function template definition",
                    [ft.mark, funcTemplateMap[ft.name].mark])
            }
            funcTemplateMap[ft.name] = ft
        }

        def getFuncTemplateOrNull(self, name: String): FuncTemplate? {
            funcTemplateMap.getOrNull(name)
        }

        def addStructTemplate(self, st: StructTemplate) {
            if st.name in structTemplateMap {
                throw N2Error(
                    "Duplicate struct template definition",
                    [st.mark, structTemplateMap[st.name].mark])
            }
            structTemplateMap[st.name] = st
        }

        def getStructTemplateOrNull(self, name: String): StructTemplate? {
            structTemplateMap.getOrNull(name)
        }

        def addStruct(self, struct_: Struct) {
            structs.add(struct_)
            addTypedef(struct_.mark, Type.struct_(struct_), struct_.name)
        }

        def getStructOrNull(self, name: String): Struct? = {
            if val (mark, type) = typeMap.getOrNull(name) {
                when type {
                    case struct_(struct_) = null(struct_)
                    else = null
                }
            } else { null }
        }

        def getStruct(self, name: String): Struct = get!(typeMap[name].f1, struct_, 0)

        def addTypedef(self, mark: Mark, type: Type, name: String) {
            if val (oldMark, type) = typeMap.getOrNull(name) {
                throw N2Error("Duplicate type definition '" + name + "'", [mark, oldMark])
            }
            typeMap[name] = (mark, type)
        }

        def getTypeOrNull(self, typeName: String): Type? = (
            typeMap.getOrNull(typeName).map(p -> p.f1))

        def addConst(self, name: String, value: Int) {
            constMap[name] = value
        }

        def getConstOrNull(self, name: String): Int? = constMap.getOrNull(name)

        def addTrait(self, trait_: Trait) {
            traits.add(trait_)
            traitMap[trait_.name] = trait_
        }

        def getTraitOrNull(self, name: String): Trait? = traitMap.getOrNull(name)
    }

    class FuncTemplate {
        val mark: Mark
        val name: String
        val templateParams: List[String]
        val tpats: List[TPat]
        val i: Int
    }

    trait AllTraitsMixin {
        def __get_traits(self): List[Trait]
        def __set__allTraits(self, traits: List[Trait]?)
        def __get__allTraits(self): List[Trait]?
        def __get_allTraits(self): List[Trait] {
            if _allTraits.isEmpty() {
                val allTraits: List[Trait] = []
                val queue = Deque[Trait].fromList(traits)
                val seen = queue.map(t -> t.name).toSet()
                while queue {
                    val subtrait = queue.popleft()
                    allTraits.add(subtrait)
                    for child in subtrait.traits {
                        if child.name not in seen {
                            queue.add(child)
                            seen.add(child.name)
                        }
                    }
                }
                _allTraits = null(allTraits)
            }
            _allTraits.get()
        }
    }

    class StructTemplate : AllTraitsMixin {
        val mark: Mark
        val name: String
        val templateParams: List[String]
        val i: Int
        val traits: List[Trait] = []
        var _allTraits: List[Trait]? = null
    }

    class Var {
        val mark: Mark
        val type: Type
        val name: String
        val index: Int
        var init: Expr?
    }

    class Trait {
        val mark: Mark
        val name: String
        val traits: List[Trait] = []
    }

    class Struct : AllTraitsMixin {
        val mark: Mark
        val name: String
        val native_: Bool
        val rootName: String
        val templateArgs: List[Type]
        val traits: List[Trait] = []
        val fields: List[Var] = []
        val fieldMap: Map[String, Var] = MapOf()
        var _allTraits: List[Trait]? = null
        def addField(self, field: Var) {
            if val oldField = fieldMap.getOrNull(field.name) {
                throw N2Error(
                    "Duplicate field definition " + field.name, [field.mark, oldField.mark])
            }
            fields.add(field)
            fieldMap[field.name] = field
        }
        def getFieldOrNull(self, name: String): Var? = fieldMap.getOrNull(name)
    }

    class Func {
        val mark: Mark
        val returnType: Type
        val name: String
        val nparams: Int
        val locals: List[Var]
        var body: Expr = ?
        def __get_params(self): List[Var] = locals[:nparams]
        def __get_type(self): Type = Type.func(returnType, params.map(p -> p.type))
        def __get_nonParamLocals(self): List[Var] = locals[nparams:]
    }

    ## Type Pattern
    ## Used to match against expressions to infer template args
    class TPat: Repr {
        val mark: Mark
        val name: String
        val args: List[TPat]
        def repr(self): String = if args { name + args } else { name }
    }

    union Type: Repr, Eq {
        case unreachable
        case void
        case bool
        case int
        case str
        case meta
        case var_
        case null_(Type)
        case struct_(Struct)
        case list(Type)
        case func(Type, List[Type])
        def isUnreachable(self): Bool = tag!(self) == tag!(Type, unreachable)
        def isVoid(self): Bool = tag!(self) == tag!(Type, void)
        def isBool(self): Bool = tag!(self) == tag!(Type, bool)
        def isVar(self): Bool = tag!(self) == tag!(Type, var_)
        def isInt(self): Bool = tag!(self) == tag!(Type, int)
        def isStr(self): Bool = tag!(self) == tag!(Type, str)
        def isMeta(self): Bool = tag!(self) == tag!(Type, meta)
        def isNull(self): Bool = tag!(self) == tag!(Type, null_)
        def isArray(self): Bool = tag!(self) == tag!(Type, list)
        def isFunc(self): Bool = tag!(self) == tag!(Type, func)
        def repr(self): String = when self {
            case struct_(s) = s.name
            case null_(t) = "null(" + t.repr() + ")"
            case list(t) = "list(" + t.repr() + ")"
            case func(rtype, argtypes) = "func(" + rtype.repr() + "," + argtypes + ")"
            else() = tag_name!(self)
        }
        def __eq(self, other: Self): Bool = tag!(self) == tag!(other) and switch tag!(self) {
            case tag!(Self, func) = when self {
                case func(rt, argts) = when other {
                    case func(ort, oargts) = rt == ort and argts == oargts
                    else = false
                }
                else = throw Error("FUBAR")
            }
            else = true
        }
        def __get_rootName(self): String = when self {
            case null_(t) = "null_"
            case list(inner) = "list"
            case func(rtype, argtypes) = "func" + argtypes.size()
            case struct_(st) = st.rootName
            else name() = name
        }
        def __get_args(self): List[Type] = when self {
            case null_(t) = [t]
            case struct_(st) = st.templateArgs
            case list(inner) = [inner]
            case func(rtype, argtypes) = [rtype] + argtypes
            else() = []
        }
        def __get_itemType(self): Type = get!(self, list, 0)
        def common(mark: Mark, a: Self, b: Self): Self {
            if a.isVoid() or b.isVoid() {
                void
            } else if a.isUnreachable() {
                b
            } else if b.isUnreachable() {
                a
            } else if a == b {
                a
            } else {
                throw N2Error("Types " + a + " and " + b + " are not compatiable", [mark])
            }
        }
    }

    union JS {
        case js(String)
        case expr(Expr)
    }

    class Expr: Repr {
        enum { # expression kinds
            kINT
            kINT_ADD
            kINT_SUB
            kINT_MUL
            kINT_DIV
            kINT_REM
            kINT_NEG
            kINT_EQ
            kINT_NE
            kINT_LT
            kINT_LE
            kINT_TO_BOOL

            kINTVAR_INCR
            kINTVAR_DECR

            kSTR
            kSTR_LEN
            kSTR_ADD

            kGETVAR
            kSETVAR
            kDECLVAR

            kARRAY
            kARRAY_LEN
            kARRAY_GET
            kARRAY_SET

            kLOGICAL_AND
            kLOGICAL_OR

            kNEWARRAY

            kNULL
            kNULLWRAP

            kIF
            kWHILE

            kGETFUNC
            kGETFUNCTEMP
            kBOUNDFUNC
            kBOUNDFUNCTEMP
            kGETSTRUCTTEMP
            kCALL
            kNEWSTRUCT
            kGETFIELD

            kTYPEDEF

            kRETURN

            kBLOCK

            kTYPE

            kJS  # raw javascript snippet
        }

        private static val kindNames: List[String] = static_field_names!(Self, "k[A-Z_]+")

        val mark: Mark
        val kind: Int
        var type: Type

        # literals
        var intValue: Int = ?
        var stringValue: String = ?

        # variable
        var var_: Var = ?

        # binops/unops/getitem/setitem
        var lhs: Expr = ?
        var rhs: Expr = ?
        var arg: Expr = ?

        # if/while
        var cond: Expr = ?
        var then: Expr = ?
        var els: Expr = ?

        # getfunc/call/list/js/struct
        var func: Func = ?
        var funcTemplate: FuncTemplate = ?
        var structTemplate: StructTemplate = ?
        def __get_args(self): List[Expr] = stmts
        def __set_args(self, value: List[Expr]) { stmts = value }
        var refName: String = ?

        # type/meta/struct
        var ty: Type = ?
        def __get_struct_(self): Struct = get!(ty, struct_, 0)
        def __set_struct_(self, s: Struct) { ty = Type.struct_(s) }

        # block
        var stmts: List[Expr] = ?
        var newScope: Bool = ?

        def __get_kindName(self): String = kindNames[kind]

        def repr(self): String {
            val kindstr = kindNames[kind]
            switch kind {
                case kBLOCK = "block(" + type + "," + ",".join(stmts.map(s -> s.repr())) + ")"
                case kIF = "if_(" + type + "," + cond + "," + then + "," + els + ")"
                case kGETFUNC = "getfunc(" + func.name + ")"
                else = kindstr
            }
        }
    }
}
