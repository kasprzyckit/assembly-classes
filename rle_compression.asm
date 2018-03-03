;Tomasz Kasprzycki
;Task 2 - RLE compression

.186
DATA1   SEGMENT

LICZNIK     DB  ?
ARGUMENTY   DB  256 DUP('$')
OFFSETY     DB  256 DUP(0)
ERR_NOARG   DB  "BLAD: NIE PODANO ZADNYCH ARGUMENTOW.$"
ERR_ARGCON  DB  "BLAD: PODANO BLEDNA ILOSC ARGUMENTOW.$" 
ERR_LONGIN  DB  "BLAD: PODANO ZA DLUGA NAZWE PLIKU WEJSCIOWEGO.$"
ERR_LONGOUT DB  "BLAD: PODANO ZA DLUGA NAZWE PLIKU WYJSCIOWEGO.$"
ERR_ARG     DB  "BLAD: PODANO NIEPRAWIDLOWE ARGUMENTY.$"
ERR         DB  13,10,"SYNTAX: KOMPRESJA_RLE.EXE [-d] INPUT OUTPUT",13,10,'$' 
ERR_FILE    DB  "BLAD: NIE ZNALENIONO WSKAZANEGO PLIKU.$"  
ERR_FILE2   DB  "BLAD: NIE UDALO SIE ODCZYTAC PLIKU.$"
ERR_FILE3   DB  "BLAD: NIE UDALO SIE STWORZYC PLIKU.$"
MESS_END    DB  "KOMPRESJA/DEKOMPRESJA ZAKONCZONA SUKCESEM.",13,10,'$' 
MODE_FLAG   DB  0     
END_FLAG    DB  0    
INFILE      DB  60 DUP(0)
OUTFILE     DB  60 DUP(0) 
INHANDLE    DW  ?
OUTHANDLE   DW  ? 
BUFFOR_IN   DB  24000 DUP(?)
BUFFOR_OUT  DB  36000 DUP(?)

    
DATA1   ENDS
    
CODE1   SEGMENT 
        
    ASSUME ES:DATA1,CS:CODE1,SS:STOS1 
    BUFFOR_SIZE_IN EQU 5DC0h 
    BUFFOR_SIZE_OUT EQU 8CA0h

START:  MOV AX, SEG WSTOSU    ;INICJACJA STOSU
        MOV SS, AX
        MOV SP, OFFSET WSTOSU
       
        CALL PARSE_ARGS  ;PARSOWANIE ARGUMENTOW
        CALL ANLSIS_ARGS ;SPRAWDZENIE ARGUMENTOW
        CMP AL, 1        ;JEZELI NIE POPRAWNE, KONIEC PROGRAMU  
        JE KONIEC             
        CALL PROCESS     ;KONWERSJA PLIKU

        
KONIEC: MOV AH, 4CH      ;KONIEC PROGRAMU
        INT 21H                                                   
        
  ;---------------------------PROCEDURY---------------------------
    PARSE_ARGS           PROC
        PUSHA
       
		
        MOV DI,OFFSET ARGUMENTY      ;ES:DI WSKAZUJE NA LANCUCH 'ARGUMENTY'
	    MOV AX,SEG ARGUMENTY
	    MOV ES,AX
	    
	    MOV SI, 80H            ;DS:SI WSKAZUJE NA POCZATEK ARGUMENTU Z LINI POLECEN
	    MOV CL, DS:[SI]        ;W CX ILOSC ZNAKOW ARGUMENTOW
        
        MOV BP, OFFSET OFFSETY
        
        XOR CH, CH     
        XOR BL, BL 
        XOR DL, DL 
        INC SI
        
POCZ:   CALL SKIP_WHITESPACE 
        CMP CX, 0
        JE ENDARG
        
ARGUM:  INC DI
        MOV AX, DI  
        MOV BYTE PTR ES:[BP], DL  
        XOR DL, DL
        INC BP
        MOV WORD PTR ES:[BP], AX
        INC BP
        INC BP  
        INC BL
        MOV AL, DS:[SI]
        
ZNAK:   MOV ES:[DI], AL 
        INC DL
        INC SI
        INC DI
        DEC CX
        MOV AL, DS:[SI]
        CMP AL, ' '
        JE POCZ
        CMP AL, 9
        JE POCZ
        CMP AL, 13
        JNE ZNAK
        
