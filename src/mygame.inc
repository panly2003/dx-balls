;     include files
;     
	  
      include windows.inc
      include masm32.inc
      include gdi32.inc
      include user32.inc
      include kernel32.inc
      include Comctl32.inc
      include comdlg32.inc
      include shell32.inc
      include oleaut32.inc
      include msvcrt.inc
	  include msimg32.inc
      include C:\masm32\macros\macros.asm
      include winmm.inc

;     libraries
;     ~~~~~~~~~
      includelib masm32.lib
      includelib gdi32.lib
      includelib user32.lib
      includelib kernel32.lib
      includelib Comctl32.lib
      includelib comdlg32.lib
      includelib shell32.lib
      includelib oleaut32.lib
      includelib msvcrt.lib
	  includelib msimg32.lib
	  includelib Winmm.lib


      ; -----------------
      ; Local prototypes
      ; -----------------



    ; ���Ա�ʾ���ꡢ�ٶȡ���״��δ�������ٶȣ�����ȡ��ֵ
    ;坐标、速度对象
    point struct
    	x SDWORD 0
    	y SDWORD 0
    point ends
    
    ;矩形碰撞箱对象，存储四条边的坐标
    box struct
    	top		SDWORD 0
    	bottom	SDWORD 0
    	left	SDWORD 0
    	right	SDWORD 0
    box ends

    
      ;球对象
    ball struct
    	pos				box	<>				;碰撞箱，包含位置和大小信息
    	speed			point <>			;速度
		exist           SDWORD 0            ;0表示不存在
    ball ends 

    ;挡板对象
    pad struct
    	pos				box	<>				;碰撞箱，包含位置和大小信息
    	speed			point <>			;速度
    pad ends   

        ;金币对象
    coin struct
    	pos				box <>				;同上
    	speed			point <>			;同上
    	exist			SDWORD 0			
    coin ends
    
    ;砖对象
    block struct
    	pos				box <>				
    	hp				SDWORD 0			
    	block_type		SDWORD 0			
    	exist			SDWORD 0			;0表示已经被消灭
    block ends

    ; ��Ϸ�г���
    .const
    	my_window_width     EQU     1000         ;界面宽
    	my_window_height    EQU     750         ;界面高
        block_width         EQU     120         ;砖长宽
        block_height        EQU     68
        ball_size           EQU     40         ;球长宽
        ;pad_width           EQU     200        ;挡板长宽
        pad_height          EQU     20                 
        coin_size           EQU     45
        coin_speed          EQU     5
        coin_fall_interval   EQU    100          

        sleep_time0         EQU     15          ;初始sleep_time
    	; initialized data allocation
    .data
        rand_p              DWORD     10007       ;用于生成随机数
        rand_b              DWORD     233         ;用于生成随机数
        rand_c              DWORD     7           ;用于生成随机数

        randint                     DWORD   9961        ;随机数
        game_counter                DWORD    0          ;游戏计时器
    	game_status                 BYTE     0          ; 0 ��ʼ���� 1 �������� 2 ��Ϸ���� 3 ���1ʤ�� 4 ���2ʤ��
    	;初始化位图
        menubg                      DWORD    0
        gamebg                      DWORD    0
        endbg                       DWORD    0
        ball_bitmap                 DWORD    0
        pad_bitmap                 DWORD    0
        longpad_bitmap              DWORD   0
        block1_bitmap               DWORD    0
        block2_bitmap               DWORD    0
        block3_bitmap               DWORD    0
		block4_bitmap               DWORD    0
        coin_bitmap                 DWORD    0
		number                      DWORD    0
		row							DWORD    0
		hp							DWORD    3
        key_left                    DWORD    0 
        key_right                    DWORD    0 
        key_up                    DWORD    0 
        key_down                    DWORD    0 
        key_space                    DWORD    0 
        score                        DWORD    0
        sleep_time                   DWORD    15
		pad_speed                   DWORD   4
        pad_width                   DWORD   200
		flag                        DWORD    0
        last_coin                    DWORD     0
        skill_timer              DWORD      0
        skill_duration          DWORD      1000
        longpad                 DWORD       0
        myball            ball        8  DUP (<>) ;最多8个球
		ball_num          DWORD       1
		myball_next       ball        <>
        mypad             pad         <>       
        blocks           block       20  DUP (<>)
        coins            coin        100  DUP (<>) 
        paintstruct      PAINTSTRUCT <>   ;


	; LGL
    	buf              BYTE     20 DUP(0)
        text            BYTE    "%d",0
        strlen           DWORD    0
    	FontName         db "sans-serif",0
	    aMsg            byte        "%s", 0dh, 0ah, 0   ; test uses
        bMsg            byte        "%d", 0ah, 0dh, 0  ; test uses
        filename        byte        "highest_scores.txt", 0
        fileHandle      DWORD       ?
        bytesWritten    DWORD       ?  ; test uses
        Score_player    DWORD       569
        my_score        byte        100 DUP(?)  ; 读入的分数字符串（未转成数字前）
        bytesRead       DWORD       ?  ; test uses

        Score_string    byte        100 DUP(?)  ; 每一个分数刚转完字符串的分数
        write_form      byte        "%d ", 0

        string_len      DWORD       200

        data1           DWORD       0

        form_read       byte        "%d", 0

        read_scores     DWORD       100 DUP(?)

        enemyDeathExe   BYTE        "enemyDeath", 0
        playerDeathExe  BYTE        "playerDeath", 0
	; LGL 

  ; -----------------------------
  ; uninitialised data allocation
  ; -----------------------------
    .data?
        hInstance   DWORD ?          ; ���ڼ�¼����ʵ��
        hWnd        DWORD ?          ; ���
        hIcon       DWORD ?
        hCursor     DWORD ?
        CommandLine DWORD ?

        sWid        DWORD ?          ; ���ڵĿ�Ⱥ͸߶�
        sHgt        DWORD ?

		thread1     DWORD ?
		thread2     DWORD ?
        thread3     DWORD ?
        thread4     DWORD ?
		


      ; -----------------
      ; Local prototypes
      ; -----------------
        Main             PROTO
        MsgLoop          PROTO
        WndProc          PROTO :DWORD,:DWORD,:DWORD,:DWORD
		startGame        PROTO
		loadGameImages   PROTO
		paintThread      PROTO :DWORD
		updateScene      PROTO
        initBall         PROTO
        initPad          PROTO

		paintBall          PROTO :DWORD,:DWORD
		paintPad	     PROTO :DWORD,:DWORD
		paintBlocks	     PROTO :DWORD,:DWORD
		paintBackground      PROTO :DWORD,:DWORD
        paintCoins        PROTO :DWORD,:DWORD

		processKeyUp         PROTO :DWORD
		processKeyDown       PROTO :DWORD
		colliDetect		     PROTO
        updatePadSpeed     PROTO
        updatePadPosition  PROTO
        updatePlayerSpeed    PROTO
        updatePlayerPosition PROTO
        updateBlockPosition  PROTO
		updateBallPosition  PROTO
        coinFall           PROTO :ptr coin
        updateCoinPos      PROTO
        addCoin            PROTO :ptr coin
        initCoin    PROTO
        initBlock           PROTO
        getRandInEdx         PROTO :DWORD
        initGame             PROTO
        paintScore           PROTO :DWORD
        getStringLength  PROTO :PTR BYTE
        enemyDeathSound      PROTO
        playerDeathSound     PROTO
		isOver               PROTO
		startUpSkills        PROTO
		
		           