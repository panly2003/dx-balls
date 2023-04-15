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
start:  ;程序入口点
    ; 获得模块句柄
	invoke GetModuleHandle, NULL;返回主调进程的可执行文件的基地址
	mov hInstance, eax ;hinstanse是通常用作应用程序实例句柄，可以包含多个窗口实例

	; 可能不需要命令行参数
	; invoke GetCommandLine
	; mov  CommandLine, eax
	; ; 得到图标和光标
    ; mov hIcon,       rv(LoadIcon,hInstance,103)
    ; mov hCursor,     rv(LoadCursor,NULL,IDC_ARROW)
	; 得到整个屏幕的尺寸
    mov sWid,        rv(GetSystemMetrics,SM_CXSCREEN)
    mov sHgt,        rv(GetSystemMetrics,SM_CYSCREEN)
	; 调用主函数
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

    STRING szClassName,   "GameClass" ;改
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
    m2m wc.hbrBackground,  NULL                 ;COLOR_BTNFACE+1 不需要background
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
    mov Wwd, my_window_width ;改
    mov Wht, my_window_height ;改

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

	; 消息循环
    call MsgLoop
    ret
Main endp

; 消息循环
MsgLoop proc
    LOCAL msg:MSG
    push ebx
    lea ebx, msg
    jmp getmsg
  msgloop:
    invoke TranslateMessage, ebx
    invoke DispatchMessage,  ebx
  getmsg:
    invoke GetMessage,ebx,0,0,0 ;该函数从调用线程的消息队列里取得一个消息并将其放于指定的结构。此函数可取得与指定窗口联系的消息
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

	; 处理窗口创建后的一些操作
	.IF uMsg == WM_CREATE
		invoke startGame

	.ELSEIF uMsg == WM_DESTROY
		; 退出线程
		invoke PostQuitMessage, NULL

	.ELSEIF uMsg == WM_PAINT
		; 调用更新场景函数，WM_PAINT由paintThread的InvalidateRect发出
		invoke updateScene

	.ELSEIF uMsg == WM_CHAR
		; 处理enter键按下事件
		.IF wParam == 13
			.IF game_status == 0
				pushad ;函数调用寄存器保护
				invoke PlaySound, 154, hInstance, SND_RESOURCE or SND_ASYNC or SND_LOOP
				popad
				invoke initGame
				mov game_status, 1
				mov game_counter, 0
			 .ELSEIF game_status == 2
			 	mov game_status, 0
			 	pushad
			 	invoke PlaySound, 150, hInstance, SND_RESOURCE or SND_ASYNC or SND_LOOP
				; 重置
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
	  ;处理键盘抬起事件

	.ELSEIF uMsg == WM_KEYDOWN
	  invoke processKeyDown, wParam
	  ;处理键盘按下事件

	.ELSE
		; 默认消息处理函数
		invoke DefWindowProc,hWin,uMsg,wParam,lParam
		ret
	.ENDIF
	xor eax, eax
	ret
WndProc endp

;按下按键
processKeyDown proc wParam:WPARAM;wParam键盘消息，可在wndProc里获得
	; .IF game_status == 1
	;按下 ←
	.IF wParam == VK_LEFT
	mov key_left, 1
	;按下 →
	.ELSEIF wParam == VK_RIGHT
	mov key_right, 1
	;按下 ↑
	.ELSEIF wParam == VK_UP
	mov key_up, 1
	;按下 ↓
	.ELSEIF wParam == VK_DOWN
	mov key_down, 1
	;按下 空格
	.ELSEIF wParam == 20h
	mov key_space, 1
	.ENDIF
	; .ENDIF
	ret
processKeyDown endp

;松开按键
processKeyUp proc wParam:WPARAM;wParam键盘消息，可在wndProc里获得
	; .IF game_status == 1
	;松开 ←
	.IF wParam == VK_LEFT
	mov key_left, 0
	;按下 →
	.ELSEIF wParam == VK_RIGHT
	mov key_right, 0
	;按下 ↑
	.ELSEIF wParam == VK_UP
	mov key_up, 0
	;按下 ↓
	.ELSEIF wParam == VK_DOWN
	mov key_down, 0
	;按下 空格
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
	;第一个小球
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


;生成金币
initCoin proc uses eax edx ecx esi edi ebx
;-----------------------------------------------------------------
	LOCAL tempCoin:coin, randResult:DWORD
	
	;设置纵坐标
	mov tempCoin.pos.bottom, 0
	mov tempCoin.pos.top, 0
	sub tempCoin.pos.top, coin_size

	;生成随机的横坐标
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

	mov tempCoin.exist, 1								;金币状态：存在
	mov eax, game_counter								
	mov last_coin, eax									;最后一次金币生成时间：现在

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
		; 加载图片
		invoke loadGameImages
		; 创造逻辑线程
		mov eax, OFFSET logicThread
		invoke CreateThread, NULL, NULL, eax, 0, 0, addr thread1
		invoke CloseHandle, eax
		; 创造绘制线程
		mov eax, OFFSET paintThread
		invoke CreateThread, NULL, NULL, eax, 0, 0, addr thread2 ;创建建ID为thread2的线程
		invoke CloseHandle, eax
		;播放背景音乐
		pushad
		invoke PlaySound, 150, hInstance, SND_RESOURCE or SND_ASYNC or SND_LOOP
		popad

		ret