ENDARG: MOV ES:LICZNIK, BL          ;DO ZMIENNEJ LICZNIK WPISUJEMY ILOSC ARGUMENTOW
        MOV BYTE PTR ES:[BP], DL
        POPA
        RET 
    PARSE_ARGS           ENDP        
;--------------------------------------------------
    SKIP_WHITESPACE     PROC        ;PRZESUWA SI NA WSKAZANIE NASTEPNEGO ZNAKU NIE BEDACEGO BIALYM ZNAKIEM 
        PUSH AX

WHITE:  MOV AL, DS:[SI]
        CMP AL, ' '
        JE WSP
        CMP AL, 9
        JNE ENDSK
WSP:    INC SI
        DEC CX
        JMP WHITE

ENDSK:  POP AX
        RET
    SKIP_WHITESPACE     ENDP
  ;----------------------------------------------------
    ANLSIS_ARGS    PROC         ;SPRAWDZA POPRAWNOSC WPROWADZONYCH ARGUMENTOW                 
        PUSH CX					 ;JEZELI BLEDNE, WYPISUJE ODPOWIEDNI BLAD I PRZEKAZUJE W AL 1 
        PUSH DX
        PUSH SI
        PUSH DI
        PUSH BP
        
        MOV AX, SEG ERR            
        MOV ES, AX
        MOV DS, AX
        MOV AL, ES:LICZNIK
        
        MOV BP, 0
        XOR CX, CX
        
        MOV AL, ES:LICZNIK
        
        CMP AL, 0          ;SPRAWDZENIE, CZY JAKIEKOLWIEK ARGUMENTY ZOSTALY WPISANE
        JE BRAK
        CMP AL, 2
        JE NOD 
        CMP AL, 3
        JNE ILOSC      
        
        MOV AL, BYTE PTR ES:OFFSETY[3]
        CMP AL, 2
        JNE FORM
        MOV SI, WORD PTR ES:OFFSETY[1]
        MOV AX, WORD PTR ES:[SI]
        CMP AX, 642DH
        JNE FORM              
        MOV AL, 1
        MOV BYTE PTR ES:MODE_FLAG, AL
        MOV BP, 3
        
NOD:    MOV CL, BYTE PTR ES:OFFSETY[BP][3]
        CMP CL, 59
        JA INLONG
        MOV SI, WORD PTR ES:OFFSETY[BP][1]
        MOV DI, OFFSET INFILE
INF:    MOV AL, BYTE PTR ES:[SI]
        MOV BYTE PTR ES:[DI], AL
        INC DI
        INC SI
        LOOP INF 
        
        MOV CL, BYTE PTR ES:OFFSETY[BP][6]
        CMP CL, 59
        JA OUTLONG
        MOV SI, WORD PTR ES:OFFSETY[BP][4]
        MOV DI, OFFSET OUTFILE
OUTF:   MOV AL, BYTE PTR ES:[SI]
        MOV BYTE PTR ES:[DI], AL
        INC DI
        INC SI
        LOOP OUTF
          
        MOV AL, 0                     ;WSZYSTKO JEST W PORZADKU
        JMP KON_CH                    ;KONIEC PROCEDURY I KONTYNUACJA PROGRAMU

BRAK:   MOV DX, OFFSET ERR_NOARG     ;NIE MA ARGUMENTU
        JMP BLAD

ILOSC:  MOV DX, OFFSET ERR_ARGCON    ;BLEDNA ILOSC ARGUMENTOW
        JMP BLAD

INLONG: MOV DX, OFFSET ERR_LONGIN    ;WEJSCIOWY ZA DLUGI
        JMP BLAD 
        
OUTLONG:MOV DX, OFFSET ERR_LONGOUT   ;WYJSCIOWY ZA DLUGI
        JMP BLAD

FORM:   MOV DX, OFFSET ERR_ARG       ;BLENDNE ARGUMENTY
        JMP BLAD
        
BLAD:   MOV AH, 9                    ;WYSWIETLENIE BLEDU I PRZEKAZANIE 1 W AL
        INT 21H                   
        MOV DX, OFFSET ERR
        INT 21H  
        MOV AL, 1
        
KON_CH: POP BP
        POP DI
        POP SI
        POP DX
        POP CX 
        RET                         
    ANLSIS_ARGS    ENDP 
    ;----------------------------------------------------
    PROCESS        PROC
        PUSHA  
        
        MOV AX,SEG ARGUMENTY
	    MOV ES, AX
	    MOV DS, AX
        CLD
               	
       	CALL OPEN_INPUT       ;OTWARCIE PLIKU WEJ
       	JC CONEND
       	CALL OPEN_OUTPUT      ;OTWARCIE PLIKU WYJ
       	JC CONEND
        
        XOR AX, AX            ;USTAWIENIE POCZATKOWYCH WARTOSCI REZYDALNYCH
        PUSH AX  
        PUSH AX
        
