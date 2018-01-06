: ub@ ( a -- u )   0 send   dup 256/ send send   wait recv ; 
: b!  ( u a -- )   1 send   dup 256/ send send   send wait ;
: go  ( a -- )     2 send   dup 256/ send send   wait ;
