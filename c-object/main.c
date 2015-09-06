#include <stdio.h>
#include <stdlib.h>

/* ************************** *
 * Closure for: int Foo (int) *
 * ************************** */

// storage type
typedef struct FooClosure {
    int (*call)(struct FooClosure *c);
} FooClosure;
// call function type
typedef int (*FooCallType)(FooClosure *);
// calling foo closure
int FooCall(FooClosure *c) {
    return c->call(c);
}
void FooFree(FooClosure *c) {
    free(c);
}


/* ******************** *
 * FooClosure for: Foo1 *
 * ******************** */

typedef struct Foo1Closure {
    FooClosure c;
    int a,b;
} Foo1Closure;

int Foo1Call( Foo1Closure *c, int val ) {
    return c->a + c->b * val;
}

FooClosure* Foo1(int a, int b) {
    Foo1Closure *c = (Foo1Closure*)malloc(sizeof(Foo1Closure));
    c->c.call = (FooCallType) Foo1Call;
    c->a = a;
    c->b = b;
    return &c->c;
}


/* ******************** *
 * FooClosure for: Foo2 *
 * ******************** */

typedef struct Foo2Closure {
    FooClosure c;
    int a,b;
} Foo2Closure;

int Foo2Call( Foo2Closure *c, int val ) {
    return c->a * (c->b + val);
}

FooClosure* Foo2(int a, int b) {
    Foo2Closure *c = (Foo2Closure*)malloc(sizeof(Foo2Closure));
    c->c.call = (FooCallType) Foo2Call;
    c->a = a;
    c->b = b;
    return &c->c;
}

void test(FooClosure *c) {
    for( int i = 0; i < 10; i++ )
        printf("val = %d: %d\n",i,FooCall(c));
}

int main() {
    FooClosure *fp1 = Foo1(13,3);
    FooClosure *fp2 = Foo2(4,1);

    printf("foo1:\n");
    test(fp1);
    printf("foo2:\n");
    test(fp2);

    FooFree(fp1);
    FooFree(fp2);

    return 0;
}
