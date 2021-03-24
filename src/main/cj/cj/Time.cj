package cj

native class Time {
    ## Unix timestamp
    def now(): Double = js!(Double, "Date.now()/1000")
}
