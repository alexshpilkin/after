base save hex

( virtual memory )

0 value pages   0 value count   100 constant /page ( hardcoded )
: ?page ( u -- )   FF and ?abort" page alignment? " ;
: >host ( a -- A )   dup 256/   dup count u>= ?abort" address? "
  cells pages + @   dup 0= ?abort" address? "   swap FF and + ;
: memory ( u -- )   here tuck to pages   dup to count   cells
  dup allot   over + swap   begin 2dup <> while   0 over !
  cell+ repeat 2drop ;
: range ( a u -- )   swap dup ?page   256/ cells pages + swap
  dup ?page   here push   dup allot   256/ cells   over + swap
  begin 2dup <> while   peek over !   pop 100 + push   cell+
  repeat 2drop lose ;
: empty ( a u -- )   swap dup ?page   256/ cells pages + swap
  dup ?page   256/ cells   over + swap   begin 2dup <> while
  0 over !   cell+ repeat 2drop ;

: ub@  ( a -- u )   >host ub@ ;
: b!   ( u a -- )   >host b! ;

( image writer )

10 constant /line ( must divide page size )

variable ichk
: Ib ( u -- )   dup ichk +!   dup 16/ 0F and digit emit
  0F and digit emit ;
: Iw ( u -- )   dup 256/ Ib Ib ; ( big endian )
: <I ( -- )   0 ichk !   [char] : emit ;
: I> ( -- )   ichk @ negate Ib   cr ;
: I0 ( a u -- a+u )   <I dup Ib   over Iw   0 Ib   over + swap
  begin 2dup <> while   dup ub@ Ib   1+ repeat nip I> ;
: I1 ( -- )   <I 0 Ib   0 Iw   1 Ib I> ;

: ihex ( -- )   count 0   begin 2dup <> while
    dup cells pages + @   0<> if
      dup 256* dup 100 + swap
      begin 2dup <> while   /line I0   repeat 2drop
    then 1+
  repeat 2drop   I1 ;

variable schk
: Sb ( u -- )   dup schk +!   dup 16/ 0F and digit emit
  0F and digit emit ;
: Sw ( u -- )   dup   256/ Sb Sb ;
: Se ( u -- )   dup 65536/ Sb Sw ;
: Sd ( u -- )   dup 65536/ Sw Sw ;
: <S ( c u -- )   0 schk !   [char] S emit swap emit   Sb ;
: S> ( -- )   schk @ invert Sb   cr ;
: S0 ( A u -- )   [char] 0 over 3 + <S 0 Sw   over + swap
  begin 2dup <> while   dup c@ Sb   1+ repeat 2drop   S> ;
: S7 ( a -- )     [char] 7 over 5 + <S Sd S> ;
: S8 ( a -- )     [char] 8 over 4 + <S Se S> ;
: S9 ( a -- )     [char] 9 over 3 + <S Sw S> ;

: Sm ( a u -- a+u )   over + swap   begin 2dup <> while
  dup ub@ Sb 1+   repeat nip ;
: S1 ( a u -- a+u )   [char] 1 over 3 + <S over Sw Sm S> ;
: S2 ( a u -- a+u )   [char] 2 over 4 + <S over Se Sm S> ;
: S3 ( a u -- a+u )   [char] 3 over 5 + <S over Sd Sm S> ;

: srec ( -- )   brand S0   count 0   begin 2dup <> while
    dup cells pages + @   0<> if
      dup 256* dup 100 + swap
      begin 2dup <> while   /line S1   repeat 2drop
    then 1+
  repeat 2drop   0 ( entry ) S9 ;

( base ) restore
