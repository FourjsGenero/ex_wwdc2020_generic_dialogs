# ex_wwdc2020_generic_dialogs

Demonstrates callback techniques using RECORD methods, dynamic Dialogs and Reflection.

Presented by Leo Schubert (Senior software engineer, Four Js) at **WWDC 20 Online**, November 17, 2020.
Talk title: *"Less code with Dynamic Dialogs, Interface Methods and Reflection"*

## Introduction

This project is a variation of the `$FGLDIR/demo/dbbrowser` sample. A combination of
`DISPLAY ARRAY` / `INPUT` / `CONSTRUCT` dynamic dialogs is applied to different tables
(`customers`, `orders`, `items`).

The key difference from the `dbbrowser` sample: application code can register callbacks
for validation and events. Each module using the new dialog code is accompanied by a
classic-dialog equivalent for comparison.

## Motivation

### The problem with classic dialogs

- Classic dialogs are strongly tied to particular data — no generic reuse
- Reusing a classic dialog for different data types requires a code generator
- Difficult to isolate business logic from UI logic
- Custom UI rules in each dialog cause code duplication / boilerplate

Dynamic Dialogs (introduced in Genero 3.10) were created to overcome these limitations.

### Why not use dynamic dialogs "as is"?

Raw dynamic dialogs still have shortcomings:

- Only `setFieldValue()` / `getFieldValue()` for data access — tedious in application code
- Field-name and event registration requires even more boilerplate than classic dialogs
- Events from `nextEvent()` are plain strings — typos are possible
- No built-in callback mechanism; a plain `WHILE` loop is required

### The holy grail

The goal of this PoC is to achieve all of the following:

- Write customizable generic UI dialog code encapsulated in a reusable library
- Use plain 4GL `RECORD` types as data in the dialogs
- Have a type-safe callback mechanism back into application / business logic
- Have compile-time checks for data column names used in dialogs
- Use parsed SQL in application code (library code computes prepared statements)
- Have a fail-safe mechanism comparable to `ON ACTION`

## Features used

| Feature | Since |
|---------|-------|
| Dynamic Dialogs | Genero 3.00 |
| `base.SqlHandle` | Genero 3.00 |
| `INTERFACE` + methods for `RECORD`s | Genero 3.20 |
| Reflection (`reflect` module) | Genero 4.00 |

## Source files

### Classic dialog equivalents (for comparison)

| File | Description |
|------|-------------|
| [classicINPUT.4gl](classicINPUT.4gl) | Classic `INPUT` dialog for a customer record |
| [classicDA.4gl](classicDA.4gl) | Classic `DISPLAY ARRAY` dialog |

### Dynamic INPUT using raw dynamic dialog API

| File | Description |
|------|-------------|
| [dynINPUT.4gl](dynINPUT.4gl) | Raw dynamic `INPUT` — shows the boilerplate without the library |

### Library + application code (INPUT)

| File | Description |
|------|-------------|
| [libINPUT.4gl](libINPUT.4gl) | Generic INPUT library: encapsulates the dynamic dialog, event loop, field sync via reflection |
| [appINPUT.4gl](appINPUT.4gl) | Application code: implements `event()` callback on `TM_Customer` |

### Library + application code (INPUT, enhanced with constants)

| File | Description |
|------|-------------|
| [libI3.4gl](libI3.4gl) | Library with 3-method interface and `CONSTANT` definitions to prevent typos |
| [appI3.4gl](appI3.4gl) | Application code using the 3-method interface (`BeforeInput`, `event`, `AfterField`) |

### Library + application code (INPUT, multiple interfaces)

| File | Description |
|------|-------------|
| [libINPUTIM.4gl](libINPUTIM.4gl) | Library using multiple single-method interfaces, checked at runtime via reflection |
| [appINPUTIM.4gl](appINPUTIM.4gl) | Application code; includes `CheckInterfaces()` for compile-time conformance check |
| [multiple_interfaces.4gl](multiple_interfaces.4gl) | Standalone demo of the multiple-interface dispatch pattern |

### DISPLAY ARRAY

| File | Description |
|------|-------------|
| [libDA.4gl](libDA.4gl) | Generic `DISPLAY ARRAY` library using reflection to introspect and fill array data |
| [appDA.4gl](appDA.4gl) | Application code for the DISPLAY ARRAY demo |

### Reflection demos

| File | Description |
|------|-------------|
| [customer_reflect.4gl](customer_reflect.4gl) | Short intro to the `reflect` module: iterating fields of a `RECORD LIKE customer.*` |
| [test_interface.4gl](test_interface.4gl) | Testing at runtime whether a RECORD implements an INTERFACE via `canAssignToVariable()` |

### SQL + reflection

| File | Description |
|------|-------------|
| [sql2array.4gl](sql2array.4gl) | `readIntoArray()`: uses `base.SqlHandle` + reflection to fill a dynamic array from a SQL query for any RECORD type |

### Utilities / shared

