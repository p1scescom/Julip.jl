# Julip
 Julip is a original compiler language that I developed when I join security camp 2019.
It compiles source code into LLVM IR.
You need llvm libraries to use Juilp.(Especially llc command)

# How to use

```
julia Julip.jl
$ julia
               _
   _       _ _(_)_     |  Documentation: https://docs.julialang.org
  (_)     | (_) (_)    |
   _ _   _| |_  __ _   |  Type "?" for help, "]?" for Pkg help.
  | | | | | | |/ _` |  |
  | | |_| | | | (_| |  |  Version 1.1.1 (2019-05-16)
 _/ |\__'_|_|_|\__'_|  |  Official https://julialang.org/ release
|__/                   |

(v1.1) pkg> activate .

julia> using Julip

julia> Julip.main(["example/sample4.jlp"])
declare i8* @malloc(i64)
declare i32 @getchar()
declare i32 @putchar(i32)
define i32 @Int_getchar() {
  %1 = call i32 @getchar()
  ret i32 %1
}
define i32 @Int_putchar_Int(i32 %a) {
  %1 = call i32 @putchar(i32 %a)
  ret i32 %1
}
define i32 @Int_now() {
  %1 = add i32 1, 0
  ret i32 %1
}
define i32 @Int_fib_Int_Int_Int_Int(i32 %all, i32 %bef, i32 %count, i32 %maxindex) {
  %1 = icmp eq i32 %maxindex, %count
  br i1 %1, label %tlabel_1, label %flabel_1
tlabel_1:
  br label %elabel_1
flabel_1:
  %2 = add i32 %all, %bef
  %3 = add i32 1, 0
  %4 = add i32 %count, %3
  %5 = call i32 @Int_fib_Int_Int_Int_Int(i32 %2, i32 %all, i32 %4, i32 %maxindex)
  br label %elabel_1
elabel_1:
  %6 = phi i32 [%all , %tlabel_1] , [%5 , %flabel_1]
  ret i32 %6
}
define i32 @Int_main() {
  %1 = add i32 1, 0
  %2 = add i32 0, 0
  %3 = add i32 %1, %2
  %4 = add i32 0, 0
  %5 = add i32 1, 0
  %6 = add i32 10, 0
  %7 = add i32 2, 0
  %8 = sub i32 %6, %7
  %9 = call i32 @Int_now()
  %10 = call i32 @Int_fib_Int_Int_Int_Int(i32 %3, i32 %4, i32 %5, i32 %8)
  %11 = call i32 @Int_now()
  %12 = sub i32 %11, %9
  ret i32 %10
}
define i32 @main() {
  %1 = call i32 @Int_main()
  ret i32 %1
}
```

and save the ir in test.ll .

```
$ llc-8 test.ll && clang-8 test.s -o test && .test
```

you can get a result.

Yeah !

Some sample file are prepared.
You test it.

