; ModuleID = 'test.c'
source_filename = "test.c"
target datalayout = "e-m:e-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

%struct.List = type { i32, %struct.List* }

@__const.main.l1 = private unnamed_addr constant %struct.List { i32 2, %struct.List* null }, align 8

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @car(i32, %struct.List*) #0 {
  %3 = alloca %struct.List, align 8
  %4 = bitcast %struct.List* %3 to { i32, %struct.List* }*
  %5 = getelementptr inbounds { i32, %struct.List* }, { i32, %struct.List* }* %4, i32 0, i32 0
  store i32 %0, i32* %5, align 8
  %6 = getelementptr inbounds { i32, %struct.List* }, { i32, %struct.List* }* %4, i32 0, i32 1
  store %struct.List* %1, %struct.List** %6, align 8
  %7 = getelementptr inbounds %struct.List, %struct.List* %3, i32 0, i32 0
  %8 = load i32, i32* %7, align 8
  ret i32 %8
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local { i32, %struct.List* } @cdr(i32, %struct.List*) #0 {
  %3 = alloca %struct.List, align 8
  %4 = alloca %struct.List, align 8
  %5 = bitcast %struct.List* %4 to { i32, %struct.List* }*
  %6 = getelementptr inbounds { i32, %struct.List* }, { i32, %struct.List* }* %5, i32 0, i32 0
  store i32 %0, i32* %6, align 8
  %7 = getelementptr inbounds { i32, %struct.List* }, { i32, %struct.List* }* %5, i32 0, i32 1
  store %struct.List* %1, %struct.List** %7, align 8
  %8 = getelementptr inbounds %struct.List, %struct.List* %4, i32 0, i32 1
  %9 = load %struct.List*, %struct.List** %8, align 8
  %10 = bitcast %struct.List* %3 to i8*
  %11 = bitcast %struct.List* %9 to i8*
  call void @llvm.memcpy.p0i8.p0i8.i64(i8* align 8 %10, i8* align 8 %11, i64 16, i1 false)
  %12 = bitcast %struct.List* %3 to { i32, %struct.List* }*
  %13 = load { i32, %struct.List* }, { i32, %struct.List* }* %12, align 8
  ret { i32, %struct.List* } %13
}

; Function Attrs: argmemonly nounwind
declare void @llvm.memcpy.p0i8.p0i8.i64(i8* nocapture writeonly, i8* nocapture readonly, i64, i1) #1

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @main() #0 {
  %1 = alloca i32, align 4
  %2 = alloca %struct.List, align 8
  %3 = alloca %struct.List, align 8
  %4 = alloca %struct.List, align 8
  %5 = alloca i32, align 4
  store i32 0, i32* %1, align 4
  %6 = bitcast %struct.List* %2 to i8*
  call void @llvm.memcpy.p0i8.p0i8.i64(i8* align 8 %6, i8* align 8 bitcast (%struct.List* @__const.main.l1 to i8*), i64 16, i1 false)
  %7 = getelementptr inbounds %struct.List, %struct.List* %3, i32 0, i32 0
  store i32 1, i32* %7, align 8
  %8 = getelementptr inbounds %struct.List, %struct.List* %3, i32 0, i32 1
  store %struct.List* %2, %struct.List** %8, align 8
  %9 = bitcast %struct.List* %3 to { i32, %struct.List* }*
  %10 = getelementptr inbounds { i32, %struct.List* }, { i32, %struct.List* }* %9, i32 0, i32 0
  %11 = load i32, i32* %10, align 8
  %12 = getelementptr inbounds { i32, %struct.List* }, { i32, %struct.List* }* %9, i32 0, i32 1
  %13 = load %struct.List*, %struct.List** %12, align 8
  %14 = call { i32, %struct.List* } @cdr(i32 %11, %struct.List* %13)
  %15 = bitcast %struct.List* %4 to { i32, %struct.List* }*
  %16 = getelementptr inbounds { i32, %struct.List* }, { i32, %struct.List* }* %15, i32 0, i32 0
  %17 = extractvalue { i32, %struct.List* } %14, 0
  store i32 %17, i32* %16, align 8
  %18 = getelementptr inbounds { i32, %struct.List* }, { i32, %struct.List* }* %15, i32 0, i32 1
  %19 = extractvalue { i32, %struct.List* } %14, 1
  store %struct.List* %19, %struct.List** %18, align 8
  %20 = bitcast %struct.List* %4 to { i32, %struct.List* }*
  %21 = getelementptr inbounds { i32, %struct.List* }, { i32, %struct.List* }* %20, i32 0, i32 0
  %22 = load i32, i32* %21, align 8
  %23 = getelementptr inbounds { i32, %struct.List* }, { i32, %struct.List* }* %20, i32 0, i32 1
  %24 = load %struct.List*, %struct.List** %23, align 8
  %25 = call i32 @car(i32 %22, %struct.List* %24)
  store i32 %25, i32* %5, align 4
  %26 = load i32, i32* %5, align 4
  ret i32 %26
}

attributes #0 = { noinline nounwind optnone uwtable "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-frame-pointer-elim"="true" "no-frame-pointer-elim-non-leaf" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="false" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #1 = { argmemonly nounwind }

!llvm.module.flags = !{!0}
!llvm.ident = !{!1}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{!"clang version 8.0.0-3~ubuntu18.04.1 (tags/RELEASE_800/final)"}
