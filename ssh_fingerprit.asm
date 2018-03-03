;Tomasz Kasprzycki
;Task 1. - SSH FINGERPRINT
;

.186
DATA1   SEGMENT

LICZNIK     DB  ?
ARGUMENTY   DB  255 DUP('$')
OFFSETY     DB  255 DUP(0)
ERR_NOARG   DB  "BLAD: NIE PODANO ZADNYCH ARGUMENTOW.$"
ERR_ARGCON  DB  "BLAD: PODANO BLEDNA ILOSC ARGUMENTOW.$"
ERR_ARGMAN  DB  "BLAD: PODANE SA ARGUMENTY ZA DLUGIE.$"
ERR_ARGFEW  DB  "BLAD: PODANE SA ARGUMENTY ZA KROTKIE.$"
ERR_ARG     DB  "BLAD: PODANO NIEPRAWIDLOWE ARGUMENTY.$"
ERR         DB  13,10,"SYNTAX: FILENAME.EXE TRYB KLUCZ",13,10,"TRYB = [0-1], KLUCZ = 32[0-9,a-f,A-F]$"
FLAG        DB  ?
KEY         DB  16 DUP(?)
FRAME       DB  "+-----------------+",13,10,'$'
BOARD       DB  153 DUP(0)
SYMBOL      DB  ' ','.','o','+','=','*','B','O','X','@','%','&','#','/','^'
ENDC        DB  ?
    
DATA1   ENDS
    
CODE1   SEGMENT 
        
        ASSUME ES:DATA1,CS:CODE1,SS:STOS1

START:  MOV AX, SEG WSTOSU    ;INICJACJA STOSU
        MOV SS, AX
        MOV SP, OFFSET WSTOSU
        
        
        CALL PARSE_ARGS  ;PARSOWANIE ARGUMENTOW
        CALL CHECK_ARGS  ;SPRAWDZENIE ARGUMENTOW
        CMP AL, 1        ;JEZELI NIE POPRAWNE, KONIEC PROGRAMU
        JE KONIEC
        CALL TRANS_ARGS  ;ARGUMENTY SA POPRAWNE, WIEC PRZENIESIENIE DO ZMIENNYCH
        CALL MAKE_MOVES  ;SPRAWDZENIE, ILE RAZY NA KAZDYM POLU BYL SKOCZEK
        CALL MAKE_BOARD  ;WSTAWIENIE ODPOWIENICH SYMBOLI
        CALL DRAW_BOARD  ;RYSOWANIE SZACHOWNICY
        
KONIEC: MOV AH, 4CH      ;KONIEC PROGRAMU
        INT 21H                                                   
        
  ;---------------------------PROCEDURY---------------------------
    PARSE_ARGS           PROC
        PUSHA
       
	    MOV AH, 62H			;DO DS ADRES SEGMENTU POCZĄTKOWEGO
		INT 21H
		MOV DS, BX
		
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
    CHECK_ARGS     PROC         ;SPRAWDZA POPRAWNOSC WPROWADZONYCH ARGUMENTOW                 
        PUSH CX					 ;JEZELI BLEDNE, WYPISUJE ODPOWIEDNI BLAD I PRZEKAZUJE W AL 1 
        PUSH DX
        PUSH SI
        
        MOV AX, SEG ERR            
        MOV DS, AX
        MOV AL, ES:LICZNIK ;ES:SI WSKAZUJE NA ARGUMENTY Z LINI POLECEN
        
        CMP AL, 0          ;SPRAWDZENIE, CZY JAKIEKOLWIEK ARGUMENTY ZOSTALY WPISANE
        JE BRAK  
        CMP AL, 1
        JE ILOSC
        CMP AL, 2
        JG ILOSC          
        
        MOV AL, OFFSETY[3]		;CZY FLAGA NIE ZA DLUGA
        CMP AL, 1
        JNE DUZO
        
        MOV AL, OFFSETY[6]		;CZY KLUCZ NIE ZA DLUGI/KROTKI
        CMP AL, 32
        JG DUZO
        JL MNIEJ

        MOV SI, WORD PTR OFFSETY[1]
        MOV AL, ES:[SI]
        CMP AL, '0'
        JE FORM                     ;SPRAWDZENIE, CZY FLAGA TO 0 LUB 1
        CMP AL, '1'         
        JNE FORMB                   ;JEZELI NIE, KONIEC PROGRAMU
        
