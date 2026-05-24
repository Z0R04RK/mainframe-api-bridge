//* COMPILE COBOL SOURCE (ACCOUNT UPDATE) 
//* AND CREATE EXECUTABLE
//COMPACCT JOB 1,NOTIFY=&SYSUID
//* name of job,dept to link to cpu usage,notifs goto me
//MYCOMP   EXEC IGYWCL
//* step label,IBM procedure "Cobol compiler & Linkage Editor"
//COBOL.SYSIN  DD DSN={{HLQ}}.BANK.SOURCE(ACCTUPD),DISP=SHR
//*feeding src code to compiler,Data Set Name,Disposition Share
//*lets others view since you are only reading/compiling it
//LKED.SYSLMOD DD DSN={{HLQ}}.BANK.LOAD(ACCTUPD),
//            DISP=(NEW,CATLG,DELETE),
//            SPACE=(TRK,(5,5,10)),
//            DSORG=PO,DSNTYPE=LIBRARY,RECFM=U,BLKSIZE=32760
//*Creating .bank.load directory and saving the exe there