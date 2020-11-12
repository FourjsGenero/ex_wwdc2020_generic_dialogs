-- demonstrates how one can use a dynamic DISPLAY ARRAY in a lib (libDA.4gl)
-- using reflection and multiple interfaces
&include "myassert.inc"
IMPORT reflect
IMPORT FGL utils
IMPORT FGL libDA
IMPORT FGL utils_customer
CONSTANT ON_ACTION_show_orders = "ON ACTION show_orders"
--we can't have methods for ARRAYs.. but we
--can embed the whole array in a RECORD having methods
TYPE TM_cust RECORD
  arr T_customers
END RECORD

FUNCTION (self TM_cust) BeforeDisplay(d ui.Dialog)
  UNUSED(self)
  CALL d.addTrigger(ON_ACTION_show_orders)
END FUNCTION

FUNCTION (self TM_cust) BeforeRow(d ui.Dialog, row INT)
  UNUSED(self)
  CALL utils_customer.check_order_count(
    d: d, num: self.arr[row].customer_num, action: "show_orders")
END FUNCTION

FUNCTION (self TM_cust) OnActionInRow(actionEvent STRING, row INT)
  IF actionEvent == ON_ACTION_show_orders THEN
    MESSAGE "would show orders for customer num:", self.arr[row].customer_num
  END IF
END FUNCTION

FUNCTION (self TM_cust) checkInterfaces()
  RETURN
  VAR ifBD I_BeforeDisplay
  LET ifBD = self
  VAR ifBR I_BeforeRow
  LET ifBR = self
  VAR ifOA I_OnActionInRow
  LET ifOA = self
END FUNCTION

FUNCTION main()
  DEFINE c TM_cust
  CALL utils.dbconnect()
  CALL utils_customer.fetch_customers(c.arr)
  OPEN FORM f FROM "customers"
  DISPLAY FORM f
  CALL libDA.runDisplayArray(
    delegate: reflect.Value.valueOf(c),
    screenRecord: "scr",
    arrVal: reflect.Value.valueOf(c.arr))
END FUNCTION
