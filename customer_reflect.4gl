IMPORT reflect
IMPORT util
SCHEMA stores
MAIN
  DEFINE c RECORD LIKE customer.* = (customer_num: 5, fname: "Jon", lname: "Schnee")
  DEFINE val, fieldVal reflect.Value, type, fieldType reflect.Type
  DEFINE i INT
  LET val = reflect.Value.valueOf(c)
  LET type = val.getType()
  DISPLAY type.toString(), " ", type.getKind()
  VAR fieldName STRING
  FOR i = 1 TO type.getFieldCount()
    LET fieldName = type.getFieldName(i)
    LET fieldVal = val.getField(i)
    LET fieldType = type.getFieldType(i)
    DISPLAY fieldName, "=", fieldVal.toString(), " type=", fieldType.toString()
  END FOR
  --we set a member to another value via reflection
  LET fieldVal=val.getFieldByName("fname")
  VAR s="Daenerys"
  CALL fieldVal.set(reflect.Value.valueOf(s))
  --the following call prints recursively all data of a reflect value
  DISPLAY util.JSON.stringify(c) 
END MAIN

