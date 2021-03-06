/* =============================================================================
   SDCC Vortex Tracker II PT3 player for MSX

   Version: 1.2 (04/01/2021)
   Architecture: MSX
   Format: C Object (SDCC .rel)
   Programming language: C and Z80 assembler

   Authors:
    - Vortex Tracker II v1.0 PT3 player for ZX Spectrum by S.V.Bulba 
      <vorobey@mail.khstu.ru> http://bulba.at.kz
    - (09-Jan-05) Adapted to MSX by Alfonso D. C. aka Dioniso 
      <dioniso072@yahoo.es>
    - Arrangements for MSX ROM: MSXKun/Paxanga soft > 
      http://paxangasoft.retroinvaders.com/
    - asMSX version: SapphiRe > http://www.z80st.es/
    - Adapted to SDCC: mvac7/303bcn > <mvac7303b@gmail.com>

   Description:
     Adaptation of the Vortex Tracker II PT3 Player for MSX to be used in 
     software development in C (SDCC). 
     
   History of versions:
    - 1.2 (04/01/2021)>assignment of frequency table memory address to NoteTable
    - 1.1 (28/05/2019) Adaptation to SDCC of asMSX version by SapphiRe.
    - 1.0 (21/10/2016) Adaptation to SDCC of the ROM version by Kun.

In this replayer:

Dioniso version:
 - No version detection (just for Vortex Tracker II and PT3.5).
 - No frequency table decompression (default is number 2). 
   Coger tabla segun quiera, en fichero aparte
 - No volume table decompression (Vortex Tracker II/PT3.5 volume table used).


msxKun version:
 - Usable desde ROM (solo tiene en RAM area de trabajo, lo minimo posible).

SapphiRe version:
 This version of the replayer uses a fixed volume and note table, if you need a 
 different note table you can copy it from TABLES.TXT file, distributed with the
 original PT3 distribution. This version also allows the use of PT3 commands.

 PLAY and PSG WRITE routines seperated to allow independent calls


mvac7 version:
 Adaptation to C (SDCC) of the SapphiRe version.
 
============================================================================= */
#ifndef  __PT3_PLAYER_H__
#define  __PT3_PLAYER_H__



// Constants


//ChannelsVars
//struc	CHNPRM
//reset group
#define CHNPRM_PsInOr 0	 //RESB 1
#define CHNPRM_PsInSm 1	 //RESB 1
#define CHNPRM_CrAmSl 2	 //RESB 1
#define CHNPRM_CrNsSl 3	 //RESB 1
#define CHNPRM_CrEnSl 4	 //RESB 1
#define CHNPRM_TSlCnt 5	 //RESB 1
#define CHNPRM_CrTnSl 6	 //RESW 1
#define CHNPRM_TnAcc  8	 //RESW 1
#define CHNPRM_COnOff 10 //RESB 1
//reset group

#define CHNPRM_OnOffD 11 //RESB 1

//IX for PTDECOD here (+12)
#define CHNPRM_OffOnD 12 //RESB 1
#define CHNPRM_OrnPtr 13 //RESW 1
#define CHNPRM_SamPtr 15 //RESW 1
#define CHNPRM_NNtSkp 17 //RESB 1
#define CHNPRM_Note   18 //RESB 1
#define CHNPRM_SlToNt 19 //RESB 1
#define CHNPRM_Env_En 20 //RESB 1
#define CHNPRM_Flags  21 //RESB 1

//Enabled - 0,SimpleGliss - 2
#define CHNPRM_TnSlDl 22 //RESB 1
#define CHNPRM_TSlStp 23 //RESW 1
#define CHNPRM_TnDelt 25 //RESW 1
#define CHNPRM_NtSkCn 27 //RESB 1
#define CHNPRM_Volume 28 //RESB 1
#define CHNPRM_Size   29 //RESB 1
// endstruc



#ifndef AY_REGISTERS
#define AY_REGISTERS
#define AY_ToneA      0 //Channel A Tone Period (12 bits)
#define AY_ToneB      2 //Channel B Tone Period (12 bits)
#define AY_ToneC      4 //Channel C Tone Period (12 bits)
#define AY_Noise      6 //Noise Period (5 bits)
#define AY_Mixer      7 //Mixer
#define AY_AmpA       8 //Channel Volume A (4 bits + B5 active Envelope)
#define AY_AmpB       9 //Channel Volume B (4 bits + B5 active Envelope)
#define AY_AmpC      10 //Channel Volume C (4 bits + B5 active Envelope)
#define AY_EnvPeriod 11 //Envelope Period (16 bits)
#define AY_EnvShape  13 //Envelope Shape
#endif


#define Loop_OFF 0
#define Loop_ON  1


