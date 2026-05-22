       IDENTIFICATION DIVISION.
       Program-id. cbl_json.
       Author. Student.
      ******************************************************************
      * This program is compiled and run via JCL file CBLJSONJ.jcl     *
      * and reads in a JSON file from SYSIN (see JCL)                  *
      * The JSON file contains a grocery store's inventory, including  *
      * product names, images, expiry dates, quantity, sales and price.*
      * The program will output a flyer for the grocery store, pricing *
      * items at a 50% discount that will expire sooner than they      *
      * would ordinarily sell.                                         *
      *                                                                *
      * If you are brand new to COBOL, here's some info to get started:*
      * Certain code must go in certain columns:                       *
      *   https://ibm.biz/structure-reference-format                   *
      * Do not write anything in column 73 and beyond.                 *
      * COBOL is not case sensitive. Code in UPPER, lower or MiXeD CaSe*
      * Code is divided into DIVISIONS & SECTIONS:                     *
      *   https://ibm.biz/area-division-headers                        *
      * Debug/trace program logic with DISPLAY:                        *
      *   https://ibm.biz/language-tracing-program-logic               *
      * IBM's COBOL manual: https://ibm.biz/cobol-zos-latest           *
      * Want to learn more? Take IBM's free COBOL course. It includes  *
      * hands-on labs in VS Code:                                      *
      *   16 hour video version: https://ibm.biz/learn-cobol-vscode    *
      *   Text version: https://ibm.biz/github-cobol                   *
      ******************************************************************
       ENVIRONMENT DIVISION.
       Input-output section.
       File-control.
      * The COBOL program names the output file "flyer". The following
      * statement associates the program's name "flyer" with the
      * external name for the actual data file, FLYYFILE, defined in JCL
           Select flyer assign to FLYRFILE.

       DATA DIVISION.
       File section.
       FD flyer recording mode V.
       1 flyer-file        pic x(10000) value spaces.
       Working-storage section.
      * Declare variables, called "data items" in COBOL
      * Learn about the picture clause (pic) and formatting:
      *  https://ibm.biz/cobol-symbols-picture
      *  https://ibm.biz/cobol-fixed-insertion-editing
      * Learn about the numbers (level indicators) in front of data
      * items: https://ibm.biz/cobol-level-numbers
      * Current line of JSON input
       1 json-line         pic x(80) value spaces.
      * Concatenation of all lines of JSON input
       1 json-doc          pic x(10000) value spaces.
      * JSON input encoded in UTF-8 but contained in alphanumeric item
       1 json-doc-1208     pic x(10000) value spaces.
      * JSON input parsed into this data structure to hold the 7
      * grocery store products
       1 inv-data.
        2 inv-record occurs 7 times.
           3 prod-name     pic x(20).
           3 expiry        pic 9(8).
           3 quantity      pic 9(3).
           3 salesperday   pic 9(3).
           3 price         pic 9(1)V9(2).
           3 prod-img      pic x(99).
      * Indicator to see if we have reached the end of the JSON input
       1 end-of-json       pic x(1) value 'N'.
      * Counter for inventory records
       1 inv-rec-cnt       pic 9(1) value 1.
      * "Today's" date for flyer (YYYYMMDD)
       1 todays-date       pic 9(8) value 20210918.
       1 todays-date-int   pic 9(10).
       1 sale-end-date-int pic 9(10).
       1 prod-img-broken   pic x(99) value "https://ibmzxplore-static.s3
      -    ".eu-gb.cloud-object-storage.appdomain.cloud/unknown.png".
      * 3 data items for currencies in $USD
       1 pricefrmt         pic $9.99.
       1 saleprice         pic $9.99.
       1 discount          pic $9.99.
       1 productname       pic x(20).

       1 daystoexpiry      pic ZZ9.
       1 daystosellall     pic ZZ9.
       1 expiry-date-int   pic 9(10).
       1 flyerformat       pic x(4).
      * HTML and CSS for flyer
       1 htmlheader1 pic x(151) value "<html><head><style>body{font-fami
      -    "ly:IBM Plex Sans;background:#98CEF4;color:black;}img{width:2
      -    "50px;}table{margin-left:auto;margin-right:auto;border:1px ".
       1 htmlheader2 pic x(151) value "solid black;width:250px;backgroun
      -    "d:white;}#title{text-align:center;font-family:IBM Plex Sans;
      -    "}.price{color:green;font-size:50px;}.discount{color:red;fo".
       1 htmlheader3 pic x(151) value "nt-size:20px;}.product{font-size:
      -    "15px;}#footer{text-align:center;font-size:larger;}</style></
      -    "head><body><div id=""title""><h1>Corner Grocery Store</h1>".
       1 htmltablestart    pic x(41) value "</div><table><tr><td colspan
      -    "=2><img src=""".
       1 htmlprice         pic x(35) value """></td></tr> <tr><td class=
      -    """price"">".
       1 htmldiscount      pic x(37) value "</td><td><span class=""disco
      -    "unt"">Save ".
       1 htmlproduct       pic x(33) value "</span><br><span class=""pro
      -    "duct"">".
       1 htmloldprice      pic x(9) value "<br>Was: ".
       1 htmltableend pic x(29) value "</span></td></tr></table><br>".
       1 htmlflyerfooter   pic x(20) value "<div id=""footer""><p>".
       1 htmlfooter        pic x(24) value "</p></div></body></html>".

       Linkage section.
       1 parameters-from-jcl.
      * System-inserted field for total string length of parameters
         2 parameters-total-length pic 9(4) usage comp.
      * Flyer format parameter - TEXT or HTML
         2 parameter-values        pic x(20).

      * Parameters are passed to the program from the JCL and moved
      * into "flyerformat"
       PROCEDURE DIVISION using parameters-from-jcl.
           If parameters-total-length > 0 then
      * Trim the parameter
             Move function trim (parameter-values) to flyerformat
           End-if

      * Read JSON data from SYSIN, concatenating lines into json-doc
           Perform until end-of-json = 'Y'
             Move spaces to json-line
             Accept json-line
      * Chose to use '***' as an end of file marker in SYSIN
             If json-line = '***'
               Move 'Y' to end-of-json
             Else
               String function trim(json-doc)
                      function trim(json-line)
                        delimited by size
                into json-doc
             End-if
           End-perform

      * Now the full JSON text is in one long string in json-doc.
      * We need to parse the data and put its contents into
      * the COBOL "group item" variable inv-data.

      * To better understand this program, learn about codepages:
      * On mainframes, character encodings are called codepages.
      * You might be familiar with the Unicode/UTF-8 character set,
      * or ASCII, a subset of UTF-8,
      * e.g. '@' is represented as 64 and 'a' as 97.
      * In addition to these codepages, mainframes support the EBCDIC
      * character set, e.g.'@' is represented as 124 and 'a' as 81

      * Since our JSON input is "hand coded" in the COBOL program,
      * it is in the EBCDIC codepage 1047. Input to JSON PARSE
      * must be in UTF-8 (codepage 1208). In a real world program, your
      * JSON input would likely already be in UTF-8, eliminating the
      * need for this conversion.
      * Convert to specific codepages using the display-of function.
      * The first argument to display-of should be type 'national',
      * which the COBOL compiler represents in UTF-16.

      * Convert JSON input to UTF-8 prior to JSON PARSE
           Move function display-of(
             function national-of(json-doc 1047) 1208) to
             json-doc-1208(1:function length(json-doc))

      * Parse JSON into inv-data data structure we defined
      * "With detail" (commented out) enables diagnostic messages
      * Turn this on if the JSON data is not parsed correctly.
           Json parse json-doc-1208 into inv-data
      *        with detail
           end-json

      * Our date is currently stored as "20210918" (YYYYMMDD)
      * We want to format this date as YYYY-MM-DD
      * To do this we need to first convert our YYYYMMDD integer to
      * number of days elapsed since 31 December 1600 (similar to Unix
      * epoch). COBOL provides a number of intrinsic functions (built-in
      * functions/BIF) to do common tasks like this in few lines of code
           Compute todays-date-int =
              function INTEGER-OF-DATE(todays-date)

      * Open flyer before moving anything to file descriptor flyer-file
           Open output flyer
           Initialize flyer-file
           If flyerformat = 'TEXT' then
              Move "Corner Grocery Store" to flyer-file
           Else
              String htmlheader1 htmlheader2 htmlheader3
                 delimited by size into flyer-file
           End-if
           Write flyer-file.

      * Loop through the 7 grocery store inventory items
           Perform until inv-rec-cnt = 8
              Compute expiry-date-int =
                 function INTEGER-OF-DATE(expiry(inv-rec-cnt))
              Compute daystoexpiry =
                 expiry-date-int - todays-date-int
      *Calculate days to sell all stock assuming usual sales, rounded up
              Compute daystosellall rounded =
                 quantity(inv-rec-cnt) / salesperday(inv-rec-cnt)
      * If this item will not sell out before it expires,
      * put item on a sale of a 50% discount and add to flyer
              If daystoexpiry < daystosellall then
                 Move price(inv-rec-cnt) to pricefrmt
                 Compute saleprice = price(inv-rec-cnt) / 2
                 Compute discount =
                    price(inv-rec-cnt) - price(inv-rec-cnt) / 2

                 Move function trim(prod-name(inv-rec-cnt))
                    to productname

                 Initialize flyer-file
                 If flyerformat = 'TEXT' then
                    String productname saleprice
                       " Was: " pricefrmt
                        delimited by size
                    into flyer-file
                 Else
                    String
                      htmltablestart prod-img(inv-rec-cnt) htmlprice
                      saleprice
                      htmldiscount discount htmlproduct productname
                      htmloldprice pricefrmt htmltableend
                      delimited by size
                  into flyer-file
                 End-if
                 Write flyer-file
              End-if
              Add 1 to inv-rec-cnt
           End-perform

      * Sale is valid from "today" (18 Sep 2021) to 7 days from "today"
           Compute sale-end-date-int = todays-date-int + 7
           Initialize flyer-file
           If flyerformat not = 'TEXT' then
              Move htmlflyerfooter to flyer-file
              Write flyer-file
           End-if

      * Date formatting options: https://ibm.biz/cobol-format-date-time
           String
              "Flyer in effect "
              function formatted-date("YYYY-MM-DD" todays-date-int)
              " to "
              function formatted-date("YYYY-MM-DD" sale-end-date-int)
              delimited by size
              into flyer-file
           Write flyer-file

           If flyerformat not = 'TEXT' then
              Move htmlfooter to flyer-file
           Write flyer-file
           End-if

           Close flyer

           Goback.
       End program cbl_json.