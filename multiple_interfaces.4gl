&include "myassert.inc"
IMPORT reflect
SCHEMA stores
PUBLIC TYPE I_BeforeInput INTERFACE
  BeforeInput(d ui.Dialog)
END INTERFACE

PUBLIC TYPE I_BeforeField INTERFACE
  BeforeField(d ui.Dialog,fieldName STRING) 
END INTERFACE

PUBLIC TYPE I_AfterField INTERFACE
  AfterField(fieldName STRING) RETURNS(STRING)
END INTERFACE

TYPE TM_Cust RECORD LIKE customer.*

FUNCTION (self TM_Cust) BeforeInput(d ui.Dialog)
  UNUSED(self)
  UNUSED(d)
  DISPLAY "TM_Cust BeforeInput"
END FUNCTION

FUNCTION (self TM_Cust) BeforeField(d ui.Dialog, fieldName STRING)
  UNUSED(self)
  UNUSED(d)
  DISPLAY "TM_Cust BeforeInput ",fieldName
END FUNCTION

FUNCTION (self TM_Cust) AfterField(fieldName STRING) RETURNS STRING
  UNUSED(self)
  DISPLAY "TM_Cust AfterField ",fieldName
  RETURN NULL
END FUNCTION

--this function checks if the TM_Cust RECORD conforms to 
--all 3 Interfaces: since we pass the delegate via reflection
--the compiler cannot know anymore that we want to have those
--3 Interfaces checked
--If there was an IMPLEMENTS clause for the RECORD type definition
--we wouldn't need to do it here
FUNCTION (self TM_Cust) CheckInterfaces() --never called
  DEFINE iBI I_BeforeInput
  DEFINE iBF I_BeforeField
  DEFINE iAF I_AfterField
  RETURN --make clear we are not called
  LET iBI=self --compiler checks that we conform to I_BeforeInput
  LET iBF=self --compiler checks that we conform to I_BeforeField
  LET iAF=self --compiler checks that we conform to I_AfterField
END FUNCTION

FUNCTION main()
  DEFINE tmcust TM_Cust --we pass now the reflect value
  CALL multiCallBack(reflect.Value.valueOf(tmcust))
END FUNCTION

--etc..
FUNCTION multiCallBack(delegate reflect.Value)
  DEFINE iBI I_BeforeInput
  DEFINE iBF I_BeforeField
  DEFINE iAF I_AfterField
  DEFINE d ui.Dialog
  IF delegate.canAssignToVariable(iBI) THEN
     CALL delegate.assignToVariable(iBI)
     CALL iBI.BeforeInput(d)
  END IF
  IF delegate.canAssignToVariable(iBF) THEN
     CALL delegate.assignToVariable(iBF)
     CALL iBF.BeforeField(d,"zipcode")
  END IF
  IF delegate.canAssignToVariable(iAF) THEN
     CALL delegate.assignToVariable(iAF)
     CALL iAF.AfterField("zipcode") RETURNING status
  END IF
  --etc
END FUNCTION


