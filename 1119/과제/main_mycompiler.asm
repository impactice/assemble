bits 64
default rel

global _start

; Snapshot registers immediately after each arithmetic operation.
%macro SAVE_REGS 0
    mov [saved_ax], ax
    mov [saved_bx], bx
    mov [saved_cx], cx
    mov [saved_dx], dx
%endmacro

%macro PRINT_REG 2
    lea rsi, [%1]
    call print_string
    movzx eax, word [%2]
    call print_hex16
%endmacro

section .data
    intro       db "Enter two integers (0..65535).", 10, 0
    msg_add     db 10, "[ADD] Result = ", 0
    msg_sub     db 10, "[SUB] Result = ", 0
    msg_mul     db 10, "[MUL] Result = ", 0
    msg_div     db 10, "[DIV] Quotient = ", 0
    msg_rem     db "  Remainder = ", 0
    msg_zero    db 10, "[DIV] Cannot divide by zero.", 10, 0
    msg_invalid db "Invalid input. Enter two integers from 0 to 65535.", 10, 0
    msg_ax      db "  AX = ", 0
    msg_bx      db "  BX = ", 0
    msg_cx      db "  CX = ", 0
    msg_dx      db "  DX = ", 0
    newline     db 10, 0
    hex_digits  db "0123456789ABCDEF"

section .bss
    number_a    resw 1
    number_b    resw 1
    saved_ax    resw 1
    saved_bx    resw 1
    saved_cx    resw 1
    saved_dx    resw 1
    input_char  resb 1
    number_buf  resb 32
    hex_buf     resb 4

section .text
_start:
    lea rsi, [intro]
    call print_string
    call read_uint16
    mov [number_a], ax
    call read_uint16
    mov [number_b], ax

    ; ADD: unsigned DX:AX = A + B.
    mov ax, [number_a]
    mov bx, [number_b]
    xor cx, cx
    xor dx, dx
    add ax, bx
    adc dx, 0
    SAVE_REGS

    movzx eax, word [saved_dx]
    shl eax, 16
    mov ax, [saved_ax]
    lea rsi, [msg_add]
    call print_result

    ; SUB: signed DX:AX = A - B.
    mov ax, [number_a]
    mov bx, [number_b]
    xor cx, cx
    xor dx, dx
    sub ax, bx
    sbb dx, 0
    SAVE_REGS

    movzx eax, word [saved_dx]
    shl eax, 16
    mov ax, [saved_ax]
    movsxd rax, eax
    lea rsi, [msg_sub]
    call print_result

    ; MUL: unsigned DX:AX = A * B.
    mov ax, [number_a]
    mov bx, [number_b]
    xor cx, cx
    xor dx, dx
    mul bx
    SAVE_REGS

    movzx eax, word [saved_dx]
    shl eax, 16
    mov ax, [saved_ax]
    lea rsi, [msg_mul]
    call print_result

    ; DIV: AX = quotient, DX = remainder.
    cmp word [number_b], 0
    je division_by_zero

    mov ax, [number_a]
    mov bx, [number_b]
    xor cx, cx
    xor dx, dx
    div bx
    SAVE_REGS

    movzx eax, word [saved_ax]
    lea rsi, [msg_div]
    call print_result

    lea rsi, [msg_rem]
    call print_string
    movzx eax, word [saved_dx]
    call print_integer
    lea rsi, [newline]
    call print_string
    jmp exit_success

division_by_zero:
    lea rsi, [msg_zero]
    call print_string

exit_success:
    mov eax, 60
    xor edi, edi
    syscall

; Read a decimal token from stdin. Return AX = 0..65535.
; Whitespace separates tokens. Invalid/missing input exits with code 1.
read_uint16:
    xor r8d, r8d
    xor r9d, r9d
.read_next:
    xor eax, eax
    xor edi, edi
    lea rsi, [input_char]
    mov edx, 1
    syscall
    test rax, rax
    js input_error
    jz .end_of_input

    movzx eax, byte [input_char]
    cmp al, 32
    jbe .separator
    cmp al, '0'
    jb input_error
    cmp al, '9'
    ja input_error
    sub eax, '0'

    imul r8, r8, 10
    add r8, rax
    cmp r8, 65535
    ja input_error
    mov r9d, 1
    jmp .read_next

.separator:
    test r9d, r9d
    jz .read_next
    jmp .done

.end_of_input:
    test r9d, r9d
    jz input_error
.done:
    mov eax, r8d
    ret

input_error:
    lea rsi, [msg_invalid]
    call print_string
    mov eax, 60
    mov edi, 1
    syscall

; RSI = zero-terminated string. Clobbers syscall registers.
print_string:
    xor edx, edx
.count:
    cmp byte [rsi + rdx], 0
    je .write
    inc rdx
    jmp .count
.write:
    mov eax, 1
    mov edi, 1
    syscall
    ret

; RAX = signed decimal value (only calculator result range is needed).
print_integer:
    lea rsi, [number_buf + 32]
    xor r8d, r8d
    mov r9d, 10
    test rax, rax
    jns .convert
    mov r8d, 1
    neg rax
.convert:
    xor edx, edx
    div r9
    add dl, '0'
    dec rsi
    mov [rsi], dl
    test rax, rax
    jnz .convert
    test r8d, r8d
    jz .write
    dec rsi
    mov byte [rsi], '-'
.write:
    lea rdx, [number_buf + 32]
    sub rdx, rsi
    mov eax, 1
    mov edi, 1
    syscall
    ret

; AX = value to print as four uppercase hexadecimal digits.
print_hex16:
    lea r8, [hex_buf + 4]
    lea r10, [hex_digits]
    mov r9d, 4
.convert:
    mov edx, eax
    and edx, 15
    mov dl, [r10 + rdx]
    dec r8
    mov [r8], dl
    shr eax, 4
    dec r9d
    jnz .convert

    mov eax, 1
    mov edi, 1
    lea rsi, [hex_buf]
    mov edx, 4
    syscall
    ret

; RSI = title, RAX = decimal result.
print_result:
    push rax
    call print_string
    pop rax
    call print_integer
    lea rsi, [newline]
    call print_string

    PRINT_REG msg_ax, saved_ax
    PRINT_REG msg_bx, saved_bx
    PRINT_REG msg_cx, saved_cx
    PRINT_REG msg_dx, saved_dx

    lea rsi, [newline]
    call print_string
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
