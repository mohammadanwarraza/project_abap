*&---------------------------------------------------------------------*
*& Program     : ZHR_EMPLOYEE_ALV_REPORT
*& Title       : Employee Master Data ALV Report
*& Description : Custom ALV Report for Employee Master Data Analysis
*&               Displays employee details with department-wise filtering
*&               Includes salary analysis and headcount statistics
*& Author      : [Your Name]
*& Date        : April 2026
*& SAP Version : SAP ECC 6.0 / S/4HANA
*&---------------------------------------------------------------------*
*& TABLES USED:
*&   PA0001 - HR Master Record: Infotype 0001 (Org. Assignment)
*&   PA0002 - HR Master Record: Infotype 0002 (Personal Data)
*&   PA0008 - HR Master Record: Infotype 0008 (Basic Pay)
*&---------------------------------------------------------------------*

REPORT ZHR_EMPLOYEE_ALV_REPORT
  LINE-SIZE 255
  MESSAGE-ID ZHR_MESSAGES.

*--------------------------------------------------------------------*
* TYPE POOL
*--------------------------------------------------------------------*
TYPE-POOLS: SLIS.

*--------------------------------------------------------------------*
* TABLES DECLARATION
*--------------------------------------------------------------------*
TABLES: PA0001,   " Org Assignment
        PA0002,   " Personal Data
        PA0008.   " Basic Pay

*--------------------------------------------------------------------*
* INTERNAL TABLE AND WORK AREA: OUTPUT STRUCTURE
*--------------------------------------------------------------------*
TYPES: BEGIN OF TY_EMP_DATA,
  PERNR   TYPE PA0001-PERNR,    " Personnel Number
  ENAME   TYPE STRING,          " Employee Full Name
  VORNA   TYPE PA0002-VORNA,    " First Name
  NACHN   TYPE PA0002-NACHN,    " Last Name
  GBDAT   TYPE PA0002-GBDAT,    " Date of Birth
  GESCH   TYPE PA0002-GESCH,    " Gender
  WERKS   TYPE PA0001-WERKS,    " Personnel Area (Plant)
  BTRTL   TYPE PA0001-BTRTL,    " Personnel Subarea
  ORGEH   TYPE PA0001-ORGEH,    " Organizational Unit
  PLANS   TYPE PA0001-PLANS,    " Position
  STELL   TYPE PA0001-STELL,    " Job
  BEGDA   TYPE PA0001-BEGDA,    " Start Date (Joining Date)
  ANSAL   TYPE PA0008-ANSAL,    " Annual Salary
  WAERS   TYPE PA0008-WAERS,    " Currency
  TRFGR   TYPE PA0008-TRFGR,    " Pay Scale Group
  LIGHT   TYPE C,               " Traffic Light Icon
END OF TY_EMP_DATA.

DATA: GT_EMP_DATA   TYPE STANDARD TABLE OF TY_EMP_DATA,
      GS_EMP_DATA   TYPE TY_EMP_DATA.

*--------------------------------------------------------------------*
* INTERNAL TABLES: FETCH FROM DB
*--------------------------------------------------------------------*
DATA: BEGIN OF GS_PA0001,
        PERNR TYPE PA0001-PERNR,
        WERKS TYPE PA0001-WERKS,
        BTRTL TYPE PA0001-BTRTL,
        ORGEH TYPE PA0001-ORGEH,
        PLANS TYPE PA0001-PLANS,
        STELL TYPE PA0001-STELL,
        BEGDA TYPE PA0001-BEGDA,
      END OF GS_PA0001,
      GT_PA0001 LIKE STANDARD TABLE OF GS_PA0001.

DATA: BEGIN OF GS_PA0002,
        PERNR TYPE PA0002-PERNR,
        VORNA TYPE PA0002-VORNA,
        NACHN TYPE PA0002-NACHN,
        GBDAT TYPE PA0002-GBDAT,
        GESCH TYPE PA0002-GESCH,
      END OF GS_PA0002,
      GT_PA0002 LIKE STANDARD TABLE OF GS_PA0002.

