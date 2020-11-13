&include "myassert.inc"
IMPORT reflect
TYPE I_1 INTERFACE
  foo() RETURNS()
END INTERFACE

TYPE T_1 RECORD
  member INT
END RECORD

TYPE T_2 RECORD
  member INT
END RECORD

FUNCTION (self T_1) foo()
  UNUSED(self)
  DISPLAY "T_1 foo"
END FUNCTION

FUNCTION main()
  DEFINE i1 I_1 --we use reflection to determine
  DEFINE t1 T_1 --that T_1 conforms to I_1
  VAR reflectVal1=reflect.Value.valueOf(t1)
  IF reflectVal1.canAssignToVariable(i1) THEN
    DISPLAY "t1 implements the I_1 interface"
    CALL reflectVal1.assignToVariable(i1)
    CALL i1.foo()
  END IF
  VAR t2 T_2
  VAR reflectVal2=reflect.Value.valueOf(t2)
  IF NOT reflectVal2.canAssignToVariable(i1) THEN
    DISPLAY "t2 does not implement the I_1 interface"
  END IF
END FUNCTION
