    ; __UNICODE__ equ 1           ; uncomment to enable UNICODE build

    .686p                       ; create 32 bit code
    .mmx                        ; enable MMX instructions
    .xmm                        ; enable SSE instructions
    .model flat, stdcall        ; 32 bit memory model
    option casemap :none        ; case sensitive

    bColor   equ  <00999999h>   ; client area brush colour
    include	mygame.inc			; local includes for this file 
	include msvcrt.inc

	ReadFromFile PROTO   		; read buffer from input file
	WriteToFile PROTO		; write a buffer to an output file
	sscanf  PROTO   C   :ptr byte, :VARARG
	sprintf PROTO  C  :ptr sbyte, :VARARG
	OpenInputFile PROTO		; open file in input mode
	CloseFile PROTO		; close a file handle
	CreateOutputFile PROTO		; create file for writing

.code
start:  ;������ڵ�
    ; ���ģ����
	invoke GetModuleHandle, NULL;�����������̵Ŀ�ִ���ļ��Ļ���ַ
	mov hInstance, eax ;hinstanse��ͨ������Ӧ�ó���ʵ����������԰����������ʵ��

	; ���ܲ���Ҫ�����в���
	; invoke GetCommandLine
	; mov  CommandLine, eax
	; ; �õ�ͼ��͹��
    ; mov hIcon,       rv(LoadIcon,hInstance,103)
    ; mov hCursor,     rv(LoadCursor,NULL,IDC_ARROW)
	; �õ�������Ļ�ĳߴ�
    mov sWid,        rv(GetSystemMetrics,SM_CXSCREEN)
    mov sHgt,        rv(GetSystemMetrics,SM_CYSCREEN)
	; ����������
    call Main
    invoke ExitProcess, eax

Main proc
    LOCAL Wwd:DWORD,Wht:DWORD,Wtx:DWORD,Wty:DWORD
    LOCAL wc:WNDCLASSEX
    LOCAL icce:INITCOMMONCONTROLSEX

  ; --------------------------------------
  ; comment out the styles you don't need.
  ; --------------------------------------
    mov icce.dwSize, SIZEOF INITCOMMONCONTROLSEX            ; set the structure size
    xor eax, eax                                            ; set EAX to zero
    or eax, ICC_WIN95_CLASSES
    or eax, ICC_BAR_CLASSES                                 ; comment out the rest
    mov icce.dwICC, eax
    invoke InitCommonControlsEx,ADDR icce                   ; initialise the common control library
  ; --------------------------------------

    STRING szClassName,   "GameClass" ;��
    STRING szDisplayName, "Dx-balls" 

  ; ---------------------------------------------------
  ; set window class attributes in WNDCLASSEX structure
  ; ---------------------------------------------------
    mov wc.cbSize,         sizeof WNDCLASSEX
    mov wc.style,          CS_BYTEALIGNCLIENT or CS_BYTEALIGNWINDOW
    m2m wc.lpfnWndProc,    OFFSET WndProc
    mov wc.cbClsExtra,     NULL
    mov wc.cbWndExtra,     NULL
    m2m wc.hInstance,      hInstance
    m2m wc.hbrBackground,  NULL                 ;COLOR_BTNFACE+1 ����Ҫbackground
    mov wc.lpszMenuName,   NULL
    mov wc.lpszClassName,  OFFSET szClassName  ;;
    m2m wc.hIcon,          hIcon
    m2m wc.hCursor,        hCursor
    m2m wc.hIconSm,        hIcon

  ; ------------------------------------
  ; register class with these attributes
  ; ------------------------------------
    invoke RegisterClassEx, ADDR wc

  ; ---------------------------------------------
  ; set width and height abosulte length
  ; ---------------------------------------------
    mov Wwd, my_window_width ;��
    mov Wht, my_window_height ;��

  ; ------------------------------------------------
  ; Top X and Y co-ordinates for the centered window
  ; ------------------------------------------------
    mov eax, sWid
    sub eax, Wwd                ; sub window width from screen width
    shr eax, 1                  ; divide it by 2
    mov Wtx, eax                ; copy it to variable

    mov eax, sHgt
    sub eax, Wht                ; sub window height from screen height
    shr eax, 1                  ; divide it by 2
    mov Wty, eax                ; copy it to variable
	

  ; -----------------------------------------------------------------
  ; create the main window with the size and attributes defined above
  ; -----------------------------------------------------------------
    invoke CreateWindowEx,WS_EX_LEFT or WS_EX_ACCEPTFILES,
                          ADDR szClassName,
                          ADDR szDisplayName,
                          WS_OVERLAPPED or WS_SYSMENU,
                          Wtx,Wty,Wwd,Wht,
                          NULL,NULL,
                          hInstance,NULL
    mov hWnd,eax
    invoke ShowWindow,hWnd, SW_SHOWNORMAL
    invoke UpdateWindow,hWnd

	; ��Ϣѭ��
    call MsgLoop
    ret
Main endp

; ��Ϣѭ��
MsgLoop proc
    LOCAL msg:MSG
    push ebx
    lea ebx, msg
    jmp getmsg
  msgloop:
    invoke TranslateMessage, ebx
    invoke DispatchMessage,  ebx
  getmsg:
    invoke GetMessage,ebx,0,0,0 ;�ú����ӵ����̵߳���Ϣ������ȡ��һ����Ϣ���������ָ���Ľṹ���˺�����ȡ����ָ��������ϵ����Ϣ
	test eax, eax
    jnz msgloop
    pop ebx
    ret
MsgLoop endp

Sort_RankingList proc
	.IF game_status == 3
		mov         edx, offset filename
		call        OpenInputFile
		mov         fileHandle, eax
		
		mov         edx, offset my_score
		mov         ecx, string_len
		call        ReadFromFile
		; mov         bytesRead, eax
		; invoke      printf, offset bMsg, eax

		mov         esi, read_scores
		invoke	    sscanf, offset my_score, offset form_read, offset data1
		mov         esi, offset read_scores
		mov         eax, data1
		mov         [esi], eax
		add         esi, 4

close_file:
		mov         eax, fileHandle
		call        CloseFile