READP:  MOV CX, BUFFOR_SIZE_IN    ;WCZYTANIE BUFORU WEJSCIOWEGO
        MOV DX, OFFSET BUFFOR_IN      
        MOV BX, ES:INHANDLE
        MOV AH, 3FH
        INT 21H  
    
        JNC INCOR2     
        MOV DX, OFFSET ERR_FILE2
        MOV AH, 9
        INT 21H     
        JMP CONEND          
       
INCOR2: MOV CX, AX        ;SPRAWDZENIE, CZY WCZYTANY BUFOR NIE JEST PUSTY
        CMP AX, 0
        JA READP2
        
        MOV AL, BYTE PTR ES:END_FLAG    ;JEZELI TAK, INICJACJA KONCA PROGRAMU
        CMP AL, 1
        JE ENDREAD
        MOV AL, 1
        MOV BYTE PTR ES:END_FLAG, AL
        
READP2: CALL CONVERT               ;KONWERSJA
        
        MOV DX, OFFSET BUFFOR_OUT  ;ZAPIS BUFORU WYJSCIOWEGO
        MOV BX, ES:OUTHANDLE
        MOV AH, 40H
        INT 21H 
        
        JNC READP     
        MOV DX, OFFSET ERR_FILE3
        MOV AH, 9
        INT 21H     
        JMP CONEND   
       
        
ENDREAD:MOV DX, OFFSET MESS_END
        MOV AH, 9
        INT 21H 
        CALL CLOSE_INPUT        ;ZAMKNIECIE PLIKU WEJSCIOWEGO
        CALL CLOSE_OUTPUT       ;ZAMKNIECIE PLIKU WEJSCIOWEGO
        
CONEND: ADD SP, 4
        POPA
        RET
    PROCESS        ENDP
    ;----------------------------------------------------   
    OPEN_INPUT      PROC
        MOV DX, OFFSET INFILE
        MOV AL, 0
        MOV AH, 3DH
        
        INT 21H     
       
        JNC INCOR     
        MOV DX, OFFSET ERR_FILE
        MOV AH, 9
        INT 21H     
        RET
        
INCOR:  MOV WORD PTR ES:INHANDLE, AX 
        RET
    OPEN_INPUT      ENDP
    ;---------------------------------------------------- 
    OPEN_OUTPUT      PROC

        MOV AH, 43H            ;POBRANIE ATRYBUTOW PLIKU WEJSCIOWEGO
        MOV AL, 0
        MOV DX, OFFSET INFILE
        
        INT 21H 
        
        JNC OUTCOR 
        MOV DX, OFFSET ERR_FILE2
        MOV AH, 9
        INT 21H  
OUTCOR: MOV DX, OFFSET OUTFILE
        MOV AL, 0
        MOV AH, 3CH
        
        INT 21H 
         
        JNC OUTCOR2       
        MOV DX, OFFSET ERR_FILE3
        MOV AH, 9
        INT 21H 
        RET  
        
OUTCOR2:MOV WORD PTR ES:OUTHANDLE, AX
        
        RET
    OPEN_OUTPUT      ENDP
    ;----------------------------------------------------   
    CLOSE_INPUT      PROC              
        MOV BX, WORD PTR ES:INHANDLE
        MOV AH, 3EH
        
        INT 21H
        
        RET
    CLOSE_INPUT      ENDP   
    ;----------------------------------------------------  
    CLOSE_OUTPUT      PROC
        MOV BX, WORD PTR ES:OUTHANDLE
        MOV AH, 3EH
        
        INT 21H
        
        RET
    CLOSE_OUTPUT      ENDP   
    ;----------------------------------------------------
    CONVERT         PROC
        MOV AL, ES:MODE_FLAG
        CMP AL, 0
        JNE DCMP            
        CALL COMPRESS
        RET