startGame endp

; 一个线程函数，根据场景的状态不断循环，游戏状态时候，不断进行碰撞判断等等
logicThread proc uses eax ecx,
	p:DWORD, 
	;LOCAL area:RECT
	game:
	; 开始界面，需要通过enter进入
	.WHILE game_status == 0
		invoke Sleep, 1000
	.ENDW

	; 游戏界面
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
		; 生成砖块
		invoke initBlock
		loop L1
		pop ecx
		loop L0

		pop ecx

		.WHILE game_status == 1
			invoke Sleep,sleep_time

			; 小球位置更新
			invoke updateBallPosition

			; 挡板速度更新
			invoke updatePadSpeed

			; 挡板位置更新
			invoke updatePadPosition

			;生成金币
			invoke initCoin

			;金币位置更新
			invoke updateCoinPos

			;判断是否全都打光
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

; 触发技能
startUpSkills proc
	LOCAL randResult:DWORD
	assume edi:ptr ball

	invoke getRandInEdx, 100
	mov randResult, edx
	.IF randResult < 25
		;触发挡板变长技能
		.if !longpad
			mov longpad, 1
			add mypad.pos.right, 100
			add pad_width, 100
			mov eax, game_counter
			mov skill_timer, eax
		.endif
		ret									
	.ELSEIF randResult < 40							
		;触发小球速度变快技能
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
		;触发挡板速度变快技能
		add pad_speed, 1
		ret	
	.ELSEIF randResult < 65
		;触发小球个数+1 技能
		.IF ball_num != 8
			; 将新增第一个小球的位置挪入edi
			mov edi, offset myball
			mov ecx, ball_num
			.WHILE ecx != 0
				add edi, type ball
				dec ecx
			.ENDW

			; 小球数量+1
			add ball_num, 1

			; 给新增的小球赋初始属性
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
		
	
			; 和窗口碰撞
			; 和窗口右侧碰撞
			.IF myball_next.pos.right > my_window_width  
				neg [edi].speed.x
			.ENDIF
			; 和窗口上侧碰撞
			.IF myball_next.pos.top < 0  
				neg [edi].speed.y
			.ENDIF
			; 和窗口左侧碰撞
			.IF myball_next.pos.left < 0  
				neg [edi].speed.x
			.ENDIF

			;和挡板碰撞 
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

			;和砖块碰撞
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

				; 1 球向右斜上飞
				.IF [edi].speed.x>0 && [edi].speed.y<0
					mov eax, [esi].pos.top
					mov edx, [esi].pos.left

					; 1.1 检测球右上角撞砖块
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
							; 砖块消失
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
			

					; 1.2 检测球左上角撞砖块
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
								; 砖块消失
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

					; 1.3 检测球右下角撞砖块
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
								; 砖块消失
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

				; 2 球向左斜上飞
				.IF [edi].speed.x<0 && [edi].speed.y<0
					; 2.1检测球左上角撞砖块
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
							; 砖块消失
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

					;2.2 检测右上角撞砖块
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
							; 砖块消失
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

					;2.3 检测左下角撞砖块
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
							; 砖块消失
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

				; 3 球向左斜下飞
				.IF [edi].speed.x<0 && [edi].speed.y>0
					; 3.1 检测左下角撞砖块
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
							; 砖块消失
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

					; 3.2 检测左上角撞砖块
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
							; 砖块消失
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

					; 3.3 检测右下角撞砖块
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
							; 砖块消失
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

				; 4 球向右斜下飞
				.IF [edi].speed.x>0 && [edi].speed.y>0
					; 4.1 检测右下角撞砖块
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
							; 砖块消失
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

					; 4.2 检测左下角撞砖块
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
							; 砖块消失
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

					; 4.2 检测右上角撞砖块
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
							; 砖块消失
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
		
			; 修改位置
			L2:
			mov     eax, [edi].speed.x
			add		[edi].pos.left, eax
			add		[edi].pos.right, eax

			mov     eax, [edi].speed.y
			add		[edi].pos.top, eax
			add		[edi].pos.bottom, eax

			.IF [edi].pos.top > my_window_height   ;球跃出下边界后设置成不存在
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
		.IF key_right == 1;→
			mov mypad.speed.x, eax
		.ELSE;无
			mov mypad.speed.x, 0
		.ENDIF
	.ENDIF
	ret
