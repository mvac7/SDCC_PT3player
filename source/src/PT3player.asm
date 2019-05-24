;
; - - - - - - - - - - - - - - - - - -  PT3  Replayer  - - - - - - - - - - - - - - - - - -
;

;Vortex Tracker II v1.0 PT3 player for MSX

; Authors:
; Vortex Tracker II v1.0 PT3 player for ZX Spectrum by S.V.Bulba <vorobey@mail.khstu.ru> http://bulba.at.kz
; (09-Jan-05) Adapted to MSX by Alfonso D. C. aka Dioniso <dioniso072@yahoo.es>
; Arrangements for MSX ROM: MSXKun/Paxanga soft > http://paxangasoft.retroinvaders.com/
; asMSX version: SapphiRe > http://www.z80st.es/
; Adapted to SDCC: mvac7/303bcn > <mvac7303b@gmail.com>



;  In this replayer:

; Dioniso version:
; - No version detection (just for Vortex Tracker II and PT3.5).
; - No frequency table decompression (default is number 2). - Coger tabla segun quiera, en fichero aparte
; - No volume table decompression (Vortex Tracker II/PT3.5 volume table used).


; msxKun version:
; - Usable desde ROM (solo tiene en RAM area de trabajo, lo minimo posible).

; SapphiRe version:
; This version of the replayer uses a fixed volume and note table, if you need a 
; different note table you can copy it from TABLES.TXT file, distributed with the
; original PT3 distribution. This version also allows the use of PT3 commands.
;
; PLAY and PSG WRITE routines seperated to allow independent calls

; mvac7 version:
;




; Warning!!! Delete 100 first bytes (header) from your PT3 module or add 100 to data addres. <<<<<<<<<<<<<<<<<<<<<< ##################### WARNING!!!  

	.area _DATA


  .area _CODE


;  --- ChannelsVars ---  (esto son equs, no posiciones RAM)
VARS = 0xE200       ;256B
 
ChanA = VARS        ;rb CHNPRM_Size		; 29 bytes
ChanB =	ChanA + 29	;rb CHNPRM_Size		; 29 bytes
ChanC = ChanB + 29	;rb CHNPRM_Size		; 29 bytes

; - GlobalVars -

DelyCnt = ChanC   + 29  ;	1
CurESld = DelyCnt + 1   ;	2	
CurEDel = CurESld + 2   ;	1

Ns_Base_AddToNs = CurEDel + 1

Ns_Base = Ns_Base_AddToNs ;	1
AddToNs = Ns_Base + 1     ; 1

 
VT_ = AddToNs + 1  ;256B  
AYREGS  = VT_      ;14B ?
EnvBase = VT_+14
VAR0END = VT_+16   ;INIT zeroes from VARS to VAR0END-1

_PT3WRK = VT_+256  ;rb	32

;AYREGS:
;VT_:			  .ds	14
;EnvBase:		.ds	2
;VAR0END:		.ds	240





; --- Workarea --- (apunta a RAM que estaba antes en codigo automodificable)

; -El byte de estado en SETUP deberia ser algo asi (CH enable/disable no esta aun)
;|EP|0|0|0|CH3|CH2|CH1|LP|

;LP: Loop enable/disable. A 1 si queremos que el tema suene solo una vez. 
;EP: End point. A 1 cada vez que el tema acaba. 
;CH1-CH3: Channel enable/disable. A 1 si no queremos que suene el canal. (AUN  NO VA!!)

PT3_SETUP   = _PT3WRK     ; set bit0 to 1, if you want to play without LOOPING
                          ; bit7 is set each time, when loop point is passed
PT3_MODADDR =	_PT3WRK+1	  ; 2 bytes dir musica guardada
PT3_CrPsPtr = _PT3WRK+3   ; 2 bytes POSICION CURSOR EN PATTERN
PT3_SAMPTRS = _PT3WRK+5	  ; 2 bytes sample info?
PT3_OrnPtrs =	_PT3WRK+7   ; 2 bytes Ornament pattern
PT3_PDSP    =	_PT3WRK+9	  ; 2 bytes pilasave
PT3_CSP     =	_PT3WRK+11	; 2 bytes pilsave2
PT3_PSP     =	_PT3WRK+13	; 2 bytes pilsave3

PT3_PrNote  = _PT3WRK+15  ;.ds	1
PT3_PrSlide = _PT3WRK+16  ;.ds	2

PT3_AdInPtA = _PT3WRK+18  ;2 bytes play data pattern
PT3_AdInPtB = _PT3WRK+20  ;2 bytes play data
PT3_AdInPtC = _PT3WRK+22  ;2 bytes play data

PT3_LPosPtr = _PT3WRK+24  ;2 bytes Pos Ptr
PT3_PatsPtr = _PT3WRK+26  ;2 bytes Pat Ptr

PT3_Delay   = _PT3WRK+28  ;1 byte delay
PT3_AddToEn = _PT3WRK+29  ;1 byte Envelope data (No cal ya que no usa Envs??)
PT3_Env_Del = _PT3WRK+31  ;1 byte Envelope data (idem)
PT3_ESldAdd = _PT3WRK+32  ;2 bytes Envelope data (idem)




