;Tomasz Kasprzycki
;Task 3. - Julia set

.186
DATA1   SEGMENT

LICZNIK     DB  ?
ARGUMENTY   DB  256 DUP('$')
OFFSETY     DB  256 DUP(0)
ERR_NOARG   DB  "BLAD: NIE PODANO ZADNYCH ARGUMENTOW.$"
ERR_ARGCON  DB  "BLAD: PODANO BLEDNA ILOSC ARGUMENTOW.$"
ERR_FORM    DB  "BLAD: FORMAT PODANYCH LICZB JEST NIEPRAWIDLOWY.$"
ERR         DB  13,10,"SYNTAX: ZBI0R_JULII.EXE XMIN XMAX YMIN YMAX CR CI",13,10,'$' 
XMIN        DQ  ?
XMAX        DQ  ?
YMIN        DQ  ?
YMAX        DQ  ?
CR          DQ  ?
CI          DQ  ?
COL         DB  ?

    
DATA1   ENDS
    
CODE1   SEGMENT 
        
    ASSUME ES:DATA1,CS:CODE1,SS:STOS1 

START:  MOV AX, SEG WSTOSU    ;INICJACJA STOSU
        MOV SS, AX
        MOV SP, OFFSET WSTOSU
        FINIT
       
        CALL PARSE_ARGS  ;PARSOWANIE ARGUMENTOW
        CALL ANLSIS_ARGS ;SPRAWDZENIE ARGUMENTOW
        CMP AL, 1        ;JEZELI NIE POPRAWNE, KONIEC PROGRAMU  
        JE KONIEC             
        CALL CONVERT_ARGS     ;KONWERSJA PLIKU
        CALL DRAW_SET

KONIEC: MOV AH, 4CH      ;KONIEC PROGRAMU
        INT 21H                                                   
        
  ;---------------------------MAKRA---------------------------
    SKIP_WHITESPACE     MACRO        ;PRZESUWA SI NA WSKAZANIE NASTEPNEGO ZNAKU NIE BEDACEGO BIALYM ZNAKIEM 
       
        LOCAL WHITE, WSP, ENDSK
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

    ENDM
    ;--------------------------------------------------
    SET_ARGUMENT_OFFSET     MACRO

        MOV AX, CX
        MOV BX, 3
        MUL BX
        MOV SI, AX  ;WYZNACZNIE OFFSETU ARGUMENTY LINI POLECEŃ
        MOV CL, BYTE PTR ES:OFFSETY[SI][3]
        MOV SI, WORD PTR ES:OFFSETY[SI][1]

    ENDM
    ;--------------------------------------------------
    DRAW_POINT      MACRO
        PUSHA

        MOV BX,DX   ;WYZNACZNIE OFFSETU PIXELA
        MOV AX,CX
        MOV BP, 320
        MUL BP
        ADD BX, AX
        MOV AL, BYTE PTR ES:COL
        MOV BYTE PTR DS:[BX],AL

        POPA
    ENDM
  ;----------------------------------------------------
    GET_COORDINATES         MACRO

        FLD QWORD PTR ES:XMIN   ;WYZNACZENIE WSPÓŁRZĘDNEJ X
        FLD QWORD PTR ES:XMAX
        FLD QWORD PTR ES:XMIN
        FSUB
        MOV WORD PTR CS:TMP, DX
        FILD WORD PTR CS:TMP
        FMUL
        MOV WORD PTR CS:TMP, 320
        FILD WORD PTR CS:TMP
        FDIV
        FADD
        FSTP QWORD PTR CS:X

        FLD QWORD PTR ES:YMIN   ;WYZNACZENIE WSPÓŁRZĘDNEJ Y
        FLD QWORD PTR ES:YMAX
        FLD QWORD PTR ES:YMIN
        FSUB
        MOV WORD PTR CS:TMP, CX
        FILD WORD PTR CS:TMP
        FMUL
        MOV WORD PTR CS:TMP, 200
        FILD WORD PTR CS:TMP
        FDIV
        FADD
        FSTP QWORD PTR CS:Y

    ENDM
  ;-----------------------------------------
  MAIN_CALCULATIONS         MACRO

        FLD QWORD PTR CS:X
        FLD QWORD PTR CS:X
        FMUL
        FLD QWORD PTR CS:Y
        FLD QWORD PTR CS:Y
        FMUL
        FSUB
        FLD QWORD PTR ES:CR
        FADD
        FSTP QWORD PTR CS:TMPQ

        FILD WORD PTR CS:TWO
        FLD QWORD PTR CS:X
        FMUL
        FLD QWORD PTR CS:Y
        FMUL
        FLD QWORD PTR ES:CI
        FADD
        FSTP QWORD PTR CS:Y

        FLD QWORD PTR CS:TMPQ
        FST QWORD PTR CS:X
        FLD QWORD PTR CS:TMPQ
        FMUL
        FLD QWORD PTR CS:Y
        FLD QWORD PTR CS:Y
        FMUL
        FADD

  ENDM
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
        
