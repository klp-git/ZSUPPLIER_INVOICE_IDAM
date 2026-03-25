CLASS zcl_supplier_invoice DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun .
    CLASS-DATA : access_token TYPE string .
    CLASS-DATA : xml_file TYPE string .
    CLASS-DATA : template TYPE string .
    CLASS-DATA : tot_sum  TYPE string.

    TYPES : BEGIN OF struct,
              xdp_template TYPE string,
              xml_data     TYPE string,
              form_type    TYPE string,
              form_locale  TYPE string,
              tagged_pdf   TYPE string,
              embed_font   TYPE string,
            END OF struct."






    CLASS-METHODS :
      create_client
        IMPORTING url           TYPE string
        RETURNING VALUE(result) TYPE REF TO if_web_http_client
        RAISING
                  cx_no_check
                  cx_http_dest_provider_error
                  cx_web_http_client_error
                  cx_static_check ,

      read_posts
        IMPORTING
                  VALUE(accountingdocument) TYPE string
                  VALUE(fiscalyear)         TYPE string
                  VALUE(companycode)        TYPE string

        RETURNING VALUE(result12)           TYPE string
        RAISING   cx_static_check.



  PROTECTED SECTION.
  PRIVATE SECTION.

    CONSTANTS lc_ads_render TYPE string VALUE '/ads.restapi/v1/adsRender/pdf'.
    CONSTANTS  lv1_url    TYPE string VALUE 'https://adsrestapi-formsprocessing.cfapps.eu10.hana.ondemand.com/v1/adsRender/pdf?templateSource=storageName&TraceLevel=2'  .
    CONSTANTS  lv2_url    TYPE string VALUE 'https://dev-jgwfc0h2.authentication.eu10.hana.ondemand.com/oauth/token'  .
    CONSTANTS lc_storage_name TYPE string VALUE 'templateSource=storageName'.
    CONSTANTS  lc_template_name TYPE string VALUE 'ZFI_SUPPLIER_INVOICE/ZFI_SUPPLIER_INVOICE'.

ENDCLASS.



CLASS ZCL_SUPPLIER_INVOICE IMPLEMENTATION.


  METHOD create_client .
    DATA(dest) = cl_http_destination_provider=>create_by_url( url ).
    result = cl_web_http_client_manager=>create_by_http_destination( dest ).
  ENDMETHOD .


  METHOD if_oo_adt_classrun~main.
    TRY.
    ENDTRY.
  ENDMETHOD.


  METHOD read_posts .

              TYPES : BEGIN OF ty_data,
              lv_index       TYPE string,
              DESC     TYPE string,
              hsn            TYPE char10,
              basic_val       TYPE p LENGTH 13 DECIMALS 2,
              cgst_rate      TYPE p  LENGTH 13 DECIMALS 2,
              csgt_amt       TYPE p LENGTH 13 DECIMALS 2,
              sgst_rate      TYPE p LENGTH 13 DECIMALS 2,
              sgst_amt       TYPE p LENGTH 13 DECIMALS 2,
              igst_rate      TYPE p LENGTH 13 DECIMALS 2,
              igst_amt       TYPE p LENGTH 13 DECIMALS 2,
              total          TYPE p LENGTH 13 DECIMALS 2,
            END OF ty_data.



    DATA: gt_data  TYPE TABLE OF ty_data,
          gs_data  TYPE ty_data.

    DATA: lv_date TYPE d,
          lv_char TYPE string.
    DATA: lvn    TYPE string,
          lv_xml TYPE string,
          lv_vs3 TYPE string.



    DATA alpha TYPE char10 .
    alpha = |{ accountingdocument ALPHA = IN }| .
    accountingdocument = alpha .


    SELECT SINGLE * FROM zcompany WHERE companycode = @companycode INTO @DATA(gs_company).
    IF gs_company-companycode = 'I100'.
      DATA(lv_comname) = 'IDAM NATURAL WELLNESS PVT LTD'.
    ELSE.
      lv_comname = gs_company-companycodename.
    ENDIF.

     SELECT SINGLE * FROM I_JournalEntry WHERE companycode = @companycode
                                                AND accountingdocument = @accountingdocument
                                                AND fiscalyear = @fiscalyear INTO @DATA(JournalEntry).



     SELECT SINGLE * FROM i_operationalacctgdocitem  WHERE companycode = @companycode
                                                AND accountingdocument = @accountingdocument
                                                AND FinancialAccountType = 'K'
                                                AND fiscalyear = @fiscalyear INTO @DATA(billto).

   SELECT SINGLE * FROM I_IN_BUSINESSPLACETAXDETAIL WHERE companycode = @companycode
                                                    AND   BusinessPlace = @billto-BusinessPlace INTO @DATA(GSTIN).

    SELECT SINGLE * FROM I_Businesspartnertaxnumber WITH PRIVILEGED ACCESS WHERE BusinessPartner = @billto-Supplier AND BPTaxType = 'IN3' INTO @DATA(SUP_GSTIN).
