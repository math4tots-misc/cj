package compiler

import cj.FS
import compiler.CJParser
import cjx.re.Regex
import compiler.CJAst

class CJItemFinder {
    static private val outerNameRe: Regex = Regex("([a-z_][A-Za-z0-9_]*\\.)+[A-Z][A-Za-z0-9_]*")

    private val sourceRoots: List[String] = []
    private val fileAstMap: Map[String, CJAst.File] = MapOf()
    private val itemAstMap: Map[String, CJAst.File] = MapOf()

    def find(self, itemName: String): CJAst.File? {
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

    def addFileAst(self, fileAst: CJAst.File) {
        fileAstMap[fileAst.packageName + "." + fileAst.item.shortName] = fileAst
    }

    def addSourceRoot(self, sourceRoot: String) = sourceRoots.add(sourceRoot)

    private def loadFileAst(self, outerItemName: String): CJAst.File? {
        if outerItemName not in fileAstMap {
            if val path = findPath(outerItemName) {
                val fileAst = CJParser.parse(path, FS.readFile(path))
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

    private def unnest(self, fileAst: CJAst.File) {
        val stack = [(fileAst.packageName, fileAst.imports.clone(), fileAst.item)]
        while stack {
            val (outerName, imports, item) = stack.pop()
            val itemName = outerName + "." + item.shortName

            Assert(itemName not in itemAstMap)
            itemAstMap[itemName] = CJAst.File(item.mark, outerName, imports, item)

            # add immediately nested items in the imports list
            for member in item.members {
                when member {
                    case item(child) {
                        val childName = itemName + "." + child.shortName
                        imports.add(CJAst.Import(child.mark, childName, child.shortName))
                    }
                    else = ()
                }
            }

            # recurse to nested items
            for member in item.members {
                when member {
                    case item(child) {
                        stack.add((itemName, imports.clone(), child))
                    }
                    else = ()
                }
            }
        }
    }
}
