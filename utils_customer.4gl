SCHEMA stores
PUBLIC TYPE T_customer RECORD LIKE customer.*
PUBLIC TYPE T_customers DYNAMIC ARRAY OF T_customer

FUNCTION fetch_customers(customers T_customers)
  DEFINE customer T_customer
  DEFINE n INT
  DECLARE cu1 CURSOR FOR SELECT * INTO customer.* FROM customer
  FOREACH cu1
    LET n = n + 1
    LET customers[n].* = customer.*
  END FOREACH
END FUNCTION

FUNCTION check_order_count(
  d ui.Dialog, num LIKE customer.customer_num, action STRING)
  DEFINE numOrders INT
  --DEFINE custarr T_customers
  --SELECT COUNT(*) INTO numOrders FROM orders WHERE @orders.customer_num = $custarr[5].customer_num
  SELECT COUNT(*) INTO numOrders FROM orders WHERE @orders.customer_num = $num
  CALL d.setActionActive(action, numOrders > 0)
END FUNCTION

FUNCTION updateCustomer(customer T_customer) RETURNS T_customer
  DEFINE num LIKE customer.customer_num = customer.customer_num
  IF NOT int_flag THEN
    DISPLAY "UPDATE customer"
    UPDATE customer SET customer.* = customer.* WHERE @customer_num = $num
  ELSE
    DISPLAY "re read customer with SELECT"
    --re read to repair changes to the record, this avoids a save var
    SELECT * INTO customer.* FROM customer WHERE @customer_num == $num
  END IF
  RETURN customer.*
END FUNCTION
