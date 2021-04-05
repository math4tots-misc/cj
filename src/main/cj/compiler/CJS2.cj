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
    val queuedItemNames: List[String] = []

    def addSourceRoot(self, sourceRoot: String) {
        itemFinder.addSourceRoot(sourceRoot)
    }

    def queueItem(self, itemName: String) {
        queuedItemNames.add(itemName)
    }

    def solve(self) {
        while queuedItemNames {
            val itemName = queuedItemNames.pop()
            solveItemWithName(itemName)
        }
    }

    private def solveItemWithName(self, itemName: String) {
        if val fileAst = itemFinder.find(itemName) {
            solveItem(fileAst)
        } else {
            throw MError("Item " + itemName + " not found", [])
        }
    }

    private def solveItem(self, fileAst: CJAst.File) {
        Assert(fileAst.item.kind == CJItemKind.class_)
        Assert(not fileAst.item.typeParameters)
        val itemName = fileAst.packageName + "." + fileAst.item.shortName
        val type = CJLR.Type(
            fileAst.item.mark,
            fileAst.item.comment,
            fileAst.item.modifiers,
            fileAst.item.shortName)
        program.addType(type)
    }
}
