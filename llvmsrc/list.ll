; ModuleID = 'Julip.Core'
;source_filename = "list.ll"

;%Symbol = type { i8*, i8 }
%List = type { i32 , %List* }

declare i8* @malloc(i64)

define i32 @cari32(%List*) {
  %2 = getelementptr %List, %List* %0, i32 0, i32 0
  %3 = load i32, i32* %2, align 4
  ret i32 %3
}

define i32 @__addi32(i32, i32) {
  %3 = add i32 %0, %1
  ret i32 %3
}

define i32 @__subi32(i32, i32) {
  %3 = sub i32 %0, %1
  ret i32 %3
}

define i1 @__and(i1, i1) {
  %3 = and i1 %0, %1
  ret i1 %3
}

define i32 @car(%List*) {
  %2 = icmp eq %List* %0, null
  br i1 %2, label %ifnil, label %ifunnil
ifnil:
  ret i32 0
ifunnil:
  %3 = call i32 @cari32(%List* %0)
  ret i32 %3
}

define %List* @cdr(%List*) {
  %2 = getelementptr %List, %List* %0, i32 0, i32 1
  %3 = load %List*, %List** %2, align 8
  %4 = icmp eq %List* %3, null
  br i1 %4, label %ifnil, label %ifunnil
ifnil:
  ret %List* null
ifunnil:
  ret %List* %3
}

define %List* @cons(i32 , %List*) {
  %3 = call i8* @malloc(i64 96)
  %4 = bitcast i8* %3 to %List*
  %5 = getelementptr %List, %List* %4, i32 0, i32 0
  %6 = getelementptr %List, %List* %4, i32 0, i32 1
  store i32 %0, i32* %5
  store %List* %1, %List** %6
  ret %List* %4
}

define i1 @nil_question(%List*) {
  %2 = icmp eq %List* %0, null
  ret i1 %2
}

; https://takoeight0821.github.io/posts/2017/09/write-llvm-prog-2.html
;define i32 @addi32(%List*, i32) {
;  %1 = call i32 @car(%0)
;  %2 = call @car(%0)
;  %2 = getelementptr %List, %List* %0, i32 0, i32 
;}

define i32 @main() {
  %1 = call %List* @cons(i32 42, %List* null)
  %2 = call %List* @cons(i32 2, %List* %1)
  %3 = call %List* @cdr(%List* %2)
  %4 = call i32 @car(%List* %3)
  %5 = call i32 @car(%List* %2)
  ret i32 %5
}
