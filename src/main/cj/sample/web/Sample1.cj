package sample.web

import cj.js.web.Document

class Sample1 {
    def main() = {
        val document = Document.get()
        document.title = "New Title"
    }
}
