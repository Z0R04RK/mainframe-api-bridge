//RUNACCT  JOB 1,NOTIFY=&SYSUID
//* EXECUTE CORE BANKING UPDATE PROGRAM
//RUNSTEP  EXEC PGM=ACCTUPD,
//            PARM='10045992FROZEN  '
//*executes & linage buffer filled with 8chars ID 8chars status
//STEPLIB  DD DSN={{HLQ}}.BANK.LOAD,DISP=SHR
//*says look in step library here
//ACCTFILE DD DSN={{HLQ}}.BANK.ACCOUNTS,DISP=SHR
//*linking the acct file to the statement in cobol code
//SYSOUT   DD SYSOUT=*
//* display statements sent to JCL job output spool