FORM:   MOV SI, WORD PTR OFFSETY[4]  
        MOV CX, 20H                        

FORM2:  MOV AL, ES:[SI]              ;PETLA SPRAWDZA, CZY KOLEJNE ZNAKI SA CYFRAMI HEKSADECYMALNYMI
        CALL CHECK_HEX               
        CMP AL, 0
        JNE FORMB
        INC SI                     
        LOOP FORM2
        
        POP SI
        POP DX
        POP CX
        MOV AL, 0                    ;WSZYSTKO JEST W PORZADKU
        RET                          ;KONIEC PROCEDURY I KONTYNUACJA PROGRAMU

BRAK:   MOV DX, OFFSET ERR_NOARG     ;NIE MA ARGUMENTU
        JMP BLAD

ILOSC:  MOV DX, OFFSET ERR_ARGCON    ;ZA DUZA ILOSC ARGUMENTOW
        JMP BLAD

MNIEJ:  MOV DX, OFFSET ERR_ARGFEW    ;ZA MALA ILOSC ZNAKOW
        JMP BLAD 
        
DUZO:   MOV DX, OFFSET ERR_ARGMAN    ;ZA DUZA ILOSC ARGUMENTOW
        JMP BLAD

FORMB:  MOV DX, OFFSET ERR_ARG
        JMP BLAD
        
BLAD:   MOV AH, 9                    ;WYSWIETLENIE BLEDU I PRZEKAZANIE 1 W AL
        INT 21H                   
        MOV DX, OFFSET ERR
        INT 21H
        
		POP SI
        POP DX
        POP CX
        MOV AL, 1 
        RET                         
    CHECK_ARGS     ENDP 
    ;----------------------------------------------------
    CHECK_HEX      PROC             ;SPRAWDZA, CZY SYMBOL ASCII PRZEKAZANY PRZEZ AL NALEZY DO CYFR HEKSDECYMALNYCH
        CMP AL, 30H                 ;JEZELI TAK, ZWRACA W AL 0
        JL INCOR ;MNIEJSZE OD '0'   ;JEZELI NIE, ZWRACA W AL 1
        CMP AL, 66H                 
        JG INCOR ;WIEKSZE OD 'f'
        CMP AL, 3AH
        JL CORR  ;NALEZY DO CYFR
        CMP AL, 60H
        JG CORR  ;NALEZY DO MALYCH LITER
        CMP AL, 41H
        JL INCOR ;NIE NALEZY DO WIELKI LITER
        CMP AL, 47H
        JL CORR  ;NALEZY DO WIELKICH LITER

INCOR:  MOV AL, 1
        RET      
        
CORR:   MOV AL, 0        
        RET
    CHECK_HEX      ENDP
    ;-------------------------------------------------- 
    TRANS_ARGS     PROC       ;KONWERTUJE KLUCZ Z ARGUMENTU NA BINARNY I UMIESZCZA GO W 'KEY', A ZNACZNIK TRYBU W 'FLAG'
        PUSH AX
        PUSH CX
        PUSH DI 
        PUSH SI
        
        MOV SI, WORD PTR ES:OFFSETY[1]   ;USTAWIA FLAGE ZGODNIE Z ARGUMENTEM
        MOV AL, ES:[SI]
        AND AL, 1
        MOV BYTE PTR ES:FLAG, AL
        
        MOV DI, OFFSET KEY      
        MOV CX, 10H           ;PETLA WPISUJACA DO 'KEY' KLUCZ W POSTACI BINARNEJ
        
        MOV SI, WORD PTR ES:OFFSETY[4]
        
