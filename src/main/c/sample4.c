int __puti(int i);

int main() {
    int x[2][3];
    // int *y=x; *(y+1)=1;
    *x;
    (*x+1);
    return *(*x+1);
    // int x[2][3];
    // int *y=x;
    // *y = 14;
    // *(y+1)=1;
    // __puti(x);
    // __puti(y);
    // __puti(*x);
    // __puti(*x + 1);
    // __puti(*(*x+1));
}
