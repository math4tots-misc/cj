package sample.web

import www.dom.HTMLElement
import www.dom.HTMLDivElement
import www.dom.Document

class Sample1 {
    def main() = {
        val document = Document.get()
        document.title = "New Title"
        val out : HTMLDivElement = document.getElementById("out")
        out.innerHTML = "Hello!<br/>"

        val button : HTMLElement = document.getElementById("button")
        button.onclick(event -> {
            out.innerHTML = out.innerHTML + "clicked<br/>"
        })

        document.onkeydown(event -> {
            out.innerHTML = out.innerHTML + "keydown " + event.key + "<br/>"
        })
    }
}
