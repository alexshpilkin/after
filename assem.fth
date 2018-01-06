base save hex

( b!   required )
: w!   over 256/ over b! 1+ b! ;
( b,   required )
: w,   dup 256/ b, b, ;
: j,   here 1+ -   dup b,
  -80 7F between 0= ?abort" jump offset? " ;

: ?b   ?abort" bit number? " ;
: ?m   ?abort" addressing mode? " ;
: ?p   ?abort" register pair? " ;
: ?a   ?abort" address? " ;
: ?r   ?abort" offset? " ;

: +mode   dup cell + swap constant ;

0 ( layout of a table for ENCODE or OPERAND, )
  +mode A  +mode #   +mode b)    +mode w)    +mode b))    +mode w))    +mode b,S)  +mode &
  +mode X  +mode X)  +mode b,X)  +mode w,X)  +mode b),X)  +mode w),X)
  +mode Y  +mode Y)  +mode b,Y)  +mode w,Y)  +mode b),Y)
  +mode C
  +mode b/w) ( must not appear in tables )
drop

: b/w>b ( o -- o )   dup b/w) = if drop b) then ;
: b/w>w ( o -- o )   dup b/w) = if drop w) then ;

: amode ( 'bname 'wname "name" -- ) ( n -- o )   push push
  : postpone dup FF postpone literal postpone u<= postpone if
  pop compile,   postpone exit postpone then   postpone dup
  FFFF postpone literal postpone u> postpone ?r   pop compile,
  postpone ; ;
: rmode ( 'bname 'wname "name" -- ) ( u -- o )   push push
  : postpone dup -80 postpone literal 7F postpone literal
  postpone between postpone if   pop compile,   postpone exit
  postpone then   postpone dup -8000 postpone literal
  7FFF postpone literal postpone between postpone 0=
  postpone ?a   pop compile,   postpone ; ;

' b/w) ' w)   amode )     ' b))   ' w))   amode ))
' b,X) ' w,X) rmode ,X)   ' b),X) ' w),X) amode ),X)
' b,Y) ' w,Y) rmode ,Y)

: ,S)    dup -80 7F between 0= ?abort" byte offset? "   b,S) ;
: ),Y)   dup FF u> ?abort" byte address? "   b),Y) ;

: x/y ( 'namex 'namey "namew" -- )   push push
  : postpone dup postpone X postpone = postpone if
  postpone drop pop compile, postpone else
  postpone Y postpone <> postpone ?m pop compile,
  postpone then postpone ; ;

'    X) '    Y) x/y    I)   '  b,X) '  b,Y) x/y b,I)
'  w,X) '  w,Y) x/y  w,I)   '   ,X) '   ,Y) x/y  ,I)
' b),X) ' b),Y) x/y b),I)   '  ),X) '  ),Y) x/y ),I)

