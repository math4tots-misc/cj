package www.sourcemap

import cjx.base64.Base64
import cj.FS
import www.sourcemap.JSB64VLQ
import cjx.parser.Mark
import cj.StringBuilder

## Utility for building up javascript source with accompanying sourcemap.
class JSBuilder {
    private val src: StringBuilder = StringBuilder()
    private val sources: List[String] = []
    private val sourceIdsByName: Map[String, Int] = MapOf()
    private val mapping: StringBuilder = Default()
    private var currentGeneratedColumn = 0
    private var lastGeneratedColumn = 0
    private var lastSourceId = 0
    private var lastSourceLine = 0
    private var lastSourceColumn = 0
    private var generatedLineStart = true
    var jsFilePath: String = ?
    var sourceRoot: String = ?
    var includeSourceMapAsDataURL = true

    def getSource(self): String {
        val base = src.toString()
        if includeSourceMapAsDataURL {
            base + "\n//" + "# sourceMappingURL=data:;base64," + Base64.encodeString(
                getSourceMap())
        } else if is_set!(self, jsFilePath) {
            val index = jsFilePath.lastIndexOf(FS.sep)
            val jsFilePath = if index == -1 { jsFilePath } else { jsFilePath[index + 1:] }
            # The '//.. sourceMap...' pattern seems to mess with node's ability
            # to detect the sourcemap, so we split up the string here
            base + "\n//" + "# sourceMappingURL=" + jsFilePath + ".map"
        } else {
            base
        }
    }

    def getSourceMap(self): String {
        val sb = StringBuilder()
        sb.str("{\"version\":3,")
        if is_set!(self, jsFilePath) {
            sb.str("\"file\":\"" + jsFilePath + "\",")
        }
        if is_set!(self, sourceRoot) {
            sb.str("\"sourceRoot\":\"" + sourceRoot + "\",")
        }
        sb.str("\"sources\":[")
        for i = 0; i < sources.size(); i++ {
            if i {
                sb.char(',')
            }
            sb.char('"')
            sb.str(sources[i])
            sb.char('"')
        }
        sb.str("],")
        sb.str("\"names\":[],")
        sb.str("\"mappings\":\"")
        sb.str(mapping.toString())
        sb.str("\"}")
        sb.toString()
    }

    def char(self, ch: Char) {
        if ch == '\n' {
            mapping.char(';')
            currentGeneratedColumn = 0
            lastGeneratedColumn = 0
            generatedLineStart = true
        } else {
            currentGeneratedColumn++
        }
        src.char(ch)
    }

    def str(self, string: String) = string.iter().forEach(c -> char(c))

    def addMark(self, mark: Mark) {
        addMapping(
            mark.filepath,
            if mark.line > 0 { mark.line - 1 } else { 0 },
            if mark.column > 0 { mark.column - 1 } else { 0 })
    }

    private def addMapping(self, sourceFileName: String, sourceLine: Int, sourceColumn: Int) {
        val sourceId = getSourceId(sourceFileName)

        val generatedColumnDiff = currentGeneratedColumn - lastGeneratedColumn
        val sourceIdDiff = sourceId - lastSourceId
        val sourceLineDiff = sourceLine - lastSourceLine
        val sourceColumnDiff = sourceColumn - lastSourceColumn

        if generatedLineStart {
            generatedLineStart = false
        } else {
            mapping.char(',')
        }

        mapping.str(JSB64VLQ.encode(generatedColumnDiff))
        mapping.str(JSB64VLQ.encode(sourceIdDiff))
        mapping.str(JSB64VLQ.encode(sourceLineDiff))
        mapping.str(JSB64VLQ.encode(sourceColumnDiff))

        lastGeneratedColumn = currentGeneratedColumn
        lastSourceId = sourceId
        lastSourceLine = sourceLine
        lastSourceColumn = sourceColumn
    }

    private def getSourceId(self, sourceFileName: String): Int {
        if val id = sourceIdsByName.getOrNull(sourceFileName) { id } else {
            val id = sources.size()
            sources.add(sourceFileName)
            sourceIdsByName[sourceFileName] = id
            id
        }
    }
}
