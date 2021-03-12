package www.wa

import cj.ArrayBufferOrView
import www.JSObject

native class WebAssembly {
    native class ResultObject {
        def __get_module(self): Module = js!(Module, self, ".module")
        def __get_instance(self): Instance = js!(Instance, self, ".instance")
    }
    native class Module {
    }
    native class Instance {
        def __get_exports(self): JSObject = js!(JSObject, self, ".exports")
    }
    native class Table {
    }
    native class Memory {
    }
    def instantiate[S: ArrayBufferOrView](
        bufferSource: S,
        importObject: JSObject): Promise[ResultObject] = js!(
            Promise[ResultObject],
            "WebAssembly.instantiate(", bufferSource, ",", importObject, ")")
}
