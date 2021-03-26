package cj

import cj.Uint8Array
import cj.DataView
import cj.BufferLike
import cj.ArrayBuffer
import cj.DynamicBuffer

native class FS {
    def __get_sep(): String = js!(String, "require('path').sep")
    def cwd(): String = js!(String, "process.cwd()")
    @variadic def join(parts: List[String]): String = js!(String, "require('path').join(...", parts, ")")
    def normalize(path: String): String = js!(String, "require('path').normalize(", path, ")")
    def basename(path: String): String = js!(String, "require('path').basename(", path, ")")
    def dirname(path: String): String = js!(String, "require('path').dirname(", path, ")")
    def exists(path: String): Bool = js!(Bool, "require('fs').existsSync(", path, ")")
    def isfile(path: String): Bool = exists(path) and js!(Bool, "require('fs').lstatSync(", path, ").isFile()")
    def isdir(path: String): Bool = exists(path) and js!(Bool, "require('fs').lstatSync(", path, ").isDirectory()")
    def readFile(path: String): String = js!(String, "require('fs').readFileSync(", path, ",'utf-8')")
    def readFileBytes(path: String): Uint8Array = js!(Uint8Array, "require('fs').readFileSync(", path, ")")
    def writeFile(path: String, data: String) = _writeUnsafe(path, data)
    def writeFileBytes[B: BufferLike](path: String, data: B) = _writeUnsafe(path, DataView(data))
    def writeArrayBuffer(path: String, data: ArrayBuffer) = _writeUnsafe(path, data)

    private def _writeUnsafe[T](path: String, t: T) {
        val dirname = js!(String, "require('path').dirname(", path, ")")
        js!(Unit, "require('fs').mkdirSync(", dirname, ",{recursive:true})")
        js!(Unit, "require('fs').writeFileSync(", path, ",", t, ")")
    }
}
