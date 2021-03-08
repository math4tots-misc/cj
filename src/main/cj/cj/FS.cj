package cj

import cj.Buffer

native class FS {
    def __get_sep(): String
    @variadic def join(parts: List[String]): String
    def dirname(path: String): String
    def isfile(path: String): Bool
    def isdir(path: String): Bool
    def readFile(path: String): String
    def readFileBytes(path: String): Buffer
    def writeFile(path: String, data: String)
    def writeFileBytes(path: String, data: Buffer)
}
