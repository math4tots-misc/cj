// Tests
//   * comma operator

void assert(int cond);
void aeq(int lhs, int rhs) {
    assert(lhs == rhs);
}

void tests8_comma() {
    aeq((1,2,3), 3);

    // comma operators as lvalues is not a standard C feature,
    // but is a standard C++ feature
    // https://gcc.gnu.org/onlinedocs/gcc-3.2/gcc/Lvalues.html
    aeq(({ int i=2, j=3; (i=5,j)=6; i; }), 5);
    aeq(({ int i=2, j=3; (i=5,j)=6; j; }), 6);
}

int main() {
    tests8_comma();
}