PKEY:   PUSH WORD PTR ES:[SI] ;JAKO PARAMETR PRZEKAZUJE DWA ZNAKI PRZEZ STOS
        CALL HEX2BIN_BYTE
        POP AX
        MOV DS:[DI], AL       ;BAJT ZAPISYWANY JAKO KOLEJNY ELEMENT 'KEY'
        INC DI              
        ADD SI, 2
        LOOP PKEY
        
        POP SI
        POP DI
        POP CX
        POP AX
        RET       
    TRANS_ARGS     ENDP
    ;---------------------------------------------------- 
    HEX2BIN_BYTE   PROC       ;KONWERTUJE DWA ZNAKI ASCII NA BINARNE
        PUSH BP                 ;PRZYJMUJE ICH WARTOSCI PRZEZ STOS, ZWRACANA WARTOSC NADPISUJE NA PARAMETRZE W STOSIE
        PUSH BX
        PUSH AX      
        
        MOV BP, SP
        MOV BX, SS:[BP + 8]  ;ADRES PRZEKAZANEGO PARAMETRU
        CALL HEX2BIN
        MOV AL, BL            ;W BL JEST BIN PIERWSZEJ CYFRY
        SHL AL, 4             ;PRZESUNIECIE W LEWO, ZEBY PIERWSZA CYFRA ZNALAZLA SIE NA 4 STARSZYCH BITACH AL
        MOV BL, BH
        CALL HEX2BIN          ;W BL JEST BIN DRUGIEJ CYFRY
        ADD AL, BL            ;DRUGA CYFRA ZNAJDUJE SIE NA 4 MLODSZYCH BITACH AL
        MOV SS:[BP + 8], AX  ;UMIESZCZENIE WYNIK NA MIEJSCE PARAMETRU NA STOSIE
    
        POP AX
        POP BX
        POP BP
        RET
    HEX2BIN_BYTE   ENDP
    ;----------------------------------------------------
    HEX2BIN        PROC       ;KONWERTUJE POJEDYNCZA CYFRE ASCII Z BL NA BINARNE I UMIESZCZA W BL 
        CMP BL, 3AH
        JL CYFR
        CMP BL, 47H
        JL CAPIT
        
        SUB BL, 57H     ;KONWERSJA MALYCH LITER
        RET
        
CAPIT:  SUB BL, 37H     ;KONWERSJA WIELKICH LITER
        RET
        
CYFR:   SUB BL, 30H     ;KONWERSJA CYFR
        RET
    HEX2BIN        ENDP
    ;----------------------------------------------------
    MAKE_MOVES     PROC         ;ZAPISUJE W 'BOARD' ILOSC ODWIEDZEN KAZDEGO POLA
        PUSHA                   
        
        ASSUME ES:DATA1
        MOV AX, SEG KEY         ;ES:SI WSKAZUJE NA BAJTY W 'KEY'
        MOV ES, AX
        MOV SI, OFFSET KEY
        
        MOV AX, SEG BOARD       ;[BP][DI] WSKAZUJE NA ODPOWIEDNIE POLA SZACHOWNICY W 'BOARD'
        MOV DS, AX              ;[X][Y] - NOTACJA W MACIERZY
        MOV BP, 4               ;[4][8] - POLE STARTU
        MOV DI, 8
        
        XOR AX, AX               
        MOV CX, 10H

MOVE:   MOV AL, BYTE PTR ES:[SI] ;POBRANIE JEDNEGO BAJTU Z 'KEY'
        PUSH CX
        MOV CX, 4

