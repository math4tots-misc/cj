package uu

import cjx.re.Regex
import uu.UUParser
import cj.FS
import uu.UUAst

## Finds sources, and unnests nested items so that it appears as though each
## item is defined in its own file.
class UULoader {
    static val outerNameRe: Regex = Regex("([a-z_][A-Za-z0-9_]*\\.)+[A-Z][A-Za-z0-9_]*")

    val sourceRoots: List[String] = []
    val fileAstMap: Map[String, UUAst.File] = MapOf()
    val itemAstMap: Map[String, UUAst.File] = MapOf()

    def load(self, itemName: String): UUAst.File? {
        if itemName not in itemAstMap {
            val outerItemName = outerNameRe.match(itemName).get().matchText
            if val fileAst = loadFileAst(outerItemName) {
                # NOTE: there's a chance that the outer item is found, but the
                # target item might not actually be found. In this case we return null.
                unnest(fileAst)
            }
        }
        itemAstMap.getOrNull(itemName)
    }

    def addFileAst(self, fileAst: UUAst.File) {
        fileAstMap[fileAst.item.name] = fileAst
    }

    private def loadFileAst(self, outerItemName: String): UUAst.File? {
        if outerItemName not in fileAstMap {
            if val path = findPath(outerItemName) {
                val fileAst = UUParser.parse(path, FS.readFile(path))
                fileAstMap[outerItemName] = fileAst
            } else { return null }
        }
        null(fileAstMap[outerItemName])
    }

    private def findPath(self, outerItemName: String): String? {
        val relpath = FS.joinList(outerItemName.split(".")) + ".cj"
        for sourceRoot in sourceRoots {
            val path = FS.join(sourceRoot, relpath)
            if FS.isfile(path) {
                return null(path)
            }
        }
        null
    }

    private def unnest(self, fileAst: UUAst.File) {
        val stack = [(fileAst.packageName, fileAst.imports.clone(), fileAst.item)]
        while stack {
            val (outerName, imports, item) = stack.pop()

            Assert(item.name not in itemAstMap)
            itemAstMap[item.name] = UUAst.File(item.mark, outerName, imports, item)

            # add immediately nested items in the imports list
            for member in item.members {
                when member {
                    case item(child) {
                        imports.add(UUAst.Import(child.mark, child.name, child.shortName))
                    }
                    else = ()
                }
            }

            # recurse to nested items
            for member in item.members {
                when member {
                    case item(child) {
                        stack.add((item.name, imports.clone(), child))
                    }
                    else = ()
                }
            }
        }
    }
}
