// Tests
//   * int arithmetic
//   * if, while and for statements

void assert(int cond);

void aeq(int lhs, int rhs) {
    assert(lhs == rhs);
}

void tests0() {
    aeq(-3, -3);
    aeq(5+7, 12);
    aeq(5-7, -2);
    aeq(5+(5-7), 3);
    aeq(5*(5-7), -10);
    aeq(5+6*7, 47);
    aeq(5*(9-6), 15);
    aeq((3+5)/2, 4);
    aeq(-10+20, 10);
    aeq(- -10, 10);
    aeq(- - +10, 10);
}

void tests1() {
    aeq((0==1), 0);
    aeq((42==42), 1);
    aeq((0!=1), 1);
    aeq((42!=42), 0);

    aeq((0<1), 1);
    aeq((1<1), 0);
    aeq((2<1), 0);
    aeq((0<=1), 1);
    aeq((1<=1), 1);
    aeq((2<=1), 0);

    aeq((1>0), 1);
    aeq((1>1), 0);
    aeq((1>2), 0);
    aeq((1>=0), 1);
    aeq((1>=1), 1);
    aeq((1>=2), 0);
}

int t2f0() {int a=3; return a;}
int t2f1() {int a=3; int z=5; return a+z;}
int t2f2() {int a; int b; a=b=3; return a+b; }
int t2f3() {1; 2; return 3;}
int t2f4() { {1; {2;} return 3;} }
int t2f5() { ;;; return 5; }

void tests2() {
    aeq(t2f0(), 3);
    aeq(t2f1(), 8);
    aeq(t2f2(), 6);
    aeq(t2f3(), 3);
    aeq(t2f4(), 3);
    aeq(t2f5(), 5);
}

int t3f0() { if (0) return 2; return 3; }
int t3f1() { if (1-1) return 2; return 3; }
int t3f2() { if (1) return 2; return 3; }
int t3f3() { if (2-1) return 2; return 3; }
int t3f4() { if (0) { 1; 2; return 3; } else { return 4; } }
int t3f5() { if (1) { 1; 2; return 3; } else { return 4; } }

void tests3_if_stmt() {
    aeq(t3f0(), 3);
    aeq(t3f1(), 3);
    aeq(t3f2(), 2);
    aeq(t3f3(), 2);
    aeq(t3f4(), 4);
    aeq(t3f5(), 3);
}

int t4f0() { int i=0, j=0; for (i=0; i<=10; i=i+1) j=i+j; return j; }
int t4f1() { for (;;) {return 3;} return 5; }
int t4f2() { int i=0; while(i<10) { i=i+1; } return i; }
int t4f3() { int j=0; for (int i=0; i<=10; i=i+1) j=i+j; return j; }

void tests4_loop() {
    aeq(t4f0(), 55);
    aeq(t4f1(), 3);
    aeq(t4f2(), 10);
    aeq(t4f3(), 55);
}

int main() {
    tests0();
    tests1();
    tests2();
    tests3_if_stmt();
    tests4_loop();
}
