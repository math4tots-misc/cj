package compiler

import compiler.CJItemKind
import compiler.CJAst
import cjx.parser.MError
import compiler.CJLR
import compiler.CJItemFinder

## CJ Solver
## Converts CJAst to CJLR
class CJS2 {
    val itemFinder: CJItemFinder = CJItemFinder()
    val program: CJLR.Program = CJLR.Program()
    val seenItemNames: Set[String] = SetOf()
    val todoItemNames: List[String] = []

    def addSourceRoot(self, sourceRoot: String) {
        itemFinder.addSourceRoot(sourceRoot)
    }

    def queueItem(self, itemName: String) {
        if itemName not in seenItemNames {
            todoItemNames.add(itemName)
        }
    }

    def solve(self) {
        while todoItemNames {
            val itemName = todoItemNames.pop()
            addItemWithName(itemName)
        }
    }

    private def addItemWithName(self, itemName: String) {
        if val fileAst = itemFinder.find(itemName) {
            pass0(fileAst)
        } else {
            throw MError("Item " + itemName + " not found", [])
        }
    }

    private def pass0(self, fileAst: CJAst.File) {
        Assert(fileAst.item.kind == CJItemKind.class_)
        Assert(not fileAst.item.typeParameters)
        val itemName = fileAst.packageName + "." + fileAst.item.shortName
        val type = CJLR.Type(
            fileAst.item.mark,
            fileAst.item.comment,
            fileAst.item.modifiers,
            fileAst.item.shortName)
        program.addType(type)
        for import_ in fileAst.imports {
            addItemWithName(import_.fullName)
        }
    }
}
