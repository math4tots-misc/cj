package sample.web

import cjx.js.web.HTMLElement
import cjx.js.web.HTMLDivElement
import cjx.js.web.Document

class Sample1 {
    def main() = {
        val document = Document.get()
        document.title = "New Title"
        val out : HTMLDivElement = document.getElementBydId("out")
        out.innerHTML = "Hello!<br/>"

        val button : HTMLElement = document.getElementBydId("button")
        button.onclick(event -> {
            out.innerHTML = out.innerHTML + "clicked<br/>"
        })

        document.onkeydown(event -> {
            out.innerHTML = out.innerHTML + "keydown " + event.key + "<br/>"
        })
    }
}
