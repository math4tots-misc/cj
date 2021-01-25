package cj

import cj.Test01.NestedClass
import cj.Time as Tim
import cj.AIO
import cj.Error

class Test04ControlFlow {

    @test
    def while1() = {
        val list = List[Int].empty()
        var i = 6
        while i< 10 {
            list.add(i)
            i = i + 1
        }
        Assert.equal(list, [6, 7, 8, 9])
    }

    @test
    def async_() = {
        Self.sampleAsync()
    }

    async def sampleAsync(): Promise[Unit] = {
        val start = Tim.now()
        AIO.wait(0.05).await
        val end = Tim.now()
        Assert.withMessage(end - start > 0.049, "Test04ControlFlow.async_/sampleAsync")
    }

    @test
    def nullable() = {
        val a = null(10)
        Assert.that(a.isPresent())
        Assert.that(not a.isEmpty())
        Assert.equal(a.get(), 10)
        Assert.equal(a.map(x -> x * x).get(), 100)
        val b = null[Int]
        Assert.that(not b.isPresent())
        Assert.that(b.isEmpty())
        val c: Nullable[String] = null
        Assert.that(not c.isPresent())
        Assert.that(c.isEmpty())
        Assert.that(null[String] != null(""))
        Assert.that(null[String] == null[String])
        Assert.that(null("") == null(""))
    }

    @test
    def nullableTypeArg() = {
        val a = NullableTypeArg[Nullable[String]].__malloc(null)
        Assert.equal(a.t, null)
        Assert.that(a.t == null)
        Assert.that(a.t != null("hi"))
    }

    # For type parameters: "T?" can also be used as an alias for "@nullable T"
    class NullableTypeArg[@nullable T] {
        val t: T
    }

    @test
    def ifNull() = {
        {
            val t = null(10)
            val x = if null(i) = t {
                "not null: " + i
            } else {
                "null"
            }
            Assert.equal(x, "not null: 10")
        }
        {
            val t = null[Int]
            val x = if null(i) = t {
                "not null: " + i
            } else {
                "null"
            }
            Assert.equal(x, "null")
        }
    }

    @test
    def nestedItem() = {
        Assert.equal(NestedClass.nestedClassVal, "some nested item val")
    }

    @test
    def for1() = {
        val out = List[Int].empty()
        for x in [1, 2, 3] {
            out.add(x * x)
        }
        Assert.equal(out, [1, 4, 9])
    }

    @test
    def forConditions() = {
        {
            val out = List[Int].empty()
            for x in [1, 2, 3, 4, 5, 6, 5, 4, 3, 2, 1] if x < 5 {
                out.add(x)
            }
            Assert.equal(out, [1, 2, 3, 4, 4, 3, 2, 1])
        }
        {
            val out = List[Int].empty()
            for x in [1, 2, 3, 4, 5, 6, 5, 4, 3, 2, 1] if x % 2 == 0 {
                out.add(x)
            }
            Assert.equal(out, [2, 4, 6, 4, 2])
        }
        {
            val out = List[Int].empty()
            for x in [1, 2, 3, 4, 5, 6, 5, 4, 3, 2, 1] while x < 5 {
                out.add(x)
            }
            Assert.equal(out, [1, 2, 3, 4])
        }
        {
            val out = List[Int].empty()
            for x in [1, 2, 3, 4, 5, 6, 5, 4, 3, 2, 1] if x % 2 == 0 while x < 5 {
                out.add(x)
            }
            Assert.equal(out, [2, 4])
        }
    }

    @test
    def classicForLoop() = {
        {
            val out = List[Int].empty()
            for i = 15; i < 20; i += 1 {
                out.add(i)
            }
            Assert.equal(out, [15, 16, 17, 18, 19])
        }
    }

    @test
    def return1() = {
        Assert.equal(Self.functionThatReturns(16), 26)
    }

    def functionThatReturns(i: Int) : Int = {
        return i + 10
    }

    @test
    def switch1() = {
        {
            val x = switch 5 {
                case 1
                case 2 = "one or two"
                case 3
                case 4
                case 5 = "3 to 5"
                else = "other"
            }
            Assert.equal(x, "3 to 5")
        }
        Assert.equal(switchf(0), "other")
        Assert.equal(switchf(1), "one or two")
        Assert.equal(switchf(2), "one or two")
        Assert.equal(switchf(3), "3 to 5")
        Assert.equal(switchf(4), "3 to 5")
        Assert.equal(switchf(5), "3 to 5")
        Assert.equal(switchf(6), "other")
    }

    def switchf(x: Int): String = switch x {
        case 1
        case 2 = "one or two"
        case 3
        case 4
        case 5 = "3 to 5"
        else = "other"
    }

    @test
    def switchStr() = {
        {
            val x = switch "xxx" {
                case "yy" = "got 2 ys"
                case "xx" = "got 2 xs"
                case "xxx" = "got 3 xs"
                case "xxxx" = "got 4 xs"
            }
            Assert.equal(x, "got 3 xs")
        }
    }

    @test
    def exceptions() = {
        {
            val x = try {
                throwString("hi")
                "nothrow"
            } catch y: String {
                y
            }
            Assert.equal(x, "s=hi")
        }
        {
            val x = try {
                try {
                    throwString("hello")
                    "nothrow"
                } catch z: Int { "int" }
            } catch y: String { y }
            Assert.equal(x, "s=hello")
        }
        {
            val x = try {
                try {
                    throwInt(721)
                    968
                } catch z: Int { z }
            } catch y: String { -1 }
            Assert.equal(x, 721)
        }
        {
            var m = "message"
            try {
                throw Error("some error")
            } catch e: Error {
                m = e.message()
            }
            Assert.equal(m, "some error")
        }
    }

    def throwString(s: String) = {
        throw "s=" + s
    }

    def throwInt(i: Int) = {
        throw i
    }
}