updatePadSpeed endp 

updatePadPosition proc uses eax ebx ecx edx
	mov eax, mypad.speed.x
	mov ebx, mypad.speed.y
	;移动
	add mypad.pos.top, ebx
	add mypad.pos.bottom, ebx
	add mypad.pos.left, eax
	add mypad.pos.right, eax
	;检测上下是否超出边框
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
	;检测左右是否超出边框
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

;判断是否全打光
isOver proc
	assume edi:ptr block
	LOCAL flag_:DWORD
	mov flag_, 0 ;游戏结束
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

;加载位图
loadGameImages proc
	; 加载开始界面的位图
	invoke LoadBitmap, hInstance, 500
	mov menubg, eax
	
    ; 加载游戏界面的位图
	invoke LoadBitmap, hInstance, 501
	mov gamebg, eax
    
	; 加载小球位图
	invoke LoadBitmap, hInstance, 517
	mov ball_bitmap, eax

	; 加载挡板的位图
	invoke LoadBitmap, hInstance, 518
	mov pad_bitmap, eax  


	; 加载长挡板的位图
	invoke LoadBitmap, hInstance, 520
	mov longpad_bitmap, eax  
    
    ; 加载砖块1的位图
    invoke LoadBitmap, hInstance, 511
	mov block1_bitmap, eax
    
    ; 加载砖块2的位图
    invoke LoadBitmap, hInstance, 512
	mov block2_bitmap, eax
    
    ; 加载砖块3的位图
    invoke LoadBitmap, hInstance, 513
	mov block3_bitmap, eax

	; 加载砖块4的位图
    invoke LoadBitmap, hInstance, 514
	mov block4_bitmap, eax

	;加载金币位图
	invoke LoadBitmap, hInstance, 519
	mov coin_bitmap, eax

	; 加载得分页面的位图
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

; 场景更新函数
updateScene proc uses eax
	LOCAL member_hdc:HDC
	LOCAL member_hdc2:HDC
	LOCAL h_bitmap:HDC
	LOCAL hdc: HDC

	invoke BeginPaint, hWnd, ADDR paintstruct
	mov hdc, eax     ;加载hwnd的

	invoke CreateCompatibleDC, hdc  ;该函数创建一个与指定设备兼容的**内存设备**上下文环境（DC）
	mov member_hdc, eax
	invoke CreateCompatibleDC, hdc
	mov member_hdc2, eax
	invoke CreateCompatibleBitmap, hdc, my_window_width, my_window_height
	mov h_bitmap, eax

	;将位图选择到兼容DC中
	invoke SelectObject, member_hdc, h_bitmap

	;绘制背景
	invoke paintBackground, member_hdc, member_hdc2

	;绘制球
	invoke paintBall, member_hdc, member_hdc2

	;绘制挡板
	invoke paintPad, member_hdc, member_hdc2

	;绘制砖块
	invoke paintBlocks, member_hdc, member_hdc2

	;绘制金币
	invoke paintCoins, member_hdc, member_hdc2

	invoke Sort_RankingList


	;绘制分数
	invoke paintScore, member_hdc

	; BitBlt（hDestDC, x, y, nWidth, nheight, hSrcDC, xSrc, ySrc, dwRop）
	; 将源矩形区域直接拷贝到目标区域：SRCCOPY
	invoke BitBlt, hdc, 0, 0, my_window_width, my_window_height, member_hdc, 0, 0, SRCCOPY


	invoke DeleteDC, member_hdc
	invoke DeleteDC, member_hdc2
	invoke DeleteObject, h_bitmap
	invoke EndPaint, hWnd, ADDR paintstruct
	ret
updateScene endp


; 球绘制函数
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


;挡板绘制函数
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


; 砖块绘制函数
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

;金币绘制函数
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
		invoke SelectObject, member_hdc2,  menubg ;把开始页面的位图放到hdc2中
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
;生成砖块
initBlock proc uses eax edx ecx esi edi ebx, 
;-----------------------------------------------------------------
	LOCAL tempBlock:block, randResult:DWORD
	
	;设置纵坐标
	mov eax,block_height
	mul row
	add eax, 70
	mov tempBlock.pos.bottom, eax
	mov tempBlock.pos.top, eax
	sub tempBlock.pos.top, block_height

	;横坐标
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
	;线性同余法: a[n+1] = (a[n] * b + c) % p
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
	; 设置文字颜色
    RGB    0,0,0
    invoke SetTextColor,member_hdc,eax
	 ;设置背景颜色
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
	; 设置文字颜色
    RGB    0,0,0
    invoke SetTextColor,member_hdc,eax
	 ;设置背景颜色
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
	; 设置文字颜色
    RGB    0,0,0
    invoke SetTextColor,member_hdc,eax
	 ;设置背景颜色
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