*    SELECT SINGLE * FROM I_SUPPLIER WITH PRIVILEGED ACCESS WHERE SUPPLIER  = @billto-Supplier INTO @DATA(SUPP).
    SELECT SINGLE * FROM ZVENDOR WITH PRIVILEGED ACCESS WHERE Supplier = @billto-Supplier INTO @DATA(SHIP).


       DATA:SHIP_TO TYPE string.




    IF  SHIP-streetname IS NOT INITIAL.
      CONCATENATE SHIP-streetname '' INTO SHIP_TO.
    ENDIF.

    IF SHIP-streetname  IS NOT INITIAL.
        CONCATENATE SHIP-streetname '' INTO SHIP_TO.
    ENDIF.

*    IF SHIP_TO-Street IS NOT INITIAL.
*      CONCATENATE SHIP_TO-Street  INTO bto SEPARATED BY ','.
*    ENDIF.
*    IF billtoadd1-streetsuffixname1 IS NOT INITIAL.
*      CONCATENATE bto billtoadd1-streetsuffixname1 INTO bto SEPARATED BY ','.
*    ENDIF.
*    IF billtoadd1-streetsuffixname2 IS NOT INITIAL.
*      CONCATENATE bto billtoadd1-streetsuffixname2 INTO bto SEPARATED BY ','.
*    ENDIF.
*
*    DATA bill_to_city_pin TYPE string.
*    CONCATENATE billtoadd1-CityName billtoadd1-postalcode ',' billtoadd1-country INTO bill_to_city_pin SEPARATED BY space.





 .

    DATA(lv_xml1) =

    |<form1>| &&
    |<Subform1>| &&
    |<QRCodeBarcode1/>| &&
    |<posting_date>{ JournalEntry-PostingDate }</posting_date>| &&
    |<CompanyName>{ lv_comname }</CompanyName>| &&
    |<Comcode>{ gs_company-companycode }</Comcode>| .

    IF gs_company-companycode = 'I100'.
      DATA(lv_logo) = |<I100></I100>|.
    ELSEIF gs_company-companycode = 'I200'.
      lv_logo = |<I200></I200> | .
    ELSEIF gs_company-companycode = 'I300'.
      lv_logo = |<I300></I300> | .
    ELSEIF gs_company-companycode = 'I500'.
      lv_logo = |<I500></I500> | .
    ENDIF.

    DATA(lv_xml2) =
    |<GST_NO>{ GSTIN-IN_GSTIDENTIFICATIONNUMBER }</GST_NO>| &&
    |<CIN_NO>U52100MH2019PTC404779</CIN_NO>| &&
    |<PAN_NO> AAFCI1834E</PAN_NO>| &&
    |<org></org>| &&
    |<CompanyAddress>One International Centre,Unit No. 2401, 24th Floor, Tower 2, Plot no. 612 and 613,Senapati Bapat Marg, Near Kamgar Stadium,Elephinstone, Delisle ,Road,Maharashtra,400013,MUMBAI</CompanyAddress>| &&
    |<com_name>ADDRESS :</com_name>| &&
    |<Company_GST_TaxInvNumber></Company_GST_TaxInvNumber>| &&
    |<BCode></BCode>| &&

    |<BAddress>{ SHIP-OrganizationName1 }{ SHIP-OrganizationName2 }</BAddress>| &&
    |<BLegalName>{ SHIP-StreetName }</BLegalName>| &&
    |<BGSTIN>{ SHIP-gstin_no }</BGSTIN>| &&
    |<BAddress>{ SHIP-StreetName  }</BAddress>| &&
    |<BCity>{ ship-CityName }</BCity>| &&
    |<BStateCode>{ ship-RegionName  }</BStateCode>| &&
    |<BDist>{ ship-PostalCode  }</BDist>| &&
    |<BFSSA_IPAN></BFSSA_IPAN>| &&

    |<SCode>Vale</SCode>| &&
    |<SName>{ SHIP-OrganizationName1 }{ SHIP-OrganizationName2 }</SName>| &&
    |<SLegalName>{ SHIP-StreetName }</SLegalName>| &&
    |<SGSTIN>{   SHIP-gstin_no }</SGSTIN>| &&
    |<SAddress>{ ship-StreetName  }</SAddress>| &&
    |<SCity>{ ship-CityName  }</SCity>| &&
    |<SStateCode>{ ship-RegionName }</SStateCode>| &&
    |<SDist>{ ship-PostalCode  }</SDist>| &&
    |<Place_supp>{ billto-IN_GSTPlaceOfSupply }</Place_supp>| &&
    |<mob_no> </mob_no>| &&
    |<email> </email>| &&
    |<Credit_no>{ JournalEntry-AccountingDocument }</Credit_no>| &&
    |<Credit_date>{ JournalEntry-DocumentDate }</Credit_date>| &&
    |<Order_date>{ JournalEntry-DocumentDate }</Order_date>| &&
    |<Order_no>{ JournalEntry-OriginalReferenceDocument  }</Order_no>| &&
    |<BillOfSuppNo>{ JournalEntry-DocumentReferenceID }</BillOfSuppNo>| &&
    |<BillOfSuppDate>{ JournalEntry-DocumentDate  }</BillOfSuppDate>| &&
    |<FSSAI_No>Ad retia sedebam</FSSAI_No>| &&
    |<Subform2>| &&
    |<Table1>| &&
    |<HeaderRow1/>| &&
    |<HeaderRow2/>| .

    SELECT * FROM i_operationalacctgdocitem  AS a
    LEFT OUTER JOIN i_glaccounttextrawdata AS b ON  b~glaccount = a~glaccount
                                                    AND  b~language = 'E'
                                                WHERE companycode = @companycode
                                                AND accountingdocument = @accountingdocument
                                                AND fiscalyear = @fiscalyear
