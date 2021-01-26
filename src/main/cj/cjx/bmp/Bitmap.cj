package cjx.bmp

import cj.Buffer
import cjx.bmp.Color
import cj.Int32Array

## Quick and dirty class for playing with bitmaps
##
## Coordinates start from (0, 0) in the lower-left corner
##
class Bitmap {
    val width : Int
    val data : Int32Array # 32-bit RGBA data

    def withDimensions(width: Int, height: Int) : Self = {
        val data = Int32Array.withSize(width * height)
        Bitmap.__malloc(width, data)
    }

    def __get_height(self: Self): Int = self.data.size() // width

    def __getitem(self: Self, x: Int, y: Int): Color = {
        val i = y * width + x
        Color.fromI32RGBA(data[i])
    }

    def __setitem(self: Self, x: Int, y: Int, color: Color) {
        val i = y * width + x
        data[i] = color.toI32RGBA()
    }

    ## Converts the bitmap data into 32bpp BMP data, and returns the contents as
    ## a Bytes value. This Bytes object can be directly written out to a file and be
    ## a valid *.bmp.
    ##
    ## Reference: https://en.wikipedia.org/wiki/BMP_file_format
    ##
    def toBMPBuffer(self: Self): Buffer = {
        # 14 (file header)
        # 40 (dib header (Windows BITMAPINFOHEADER))
        # 4 * data.size() (pixel data)
        val bytesize = 14 + 40 + 4 * data.size()
        val width = self.width
        val height = self.height
        val out = Buffer.withCapacity(bytesize)

        # -- file header --
        out.addUTF8("BM") # magic
        out.addI32(bytesize) # size of BMP file in bytes
        out.addU16(0) # reserved
        out.addU16(0) # reserved
        out.addI32(14 + 40) # offset to start of pixel data
        Assert.equal(out.size(), 14)

        # -- dib header (Windows BITMAPINFOHEADER) --
        out.addI32(40) # size of this header in bytes
        out.addI32(width) # width in pixels
        out.addI32(height) # height in pixels
        out.addU16(1) # # color planes (must be 1?)
        out.addU16(32) # bits per pixel
        out.addI32(0) # compression (none)
        out.addI32(0) # uncompressed image size (if compressed)
        out.addI32(2835) # horizontal resolution (2835 used in wiki example)
        out.addI32(2835) # vertical resolution (2835 used in wiki example)
        out.addI32(0) # # colors in palette (palette is not used here)
        out.addI32(0) # # important colors (generally ignored)
        Assert.equal(out.size(), 14 + 40)

        # -- pixel data --
        for y = 0; y < height; y += 1 {
            for x = 0; x < width; x += 1 {
                out.addI32(self[x, y].toI32ARGB())
            }
        }
        Assert.equal(out.size(), bytesize)

        out
    }
}
