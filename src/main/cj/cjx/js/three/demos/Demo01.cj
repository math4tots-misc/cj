package cjx.js.three.demos

import www.JSObject
import cj.JSON
import cjx.js.web.Document
import cjx.js.web.Window
import cjx.js.three.Three

class Demo01 {
    static val window: Window = Window.get()
    static val document: Document = Document.get()
    static val three: Three = Three.get()
    static var scene: JSObject = ?
    static var renderer: JSObject = ?
    static var camera: JSObject = ?
    static var cube: JSObject = ?

    def main() {
        scene = three.field("Scene").new()
        camera = three.field("PerspectiveCamera").new(
            75, window.innerWidth / window.innerHeight, 0.1, 1000)
        renderer = three.field("WebGLRenderer").new()
        renderer.call("setSize", window.innerWidth, window.innerHeight)
        document.field("body").call("appendChild", renderer.field("domElement"))

        val geometry = three.field("BoxGeometry").new()
        val material = three.field("MeshBasicMaterial").new(JSON.object("color": 0x00ff00))
        cube = three.field("Mesh").new(geometry, material)
        scene.call("add", cube)
        camera.field("position").setField("z", 5)
        animate()
    }

    def animate() {
        # window.requestAnimationFrame(ts -> animate())
        val rotation = cube.field("rotation")
        rotation.setField("x", rotation.field("x").toDouble() + 0.02)
        rotation.setField("y", rotation.field("y").toDouble() + 0.09)
        renderer.call("render", scene, camera)
    }
}
