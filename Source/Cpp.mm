#import "Cpp.h"

@implementation Objective_CPP

// Timothy Chan: divide and conquer lower 3D hell
// http://tmc.web.engr.illinois.edu/ch3d/ch3d.pdf

struct CPoint {
    double x, y, z;
    CPoint *prev, *next;
    
    void act() {
        if (prev->next != this) prev->next = next->prev = this;  // insert
        else { prev->next = next; next->prev = prev; }  // delete
    }
};

double INF = 1e99;
static CPoint cNil = {INF, INF, INF, 0, 0};
CPoint *cNIL = &cNil;

inline double turn(CPoint *p, CPoint *q, CPoint *r) {  // <0 iff cw
    if (p == cNIL || q == cNIL || r == cNIL) return 1.0;
    return (q->x - p->x) * (r->y - p->y) - (r->x - p->x) * (q->y - p->y);
}

inline double time(CPoint *p, CPoint *q, CPoint *r) {  // when turn changes
    if (p == cNIL || q == cNIL || r == cNIL) return INF;
    return ((q->x - p->x) * (r->z - p->z) - (r->x - p->x) * (q->z - p->z)) / turn(p,q,r);
}

CPoint *sort(CPoint P[], int n) {  // mergesort
    CPoint *a, *b, *c, head;
    if (n == 1) { P[0].next = cNIL; return P; }
    a = sort(P, n/2);
    b = sort(P+n/2, n-n/2);
    c = &head;
    do
        if (a->x < b->x) { c = c->next = a ; a = a->next; }
        else { c = c->next = b; b = b->next; }
    while (c != cNIL);
    return head.next;
}

void hull(CPoint *list, int n, CPoint **A, CPoint **B) {
    CPoint *u, *v, *mid;
    double t[6], oldt, newt;
    int i, j, k, l, minl = 0;
    
    if(n==1) { A[0] = list->prev = list->next = cNIL; return; }
    
    for(u = list,i = 0; i < n/2-1; u = u->next, i++) {}
    mid = v = u->next;
    hull(list, n/2, B, A);  // recurse on left and right sides
    hull(mid, n-n/2, B+n/2*2, A+n/2*2);
    
    for ( ; ; ) { // find initial bridge
        if (turn(u, v, v->next) < 0)
            v = v->next;
        else
            if (turn(u->prev, u, v) < 0)
                u = u->prev;
            else
                break;
    }
    
    // merge by tracking bridge uv over time
    for(i = k = 0, j = n/2*2, oldt = -INF;;oldt = newt) {
        t[0] = time(B[i]->prev, B[i], B[i]->next);
        t[1] = time(B[j]->prev, B[j], B[j]->next);
        t[2] = time(u, u->next, v);
        t[3] = time(u->prev, u, v);
        t[4] = time(u, v->prev, v);
        t[5] = time(u, v, v->next);
        
        for(newt = INF,l = 0;l < 6;l++)
            if (t[l] > oldt && t[l] <newt) { minl = l; newt = t[l]; }
        
        if (newt == INF) break;
        switch (minl) {
            case 0:  if (B[i]->x < u->x) A[k++] = B[i];  B[i++]->act();  break;
            case 1:  if (B[j]->x > v->x) A[k++] = B[j];  B[j++]->act();  break;
            case 2:  A[k++] = u = u->next;  break;
            case 3:  A[k++] = u;  u = u->prev;  break;
            case 4:  A[k++] = v = v->prev;  break;
            case 5:  A[k++] = v;  v = v->next;  break;
        }
    }
    
    A[k] = cNIL;    
    u->next = v;
    v->prev = u;    // now go back in time to update pointers
    
    for(k--;k >= 0; k--) {
        if (A[k]->x <= u->x || A[k]->x >= v->x) {
            A[k]->act();
            if (A[k] == u) u = u->prev;
            else if (A[k] == v) v = v->next;
        }
        else {
            u->next = A[k];
            A[k]->prev = u; v->prev = A[k];
            A[k]->next = v;
            if (A[k]->x < mid->x)
                u = A[k];
            else
                v = A[k];
        }
    }
}

// ===========================================================================

-(void)chan3DHull:(float *)data :(int)count :(int *)indices :(int *)iCount {
    int n = count/3;
    CPoint *P = new CPoint[n];
    CPoint **A = new CPoint *[2 * n];
    CPoint **B = new CPoint *[2 * n];
    
    int index = 0;
    for(int i=0;i<count;i+=3) {
        P[index] = cNil;
        P[index].x = data[i];
        P[index].y = data[i+1];
        P[index].z = data[i+2];
        ++index;
    }
    
    CPoint *list = sort(P,n);
    hull(list,n,A,B);
    
    index = 0;
    for (int i = 0; A[i] != cNIL; A[i++]->act())  {
        indices[index++] = int(A[i]->prev - P);
        indices[index++] = int(A[i] - P);
        indices[index++] = int(A[i]->next - P);
    }
    *iCount = index;
    
    delete[] A;
    delete[] B;
    delete[] P;
}

@end
