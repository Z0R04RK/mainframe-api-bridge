       IDENTIFICATION DIVISION.
       PROGRAM-ID. ACCTUPD.
       
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT ACCT-FILE ASSIGN TO 'ACCOUNTS.DAT'
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-IN-STATUS.
           SELECT TEMP-FILE ASSIGN TO 'ACCOUNTS.TMP'
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-OUT-STATUS.

       DATA DIVISION.
       FILE SECTION.
       FD  ACCT-FILE.
       01  ACCT-REC-IN         PIC X(68).
       
       FD  TEMP-FILE.
       01  ACCT-REC-OUT        PIC X(68).

       WORKING-STORAGE SECTION.
       01  WS-FLAGS.
           05 WS-EOF           PIC X VALUE 'N'.
           05 WS-FOUND         PIC X VALUE 'N'.
       01  WS-IN-STATUS        PIC XX.
       01  WS-OUT-STATUS       PIC XX.
       
       01  WS-TARGET-ID        PIC X(8).
       01  WS-NEW-STATUS       PIC X(8).

       01  WS-PARSED-REC.
           05 WS-ACCT-ID       PIC X(8).
           05 WS-BRANCH        PIC X(3).
           05 WS-TYPE          PIC X(3).
           05 WS-NAME          PIC X(20).
           05 WS-STATUS        PIC X(8).
           05 WS-BALANCES      PIC X(26).

       PROCEDURE DIVISION.
       0000-MAIN.
           DISPLAY 1 UPON ARGUMENT-NUMBER
           ACCEPT WS-TARGET-ID FROM ARGUMENT-VALUE
           
           DISPLAY 2 UPON ARGUMENT-NUMBER
           ACCEPT WS-NEW-STATUS FROM ARGUMENT-VALUE

           OPEN INPUT ACCT-FILE
           OPEN OUTPUT TEMP-FILE

           IF WS-IN-STATUS NOT = '00'
               DISPLAY '500:INPUT FILE ERROR'
               STOP RUN
           END-IF.

           PERFORM 1000-PROCESS-RECORDS UNTIL WS-EOF = 'Y'

           CLOSE ACCT-FILE
           CLOSE TEMP-FILE

           IF WS-FOUND = 'Y'
               DISPLAY '200:UPDATE SUCCESSFUL'
           ELSE
               DISPLAY '404:ACCOUNT NOT FOUND'
           END-IF

           STOP RUN.

       1000-PROCESS-RECORDS.
           READ ACCT-FILE INTO WS-PARSED-REC
               AT END
                   MOVE 'Y' TO WS-EOF
               NOT AT END
                   IF WS-ACCT-ID = WS-TARGET-ID
                       MOVE WS-NEW-STATUS TO WS-STATUS
                       MOVE 'Y' TO WS-FOUND
                   END-IF
                   MOVE WS-PARSED-REC TO ACCT-REC-OUT
                   WRITE ACCT-REC-OUT
           END-READ.