package sample

import sample.SampleClass
import sample.SampleUnion
import cj.IO

class Main {
    def main() = {
        IO.println("Hello world!")

        IO.println(Int.__add(4, 17))
        IO.println((4).__add(71))
        IO.println(4 + 71)

        {
            val x = 12
            IO.println(x)
        }

        {
            var x = SampleUnion.one(24)
            union x {
                case one(a) = IO.println("a: " + a)
                case two(a, b) = ()
                case three(s) = ()
            }
        }

        IO.println("foo: " + Self.foo(SampleUnion.two(76, 2)))

        {
            IO.println("sampleStaticField = " + SampleUnion.sampleStaticField)
            SampleUnion.sampleStaticField = 91
            IO.println("sampleStaticField = " + SampleUnion.sampleStaticField)
        }

        {
            val x = SampleClass.__malloc("hi", 5.5)
            IO.println("valField = " + x.valField)
            IO.println("varField = " + x.varField)
            x.varField = 77.2
            IO.println("varField = " + x.varField)
        }

        {
            val f: Fn2[Int, Int, Int] = (a, b) -> a + b
            IO.println("f.call(22, 88) = " + f.call(22, 88))
        }

        {
            val list = List[Int].empty()
            list.add(3)
            list.add(5)
            IO.println("list = " + list)
            val list2 = list.map(x -> x * x)
            IO.println("list2 = " + list2)
        }
    }

    def foo(u: SampleUnion): Int = union u {
        case one(a) = a
        case two(a, b) = a * b
        case three(s) = s.size()
    }
}
