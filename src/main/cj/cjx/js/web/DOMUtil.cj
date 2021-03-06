package cjx.js.web

import cjx.js.web.HTMLInputElement
import cjx.js.web.Event
import cjx.js.web.HTMLDivElement
import cjx.js.web.HTMLElement
import cjx.js.web.Document
import cjx.js.web.HTMLButtonElement
import cjx.js.web.MouseEvent

class DOMUtil {

    @variadic def div(children: List[HTMLElement]): HTMLDivElement {
        val div: HTMLDivElement = Document.get().createElement()
        for child in children {
            div.appendChild(child)
        }
        div
    }

    def text(text: String): HTMLElement {
        val div: HTMLDivElement = Document.get().createElement()
        div.style.display = "inline-block"
        div.innerText = text
        div
    }

    def button(text: String, onclick: Fn[MouseEvent, Unit]): HTMLButtonElement {
        val button: HTMLButtonElement = Document.get().createElement()
        button.innerText = text
        button.onclick(onclick)
        button
    }

    def checkbox(init: Bool, onchange: Fn[Event, Bool, Unit]): HTMLInputElement {
        val checkbox: HTMLInputElement = Document.get().createElement()
        checkbox.type = "checkbox"
        checkbox.checked = init
        checkbox.onchange(event -> onchange.call(event, checkbox.checked))
        checkbox
    }

    def textinput(init: String, onchange: Fn[Event, String, Unit]): HTMLInputElement {
        val textinput: HTMLInputElement = Document.get().createElement()
        textinput.type = "text"
        textinput.value = init
        textinput.onchange(event -> onchange.call(event, textinput.value))
        textinput
    }
}
