       IDENTIFICATION DIVISION.
      *This section declares the program's metadata/name 
       PROGRAM-ID. ACCTINQ.
      *Stands for Account Inquiry

       ENVIRONMENT DIVISION. 
      *This section maps external files or hardware to internal vars

       INPUT-OUTPUT SECTION. 
       FILE-CONTROL. 
           SELECT ACCT-FILE ASSIGN TO 'ACCOUNT.DAT'
      *Internal variable ACCT-FILE associated with the file name
           ORGANIZATION IS SEQUENTIAL
      *How file is structured on the disk
           ACCESS MODE IS SEQUENTIAL
      *How our program intends the compiler to read it
           FILE STATUS IS WS-FILE-STATUS.
      *2 char var for tracking success or failure of file operations

       DATA DIVISION.
       FILE SECTION.
       FD  ACCT-FILE
           RECORD CONTAINS 68 CHARACTERS.

       01  ACCT-RECORD.
      *01 defines the root record layout structure (the entire row)
           05  FD-ACCT-NUM             PIC X(8).
           05  FD-BRANCH               PIC X(3).
           05  FD-ACCT-TYPE            PIC X(3).
           05  FD-NAME                 PIC X(20).
           05  FD-STATUS               PIC X(8).
           05  FD-LEDGER-BAL           PIC X(9).
           05  FD-AVAIL-BAL            PIC X(9).
           05  FD-LAST-ACT             PIC X(8).
      *variable to split the 68-char row into specific fields

       WORKING-STORAGE SECTION.
      *01 variables define independent pieces of memory
       01  WS-FILE-STATUS          PIC X(2).
       01  WS-EOF                  PIC X VALUE 'N'.
       01  WS-SEARCH-ACCT          PIC X(8).
       01  WS-FOUND                PIC X VALUE 'N'.
      *initialized with value n to no


      * LINKAGE SECTION. 
      * 01  LS-INPUT-ACCT           PIC X(8).
      *This var acts as a pointer to the arg passed by the runtime env
      *If we were actually using an actual z/os IBM mainframe where the 
      *program recieves args from a JCL script

       PROCEDURE DIVISION USING LS-INPUT-ACCT.
      *Main logic of the program, using the input account number
       0000-MAIN.
      *Move the input account number to working storage search var
           MOVE LS-INPUT-ACCT TO WS-SEARCH-ACCT.
      *Open the dataset and check for errors
           OPEN INPUT ACCT-FILE
           IF WS-FILE-STATUS NOT = '00'
              DISPLAY '500:ERROR OPENING FILE: ' WS-FILE-STATUS
              STOP RUN
           END-IF.
           
      *Trigger loop paragraph until hitting eof or match
           PERFORM 1000-READ-LOOP UNTIL WS-EOF = 'Y' OR WS-FOUND = 'Y'

      *If the loop finished and found flag is 'N' return a 404
           IF WS-FOUND = 'N'
              DISPLAY '404:ACCOUNT NOT FOUND'
           END-IF.

      *Close the files to release the memory lock
           CLOSE ACCT-FILE 
           STOP RUN.

       1000-READ-LOOP.
           READ ACCT-FILE
           
              AT END
                 MOVE 'Y' TO WS-EOF
   
              NOT AT END
                 IF FD-ACCT-NUM = WS-SEARCH-ACCT 
                    MOVE 'Y' TO WS-FOUND 
               
      *Outp   utting the formatted str for Node.js to capture
                    DISPLAY '200:' FD-ACCT-NUM ':' FD-BRANCH ':'
                       FD-ACCT-TYPE ':' FD-LEDGER-BAL ':' FD-AVAIL-BAL ':'
                       FD-AVAIL-BAL ':' FD-LAST-ACT
                  END-IF
           END-READ.



