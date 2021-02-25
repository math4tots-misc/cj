package cjx.jx

import cj.StringBuilder
import cj.Error

## Base 64 VLQ encoder util
class JXB64VLQ {

    def encode(var x: Int): String {
        if x == 0 {
            return "A"
        }
        val sb = StringBuilder()
        val negative = if x < 0 { x = -x; 1 } else { 0 }
        val firstChunk = x % 16
        x = x // 16
        val firstCont = if x { 32 } else { 0 }
        sb.char(_digit(firstCont + firstChunk * 2 + negative))
        while x {
            val chunk = x % 32
            x = x // 32
            val cont = if x { 32 } else { 0 }
            sb.char(_digit(cont + chunk))
        }
        sb.toString()
    }

    ## Converts a numeric digit to a base64 digit
    def _digit(d: Int): Char {
        if d < 0 or d >= 64 {
            throw Error("Invalid base64 digit: " + d)
        } else if d <= 25 {
            ('A'.toInt() + d).toChar()
        } else if d <= 51 {
            ('a'.toInt() + d - 26).toChar()
        } else if d <= 61 {
            ('0'.toInt() + d - 52).toChar()
        } else if d == 62 {
            '+'
        } else {
            Assert.equal(d, 63)
            '-'
        }
    }
}
