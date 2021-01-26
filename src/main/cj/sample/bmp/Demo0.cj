package sample.bmp

import cj.FS
import cjx.bmp.Bitmap

## Sample usage of Bitmap class
class Demo0 {
    def main() = {
        val w = 300
        val h = 300
        val bmp = Bitmap.withDimensions(w, h)

        for y = 0; y < h; y += 1 {
            for x = 0; x < w; x += 1 {
                bmp[x, y] = (x.toDouble() / w, y.toDouble() / h, 0.2)
            }
        }

        val buffer = bmp.toBMPBuffer()
        FS.writeFileBytes("target/out.bmp", buffer)
    }
}