*                                                AND costcenter <> ' '
                                                AND profitcenter <> ' ' INTO TABLE @DATA(lt_data).

    SELECT * FROM i_operationalacctgdocitem AS A
    LEFT OUTER JOIN I_TAXCODERATE AS B ON B~TaxCode = A~TaxCode
                                       AND B~AccountKeyForGLAccount = A~TransactionTypeDetermination
                                       AND B~Country = 'IN'
                                                WHERE companycode = @companycode
                                                AND accountingdocument = @accountingdocument
                                                AND fiscalyear = @fiscalyear
                                                AND transactiontypedetermination IN ('JIC' , 'JIS','JII', 'JIU' ) INTO TABLE @DATA(taxamt).




  DATA: lv_index TYPE sy-tabix.

DATA:  LV_COUNT TYPE STRING,
      TOTAL TYPE DMBTR.

LOOP AT lt_data INTO DATA(ls_data).
 gs_data-desc = ls_data-b-glaccountname.
 gs_data-hsn =  LS_DATA-A-IN_HSNOrSACCode .
 GS_DATA-basic_val = LS_DATA-A-AmountInCompanyCodeCurrency .

LV_COUNT = LV_COUNT + 1.


  " Move cursor only once per lt_data row
  READ TABLE taxamt TRANSPORTING NO FIELDS
       WITH KEY A-companycode        = ls_data-A-companycode
                A-accountingdocument = ls_data-A-accountingdocument
                A-fiscalyear         = ls_data-A-fiscalyear
       BINARY SEARCH.

  IF sy-subrc = 0.

    lv_index = sy-tabix.

    LOOP AT taxamt INTO DATA(ls_taxamount)
         FROM lv_index.

      " Exit when key changes
      IF ls_taxamount-A-companycode        <> ls_data-A-companycode OR
         ls_taxamount-A-accountingdocument <> ls_data-A-accountingdocument OR
         ls_taxamount-A-fiscalyear         <> ls_data-A-fiscalyear.
        EXIT.
      ENDIF.

      CASE ls_taxamount-A-transactiontypedetermination.
        WHEN 'JIC'.
          GS_DATA-csgt_amt = ls_taxamount-A-amountincompanycodecurrency.
          GS_DATA-cgst_rate = ls_taxamount-B-ConditionRateRatio.
        WHEN 'JIS'.
          GS_DATA-sgst_amt = ls_taxamount-A-amountincompanycodecurrency.
          GS_DATA-Sgst_rate = ls_taxamount-B-ConditionRateRatio.
        WHEN 'JII'.
         GS_DATA-igst_amt = ls_taxamount-A-amountincompanycodecurrency.
          GS_DATA-igst_rate = ls_taxamount-B-ConditionRateRatio.
        WHEN 'JIU'.
          gs_data-sgst_amt  =  ls_taxamount-A-amountincompanycodecurrency.
          gs_data-sgst_rate =  ls_taxamount-B-conditionrateratio.
      ENDCASE.
    ENDLOOP.
  ENDIF.
 TOTAL =  TOTAL +  LS_DATA-A-AmountInCompanyCodeCurrency + GS_DATA-csgt_amt  + GS_DATA-sgst_amt + GS_DATA-igst_amt.
  APPEND gs_data TO gt_data.