DCMP:   CALL DECOMPRESS
        RET   
    CONVERT         ENDP
    ;---------------------------------------------------- 
    COMPRESS        PROC
        PUSHA
        
        MOV DI, OFFSET BUFFOR_IN
        MOV SI, OFFSET BUFFOR_OUT 
        INC CX           ;DLA PORAWNOSCI OPERACJI LANCUCHOWYCH - INKREMENTACJA CX
        XOR AH, AH
        
        MOV BP, SP            ;WCZYTANIE WARTOSCI REZYDALNYCH
        MOV BX, SS:[BP+14H]
        MOV AX, SS:[BP+16H]  
        
        CALL COMPRESS_CARRY   ;WPISANIE WARTOSCI REZYDALNYCH
        
        CMP BX, 0         ;JEZELI SA WARTOSCI REZYDALNE, KONTYNUUJEMY
        JA COMLP2
        
COMLP:  MOV AL, ES:[DI]   ;WCZYTANIE PIERWSZY ZNAK SERII
COMLP2: ADD BX, CX       ;BX - OBECNA ILOSC NIESPRAWDZONYCH BAJTOW W BUFORZE I REZYDALNYCH
        REPE SCASB       ;PRZEJSCIE PRZEZ SERIE TAKICH SAMYCH ZNAKOW
        JCXZ CMEND       
        DEC DI           ;DLA PORAWNOSCI OPERACJI LANCUCHOWYCH - DEKREMENTACJA DX I INKREMENTACJA CX
        INC CX
        
        SUB BX, CX       ;OBLICZENIE ILOSCI ZNAKOW W SERII 
        
        CALL COMPRESS_SERIES      ;KOMPRESJA SERII
        JMP COMLP   
        
CMEND:  DEC BX                  ;KONIEC BUFORU
        MOV DL, BYTE PTR ES:END_FLAG
        CMP DL, 0      ;SPRAWDZENIE, CZY NIE KONIEC PROGRAMU 
        JE CMEND2       ;JEZELI NIE, ZAPISANIE WARTOSCI REZYDALNYCH
        CALL COMPRESS_SERIES   ;JEZELI TAK, ZAPIS OSTATNIEJ SERII
        JMP CMEND3
        
CMEND2: MOV SS:[BP+14H], BX  ;ZAPIS WARTOSCI REZYDALNYCH
        MOV SS:[BP+16H], AX                        
                              
CMEND3: MOV CX, SI          ;SPRAWDZNIE ILOSCI ZAPISANYCH BAJTOW
        MOV SI, OFFSET BUFFOR_OUT 
        SUB CX, SI
        MOV BP, SP 
        MOV WORD PTR SS:[BP + 12], CX  ;WPROWADZENIE ILOSCI DO CX
        POPA                              
        RET
    COMPRESS        ENDP
    ;---------------------------------------------------- 
    COMPRESS_SERIES        PROC
        
        CMP BX, 3       ;MOZLIWE PRZYPADKI
        JA COMSR 
        
        CMP AL, 0
        JE CMZERO   
        
CMNOCON:MOV BYTE PTR ES:[SI], AL    ;KOMPRESJA POJEDYNCZEGO ZNAKU
        INC SI   
        DEC BX
        CMP BX, 0
        JA CMNOCON
        RET

CMZERO: CMP BX, 1                ;KOMPRESJA ZERA
        JA COMSR
        MOV WORD PTR ES:[SI], AX
        INC SI
        INC SI  
        DEC BX
        RET
        
COMSR:  XOR DX, DX           ;KOMPRESJA SERII
        CMP BX, 0FFH
        JBE COMSR2
        MOV DX, BX           ;PRZYPADEK DLA SERII DLUZSZEJ OD 255
        MOV BX, 0FFH         
        SUB DX, 0FFH

COMSR2: MOV BYTE PTR ES:[SI], AH     
        INC SI
        MOV BYTE PTR ES:[SI], BL
        INC SI
        MOV BYTE PTR ES:[SI], AL
        INC SI
        MOV BX, DX
        CMP BX, 0
        JA COMSR
        
        RET
    COMPRESS_SERIES        ENDP 
    ;---------------------------------------------------- 
    COMPRESS_CARRY    PROC
CCARST: CMP BX, 1FEH         ;SPRAWDZENIE, CZY NIE SERIA REZYDALNA NIE JEST ZA DUZA
        JB CCAREND
        PUSH BX
        MOV BX, 1FEH
        CALL COMPRESS_SERIES    ;JEZELI TAK, CZESC KOMPRESUJEMY
        POP BX
        SUB BX, 1FEH
        JMP CCARST
        
