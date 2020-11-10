&include "myassert.inc"
IMPORT reflect
IMPORT util
IMPORT FGL utils
--define an Interface our generic dialog can call
--application RECORDs must define this interface
PUBLIC TYPE I_DynamicDialog INTERFACE
  init(d ui.Dialog),
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
  delegate I_DynamicDialog, screenRecord STRING, arrVal reflect.Value)
  DEFINE a_dialog TM_Dialog
  CALL a_dialog.displayArray(delegate, screenRecord, arrVal)
END FUNCTION

PRIVATE FUNCTION (self TM_Dialog)
  displayArray(
  delegate I_DynamicDialog, screenRecord STRING, arrVal reflect.Value)
  DEFINE event STRING
  LET self.screenRecord = screenRecord
  CALL self.computeFieldNames(arrVal.getType())
  LET self.d =
    ui.Dialog.createDisplayArrayTo(
      fields: self.fields, screenRecord: screenRecord)
  CALL self.d.setArrayLength(name: screenRecord, length: arrVal.getLength())
  CALL self.setArrayData(arrVal)
  CALL self.d.addTrigger("ON ACTION cancel")
  --call the init function to allow the delegate adding actions,triggers
  CALL delegate.init(self.d)
  WHILE TRUE -- event loop for dialog self.d
    LET event = self.d.nextEvent()
    --call back the delegate on each event
    CALL delegate.event(self.d, event, self.d.getCurrentRow(screenRecord))
    IF event = "ON ACTION cancel" THEN
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
