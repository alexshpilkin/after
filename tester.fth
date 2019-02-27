\ Hayes-style test harness

variable previous-depth   variable test-depth
label test-stack   16 cells allot

: {   depth previous-depth !   0 test-depth ! ;

: ->   depth previous-depth @ -   dup test-depth !
  cells test-stack tuck + push   begin   dup peek u< while
  tuck !   cell+ repeat   drop lose ;

: }   depth previous-depth @ -   dup test-depth @ <>
  ?abort" Stack depth differs"   cells test-stack tuck + push
  begin   dup peek u< while   tuck @ <>
  ?abort" Stack contents differ"   cell+ repeat   drop lose ;

: ?stack   depth 0 <> ?abort" Stray items on the stack" ;
