&include "myassert.inc"
IMPORT reflect
IMPORT FGL utils
IMPORT FGL libINPUT
IMPORT FGL utils_customer
SCHEMA stores
TYPE TM_Customer RECORD LIKE customer.*
--we "glue" methods to the TM_Customer RECORD
--new in 4.00: we can have the methods placed directly below the
--RECORD definition
FUNCTION (self TM_Customer) init(d ui.Dialog)
  UNUSED(self)
  CALL d.addTrigger("ON ACTION an_action")
END FUNCTION

FUNCTION (self TM_Customer) event(d ui.Dialog, event STRING)
  DISPLAY "TM_Customer event:", event
  CASE
    WHEN event.getIndexOf(str: "AFTER FIELD",1) == 1 AND d.getCurrentItem()=="zipcode"
        AND length(self.zipcode)<>5 
      ERROR "zipcode must have 5 digits"
      CALL d.nextField("zipcode")
    WHEN event == "ON ACTION an_action"
      MESSAGE "an action"
  END CASE
END FUNCTION

FUNCTION main()
  DEFINE tmcust TM_Customer
  CALL utils.dbconnect()
  SELECT * INTO tmcust.* FROM customer WHERE @customer_num=101
  OPEN FORM f FROM "customers_singlerow"
  DISPLAY FORM f
  LET int_flag = FALSE
  CALL libINPUT.runINPUT(
    delegate: tmcust, recVal: reflect.Value.valueOf(tmcust))
  CALL utils_customer.updateCustomer(tmcust.*) RETURNING tmcust.*
  CALL printRV("tmcust:",reflect.Value.valueOf(tmcust))
END FUNCTION
