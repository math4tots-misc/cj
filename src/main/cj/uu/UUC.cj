package uu

import uu.UUIR
import uu.UULoader

## Global CJ context
class UUC {
    val loader: UULoader = UULoader()
    val module: UUIR.Module = UUIR.Module()

    def addSourceRoot(self, sourceRoot: String) {
        loader.sourceRoots.add(sourceRoot)
    }

    def load(self, itemNames: List[String]) {
        loader.loadAllDeps(itemNames)
        for fileAst in loader.getAllLoadedItems() {
            val type = UUIR.Type(fileAst.item.mark, fileAst.item.comment, fileAst.item.name)
            module.addType(type)
        }
    }
}