mov         string_len, 0  

		mov         edx, offset filename
		call        CreateOutputFile
		mov         fileHandle, eax

		mov          esi, offset read_scores
		add          esi, 4  
		mov          eax, score
		mov          [esi], eax


		pushad
		mov esi, offset read_scores
		mov eax,[esi]
		mov ebx,[esi+4]
		.if eax < ebx
		mov [esi],ebx
		mov [esi+4],eax
		.endif
		popad

		;//////////////////////////////////////////////////////////move back to data1-10
		mov         esi, offset read_scores
		mov         eax, [esi]
		mov         data1, eax
		add         esi, 4

		mov          ecx, 1
		mov          esi, offset read_scores
writeBack:             
		mov          ebx, [esi]   
		pushad
		invoke       sprintf, ADDR Score_string, ADDR write_form, ebx 
		
		add          string_len, eax 


		mov          ecx, eax 
		mov          eax, fileHandle
		mov          edx, offset Score_string
		call         WriteToFile

		popad
		add          esi, 4  ; DWORD!
		loop         writeBack

		mov          eax, fileHandle
		;invoke      printf, offset bMsg, string_len
		call         CloseFile
		mov game_status, 2
	.ENDIF
	ret
Sort_RankingList endp

WndProc proc hWin:DWORD, uMsg:DWORD, wParam:DWORD, lParam:DWORD
	assume edi:ptr ball

	; �����ڴ������һЩ����
	.IF uMsg == WM_CREATE
		invoke startGame

	.ELSEIF uMsg == WM_DESTROY
		; �˳��߳�
		invoke PostQuitMessage, NULL

	.ELSEIF uMsg == WM_PAINT
		; ���ø��³���������WM_PAINT��paintThread��InvalidateRect����
		invoke updateScene

	.ELSEIF uMsg == WM_CHAR
		; ����enter�������¼�
		.IF wParam == 13
			.IF game_status == 0
				pushad ;�������üĴ�������
				invoke PlaySound, 154, hInstance, SND_RESOURCE or SND_ASYNC or SND_LOOP
				popad
				invoke initGame
				mov game_status, 1
				mov game_counter, 0
			 .ELSEIF game_status == 2
			 	mov game_status, 0
			 	pushad
			 	invoke PlaySound, 150, hInstance, SND_RESOURCE or SND_ASYNC or SND_LOOP
				; ����
				mov ball_num, 1
				mov edi, offset myball
				mov [edi].speed.x, 4
				mov [edi].speed.y, -4
				mov pad_speed, 4
			 	popad
			.ENDIF
		.ENDIF
	.ELSEIF uMsg == WM_KEYUP
	  invoke processKeyUp, wParam
	  ;�������̧���¼�

	.ELSEIF uMsg == WM_KEYDOWN
	  invoke processKeyDown, wParam
	  ;������̰����¼�

	.ELSE
		; Ĭ����Ϣ������
		invoke DefWindowProc,hWin,uMsg,wParam,lParam
		ret
	.ENDIF
	xor eax, eax
	ret
WndProc endp

;���°���
processKeyDown proc wParam:WPARAM;wParam������Ϣ������wndProc����
	; .IF game_status == 1
	;���� ��
	.IF wParam == VK_LEFT
	mov key_left, 1
	;���� ��
	.ELSEIF wParam == VK_RIGHT
	mov key_right, 1
	;���� ��
	.ELSEIF wParam == VK_UP
	mov key_up, 1
	;���� ��
	.ELSEIF wParam == VK_DOWN
	mov key_down, 1
	;���� �ո�
	.ELSEIF wParam == 20h
	mov key_space, 1
	.ENDIF
	; .ENDIF
	ret
processKeyDown endp

;�ɿ�����
processKeyUp proc wParam:WPARAM;wParam������Ϣ������wndProc����
	; .IF game_status == 1
	;�ɿ� ��
	.IF wParam == VK_LEFT
	mov key_left, 0
	;���� ��
	.ELSEIF wParam == VK_RIGHT
	mov key_right, 0
	;���� ��
	.ELSEIF wParam == VK_UP
	mov key_up, 0
	;���� ��
	.ELSEIF wParam == VK_DOWN
	mov key_down, 0
	;���� �ո�
	.ELSEIF wParam == 20h
	mov key_space, 0
	.ENDIF
	; .ENDIF
	ret
processKeyUp endp


initGame proc uses esi ecx,

	mov esi, offset blocks
	mov ecx, lengthof blocks
L1:
	mov (block ptr [esi]).exist, 0
	add esi, sizeof block
	loop L1

	mov esi, offset coins
	mov ecx, lengthof coins
L2:
	mov (coin ptr [esi]).exist, 0
	add esi, sizeof coin
	loop L2

	mov game_counter, 0
	mov last_coin, 0
	mov key_left, 0
	mov key_right, 0
	mov key_up, 0
	mov key_down, 0
	mov key_space, 0
	mov score, 0
	mov sleep_time, sleep_time0
	invoke initBall
	invoke initPad
	invoke initCoin
	ret
initGame endp

initBall proc
	assume edi:ptr ball
	;��һ��С��
	mov  edi, offset  myball
	mov [edi].pos.top, my_window_height
	sub [edi].pos.top, pad_height
	sub [edi].pos.top, ball_size
	sub [edi].pos.top, 80
	mov [edi].pos.bottom, my_window_height
	sub [edi].pos.bottom, pad_height
	sub [edi].pos.bottom, 80
	mov [edi].pos.left, 400
	mov [edi].pos.right, 440
	mov [edi].speed.x, 4
	mov [edi].speed.y, -4
	mov [edi].exist, 1
	ret
initBall endp


initPad proc
	mov mypad.pos.top, my_window_height
	sub mypad.pos.top, pad_height
	sub mypad.pos.top, 80
	mov mypad.pos.bottom, my_window_height
	sub mypad.pos.bottom, 80
	mov mypad.pos.left, 400
	mov mypad.pos.right, 600
	mov mypad.speed.x, 0
	mov mypad.speed.y, 0
	ret
initPad endp