MOVE1:  CALL FETCH2BITS          ;DLA KAZDEGO BAJTA 4 RAZY POBRANIE PO 2 BITY
        CALL ONEMOVE             ;WYKONANIE POJEDYNCZEGO RUCHU
        LOOP MOVE1
        
        POP CX                   ;BAJT SKONCZONY
        INC SI                   ;PRZEJSCIE DO KOLEJNEGO
        LOOP MOVE
        
        CALL MARK_END            ;ZACHOWANIE OSTATNIEJ POZYCJI
         
        POPA
        RET
    MAKE_MOVES     ENDP
    ;----------------------------------------------------
    FETCH2BITS     PROC        ;DO AH PRZENOSI DWA BITY KODUJACE KIERUNEK KOLEJNEGO SKOKU, PRZYJMUJE BAJT W AL
       
        XOR AH, AH          ;????????:ABCDEFGH -> 00000000:ABCDEFGH  ;ZAPIS BINARNY AX
        ROR AX, 2           ;00000000:ABCDEFGH -> GH000000:00ABCDEF
        SHR AH, 6           ;GH000000:00ABCDEF -> 000000GH:00ABCDEF
        
        RET
    FETCH2BITS     ENDP     
    ;----------------------------------------------------
    ONEMOVE        PROC        ;WYKOUJE POJEDYNCZY RUCH SKOCZKIEM I ZWIEKSZA ODPOWIEDNIE POLE W 'BOARD'
        PUSH AX                ;PRZYJMUJE NUMER KIERUNKU SKOKU W AH
        PUSH BX
        PUSH CX
        PUSH DX                
        PUSH SI
              
        CALL SET_DIR_PARAM     ;PRZENIESIENIE GRANICZNYCH WARTOSCI SZACHOWNICY DO BX I DX
        CALL CHECK_CORNER      ;SPRAWDZENIE, CZY SKOCZEK NIE JEST W ROGU
        CMP AL, 1              ;JEST - KONIEC RUCHU
        JE ENDMOVE
        
        CALL NEXT_SQUARE       ;NIE JEST - OBLICZENIE KOLEJNEGO POLA 
        CALL INC_SQUARE        ;INKREMENTACJA LICZNIKA ODWIEDZIN TEGO POLA      

ENDMOVE:POP SI
        POP DX
        POP CX
        POP BX
        POP AX
        RET
    ONEMOVE        ENDP
    ;----------------------------------------------------    
    SET_DIR_PARAM   PROC    ;USTAWIA PARAMETRY DO SPRAWDZNIA, CZY ZNAJDUJE SIE W ROGU
                            ;PRZYJMUJE NUMER KIERUNKU SKOKU W AH
        CMP AH, 0    ;SPRAWDZENIE, W KTORA STRONE KIERUJE SIE SKOCZEK
        JE ZERO
        CMP AH, 1
        JE ONE
        CMP AH, 2
        JE TWO
        JMP THREE
        
ZERO:   MOV BX, 0        ;GRANICZNE POZYCJE SZACHOWNICY
        MOV DX, 0
        RET
       
ONE:    MOV BX, 0
        MOV DX, 16
        RET

TWO:    MOV BX, 8
        MOV DX, 0
        RET
          
THREE:  MOV BX, 8
        MOV DX, 16
        RET
    SET_DIR_PARAM   ENDP
    ;----------------------------------------------------
    CHECK_CORNER   PROC  ;SPRAWDZA CZY DS:[BP][DI] WSKAZUJE NA RG, ZWRACA W AL 0 JEZELI NIE, 1 JEZELI TAK
        CMP BP, BX      ;JEZELI NIE NA POZIOMEJ KRAWEDZI, TO NIE W ROGU
        JNE NCOR
        CMP DI, DX      ;JEZELI NIE NA PIONOWEJ KRAWEDZI, TO NIE W ROGU
        JNE NCOR
        
        MOV AL, 1       ;NA OBU KRAWEDZIACH, WIEC W ROGU
        RET
NCOR:   MOV AL, 0       ;NIE W ROGU
        RET
    CHECK_CORNER   ENDP
    ;----------------------------------------------------
    NEXT_SQUARE         PROC    ;USTAWIA BP I DI NA KOLEJNA POZYCJE SKOCZKA
        CALL SET_MOVE           ;PRZYJMUJE NUMER KIERUNKU SKOKU W AH
                                ;DO CX ZWRACA ODLEGLOSC SKOKU, ZALEZNIE OD TRYBU
        CMP AH, 0
        JE TOP0          ;SPRAWDZENIE, W KTORA STRONE KIERUJE SIE SKOCZEK
        CMP AH, 1
        JE TOP1
        CMP AH, 2
        JE DOWN2
        JMP DOWN3
                        ;00
