package cjx.xx

import cjx.xx.llir.XXLLIRClass
import cjx.xx.XXError
import cjx.xx.XXMark
import cjx.xx.XXAst
import cjx.xx.llir.XXLLIRType

@derive(new)
class XXSolver {
    val classMap: Map[String, XXLLIRClass] = Map()
    val templateMap: Map[String, Tuple[Scope, XXAst.Item]] = Map()
    val traitMap: Map[String, Tuple[Scope, String, XXAst.Item]] = Map()
    val todos: List[List[Fn[Unit]]] = []

    def todo(self, level: Int, f: Fn[Unit]) {
        while level >= todos.size() {
            todos.add([])
        }
        todos[level].add(f)
    }

    def solve(self) {
        var repeat = true
        while repeat {
            var i = 0
            while i < todos.size() and not todos[i] {
                i++
            }
            if i < todos.size() {
                todos[i].pop().call()
            } else {
                repeat = false
            }
        }
    }

    @derive(repr)
    union Data {
        case number(Double)
        case string(String)
        case fullName(String)
        case type(XXLLIRType)
    }

    class Scope {
        val parent: Nullable[Scope]
        val map: Map[String, Data] = Map()
        def new(p: Self): Self = __malloc(null(p))
        def newRoot(): Self = __malloc(null)
    }

    def scopeSet(self, mark: XXMark, scope: Scope, key: String, value: Data) {
        if key in scope.map {
            throw XXError("Name '" + key + "' already defined in this scope", [mark])
        }
        scope.map[key] = value
    }

    def scopeGetOrNull(self, var scope: Scope, key: String): Nullable[Data] {
        while true {
            if null(value) = scope.map.getOrNull(key) {
                return null(value)
            }
            if null(parent) = scope.parent {
                scope = parent
            } else {
                return null
            }
        }
    }

    def scopeGet(self, mark: XXMark, scope: Scope, key: String): Data {
        if null(value) = scopeGetOrNull(scope, key) {
            value
        } else {
            throw XXError("Name '" + key + "' not found in this scope", [mark])
        }
    }

    def scopeGetString(self, mark: XXMark, scope: Scope, key: String): String {
        val data = scopeGet(mark, scope, key)
        when data {
            case string(value) = value
            else = throw XXError("Expected string but got " + data.repr(), [mark])
        }
    }

    def solveType(self, scope: Scope, astType: XXAst.Type): XXLLIRType {
        throw XXError("TODO solveType", [astType.mark])
    }

    def solveCompileTimeBoolExpr(self, scope: Scope, expr: XXAst.Expr): Bool {
        throw XXError("TODO solveCompileTimeBoolExpr", [expr.mark])
    }

    def solveClassOrInterfaceType(self, scope: Scope, astType: XXAst.Type): String {
        val type = solveType(scope, astType)
        when type {
            case klass(clsname) = clsname
            else = throw XXError("Expected class or interface type", [astType.mark])
        }
    }

    def addFile(self, file: XXAst.File) {
        val packageName = file.packageName
        val fileScope = Scope.newRoot()
        scopeSet(file.mark, fileScope, "@package", Data.string(packageName))
        for import_ in file.imports {
            scopeSet(import_.mark, fileScope, import_.alias, Data.fullName(import_.fullName))
        }
        for astItem in file.items {
            val itemFullName = packageName + "." + astItem.shortName
            scopeSet(astItem.mark, fileScope, astItem.shortName, Data.fullName(itemFullName))
        }
        for astItem in file.items {
            val itemFullName = packageName + "." + astItem.shortName
            addItem0(fileScope, itemFullName, astItem)
        }
    }

    private def addItem0(self, outerScope: Scope, fullName: String, astItem: XXAst.Item) {
        if astItem.templateParameters {
            templateMap[fullName] = (outerScope, astItem)
        } else {
            val itemScope = Scope(outerScope)
            addItem(itemScope, fullName, astItem)
        }
    }

    private def addItem(self, itemScope: Scope, itemName: String, astItem: XXAst.Item) {
        for nestedItem in astItem.nestedItems {
            val nestedItemName = itemName + "$" + nestedItem.shortName
            addItem0(itemScope, nestedItemName, nestedItem)
        }
        when astItem.kind {
            case class_ = addClass(itemScope, itemName, astItem)
            case trait_ = { traitMap[itemName] = (itemScope, itemName, astItem) }
            case union_ = throw XXError("TODO addItem union", [astItem.mark])
            case interface_ = throw XXError("TODO addItem interface", [astItem.mark])
        }
    }

    private def addClass(self, itemScope: Scope, itemName: String, astItem: XXAst.Item) {
        scopeSet(astItem.mark, itemScope, "Self", Data.fullName(itemName))
        val cls = XXLLIRClass(astItem.mark, astItem.modifiers, itemName)
        classMap[itemName] = cls
        todo(0, () -> {
            for decl in astItem.bases {
                if (decl.condition.isEmpty() or
                        solveCompileTimeBoolExpr(itemScope, decl.condition.get())) {
                    val base = solveClassOrInterfaceType(itemScope, decl.type)
                    if classMap[base].isInterface() {
                        cls.interfaces.add(base)
                    } else {
                        if cls.superClass != "java.lang.Object" {
                            throw XXError("Multiple base classes are not allowed", [decl.mark])
                        }
                        cls.superClass = base
                    }
                }
            }
        })
        todo(1, () -> {
        })
    }
}
