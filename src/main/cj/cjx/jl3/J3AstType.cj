package cjx.jl3

union J3AstType {
    case noreturn
    case void
    case int
    case double
    case klass(String, List[J3AstType])
}
