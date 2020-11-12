#-- demonstrates the usage of an extended Interface
#-- delegates using the I_DynamicINPUT interface from libI3.4gl
#-- *must* implement all 3 methods
#-- if a method is not actually needed it remains as boilerplate
&include "myassert.inc"
IMPORT reflect
IMPORT util
IMPORT FGL utils
IMPORT FGL libI3
IMPORT FGL utils_customer
SCHEMA stores
TYPE TM_Customer RECORD LIKE customer.*
CONSTANT ON_ACTION_an_action = "ON ACTION an_action"
CONSTANT C_zipcode = "zipcode"
--we implement 3 methods
FUNCTION (self TM_Customer) BeforeInput(d ui.Dialog)
  UNUSED(self)
  CALL d.addTrigger(ON_ACTION_an_action)
END FUNCTION

FUNCTION (self TM_Customer) event(d ui.Dialog, event STRING)
  UNUSED(self)
  UNUSED(d)
  IF event == ON_ACTION_an_action THEN
    MESSAGE "an action"
  END IF
END FUNCTION

FUNCTION (self TM_Customer) AfterField(fieldName STRING) RETURNS STRING
  IF fieldName == C_zipcode AND length(self.zipcode) <> 5 THEN
    RETURN "zipcode must have 5 digits"
  END IF
  RETURN NULL
END FUNCTION

FUNCTION main()
  DEFINE tmcust TM_Customer
  CALL utils.dbconnect()
  SELECT * INTO tmcust.* FROM customer WHERE @customer_num = 101
  OPEN FORM f FROM "customers_singlerow"
  DISPLAY FORM f
  LET int_flag = FALSE
  --pass our delegate having the event() method and the reflection value
  --of the Record
  CALL runINPUT(delegate: tmcust, recVal: reflect.Value.valueOf(tmcust))
  CALL utils_customer.updateCustomer(tmcust.*) RETURNING tmcust.*
  DISPLAY util.JSON.stringify(tmcust)
END FUNCTION