; ------------------------------------------------------------------------------
; Constants

AY0index = 0xA0
AY0write = 0xA1
AY0read  = 0xA2


;ChannelsVars
;struc	CHNPRM
;reset group
CHNPRM_PsInOr = 0	 ;RESB 1
CHNPRM_PsInSm = 1	 ;RESB 1
CHNPRM_CrAmSl = 2	 ;RESB 1
CHNPRM_CrNsSl = 3	 ;RESB 1
CHNPRM_CrEnSl = 4	 ;RESB 1
CHNPRM_TSlCnt = 5	 ;RESB 1
CHNPRM_CrTnSl = 6	 ;RESW 1
CHNPRM_TnAcc  = 8	 ;RESW 1
CHNPRM_COnOff = 10 ;RESB 1
;reset group

CHNPRM_OnOffD = 11 ;RESB 1

;IX for PTDECOD here (+12)
CHNPRM_OffOnD = 12 ;RESB 1
CHNPRM_OrnPtr = 13 ;RESW 1
CHNPRM_SamPtr = 15 ;RESW 1
CHNPRM_NNtSkp = 17 ;RESB 1
CHNPRM_Note   = 18 ;RESB 1
CHNPRM_SlToNt = 19 ;RESB 1
CHNPRM_Env_En = 20 ;RESB 1
CHNPRM_Flags  = 21 ;RESB 1

;Enabled - 0,SimpleGliss - 2
CHNPRM_TnSlDl = 22 ;RESB 1
CHNPRM_TSlStp = 23 ;RESW 1
CHNPRM_TnDelt = 25 ;RESW 1
CHNPRM_NtSkCn = 27 ;RESB 1
CHNPRM_Volume = 28 ;RESB 1
CHNPRM_Size   = 29 ;RESB 1
; endstruc

;- struc AR -
AR_TonA  = 0	;RESW 1
AR_TonB  = 2	;RESW 1
AR_TonC  = 4	;RESW 1
AR_Noise = 6	;RESB 1
AR_Mixer = 7	;RESB 1
AR_AmplA = 8	;RESB 1
AR_AmplB = 9	;RESB 1
AR_AmplC = 10	;RESB 1
AR_Env   = 11	;RESW 1
AR_EnvTp = 13	;RESB 1
;endstruc



T1_ = VT_+16 ;Tone tables data depacked here

T_OLD_1 = T1_
T_OLD_2 = T_OLD_1+24
T_OLD_3 = T_OLD_2+24
T_OLD_0 = T_OLD_3+2
T_NEW_0 = T_OLD_0
T_NEW_1 = T_OLD_1
T_NEW_2 = T_NEW_0+24
T_NEW_3 = T_OLD_3




	

; ================================================ REPLAYER =================================================

; PT3 JP Table (podria incluso ahorrarse)

;_Pt3Init::	jp	INIT		; inicializa musica
;_PT3Play::	jp	PLAY		; playea
;_PT3Stop::	jp	MUTE		; para

; -- replayer --

CHECKLP:	
  LD   HL,#PT3_SETUP
	SET  7,(HL)   ; -------------------------------------------------------------- <<< ????
	BIT  0,(HL)   ;loop bit 
	RET  Z
  
;=1 - No loop
	POP  HL
	LD   HL,#DelyCnt
	INC  (HL)
	LD   HL,#ChanA+CHNPRM_NtSkCn
	INC  (HL)



