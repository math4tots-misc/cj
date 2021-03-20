package www.sourcemap

import cjx.parser.Mark
import cj.JSON
import www.sourcemap.JSBuilder

class JSBuilderTest {
    @test
    def empty() {
        val jb = JSBuilder()
        jb.includeSourceMapAsDataURL = false
        val mapstr = jb.getSourceMap()
        val srcmap = JSON.parse(mapstr)
        Assert.equal(srcmap, MapOf(
            "version": 3,
            "sources": [],
            "names": [],
            "mappings": "",
        ))
        Assert.equal(jb.getSource(), "")
    }

    @test
    def sample1() {
        val jb = JSBuilder()
        jb.includeSourceMapAsDataURL = false
        jb.str("hello ")
        jb.addMark(Mark("<test>", 2, 1))
        jb.str("world\n")
        jb.addMark(Mark("<test>", 2, 1))
        jb.str("line\n\n")
        val mapstr = jb.getSourceMap()
        val srcmap = JSON.parse(mapstr)
        Assert.equal(srcmap, MapOf(
            "version": 3,
            "sources": ["<test>"],
            "names": [],
            "mappings": "MACA;AAAA;;", # NOTE: value here is unverified
        ))
        Assert.equal(jb.getSource(), "hello world\nline\n\n")
    }
}
