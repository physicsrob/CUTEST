; --- NOTE ---
;   This was produced by scanning and OCRing the program listing
;   from Processor Technology Access newsletter, issue #2.  The
;   OCRing didn't go smoothly, and there was a LOT of hand editing.
;   After restoring the program listing, it was hand edited to be
;   compatible with the standard CP/M ASM assembler.  It assembles
;   and the hex output has been compared against the object listing
;   from the OCR'd listing and they match.  However, there is no
;  guarantee that this source is actually accurate.
;       Revision history:
;            99/11/06 -- jtb: first released version
;            99/11/13 -- jtb: fixed two source code OCR errors
;	     21/10-18 -- rap: change serial port to 2IO card
; --- NOTE END ---
;
;
;
;
;        CUTER(TM)
;
;                 COPYRIGHT (C) 1977
;                 SOFTWARE TECHNOLOGY CORP.
;                 P.O. BOX 5260
;                 SAN MATEO, CA 94402
;                 (415) 349-8080
;
;    A L L    R I G H T S   R E S E R V E D ! ! !
;
;
;        VERSION  1.3
;                 77-03-27
;
;
;  THIS PROGRAM IS DESIGNED TO BE A STANDALONE CUTS
;  OPERATING SYSTEM. CUTER IS DESIGNED TO BE READ IN FROM
;  CASSETTE TAPE OR TO BE RESIDENT IN READ-ONLY-MEMORY.
;  CUTER SUPPORTS VARIOUS DEVICES INCLUDING SERIAL,
;  PARALLEL, THE PROCESSOR TECHNOLOGY VDM(TM) AND UP TO
;  TWO CUTS TAPE DRIVES.
;
;  CUTER(TM) HAS BEEN WRITTEN SO AS TO BE COMPATIBLE WITH
;  SOLOS(TM).  THE FOLLOWING KEYS ARE USED BY CUTER(TM)
;  IN PLACE OF THE SPECIAL KEYS ON THE SOL KEYBOARD:
;
;     CURSOR UP       CTL-W
;     CURSOR LEFT     CTL-A
;     CURSOR RIGHT    CTL-S
;     CURSOR DOWN     CTL-Z
;     CURSOR HOME     CTL-N
;     CLEAR SCREEN    CTL-K
;     MODE            CTL-@
;
;
;