ENDLOOP.

 CLEAR :  GS_DATA.
   LOOP AT GT_DATA INTO GS_DATA.
      DATA(lv_xml3) =
      |<Row1>| &&
      |<SlNo>{ LV_COUNT }</SlNo>| &&
      |<GoodsDescriptions>{  gs_data-desc }</GoodsDescriptions>| &&
      |<HSNCD>{ gs_data-hsn }</HSNCD>| &&
      |<BasicValue>{ GS_DATA-basic_val }</BasicValue>| &&

      |<cgst_p>{ GS_DATA-cgst_rate }</cgst_p>| &&
      |<cgst_amt>{ GS_DATA-csgt_amt  }</cgst_amt>| &&
      |<sgst_p>{ GS_DATA-sgst_rate  }</sgst_p>| &&
      |<sgst_amt>{ GS_DATA-sgst_amt  }</sgst_amt>| &&
      |<igst_p>{ GS_DATA-igst_rate }</igst_p>| &&
      |<igst_amt>{ GS_DATA-igst_amt }</igst_amt>| &&
      |<Rate_cs></Rate_cs>| &&
      |<gross_amt>{   LS_DATA-A-AmountInCompanyCodeCurrency + GS_DATA-csgt_amt  + GS_DATA-sgst_amt + GS_DATA-igst_amt }</gross_amt>| &&
      |</Row1>| .

      CONCATENATE lv_vs3 lv_xml3 INTO lv_vs3.
      CLEAR : lv_xml3.
    ENDLOOP.

    CONCATENATE lv_xml1 lv_xml2 lv_vs3 INTO lvn.
    DATA(lv_xml4) =
    |</Table1>| &&
    |</Subform2>| &&
    |<Subform5>| &&
    |<FooterRow2/>| &&
*    |<posting_date>{ billto-PostingDate }</posting_date>| &&
    |<inv_value_in_words></inv_value_in_words>| &&
    |<TCS_PERCENT></TCS_PERCENT>| &&
    |<TCS_VALUE></TCS_VALUE>| &&
    |<roundoff></roundoff>| &&
    |<invoice_total>{   TOTAL  }</invoice_total>| &&
    |<vehicle_no></vehicle_no>| &&
    |<ModOfTransport></ModOfTransport>| &&
    |<DriverName></DriverName>| &&
    |<PlaceOfSupply></PlaceOfSupply>| &&
    |<IRN></IRN>| &&
    |<IRN_Date></IRN_Date>| &&
    |<removal_dt_tm></removal_dt_tm>| &&
    |<Transporter></Transporter>| &&
    |<EWayBill></EWayBill>| &&
    |<awb_no> { billto-DocumentItemText  }</awb_no>| &&
    |<SystemDocNo></SystemDocNo>| &&
    |<CompanyName></CompanyName>| &&
    |</Subform5>| &&
    |<Subform6>| &&
    |<CompanyRegAddress></CompanyRegAddress>| &&
    |<CompanyEmail></CompanyEmail>| &&
    |<CompanyWebsite></CompanyWebsite>| &&
    |</Subform6>| &&
    |</Subform1>| &&
    |</form1>| .

    CONCATENATE lvn lv_xml4 INTO lv_xml.



    DATA(url) = |{ lv2_url }|.
    DATA(client) = create_client( url ).
    DATA(req) = client->get_http_request(  ).

    req->set_authorization_basic( i_username = 'sb-f025c9a7-2c02-4a9b-8188-b2138f631e4f!b526018|ads-xsappname!b102452'
    i_password = 'e00484ac-5881-494d-bb8a-89b10230b86a$uqtsFWGanDIu8WVyqL2BDEVJrGBBqhhDH8nx6fgu3V0=') .
    req->set_content_type( 'application/x-www-form-urlencoded'  ).
    req->set_form_field( EXPORTING i_name  = 'grant_type'
                                   i_value = 'client_credentials' ) .

    DATA(response) = client->execute( if_web_http_client=>post )->get_text(  ).

    REPLACE ALL OCCURRENCES OF '{"access_token":"' IN response WITH ''.
    SPLIT response AT '","token_type' INTO DATA(v1) DATA(v2) .
    DATA(access_token) = v1 .
    client->close(  ).

    REPLACE ALL OCCURRENCES OF '\t' IN lv_xml WITH '&#9;'.
    REPLACE ALL OCCURRENCES OF '\n' IN lv_xml WITH '&#10;'.
    REPLACE ALL OCCURRENCES OF '\r' IN lv_xml WITH '&#13;'.
    REPLACE ALL OCCURRENCES OF '!' IN lv_xml WITH '&#33;'.
