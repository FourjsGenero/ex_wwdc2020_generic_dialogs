IMPORT util
IMPORT FGL utils
IMPORT FGL utils_customer
SCHEMA stores

MAIN
  DEFINE customer RECORD LIKE customer.*
  CALL utils.dbconnect()
  SELECT * INTO customer.* FROM customer WHERE @customer_num=101
  OPEN FORM f FROM "customers_singlerow"
  DISPLAY FORM f
  LET int_flag = FALSE
  INPUT BY NAME customer.* WITHOUT DEFAULTS ATTRIBUTE(UNBUFFERED)
    AFTER FIELD zipcode
      IF LENGTH(customer.zipcode) <> 5 THEN
        ERROR "zipcode must have 5 digits"
        NEXT FIELD CURRENT
      END IF
    ON ACTION an_action
      MESSAGE "an_action"
  END INPUT
  CALL utils_customer.updateCustomer(customer.*) RETURNING customer.*
  DISPLAY util.JSON.stringify(customer)
END MAIN