;���ɽ��
initCoin proc uses eax edx ecx esi edi ebx
;-----------------------------------------------------------------
	LOCAL tempCoin:coin, randResult:DWORD
	
	;����������
	mov tempCoin.pos.bottom, 0
	mov tempCoin.pos.top, 0
	sub tempCoin.pos.top, coin_size

	;��������ĺ�����
	invoke getRandInEdx, 750
	add edx, 80
	mov tempCoin.pos.left, edx
	add edx, coin_size
	mov tempCoin.pos.right, edx

	mov eax, game_counter
	sub eax, last_coin
	.IF eax < coin_fall_interval
		ret
	.ENDIF
	mov edx, 0
	mov ebx, 15
	div ebx

	.IF edx != 0
		ret
	.ENDIF

	mov tempCoin.speed.x, 0
	mov tempCoin.speed.y, coin_speed

	mov tempCoin.exist, 1								;���״̬������
	mov eax, game_counter								
	mov last_coin, eax									;���һ�ν������ʱ�䣺����

	lea esi, tempCoin
	mov edi, offset coins
	mov ecx, lengthof coins

L1:
	mov eax, (coin ptr [edi]).exist
	.IF eax == 0
		jmp L2
	.ENDIF


	add edi, sizeof coin
	loop L1

L2:	mov ecx, sizeof coin

L3:
	mov al, byte ptr [esi]
	mov byte ptr [edi], al
	inc esi
	inc edi
	loop L3

L4:	
	ret
initCoin endp

startGame  proc
		; ����ͼƬ
		invoke loadGameImages
		; �����߼��߳�
		mov eax, OFFSET logicThread
		invoke CreateThread, NULL, NULL, eax, 0, 0, addr thread1
		invoke CloseHandle, eax
		; ��������߳�
		mov eax, OFFSET paintThread
		invoke CreateThread, NULL, NULL, eax, 0, 0, addr thread2 ;������IDΪthread2���߳�
		invoke CloseHandle, eax
		;���ű�������
		pushad
		invoke PlaySound, 150, hInstance, SND_RESOURCE or SND_ASYNC or SND_LOOP
		popad

		ret
startGame endp

; һ���̺߳��������ݳ�����״̬����ѭ������Ϸ״̬ʱ�򣬲��Ͻ�����ײ�жϵȵ�
logicThread proc uses eax ecx,
	p:DWORD, 
	;LOCAL area:RECT
	game:
	; ��ʼ���棬��Ҫͨ��enter����
	.WHILE game_status == 0
		invoke Sleep, 1000
	.ENDW

	; ��Ϸ����
	.IF game_status == 1
		invoke crt_time, eax
		mov randint, eax
		push ecx
		mov ecx,4
	L0:
		mov row,ecx
		push ecx
		mov ecx,5
		L1:
		mov number,ecx
		; ����ש��
		invoke initBlock
		loop L1
		pop ecx
		loop L0

		pop ecx

		.WHILE game_status == 1
			invoke Sleep,sleep_time

			; С��λ�ø���
			invoke updateBallPosition

			; �����ٶȸ���
			invoke updatePadSpeed

			; ����λ�ø���
			invoke updatePadPosition

			;���ɽ��
			invoke initCoin

			;���λ�ø���
			invoke updateCoinPos

			;�ж��Ƿ�ȫ�����
			invoke isOver

			mov eax, game_counter
			inc eax
			mov game_counter, eax


			.if longpad
				mov eax, game_counter
				sub eax, skill_timer
				.if eax > skill_duration 
					mov longpad, 0
					sub mypad.pos.right, 100
					sub pad_width, 100
				.endif
			.endif

		.ENDW
	.ENDIF
	.while game_status == 2
		invoke Sleep,1000
	.endw

	jmp game
	ret
logicThread endp

; ��������
startUpSkills proc
	LOCAL randResult:DWORD
	assume edi:ptr ball

	invoke getRandInEdx, 100
	mov randResult, edx
	.IF randResult < 25
		;��������䳤����
		.if !longpad
			mov longpad, 1
			add mypad.pos.right, 100
			add pad_width, 100
			mov eax, game_counter
			mov skill_timer, eax
		.endif
		ret									
	.ELSEIF randResult < 40							
		;����С���ٶȱ�켼��
		mov edi, offset myball
		mov ecx, ball_num
		.while ecx != 0
			.IF [edi].speed.x > 0
				add [edi].speed.x, 1
			.ELSE
				sub [edi].speed.x, 1
			.ENDIF
			.IF [edi].speed.y > 0
				add [edi].speed.y, 1
			.ELSE
				sub [edi].speed.y, 1
			.ENDIF
			dec ecx
			add edi, type ball
		.endw
		ret	
	.ELSEIF randResult < 55							
		;���������ٶȱ�켼��
		add pad_speed, 1
		ret	
	.ELSEIF randResult < 65
		;����С�����+1 ����
		.IF ball_num != 8
			; ��������һ��С���λ��Ų��edi
			mov edi, offset myball
			mov ecx, ball_num
			.WHILE ecx != 0
				add edi, type ball
				dec ecx
			.ENDW

			; С������+1
			add ball_num, 1

			; ��������С�򸳳�ʼ����
			mov [edi].pos.top, my_window_height
			sub [edi].pos.top, pad_height
			sub [edi].pos.top, ball_size
			sub [edi].pos.top, 80
			mov [edi].pos.bottom, my_window_height
			sub [edi].pos.bottom, pad_height
			sub [edi].pos.bottom, 80
			mov edx, mypad.pos.left
			mov [edi].pos.left, edx
			add edx, 40
			mov [edi].pos.right, edx
			mov [edi].speed.x, 4
			mov [edi].speed.y, -4
			mov [edi].exist, 1
			ret
		.ENDIF
	.ELSE
		ret
	.ENDIF
startUpSkills endp

