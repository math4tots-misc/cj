package cj

import cj.MapOf
import cj.JSON

class Test13JSON {
    @test
    def sample() = {
        {
            val json = JSON.parse("[1, 2, 3]")
            Assert.that(json != "hello")
            Assert.that(json != [5])
            Assert.that(json == [1, 2, 3])
        }
        {
            val json = JSON.parse("{\"a\": 3, \"b\": [\"hello\"]}")
            Assert.that(json != MapOf("a": 3, "b": ["hezllo"]))
            Assert.that(json == MapOf("a": 3, "b": ["hello"]))
        }
    }

    @test
    def jsobj() {
        val json: JSON = jsobj!(foo: 12, bar: "hi").unsafeCast()
        Assert.equal(json, MapOf("bar": "hi", "foo": 12))
    }

    @test
    def eq() {
        {
            val json1 = json!(
                a: [1, 2, 3],
                b: json!(x: "x value", y: "y"))
            val json2 = json!(
                b: json!(y: "y", x: "x value"),
                a: [1, 2, 3])
            Assert.equal(json1, json2)

            val json3 = json!(
                b: json!(x: "x value", y: "y"),
                a: [1, 2, 3, 4])
            Assert(json1 != json3)
            Assert(json2 != json3)

            val json4 = json!(
                b: json!(x: "x value", y: "y"),
                a: [1, 2, 7])
            Assert(json1 != json4)
            Assert(json2 != json4)

            val json5 = json!(
                a: [1, 2, 3],
                b: json!(x: "x value", y: "y"),
                c: "c")
            Assert(json1 != json5)
            Assert(json2 != json5)
        }
    }
}
