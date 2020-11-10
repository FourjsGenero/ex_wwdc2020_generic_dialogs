IMPORT reflect
IMPORT FGL utils
IMPORT FGL utils_customer
SCHEMA stores

MAIN
  DEFINE arr T_customers
  CALL utils.dbconnect()
  CALL fetch_customers(arr)
  OPEN FORM f FROM "customers"
  DISPLAY FORM f
  DISPLAY ARRAY arr TO scr.* ATTRIBUTE(UNBUFFERED, ACCEPT = FALSE)
    BEFORE ROW
      CALL utils_customer.check_order_count(
        d: DIALOG, num: arr[arr_curr()].customer_num, action: "show_orders")
    ON UPDATE
      CALL utils_customer.updateCustomer(arr[arr_curr()].*)
        RETURNING arr[arr_curr()].*
    ON ACTION show_orders ATTRIBUTE(ROWBOUND)
      MESSAGE "would show orders for customer num:",
        arr[arr_curr()].customer_num
  END DISPLAY
END MAIN