updateBallPosition proc  uses edi esi ebx eax
	assume edi:ptr ball
	assume esi:ptr block
	.IF game_status == 1
    	mov    edi, offset  myball
		mov ecx, ball_num
		.WHILE ecx != 0
			pushad
			mov eax, [edi].pos.top
			add eax, [edi].speed.y
			mov myball_next.pos.top, eax
		
			mov eax, [edi].pos.bottom
			add eax, [edi].speed.y
			mov myball_next.pos.bottom, eax

			mov eax, [edi].pos.left
			add eax, [edi].speed.x
			mov myball_next.pos.left, eax

			mov eax, [edi].pos.right
			add eax, [edi].speed.x
			mov myball_next.pos.right, eax
		
	
			; �ʹ�����ײ
			; �ʹ����Ҳ���ײ
			.IF myball_next.pos.right > my_window_width  
				neg [edi].speed.x
			.ENDIF
			; �ʹ����ϲ���ײ
			.IF myball_next.pos.top < 0  
				neg [edi].speed.y
			.ENDIF
			; �ʹ��������ײ
			.IF myball_next.pos.left < 0  
				neg [edi].speed.x
			.ENDIF

			;�͵�����ײ 
			mov eax, mypad.pos.top
			.IF myball_next.pos.bottom > eax
				mov eax, myball_next.pos.left
				.IF eax < mypad.pos.right && eax > mypad.pos.left
					.IF flag != 1
						neg [edi].speed.y
						mov flag, 1
					.ENDIF
				.ElSE 
					mov flag, 0
					mov eax, myball_next.pos.right
					.IF eax < mypad.pos.right && eax > mypad.pos.left
						neg [edi].speed.y
					.ENDIF
				.ENDIF
			.ELSE
				mov flag, 0
			.ENDIF

			;��ש����ײ
			mov ebx, 20
			.WHILE ebx > 0
				mov edx, ebx
				dec edx
				mov eax, 0
				mov esi, offset blocks
				.WHILE edx > 0
					add esi, type block
					dec edx
				.ENDW

				cmp [esi].exist, 0
				je L1

				; 1 ������б�Ϸ�
				.IF [edi].speed.x>0 && [edi].speed.y<0
					mov eax, [esi].pos.top
					mov edx, [esi].pos.left

					; 1.1 ��������Ͻ�ײש��
					.IF ((myball_next.pos.right > edx) && (myball_next.pos.top > eax))
						mov eax, [esi].pos.bottom
						mov edx, [esi].pos.right
						.IF ((myball_next.pos.right < edx) && (myball_next.pos.top < eax))
							sub edx, myball_next.pos.left
							sub eax, myball_next.pos.top
							.IF edx < eax
								neg [edi].speed.x
							.ELSE
								neg [edi].speed.y
							.ENDIF
							; ש����ʧ
							.IF [esi].block_type != 4
								mov eax, 0
								mov [esi].exist, eax
								add score,10
								.IF [esi].block_type == 3
									invoke startUpSkills
								.ENDIF
								jmp L2
							.ENDIF
							.break
						.ENDIF
					.ENDIF
			

					; 1.2 ��������Ͻ�ײש��
					mov eax, [esi].pos.top
					mov edx, [esi].pos.left
					.IF ((myball_next.pos.left > edx) && (myball_next.pos.top > eax))
							mov eax, [esi].pos.bottom
							mov edx, [esi].pos.right
							.IF ((myball_next.pos.left < edx) && (myball_next.pos.top < eax))
								sub edx, myball_next.pos.left
								sub eax, myball_next.pos.top
								.IF edx < eax
									neg [edi].speed.x
								.ELSE
									neg [edi].speed.y
								.ENDIF
								; ש����ʧ
								.IF [esi].block_type != 4
									mov eax, 0
									mov [esi].exist, eax
									add score,10
									.IF [esi].block_type == 3
										invoke startUpSkills
									.ENDIF
									jmp L2
								.ENDIF
								.break
							.ENDIF
					.ENDIF

					; 1.3 ��������½�ײש��
					mov eax, [esi].pos.top
					mov edx, [esi].pos.left
					.IF ((myball_next.pos.right > edx) && (myball_next.pos.bottom > eax))
							mov eax, [esi].pos.bottom
							mov edx, [esi].pos.right
							.IF ((myball_next.pos.right < edx) && (myball_next.pos.bottom < eax))
								mov edx, [esi].pos.left
								sub edx, myball_next.pos.right
								neg edx
								mov eax, [esi].pos.top
								sub eax, myball_next.pos.bottom
								neg eax
								.IF edx < eax
									neg [edi].speed.x
								.ELSE
									neg [edi].speed.y
								.ENDIF
								; ש����ʧ
								.IF [esi].block_type != 4
									mov eax, 0
									mov [esi].exist, eax
									add score,10
									.IF [esi].block_type == 3
										invoke startUpSkills
									.ENDIF
									jmp L2
								.ENDIF
								.break
							.ENDIF
					.ENDIF
				.ENDIF

				; 2 ������б�Ϸ�
				.IF [edi].speed.x<0 && [edi].speed.y<0
					; 2.1��������Ͻ�ײש��
					mov eax, [esi].pos.top
					mov edx, [esi].pos.left
					.IF ((myball_next.pos.left > edx) && (myball_next.pos.top > eax))
						mov eax, [esi].pos.bottom
						mov edx, [esi].pos.right
						.IF ((myball_next.pos.left < edx) && (myball_next.pos.top < eax))
							sub edx, myball_next.pos.left
							sub eax, myball_next.pos.top
							.IF edx < eax
								neg [edi].speed.x
							.ELSE
								neg [edi].speed.y
							.ENDIF
							; ש����ʧ
							.IF [esi].block_type != 4
								mov eax, 0
								mov [esi].exist, eax
								add score,10
								.IF [esi].block_type == 3
									invoke startUpSkills
								.ENDIF
								jmp L2
							.ENDIF
							.break
						.ENDIF
					.ENDIF

					;2.2 ������Ͻ�ײש��
					mov eax, [esi].pos.top
					mov edx, [esi].pos.left
					.IF ((myball_next.pos.right > edx) && (myball_next.pos.top > eax))
						mov eax, [esi].pos.bottom
						mov edx, [esi].pos.right
						.IF ((myball_next.pos.right < edx) && (myball_next.pos.top < eax))
							mov edx, [esi].pos.left
							sub edx, myball_next.pos.right
							neg edx
							mov eax, [esi].pos.bottom
							sub eax, myball_next.pos.top
							.IF edx < eax
								neg [edi].speed.x
							.ELSE
								neg [edi].speed.y
							.ENDIF
							; ש����ʧ
							.IF [esi].block_type != 4
								mov eax, 0
								mov [esi].exist, eax
								add score,10
								.IF [esi].block_type == 3
									invoke startUpSkills
								.ENDIF
								jmp L2
							.ENDIF
							.break
						.ENDIF
					.ENDIF

					;2.3 ������½�ײש��
					mov eax, [esi].pos.top
					mov edx, [esi].pos.left
					.IF ((myball_next.pos.left > edx) && (myball_next.pos.bottom > eax))
						mov eax, [esi].pos.bottom
						mov edx, [esi].pos.right
						.IF ((myball_next.pos.left < edx) && (myball_next.pos.bottom < eax))
							sub edx, myball_next.pos.left
							mov eax, [esi].pos.top
							sub eax, myball_next.pos.bottom
							neg eax
							.IF edx < eax
								neg [edi].speed.x
							.ELSE
								neg [edi].speed.y
							.ENDIF
							; ש����ʧ
							.IF [esi].block_type != 4
								mov eax, 0
								mov [esi].exist, eax
								add score,10
								.IF [esi].block_type == 3
									invoke startUpSkills
								.ENDIF
								jmp L2
							.ENDIF
							.break
						.ENDIF
					.ENDIF
				.ENDIF

				; 3 ������б�·�
				.IF [edi].speed.x<0 && [edi].speed.y>0
					; 3.1 ������½�ײש��
					mov eax, [esi].pos.bottom
					mov edx, [esi].pos.left
					.IF ((myball_next.pos.left > edx) && (myball_next.pos.bottom < eax))
						mov eax, [esi].pos.top
						mov edx, [esi].pos.right
						.IF ((myball_next.pos.left < edx) && (myball_next.pos.bottom > eax))
							sub edx, myball_next.pos.left
							sub eax, myball_next.pos.bottom
							neg eax
							.IF edx < eax
								neg [edi].speed.x
							.ELSE
								neg [edi].speed.y
							.ENDIF
							; ש����ʧ
							.IF [esi].block_type != 4
								mov eax, 0
								mov [esi].exist, eax
								add score,10
								.IF [esi].block_type == 3
									invoke startUpSkills
								.ENDIF
								jmp L2
							.ENDIF
							.break
						.ENDIF
					.ENDIF

					; 3.2 ������Ͻ�ײש��
					mov eax, [esi].pos.bottom
					mov edx, [esi].pos.left
					.IF ((myball_next.pos.left > edx) && (myball_next.pos.top < eax))
						mov eax, [esi].pos.top
						mov edx, [esi].pos.right
						.IF ((myball_next.pos.left < edx) && (myball_next.pos.top > eax))
							sub edx, myball_next.pos.left
							mov eax, [esi].pos.bottom
							sub eax, myball_next.pos.top
							.IF edx < eax
								neg [edi].speed.x
							.ELSE
								neg [edi].speed.y
							.ENDIF
							; ש����ʧ
							.IF [esi].block_type != 4
								mov eax, 0
								mov [esi].exist, eax
								add score,10
								.IF [esi].block_type == 3
									invoke startUpSkills
								.ENDIF
								jmp L2
							.ENDIF
							.break
						.ENDIF
					.ENDIF

					; 3.3 ������½�ײש��
					mov eax, [esi].pos.bottom
					mov edx, [esi].pos.left
					.IF ((myball_next.pos.right > edx) && (myball_next.pos.bottom < eax))
						mov eax, [esi].pos.top
						mov edx, [esi].pos.right
						.IF ((myball_next.pos.right < edx) && (myball_next.pos.bottom > eax))
							mov edx, [esi].pos.left
							sub edx, myball_next.pos.right
							neg edx
							sub eax, myball_next.pos.bottom
							neg eax
							.IF edx < eax
								neg [edi].speed.x
							.ELSE
								neg [edi].speed.y
							.ENDIF
							; ש����ʧ
							.IF [esi].block_type != 4
								mov eax, 0
								mov [esi].exist, eax
								add score,10
								.IF [esi].block_type == 3
									invoke startUpSkills
								.ENDIF
								jmp L2
							.ENDIF
							.break
						.ENDIF
					.ENDIF
				.ENDIF

				; 4 ������б�·�
				.IF [edi].speed.x>0 && [edi].speed.y>0
					; 4.1 ������½�ײש��
					mov eax, [esi].pos.bottom
					mov edx, [esi].pos.right
					.IF ((myball_next.pos.right < edx) && (myball_next.pos.bottom < eax))
						mov eax, [esi].pos.top
						mov edx, [esi].pos.left
						.IF ((myball_next.pos.right > edx) && (myball_next.pos.bottom > eax))
							sub edx, myball_next.pos.right
							sub eax, myball_next.pos.bottom
							neg edx
							neg eax
							.IF edx < eax
								neg [edi].speed.x
							.ELSE
								neg [edi].speed.y
							.ENDIF
							; ש����ʧ
							.IF [esi].block_type != 4
								mov eax, 0
								mov [esi].exist, eax
								add score,10
								.IF [esi].block_type == 3
									invoke startUpSkills
								.ENDIF
								jmp L2
							.ENDIF
							.break
						.ENDIF
					.ENDIF

					; 4.2 ������½�ײש��
					mov eax, [esi].pos.bottom
					mov edx, [esi].pos.right
					.IF ((myball_next.pos.left < edx) && (myball_next.pos.bottom < eax))
						mov eax, [esi].pos.top
						mov edx, [esi].pos.left
						.IF ((myball_next.pos.left > edx) && (myball_next.pos.bottom > eax))
							mov edx, [esi].pos.right
							sub edx, myball_next.pos.left
							sub eax, myball_next.pos.bottom
							neg eax
							.IF edx < eax
								neg [edi].speed.x
							.ELSE
								neg [edi].speed.y
							.ENDIF
							; ש����ʧ
							.IF [esi].block_type != 4
								mov eax, 0
								mov [esi].exist, eax
								add score,10
								.IF [esi].block_type == 3
									invoke startUpSkills
								.ENDIF
								jmp L2
							.ENDIF
							.break
						.ENDIF
					.ENDIF

					; 4.2 ������Ͻ�ײש��
					mov eax, [esi].pos.bottom
					mov edx, [esi].pos.right
					.IF ((myball_next.pos.right < edx) && (myball_next.pos.top < eax))
						mov eax, [esi].pos.top
						mov edx, [esi].pos.left
						.IF ((myball_next.pos.right > edx) && (myball_next.pos.top > eax))
							sub edx, myball_next.pos.right
							neg edx
							mov eax, [esi].pos.bottom
							sub eax, myball_next.pos.top
							.IF edx < eax
								neg [edi].speed.x
							.ELSE
								neg [edi].speed.y
							.ENDIF
							; ש����ʧ
							.IF [esi].block_type != 4
								mov eax, 0
								mov [esi].exist, eax
								add score,10
								.IF [esi].block_type == 3
									invoke startUpSkills
								.ENDIF
								jmp L2
							.ENDIF
							.break
						.ENDIF
					.ENDIF

				.ENDIF

				L1:
				dec ebx
			.ENDW
		
			; �޸�λ��
			L2:
			mov     eax, [edi].speed.x
			add		[edi].pos.left, eax
			add		[edi].pos.right, eax

			mov     eax, [edi].speed.y
			add		[edi].pos.top, eax
			add		[edi].pos.bottom, eax

			.IF [edi].pos.top > my_window_height   ;��Ծ���±߽�����óɲ�����
				mov [edi].exist, 0
				mov game_status, 3
				invoke PlaySound, 155, hInstance, SND_RESOURCE or SND_ASYNC or SND_LOOP
			.ENDIF
			
			popad
			dec ecx
			add edi, type ball

		.ENDW
	.ENDIF
	ret
