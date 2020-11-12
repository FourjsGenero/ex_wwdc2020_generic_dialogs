-- demonstrates how one can encapsulate a single DISPLAY ARRAY dynamic dialog
-- using reflection and multiple interfaces which can be optionally implemented
-- in the application RECORDs
&include "myassert.inc"
IMPORT reflect
IMPORT util
IMPORT FGL utils

PUBLIC CONSTANT BEFORE_DISPLAY = "BEFORE DISPLAY"
PUBLIC CONSTANT BEFORE_ROW = "BEFORE ROW"
PUBLIC CONSTANT AFTER_FIELD = "AFTER FIELD"
PUBLIC CONSTANT AFTER_INPUT = "AFTER INPUT"
PUBLIC CONSTANT ON_ACTION = "ON ACTION"
PUBLIC CONSTANT ON_ACTION_accept = "ON ACTION accept"
PUBLIC CONSTANT ON_ACTION_cancel = "ON ACTION cancel"
--define multiple Interfaces our generic dialog can call
--application RECORDs can define one of those interfaces
PUBLIC TYPE I_BeforeDisplay INTERFACE
  BeforeDisplay(d ui.Dialog)
END INTERFACE

PUBLIC TYPE I_BeforeRow INTERFACE
  BeforeRow(d ui.Dialog, row INT)
END INTERFACE

PUBLIC TYPE I_OnActionInRow INTERFACE
  OnActionInRow(actionEvent STRING, row INT)
END INTERFACE

PUBLIC TYPE I_DialogEvent INTERFACE
  event(d ui.Dialog, event STRING, row INT)
END INTERFACE

PRIVATE TYPE TM_Dialog RECORD
  d ui.Dialog,
  screenRecord STRING,
  screenRecordNames DYNAMIC ARRAY OF STRING,
  fields T_fields
END RECORD

--this is the only function callable from other modules
--hence all RECORD member of TM_Dialog cannot be accessed from other modules
--(data encapsulation)
PUBLIC FUNCTION runDisplayArray(
  delegate reflect.Value, screenRecord STRING, arrVal reflect.Value)
  DEFINE a_dialog TM_Dialog
  CALL a_dialog.displayArray(delegate, screenRecord, arrVal)
END FUNCTION

PRIVATE FUNCTION (self TM_Dialog)
  displayArray(
  delegate reflect.Value, screenRecord STRING, arrVal reflect.Value)
  DEFINE event STRING

  LET self.screenRecord = screenRecord
  CALL self.computeFieldNames(arrVal.getType())
  LET self.d =
    ui.Dialog.createDisplayArrayTo(
      fields: self.fields, screenRecord: screenRecord)
  VAR d = self.d
  CALL d.setArrayLength(name: screenRecord, length: arrVal.getLength())
  CALL self.setArrayData(arrVal)
  CALL d.addTrigger(ON_ACTION_cancel)
  WHILE TRUE -- event loop for dialog self.d
    LET event = d.nextEvent()
    CASE
      WHEN event == BEFORE_DISPLAY
        VAR ifBD I_BeforeDisplay
        --call back the delegate on BEFORE DISPLAY
        IF delegate.canAssignToVariable(ifBD) THEN
          CALL delegate.assignToVariable(ifBD)
          CALL ifBD.BeforeDisplay(d: d)
        END IF
      WHEN event == BEFORE_ROW
        VAR ifBR I_BeforeRow
        --call back the delegate on BEFORE ROW
        IF delegate.canAssignToVariable(ifBR) THEN
          CALL delegate.assignToVariable(ifBR)
          CALL ifBR.BeforeRow(d: d, row: d.getCurrentRow(screenRecord))
        END IF
      WHEN event.getIndexOf(ON_ACTION, 1) == 1
        VAR ifOA I_OnActionInRow
        IF delegate.canAssignToVariable(ifOA) THEN
          CALL delegate.assignToVariable(ifOA)
          CALL ifOA.OnActionInRow(
            actionEvent: event, row: d.getCurrentRow(screenRecord))
        END IF
      OTHERWISE
        VAR ifDE I_DialogEvent
        IF delegate.canAssignToVariable(ifDE) THEN
          CALL delegate.assignToVariable(ifDE)
          CALL ifDE.event(
            d: d, event: event, row: d.getCurrentRow(screenRecord))
        END IF
    END CASE
    IF event == ON_ACTION_cancel THEN
      EXIT WHILE
    END IF
  END WHILE
END FUNCTION

--fill the dialog data by using the reflect values of the array
PRIVATE FUNCTION (self TM_Dialog) setArrayData(arrVal reflect.Value)
  DEFINE i, j INT
  VAR arrayLen = arrVal.getLength()
  VAR scrLen = self.screenRecordNames.getLength()
  FOR i = 1 TO arrayLen
    CALL self.d.setCurrentRow(self.screenRecord, i)
    VAR element reflect.Value
    LET element = arrVal.getArrayElement(i)
    FOR j = 1 TO scrLen
      VAR name = self.screenRecordNames[j]
      VAR fieldval reflect.Value
      LET fieldval = element.getFieldByName(name)
      CALL self.d.setFieldValue(name, fieldval.toString())
    END FOR
  END FOR
  CALL self.d.setCurrentRow(self.screenRecord, 1) --TODO: check array empty
END FUNCTION

PRIVATE FUNCTION (self TM_Dialog) computeFieldNames(arrType reflect.Type)
  DEFINE f42f STRING
  CALL self.fields.clear()
  VAR curr = utils.getCurrentForm()
  VAR name STRING
  LET name = curr.getAttribute("name")
  LET f42f = name || ".42f"
  --do some computations to deduce the field names
  VAR dict DICTIONARY OF STRING
  LET dict =
    utils.readNamesFromScreenRecord(self.screenRecord, f42f, qualified: FALSE)
  VAR names DYNAMIC ARRAY OF STRING
  LET names = dict.getKeys()
  LET self.screenRecordNames = names
  DISPLAY "names:", util.JSON.stringify(names)
  VAR elemType = arrType.getElementType()
  VAR i INT
  FOR i = 1 TO names.getLength()
    LET self.fields[i].name = names[i]
    LET self.fields[i].type = elemType.getFieldTypeByName(names[i]).toString()
  END FOR
  DISPLAY "fields:", util.JSON.stringify(self.fields)
END FUNCTION
