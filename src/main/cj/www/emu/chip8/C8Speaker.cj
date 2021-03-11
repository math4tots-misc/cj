package www.emu.chip8

import www.JSObject

class C8Speaker {
    var _audioCtx: JSObject? = null
    var _gain: JSObject? = null
    var _finish: JSObject? = null
    var oscillator: JSObject? = null

    private def init(self) {
        val audioCtx: JSObject = js!(JSObject, "AudioContext").new()
        val gain: JSObject = audioCtx.call("createGain")
        val finish: JSObject = audioCtx.field("destination")
        gain.call("connect", finish)
        self._audioCtx = null(audioCtx)
        self._gain = null(gain)
        self._finish = null(finish)
    }

    private def __get_audioCtx(self): JSObject = _audioCtx.get()
    private def __get_gain(self): JSObject = _gain.get()
    private def __get_finish(self): JSObject = _finish.get()

    def play(self, frequency: Double) {
        if _audioCtx.isEmpty() {
            init()
        }
        if oscillator.isEmpty() {
            IO.println("STARTING SOUND")
            val osc = audioCtx.call("createOscillator")
            oscillator = null(osc)
            osc.field("frequency").call(
                "setValueAtTime", if frequency { frequency } else { 440 },
                audioCtx.field("currentTime"))
            osc.setField("type", "square")
            osc.call("connect", gain)
            osc.call("start")
        }
    }

    def stop(self) {
        if val osc = oscillator {
            if _audioCtx.isEmpty() {
                init()
            }
            IO.println("STOPPING SOUND")
            oscillator = null
            osc.call("stop")
            osc.call("disconnect")
        }
    }
}
