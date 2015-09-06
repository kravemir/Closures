declare void @llvm.init.trampoline(i8*, i8*, i8*);
declare i8* @llvm.adjust.trampoline(i8*);
declare i32 @printf(i8* noalias nocapture, ...)
declare i8* @malloc(i32)
declare i8* @memalign(i32,i32)

; takes foo closure function and environment
; returns trampoline for closure
define i32(i32)* @make_foo_trampoline( i8* %fn, i8* %env )
{
    ; allocate memory for trampoline of size 72b, with 4b align
    %tramp_ptr = call i8* @memalign( i32 72, i32 4 )
    call void @llvm.init.trampoline(
        i8* %tramp_ptr,
        i8* %fn,
        i8* %env
    )
    %ptr = call i8* @llvm.adjust.trampoline(i8* %tramp_ptr)
    %fp = bitcast i8* %ptr to i32(i32)*
    ret i32(i32)* %fp
}

define i32 @foo1_closure([2 x i32]* nest %ptr, i32 %val)
{
    %aptr = getelementptr [2 x i32]* %ptr, i32 0, i32 0
    %bptr = getelementptr [2 x i32]* %ptr, i32 0, i32 1
    %a = load i32* %aptr
    %b = load i32* %bptr
    %valx = mul i32 %b, %val
    %sum = add i32 %valx, %a
    ret i32 %sum
}

define i32(i32)* @foo1(i32 %a, i32 %b)
{
    ; allocate environment
    %env.0 = call i8* @malloc( i32 8 )
    %env = bitcast i8* %env.0 to [2 x i32]*
    %aptr = getelementptr [2 x i32]* %env, i32 0, i32 0
    %bptr = getelementptr [2 x i32]* %env, i32 0, i32 1
    store i32 %a, i32* %aptr
    store i32 %b, i32* %bptr
    
    ; create trampoline
    %fp = call i32(i32)*(i8*,i8*)* @make_foo_trampoline(
        i8* bitcast (i32 ( [2 x i32]*, i32)* @foo1_closure to i8*),
        i8* %env.0
    )
    ret i32(i32)* %fp
}

define i32 @foo2_closure([2 x i32]* nest %ptr, i32 %val)
{
    %aptr = getelementptr [2 x i32]* %ptr, i32 0, i32 0
    %bptr = getelementptr [2 x i32]* %ptr, i32 0, i32 1
    %a = load i32* %aptr
    %b = load i32* %bptr
    %valx = add i32 %b, %val
    %sum = mul i32 %valx, %a
    ret i32 %sum
}
define i32(i32)* @foo2(i32 %a, i32 %b)
{
    ; allocate environment
    %env.0 = call i8* @malloc( i32 8 )
    %env = bitcast i8* %env.0 to [2 x i32]*
    %aptr = getelementptr [2 x i32]* %env, i32 0, i32 0
    %bptr = getelementptr [2 x i32]* %env, i32 0, i32 1
    store i32 %a, i32* %aptr
    store i32 %b, i32* %bptr
    
    ; create trampoline
    %fp = call i32(i32)*(i8*,i8*)* @make_foo_trampoline(
        i8* bitcast (i32 ( [2 x i32]*, i32)* @foo2_closure to i8*),
        i8* %env.0
    )
    ret i32(i32)* %fp
}

; constants for printf
@foo1_begin = internal constant [6 x i8] c"foo1\0A\00"
@foo2_begin = internal constant [6 x i8] c"foo2\0A\00"
@result_fmt = internal constant [14 x i8] c"val = %d: %d\0A\00"

define void @tester(i32(i32)* %fp)
{
entry:
    br label %loop

loop:
    %i = phi i32 [ 0, %entry ], [ %nextvar, %loop ]
    %result = call i32(i32)* %fp(i32 %i)
    call i32 (i8*, ...)* @printf( i8* getelementptr ([14 x i8]* @result_fmt, i32 0, i32 0), i32 %i, i32 %result)
    
    %nextvar = add i32 %i, 1
    %cmp = icmp eq i32 %nextvar, 10
    br i1 %cmp, label %afterloop, label %loop

afterloop:
    ret void
}

define i32 @main(i32, i8**)
{
    ; create closures
    %fp1 = call i32(i32)* (i32,i32)* @foo1( i32 13, i32 3)
    %fp2 = call i32(i32)* (i32,i32)* @foo2( i32 4, i32 1)
    
    ; test first closure
    call i32 (i8*, ...)* @printf( i8* getelementptr ([6 x i8]* @foo1_begin, i32 0, i32 0))
    call void(i32(i32)*)* @tester ( i32(i32)* %fp1)

    ; test second closure
    call i32 (i8*, ...)* @printf( i8* getelementptr ([6 x i8]* @foo2_begin, i32 0, i32 0))
    call void(i32(i32)*)* @tester ( i32(i32)* %fp2)

    ret i32 0
}