*    REPLACE ALL OCCURRENCES OF '"' IN lv_xml WITH '&#34;'.
*    REPLACE ALL OCCURRENCES OF '#' IN lv_xml WITH '&#35;'.
    REPLACE ALL OCCURRENCES OF '$' IN lv_xml WITH '&#36;'.
*    REPLACE ALL OCCURRENCES OF '%' IN lv_xml WITH '&#37;'.
    REPLACE ALL OCCURRENCES OF '&' IN lv_xml WITH '&#38;'.
*    REPLACE ALL OCCURRENCES OF |'| IN lv_xml WITH '&#39;'.
    REPLACE ALL OCCURRENCES OF '(' IN lv_xml WITH '&#40;'.
    REPLACE ALL OCCURRENCES OF ')' IN lv_xml WITH '&#41;'.
    REPLACE ALL OCCURRENCES OF '*' IN lv_xml WITH '&#42;'.
    REPLACE ALL OCCURRENCES OF '+' IN lv_xml WITH '&#43;'.
*    REPLACE ALL OCCURRENCES OF ',' IN lv_xml WITH '&#44;'.
*    REPLACE ALL OCCURRENCES OF '-' IN lv_xml WITH '&#45;'.
*    REPLACE ALL OCCURRENCES OF '.' IN lv_xml WITH '&#46;'.
*    REPLACE ALL OCCURRENCES OF '/' IN lv_xml WITH '&#47;'.
    REPLACE ALL OCCURRENCES OF ':' IN lv_xml WITH '&#58;'.
*    REPLACE ALL OCCURRENCES OF ';' IN lv_xml WITH '&#59;'.
*    REPLACE ALL OCCURRENCES OF '<' IN lv_xml WITH '&#60;'.
    REPLACE ALL OCCURRENCES OF '=' IN lv_xml WITH '&#61;'.
*    REPLACE ALL OCCURRENCES OF '>' IN lv_xml WITH '&#62;'.
    REPLACE ALL OCCURRENCES OF '?' IN lv_xml WITH '&#63;'.
    REPLACE ALL OCCURRENCES OF '@' IN lv_xml WITH '&#64;'.
    REPLACE ALL OCCURRENCES OF '[' IN lv_xml WITH '&#91;'.
*    REPLACE ALL OCCURRENCES OF '\' IN lv_xml WITH '&#92;'.
    REPLACE ALL OCCURRENCES OF ']' IN lv_xml WITH '&#93;'.
    REPLACE ALL OCCURRENCES OF '^' IN lv_xml WITH '&#94;'.
