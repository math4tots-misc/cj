package cj

## Basic Asynchronous utils
native class AIO {
    def wait(seconds: Double): Promise[Unit]
}
