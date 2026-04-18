CLASS zcl_hello_mohammad DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.
ENDCLASS.


CLASS zcl_hello_mohammad IMPLEMENTATION.

  METHOD if_oo_adt_classrun~main.

    TYPES: BEGIN OF ty_employee,
             name   TYPE string,
             age    TYPE i,
             salary TYPE i,
           END OF ty_employee.

    DATA: lt_employees TYPE STANDARD TABLE OF ty_employee,
          ls_employee  TYPE ty_employee.

    " Employee 1
    ls_employee-name = 'Mohammad'.
    ls_employee-age = 20.
    ls_employee-salary = 50000.
    APPEND ls_employee TO lt_employees.

    " Employee 2
    ls_employee-name = 'Rahul'.
    ls_employee-age = 22.
    ls_employee-salary = 60000.
    APPEND ls_employee TO lt_employees.

    " Employee 3
    ls_employee-name = 'Aman'.
    ls_employee-age = 21.
    ls_employee-salary = 55000.
    APPEND ls_employee TO lt_employees.

    " Output
    out->write( '--- Employee Report ---' ).
    out->write( lt_employees ).

  ENDMETHOD.

ENDCLASS.