*    REPLACE ALL OCCURRENCES OF '_' IN lv_xml WITH '&#95;'.
    REPLACE ALL OCCURRENCES OF '`' IN lv_xml WITH '&#96;'.
    REPLACE ALL OCCURRENCES OF '{' IN lv_xml WITH '&#123;'.
    REPLACE ALL OCCURRENCES OF '|' IN lv_xml WITH '&#124;'.
    REPLACE ALL OCCURRENCES OF '}' IN lv_xml WITH '&#125;'.
    REPLACE ALL OCCURRENCES OF '~' IN lv_xml WITH '&#126;'.
    REPLACE ALL OCCURRENCES OF '€' IN lv_xml WITH '&#128;'.
    REPLACE ALL OCCURRENCES OF '‚' IN lv_xml WITH '&#130;'.
    REPLACE ALL OCCURRENCES OF 'ƒ' IN lv_xml WITH '&#131;'.
    REPLACE ALL OCCURRENCES OF '„' IN lv_xml WITH '&#132;'.
    REPLACE ALL OCCURRENCES OF '…' IN lv_xml WITH '&#133;'.
    REPLACE ALL OCCURRENCES OF '†' IN lv_xml WITH '&#134;'.
    REPLACE ALL OCCURRENCES OF '‡' IN lv_xml WITH '&#135;'.
    REPLACE ALL OCCURRENCES OF 'ˆ' IN lv_xml WITH '&#136;'.
    REPLACE ALL OCCURRENCES OF '‰' IN lv_xml WITH '&#137;'.
    REPLACE ALL OCCURRENCES OF 'Š' IN lv_xml WITH '&#138;'.
    REPLACE ALL OCCURRENCES OF '‹' IN lv_xml WITH '&#139;'.
    REPLACE ALL OCCURRENCES OF 'Œ' IN lv_xml WITH '&#140;'.
    REPLACE ALL OCCURRENCES OF 'Ž' IN lv_xml WITH '&#142;'.
    REPLACE ALL OCCURRENCES OF '‘' IN lv_xml WITH '&#145;'.
    REPLACE ALL OCCURRENCES OF '’' IN lv_xml WITH '&#146;'.
    REPLACE ALL OCCURRENCES OF '“' IN lv_xml WITH '&#147;'.
    REPLACE ALL OCCURRENCES OF '”' IN lv_xml WITH '&#148;'.
    REPLACE ALL OCCURRENCES OF '•' IN lv_xml WITH '&#149;'.
    REPLACE ALL OCCURRENCES OF '–' IN lv_xml WITH '&#150;'.
    REPLACE ALL OCCURRENCES OF '—' IN lv_xml WITH '&#151;'.
    REPLACE ALL OCCURRENCES OF '˜' IN lv_xml WITH '&#152;'.
    REPLACE ALL OCCURRENCES OF '™' IN lv_xml WITH '&#153;'.
    REPLACE ALL OCCURRENCES OF 'š' IN lv_xml WITH '&#154;'.
    REPLACE ALL OCCURRENCES OF '›' IN lv_xml WITH '&#155;'.
    REPLACE ALL OCCURRENCES OF 'œ' IN lv_xml WITH '&#156;'.
    REPLACE ALL OCCURRENCES OF 'ž' IN lv_xml WITH '&#158;'.
    REPLACE ALL OCCURRENCES OF 'Ÿ' IN lv_xml WITH '&#159;'.
    REPLACE ALL OCCURRENCES OF '¡' IN lv_xml WITH '&#161;'.
    REPLACE ALL OCCURRENCES OF '¢' IN lv_xml WITH '&#162;'.
    REPLACE ALL OCCURRENCES OF '£' IN lv_xml WITH '&#163;'.
    REPLACE ALL OCCURRENCES OF '¤' IN lv_xml WITH '&#164;'.
    REPLACE ALL OCCURRENCES OF '¥' IN lv_xml WITH '&#165;'.
    REPLACE ALL OCCURRENCES OF '¦' IN lv_xml WITH '&#166;'.
    REPLACE ALL OCCURRENCES OF '§' IN lv_xml WITH '&#167;'.
    REPLACE ALL OCCURRENCES OF '¨' IN lv_xml WITH '&#168;'.
    REPLACE ALL OCCURRENCES OF '©' IN lv_xml WITH '&#169;'.
    REPLACE ALL OCCURRENCES OF 'ª' IN lv_xml WITH '&#170;'.
    REPLACE ALL OCCURRENCES OF '«' IN lv_xml WITH '&#171;'.
    REPLACE ALL OCCURRENCES OF '¬' IN lv_xml WITH '&#172;'.
    REPLACE ALL OCCURRENCES OF '®' IN lv_xml WITH '&#174;'.
    REPLACE ALL OCCURRENCES OF '¯' IN lv_xml WITH '&#175;'.
    REPLACE ALL OCCURRENCES OF '°' IN lv_xml WITH '&#176;'.
    REPLACE ALL OCCURRENCES OF '±' IN lv_xml WITH '&#177;'.
    REPLACE ALL OCCURRENCES OF '²' IN lv_xml WITH '&#178;'.
    REPLACE ALL OCCURRENCES OF '³' IN lv_xml WITH '&#179;'.
    REPLACE ALL OCCURRENCES OF '´' IN lv_xml WITH '&#180;'.
    REPLACE ALL OCCURRENCES OF 'µ' IN lv_xml WITH '&#181;'.
    REPLACE ALL OCCURRENCES OF '¶' IN lv_xml WITH '&#182;'.
    REPLACE ALL OCCURRENCES OF '·' IN lv_xml WITH '&#183;'.
    REPLACE ALL OCCURRENCES OF '¸' IN lv_xml WITH '&#184;'.
    REPLACE ALL OCCURRENCES OF '¹' IN lv_xml WITH '&#185;'.
    REPLACE ALL OCCURRENCES OF 'º' IN lv_xml WITH '&#186;'.
    REPLACE ALL OCCURRENCES OF '»' IN lv_xml WITH '&#187;'.
    REPLACE ALL OCCURRENCES OF '¼' IN lv_xml WITH '&#188;'.
    REPLACE ALL OCCURRENCES OF '½' IN lv_xml WITH '&#189;'.
    REPLACE ALL OCCURRENCES OF '¾' IN lv_xml WITH '&#190;'.
    REPLACE ALL OCCURRENCES OF '¿' IN lv_xml WITH '&#191;'.
    REPLACE ALL OCCURRENCES OF 'À' IN lv_xml WITH '&#192;'.
    REPLACE ALL OCCURRENCES OF 'Á' IN lv_xml WITH '&#193;'.
    REPLACE ALL OCCURRENCES OF 'Â' IN lv_xml WITH '&#194;'.
    REPLACE ALL OCCURRENCES OF 'Ã' IN lv_xml WITH '&#195;'.
    REPLACE ALL OCCURRENCES OF 'Ä' IN lv_xml WITH '&#196;'.
    REPLACE ALL OCCURRENCES OF 'Å' IN lv_xml WITH '&#197;'.
    REPLACE ALL OCCURRENCES OF 'Æ' IN lv_xml WITH '&#198;'.
    REPLACE ALL OCCURRENCES OF 'Ç' IN lv_xml WITH '&#199;'.
    REPLACE ALL OCCURRENCES OF 'È' IN lv_xml WITH '&#200;'.
    REPLACE ALL OCCURRENCES OF 'É' IN lv_xml WITH '&#201;'.
    REPLACE ALL OCCURRENCES OF 'Ê' IN lv_xml WITH '&#202;'.
    REPLACE ALL OCCURRENCES OF 'Ë' IN lv_xml WITH '&#203;'.
    REPLACE ALL OCCURRENCES OF 'Ì' IN lv_xml WITH '&#204;'.
    REPLACE ALL OCCURRENCES OF 'Í' IN lv_xml WITH '&#205;'.
    REPLACE ALL OCCURRENCES OF 'Î' IN lv_xml WITH '&#206;'.
    REPLACE ALL OCCURRENCES OF 'Ï' IN lv_xml WITH '&#207;'.
    REPLACE ALL OCCURRENCES OF 'Ð' IN lv_xml WITH '&#208;'.
    REPLACE ALL OCCURRENCES OF 'Ñ' IN lv_xml WITH '&#209;'.
    REPLACE ALL OCCURRENCES OF 'Ò' IN lv_xml WITH '&#210;'.
    REPLACE ALL OCCURRENCES OF 'Ó' IN lv_xml WITH '&#211;'.
    REPLACE ALL OCCURRENCES OF 'Ô' IN lv_xml WITH '&#212;'.
    REPLACE ALL OCCURRENCES OF 'Õ' IN lv_xml WITH '&#213;'.
    REPLACE ALL OCCURRENCES OF 'Ö' IN lv_xml WITH '&#214;'.
    REPLACE ALL OCCURRENCES OF '×' IN lv_xml WITH '&#215;'.
    REPLACE ALL OCCURRENCES OF 'Ø' IN lv_xml WITH '&#216;'.
    REPLACE ALL OCCURRENCES OF 'Ù' IN lv_xml WITH '&#217;'.
    REPLACE ALL OCCURRENCES OF 'Ú' IN lv_xml WITH '&#218;'.
    REPLACE ALL OCCURRENCES OF 'Û' IN lv_xml WITH '&#219;'.
    REPLACE ALL OCCURRENCES OF 'Ü' IN lv_xml WITH '&#220;'.
    REPLACE ALL OCCURRENCES OF 'Ý' IN lv_xml WITH '&#221;'.
    REPLACE ALL OCCURRENCES OF 'Þ' IN lv_xml WITH '&#222;'.
    REPLACE ALL OCCURRENCES OF 'ß' IN lv_xml WITH '&#223;'.
    REPLACE ALL OCCURRENCES OF 'à' IN lv_xml WITH '&#224;'.
    REPLACE ALL OCCURRENCES OF 'á' IN lv_xml WITH '&#225;'.
    REPLACE ALL OCCURRENCES OF 'â' IN lv_xml WITH '&#226;'.
    REPLACE ALL OCCURRENCES OF 'ã' IN lv_xml WITH '&#227;'.
    REPLACE ALL OCCURRENCES OF 'ä' IN lv_xml WITH '&#228;'.
    REPLACE ALL OCCURRENCES OF 'å' IN lv_xml WITH '&#229;'.
    REPLACE ALL OCCURRENCES OF 'æ' IN lv_xml WITH '&#230;'.
    REPLACE ALL OCCURRENCES OF 'ç' IN lv_xml WITH '&#231;'.
    REPLACE ALL OCCURRENCES OF 'è' IN lv_xml WITH '&#232;'.
    REPLACE ALL OCCURRENCES OF 'é' IN lv_xml WITH '&#233;'.
    REPLACE ALL OCCURRENCES OF 'ê' IN lv_xml WITH '&#234;'.
    REPLACE ALL OCCURRENCES OF 'ë' IN lv_xml WITH '&#235;'.
    REPLACE ALL OCCURRENCES OF 'ì' IN lv_xml WITH '&#236;'.
    REPLACE ALL OCCURRENCES OF 'í' IN lv_xml WITH '&#237;'.
    REPLACE ALL OCCURRENCES OF 'î' IN lv_xml WITH '&#238;'.
    REPLACE ALL OCCURRENCES OF 'ï' IN lv_xml WITH '&#239;'.
    REPLACE ALL OCCURRENCES OF 'ð' IN lv_xml WITH '&#240;'.
    REPLACE ALL OCCURRENCES OF 'ñ' IN lv_xml WITH '&#241;'.
    REPLACE ALL OCCURRENCES OF 'ò' IN lv_xml WITH '&#242;'.
    REPLACE ALL OCCURRENCES OF 'ó' IN lv_xml WITH '&#243;'.
    REPLACE ALL OCCURRENCES OF 'ô' IN lv_xml WITH '&#244;'.
    REPLACE ALL OCCURRENCES OF 'õ' IN lv_xml WITH '&#245;'.
    REPLACE ALL OCCURRENCES OF 'ö' IN lv_xml WITH '&#246;'.
    REPLACE ALL OCCURRENCES OF '÷' IN lv_xml WITH '&#247;'.
    REPLACE ALL OCCURRENCES OF 'ø' IN lv_xml WITH '&#248;'.
    REPLACE ALL OCCURRENCES OF 'ù' IN lv_xml WITH '&#249;'.
    REPLACE ALL OCCURRENCES OF 'ú' IN lv_xml WITH '&#250;'.
    REPLACE ALL OCCURRENCES OF 'û' IN lv_xml WITH '&#251;'.
    REPLACE ALL OCCURRENCES OF 'ü' IN lv_xml WITH '&#252;'.
    REPLACE ALL OCCURRENCES OF '✓' IN lv_xml WITH 'a'.
    REPLACE ALL OCCURRENCES OF 'ý' IN lv_xml WITH '&#253;'.


    DATA(gv) = 'https://adsrestapi-formsprocessing.cfapps.eu10.hana.ondemand.com/v1/adsRender/pdf?templateSource=storageName&TraceLevel=2' .
    DATA(ls_data_xml) = cl_web_http_utility=>encode_base64( lv_xml ).

    url = |{ gv }|.
    client = create_client( url ).
    req = client->get_http_request(  ).
    req->set_authorization_bearer( access_token ) .

    DATA(ls_body) = VALUE struct( xdp_template = lc_template_name
                                  xml_data     = ls_data_xml
                                  form_type    = 'print'
                                  form_locale  = 'en_US   '
                                  tagged_pdf   = '0'
                                  embed_font   = '0' ).
    DATA(lv_json) = /ui2/cl_json=>serialize( data = ls_body compress = abap_true pretty_name = /ui2/cl_json=>pretty_mode-camel_case ).
    req->append_text(
              EXPORTING
                data   = lv_json
            ).
    req->set_content_type( 'application/json' ).


    DATA: result9 TYPE string.
