-- demonstrates the usage of multiple optional interfaces
-- uses libINPUTIM.4gl as library
&include "myassert.inc"
IMPORT reflect
IMPORT util
IMPORT FGL utils
IMPORT FGL libINPUTIM
IMPORT FGL utils_customer
SCHEMA stores
TYPE TM_Customer RECORD LIKE customer.*
CONSTANT ON_ACTION_an_action = "ON ACTION an_action"
CONSTANT C_zipcode = "zipcode"
--we implement 3 methods out of 5 possible methods
FUNCTION (self TM_Customer) BeforeInput(d ui.Dialog)
  UNUSED(self)
  CALL d.addTrigger(ON_ACTION_an_action)
END FUNCTION

FUNCTION (self TM_Customer) OnAction(actionEvent STRING)
  UNUSED(self)
  IF actionEvent == ON_ACTION_an_action THEN
    MESSAGE "an action"
  END IF
END FUNCTION

FUNCTION (self TM_Customer)
  AfterField(
  d ui.Dialog, fieldName STRING)
  RETURNS STRING
  UNUSED(d)
  IF fieldName == C_zipcode AND length(self.zipcode) <> 5 THEN
    RETURN "zipcode must have 5 digits"
  END IF
  RETURN NULL
END FUNCTION

{--uncomment this code and it will be called by libINPUTIM too
 --before each field
FUNCTION (self TM_Customer) BeforeField(d ui.Dialog,fieldName STRING)
  UNUSED(self)
  UNUSED(d)
  DISPLAY "TM_Customer BeforeField:",fieldName
END FUNCTION
}

--this function checks if the TM_Customer RECORD conforms to 
--all 3 Interfaces: since we pass the delegate via reflection
--the compiler cannot know anymore that we want to have those
--3 Interfaces checked
--If there was an IMPLEMENTS clause for the RECORD type definition
--we wouldn't need to do it here
--IMPLEMENTS would als enable code completion for the method names
--and types... so this is just a workaround until IMPLEMENTS is there

FUNCTION (self TM_Customer) checkInterfaces()
  RETURN
  VAR ifBI I_BeforeInput
  LET ifBI = self --checks if TM_Customer implements I_BeforeInput
  VAR ifOA I_OnAction
  LET ifOA = self --checks if TM_Customer implements I_OnAction
  VAR ifAF I_AfterField
  LET ifAF = self --checks if TM_Customer implements I_AfterField
END FUNCTION

FUNCTION main()
  DEFINE tmcust TM_Customer
  CALL utils.dbconnect()
  SELECT * INTO tmcust.* FROM customer WHERE @customer_num = 101
  OPEN FORM f FROM "customers_singlerow"
  DISPLAY FORM f
  LET int_flag = FALSE
  --pass our delegate as reflect Value: this enables the check for multiple interfaces
  CALL runINPUT(
    delegate: reflect.Value.valueOf(tmcust),
    recVal: reflect.Value.valueOf(tmcust))
  CALL utils_customer.updateCustomer(tmcust.*) RETURNING tmcust.*
  DISPLAY util.JSON.stringify(tmcust)
END FUNCTION
