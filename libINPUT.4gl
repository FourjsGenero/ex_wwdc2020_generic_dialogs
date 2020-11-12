&include "myassert.inc"
IMPORT reflect
IMPORT util
IMPORT FGL utils
--define Interface methods our generic dialog can call
--application RECORDs *must* implement this interface
PUBLIC TYPE I_DynamicINPUT INTERFACE
  event(d ui.Dialog, event STRING)
END INTERFACE

PUBLIC TYPE TM_Input RECORD
  d ui.Dialog,
  fieldNames DYNAMIC ARRAY OF STRING,
  fields T_fields
END RECORD

PUBLIC FUNCTION (self TM_Input)
  input(
  delegate I_DynamicINPUT, recVal reflect.Value)
  CALL self.computeFieldNamesAndTypes(recVal)
  LET self.d = ui.Dialog.createInputByName( fields: self.fields )
  CALL self.setRecordData(recVal)
  CALL self.d.addTrigger("ON ACTION accept")
  CALL self.d.addTrigger("ON ACTION cancel")
  WHILE TRUE -- event loop for dialog self.d
    VAR event = self.d.nextEvent()
    IF event.getIndexOf(str: "AFTER FIELD",startIndex: 1) == 1 THEN
      --we sync the changes made to the dialog field to the appropriate field in the record
      CALL self.syncDialogFieldWithRecordField(self.d.getCurrentItem(),recVal)
    END IF
    --call back the delegate on each event
    CALL delegate.event(self.d, event)
    CASE
      WHEN event == "ON ACTION cancel"
        LET int_flag=TRUE
        DISPLAY "int_flag=",int_flag
        EXIT WHILE
      WHEN event == "ON ACTION accept"
        CALL self.d.accept()
      WHEN event = "AFTER INPUT"
        EXIT WHILE
    END CASE
  END WHILE
END FUNCTION

--retrieve the column names from the current form 
--and assign the record variable field types using reflection
PRIVATE FUNCTION (self TM_Input) computeFieldNamesAndTypes(recVal reflect.Value)
  VAR recType = recVal.getType()
  VAR formNode = ui.Window.getCurrent().getForm().getNode()
  VAR l = formNode.selectByTagName("FormField")
  VAR i INT
  VAR len = l.getLength()
  FOR i = 1 TO len
    VAR node = l.item(i)
    VAR name = node.getAttribute("colName")
    LET self.fields[i].name = name
    LET self.fields[i].type = recType.getFieldTypeByName(name).toString()
  END FOR
  DISPLAY "fields:", util.JSON.stringify(self.fields)
END FUNCTION

--fill the initial dialog data by using the reflect values of the record
PRIVATE FUNCTION (self TM_Input) setRecordData(recVal reflect.Value)
  DEFINE i INT
  VAR numFields = self.fields.getLength()
  FOR i = 1 TO numFields
    VAR name = self.fields[i].name
    VAR fieldval reflect.Value
    LET fieldval = recVal.getFieldByName(name)
    DISPLAY "set field:",name," value:",fieldval.toString()
    CALL self.d.setFieldValue(name, fieldval.toString())
  END FOR
END FUNCTION

--called after each AFTER field to sync Dialog field value back to the application record value
PRIVATE FUNCTION (self TM_Input) syncDialogFieldWithRecordField(name STRING,recVal reflect.Value)
  VAR dlgVal = reflect.Value.copyOf(self.d.getFieldValue(name))
  CALL printRV(name,dlgVal)
  VAR fieldval = recVal.getFieldByName(name)
  MYASSERT(fieldVal.getType().isAssignableFrom(dlgVal.getType()))
  DISPLAY "sync dlg field:",name," value:",dlgVal.toString(),"type:",dlgVal.getType().toString()," to record field"
  CALL fieldval.set(dlgVal)
END FUNCTION

FUNCTION isAfterField(event STRING,colname STRING)
  DEFINE testname STRING
  LET testname="AFTER FIELD "||colname
  RETURN event.equals(testname)
END FUNCTION