*    DATA(result2) = client->execute( if_web_http_client=>post )->get_status( ) .
    result9 = client->execute( if_web_http_client=>post )->get_text( ).

    result12 = result9 .

    FIELD-SYMBOLS:
      <data>                TYPE data,
      <field>               TYPE any,
      <pdf_based64_encoded> TYPE any.
    DATA : lr_d TYPE string .

    DATA(lr_d1) = /ui2/cl_json=>generate( json = result9 ).
*     DATA(lr_d1) = /ui2/cl_json=>generate( json = result12 ).

    IF lr_d1 IS BOUND.
      ASSIGN lr_d1->* TO <data>.
      ASSIGN COMPONENT `fileContent` OF STRUCTURE <data> TO <field>.
      IF sy-subrc EQ 0.
        ASSIGN <field>->* TO <pdf_based64_encoded>.
        result12 = <pdf_based64_encoded> .
**            out->write( <pdf_based64_encoded> ).
*         CLEAR WA_PRINT.
*
*         WA_PRINT-client    = SY-mandt.
*         WA_PRINT-inv_doc   = invdocument.
*         WA_PRINT-inv_year  = SY-datum+0(4).
*         WA_PRINT-mark      = 'X'.
*         WA_PRINT-user_i    = SY-uname.
*         WA_PRINT-date_i    = SY-datum.
*         WA_PRINT-time_i    = SY-uzeit.
*
*         MODIFY zinv_print_st FROM @WA_PRINT.
      ENDIF.
    ENDIF.
  ENDMETHOD.
ENDCLASS.
