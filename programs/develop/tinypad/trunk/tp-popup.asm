;POP_WIDTH   = (popup_text.max_title+popup_text.max_accel+6)*6
POP_IHEIGHT = 16
;POP_HEIGHT  = popup_text.cnt_item*POP_IHEIGHT+popup_text.cnt_sep*4+4

func calc_middle
	shr	eax,1
	shr	ebx,1
	and	eax,0x007F7F7F
	and	ebx,0x007F7F7F
	add	eax,ebx
	ret
endf

func calc_3d_colors
	pushad
	m2m	[cl_3d_normal],[sc.work]
	m2m	[cl_3d_inset],[sc.work_graph]
	push	[cl_3d_normal]
	add	byte[esp],48
	jnc	@f
	mov	byte[esp],255
    @@: add	byte[esp+1],48
	jnc	@f
	mov	byte[esp+1],255
    @@: add	byte[esp+2],48
	jnc	@f
	mov	byte[esp+2],255
    @@: pop	[cl_3d_outset]
	mov	eax,[cl_3d_inset]
	mov	ebx,[cl_3d_outset]
	call	calc_middle
	mov	[cl_3d_pushed],eax
	mov	eax,[cl_3d_normal]
	mov	ebx,[sc.work_text]
	call	calc_middle
	mov	[cl_3d_grayed],eax
	popad
	ret
endf

func draw_3d_panel ; x,y,w,h
	cmp	dword[esp+8],4
	jl	.exit
	cmp	dword[esp+4],4
	jl	.exit
	mov	ebx,[esp+16-2]
	mov	bx,[esp+8]
	inc	ebx
	mov	ecx,[esp+12-2]
	mov	cx,[esp+4]
	inc	ecx
	mcall	13,,,[cl_3d_normal];0x00EEEEEE;[sc.work]
	dec	ebx
	add	bx,[esp+16]
	mov	cx,[esp+12]
	mcall	38,,,[cl_3d_inset];0x006382BF;[sc.work_text]
	add	ecx,[esp+4-2]
	add	cx,[esp+4]
	mcall
	mov	bx,[esp+16]
	mov	ecx,[esp+12-2]
	mov	cx,[esp+4]
	add	cx,[esp+12]
	mcall
	add	ebx,[esp+8-2]
	add	bx,[esp+8]
	mcall
	mov	ebx,[esp+16-2]
	mov	bx,[esp+8]
	add	bx,[esp+16]
	add	ebx,1*65536-1
	mov	ecx,[esp+12-2]
	mov	cx,[esp+12]
	add	ecx,0x00010001
	mcall	,,,[cl_3d_outset]
	mov	bx,[esp+16]
	inc	ebx
	mov	ecx,[esp+12-2]
	mov	cx,[esp+4]
	add	cx,[esp+12]
	add	ecx,2*65536-1
	mcall
  .exit:
	ret	4*4
endf

popup_thread_start:
	mov	[popup_active],1
	mov	[pi_cur],0
	mov	ebp,[esp]
	mcall	14
	movzx	ebx,ax
	shr	eax,16
	movzx	ecx,[ebp+POPUP.x]
	add	cx,[ebp+POPUP.width]
	cmp	ecx,eax
	jle	@f
	mov	cx,[ebp+POPUP.width]
	sub	[ebp+POPUP.x],cx
    @@: movzx	ecx,[ebp+POPUP.y]
	add	cx,[ebp+POPUP.height]
	cmp	ecx,ebx
	jle	@f
	mov	cx,[ebp+POPUP.height]
	sub	[ebp+POPUP.y],cx
    @@: mcall	40,01100111b		; ipc mouse button key redraw
	cmp	[mi_cur],0
	jl	.2
	sub	esp,32-16
	push	0 0 8 0
	mcall	60,1,esp,32
  .2:	call	draw_popup_wnd

  still_popup:
	cmp	[main_closed],1
	je	close_popup
	mcall	10
	cmp	eax,1
	je	popup_thread_start.2
	cmp	eax,2
	je	key_popup
	cmp	eax,3
	je	button_popup
	cmp	eax,6
	je	mouse_popup
	cmp	eax,7
	jne	still_popup

	mov	ebp,[POPUP_STACK];-32+12+4]
	mov	dword[POPUP_STACK-32+4],8
	movzx	ebx,[ebp+POPUP.x]
	movzx	ecx,[ebp+POPUP.y]
	movzx	edx,[ebp+POPUP.width]
	movzx	esi,[ebp+POPUP.height]
	mcall	67
;       call    draw_popup_wnd
	jmp	still_popup

  mouse_popup:
	mov	ecx,mst2
	call	get_mouse_event
	cmp	al,MEV_LDOWN
	je	check_popup_click
	cmp	al,MEV_MOVE
	je	check_popup_move

	mcall	9,p_info2,-1
	cmp	ax,[p_info2.window_stack_position]
	jne	close_popup

	jmp	still_popup

  check_popup_click:
	mov	eax,[pi_cur]
	or	al,al
	js	close_popup
	jz	still_popup
	mov	ebx,[ebp+POPUP.actions]
	mov	[just_from_popup],1
	call	dword[ebx+eax*4-4];dword[popup_text.actions+eax*4-4]
	inc	[just_from_popup]
	jmp	close_popup

  check_popup_move:
	mov	eax,[pi_cur]
	call	get_active_popup_item
	cmp	eax,[pi_cur]
	je	still_popup
	call	draw_popup_wnd
	jmp	still_popup

  key_popup:
	mcall	;2
	cmp	ah,27
	jne	still_popup

  button_popup:
	mcall	17

  close_popup:
	mcall	18,3,[p_info.PID]
	mov	[popup_active],0
	mcall	-1

