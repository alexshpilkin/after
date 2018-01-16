: send   255 and   dup xmit   recv <> ?abort" echo? " ;
: go ( a -- )   dup 256/ send send   wait ;
: ub@   'read  go   dup 256/ send send   wait recv ;
: b!    'write go   swap send   dup 256/ send send   wait ;