;-------------------------------------------------------------------------------  
MUTE:
_PT3Stop::	
  XOR  A
	LD   H,A
	LD   L,A
	LD   (#AYREGS+AR_AmplA),A
	LD   (#AYREGS+AR_AmplB),HL
	JP   _PT3PlayAY                ;ROUT_A0
;-------------------------------------------------------------------------------




;-------------------------------------------------------------------------------
; void PT3Init(unsigned int,char)
_PT3Init::
  push IX
  ld   IX,#0
  add  IX,SP
  
  ld   HL,#PT3_SETUP
  ld   A,6(IX)
  or   A
  jr   NZ,SongLoop
  set  0,(HL)  ;not loop
  jr   initSong
  
SongLoop:  
  res  0,(HL)  ;loop

initSong:  
  ld   L,4(IX)
  ld   H,5(IX)
  call playerINIT
  
  pop  IX
  ret
;-------------------------------------------------------------------------------

  


;-------------------------------------------------------------------------------
;_PT3Run::   
;  push IX
;  call PLAY
;  pop  IX
;  ret


;void PT3Loop(char)
;_PT3Loop::
;  push IX
;  ld   HL,#PT3_SETUP
;  ld   A,4(IX)
;  or   A
;  jr   NZ,SongLoop
;  set  0,(HL)  ;not loop
;  pop  IX
;  ret
;SongLoop:  
;  res  0,(HL)  ;loop
;  pop  IX
;  ret


; ------------------------------------------------------------------------------
playerINIT::
	;HL - AddressOfModule-100
	;ld hl,MDLADDR-100	; ## esto ahora se da como entrada al llamar a rutina
	; asi que la musica puede ir en cualquier lado ROM o RAM

	;or	 A		; # added
	;ld	 DE,#100		; # added
	;sbc	 HL,DE		; # added

	LD   (#PT3_MODADDR),HL	; # chg
	PUSH HL
	LD   DE,#100
	ADD  HL,DE
	LD   A,(HL)
	LD   (#PT3_Delay),A		; # chg
	PUSH HL
	POP  IX
	ADD  HL,DE
	LD   (#PT3_CrPsPtr),HL
	LD   E,102-100(IX)
	ADD  HL,DE
	INC  HL
	LD   (#PT3_LPosPtr),HL	; # chg
	POP  DE
	LD   L,103-100(IX)
	LD   H,104-100(IX)
	ADD  HL,DE
	LD   (#PT3_PatsPtr),HL	; # chg
	LD   HL,#169
	ADD  HL,DE
	LD   (#PT3_OrnPtrs),HL	; # chg
	LD   HL,#105
	ADD  HL,DE
	LD   (#PT3_SAMPTRS),HL	; # chg
	LD   HL,#PT3_SETUP
	RES  7,(HL)


; Create Volume Table for Vortex Tracker II/PT3.5
; (c) Ivan Roshin, adapted by SapphiRe ---
  ld	HL,#0x11
  ld	D,H
  ld  E,H
  ld  IX,#VT_+16
  ld  B,#15
INITV1:	
  push HL
  add  HL,DE
  ex   DE,HL
  sbc  HL,HL
  ld   C,B 
  ld   B,#16
INITV2:	
  ld   A,L
  rla
  ld   A,H
  adc  A,#0
  ld   (IX),A
  inc  IX
  add  HL,DE
  djnz INITV2
  pop  HL
  ld   A,E
  cp   #0x77
  jr   NZ,INITV3
  inc  E
INITV3:	
  ld   B,C
  djnz INITV1
    

  
  
  ; --- INITIALIZE PT3 VARIABLES ---
	xor	 A	
	LD   HL,#VARS
	LD   (HL),A
	LD   DE,#VARS+1
	LD   BC,#VAR0END - VARS -1
	LDIR
  
	INC  A
	LD   (#DelyCnt),A
	LD   HL,#0xF001	;H - CHNPRM_Volume, L - CHNPRM_NtSkCn
	LD   (#ChanA+CHNPRM_NtSkCn),HL
	LD   (#ChanB+CHNPRM_NtSkCn),HL
	LD   (#ChanC+CHNPRM_NtSkCn),HL

	LD   HL,#EMPTYSAMORN
	LD   (#PT3_AdInPtA),HL ;ptr to zero  ; # chg
	LD   (#ChanA+CHNPRM_OrnPtr),HL ;ornament 0 is "0,1,0"
	LD   (#ChanB+CHNPRM_OrnPtr),HL ;in all versions from
	LD   (#ChanC+CHNPRM_OrnPtr),HL ;3.xx to 3.6x and VTII

	LD   (#ChanA+CHNPRM_SamPtr),HL ;S1 There is no default
	LD   (#ChanB+CHNPRM_SamPtr),HL ;S2 sample in PT3, so, you
	LD   (#ChanC+CHNPRM_SamPtr),HL ;S3 can comment S1,2,3; see
				    ;also EMPTYSAMORN comment
	ret
;------------------------------------------------------------------------------- END playerINIT



  
  
;-------------------------------------------------------------------------------
;pattern decoder
PD_OrSm:	
  LD   -12+CHNPRM_Env_En(IX),#0
	CALL SETORN
	LD   A,(BC)
	INC  BC
	RRCA

PD_SAM:	
  ADD  A,A
PD_SAM_:	
  LD   E,A
	LD   D,#0
	ld	 HL,(#PT3_SAMPTRS)
	ADD  HL,DE
	LD   E,(HL)
	INC  HL
	LD   D,(HL)
	ld	 HL,(#PT3_MODADDR)
	ADD  HL,DE
	LD   -12+CHNPRM_SamPtr(IX),L
	LD   -12+CHNPRM_SamPtr+1(IX),H
	JR   PD_LOOP

PD_VOL:	
  RLCA
	RLCA
	RLCA
	RLCA
	LD   -12+CHNPRM_Volume(IX),A
	JR   PD_LP2
	
PD_EOff:	
  LD   -12+CHNPRM_Env_En(IX),A
	LD   -12+CHNPRM_PsInOr(IX),A
	JR   PD_LP2

PD_SorE:	
  DEC  A
	JR   NZ,PD_ENV
	LD   A,(BC)
	INC  BC
	LD   -12+CHNPRM_NNtSkp(IX),A
	JR   PD_LP2

PD_ENV:	
  CALL SETENV
	JR   PD_LP2

PD_ORN:	
  CALL SETORN
	JR   PD_LOOP
       
PD_ESAM:	
  LD   -12+CHNPRM_Env_En(IX),A
	LD   -12+CHNPRM_PsInOr(IX),A
	CALL NZ,SETENV
	LD   A,(BC)
	INC  BC
	JR   PD_SAM_

PTDECOD: 
  LD   A,-12+CHNPRM_Note(IX)
	LD   (#PT3_PrNote),A           ;LD   (#PrNote+1),A
  LD   L,CHNPRM_CrTnSl-12(IX)
  LD   H,CHNPRM_CrTnSl+1-12(IX)
  LD  (#PT3_PrSlide),HL

PD_LOOP:	
  ld   DE,#0x2010
PD_LP2:	
  ld   A,(BC)
	inc  BC
	ADD  A,E
	JR   C,PD_OrSm
	ADD  A,D
	JR   Z,PD_FIN
	JR   C,PD_SAM
	ADD  A,E
	JR   Z,PD_REL
	JR   C,PD_VOL
	ADD  A,E
	JR   Z,PD_EOff
	JR   C,PD_SorE
	ADD  A,#96
	JR   C,PD_NOTE
	ADD  A,E
	JR   C,PD_ORN
	ADD  A,D
	JR   C,PD_NOIS
	ADD  A,E
	JR   C,PD_ESAM
	ADD  A,A
	LD   E,A
	
  LD   HL,#(SPCCOMS + 0xDF20)  ;LD HL,((SPCCOMS+$DF20) % 65536)
;	PUSH DE
;	LD   DE,#0xDF20
;	LD   HL,#SPCCOMS	
;	ADD  HL,DE
;	POP  DE	
  
  ADD  HL,DE
  LD   E,(HL)
  INC  HL
  LD   D,(HL)
  PUSH DE
  
	JR   PD_LOOP

PD_NOIS:	
  LD   (#Ns_Base),A
	JR   PD_LP2

PD_REL:	
  RES  0,-12+CHNPRM_Flags(IX)
	JR   PD_RES
	
PD_NOTE:	
  ld   -12+CHNPRM_Note(IX),A
	SET  0,-12+CHNPRM_Flags(IX)
	XOR  A

PD_RES:	
	ld	 (#PT3_PDSP),SP
	LD   SP,IX
	LD   H,A
	LD   L,A
	PUSH HL
	PUSH HL
	PUSH HL
	PUSH HL
	PUSH HL
	PUSH HL
	ld	SP,(#PT3_PDSP)

PD_FIN:	
  ld   A,-12+CHNPRM_NNtSkp(IX)
	ld   -12+CHNPRM_NtSkCn(IX),A
	ret

C_PORTM: 
  RES  2,-12+CHNPRM_Flags(IX)
	LD   A,(BC)
	INC  BC
;SKIP PRECALCULATED TONE DELTA (BECAUSE
;CANNOT BE RIGHT AFTER PT3 COMPILATION)
	INC  BC
	INC  BC
	LD   -12+CHNPRM_TnSlDl(IX),A
	LD   -12+CHNPRM_TSlCnt(IX),A
	LD   DE,#NT_
	LD   A,-12+CHNPRM_Note(IX)
	LD   -12+CHNPRM_SlToNt(IX),A
	ADD  A,A
	LD   L,A
	LD   H,#0
	ADD  HL,DE
	LD   A,(HL)
	INC  HL
	LD   H,(HL)
	LD   L,A
	PUSH HL
  LD   A,(#PT3_PrNote)            ;<--- LD   A,#0x3E
	LD   -12+CHNPRM_Note(IX),A
	ADD  A,A
	LD   L,A
	LD   H,#0
	ADD  HL,DE
	LD   E,(HL)
	INC  HL
	LD   D,(HL)
	POP  HL
	SBC  HL,DE
	LD   -12+CHNPRM_TnDelt(IX),L
	LD   -12+CHNPRM_TnDelt+1(IX),H
  LD   DE,(#PT3_PrSlide)             ;<--- change to Kun version
	LD   -12+CHNPRM_CrTnSl(IX),E       ;<---
	LD   -12+CHNPRM_CrTnSl+1(IX),D     ;<---
  LD   A,(BC) ;SIGNED TONE STEP
	INC  BC
	EX   AF,AF
	LD   A,(BC)
	INC  BC
	AND  A
	JR   Z,NOSIG
	EX   DE,HL
NOSIG:	
  SBC  HL,DE
	JP   P,SET_STP
	CPL
	EX   AF,AF
	NEG
	EX   AF,AF
SET_STP:	
  LD   -12+CHNPRM_TSlStp+1(IX),A
	EX   AF,AF
	ld   -12+CHNPRM_TSlStp(IX),A
	ld   -12+CHNPRM_COnOff(IX),#0
	ret

C_GLISS:	
  SET  2,-12+CHNPRM_Flags(IX)
	LD   A,(BC)
	INC  BC
	LD  -12+CHNPRM_TnSlDl(IX),A
	LD  -12+CHNPRM_TSlCnt(IX),A
	LD   A,(BC)
	INC  BC
	EX   AF,AF
	LD   A,(BC)
	INC  BC
	JR   SET_STP

C_SMPOS:	
  LD   A,(BC)
	INC  BC
	LD   -12+CHNPRM_PsInSm(IX),A
	RET

C_ORPOS:	
  LD   A,(BC)
	INC  BC
	LD   -12+CHNPRM_PsInOr(IX),A
	RET

C_VIBRT:	
  LD   A,(BC)
	INC  BC
	LD   -12+CHNPRM_OnOffD(IX),A
	LD   -12+CHNPRM_COnOff(IX),A
	LD   A,(BC)
	INC  BC
	LD   -12+CHNPRM_OffOnD(IX),A
	XOR  A
	LD   -12+CHNPRM_TSlCnt(IX),A
	LD   -12+CHNPRM_CrTnSl(IX),A
	LD   -12+CHNPRM_CrTnSl+1(IX),A
	RET

C_ENGLS:	
  LD   A,(BC)
	INC  BC
	LD   (#PT3_Env_Del),A
	LD   (#CurEDel),A
	LD   A,(BC)
	INC  BC
	LD   L,A
	LD   A,(BC)
	INC  BC
	LD   H,A
	LD   (#PT3_ESldAdd),HL
	RET

C_DELAY:	
  LD   A,(BC)
	INC  BC
	LD   (#PT3_Delay),A
	RET
	
SETENV:	
  LD   -12+CHNPRM_Env_En(IX),E
	LD   (#AYREGS+AR_EnvTp),A
	LD   A,(BC)
	INC  BC
	LD   H,A
	LD   A,(BC)
	INC  BC
	LD   L,A
	LD   (#EnvBase),HL
	XOR  A
	LD   -12+CHNPRM_PsInOr(IX),A
	LD   (#CurEDel),A
	LD   H,A
	LD   L,A
	LD   (#CurESld),HL
  
C_NOP:	
  RET

SETORN:	
  ADD  A,A
	LD   E,A
	LD   D,#0
	LD   -12+CHNPRM_PsInOr(IX),D
	ld	 HL,(#PT3_OrnPtrs) 
	ADD  HL,DE
	LD   E,(HL)
	INC  HL
	LD   D,(HL)
	ld   HL,(#PT3_MODADDR) 
	ADD  HL,DE
	LD   -12+CHNPRM_OrnPtr(IX),L
	LD   -12+CHNPRM_OrnPtr+1(IX),H
	RET





;-------------------------------------------------------------------------------
;ALL 16 ADDRESSES TO PROTECT FROM BROKEN PT3 MODULES 

SPCCOMS: 
.dw C_NOP			  ; ## COMPROBAR Q NO SEA AUTOMODIF
.dw C_GLISS			; (parece que no lo toca nada)
.dw C_PORTM
.dw C_SMPOS
.dw C_ORPOS
.dw C_VIBRT
.dw C_NOP
.dw C_NOP
.dw C_ENGLS
.dw C_DELAY
.dw C_NOP
.dw C_NOP
.dw C_NOP
.dw C_NOP
.dw C_NOP
.dw C_NOP





CHREGS:	
  XOR  A
	LD   (#AYREGS+AR_AmplC),A
	BIT   0,CHNPRM_Flags(IX)
	PUSH  HL
	JP    Z,CH_EXIT
	ld	 (#PT3_CSP),sp
	LD   L,CHNPRM_OrnPtr(IX)
	LD   H,CHNPRM_OrnPtr+1(IX)
	LD   SP,HL
	POP  DE
	LD   H,A
	LD   A,CHNPRM_PsInOr(IX)
	LD   L,A
	ADD  HL,SP
	INC  A
	CP   D
	JR   C,CH_ORPS
	LD   A,E
CH_ORPS:	
  LD   CHNPRM_PsInOr(IX),A
	LD   A,CHNPRM_Note(IX)
	ADD  A,(HL)
	JP   P,CH_NTP
	XOR  A
CH_NTP:	
  CP   #96
	JR   C,CH_NOK
	LD   A,#95
CH_NOK:	
  ADD  A,A
	EX   AF,AF
	LD   L,CHNPRM_SamPtr(IX)
	LD   H,CHNPRM_SamPtr+1(IX)
	LD   SP,HL
	POP  DE
	LD   H,#0
	LD   A,CHNPRM_PsInSm(IX)
	LD   B,A
	ADD  A,A
	ADD  A,A
	LD   L,A
	ADD  HL,SP
	LD   SP,HL
	LD   A,B
	INC  A
	CP   D
	JR   C,CH_SMPS
	LD   A,E
CH_SMPS:	
  LD   CHNPRM_PsInSm(IX),A
	POP  BC
	POP  HL
	LD   E,CHNPRM_TnAcc(IX)
	LD   D,CHNPRM_TnAcc+1(IX)
	ADD  HL,DE
	BIT  6,B
	JR   Z,CH_NOAC
	LD   CHNPRM_TnAcc(IX),L
	LD   CHNPRM_TnAcc+1(IX),H
CH_NOAC: 
  EX   DE,HL
	EX   AF,AF
	LD   L,A
	LD   H,#0
	LD   SP,#NT_
	ADD  HL,SP
	LD   SP,HL
	POP  HL
	ADD  HL,DE
	LD   E,CHNPRM_CrTnSl(IX)
	LD   D,CHNPRM_CrTnSl+1(IX)
	ADD  HL,DE
	ld	 SP,(#PT3_CSP)
	EX   (SP),HL
	XOR  A
	OR   CHNPRM_TSlCnt(IX)
	JR   Z,CH_AMP
	DEC  CHNPRM_TSlCnt(IX)
	JR   NZ,CH_AMP
	LD   A,CHNPRM_TnSlDl(IX)
	LD   CHNPRM_TSlCnt(IX),A
	LD   L,CHNPRM_TSlStp(IX)
	LD   H,CHNPRM_TSlStp+1(IX)
	LD   A,H
	ADD  HL,DE
	LD   CHNPRM_CrTnSl(IX),L
	LD   CHNPRM_CrTnSl+1(IX),H
	BIT  2,CHNPRM_Flags(IX)
	JR   NZ,CH_AMP
	LD   E,CHNPRM_TnDelt(IX)
	LD   D,CHNPRM_TnDelt+1(IX)
	AND  A
	JR   Z,CH_STPP
	EX   DE,HL
CH_STPP: 
  SBC  HL,DE
	JP   M,CH_AMP
	LD   A,CHNPRM_SlToNt(IX)
	LD   CHNPRM_Note(IX),A
	XOR  A
	LD   CHNPRM_TSlCnt(IX),A
	LD   CHNPRM_CrTnSl(IX),A
	LD   CHNPRM_CrTnSl+1(IX),A
CH_AMP:	
  LD   A,CHNPRM_CrAmSl(IX)
	BIT  7,C
	JR   Z,CH_NOAM
	BIT  6,C
	JR   Z,CH_AMIN
	CP   #15
	JR   Z,CH_NOAM
	INC  A
	JR   CH_SVAM
CH_AMIN:	
  CP   #-15
	JR   Z,CH_NOAM
	DEC  A
CH_SVAM:	
  LD   CHNPRM_CrAmSl(IX),A
CH_NOAM:	
  LD   L,A
	LD   A,B
	AND  #15
	ADD  A,L
	JP   P,CH_APOS
	XOR  A
CH_APOS:	
  CP   #16
	JR   C,CH_VOL
	LD   A,#15
CH_VOL:	
  OR   CHNPRM_Volume(IX)
	LD   L,A
	LD   H,#0
	LD   DE,#VT_
	ADD  HL,DE
	LD   A,(HL)
CH_ENV:	
  BIT  0,C
	JR   NZ,CH_NOEN
	OR   CHNPRM_Env_En(IX)
CH_NOEN:	
  LD   (#AYREGS+AR_AmplC),A
	BIT  7,B
	LD   A,C
	JR   Z,NO_ENSL
	RLA
	RLA
	SRA  A
	SRA  A
	SRA  A
	ADD  A,CHNPRM_CrEnSl(IX) ;SEE COMMENT BELOW
	BIT  5,B
	JR   Z,NO_ENAC
	LD   CHNPRM_CrEnSl(IX),A
NO_ENAC:	
	ld	 HL,#PT3_AddToEn 
	ADD  A,(HL) ;BUG IN PT3 - NEED WORD HERE.
		   ;FIX IT IN NEXT VERSION?
	LD   (HL),A
	JR   CH_MIX
NO_ENSL: 
  RRA
	ADD  A,CHNPRM_CrNsSl(IX)
	LD   (#AddToNs),A
	BIT  5,B
	JR   Z,CH_MIX
	LD   CHNPRM_CrNsSl(IX),A
CH_MIX:	
  LD   A,B
	RRA
	AND  #0x48
CH_EXIT:	
  LD   HL,#AYREGS+AR_Mixer
	OR   (HL)
	RRCA
	LD   (HL),A
	POP  HL
	XOR  A
	OR   CHNPRM_COnOff(IX)
	RET  Z
	DEC  CHNPRM_COnOff(IX)
	RET  NZ
	XOR  CHNPRM_Flags(IX)
	LD   CHNPRM_Flags(IX),A
	RRA
	LD   A,CHNPRM_OnOffD(IX)
	JR   C,CH_ONDL
	LD   A,CHNPRM_OffOnD(IX)
CH_ONDL:	
  LD   CHNPRM_COnOff(IX),A
	RET


;------------------------------------------------------------------------------- PLAY PT3
;PLAY:
_PT3Run:: 
  XOR  A
	LD   (#PT3_AddToEn),A
	LD   (#AYREGS+AR_Mixer),A
	DEC  A
	LD   (#AYREGS+AR_EnvTp),A
	LD   HL,#DelyCnt
	DEC  (HL)
	JP   NZ,PL2 
	LD   HL,#ChanA+CHNPRM_NtSkCn
	DEC  (HL)
	JR   NZ,PL1B
	ld	 BC,(#PT3_AdInPtA)
	LD   A,(BC)
	AND  A
	JR   NZ,PL1A
	LD   D,A
	LD   (#Ns_Base),A
	LD   HL,(#PT3_CrPsPtr)
	INC  HL
	LD   A,(HL)
	INC  A
	JR   NZ,PLNLP
	CALL CHECKLP
	ld	 HL,(#PT3_LPosPtr)
	LD   A,(HL)
	INC  A
PLNLP:	
  LD   (#PT3_CrPsPtr),HL
	DEC  A
	ADD  A,A
	LD   E,A
	RL   D
	ld   HL,(#PT3_PatsPtr)
	ADD  HL,DE
	LD   DE,(#PT3_MODADDR)
	ld   (#PT3_PSP),SP
	LD   SP,HL
	POP  HL
	ADD  HL,DE
	LD   B,H
	LD   C,L
	POP  HL
	ADD  HL,DE
	LD   (#PT3_AdInPtB),HL
	POP  HL
	ADD  HL,DE
	LD   (#PT3_AdInPtC),HL
	ld   SP,(#PT3_PSP)
  
PL1A:	
  LD   IX,#ChanA+12
	CALL PTDECOD
	LD   (#PT3_AdInPtA),BC
  
PL1B:	
  LD   HL,#ChanB+CHNPRM_NtSkCn
	DEC  (HL)
	JR   NZ,PL1C
	LD   IX,#ChanB+12
	ld   BC,(#PT3_AdInPtB)
	CALL PTDECOD
	LD   (#PT3_AdInPtB),BC

PL1C:	
  LD   HL,#ChanC+CHNPRM_NtSkCn
	DEC  (HL)
	JR   NZ,PL1D
	LD   IX,#ChanC+12
	ld   BC,(#PT3_AdInPtC)
	CALL PTDECOD
	LD   (#PT3_AdInPtC),BC

PL1D:	
	ld   A,(#PT3_Delay)
	ld   (#DelyCnt),A

PL2:	
  LD   IX,#ChanA
	LD   HL,(#AYREGS+AR_TonA)
	CALL CHREGS
	LD   (#AYREGS+AR_TonA),HL
	LD   A,(#AYREGS+AR_AmplC)
	LD   (#AYREGS+AR_AmplA),A
	LD   IX,#ChanB
	LD   HL,(#AYREGS+AR_TonB)
	CALL CHREGS
	LD   (#AYREGS+AR_TonB),HL
	LD   A,(#AYREGS+AR_AmplC)
	LD   (#AYREGS+AR_AmplB),A
	LD   IX,#ChanC
	LD   HL,(#AYREGS+AR_TonC)
	CALL CHREGS
	LD   (#AYREGS+AR_TonC),HL

	LD   HL,(#Ns_Base_AddToNs)
	LD   A,H
	ADD  A,L
	LD   (#AYREGS+AR_Noise),A

	ld   A,(#PT3_AddToEn)
	LD   E,A
	ADD  A,A
	SBC  A,A
	LD   D,A
	LD   HL,(#EnvBase)
	ADD  HL,DE
	LD   DE,(#CurESld)
	ADD  HL,DE
	LD  (#AYREGS+AR_Env),HL

	XOR  A
	LD   HL,#CurEDel
	OR   (HL)
  
;new from SapphiRe
  RET  Z
  DEC  (HL)
  RET  NZ
  LD   A,(#PT3_Env_Del)
  LD   (HL),A
  LD   HL,(#PT3_ESldAdd)
  ADD  HL,DE
  LD   (CurESld),HL
  RET
;-------------------------------------------------------------------------------



;	JR   Z,ROUT_A0
;	DEC  (HL)
;	JR   NZ,ROUT
;	ld   A,(#PT3_Env_Del)		; # chg
;	LD   (HL),A
;	ld   HL,(#PT3_ESldAdd)		; # chg
;	ADD  HL,DE
;	LD   (#CurESld),HL

;ROUT:	
;  XOR  A

;ROUT_A0:




; send data to AY registers
;------------------------------------------------------------------------------- PLAY AY
_PT3PlayAY::
  ld   A,(#AYREGS+AR_Mixer)
  AND  #0b00111111
  ld   B,A
      
  ld   A,#AR_Mixer
  out  (#AY0index),A
  in   A,(#AY0read)  
  and	 #0b11000000	; Mascara para coger dos bits de joys 
	or	 B		        ; A�ado Byte de B
  
  ld   (#AYREGS+AR_Mixer),A
   
  XOR  A
  
	ld   C,#AY0index
	ld   HL,#AYREGS  
LOUT:	
  OUT  (C),A
	INC  C
	OUTI 
	DEC  C
	INC  A
	CP   #13
	JR   NZ,LOUT
	OUT  (C),A
	LD   A,(HL)
	AND  A
	RET  M
	INC  C
	OUT  (C),A
	RET
;-------------------------------------------------------------------------------



;-------------------------------------------------------------------------------

EMPTYSAMORN: 
.db 0,1,0,0x90 ;delete $90 if you don't need default sample  ; # pongo el 0 aqui


; Kun: -tabla NOTAS, va en ROM pero podria ir en ram y asi tener todas packed y luego depack la que quiera -

;Note table (if you use another in Vortex Tracker II copy it and paste it from TABLES.TXT)		
NT_:	

;Note Table 0
;	.dw 0x0C22,0x0B73,0x0ACF,0x0A33,0x09A1,0x0917,0x0894,0x0819,0x07A4,0x0737,0x06CF,0x066D
;	.dw 0x0611,0x05BA,0x0567,0x051A,0x04D0,0x048B,0x044A,0x040C,0x03D2,0x039B,0x0367,0x0337
;	.dw 0x0308,0x02DD,0x02B4,0x028D,0x0268,0x0246,0x0225,0x0206,0x01E9,0x01CE,0x01B4,0x019B
;	.dw 0x0184,0x016E,0x015A,0x0146,0x0134,0x0123,0x0112,0x0103,0x00F5,0x00E7,0x00DA,0x00CE
;	.dw 0x00C2,0x00B7,0x00AD,0x00A3,0x009A,0x0091,0x0089,0x0082,0x007A,0x0073,0x006D,0x0067
;	.dw 0x0061,0x005C,0x0056,0x0052,0x004D,0x0049,0x0045,0x0041,0x003D,0x003A,0x0036,0x0033
;	.dw 0x0031,0x002E,0x002B,0x0029,0x0027,0x0024,0x0022,0x0020,0x001F,0x001D,0x001B,0x001A
;	.dw 0x0018,0x0017,0x0016,0x0014,0x0013,0x0012,0x0011,0x0010,0x000F,0x000E,0x000D,0x000C

;Note Table 1
;	.dw 0x0EF8,0x0E10,0x0D60,0x0C80,0x0BD8,0x0B28,0x0A88,0x09F0,0x0960,0x08E0,0x0858,0x07E0
;	.dw 0x077C,0x0708,0x06B0,0x0640,0x05EC,0x0594,0x0544,0x04F8,0x04B0,0x0470,0x042C,0x03FD
;	.dw 0x03BE,0x0384,0x0358,0x0320,0x02F6,0x02CA,0x02A2,0x027C,0x0258,0x0238,0x0216,0x01F8
;	.dw 0x01DF,0x01C2,0x01AC,0x0190,0x017B,0x0165,0x0151,0x013E,0x012C,0x011C,0x010A,0x00FC
;	.dw 0x00EF,0x00E1,0x00D6,0x00C8,0x00BD,0x00B2,0x00A8,0x009F,0x0096,0x008E,0x0085,0x007E
;	.dw 0x0077,0x0070,0x006B,0x0064,0x005E,0x0059,0x0054,0x004F,0x004B,0x0047,0x0042,0x003F
;	.dw 0x003B,0x0038,0x0035,0x0032,0x002F,0x002C,0x002A,0x0027,0x0025,0x0023,0x0021,0x001F
;	.dw 0x001D,0x001C,0x001A,0x0019,0x0017,0x0016,0x0015,0x0013,0x0012,0x0011,0x0010,0x000F

;Note table 2
.dw 0x0D10,0x0C55,0x0BA4,0x0AFC,0x0A5F,0x09CA,0x093D,0x08B8,0x083B,0x07C5,0x0755,0x06EC
.dw 0x0688,0x062A,0x05D2,0x057E,0x052F,0x04E5,0x049E,0x045C,0x041D,0x03E2,0x03AB,0x0376
.dw 0x0344,0x0315,0x02E9,0x02BF,0x0298,0x0272,0x024F,0x022E,0x020F,0x01F1,0x01D5,0x01BB
.dw 0x01A2,0x018B,0x0174,0x0160,0x014C,0x0139,0x0128,0x0117,0x0107,0x00F9,0x00EB,0x00DD
.dw 0x00D1,0x00C5,0x00BA,0x00B0,0x00A6,0x009D,0x0094,0x008C,0x0084,0x007C,0x0075,0x006F
.dw 0x0069,0x0063,0x005D,0x0058,0x0053,0x004E,0x004A,0x0046,0x0042,0x003E,0x003B,0x0037
.dw 0x0034,0x0031,0x002F,0x002C,0x0029,0x0027,0x0025,0x0023,0x0021,0x001F,0x001D,0x001C
.dw 0x001A,0x0019,0x0017,0x0016,0x0015,0x0014,0x0012,0x0011,0x0010,0x000F,0x000E,0x000D

;Note Table 3
;	.dw 0x0CDA,0x0C22,0x0B73,0x0ACF,0x0A33,0x09A1,0x0917,0x0894,0x0819,0x07A4,0x0737,0x06CF
;	.dw 0x066D,0x0611,0x05BA,0x0567,0x051A,0x04D0,0x048B,0x044A,0x040C,0x03D2,0x039B,0x0367
;	.dw 0x0337,0x0308,0x02DD,0x02B4,0x028D,0x0268,0x0246,0x0225,0x0206,0x01E9,0x01CE,0x01B4
;	.dw 0x019B,0x0184,0x016E,0x015A,0x0146,0x0134,0x0123,0x0112,0x0103,0x00F5,0x00E7,0x00DA
;	.dw 0x00CE,0x00C2,0x00B7,0x00AD,0x00A3,0x009A,0x0091,0x0089,0x0082,0x007A,0x0073,0x006D
;	.dw 0x0067,0x0061,0x005C,0x0056,0x0052,0x004D,0x0049,0x0045,0x0041,0x003D,0x003A,0x0036
;	.dw 0x0033,0x0031,0x002E,0x002B,0x0029,0x0027,0x0024,0x0022,0x0020,0x001F,0x001D,0x001B
;	.dw 0x001A,0x0018,0x0017,0x0016,0x0014,0x0013,0x0012,0x0011,0x0010,0x000F,0x000E,0x000D