: return   ( -- dest )     here ;
( backward ( dest -- o )   & constant backward
: forward  ( -- orig o )   here here & ;
: resolve  ( orig -- )     ( this has to inspect the opcode )
  dup ub@ 72 = if 5 + else 2 + then   here over -   swap 1- b! ;

label (operand)   ( semantics of operand )
  ' relax , ' die   , ' b, , ' w, , ' b, , ' w, , ' b, , ' j, ,
  ' relax , ' relax , ' b, , ' w, , ' b, , ' w, ,
  ' relax , ' relax , ' b, , ' w, , ' b, ,
  ' relax ,

: operand, ( o 'imm, )   over # = if   nip   else   drop
  (operand) + @   then execute ;

: encode ( o a -- u )   + @   dup FFFF = ?m   dup 256/
  dup if b, else drop then ;

label (binary)   ( precode; high nibble )
  FFFF , 00A0 , 00B0 , 00C0 , 92C0 , 72C0 , 0010 , FFFF ,
  FFFF , 00F0 , 00E0 , 00D0 , 92D0 , 72D0 ,
  FFFF , 90F0 , 90E0 , 90D0 , 91D0 ,
  FFFF ,

: binary ( n "name" -- ) ( o -- )   create , ;does: @ push
  b/w>b   dup (binary) encode   pop or b,   ['] b, operand, ;

  00 binary sub,  01 binary cpa,  02 binary sbc, ( 3        CPW)
  04 binary and,  05 binary bcp, ( 6        LDA) ( 7        STA)
  08 binary xor,  09 binary adc,  0A binary orr,  0B binary add,
 ( C        JMP) ( D        CAL) ( E        LDW) ( F        STW)

label (cal/jmp)   ( precode; high nibble of opcode )
  FFFF , FFFF , FFFF , 00C0 , 92C0 , 72C0 , FFFF , 00A0 ,
  FFFF , 00F0 , 00E0 , 00D0 , 92D0 , 72D0 ,
  FFFF , 90F0 , 90E0 , 90D0 , 91D0 ,
  FFFF ,

( -- cc )   ( jump opcode )
20 constant al  21 constant nv  22 constant hi  23 constant ls
24 constant hs  25 constant lo  26 constant ne  27 constant eq
24 constant cc  25 constant cs  ( FIXME unlike ARM? )
28 constant vc  29 constant vs  2A constant pl  2B constant mi
2C constant gt  2D constant le  2E constant ge  2F constant lt

: inv ( cc -- cc )   1 xor ;

: cal, ( o -- )   b/w>w dup   (cal/jmp) encode 0D or b,
  ['] die operand, ;
: jmp, ( o -- )   b/w>w dup   dup & = if drop 20 ( JAL ) else
  (cal/jmp) encode 0C or then b,   ['] die operand, ;
: ?jr, ( o cc -- )   over & <> ?m   b,   ['] die operand, ;

: begin,  ( -- dest )        return ;
: again,  ( dest -- )        backward jmp, ;
: until,  ( dest cc -- )     inv push   backward pop ?jr, ;
: if,     ( cc -- orig )     inv push   forward pop ?jr, ;
: else,   ( orig -- orig )   forward jmp,   swap resolve ;
: then,   ( orig -- )        resolve ;
: while,  ( cc dest -- orig dest )   if, swap ;
: repeat, ( orig dest -- )   again, then, ;

: lda, ( o -- )   b/w>b dup   dup b,S) = if drop 7B else
  (binary) encode 06 or   then   b,   ['] b,  operand, ;
: sta, ( o -- )   b/w>b dup   dup # = ?m   dup b,S) = if
  drop 6B   else   (binary) encode 07 or   then   b,
  ['] die operand, ;

label (ldx/stxy)   ( precode; high nibble of opcode )
  FFFF , 00A0 , 00B0 , 00C0 , 92C0 , 72C0 , 0010 , FFFF ,
  FFFF , 00F0 , 00E0 , 00D0 , 92D0 , 72D0 ,
  FFFF , FFFF , FFFF , FFFF , FFFF ,
  FFFF ,

label (ldy/styx)   ( precode; part[NB!] of opcode )
  FFFF , 90A0 , 90B0 , 90C0 , 91C0 , FFFF , 0018 , FFFF ,
  FFFF , FFFF , FFFF , FFFF , FFFF , FFFF ,
  FFFF , 90F0 , 90E0 , 90D0 , 91D0 ,
  FFFF ,

: ldx, ( o -- )   b/w>b dup (ldx/stxy) encode 0E  or b,
  ['] w, operand, ;
: ldy, ( o -- )   b/w>b dup (ldy/styx) encode 0E xor b,
  ['] w, operand, ;
' ldx, ' ldy, x/y ldi,

: stx, ( o -- )   b/w>b dup   dup # = ?m   dup X < if (ldx/stxy)
  else (ldy/styx) then   encode 0F  or b,   ['] die operand, ;
: sty, ( o -- )   b/w>b dup   dup # = ?m   dup X < if (ldy/styx)
  else (ldx/stxy) then   encode 0F xor b,   ['] die operand, ;
' stx, ' sty, x/y sti,

: cpx, ( o -- )   b/w>b dup   dup X < if (ldx/stxy) else
  (ldy/styx) then   encode 03 or b,   ['] w, operand, ;
: cpy, ( o -- )   b/w>b dup   dup b,S) = ?m   dup X < if
  (ldx/stxy) else (ldy/styx) then   encode 03 or b,
  ['] w, operand, ;
' cpx, ' cpy, x/y cpi,

( precode of TFR; high nibble of EXG; low nibble of TFR )
0047 constant XL,A   9067 constant YL,A   ' XL,A ' YL,A x/y IL,A
004F constant A,XL   906F constant A,YL   ' A,XL ' A,YL x/y A,IL
0095 constant XH,A   9095 constant YH,A   ' XH,A ' YH,A x/y IH,A
009E constant A,XH   909E constant A,YH   ' A,XH ' A,YH x/y A,IH
0053 constant X,Y    9053 constant Y,X 
00F4 constant S,X    90F4 constant S,Y    ' S,X  ' S,Y  x/y S,I
00F6 constant X,S    90F6 constant Y,S    ' X,S  ' Y,S  x/y I,S

: tfr, ( p -- )   dup 256/   dup if b, else drop then
  0F and 90 or b, ;
: exg, ( p -- )   00F0 and   dup F0 = ?p   01 or b, ;
( FIXME exg a, mem )

label (unary)   ( precode; high nibble of opcode )
  0040 , FFFF , 0030 , 7250 , 9230 , 7230 , 0000 , FFFF ,
  0050 , 0070 , 0060 , 7240 , 9260 , 7260 ,
  9050 , 9070 , 9060 , 9040 , 9160 ,
  FFFF ,

: unary ( n "name" -- ) ( o -- )   create , ;does: @ push
  b/w>b dup   (unary) encode   pop or b,   ['] die operand, ;

  00 unary neg,  ( 1 misc/undef) ( 2 misc/undef)  03 unary not,
  04 unary srl,  ( 5 misc/undef)  06 unary rrc,   07 unary sra,
  08 unary sll,   09 unary rlc,   0A unary dec,  ( B misc/undef)
  08 unary sla,
  0C unary inc,   0D unary tnz,   0E unary swp,   0F unary clr,

: rotate ( n "name" -- ) ( o -- )   create , ;does: @ swap
  dup Y = if   drop 90 b,   else   X <> ?m   then b, ;

  01 rotate rra,  02 rotate rla,

label (psh/pop)   ( precode; part[NB!] of opcode )
  0080 , 0043 , FFFF , 0033 , FFFF , FFFF , FFFF , FFFF ,
  0081 , FFFF , FFFF , FFFF , FFFF , FFFF ,
  9081 , FFFF , FFFF , FFFF , FFFF ,
  0082 ,

: psh, ( o -- )   b/w>w dup   (psh/pop) encode 08 or b,
  ['] b, operand, ;
: pop, ( o -- )   b/w>w dup   dup # = ?m   dup w) = if drop 32
  else   (psh/pop) encode 04 or   then b,   ['] b, operand, ;

label (adi/sbi)   ( precode; high nibble of opcode )
  FFFF , 72A0 , FFFF , 72B0 , FFFF , FFFF , 72F0 , FFFF ,
  FFFF , FFFF , FFFF , FFFF , FFFF , FFFF ,
  FFFF , FFFF , FFFF , FFFF , FFFF ,
  FFFF ,

: adx, ( o -- )   b/w>w dup   dup # = if drop 1C else
  (adi/sbi) encode 0B or   then b,   ['] w, operand, ;
: ady, ( o -- )   b/w>w dup   (adi/sbi) encode 09 or b,
  ['] w, operand, ;
: ads, ( o -- )   dup # <> ?m   5B b, ['] b, operand, ;
: sbx, ( o -- )   b/w>w dup   dup # = if drop 1D else
  (adi/sbi) encode ( 00 )  then b,   ['] w, operand, ;
: sby, ( o -- )   b/w>w dup   (adi/sbi) encode 02 or b,
  ['] w, operand, ;
' adx, ' ady, x/y adi,   ' sbx, ' sby, x/y sbi,

: mov, ( o1 o2 -- )   b/w>b ( be optimistic )
  dup b) = if   45 b, ['] die operand,   b/w>b   dup b) <> ?m
    ['] die operand,   exit then
  dup w) = if   55 b, ['] die operand,   b/w>w   dup w) <> ?m
    ['] die operand,   exit then
  dup # <> ?m   35 b, ['] b,  operand,   b/w>w   dup w) <> ?m
    ['] die operand,   exit ;

: bitmod ( n m "name" -- ) ( o bit -- )   create , , ;does:
  dup cell + @ b,   @ swap 7 and 2* or b,   b/w>w   dup w) <> ?m
  ['] die operand, ;

  90 10 bitmod cpl,   90 11 bitmod ccm,
  72 10 bitmod set,   72 11 bitmod res,

: bitjmp ( n "name" -- ) ( j o bit -- )   create , ;does:
  72 b,   @ swap 7 and 2* or b,   b/w>w   dup w) <> ?m
  ['] die operand,   dup & <> ?m   ['] die operand, ;

  00 bitjmp tjt,   01 bitjmp tjf,

: nullary    create ,   ;does: @ b, ;
: 2nullary   create , , ;does: dup cell + @ b, @ b, ;

  42 nullary mlx,   90 42 2nullary mly,   ' mlx, ' mly, x/y mli,
  62 nullary dvx,   90 62 2nullary dvy,   ' dvx, ' dvy, x/y dvi,
  65 nullary div,   ( note dvi, is DIV and div, is DIVW )

  80 nullary irt,    81 nullary ret,
( 82 INT em      )   83 nullary trp,
( 84 POP A       ) ( 85 POP XY     )
( 86 POP CC      ) ( 87 RETF       )
( 88 PSH A       ) ( 89 PSH XY     )
( 8A PSH CC      )   8B nullary brk,
  8C nullary ccf,  ( 8D CALLF      )
  8E nullary hlt,    8F nullary wfi,

  72 8E 2nullary wfe,

( 90 PDY        )  ( 91 PIX        )
( 92 PIY        )  ( 93 TFR XY,YX  )
( 94 TFR S,XY   )  ( 95 TFR XYH,A  )
( 96 TFR XY,S   )  ( 97 TFR XYL,A  )
  98 nullary rcf,    99 nullary scf,
  9A nullary rim,    9B nullary sim,
  9C nullary rvf,    9D nullary nop,
( 9E TFR A,XYH  )  ( 9F TFR A,XYL  )

: vector  ( u -- a )   dup 20 u> ?abort" vector? " 4* 8002 or ;
: !vector ( a u -- )   vector w! ;
: @vector ( u -- a )   vector w@ ;

: 0vectors ( -- )   8080 8000 begin 2dup <> while   8200 over w!
  2 + 0000 over w!   2 + repeat ;

( base ) restore
