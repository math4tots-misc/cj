package compiler.solver

import compiler.CJAst
import compiler.CJParser
import cj.FS

trait CJItemFinderMixin {

    def __get_sourceRoots(self): List[String]

    def parseFileForItem(self, fullName: String): CJAst.File? {
        val relpath = fullName.replace(".", FS.sep) + ".cj"
        for root in sourceRoots {
            val path = FS.join(root, relpath)
            if FS.isfile(path) {
                val contents = FS.readFile(path)
                return null(CJParser.parse(path, contents))
            }
        }
        null
    }
}
