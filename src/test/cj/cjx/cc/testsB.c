// Tests
//   * address-of and deref operators
//   * pointer arithmetic
//   * arrays, and subscripting
//   * string and char literals
//   * statement expressions

void assert(int cond);
int __puti(int i);
void aeq(int lhs, int rhs) {
    assert(lhs == rhs);
}

int t1f0() { int x=3; return *&x; }
int t1f1() { int x=3; int *y=&x; int **z=&y; return **z; }
int t1f2() { int x=3; int y=5; return *(&x+1); }
int t1f3() { int x=3; int y=5; return *(&y-1); }
int t1f4() { int x=3; int y=5; return *(&x-(-1)); }
int t1f5() { int x=3; int *y=&x; *y=5; return x; }
int t1f6() { int x=3; int y=5; *(&x+1)=7; return y; }
int t1f7() { int x=3; int y=5; *(&y-1)=7; return x; }
int t1f8() { int x=3; return (&x+2)-&x+3; }

void tests1_addr() {
    aeq(t1f0(), 3);
    aeq(t1f1(), 3);
    aeq(t1f2(), 5);
    aeq(t1f3(), 3);
    aeq(t1f4(), 5);
    aeq(t1f5(), 5);
    aeq(t1f6(), 7);
    aeq(t1f7(), 7);
    aeq(t1f8(), 5);
}

void tests2_array() {
    aeq(({int x[2]; int *y=x; *y=3; *x;}), 3);
    aeq(({int x[2]; int *y=&x; *y=3; *x;}), 3);
    aeq(({int x[3]; *x=3; *(x+1)=4; *(x+2)=5; *x;}), 3);
    aeq(({int x[3]; *x=3; *(x+1)=4; *(x+2)=5; *(x+1);}), 4);
    aeq(({int x[3]; *x=3; *(x+1)=4; *(x+2)=5; *(x+2);}), 5);

    aeq(({int x[2][3]; int *y=x; *y=0; **x;}), 0);
    aeq(({int x[2][3]; int *y=x; *(y+1)=1; *(*x+1);}), 1);
    aeq(({int x[2][3]; int *y=x; *(y+2)=2; *(*x+2);}), 2);
    aeq(({int x[2][3]; int *y=x; *(y+3)=3; **(x+1);}), 3);
    aeq(({int x[2][3]; int *y=x; *(y+4)=4; *(*(x+1)+1);}), 4);
    aeq(({int x[2][3]; int *y=x; *(y+5)=5; *(*(x+1)+2);}), 5);
}

void tests3_subscr() {
    aeq(({int x[3]; *x=3; x[1]=4; x[2]=5; *x;}), 3);
    aeq(({int x[3]; *x=3; x[1]=4; x[2]=5; *(x+1);}), 4);
    aeq(({int x[3]; *x=3; x[1]=4; x[2]=5; *(x+2);}), 5);
    aeq(({int x[3]; *x=3; x[1]=4; x[2]=5; *(x+2);}), 5);
    aeq(({int x[3]; *x=3; x[1]=4; 2[x]=5; *(x+2);}), 5);

    aeq(({int x[2][3]; int *y=x; y[0]=0; x[0][0];}), 0);
    aeq(({int x[2][3]; int *y=x; y[1]=1; x[0][1];}), 1);
    aeq(({int x[2][3]; int *y=x; y[2]=2; x[0][2];}), 2);
    aeq(({int x[2][3]; int *y=x; y[3]=3; x[1][0];}), 3);
    aeq(({int x[2][3]; int *y=x; y[4]=4; x[1][1];}), 4);
    aeq(({int x[2][3]; int *y=x; y[5]=5; x[1][2];}), 5);
}

void tests4_sizeof() {
    aeq(({int x; sizeof(x);}), 4);
    aeq(({int x; sizeof x;}), 4);
    aeq(({int *x; sizeof(x);}), 4);
    aeq(({int x[4]; sizeof(x);}), 4 * 4);
    aeq(({int x[3][4]; sizeof(x);}), 48);
    aeq(({int x[3][4]; sizeof(*x);}), 16);
    aeq(({int x[3][4]; sizeof(**x);}), 4);
    aeq(({int x[3][4]; sizeof(**x) + 1;}), 5);
    aeq(({int x[3][4]; sizeof **x + 1;}), 5);
    aeq(({int x[3][4]; sizeof(**x + 1);}), 4);
    aeq(({int x=1; sizeof(x=2);}), 4);
    aeq(({int x=1; sizeof(x=2); x;}), 1);
}

int sub_char(char a, char b, char c) { return a-b-c; }

void tests5_char() {
    aeq(({ char x=1; x; }), 1);
    aeq(({ char x=1; char y=2; x; }), 1);
    aeq(({ char x=1; char y=2; y; }), 2);

    aeq(({ char x; sizeof(x); }), 1);
    aeq(({ char x[10]; sizeof(x); }), 10);
    aeq(sub_char(7, 3, 3), 1);
}

void tests6_strlit() {
    __puti(""[0]);
    aeq(""[0], 0);
    aeq(sizeof(""), 1);

    aeq("abc"[0], 97);
    aeq("abc"[1], 98);
    aeq("abc"[2], 99);
    aeq("abc"[3], 0);
    aeq(sizeof("abc"), 4);
    aeq(sizeof("abcdef"), 7);

    aeq("\a"[0], 7);
    aeq("\b"[0], 8);
    aeq("\t"[0], 9);
    aeq("\n"[0], 10);
    aeq("\v"[0], 11);
    aeq("\f"[0], 12);
    aeq("\r"[0], 13);
    aeq("\e"[0], 27);

    aeq("\j"[0], 106);
    aeq("\k"[0], 107);
    aeq("\l"[0], 108);

    aeq("\ax\ny"[0], 7);
    aeq("\ax\ny"[1], 120);
    aeq("\ax\ny"[2], 10);
    aeq("\ax\ny"[3], 121);

    aeq("\0"[0], 0);
    aeq("\20"[0], 16);
    aeq("\101"[0], 65);
    aeq("\1500"[0], 104);

    aeq("\x00"[0], 0);
    aeq("\x77"[0], 119);
    aeq("\xA5"[0], 165);
    aeq("\x00ff"[0], 255);
}

int t7f0() { return ({ 0; }); }
int t7f1() { return ({ 0; 1; 2; }); }
int t7f2() { ({ 0; return 1; 2; }); return 3; }
int t7f3() { return ({ 1; }) + ({ 2; }) + ({ 3; }); }
int t7f4() { return ({ int x=3; x; }); }

void tests7_stmtexpr() {
    aeq(t7f0(), 0);
    aeq(t7f1(), 2);
    aeq(t7f2(), 1);
    aeq(t7f3(), 6);
    aeq(t7f4(), 3);
}

int main() {
    tests1_addr();
    tests2_array();
    tests3_subscr();
    tests4_sizeof();
    tests5_char();
    tests6_strlit();
    tests7_stmtexpr();
}