DATA: BEGIN OF GS_PA0008,
        PERNR TYPE PA0008-PERNR,
        ANSAL TYPE PA0008-ANSAL,
        WAERS TYPE PA0008-WAERS,
        TRFGR TYPE PA0008-TRFGR,
      END OF GS_PA0008,
      GT_PA0008 LIKE STANDARD TABLE OF GS_PA0008.

*--------------------------------------------------------------------*
* ALV VARIABLES
*--------------------------------------------------------------------*
DATA: GT_FIELDCAT   TYPE SLIS_T_FIELDCAT_ALV,
      GS_FIELDCAT   TYPE SLIS_FIELDCAT_ALV,
      GT_SORT       TYPE SLIS_T_SORTINFO_ALV,
      GS_SORT       TYPE SLIS_SORTINFO_ALV,
      GS_LAYOUT     TYPE SLIS_LAYOUT_ALV,
      GS_VARIANT    TYPE DISVARIANT,
      GS_EVENT      TYPE SLIS_ALV_EVENT,
      GT_EVENTS     TYPE SLIS_T_EVENT,
      GT_HEADING    TYPE SLIS_T_LISTHEADER,
      GS_HEADING    TYPE SLIS_LISTHEADER.

*--------------------------------------------------------------------*
* GLOBAL VARIABLES
*--------------------------------------------------------------------*
DATA: GV_REPID      TYPE SY-REPID,
      GV_TITLE      TYPE LVC_TITLE,
      GV_COUNT      TYPE I.

*--------------------------------------------------------------------*
* SELECTION SCREEN
*--------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK B1 WITH FRAME TITLE TEXT-001.

  SELECT-OPTIONS: S_PERNR FOR PA0001-PERNR MATCHCODE OBJECT PERNR,
                  S_WERKS FOR PA0001-WERKS MATCHCODE OBJECT H_T500P,
                  S_ORGEH FOR PA0001-ORGEH,
                  S_BEGDA FOR PA0001-BEGDA.

SELECTION-SCREEN END OF BLOCK B1.

SELECTION-SCREEN BEGIN OF BLOCK B2 WITH FRAME TITLE TEXT-002.
  PARAMETERS: P_TOP    TYPE I DEFAULT 10 OBLIGATORY,   " Top N Earners
              P_VAR    TYPE DISVARIANT-VARIANT.          " ALV Variant
SELECTION-SCREEN END OF BLOCK B2.

*--------------------------------------------------------------------*
* INITIALIZATION
*--------------------------------------------------------------------*
INITIALIZATION.
  GV_REPID = SY-REPID.
  " Default date range: current year
  S_BEGDA-LOW  = |{ SY-DATUM(4) }0101|.
  S_BEGDA-HIGH = SY-DATUM.
  APPEND S_BEGDA.

*--------------------------------------------------------------------*
* AT SELECTION SCREEN
*--------------------------------------------------------------------*
AT SELECTION-SCREEN.
  PERFORM VALIDATE_SELECTION.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR P_VAR.
  GS_VARIANT-REPORT = GV_REPID.
  CALL FUNCTION 'REUSE_ALV_VARIANT_F4'
    EXPORTING
      IS_VARIANT = GS_VARIANT
    IMPORTING
      ES_VARIANT = GS_VARIANT
    EXCEPTIONS
      OTHERS     = 2.
  IF SY-SUBRC = 0.
    P_VAR = GS_VARIANT-VARIANT.
  ENDIF.

*--------------------------------------------------------------------*
* START-OF-SELECTION
*--------------------------------------------------------------------*
START-OF-SELECTION.
  PERFORM FETCH_DATA.
  PERFORM PROCESS_DATA.

