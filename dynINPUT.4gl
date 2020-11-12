IMPORT util
IMPORT FGL utils
IMPORT FGL utils_customer
SCHEMA stores

MAIN
  DEFINE customer RECORD LIKE customer.*
  DEFINE fields DYNAMIC ARRAY OF RECORD
    name STRING, -- a column name
    type STRING -- a column type
  END RECORD = [(name: "customer_num", type: "INTEGER"), (name: "fname", type: "CHAR(15)"),
      (name: "lname", type: "CHAR(15)"), (name: "company", type: "CHAR(20)"),
      (name: "address1", type: "CHAR(20)"), (name: "address2", type: "CHAR(20)"),
      (name: "city", type: "CHAR(15)"), (name: "state", type: "CHAR(2)"),
      (name: "zipcode", type: "CHAR(5)"), (name: "phone", type: "CHAR(18)")]
  CALL utils.dbconnect()
  SELECT * INTO customer.* FROM customer WHERE @customer_num = 101
  OPEN FORM f FROM "customers_singlerow"
  DISPLAY FORM f
  VAR d ui.Dialog
  LET d = ui.Dialog.createInputByName(fields)
  CALL d.setFieldValue("customer_num", customer.customer_num)
  CALL d.setFieldValue("fname", customer.fname)
  CALL d.setFieldValue("lname", customer.lname)
  CALL d.setFieldValue("lname", customer.company)
  -- etc. etc
  CALL d.addTrigger("ON ACTION accept")
  CALL d.addTrigger("ON ACTION cancel")
  CALL d.addTrigger("ON ACTION an_action")
  WHILE TRUE -- event loop for dialog d
    VAR event STRING
    LET event = d.nextEvent()
    DISPLAY "event:",event
    CASE
      WHEN event == "ON ACTION cancel"
        LET int_flag = TRUE
        EXIT WHILE
      WHEN event == "ON ACTION accept"
        EXIT WHILE
      WHEN event == "AFTER FIELD zipcode" AND length(d.getFieldValue("zipcode")) <> 5
        ERROR "zipcode must have 5 digits"
        CALL d.nextField("zipcode")
      WHEN event = "ON ACTION an_action"
        MESSAGE "an_action"
    END CASE
  END WHILE
  IF NOT int_flag THEN --sync dialog values to customer
    LET customer.customer_num = d.getFieldValue("customer_num")
    LET customer.fname = d.getFieldValue("fname")
    LET customer.company = d.getFieldValue("company")
    --etc.. etc..
  END IF
  CALL utils_customer.updateCustomer(customer.*) RETURNING customer.*
  DISPLAY util.JSON.stringify(customer)
END MAIN
