CLASS zcl_supplier_invoice_hc DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
      INTERFACES if_http_service_extension .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_SUPPLIER_INVOICE_HC IMPLEMENTATION.


  METHOD if_http_service_extension~handle_request.

    TRY.

        DATA(req) = request->get_form_fields(  ).
        response->set_header_field( i_name = 'Access-Control-Allow-Origin' i_value = '*' ).
        response->set_header_field( i_name = 'Access-Control-Allow-Credentials' i_value = 'true' ).

        DATA(accountingdocument) = req[ 2 ]-value .
        DATA(fiscalyear) = req[ 3 ]-value .
*         DATA(radiobuttontext) = req[ 4 ]-value .
        DATA(companycode) = req[ 4 ]-value .

        DATA var1 TYPE zchar10.
        var1 = accountingdocument.
        var1 =   |{ |{ var1 ALPHA = OUT }| ALPHA = IN }| .
        accountingdocument = var1.

        SELECT SINGLE accountingdocumenttype FROM i_operationalacctgdocitem WHERE accountingdocument = @accountingdocument
                                           AND companycode = @companycode
                                            AND fiscalyear = @fiscalyear
                                            INTO @DATA(bankvoucher) .


* IF bankvoucher = 'SA'.
          DATA(pdf2) = zcl_supplier_invoice=>read_posts( accountingdocument = accountingdocument  companycode = companycode fiscalyear = fiscalyear ) .
*        ENDIF.
*
        response->set_text( pdf2  ).
      CATCH cx_static_check.


    ENDTRY.

  ENDMETHOD.
ENDCLASS.