END-OF-SELECTION.
  IF GT_EMP_DATA IS INITIAL.
    MESSAGE S001(ZHR_MESSAGES) DISPLAY LIKE 'W'.
    " No records found for the given selection criteria
    LEAVE LIST-PROCESSING.
  ENDIF.
  PERFORM BUILD_FIELDCATALOG.
  PERFORM BUILD_LAYOUT.
  PERFORM BUILD_SORT.
  PERFORM BUILD_EVENTS.
  PERFORM DISPLAY_ALV.

*&---------------------------------------------------------------------*
*&  FORM VALIDATE_SELECTION
*&---------------------------------------------------------------------*
FORM VALIDATE_SELECTION.
  " Validate Top N Earners input
  IF P_TOP <= 0.
    MESSAGE E002(ZHR_MESSAGES).
    " 'Top N Earners must be greater than zero'
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*&  FORM FETCH_DATA
*&---------------------------------------------------------------------*
FORM FETCH_DATA.
  " Fetch Org Assignment data (Infotype 0001)
  SELECT PERNR WERKS BTRTL ORGEH PLANS STELL BEGDA
    FROM PA0001
    INTO TABLE GT_PA0001
    WHERE PERNR IN S_PERNR
      AND WERKS IN S_WERKS
      AND ORGEH IN S_ORGEH
      AND BEGDA IN S_BEGDA
      AND ENDDA >= SY-DATUM     " Only active records
      AND BEGDA <= SY-DATUM.

  IF GT_PA0001 IS INITIAL.
    RETURN.
  ENDIF.

  " Collect personnel numbers for further reads
  DATA: LT_PERNR TYPE RANGE OF PA0001-PERNR,
        LS_PERNR LIKE LINE OF LT_PERNR.

  LOOP AT GT_PA0001 INTO GS_PA0001.
    LS_PERNR-SIGN   = 'I'.
    LS_PERNR-OPTION = 'EQ'.
    LS_PERNR-LOW    = GS_PA0001-PERNR.
    APPEND LS_PERNR TO LT_PERNR.
  ENDLOOP.

  " Fetch Personal Data (Infotype 0002)
  SELECT PERNR VORNA NACHN GBDAT GESCH
    FROM PA0002
    INTO TABLE GT_PA0002
    WHERE PERNR IN LT_PERNR
      AND ENDDA >= SY-DATUM
      AND BEGDA <= SY-DATUM.

  " Fetch Basic Pay (Infotype 0008)
  SELECT PERNR ANSAL WAERS TRFGR
    FROM PA0008
    INTO TABLE GT_PA0008
    WHERE PERNR IN LT_PERNR
      AND ENDDA >= SY-DATUM
      AND BEGDA <= SY-DATUM.

ENDFORM.

