&include "myassert.inc"
IMPORT reflect
IMPORT util
IMPORT FGL utils
--define Interface methods our generic dialog can call
--application RECORDs *must* define this interface
PUBLIC TYPE I_DynamicINPUT INTERFACE
  init(d ui.Dialog),
  event(d ui.Dialog, event STRING)
END INTERFACE
--the usual field definition for dynamic dialogs
PUBLIC TYPE T_fields DYNAMIC ARRAY OF RECORD
  name STRING, -- a column name
  type STRING -- a column type
END RECORD

PRIVATE TYPE TM_Input RECORD
  d ui.Dialog,
  fieldNames DYNAMIC ARRAY OF STRING,
  fields T_fields
END RECORD

--this is the only function callable from other modules
--hence all RECORD member of TM_Input cannot be accessed from other modules
--(data encapsulation)
PUBLIC FUNCTION runINPUT(
  delegate I_DynamicINPUT, recVal reflect.Value)
  DEFINE a_dialog TM_Input
  CALL a_dialog.input(delegate, recVal)
END FUNCTION

PRIVATE FUNCTION (self TM_Input)
  input(
  delegate I_DynamicINPUT, recVal reflect.Value)
  DEFINE event STRING
  CALL self.computeFieldNames(recVal.getType())
  LET self.d = ui.Dialog.createInputByName( fields: self.fields )
  CALL self.setRecordData(recVal)
  CALL self.d.addTrigger("ON ACTION accept")
  CALL self.d.addTrigger("ON ACTION cancel")
  --call the init function to allow the delegate adding actions,triggers
  CALL delegate.init(self.d)
  WHILE TRUE -- event loop for dialog self.d
    LET event = self.d.nextEvent()
    --call back the delegate on each event
    IF event.getIndexOf(str: "AFTER FIELD",startIndex: 1) == 1 THEN
      --we sync the changes made to the dialog data to the appropriate field in the record
      CALL self.syncDialogFieldWithRecordData(self.d.getCurrentItem(),recVal)
    END IF
    CALL delegate.event(self.d, event)
    CASE
      WHEN event = "ON ACTION cancel"
        LET int_flag=TRUE
        DISPLAY "int_flag=",int_flag
        EXIT WHILE
      WHEN event = "ON ACTION accept"
        CALL self.d.accept()
      WHEN event = "AFTER INPUT"
        EXIT WHILE
    END CASE
  END WHILE
END FUNCTION

--retrieve the column names from the current form 
PRIVATE FUNCTION (self TM_Input) computeFieldNames(recType reflect.Type)
  CALL self.fields.clear()
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

--fill the dialog data by using the reflect values of the record
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

PRIVATE FUNCTION (self TM_Input) syncDialogFieldWithRecordData(name STRING,recVal reflect.Value)
  DEFINE s STRING
  LET s= self.d.getFieldValue(name) --reflect.Value.valueOf(self.d.getFieldValue(name)) doesn't work
  VAR dlgVal = reflect.Value.valueOf(s)
  CALL printRV(name,dlgVal)
  VAR fieldval = recVal.getFieldByName(name)
  MYASSERT(fieldVal.getType().isAssignableFrom(dlgVal.getType()))
  DISPLAY "sync dlg field:",name," value:",s," to record field"
  CALL fieldval.set(dlgVal)
END FUNCTION

