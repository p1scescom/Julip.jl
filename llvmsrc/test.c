#define NULL ((void*)0)

typedef struct List {
    int car;
    struct List *cdr;
} List;

int car(List l) {
    return l.car;
}

List cdr(List l) {
    return *(l.cdr);
}

int main() {
    List l1 = {2, NULL};
    List l2 = {1 , &l1};
    List a = cdr(l2);
    int b = car(a);
    return b;
}
