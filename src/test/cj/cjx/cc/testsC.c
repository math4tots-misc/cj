// Tests
//   * structs

void __putsi(char *s, int x);
void assert(int cond);
void aeq(int lhs, int rhs) {
    if (lhs != rhs) {
        __putsi("lhs = ", lhs);
        __putsi("rhs = ", rhs);
    }
    assert(lhs == rhs);
}

void test01_struct() {
    int ptrSize = 4;

    aeq(({ struct {int a; int b;} x; x.a=1; x.b=2; x.a; }), 1);
    aeq(({ struct {int a; int b;} x; x.a=1; x.b=2; x.b; }), 2);
    aeq(({ struct {char a; int b; char c;} x; x.a=1; x.b=2; x.c=3; x.a; }), 1);
    aeq(({ struct {char a; int b; char c;} x; x.b=1; x.b=2; x.c=3; x.b; }), 2);
    aeq(({ struct {char a; int b; char c;} x; x.a=1; x.b=2; x.c=3; x.c; }), 3);

    aeq(({ struct {char a; char b;} x[3]; char *p=x; p[0]=0; x[0].a; }), 0);
    aeq(({ struct {char a; char b;} x[3]; char *p=x; p[1]=1; x[0].b; }), 1);
    aeq(({ struct {char a; char b;} x[3]; char *p=x; p[2]=2; x[1].a; }), 2);
    aeq(({ struct {char a; char b;} x[3]; char *p=x; p[3]=3; x[1].b; }), 3);

    aeq(({ struct {char a[3]; char b[5];} x; char *p=&x; x.a[0]=6; p[0]; }), 6);
    aeq(({ struct {char a[3]; char b[5];} x; char *p=&x; x.b[0]=7; p[3]; }), 7);

    aeq(({ struct { struct { char b; } a; } x; x.a.b=6; x.a.b; }), 6);

    aeq(({ struct {int a;} x; sizeof(x); }), ptrSize);
    aeq(({ struct {int a; int b;} x; sizeof(x); }), 2 * ptrSize);
    aeq(({ struct {int a, b;} x; sizeof(x); }), 2 * ptrSize);
    aeq(({ struct {int a[3];} x; sizeof(x); }), 3 * ptrSize);
    aeq(({ struct {int a;} x[4]; sizeof(x); }), 4 * ptrSize);
    aeq(({ struct {int a[3];} x[2]; sizeof(x); }), 2 * 3 * ptrSize);
    aeq(({ struct {char a; char b;} x; sizeof(x); }), 2);
    aeq(({ struct {char a; int b;} x; sizeof(x); }), 8); // char is padded for alignment
    aeq(({ struct {int a; char b;} x; sizeof(x); }), 8); // char is padded for alignment
    aeq(({ struct {} x; sizeof(x); }), 0);
}

void test02_tagged_struct() {
    aeq(({ struct t {int a; int b;} x; struct t y; sizeof(y); }), 8);
    aeq(({ struct t {int a; int b;}; struct t y; sizeof(y); }), 8);
    aeq(({ struct t {char a[2];}; { struct t {char a[4];}; } struct t y; sizeof(y); }), 2);
    aeq(({ struct t {int x;}; int t=1; struct t y; y.x=2; t+y.x; }), 3);
}

int main() {
    test01_struct();
    test02_tagged_struct();
}