POCZ:   SKIP_WHITESPACE 
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
  ;----------------------------------------------------
    ANLSIS_ARGS    PROC         ;SPRAWDZA POPRAWNOSC WPROWADZONYCH ARGUMENTOW                 
        PUSHA					 ;JEZELI BLEDNE, WYPISUJE ODPOWIEDNI BLAD I PRZEKAZUJE W AL 1 
        
        MOV AX, SEG ERR            
        MOV ES, AX
        MOV DS, AX
        
        MOV AL, ES:LICZNIK
        CMP AL, 0
        JE BRAK
        CMP AL, 6
        JNE ILOSC    
        
        MOV CX, 6
CHECK_LOOP:         ;PETLA PRZECHODZI PO WSZYSTKICH ARGUMENTACH
        CALL CHECK_REAL
        CMP AL, 1
        JE FORM
        LOOP CHECK_LOOP
          
        POPA
        MOV AL, 0                     ;WSZYSTKO JEST W PORZADKU
        RET                    ;KONIEC PROCEDURY I KONTYNUACJA PROGRAMU

BRAK:   MOV DX, OFFSET ERR_NOARG     ;NIE MA ARGUMENTU
        JMP BLAD

ILOSC:  MOV DX, OFFSET ERR_ARGCON    ;BLEDNA ILOSC ARGUMENTOW
        JMP BLAD

FORM:   MOV DX, OFFSET ERR_FORM    ;BLEDNA FORMA ARGUMENTOW
        JMP BLAD                                              

BLAD:   MOV AH, 9                    ;WYSWIETLENIE BLEDU I PRZEKAZANIE 1 W AL
        INT 21H                   
        MOV DX, OFFSET ERR
        INT 21H  
        POPA
        MOV AL, 1
        RET                         
    ANLSIS_ARGS    ENDP 
  ;----------------------------------------------------
    CHECK_REAL      PROC
        PUSH CX
        
        DEC CX
        SET_ARGUMENT_OFFSET
        MOV AL, BYTE PTR ES:[SI]
        CMP AL, '-'     ;SPRAWDZENIE, CZY JEST UJEMNA
        JNE REAL_LOOP1
        INC SI
        DEC CX
        JCXZ REAL_INCORRECT

REAL_LOOP1:         ;CYFRY PRZED PRZECINKIEM
        MOV AL, BYTE PTR ES:[SI]
        CMP AL, '.'
        JE REAL_LOOP21
        CMP AL, '0'
        JB REAL_INCORRECT
        CMP AL, '9'
        JA REAL_INCORRECT
        INC SI
        LOOP REAL_LOOP1
        JMP REAL_INCORRECT 
REAL_LOOP21: INC SI
        DEC CX
        JCXZ REAL_CORRECT
REAL_LOOP22:            ;CYFRY PO PRZECINKU
        MOV AL, BYTE PTR ES:[SI]
        CMP AX, '0'
        JB REAL_INCORRECT
        CMP AX, '9'
        JA REAL_INCORRECT
        INC SI
        LOOP REAL_LOOP22

REAL_CORRECT:        
        MOV AL, 0
        JMP ENDREAL       
REAL_INCORRECT:
        MOV AL, 1
ENDREAL:POP CX
        RET
    CHECK_REAL      ENDP
  ;----------------------------------------------------
    CONVERT_ARGS    PROC
        PUSHA

        MOV CX, 6
CONVERT_LOOP:       ;PETLA PRZECHODZI PO WSZYSTKICH LICZBACH
        CALL CONVERT_ARG
        LOOP CONVERT_LOOP

        POPA
        RET
    CONVERT_ARGS    ENDP
  ;----------------------------------------------------
    CONVERT_ARG     PROC
        PUSH CX

        DEC CX
    DRAW_POINT      MACRO
        PUSHA

        MOV BX,DX   ;WYZNACZNIE OFFSETU PIXELA
        MOV AX,CX
        MOV BP, 320
        MUL BP
        ADD BX, AX
        MOV AL, BYTE PTR ES:COL
        MOV BYTE PTR DS:[BX],AL

        POPA
    ENDM
  ;----------------------------------------------------
        MOV AX, CX
        MOV BX, 8
        MUL BX
        MOV DI, AX  ;WYZNACZENIE OFFSETU ZMIENNEJ
        SET_ARGUMENT_OFFSET
        MOV DL, 0
        FLDZ    ;DO KOPROCESORA POCZĄTKOWO WKŁADAMY ZERO
        XOR AH, AH
        
        MOV AL, BYTE PTR ES:[SI]
        CMP AL, '-'     ;JEZELI UJEMNE, TO DL = 1, JEZELI NIE DL = 0
        JNE ARG_LOOP1
        MOV DL, 1
        INC SI
        DEC CX
        JCXZ ARG_LOOP_END

