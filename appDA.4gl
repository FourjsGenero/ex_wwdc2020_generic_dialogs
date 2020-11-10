&include "myassert.inc"
IMPORT reflect
IMPORT FGL utils
IMPORT FGL libDA
IMPORT FGL utils_customer
--we can't have methods for ARRAYs.. but we
--can embed the whole array in a RECORD having methods
TYPE TM_cust RECORD
  arr T_customers
END RECORD

FUNCTION (self TM_cust) init(d ui.Dialog)
  UNUSED(self)
  CALL d.addTrigger("ON ACTION show_orders")
END FUNCTION

FUNCTION (self TM_cust) event(d ui.Dialog, event STRING, row INTEGER)
  DISPLAY "TM_cust event:", event, " in row:", row
  CASE
    WHEN event == "BEFORE ROW"
      CALL utils_customer.check_order_count(
        d: d, num: self.arr[row].customer_num, action: "show_orders")
    WHEN event == "ON ACTION show_orders"
      MESSAGE "would show orders for customer num:", self.arr[row].customer_num
  END CASE
END FUNCTION

FUNCTION main()
  DEFINE c TM_cust
  CALL utils.dbconnect()
  CALL utils_customer.fetch_customers(c.arr)
  OPEN FORM f FROM "customers"
  DISPLAY FORM f
  CALL libDA.runDisplayArray(
    delegate: c, screenRecord: "scr", arrVal: reflect.Value.valueOf(c.arr))
END FUNCTION
