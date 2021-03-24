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

        def int(mark: Mark, value: Int): Self {
            val self = Self(mark, kINT, Type.int)
            self.intValue = value
            self
        }

        def str(mark: Mark, value: String): Self {
            val self = Self(mark, kSTR, Type.str)
            self.stringValue = value
            self
        }

        def getvar(mark: Mark, var_: Var): Self {
            val self = Self(mark, kGETVAR, var_.type)
            self.var_ = var_
            self
        }

        def setvar(mark: Mark, var_: Var, valexpr: Expr): Self {
            val self = unop(mark, kSETVAR, var_.type, icast(valexpr, var_.type))
            self.var_ = var_
            self
        }

        def declvar(mark: Mark, var_: Var): Self {
            val self = Self(mark, kDECLVAR, Type.void)
            if val init = var_.init {
                var_.init = null(icast(init, var_.type))
            }
            self.var_ = var_
            self
        }

        def getfunc(mark: Mark, func: Func, refName: String): Self {
            val self = Self(mark, kGETFUNC, func.type)
            self.func = func
            self.refName = refName
            self
        }

        def getfuncTemplate(mark: Mark, funcTemplate: FuncTemplate, refName: String): Self {
            val self = Self(mark, kGETFUNCTEMP, Type.meta)
            self.funcTemplate = funcTemplate
            self.refName = refName
            self
        }

        def boundfunc(mark: Mark, func: Func, expr: Expr, refName: String): Self {
            val self = unop(mark, kBOUNDFUNC, Type.meta, expr)
            self.func = func
            self.refName = refName
            self
        }

        def boundfuncTemplate(mark: Mark, ft: FuncTemplate, expr: Expr, refName: String): Self {
            val self = unop(mark, kBOUNDFUNCTEMP, Type.meta, expr)
            self.funcTemplate = ft
            self.refName = refName
            self
        }

        def getstructTemplate(mark: Mark, structTemplate: StructTemplate): Self {
            val self = Self(mark, kGETSTRUCTTEMP, Type.meta)
            self.structTemplate = structTemplate
            self
        }

        def callf(mark: Mark, func: Func, args: List[Expr]): Self {
            val self = Self(mark, kCALL, func.returnType)
            self.func = func
            self.args = args
            if args.size() != func.nparams {
                throw N2Error(
                    "Expected " + func.params.size() + " args but got " + args.size(), [mark])
            }
            val params = func.params
            for i = 0; i < args.size(); i++ {
                args[i] = args[i].icast(params[i].type)
            }
            self
        }

        def newstruct(mark: Mark, struct_: Struct, args: List[Expr]): Self {
            val self = Self(mark, kNEWSTRUCT, Type.struct_(struct_))
            self.struct_ = struct_
            self.args = args
            self
        }

        def getfield(mark: Mark, owner: Expr, struct_: Struct, field: Var): Self {
            val self = unop(mark, kGETFIELD, field.type, owner)
            self.var_ = field
            self.struct_ = struct_
            self
        }

        def js(mark: Mark, type: Type, args: List[Expr]): Expr {
            val self = Self(mark, kJS, type)
            self.args = args
            self
        }

        def evalType(program: Program, expr: Expr): Type {
            switch expr.kind {
                case kTYPE { return expr.ty }
                case kGETFUNC; case kGETFUNCTEMP; case kBOUNDFUNC; case kBOUNDFUNCTEMP {
                    if val type = program.getTypeOrNull(expr.refName) {
                        return type
                    }
                }
                else = ()
            }
            throw N2Error("Expected type but got " + expr, [expr.mark])
        }

        def evalNumericType(program: Program, expr: Expr): Type {
            val type = evalType(program, expr)
            when type {
                case int = type
                else {
                    throw N2Error("Expected numeric type but got " + type, [expr.mark])
                }
            }
        }

        def checkMinArgc(mark: Mark, args: List[Expr], argc: Int) {
            if args.size() < argc {
                throw N2Error(
                    "Expected at least " + argc + " args but got " + args.size(), [mark])
            }
        }

        def checkArgc(mark: Mark, args: List[Expr], argc: Int) {
            if args.size() != argc {
                throw N2Error(
                    "Expected " + argc + " args but got " + args.size(), [mark])
            }
        }

        def macro(mark: Mark, program: Program, macroName: String, args: List[Expr]): Self {
            switch macroName {
                case "js!" {
                    checkMinArgc(mark, args, 2)
                    js(mark, evalType(program, args[0]), args[1:])
                }
                else = throw N2Error("Unrecognized macro '" + macroName + "'", [mark])
            }
        }

        def assign(mark: Mark, lhs: Expr, rhs: Expr): Self {
            if lhs.kind == kGETVAR {
                return setvar(mark, lhs.var_, rhs)
            }
            throw N2Error(kindNames[lhs.kind] + " is not assignable", [mark])
        }

        def type(mark: Mark, type: Type): Self {
            val self = Self(mark, kTYPE, Type.meta)
            self.ty = type
            self
        }

        def nullwrap(mark: Mark, expr: Expr): Self {
            if tag!(expr.type) == tag!(Type, null_) {
                throw N2Error("null type cannot be nested", [mark])
            }
            if tag!(expr.type) == tag!(Type, meta) {
                throw N2Error("a concretely typed value is expected here", [mark])
            }
            val type = Type.null_(expr.type)
            unop(mark, kNULLWRAP, type, expr)
        }

        def nullexpr(mark: Mark): Self {
            Self(mark, kNULL, Type.meta)
        }

        def typednull(mark: Mark, type: Type): Self {
            Self(mark, kNULL, type)
        }

        def if_(mark: Mark, var cond: Expr, then: Expr, els: Expr): Self {
            val type = Type.common(mark, then.type, els.type)
            val self = Self(mark, kIF, type)
            self.cond = icast(cond, Type.bool)
            self.then = icast(then, type)
            self.els = icast(els, type)
            self
        }

        def while_(mark: Mark, cond: Expr, then: Expr): Self {
            val self = Self(mark, kWHILE, Type.void)
            self.cond = icast(cond, Type.int)
            self.then = then
            self
        }

        def list(mark: Mark, var args: List[Expr], itemType: Type?): Self {
            if not args and itemType.isEmpty() {
                val self = Self(mark, kARRAY, Type.meta)
                self.args = []
                self
            } else {
                val itype = if val t = itemType { t } else { args[0].type }
                args = args.map(a -> icast(a, itype))
                val self = Self(mark, kARRAY, Type.list(itype))
                self.args = args
                self
            }
        }

        def getitem(mark: Mark, owner: Expr, index: Expr): Expr {
            when owner.type {
                case list(itemType) {
                    val self = Self(mark, kARRAY_GET, itemType)
                    self.lhs = owner
                    self.rhs = index
                    self
                }
                else = throw N2Error("Subscripting not supported for " + owner.type, [mark])
            }
        }

        ## implicit cast
        def icast(var expr: Expr, type: Type): Expr {
            if type.isBool() and expr.type.isInt() {
                expr = unop(expr.mark, kINT_TO_BOOL, Type.bool, expr)
            }
            if type.isNull() and expr.kind == kNULL and expr.type.isMeta() {
                return typednull(expr.mark, type)
            }
            if type.isArray() and expr.kind == kARRAY and expr.type.isMeta() {
                Assert.that(expr.args.isEmpty())
                return icast(list(expr.mark, expr.args, null(type.itemType)), type)
            }
            if expr.type.isMeta() {
                throw N2Error("Expected expression, but got type", [expr.mark])
            }
            if expr.type == type or expr.type.isUnreachable() { # no cast needed
                return expr
            }
            if type.isVoid() { # cast to void
                return block(expr.mark, [expr, nop(expr.mark)])
            }
            if type.isVar() and not expr.type.isVoid() {
                return expr
            }
            if type.isNull() and not expr.type.isNull() {
                return icast(nullwrap(expr.mark, expr), type)
            }
            throw N2Error("Expected " + type + " but got " + expr.type, [expr.mark])
        }

        private def binop(mark: Mark, kind: Int, type: Type, lhs: Expr, rhs: Expr): Expr {
            val expr = Expr(mark, kind, type)
            expr.lhs = lhs
            expr.rhs = rhs
            expr
        }

        private def unop(mark: Mark, kind: Int, type: Type, arg: Expr): Expr {
            val expr = Expr(mark, kind, type)
            expr.arg = arg
            expr
        }

        def neg(mark: Mark, arg: Expr): Self {
            if arg.type.isInt() {
                if arg.kind == kINT {
                    return int(mark, -arg.intValue)
                } else {
                    return unop(mark, kINT_NEG, Type.int, arg)
                }
            }
            throw N2Error(
                "Invalid args to unary '-' (" + arg.type + ")", [mark])
        }

        def pos(mark: Mark, arg: Expr): Self {
            if arg.type.isInt() {
                return arg
            }
            throw N2Error(
                "Invalid args to unary '-' (" + arg.type + ")", [mark])
        }

        def incr(mark: Mark, expr: Expr): Self {
            if not expr.type.isInt() {
                throw N2Error("Only int types can be incremented but got " + expr.type, [mark])
            }
            switch expr.kind {
                case kGETVAR {
                    val self = Self(mark, kINTVAR_INCR, Type.int)
                    self.var_ = expr.var_
                    return self
                }
            }
            throw N2Error(expr.kindName + " expressions cannot be incremented", [mark])
        }

        def decr(mark: Mark, expr: Expr): Self {
            if not expr.type.isInt() {
                throw N2Error("Only int types can be decremented but got " + expr.type, [mark])
            }
            switch expr.kind {
                case kGETVAR {
                    val self = Self(mark, kINTVAR_DECR, Type.int)
                    self.var_ = expr.var_
                    return self
                }
            }
            throw N2Error(expr.kindName + " expressions cannot be decremented", [mark])
        }

        def add(mark: Mark, lhs: Expr, rhs: Expr): Self {
            if lhs.type.isInt() and rhs.type.isInt() {
                return binop(mark, kINT_ADD, Type.int, lhs, rhs)
            } else if lhs.type.isStr() and rhs.type.isStr() {
                return binop(mark, kSTR_ADD, Type.str, lhs, rhs)
            }
            throw N2Error(
                "Invalid args to binary '+' (" + lhs.type + "," + rhs.type + ")", [mark])
        }

        def sub(mark: Mark, lhs: Expr, rhs: Expr): Self {
            if lhs.type.isInt() and rhs.type.isInt() {
                return binop(mark, kINT_SUB, Type.int, lhs, rhs)
            }
            throw N2Error(
                "Invalid args to binary '-' (" + lhs.type + "," + rhs.type + ")", [mark])
        }

        def mul(mark: Mark, lhs: Expr, rhs: Expr): Self {
            if lhs.type.isInt() and rhs.type.isInt() {
                return binop(mark, kINT_MUL, Type.int, lhs, rhs)
            }
            throw N2Error(
                "Invalid args to binary '*' (" + lhs.type + "," + rhs.type + ")", [mark])
        }

        def div(mark: Mark, lhs: Expr, rhs: Expr): Self {
            if lhs.type.isInt() and rhs.type.isInt() {
                return binop(mark, kINT_DIV, Type.int, lhs, rhs)
            }
            throw N2Error(
                "Invalid args to binary '/' (" + lhs.type + "," + rhs.type + ")", [mark])
        }

        def rem(mark: Mark, lhs: Expr, rhs: Expr): Self {
            if lhs.type.isInt() and rhs.type.isInt() {
                return binop(mark, kINT_REM, Type.int, lhs, rhs)
            }
            throw N2Error(
                "Invalid args to binary '%' (" + lhs.type + "," + rhs.type + ")", [mark])
        }

        def eq(mark: Mark, lhs: Expr, rhs: Expr): Self {
            if lhs.type.isInt() and rhs.type.isInt() {
                return binop(mark, kINT_EQ, Type.int, lhs, rhs)
            }
            throw N2Error(
                "Invalid args to binary '==' (" + lhs.type + "," + rhs.type + ")", [mark])
        }

        def ne(mark: Mark, lhs: Expr, rhs: Expr): Self {
            if lhs.type.isInt() and rhs.type.isInt() {
                return binop(mark, kINT_NE, Type.int, lhs, rhs)
            }
            throw N2Error(
                "Invalid args to binary '!=' (" + lhs.type + "," + rhs.type + ")", [mark])
        }

        def lt(mark: Mark, lhs: Expr, rhs: Expr): Self {
            if lhs.type.isInt() and rhs.type.isInt() {
                return binop(mark, kINT_LT, Type.int, lhs, rhs)
            }
            throw N2Error(
                "Invalid args to binary '<' (" + lhs.type + "," + rhs.type + ")", [mark])
        }

        def le(mark: Mark, lhs: Expr, rhs: Expr): Self {
            if lhs.type.isInt() and rhs.type.isInt() {
                return binop(mark, kINT_LE, Type.int, lhs, rhs)
            }
            throw N2Error(
                "Invalid args to binary '<=' (" + lhs.type + "," + rhs.type + ")", [mark])
        }

        def and_(mark: Mark, var lhs: Expr, var rhs: Expr): Self {
            lhs = icast(lhs, Type.bool)
            rhs = icast(rhs, Type.bool)
            return binop(mark, kLOGICAL_AND, Type.bool, lhs, rhs)
        }

        def or_(mark: Mark, var lhs: Expr, var rhs: Expr): Self {
            lhs = icast(lhs, Type.bool)
            rhs = icast(rhs, Type.bool)
            return binop(mark, kLOGICAL_OR, Type.bool, lhs, rhs)
        }

        def ret(mark: Mark, expr: Expr): Self {
            return unop(mark, kRETURN, Type.unreachable, expr)
        }

        def block(mark: Mark, stmts: List[Expr]): Self {
            val type = if stmts { stmts.last().type } else { Type.void }
            val block = Expr(mark, kBLOCK, type)
            block.stmts = stmts
            block.newScope = true
            block
        }

        def seq(mark: Mark, stmts: List[Expr]): Self {
            if stmts.size() == 1 {
                return stmts[0]
            }
            val type = if stmts { stmts.last().type } else { Type.void }
            val block = Expr(mark, kBLOCK, type)
            block.stmts = stmts
            block.newScope = false
            block
        }

        def nop(mark: Mark): Self = seq(mark, [])

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