ARG_LOOP1:  ;CYFRY PRZED PRZECINKIEM
        MOV AL, ES:[SI]
        CMP AL, '.'
        JE ARG_LOOP21
        SUB AL, 30H
        MOV CS:[TMP], AX
        FILD CS:[TEN]
        FMUL
        FILD CS:[TMP]
        FADD
        INC SI
        LOOP ARG_LOOP1
ARG_LOOP21:     ;CYFRY PO PRZECINKU
        XOR BX, BX
        FLDZ
        INC SI
        DEC CX
        JCXZ ARG_LOOP3
ARG_LOOP22:
        INC BX
        MOV AL, ES:[SI]
        SUB AL, 30H
        MOV CS:[TMP], AX
        FILD CS:[TEN]
        FMUL
        FILD CS:[TMP]
        FADD
        INC SI
        LOOP ARG_LOOP22

        MOV CX, BX
ARG_LOOP3:      ;LICZY PO PRZECINKU DZILIMY PRZEZ 10, AŻ <0
        FILD CS:[TEN]
        FDIV
        LOOP ARG_LOOP3

ARG_LOOP_END:
        FADD    ;DODAJEMY CZĘŚĆ CAŁKOWITĄ DO UŁAMKOWEJ
        CMP DL, 0
        JE ARG_END
        FLDZ    ;JEZELI JEST '-', TO ODJEMUJEMY OD ZERA
        FSUB ST(0), ST(1)

ARG_END:FSTP QWORD PTR ES:XMIN[DI]
        POP CX
        RET
    CONVERT_ARG     ENDP
  ;----------------------------------------------------
    DRAW_SET        PROC
        PUSH AX
        PUSH BX
        PUSH CX
        PUSH DX

        MOV AL, 13H  ;WŁĄCZNEIE TRYBU GRAFICZNEGO
        MOV AH, 0
        INT 10H
        
        MOV AX, 0A000H   ;SEGMENT PAMIĘCI VGA
        MOV DS, AX

        MOV CX, 320
DRAW_LOOP1:
        PUSH CX
        MOV DX, CX
        MOV CX, 200 ;X:Y = DX:CX
DRAW_LOOP2:
        CALL GET_COLOUR     ;WYZNACZNIE KOLORU
        DRAW_POINT     ;NARYSOWANIE PUNKTU

        LOOP DRAW_LOOP2
        POP CX
        LOOP DRAW_LOOP1

        MOV AH, 1           ;OCZEKIWANIE NA NACIŚNIĘCIE KLAWISZA
        INT 21H

        MOV AL, 3           ;WYŁĄCZENIE TRYBU GRAFICZNEGO
        MOV AH, 0
        INT 10H

        POP DX
        POP CX
        POP BX
        POP AX
    DRAW_SET        ENDP
  ;----------------------------------------------------
    GET_COLOUR      PROC
        PUSH CX

        GET_COORDINATES

        MOV CX, 1000
COLOUR_LOOP:
        MAIN_CALCULATIONS

        FILD WORD PTR CS:FOUR   ;PORÓWNIANIE Z 4
        FCOM
        FSTSW WORD PTR CS:TMP
        MOV AX, CS:TMP

        SAHF    ;PRZENIESIENIE ZNCZNIKÓW KOPROCESORA DO ZNACZNIKÓW PROCESORA
        JB COLOUR_LOOP_END

        DEC CX
        CMP CX, 0
        JNE COLOUR_LOOP

COLOUR_LOOP_END:
        CMP CX, 0
        JNE COLOUR_BLACK
        MOV ES:COL, 0FH
        POP CX
        RET
COLOUR_BLACK:
        MOV ES:COL, 0
        POP CX
        RET
    GET_COLOUR      ENDP
  ;------------------------KONIEC PROCEDUR------------------------  
TWO     DW  2
FOUR    DW  4
TEN     DW  10
TMP     DW  ?
TMPQ    DQ  ?
X       DQ  ?
Y       DQ  ?
CODE1   ENDS


STOS1   SEGMENT STACK
        DW 200 DUP(?)
WSTOSU  DW ?
STOS1   ENDS
       
END     START
