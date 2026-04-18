CLASS zcl_hello_mohammad DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.
ENDCLASS.


CLASS zcl_hello_mohammad IMPLEMENTATION.

  METHOD if_oo_adt_classrun~main.

    TYPES: BEGIN OF ty_emp,
             name   TYPE string,
             dept   TYPE string,
             salary TYPE i,
             light  TYPE string,
           END OF ty_emp.

    DATA: lt_emp TYPE STANDARD TABLE OF ty_emp,
          ls_emp TYPE ty_emp.

    " Sample Data
    ls_emp-name = 'Mohammad'. ls_emp-dept = 'IT'. ls_emp-salary = 60000. APPEND ls_emp TO lt_emp.
    ls_emp-name = 'Rahul'.    ls_emp-dept = 'HR'. ls_emp-salary = 40000. APPEND ls_emp TO lt_emp.
    ls_emp-name = 'Aman'.     ls_emp-dept = 'IT'. ls_emp-salary = 50000. APPEND ls_emp TO lt_emp.
    ls_emp-name = 'Neha'.     ls_emp-dept = 'HR'. ls_emp-salary = 70000. APPEND ls_emp TO lt_emp.

    " Calculate Average Salary
    DATA: lv_sum TYPE i VALUE 0,
          lv_avg TYPE i.

    LOOP AT lt_emp INTO ls_emp.
      lv_sum = lv_sum + ls_emp-salary.
    ENDLOOP.

    lv_avg = lv_sum / lines( lt_emp ).

    " Define thresholds (fix for decimal issue)
    DATA: lv_high TYPE i,
          lv_low  TYPE i.

    lv_high = lv_avg + ( lv_avg / 10 ).   " +10%
    lv_low  = lv_avg - ( lv_avg / 10 ).   " -10%

    " Assign traffic lights
    LOOP AT lt_emp INTO ls_emp.

      IF ls_emp-salary >= lv_high.
        ls_emp-light = 'GREEN'.
      ELSEIF ls_emp-salary >= lv_low.
        ls_emp-light = 'YELLOW'.
      ELSE.
        ls_emp-light = 'RED'.
      ENDIF.

      MODIFY lt_emp FROM ls_emp.

    ENDLOOP.

    " Sort by department and salary descending
    SORT lt_emp BY dept salary DESCENDING.

    " Output
    out->write( '--- Employee Report (ALV Style) ---' ).

    DATA: lv_current_dept TYPE string VALUE '',
          lv_subtotal TYPE i VALUE 0.

    LOOP AT lt_emp INTO ls_emp.

      " Department change → print subtotal
      IF lv_current_dept <> ls_emp-dept AND lv_current_dept <> ''.
        out->write( |Subtotal ({ lv_current_dept }): { lv_subtotal }| ).
        lv_subtotal = 0.
      ENDIF.

      " New department header
      IF lv_current_dept <> ls_emp-dept.
        out->write( '' ).
        out->write( |Department: { ls_emp-dept }| ).
        lv_current_dept = ls_emp-dept.
      ENDIF.

      " Row output
      out->write( |{ ls_emp-light } | && ls_emp-name && | | && ls_emp-salary ).

      lv_subtotal = lv_subtotal + ls_emp-salary.

    ENDLOOP.

    " Final subtotal
    IF lv_current_dept <> ''.
      out->write( |Subtotal ({ lv_current_dept }): { lv_subtotal }| ).
    ENDIF.

  ENDMETHOD.

ENDCLASS.