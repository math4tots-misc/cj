package cj

## Basic Asynchronous utils
native class AIO {
    def wait(seconds: Double): Promise[Unit] = js!(
        Promise[Unit],
        "new Promise((resolve,reject)=>setTimeout(resolve,",seconds,"*1000))")
}