CCAREND:RET
    COMPRESS_CARRY    ENDP 
    ;---------------------------------------------------- 
    DECOMPRESS        PROC
        PUSHA
        
        MOV DI, OFFSET BUFFOR_IN     
        MOV SI, OFFSET BUFFOR_OUT
        MOV DX, BUFFOR_SIZE_OUT
        
        MOV BP, SP          ;POBRANIE WARTOSI REZYDALNYCH
        MOV AX, SS:[BP+20] 
        CMP AL, 0     ;ZALEZNIE OD WARTOSCI REZYDALNYCH, ROZPOCZECIE OD ODPOWIEDNIEGO MIEJSCA
        JE DCMLP
        CMP AH, 0
        JE DCMZER0
        JNE DCMPS
        
DCMLP:  JCXZ DCMEND       ;JEZELI BUFOR PUSTY, KONIEC BEZ REZDALNYCH
        
        MOV AH, BYTE PTR ES:[DI]   ;POBOR BAJTU
        INC DI
        DEC CX
        
        CMP AH, 0      ;JEZELI NIE ZERO, DEKOMPRESJA POJEDYNCZEGO BAJTU
        JNE DCMPJ
        
        JCXZ DCMIS
        
DCMZER0:MOV AH, BYTE PTR ES:[DI]   
        INC DI
        DEC CX
        
        CMP AH, 0
        JE DCMPJ      ;JEZELI ZERO, DEKOMPRESJA ZERA
        
        JCXZ DCMIS 
        
DCMPS:  MOV BL, AH         ;DEKOMPRESJA SERII
        MOV AH, BYTE PTR ES:[DI]
        INC DI
        DEC CX 
        
        CALL DECOMPRESS_SERIES   
        JMP DCMLP

DCMPJ:  MOV BL, 1       ;DEKOMPRESJA POJEDYNCZEGO BAJTU
        CALL DECOMPRESS_SERIES
        JMP DCMLP 
        
DCMIS:  MOV AL, 1    ;KONIEC BUFORU, BRAKUJE BAJTU
        JMP DCMEND2
        
DCMEND: XOR AL, AL
DCMEND2:MOV WORD PTR SS:[BP + 20], AX  ;ZAPISANE WARTOSCI REZYDALNYCH
        MOV CX, SI
        MOV SI, OFFSET BUFFOR_OUT 
        SUB CX, SI       ;OBLICZENIE ILOSCI ZAPISANYCH BAJTOW
        MOV BP, SP 
        MOV WORD PTR SS:[BP + 12], CX
        
        POPA
        RET
    DECOMPRESS        ENDP
  ;----------------------------------------------------
    DECOMPRESS_SERIES       PROC
        PUSH CX
        
DCMPSR1:XOR BH, BH    ;SPRAWDZNIE, CZY SERIA DO ZAPISU ZMIESCI SIE W BUFORZE
        CMP BX, DX
        JAE DCMPSR2
        
        MOV CX, BX    ;ZMIESCI SIE 
        SUB DX, BX
        JMP DCMPSR3
        
DCMPSR2:MOV CX, DX   ;NIE ZMIESCI SIE
        SUB BX, DX 
        XOR DX, DX       
         
DCMPSR3:JCXZ DCMPSR4         ;ZAPIS SERII
        MOV BYTE PTR ES:[SI], AH  
        INC SI
        LOOP DCMPSR3
        
        CMP DX, 0      
        JA DCMPSR4 
        
        CALL WRITE_BUFFOR  ;JEZLI BUFOR WYJ ZAPELNIONY, ZAPISUJEMY GO
        JMP DCMPSR1
        
DCMPSR4:POP CX
        RET
    DECOMPRESS_SERIES       ENDP
  ;----------------------------------------------------
    WRITE_BUFFOR        PROC
        PUSH AX
        PUSH BX        ;ZAPISUJEMY CALY BUFOR WYJSCIOWY
                
        MOV CX, BUFFOR_SIZE_OUT
        MOV DX, OFFSET BUFFOR_OUT
        MOV BX, ES:OUTHANDLE
        MOV AH, 40H
        INT 21H   
        
        POP BX
        POP AX
        MOV SI, OFFSET BUFFOR_OUT
        MOV DX, BUFFOR_SIZE_OUT
        
        RET 
    WRITE_BUFFOR        ENDP
  ;------------------------KONIEC PROCEDUR------------------------  
CODE1   ENDS


STOS1   SEGMENT STACK
        DW 200 DUP(?)
WSTOSU  DW ?
STOS1   ENDS
       
END     START
