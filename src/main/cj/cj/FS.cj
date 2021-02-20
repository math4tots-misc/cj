package cj

import cj.Buffer

native class FS {
    def __get_sep(): String
    def readFile(path: String): String
    def readFileBytes(path: String): Buffer
    def writeFile(path: String, data: String)
    def writeFileBytes(path: String, data: Buffer)
}