| File | Description |
|------|-------------|
| [interface.4gl](interface.4gl) | Short INTERFACE / RECORD methods recapitulation |
| [utils.4gl](utils.4gl) | Shared utilities (e.g. `dbconnect`) |
| [utils_customer.4gl](utils_customer.4gl) | Customer-specific utilities (e.g. `updateCustomer`) |
| [cols_customer.4gl](cols_customer.4gl) | Column name constants for the customer table |

## Key concepts explained

### 1. Encapsulating the dynamic INPUT in a library (`libINPUT.4gl`)

The library defines an interface that application RECORDs must implement:

```4gl
PUBLIC TYPE I_DynamicINPUT INTERFACE
    event(d ui.Dialog, event STRING)
END INTERFACE
```

The `TM_Input.input()` method:
- Uses reflection on the passed `recVal` to discover field names and types from the current form
- Creates the dynamic dialog via `ui.Dialog.createInputByName()`
- Runs the event loop and calls back `delegate.event()` on each event
- Syncs dialog field values back to the record via `reflect.Value.set()` after each `AFTER FIELD`

### 2. Reflection for field discovery (`computeFieldNamesAndTypes`)

```4gl
VAR formNode = ui.Window.getCurrent().getForm().getNode()
VAR l = formNode.selectByTagName("FormField")
-- for each FormField node: get colName attribute,
-- then look up the type in the record via recType.getFieldTypeByName(name)
```

This means the library needs zero knowledge of the concrete RECORD type.

### 3. Syncing dialog values back to the record (`syncDialogFieldWithRecordField`)

```4gl
VAR dlgVal = reflect.Value.copyOf(self.d.getFieldValue(name))
VAR fieldval = recVal.getFieldByName(name)
CALL fieldval.set(dlgVal)
```

### 4. Preventing typos with `CONSTANT`

```4gl
PUBLIC CONSTANT ON_ACTION_accept = "ON ACTION accept"
PUBLIC CONSTANT AFTER_FIELD      = "AFTER FIELD"
CONSTANT C_zipcode               = "zipcode"
```

Using constants enables code completion and compiler checks instead of raw string literals.

### 5. Multiple optional interfaces via reflection

Rather than forcing every application RECORD to implement every callback method, the library
accepts a `reflect.Value` delegate and tests at runtime:

```4gl
IF delegate.canAssignToVariable(iBI) THEN
    CALL delegate.assignToVariable(iBI)
    CALL iBI.BeforeInput(d)
END IF
```

A never-called `CheckInterfaces()` method on the RECORD provides compile-time verification:

```4gl
FUNCTION (self TM_Cust) CheckInterfaces()
    DEFINE iBI I_BeforeInput
    RETURN
    LET iBI = self  -- compiler checks conformance
END FUNCTION
```

### 6. SQL + reflection (`sql2array.4gl`)

`base.SqlHandle` and reflection work together to populate a typed dynamic array from
an arbitrary SQL query without per-column assignment code:

```4gl
CALL readIntoArray(reflect.Value.valueOf(a), "select * from customer", FALSE)
```

Supports `SELECT`, `INSERT`, and `UPDATE`. Performance is slower than parsed SQL;
keep result sets under ~300 rows.

## Holy grail — achieved?

| Goal | Result |
|------|--------|
| Generic reusable UI dialog library | Yes |
| Use plain 4GL RECORD types as data | Yes |
| Type-safe callback into business logic | Yes |
| Compile-time checks for column names | Partial — requires `CONSTANT` or generated constants |
| Parsed SQL in application code | Yes |
| Fail-safe mechanism like `ON ACTION` | No — adding and checking an action still requires 2 steps |

## Less code?

Comparing classic vs. new approach for this use case, the new code needs roughly **half
the lines** in application code and carries significantly less boilerplate. The pattern
(WHILE loop, CONSTRUCT filter, INPUT/append) is written once in the library and reused
across tables.

The library can additionally handle things that classic dialogs require per-dialog boilerplate for:
- Row count updates in `BEFORE ROW`
- Toolbar state management
- Filter loop (`WHILE` around `DISPLAY ARRAY` + `CONSTRUCT`)
- Global actions without a preprocessor
- `ON FILLBUFFER` and multiple selection
- Adaptive layout: multiple dialog on desktop, cascaded single dialog on mobile

## Links

- Slides / original repository: https://github.com/leopatras/generic_dlg_reflect
- This repository: https://github.com/FourjsGenero/ex_wwdc2020_generic_dialogs
- Dynamic Dialogs docs: http://4js.com/online_documentation/fjs-fgl-manual-html/?path=fjs-fglmanual#fgl-topics/c_fgl_dynamic_dialogs.html
- Ask Reuben ig-24 (Dynamic Dialogs): https://4js.com/ask-reuben/ig-24/
- base.SqlHandle docs: http://4js.com/online_documentation/fjs-fgl-manual-html/?path=fjs-fglmanual#fgl-topics/c_fgl_ClassSqlHandle_create.html
- Ask Reuben ig-25 (SqlHandle): https://4js.com/ask-reuben/ig-25/
- INTERFACE docs: http://4js.com/online_documentation/fjs-fgl-manual-html/?path=fjs-fglmanual#fgl-topics/c_fgl_Interface.html