TOP0:   CMP BP, BX      ;JEZELI NA POZIOMEJ KRAWEDZI,
        JE LEFT0        ;TO SKOCZEK NIE PORUSZA SIE W PIONIE
        DEC BP
        LOOP TOP0       ;ZGODNIE Z DLUGOSCIA SKOKU, SKOCZEK MOZE PORUSZYC SIE PONOWNIE
LEFT0:  CALL SET_MOVE 
LEFT0P: CMP DI, DX      ;JEZELI NA PIONOWEJ KRAWEDZI,
        JE MOVEND       ;TO SKOCZEK NIE PORUSZA SIE W POZIOMIE
        DEC DI
        LOOP LEFT0P
        RET
       
TOP1:   CMP BP, BX      ;01
        JE RIGHT1
        DEC BP
        LOOP TOP1
RIGHT1: CALL SET_MOVE
RIGHT1P:CMP DI, DX
        JE MOVEND
        INC DI
        LOOP RIGHT1P
        RET

DOWN2:  CMP BP, BX      ;10
        JE LEFT2
        INC BP
        LOOP DOWN2
LEFT2:  CALL SET_MOVE 
LEFT2P: CMP DI, DX
        JE MOVEND
        DEC DI
        LOOP LEFT2P
        RET
                
DOWN3:  CMP BP, BX      ;11
        JE RIGHT3
        INC BP
        LOOP DOWN3
RIGHT3: CALL SET_MOVE
RIGHT3P:CMP DI, DX
        JE MOVEND
        INC DI
        LOOP RIGHT3P

MOVEND: RET            
    NEXT_SQUARE         ENDP
    ;----------------------------------------------------
    SET_MOVE            PROC   ;USTAWIA PRZESUNIECIE ZGODNIE ZE ZNACZNIKIEM Z ARGUMENTU
        MOV SI, OFFSET FLAG    ;ZWRACA ILOSC POL DO PRZESKOCZENIA W CX
        MOV CL, ES:[SI]
        XOR CH, CH
        
        CMP CX, 0    ;JEZELI TRYB = 0, TO SKOK = 1
        JNE EXTEN
        MOV CX, 1
        RET
EXTEN:  MOV CX, 2    ;JEZELI TRYB = 1, TO SKOK = 2
        RET  
    SET_MOVE            ENDP
    ;----------------------------------------------------
    INC_SQUARE          PROC    ;INKREMENTUJE LICZNIK ODWIEDZEN ODPOWIEDNIEGO POLA
        PUSH AX                   ;WSPOLRZEDNE POLA ODCZYTUJE Z BP:DI
        PUSH BX
        PUSH BP
        
        MOV AX, BP
        MOV BX, 17   ;OBLICZENIE ADRESU W TABLICY
        IMUL BX      ;[X][Y] -> X*17 + Y
        MOV BP, AX
        
        INC DS:BOARD[BP][DI] ;ZWIEKSZENIE ODPOWIENIEGO POLA W 'BOARD'
        
        POP BP
        POP BX
        POP AX
        RET
    INC_SQUARE          ENDP
    ;----------------------------------------------------
    MARK_END            PROC        ;ZACHOWUJE OSTATNIE ODWIEDZONE POLE
        PUSH AX                     ;PRZYJMUJE PARAMETRY POLA W BP:DI
        PUSH BX
        PUSH BP
        
        MOV AX, BP
        MOV BX, 17   ;OBLICZENIE ADRESU W TABLICY
        IMUL BX      ;[X][Y] -> X*17 + Y
        ADD AX, DI
        MOV BYTE PTR DS:[ENDC], AL
        
        POP BP
        POP BX
        POP AX
        RET
    MARK_END            ENDP
    ;----------------------------------------------------
    MAKE_BOARD          PROC      ;WSTAWIA ODPOWIENIE SYMBOLE W 'BOARD', ZGODNIE Z ILOSCIA ODWIEDZEN
        PUSHA
        
        MOV AX, SEG BOARD       ;ES:DI WSKAZUJE NA 'BOARD'
        MOV ES, AX
        MOV DI, OFFSET BOARD
        
        MOV AX, SEG SYMBOL      ;DS WSKAZUJE NA 'SYMBOL'
        MOV DS, AX
        
        MOV CX, 153             ;WYWOLANIE DLA KAZDEGO POLA