updateBallPosition endp

updatePadSpeed proc uses eax ebx ecx edi
	mov eax, pad_speed

	.IF key_left == 1
		mov mypad.speed.x, eax
		neg mypad.speed.x
	.ELSE
		.IF key_right == 1;��
			mov mypad.speed.x, eax
		.ELSE;��
			mov mypad.speed.x, 0
		.ENDIF
	.ENDIF
	ret
updatePadSpeed endp 

updatePadPosition proc uses eax ebx ecx edx
	mov eax, mypad.speed.x
	mov ebx, mypad.speed.y
	;�ƶ�
	add mypad.pos.top, ebx
	add mypad.pos.bottom, ebx
	add mypad.pos.left, eax
	add mypad.pos.right, eax
	;��������Ƿ񳬳��߿�
	;mov ecx, real_player_heightW
	mov ecx, pad_height
	mov edx, my_window_height
	.IF mypad.pos.top < 0
	mov mypad.pos.top, 0
	mov mypad.pos.bottom, ecx
	.ENDIF
	.IF mypad.pos.bottom > edx
	mov mypad.pos.bottom, edx
	mov mypad.pos.top, edx
	sub mypad.pos.top, ecx
	.ENDIF
	;��������Ƿ񳬳��߿�
	;mov ecx, real_player_width
	mov ecx, pad_width
	mov edx, my_window_width
	.IF mypad.pos.left < 0
	mov mypad.pos.left, 0
	mov mypad.pos.right, ecx
	.ENDIF
	.IF mypad.pos.right > edx
	mov mypad.pos.right, edx
	mov mypad.pos.left, edx
	sub mypad.pos.left, ecx
	.ENDIF
	ret
