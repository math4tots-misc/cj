package compiler.solver

import compiler.solver.CJItemFinderMixin
import compiler.solver.CJTypeSolverMixin
import compiler.CJError
import compiler.CJData
import compiler.CJScope
import compiler.CJAst
import compiler.CJIR
import compiler.CJIR.Type

class CJSolver: CJTypeSolverMixin, CJItemFinderMixin {

    class Task: Repr {
        val name: String
        val detail: String
        val f: Fn[Unit]
        def repr(self): String = "Task(" + name + "," + detail + ")"
    }

    val sourceRoots: List[String]
    val todos: List[List[Task]] = []
    val itemMap: Map[String, CJIR.ItemDef] = Map()

    def todo(self, level: Int, name: String, detail: String, f: Fn[Unit]) {
        while level >= todos.size() {
            todos.add([])
        }
        todos[level].add(Task(name, detail, f))
    }

    def solve(self) {
        var repeat = true
        while repeat {
            var i = 0
            while i < todos.size() and not todos[i] {
                i++
            }
            if i < todos.size() {
                todos[i].pop().f.call()
            } else {
                repeat = false
            }
        }
    }

    def addFile(self, file: CJAst.File) {
        val fileScope = CJScope.newRoot()
        val packageName = file.packageName
        for import_ in file.imports {
            fileScope.set(
                import_.mark,
                import_.alias,
                CJData.fullName(import_.fullName))
        }
        val fullName = packageName + "." + file.item.shortName
        addItem(fileScope, fullName, file.item)
    }

    def getItemDefOrNull(self, fullName: String): CJIR.ItemDef? {
        if val item = itemMap.getOrNull(fullName) {
            null(item)
        } else {
            if val astFile = parseFileForItem(fullName) {
                addFile(astFile)
                if val item = itemMap.getOrNull(fullName) {
                    null(item)
                } else { null }
            } else { null }
        }
    }

    private def addItem(self, outerScope: CJScope, fullName: String, item: CJAst.Item) {
        outerScope.set(item.mark, item.shortName, CJData.fullName(fullName))
        val itemScope = CJScope(outerScope)
        itemMap[fullName] = when item.kind {
            case class_ {
                val iritem = CJIR.ClassDef(item.mark, item.comment, item.modifiers, fullName)
                processItemTypeParams(itemScope, item, iritem)
                CJIR.ItemDef.class_(iritem)
            }
            case union_ {
                val iritem = CJIR.UnionDef(item.mark, item.comment, item.modifiers, fullName)
                processItemTypeParams(itemScope, item, iritem)
                CJIR.ItemDef.union_(iritem)
            }
            case trait_ = {
                val iritem = CJIR.TraitDef(item.mark, item.comment, item.modifiers, fullName)
                processItemTypeParams(itemScope, item, iritem)
                CJIR.ItemDef.trait_(iritem)
            }
        }
        for member in item.members {
            when member {
                case item(subitem) = addItem(
                    itemScope, fullName + "$" + subitem.shortName, subitem)
                else = ()
            }
        }
    }

    private def processItemTypeParams[I: CJIR.ItemDef](
            self, scope: CJScope, astItem: CJAst.Item, item: I) {
        for astTypeParam in astItem.typeParameters {
            val typeParam = CJIR.TypeParameter(astTypeParam.mark, true, astTypeParam.name)
            scope.set(typeParam.mark, typeParam.name, CJData.type(Type.variable(typeParam)))
            item.addTypeParameter(typeParam)
        }
    }
}
