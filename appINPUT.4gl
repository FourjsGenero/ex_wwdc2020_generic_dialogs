&include "myassert.inc"
IMPORT reflect
IMPORT util
IMPORT FGL utils
IMPORT FGL libINPUT
IMPORT FGL utils_customer
SCHEMA stores
TYPE TM_Customer RECORD LIKE customer.*
--we "glue" methods to the TM_Customer RECORD
--new in 4.00: we can have the methods placed directly below the
--RECORD definition
FUNCTION (self TM_Customer) event(d ui.Dialog, event STRING)
  DISPLAY "TM_Customer event:", event
  CASE
    WHEN event == "BEFORE INPUT"
      CALL d.addTrigger("ON ACTION an_action")
    WHEN event == "ON ACTION an_action"
      MESSAGE "an action"
    WHEN event.getIndexOf("AFTER FIELD", 1) == 1 AND length(self.zipcode) <> 5
      ERROR "zipcode must have 5 digits"
      CALL d.nextField(d.getCurrentItem())
  END CASE
END FUNCTION

FUNCTION main()
  DEFINE tmcust TM_Customer
  DEFINE tminp TM_Input
  CALL utils.dbconnect()
  SELECT * INTO tmcust.* FROM customer WHERE @customer_num = 101
  OPEN FORM f FROM "customers_singlerow"
  DISPLAY FORM f
  LET int_flag = FALSE
  --pass our delegate having the event() method and the reflection value
  --of the Record
  CALL tminp.input(delegate: tmcust, recVal: reflect.Value.valueOf(tmcust))
  CALL utils_customer.updateCustomer(tmcust.*) RETURNING tmcust.*
  DISPLAY util.JSON.stringify(tmcust)
END FUNCTION
