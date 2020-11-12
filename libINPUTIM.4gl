-- demonstrates the usage of multiple optional interfaces
-- checks at run time which interfaces the delegate supports
&include "myassert.inc"
IMPORT reflect
IMPORT util
IMPORT FGL utils
PUBLIC CONSTANT BEFORE_INPUT = "BEFORE INPUT"
PUBLIC CONSTANT BEFORE_FIELD = "BEFORE FIELD"
PUBLIC CONSTANT AFTER_FIELD = "AFTER FIELD"
PUBLIC CONSTANT AFTER_INPUT = "AFTER INPUT"
PUBLIC CONSTANT ON_ACTION = "ON ACTION"
PUBLIC CONSTANT ON_ACTION_accept = "ON ACTION accept"
PUBLIC CONSTANT ON_ACTION_cancel = "ON ACTION cancel"
--define 4 Interface methods our generic dialog *could* call
--in case application RECORDs did choose to implement them

PUBLIC TYPE I_BeforeInput INTERFACE
  BeforeInput(d ui.Dialog)
END INTERFACE

PUBLIC TYPE I_BeforeField INTERFACE
  BeforeField(d ui.Dialog, fieldName STRING)
END INTERFACE

PUBLIC TYPE I_AfterField INTERFACE
  AfterField(d ui.Dialog, fieldName STRING) RETURNS STRING
END INTERFACE

PUBLIC TYPE I_OnAction INTERFACE
  OnAction(actionEvent STRING)
END INTERFACE

PUBLIC TYPE I_DialogEvent INTERFACE
  event(d ui.Dialog, event STRING)
END INTERFACE

PRIVATE TYPE TM_Input RECORD
  d ui.Dialog,
  fieldNames DYNAMIC ARRAY OF STRING,
  fields T_fields
END RECORD

--this is the only function callable from other modules
--hence all RECORD member of TM_Input cannot be accessed from other modules
--(data encapsulation)
PUBLIC FUNCTION runINPUT(delegate reflect.Value, recVal reflect.Value)
  DEFINE a_dialog TM_Input
  CALL a_dialog.input(delegate, recVal)
END FUNCTION

PRIVATE FUNCTION (self TM_Input)
  input(
  delegate reflect.Value, recVal reflect.Value)
  CALL self.computeFieldNamesAndTypes(recVal.getType())
  LET self.d = ui.Dialog.createInputByName(fields: self.fields)
  CALL self.setRecordData(recVal)
  CALL self.d.addTrigger(ON_ACTION_accept)
  CALL self.d.addTrigger(ON_ACTION_cancel)
  VAR d = self.d
  WHILE TRUE -- event loop for dialog self.d
    VAR event = d.nextEvent()
    CASE
      WHEN event == BEFORE_INPUT
        VAR ifBI I_BeforeInput
        IF delegate.canAssignToVariable(ifBI) THEN
          --delegate implents the I_BeforeInput interface
          CALL delegate.assignToVariable(ifBI)
          CALL ifBI.BeforeInput(d)
        END IF
      WHEN event.getIndexOf(ON_ACTION, 1) == 1
        VAR ifOA I_OnAction
        IF delegate.canAssignToVariable(ifOA) THEN
          --delegate implents the I_OnAction interface
          CALL delegate.assignToVariable(ifOA)
          CALL ifOA.OnAction(actionEvent: event)
        END IF
      WHEN event.getIndexOf(BEFORE_FIELD, 1) == 1
        VAR ifBF I_BeforeField
        IF delegate.canAssignToVariable(ifBF) THEN
          --delegate implents the I_BeforeField interface
          CALL delegate.assignToVariable(ifBF)
          CALL ifBF.BeforeField(d: d, d.getCurrentItem())
        END IF
      WHEN event.getIndexOf(AFTER_FIELD, 1) == 1
        CALL self.syncDialogFieldWithRecordField(d.getCurrentItem(), recVal)
        VAR ifAF I_AfterField
        IF delegate.canAssignToVariable(ifAF) THEN
          --delegate implents the I_AfterField interface
          CALL delegate.assignToVariable(ifAF)
          VAR err = ifAF.AfterField(d, d.getCurrentItem())
          IF err THEN
            ERROR err
            CALL d.nextField(d.getCurrentItem())
            CONTINUE WHILE
          END IF
        END IF
      OTHERWISE --ON CHANGE and may be others
        VAR ifDE I_DialogEvent
        IF delegate.canAssignToVariable(ifDE) THEN
          --delegate implents the I_DialogEvent interface
          CALL delegate.assignToVariable(ifDE)
          CALL ifDE.event(d: d, event: event)
        END IF
    END CASE
    CASE
      WHEN event = ON_ACTION_cancel
        LET int_flag = TRUE
        DISPLAY "int_flag=", int_flag
        EXIT WHILE
      WHEN event = ON_ACTION_accept
        CALL self.d.accept()
      WHEN event = AFTER_INPUT
        EXIT WHILE
    END CASE
  END WHILE
END FUNCTION

--retrieve the column names from the current form
PRIVATE FUNCTION (self TM_Input) computeFieldNamesAndTypes(recType reflect.Type)
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
    DISPLAY "set field:", name, " value:", fieldval.toString()
    CALL self.d.setFieldValue(name, fieldval.toString())
  END FOR
END FUNCTION

PRIVATE FUNCTION (self TM_Input)
  syncDialogFieldWithRecordField(
  name STRING, recVal reflect.Value)
  VAR dlgVal = reflect.Value.copyOf(self.d.getFieldValue(name))
  CALL printRV(name, dlgVal)
  VAR fieldval = recVal.getFieldByName(name)
  MYASSERT(fieldVal.getType().isAssignableFrom(dlgVal.getType()))
  DISPLAY "sync dlg field:",
    name,
    " value:",
    dlgVal.toString(),
    "type:",
    dlgVal.getType().toString(),
    " to record field"
  CALL fieldval.set(dlgVal)
END FUNCTION