*&---------------------------------------------------------------------*
*&  FORM PROCESS_DATA
*&---------------------------------------------------------------------*
FORM PROCESS_DATA.
  DATA: LS_PA0002 LIKE LINE OF GT_PA0002,
        LS_PA0008 LIKE LINE OF GT_PA0008,
        LV_SALARY TYPE PA0008-ANSAL.

  " Average salary for traffic light logic
  DATA: LV_AVG_SAL TYPE PA0008-ANSAL,
        LV_SUM_SAL TYPE P DECIMALS 2,
        LV_COUNT   TYPE I.

  LOOP AT GT_PA0008 INTO LS_PA0008.
    LV_SUM_SAL = LV_SUM_SAL + LS_PA0008-ANSAL.
    LV_COUNT   = LV_COUNT + 1.
  ENDLOOP.
  IF LV_COUNT > 0.
    LV_AVG_SAL = LV_SUM_SAL / LV_COUNT.
  ENDIF.

  " Build output table
  LOOP AT GT_PA0001 INTO GS_PA0001.
    CLEAR GS_EMP_DATA.

    GS_EMP_DATA-PERNR = GS_PA0001-PERNR.
    GS_EMP_DATA-WERKS = GS_PA0001-WERKS.
    GS_EMP_DATA-BTRTL = GS_PA0001-BTRTL.
    GS_EMP_DATA-ORGEH = GS_PA0001-ORGEH.
    GS_EMP_DATA-PLANS = GS_PA0001-PLANS.
    GS_EMP_DATA-STELL = GS_PA0001-STELL.
    GS_EMP_DATA-BEGDA = GS_PA0001-BEGDA.

    " Read personal data
    READ TABLE GT_PA0002 INTO LS_PA0002
      WITH KEY PERNR = GS_PA0001-PERNR.
    IF SY-SUBRC = 0.
      GS_EMP_DATA-VORNA = LS_PA0002-VORNA.
      GS_EMP_DATA-NACHN = LS_PA0002-NACHN.
      GS_EMP_DATA-GBDAT = LS_PA0002-GBDAT.
      GS_EMP_DATA-GESCH = LS_PA0002-GESCH.
      CONCATENATE LS_PA0002-VORNA LS_PA0002-NACHN
        INTO GS_EMP_DATA-ENAME SEPARATED BY SPACE.
    ENDIF.

    " Read basic pay
    READ TABLE GT_PA0008 INTO LS_PA0008
      WITH KEY PERNR = GS_PA0001-PERNR.
    IF SY-SUBRC = 0.
      GS_EMP_DATA-ANSAL = LS_PA0008-ANSAL.
      GS_EMP_DATA-WAERS = LS_PA0008-WAERS.
      GS_EMP_DATA-TRFGR = LS_PA0008-TRFGR.
      LV_SALARY          = LS_PA0008-ANSAL.
    ELSE.
      LV_SALARY = 0.
    ENDIF.

    " Traffic Light: Green=above avg, Yellow=at avg±10%, Red=below avg
    IF LV_AVG_SAL > 0.
      IF LV_SALARY >= LV_AVG_SAL * '1.1'.
        GS_EMP_DATA-LIGHT = '1'.   " Green
      ELSEIF LV_SALARY >= LV_AVG_SAL * '0.9'.
        GS_EMP_DATA-LIGHT = '2'.   " Yellow
      ELSE.
        GS_EMP_DATA-LIGHT = '3'.   " Red
      ENDIF.
    ENDIF.

    APPEND GS_EMP_DATA TO GT_EMP_DATA.
  ENDLOOP.

  " Sort by salary descending
  SORT GT_EMP_DATA BY ANSAL DESCENDING.

ENDFORM.

*&---------------------------------------------------------------------*
*&  FORM BUILD_FIELDCATALOG
*&---------------------------------------------------------------------*
FORM BUILD_FIELDCATALOG.
  DEFINE ADD_FIELD.
    CLEAR GS_FIELDCAT.
    GS_FIELDCAT-FIELDNAME   = &1.
    GS_FIELDCAT-SELTEXT_M   = &2.
    GS_FIELDCAT-COL_POS     = &3.
    GS_FIELDCAT-OUTPUTLEN   = &4.
    GS_FIELDCAT-JUST        = &5.
    GS_FIELDCAT-TABNAME     = 'GT_EMP_DATA'.
    APPEND GS_FIELDCAT TO GT_FIELDCAT.
  END-OF-DEFINITION.

  "          Field        Label                  Pos  Len  Just
  ADD_FIELD 'LIGHT'      'Status'                1    3    'C'.
  ADD_FIELD 'PERNR'      'Pers.No.'              2    8    'R'.
  ADD_FIELD 'ENAME'      'Employee Name'          3    35   'L'.
  ADD_FIELD 'GBDAT'      'Date of Birth'          4    10   'C'.
  ADD_FIELD 'GESCH'      'Gender'                 5    6    'C'.
  ADD_FIELD 'WERKS'      'Pers.Area'              6    8    'L'.
  ADD_FIELD 'BTRTL'      'Sub-Area'               7    8    'L'.
  ADD_FIELD 'ORGEH'      'Org.Unit'               8    10   'L'.
  ADD_FIELD 'PLANS'      'Position'               9    10   'L'.
  ADD_FIELD 'STELL'      'Job'                   10    10   'L'.
  ADD_FIELD 'BEGDA'      'Joining Date'          11    10   'C'.
  ADD_FIELD 'TRFGR'      'Pay Grade'             12    8    'C'.
  ADD_FIELD 'ANSAL'      'Annual Salary'         13    15   'R'.
  ADD_FIELD 'WAERS'      'Currency'              14    5    'L'.

  " Specific properties for certain fields
  LOOP AT GT_FIELDCAT INTO GS_FIELDCAT.
    CASE GS_FIELDCAT-FIELDNAME.
      WHEN 'LIGHT'.
        GS_FIELDCAT-ICON = 'X'.
      WHEN 'ANSAL'.
        GS_FIELDCAT-DO_SUM  = 'X'.
        GS_FIELDCAT-DATATYPE = 'CURR'.
      WHEN 'PERNR'.
        GS_FIELDCAT-KEY = 'X'.   " Key column - always visible
    ENDCASE.
    MODIFY GT_FIELDCAT FROM GS_FIELDCAT.
  ENDLOOP.

