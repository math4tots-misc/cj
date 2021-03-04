package cjx.chip8

import cjx.js.web.KeyboardEvent
import cj.Uint8Array
import cjx.js.web.Window

class C8Keyboard {
    static val window: Window = Window.get()
    static val keymap: Map[Int, Int] = Map(
        49: 0x1, # 1
        50: 0x2, # 2
        51: 0x3, # 3
        52: 0xc, # 4
        81: 0x4, # Q
        87: 0x5, # W
        69: 0x6, # E
        82: 0xD, # R
        65: 0x7, # A
        83: 0x8, # S
        68: 0x9, # D
        70: 0xE, # F
        90: 0xA, # Z
        88: 0x0, # X
        67: 0xB, # C
        86: 0xF, # V
    )

    var onNextKeyPress: Fn[Int, Unit]? = null
    val keysPressed: Uint8Array = Uint8Array.withSize(16)

    def(): Self {
        val self = __malloc()
        window.onkeydown(event -> onKeyDown(event))
        window.onkeyup(event -> onKeyUp(event))
        self
    }

    def isKeyPressed(self, keyCode: Int) {
        keyCode >= 0 and keyCode < keysPressed.size() and keysPressed[keyCode]
    }

    def onKeyDown(self, event: KeyboardEvent) {
        val which: Int = event.field("which").unsafeCast()
        if val key = keymap.getOrNull(which) {
            if not keysPressed[key] {
                IO.println("keydown = " + key)
                keysPressed[key] = 1
                if val nkp = onNextKeyPress {
                    nkp.call(key)
                    onNextKeyPress = null
                }
            }
        }
    }

    def onKeyUp(self, event: KeyboardEvent) {
        val which: Int = event.field("which").unsafeCast()
        if val key = keymap.getOrNull(which) {
            IO.println("keyup = " + key)
            keysPressed[key] = 0
        }
    }
}
