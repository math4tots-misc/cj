package www.wa

import cj.ArrayBuffer
import cj.ArrayBufferOrView
import www.JSObject

native class WebAssembly {
    native class ResultObject {
        def __get_module(self): Module = js!(Module, self, ".module")
        def __get_instance(self): Instance = js!(Instance, self, ".instance")
    }
    native class Module {
        def[S: ArrayBufferOrView](bufferSource: S): Self = js!(
            Self, "new WebAssembly.Module(", bufferSource, ")")
    }
    native class Instance {
        def(module: Module, importObject: JSObject): Self = js!(
            Self, "new WebAssembly.Instance(", module, ",", importObject, ")")
        def __get_exports(self): JSObject = js!(JSObject, self, ".exports")
    }
    native class Table {
    }
    native class Memory {
        def(init: Int, max: Int): Self = js!(
            Self, "new WebAssembly.Memory({initial: ", init, ", maximum: ", max, "})")
        def __get_buffer(self): ArrayBuffer = js!(ArrayBuffer, self, ".buffer")
    }
    def instantiate[S: ArrayBufferOrView](
        bufferSource: S,
        importObject: JSObject): Promise[ResultObject] = js!(
            Promise[ResultObject],
            "WebAssembly.instantiate(", bufferSource, ",", importObject, ")")
}
