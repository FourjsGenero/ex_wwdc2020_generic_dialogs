&include "myassert.inc"
TYPE I_1 INTERFACE
  foo() RETURNS()
END INTERFACE

TYPE T_1 RECORD
  member INT
END RECORD

FUNCTION (self T_1) foo()
  DISPLAY "T_1 foo"
  LET self.member = 5
END FUNCTION

TYPE T_2 RECORD
  anotherMember STRING
END RECORD

FUNCTION (self T_2) foo()
  UNUSED(self)
  DISPLAY "T_2 foo"
END FUNCTION

TYPE T_3 RECORD
  xx INT
END RECORD

FUNCTION fooViaInterface(i1 I_1)
  CALL i1.foo()
END FUNCTION

FUNCTION MAIN()
  DEFINE
    t1 T_1,
    t2 T_2,
    t3 T_3
  UNUSED(t3)
  CALL fooViaInterface(t1) --prints "T_1 foo"
  DISPLAY t1.member --5
  CALL fooViaInterface(t2) --prints "T_2 foo"
  --CALL fooViaInterface(t3)
END FUNCTION