ENDFORM.

*&---------------------------------------------------------------------*
*&  FORM BUILD_LAYOUT
*&---------------------------------------------------------------------*
FORM BUILD_LAYOUT.
  GS_LAYOUT-ZEBRA           = 'X'.   " Alternating row colors
  GS_LAYOUT-COLWIDTH_OPTIMIZE = 'X'. " Auto-optimize column widths
  GS_LAYOUT-SEL_MODE        = 'D'.   " Multiple row selection
  GS_LAYOUT-TOTALS_TEXT     = 'Total Annual Salary'.
  GS_LAYOUT-TOTALS_BEFORE_ITEMS = ' '.

  " Variant
  GS_VARIANT-REPORT   = GV_REPID.
  GS_VARIANT-VARIANT  = P_VAR.
ENDFORM.

*&---------------------------------------------------------------------*
*&  FORM BUILD_SORT
*&---------------------------------------------------------------------*
FORM BUILD_SORT.
  CLEAR GS_SORT.
  GS_SORT-FIELDNAME = 'ORGEH'.
  GS_SORT-SPOS      = 1.
  GS_SORT-UP        = 'X'.
  GS_SORT-SUBTOT    = 'X'.    " Subtotals by Org Unit
  APPEND GS_SORT TO GT_SORT.

  CLEAR GS_SORT.
  GS_SORT-FIELDNAME = 'ANSAL'.
  GS_SORT-SPOS      = 2.
  GS_SORT-DOWN      = 'X'.   " Highest salary first within org unit
  APPEND GS_SORT TO GT_SORT.
ENDFORM.

*&---------------------------------------------------------------------*
*&  FORM BUILD_EVENTS
*&---------------------------------------------------------------------*
FORM BUILD_EVENTS.
  " Top-of-page event
  CLEAR GS_EVENT.
  GS_EVENT-NAME    = SLIS_EV_TOP_OF_PAGE.
  GS_EVENT-FORM    = 'ALV_TOP_OF_PAGE'.
  APPEND GS_EVENT TO GT_EVENTS.

  " User command event (for custom toolbar buttons)
  CLEAR GS_EVENT.
  GS_EVENT-NAME    = SLIS_EV_USER_COMMAND.
  GS_EVENT-FORM    = 'ALV_USER_COMMAND'.
  APPEND GS_EVENT TO GT_EVENTS.
ENDFORM.