func draw_popup_wnd
	mcall	12,1

;       mcall   48,3,sc,sizeof.system_colors
;       call    calc_3d_colors

;        mov     ebx,[p_pos]
;        mov     ecx,[p_pos-2]
;        mov     bx,POP_WIDTH
;        mov     cx,POP_HEIGHT
	mov	ebx,dword[ebp+POPUP.x-2]
	mov	bx,[ebp+POPUP.width]
	mov	ecx,dword[ebp+POPUP.y-2]
	mov	cx,[ebp+POPUP.height]
	mcall	0,,,0x01000000,0x01000000

	movzx	ebx,bx
	movzx	ecx,cx
	pushd	0 0 ebx ecx ;POP_WIDTH POP_HEIGHT
	call	draw_3d_panel

	mov	[pi_sel],0
;        mcall   37,1
;        movsx   ebx,ax
;        sar     eax,16
;        mov     [c_pos.x],eax
;        mov     [c_pos.y],ebx

	mov	eax,4
	mpack	ebx,3*6,3
	mov	ecx,[sc.work_text]
	mov	edx,[ebp+POPUP.data];popup_text.data
    @@: inc	[pi_sel]
	inc	edx
	movzx	esi,byte[edx-1]
	cmp	byte[edx],'-'
	jne	.lp1
	pushad
	mov	ecx,ebx
	shl	ecx,16
	mov	cx,bx
	movzx	ebx,[ebp+POPUP.width]
	add	ebx,0x00010000-1
;       mpack   ebx,1,POP_WIDTH-1
	add	ecx,0x00010001
	mcall	38,,,[cl_3d_inset];0x006382BF;[sc.work_text]
	add	ecx,0x00010001
	mcall	,,,[cl_3d_outset];0x00FFFFFF
	popad
	add	ebx,4
	jmp	.lp2
  .lp1: mov	edi,[pi_sel]
	cmp	edi,[pi_cur]
	jne	.lp3
	test	byte[ebp+edi-1],0x01 ; byte[popup_text+edi-1],0x01
	jz	.lp3
	pushad
	movzx	ecx,bx
	shl	ecx,16
	mov	cl,POP_IHEIGHT-1
	movzx	ebx,[ebp+POPUP.width]
	add	ebx,0x00010000-1
;       mpack   ebx,1,POP_WIDTH-1
	mcall	13,,,[cl_3d_pushed];0x00A3B8CC
	rol	ecx,16
	mov	ax,cx
	rol	ecx,16
	mov	cx,ax
	mcall	38,,,[cl_3d_inset];0x006382BF
	add	ecx,(POP_IHEIGHT-1)*65536+POP_IHEIGHT-1
	mcall	,,,[cl_3d_outset];0x00FFFFFF
	popad
  .lp3: add	ebx,(POP_IHEIGHT-7)/2

	pushad
	test	byte[ebp+edi-1],0x02
	jz	.lp8
	movzx	ecx,bx
	shl	ecx,16
	mov	cx,bx
	shr	ebx,16
	push	bx
	shl	ebx,16
	pop	bx
	add	ecx,0x00040003
	sub	ebx,0x000A000B
	mcall	38,,,[sc.work_text]
	add	ecx,0x00010001
	mcall
	add	ebx,4
	sub	ecx,2
	mcall
	sub	ecx,0x00010001
	mcall
  .lp8: popad

	mov	ecx,[sc.work_text];0x00000000
	test	byte[ebp+edi-1],0x01 ; byte[popup_text+edi-1],0x01
	jnz	.lp5
	add	ebx,0x00010001
	mov	ecx,[cl_3d_outset]
	mcall
	sub	ebx,0x00010001
	mov	ecx,[cl_3d_inset]
	;mov     ecx,[sc.grab_text];0x007F7F7F
  .lp5: mcall
	push	ebx
	add	edx,esi
	inc	edx
	movzx	esi,byte[edx-1]
	add	ebx,[ebp+POPUP.acc_ofs] ; ((popup_text.max_title+2)*6-1)*65536
	cmp	edi,[pi_cur]
	je	.lp4
	mov	ecx,[cl_3d_inset];0x006382BF
  .lp4: test	byte[ebp+edi-1],0x01 ; byte[popup_text+edi-1],0x01
	jnz	.lp6
	add	ebx,0x00010001
	mov	ecx,[cl_3d_outset]
	mcall
	sub	ebx,0x00010001
	mov	ecx,[cl_3d_inset]
	;mov     ecx,[sc.grab_text];0x007F7F7F
  .lp6: mcall
	pop	ebx
	add	ebx,POP_IHEIGHT-(POP_IHEIGHT-7)/2
  .lp2: add	edx,esi
	cmp	byte[edx],0
	jne	@b
  .exit:
	mcall	12,2
	ret
endf

pi_sel	 dd ?
pi_cur	 dd ?
p_pos	 dd ?
popup_active db 0