SYMBP:  CALL SET_SYMBOL
        INC DI
        LOOP SYMBP
        
        MOV AL, 4CH       ;OZNACZENIE PIERWSZEGO POLA
        XOR AH,AH                                          
        MOV DI, AX
        MOV ES:BOARD[DI], 'S'
        
        MOV AL, ES:ENDC         ;OZNACZNIE OSTATNIEGO POLA
        XOR AH,AH
        MOV DI, AX
        MOV ES:BOARD[DI], 'E'
        
        POPA
        RET
    MAKE_BOARD          ENDP
    ;----------------------------------------------------
    SET_SYMBOL          PROC        ;WSTAWIA ODPOWIEDNI ZNAK DLA ES:DI
        PUSHA
        
        MOV AL, ES:[DI]        ;POBRANA ZOSTAJE ILOSC ODWIEDZIN TEGO POLA
        XOR AH, AH
        MOV SI, AX
        CMP SI, 15             ;SPRAWDZENIE, CZY NIE JEST POWYZEJ 14
        JL CHANGE
        MOV SI, 14
CHANGE: MOV AL, DS:SYMBOL[SI]  
        MOV ES:[DI], AL        ;WSTAWIENIE ODPOWIEDNIEGO SYMBOLU
       
        POPA
        RET        
    SET_SYMBOL          ENDP
    ;----------------------------------------------------
    DRAW_BOARD          PROC       ;RYSUJE SZACHOWNICE
        PUSHA
        
        MOV AX, SEG BOARD          ;ES:SI WSKAZUJE NA 'BOARD'
        MOV ES, AX
        MOV DI, OFFSET BOARD
        
        MOV AX, SEG FRAME          ;DS:DX WSKAZUJE NA POZIOMA RAMKE
        MOV DS, AX
        MOV DX, OFFSET FRAME
        
        MOV AH, 9                  ;WYSWIETLENIE GORNEJ CZECSI RAMKI
        INT 21H
        
        MOV CX, 9
DRAWP:  CALL PRINT_LINE            ;WYSWIETLANIE PO KOLEJI LINI
        LOOP DRAWP
        
        MOV DX, OFFSET FRAME       ;WYSWIETLANIE DOLNEJ CZESCI RAMKI
        MOV AH, 9
        INT 21H
        
        POPA
        RET
    DRAW_BOARD          ENDP   
    ;----------------------------------------------------
    PRINT_LINE          PROC        ;DRUKUJE POJEDYNCZA LINIE
        PUSH CX
        PUSH DX
        PUSH AX
        
        MOV AH, 2           ;WYSWIETLENIE RAMKI
        MOV DL, '|'
        INT 21H
        MOV CX, 17

LINEP:  MOV DL, ES:[DI]     ;POBRANIE ODPOWIEDNIEGO ZNAKU I WYSWIETLENIE
        INT 21H
        INC DI
        LOOP LINEP

        MOV DL, '|'         ;WYSWIETLENIE BOKU RAMKI
        INT 21H
        MOV DL, 13
        INT 21H             ;NOWA LINIA
        MOV DL, 10
        INT 21H
        
        POP AX
        POP DX
        POP CX
        RET
    PRINT_LINE          ENDP      
  ;------------------------KONIEC PROCEDUR------------------------  
CODE1   ENDS


STOS1   SEGMENT STACK
        DW 200 DUP(?)
WSTOSU  DW ?
STOS1   ENDS
       
END     START