*&---------------------------------------------------------------------*
*&  FORM DISPLAY_ALV
*&---------------------------------------------------------------------*
FORM DISPLAY_ALV.
  GV_TITLE = 'Employee Master Data Report | KIIT SAP Capstone'.

  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
      I_CALLBACK_PROGRAM      = GV_REPID
      I_CALLBACK_USER_COMMAND = 'ALV_USER_COMMAND'
      I_CALLBACK_TOP_OF_PAGE  = 'ALV_TOP_OF_PAGE'
      I_GRID_TITLE            = GV_TITLE
      IS_LAYOUT               = GS_LAYOUT
      IT_FIELDCAT             = GT_FIELDCAT
      IT_SORT                 = GT_SORT
      IT_EVENTS               = GT_EVENTS
      IS_VARIANT              = GS_VARIANT
      I_SAVE                  = 'A'
    TABLES
      T_OUTTAB                = GT_EMP_DATA
    EXCEPTIONS
      PROGRAM_ERROR           = 1
      OTHERS                  = 2.

  IF SY-SUBRC <> 0.
    MESSAGE E003(ZHR_MESSAGES).
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*&  FORM ALV_TOP_OF_PAGE
*&---------------------------------------------------------------------*
FORM ALV_TOP_OF_PAGE.
  CLEAR GT_HEADING.

  " Header line 1 — Report title
  GS_HEADING-TYP  = 'H'.
  GS_HEADING-INFO = 'Employee Master Data Report'.
  APPEND GS_HEADING TO GT_HEADING.

  " Header line 2 — Selection info
  GS_HEADING-TYP  = 'S'.
  GS_HEADING-KEY  = 'Personnel Area:'.
  GS_HEADING-INFO = S_WERKS-LOW.
  APPEND GS_HEADING TO GT_HEADING.

  GS_HEADING-TYP  = 'S'.
  GS_HEADING-KEY  = 'Run Date:'.
  WRITE SY-DATUM TO GS_HEADING-INFO DD/MM/YYYY.
  APPEND GS_HEADING TO GT_HEADING.

  " Header line 3 — Record count
  GS_HEADING-TYP  = 'A'.
  DESCRIBE TABLE GT_EMP_DATA LINES GV_COUNT.
  WRITE GV_COUNT TO GS_HEADING-INFO LEFT-JUSTIFIED.
  CONCATENATE GS_HEADING-INFO ' Employee Record(s) Found'
    INTO GS_HEADING-INFO.
  APPEND GS_HEADING TO GT_HEADING.

  CALL FUNCTION 'REUSE_ALV_COMMENTARY_WRITE'
    EXPORTING
      IT_LIST_COMMENTARY = GT_HEADING.
ENDFORM.

*&---------------------------------------------------------------------*
*&  FORM ALV_USER_COMMAND  — Custom toolbar actions
*&---------------------------------------------------------------------*
FORM ALV_USER_COMMAND USING P_UCOMM    TYPE SY-UCOMM
                            P_SELFIELD TYPE SLIS_SELFIELD.
  CASE P_UCOMM.
    WHEN 'DETAIL'.
      " Drill-down: call HR transaction for selected employee
      DATA: LS_SELECTED TYPE TY_EMP_DATA.
      READ TABLE GT_EMP_DATA INDEX P_SELFIELD-TABINDEX
        INTO LS_SELECTED.
      IF SY-SUBRC = 0.
        SET PARAMETER ID 'PER' FIELD LS_SELECTED-PERNR.
        CALL TRANSACTION 'PA20' AND SKIP FIRST SCREEN.
      ENDIF.

    WHEN 'TOPN'.
      " Show only Top N earners
      DATA: LT_TOPN TYPE STANDARD TABLE OF TY_EMP_DATA.
      SORT GT_EMP_DATA BY ANSAL DESCENDING.
      LT_TOPN = GT_EMP_DATA.
      DELETE LT_TOPN FROM P_TOP + 1.
      GT_EMP_DATA = LT_TOPN.
      P_SELFIELD-REFRESH = 'X'.

    WHEN 'RESET'.
      " Re-fetch data
      PERFORM FETCH_DATA.
      PERFORM PROCESS_DATA.
      P_SELFIELD-REFRESH = 'X'.
  ENDCASE.
ENDFORM.
