       IDENTIFICATION DIVISION.
      *This section declares the program's metadata/name
       PROGRAM-ID. ACCTINQ.

       ENVIRONMENT DIVISION.
      *This section maps external files or hardware to internal vars
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT ACCT-FILE ASSIGN TO 'ACCOUNTS.DAT'
           ORGANIZATION IS SEQUENTIAL
           ACCESS MODE IS SEQUENTIAL
           FILE STATUS IS WS-FILE-STATUS.

       DATA DIVISION.
       FILE SECTION.
       FD  ACCT-FILE
           RECORD CONTAINS 68 CHARACTERS.

       01  ACCT-RECORD.
           05  FD-ACCT-NUM             PIC X(8).
           05  FD-BRANCH               PIC X(3).
           05  FD-ACCT-TYPE            PIC X(3).
           05  FD-NAME                 PIC X(20).
           05  FD-STATUS               PIC X(8).
           05  FD-LEDGER-BAL           PIC X(9).
           05  FD-AVAIL-BAL            PIC X(9).
           05  FD-LAST-ACT             PIC X(8).

       WORKING-STORAGE SECTION.
       01  WS-FILE-STATUS          PIC X(2).
       01  WS-EOF                  PIC X VALUE 'N'.
       01  WS-SEARCH-ACCT          PIC X(8).
       01  WS-FOUND                PIC X VALUE 'N'.
       01  WS-INPUT-ACCT           PIC X(8).

       PROCEDURE DIVISION.
       0000-MAIN.
      *Grab the command line argument passed by the terminal/Node
           ACCEPT WS-INPUT-ACCT FROM COMMAND-LINE.
           MOVE WS-INPUT-ACCT TO WS-SEARCH-ACCT.

           OPEN INPUT ACCT-FILE
           IF WS-FILE-STATUS NOT = '00'
              DISPLAY '500:ERROR OPENING FILE: ' WS-FILE-STATUS
              STOP RUN
           END-IF.

           PERFORM 1000-READ-LOOP UNTIL WS-EOF = 'Y' OR WS-FOUND = 'Y'.

           IF WS-FOUND = 'N'
              DISPLAY '404:ACCOUNT NOT FOUND'
           END-IF.

           CLOSE ACCT-FILE.
           STOP RUN.

       1000-READ-LOOP.
           READ ACCT-FILE
              AT END
                 MOVE 'Y' TO WS-EOF
              NOT AT END
                 IF FD-ACCT-NUM = WS-SEARCH-ACCT
                    MOVE 'Y' TO WS-FOUND
                    DISPLAY '200:' FD-ACCT-NUM ':' FD-BRANCH ':'
                            FD-ACCT-TYPE ':' FD-NAME ':'
                            FD-STATUS ':' FD-LEDGER-BAL ':'
                            FD-AVAIL-BAL ':' FD-LAST-ACT
                 END-IF
           END-READ.