/*
T1_ = VT_+16 ;Tone tables data depacked here
T_OLD_1 = T1_
T_OLD_2 = T_OLD_1+24
T_OLD_3 = T_OLD_2+24
T_OLD_0 = T_OLD_3+2
T_NEW_0 = T_OLD_0
T_NEW_1 = T_OLD_1
T_NEW_2 = T_NEW_0+24
T_NEW_3 = T_OLD_3
*/



//VARS:
extern char ChanA[29]; //CHNPRM_Size
extern char ChanB[29];
extern char ChanC[29];			


extern char DelyCnt;
extern unsigned int CurESld;		
extern char CurEDel;


//Ns_Base_AddToNs:
extern char Ns_Base;		
extern char AddToNs;		


extern char AYREGS[14];
extern unsigned int EnvBase;
extern char VAR0END[240];


/*            
Switches: 1=ON; 0=OFF
- BIT 0 = ?
- BIT 1 = PLAYER ON/OFF
- BIT 2 = ?
- BIT 3 = ?
- BIT 4 = LOOP ON/OFF
- BIT 7 = is END? YES/NO
*/
extern char PT3state; //before called PT3_SETUP

/* --- Workarea --- (apunta a RAM que estaba antes en codigo automodificable)
 -El byte de estado en SETUP deberia ser algo asi (CH enable/disable no esta aun)
|EP|0|0|0|CH3|CH2|CH1|LP|

LP: Loop enable/disable. A 1 si queremos que el tema suene solo una vez. 
EP: End point. A 1 cada vez que el tema acaba. 
CH1-CH3: Channel enable/disable. A 1 si no queremos que suene el canal. (AUN  NO VA!!)
*/
//extern char PT3_SETUP;   set bit0 to 1, if you want to play without looping
//				           bit7 is set each time, when loop point is passed          

extern unsigned int PT3_MODADDR;	 //direccion datos canci�n
extern unsigned int PT3_CrPsPtr;  //POSICION CURSOR EN PATTERN
extern unsigned int PT3_SAMPTRS;  //sample info?
extern unsigned int PT3_OrnPtrs;  //Ornament pattern

extern unsigned int PT3_PDSP;     //pilasave
extern unsigned int PT3_CSP;      //pilsave2
extern unsigned int PT3_PSP;      //pilsave3
  
extern char PT3_PrNote;
extern unsigned int PT3_PrSlide;
  
extern unsigned int PT3_AdInPtA;  //play data pattern
extern unsigned int PT3_AdInPtB;  //play data
extern unsigned int PT3_AdInPtC;  //play data
  
extern unsigned int PT3_LPosPtr;  //Position Ptr?
extern unsigned int PT3_PatsPtr;  //Pat Ptr

extern char PT3_Delay;            //delay
extern char PT3_AddToEn;          //Envelope data (No cal ya que no usa Envs??)
extern char PT3_Env_Del;          //Envelope data (idem)
extern unsigned int PT3_ESldAdd;  //Envelope data (idem)

extern unsigned int NoteTable;   //note table memory address
//extern char NoteTable[192];       //Note table




/* =============================================================================
 Player_Init
 Description: Initialize the Player
 Input:       -
 Output:      -
============================================================================= */
void Player_Init();



/* =============================================================================
 Player_Loop
 Description: Change state of loop
 Input:       - 0=off ; 1=on  (false = 0, true = 1)
 Output:      -
============================================================================= */
void Player_Loop(char loop); 



/* =============================================================================
 Player_Pause
 Description: Pause song playback
 Input:       -
 Output:      -
============================================================================= */
void Player_Pause();



/* =============================================================================
 Player_Resume
 Description: Resume song playback
 Input:       -
 Output:      -
============================================================================= */  	
void Player_Resume();



/* -----------------------------------------------------------------------------
 Player_InitSong
 Description: Initialize song
 Input: (unsigned int) Song data address. 
                       Subtract 100 if you delete the header of the PT3 file.
        (char) Loop - 0=off ; 1=on  (false = 0, true = 1));
 Output:      -
----------------------------------------------------------------------------- */
void Player_InitSong(unsigned int songADDR, char loop);



/* -----------------------------------------------------------------------------
 PlayAY
 Description: Play Song. 
              Send data form AYREGS buffer to AY registers
              Execute on each interruption of VBLANK
 Input:       -
 Output:      -
----------------------------------------------------------------------------- */
void PlayAY();



/* -----------------------------------------------------------------------------
 Player_Decode
 Description: Process the next step in the song sequence
 Input:       -
 Output:      - 
----------------------------------------------------------------------------- */
void Player_Decode(); 




/* -----------------------------------------------------------------------------
 Player_IsEnd
 Description: Indicates whether the song has finished playing
 Input:       -
 Output:      [char] 0 = No, 1 = Yes 
----------------------------------------------------------------------------- */
char Player_IsEnd();



// mute functions, 0=off, other=on
//void muteChannelA(char value);
//void muteChannelB(char value);
//void muteChannelC(char value);


#endif