updatePadPosition endp


updateCoinPos proc  uses ecx edi
	assume edi:ptr coin 
	.IF game_status == 1
    	mov    edi, offset  coins
		mov	   ecx, lengthof coins

		L2:
	        push   ecx
			push	edi

			mov     eax, [edi].speed.x
			add		[edi].pos.left, eax
			add		[edi].pos.right, eax

			mov     eax, [edi].speed.y
			add		[edi].pos.top, eax
			add		[edi].pos.bottom, eax
			.IF [edi].pos.top > my_window_height   
			    mov [edi].exist, 0
			.ENDIF
			mov eax, mypad.pos.left
			mov ebx, mypad.pos.right
			mov edx, mypad.pos.top
			.IF ([edi].exist) && ([edi].pos.bottom >= edx) && ([edi].pos.right > eax) && ([edi].pos.left < ebx)
				mov [edi].exist, 0
				add score, 10
			.ENDIF
			pop		edi
            add		edi, type coin
			pop		ecx
			dec		ecx
			cmp		ecx, 0
			jne L2
	.ENDIF
	ret
updateCoinPos endp

;�ж��Ƿ�ȫ���
isOver proc
	assume edi:ptr block
	LOCAL flag_:DWORD
	mov flag_, 0 ;��Ϸ����
	mov ecx, 20
	mov edi, offset blocks
	.WHILE ecx != 0
		.IF [edi].exist == 1 && [edi].block_type != 4
			mov flag_, 1
			.break
		.ENDIF
		add edi, type block
		dec ecx
	.ENDW
	.IF flag_ == 0
		add score, 200
		mov game_status, 3
		invoke PlaySound, 155, hInstance, SND_RESOURCE or SND_ASYNC or SND_LOOP
	.ENDIF
	ret
isOver endp

;����λͼ
loadGameImages proc
	; ���ؿ�ʼ�����λͼ
	invoke LoadBitmap, hInstance, 500
	mov menubg, eax
	
    ; ������Ϸ�����λͼ
	invoke LoadBitmap, hInstance, 501
	mov gamebg, eax
    
	; ����С��λͼ
	invoke LoadBitmap, hInstance, 517
	mov ball_bitmap, eax

	; ���ص����λͼ
	invoke LoadBitmap, hInstance, 518
	mov pad_bitmap, eax  


	; ���س������λͼ
	invoke LoadBitmap, hInstance, 520
	mov longpad_bitmap, eax  
    
    ; ����ש��1��λͼ
    invoke LoadBitmap, hInstance, 511
	mov block1_bitmap, eax
    
    ; ����ש��2��λͼ
    invoke LoadBitmap, hInstance, 512
	mov block2_bitmap, eax
    
    ; ����ש��3��λͼ
    invoke LoadBitmap, hInstance, 513
	mov block3_bitmap, eax

	; ����ש��4��λͼ
    invoke LoadBitmap, hInstance, 514
	mov block4_bitmap, eax

	;���ؽ��λͼ
	invoke LoadBitmap, hInstance, 519
	mov coin_bitmap, eax

	; ���ص÷�ҳ���λͼ
	invoke LoadBitmap, hInstance, 502
	mov endbg, eax
    ret
loadGameImages endp

paintThread proc p:DWORD
	.WHILE 1
		invoke Sleep, 10
		invoke InvalidateRect, hWnd, NULL, FALSE
	.ENDW
	ret
paintThread endp

; �������º���
updateScene proc uses eax
	LOCAL member_hdc:HDC
	LOCAL member_hdc2:HDC
	LOCAL h_bitmap:HDC
	LOCAL hdc: HDC

	invoke BeginPaint, hWnd, ADDR paintstruct
	mov hdc, eax     ;����hwnd��

	invoke CreateCompatibleDC, hdc  ;�ú�������һ����ָ���豸���ݵ�**�ڴ��豸**�����Ļ�����DC��
	mov member_hdc, eax
	invoke CreateCompatibleDC, hdc
	mov member_hdc2, eax
	invoke CreateCompatibleBitmap, hdc, my_window_width, my_window_height
	mov h_bitmap, eax

	;��λͼѡ�񵽼���DC��
	invoke SelectObject, member_hdc, h_bitmap

	;���Ʊ���
	invoke paintBackground, member_hdc, member_hdc2

	;������
	invoke paintBall, member_hdc, member_hdc2

	;���Ƶ���
	invoke paintPad, member_hdc, member_hdc2

	;����ש��
	invoke paintBlocks, member_hdc, member_hdc2

	;���ƽ��
	invoke paintCoins, member_hdc, member_hdc2

	invoke Sort_RankingList


	;���Ʒ���
	invoke paintScore, member_hdc

	; BitBlt��hDestDC, x, y, nWidth, nheight, hSrcDC, xSrc, ySrc, dwRop��
	; ��Դ��������ֱ�ӿ�����Ŀ������SRCCOPY
	invoke BitBlt, hdc, 0, 0, my_window_width, my_window_height, member_hdc, 0, 0, SRCCOPY


	invoke DeleteDC, member_hdc
	invoke DeleteDC, member_hdc2
	invoke DeleteObject, h_bitmap
	invoke EndPaint, hWnd, ADDR paintstruct
	ret
updateScene endp


; ����ƺ���
paintBall proc member_hdc1: HDC, member_hdc2:HDC
	assume edi:ptr ball
	mov edi, offset myball
	.IF game_status == 1
		mov ecx, ball_num
		L1:
			pushad
			invoke SelectObject, member_hdc2, ball_bitmap
			invoke TransparentBlt, member_hdc1, [edi].pos.left, [edi].pos.top,\
				ball_size, ball_size, member_hdc2, 0, 0, ball_size, ball_size, 16777215
			popad
			add edi, type ball
			loop L1
	.ENDIF

	ret
paintBall endp


;������ƺ���
paintPad proc member_hdc1: HDC, member_hdc2:HDC

	.IF game_status == 1
		.if longpad
			invoke SelectObject, member_hdc2, longpad_bitmap
			invoke TransparentBlt, member_hdc1, mypad.pos.left, mypad.pos.top,\
				pad_width, pad_height, member_hdc2, 0, 0, pad_width, pad_height, 16777215
		.else
			invoke SelectObject, member_hdc2, pad_bitmap
			invoke TransparentBlt, member_hdc1, mypad.pos.left, mypad.pos.top,\
				pad_width, pad_height, member_hdc2, 0, 0, pad_width, pad_height, 16777215
		.endif

	.ENDIF

	ret
paintPad endp


; ש����ƺ���
paintBlocks proc uses edi ecx, member_hdc1:HDC, member_hdc2:HDC
	assume edi:ptr block
	.IF game_status == 1
    	mov    edi, offset  blocks
		mov	   ecx, lengthof blocks
		L2:
	        push   ecx
			push	edi
			.IF [edi].exist == 1
				.IF [edi].block_type == 1
					invoke	SelectObject, member_hdc2, block1_bitmap
				.ELSEIF [edi].block_type == 2
					invoke	SelectObject, member_hdc2, block2_bitmap
				.ELSEIF [edi].block_type == 3
					invoke	SelectObject, member_hdc2, block3_bitmap
				.ELSEIF [edi].block_type == 4
					invoke	SelectObject, member_hdc2, block4_bitmap
				.ENDIF
				invoke	TransparentBlt, member_hdc1, [edi].pos.left, [edi].pos.top,\
					block_width, block_height, member_hdc2, 0, 0, block_width, block_height, 16777215
			.ENDIF
			pop		edi
            add		edi, type blocks
			pop		ecx
			dec		ecx
			cmp		ecx, 0
			jne L2
	.ENDIF
	ret
paintBlocks endp

;��һ��ƺ���
paintCoins proc uses edi ecx, member_hdc1:HDC, member_hdc2:HDC
	assume edi:ptr coin
	.IF game_status == 1
    	mov    edi, offset  coins
		mov	   ecx, lengthof coins

		L2:
	        push   ecx
			push	edi
			.IF [edi].exist == 1
				invoke	SelectObject, member_hdc2, coin_bitmap
				invoke	TransparentBlt, member_hdc1, [edi].pos.left, [edi].pos.top,\
					coin_size, coin_size, member_hdc2, 0, 0, coin_size, coin_size, 16777215
			.ENDIF
			pop		edi
            add		edi, type coin
			pop		ecx
			dec		ecx
			cmp		ecx, 0
			jne L2
	.ENDIF
	ret
paintCoins endp



paintBackground proc  member_hdc1:HDC, member_hdc2:HDC
	.IF game_status == 0
		invoke SelectObject, member_hdc2,  menubg ;�ѿ�ʼҳ���λͼ�ŵ�hdc2��
		invoke BitBlt, member_hdc1, 0, 0, my_window_width, my_window_height, member_hdc2, 0, 0, SRCCOPY
	.ELSEIF game_status == 1
		invoke SelectObject, member_hdc2,  gamebg
		invoke BitBlt, member_hdc1, 0, 0, my_window_width, my_window_height, member_hdc2, 0, 0, SRCCOPY
	.ELSEIF game_status == 2
		invoke SelectObject, member_hdc2,  endbg
		invoke BitBlt, member_hdc1, 0, 0, my_window_width, my_window_height, member_hdc2, 0, 0, SRCCOPY	
	.ENDIF
	ret
paintBackground endp

;-----------------------------------------------------------------
;����ש��
initBlock proc uses eax edx ecx esi edi ebx, 
;-----------------------------------------------------------------
	LOCAL tempBlock:block, randResult:DWORD
	
	;����������
	mov eax,block_height
	mul row
	add eax, 70
	mov tempBlock.pos.bottom, eax
	mov tempBlock.pos.top, eax
	sub tempBlock.pos.top, block_height

	;������
	mov eax, block_width
	mul number
	mov edx,eax
	add edx, 80
	mov tempBlock.pos.left, edx
	add edx, block_width
	mov tempBlock.pos.right, edx
	
	mov eax, game_counter
	
	invoke getRandInEdx, 100
	mov randResult, edx
	.IF randResult < 25								
		mov tempBlock.block_type, 1					
	.ELSEIF randResult < 50							
		mov tempBlock.block_type, 2
	.ELSEIF randResult < 75						
		mov tempBlock.block_type, 3
	.ELSE
		mov tempBlock.block_type, 4

	.ENDIF
	mov tempBlock.exist, 1								
	mov eax, game_counter								

	lea esi, tempBlock
	mov edi, offset blocks
	mov ecx, lengthof blocks

L1:
	mov eax, (block ptr [edi]).exist
	.IF eax == 0
		jmp L2
	.ENDIF


	add edi, sizeof block
	loop L1

L2:	mov ecx, sizeof block

L3:
	mov al, byte ptr [esi]
	mov byte ptr [edi], al
	inc esi
	inc edi
	loop L3

L4:	
	ret
initBlock endp

getRandInEdx proc uses eax ebx,
	tempMod:DWORD
	;����ͬ�෨: a[n+1] = (a[n] * b + c) % p
	mov eax, randint
	mul rand_b
	add eax, rand_c
	mov edx, 0
	div rand_p
	mov randint, edx
	mov eax, randint
	mov edx, 0
	div tempMod

	ret
getRandInEdx endp

paintScore proc member_hdc:HDC
    LOCAL rect : RECT
	LOCAL hfont:HFONT

	.IF game_status == 1 
	mov rect.left, 20
	mov rect.right, 100
	mov rect.top, 45
	mov rect.bottom, 95
	; mov    eax, offset text
	; invoke wsprintf,offset buf,offset text, score
	invoke CreateFont,40,0,0,0,FW_HEAVY,0,0,0,ANSI_CHARSET,\
                                       OUT_DEFAULT_PRECIS,CLIP_DEFAULT_PRECIS,\
                                       DEFAULT_QUALITY,DEFAULT_PITCH or FF_SCRIPT or FF_SWISS,\
                                       ADDR FontName
    invoke SelectObject, member_hdc, eax
    mov    hfont,eax
	; ����������ɫ
    RGB    0,0,0
    invoke SetTextColor,member_hdc,eax
	 ;���ñ�����ɫ
    RGB    234,222,140
    invoke SetBkColor,member_hdc,eax
	mov    eax, offset text
	invoke wsprintf,offset buf,offset text, score

	invoke getStringLength, offset buf
	invoke DrawText, member_hdc, addr buf, -1,  addr rect,  DT_SINGLELINE or DT_CENTER or DT_VCENTER

	.ELSEIF game_status == 2  ; end

	mov rect.left, 390
	mov rect.right, 490
	mov rect.top,610
	mov rect.bottom, 670
	invoke CreateFont,40,0,0,0,FW_HEAVY,0,0,0,ANSI_CHARSET,\
                                       OUT_DEFAULT_PRECIS,CLIP_DEFAULT_PRECIS,\
                                       DEFAULT_QUALITY,DEFAULT_PITCH or FF_SCRIPT or FF_SWISS,\
                                       ADDR FontName
    invoke SelectObject, member_hdc, eax
    mov    hfont,eax
	; ����������ɫ
    RGB    0,0,0
    invoke SetTextColor,member_hdc,eax
	 ;���ñ�����ɫ
    RGB    142,205,214
    invoke SetBkColor,member_hdc,eax
	mov    eax, offset text

	
	; mov    ebx, [esi];////////////
	invoke wsprintf,offset buf,offset text, data1;//////////

	invoke getStringLength, offset buf
	invoke DrawText, member_hdc, addr buf, -1,  addr rect,  DT_SINGLELINE or DT_CENTER or DT_VCENTER	

	;print this round score
	mov rect.left, 400
	mov rect.right, 600
	mov rect.top,260
	mov rect.bottom, 400
	invoke CreateFont,150,0,0,0,FW_HEAVY,0,0,0,ANSI_CHARSET,\
                                       OUT_DEFAULT_PRECIS,CLIP_DEFAULT_PRECIS,\
                                       DEFAULT_QUALITY,DEFAULT_PITCH or FF_SCRIPT or FF_SWISS,\
                                       ADDR FontName
    invoke SelectObject, member_hdc, eax
    mov    hfont,eax
	; ����������ɫ
    RGB    0,0,0
    invoke SetTextColor,member_hdc,eax
	 ;���ñ�����ɫ
    RGB    253,199,109
    invoke SetBkColor,member_hdc,eax
	mov    eax, offset text

    invoke wsprintf,offset buf,offset text, score; ////////
	invoke getStringLength,offset buf
	invoke DrawText, member_hdc, addr buf, -1,  addr rect,  DT_SINGLELINE or DT_CENTER or DT_VCENTER
	.ENDIF

	ret
paintScore endp

getStringLength proc uses edi ecx eax, string:PTR BYTE
	assume edi: PTR BYTE
	mov edi,string
	mov ecx,0
length_L1:
	mov al,[edi]
	inc ecx
	inc edi
	cmp al,0
	jne length_L1
length_L2:
	dec ecx
	mov strlen,ecx
	ret
getStringLength endp

end start