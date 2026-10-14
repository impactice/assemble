hello.asm
```
.model small
.stack 100h
.data
    msg db 'Hello, Interrupt!$'
.code
main proc
    mov ax, @data
    mov ds, ax

    mov ah, 09h
    mov dx, offset msg
    int 21h

    mov ah, 4Ch
    int 21h
main endp
end main
```

myint.asm
```
.model small
.stack 100h
.data
    msg db 'My ISR called!$'
.code
my_isr proc far
    push ax
    push dx
    mov ah, 09h
    mov dx, offset msg
    int 21h
    pop dx
    pop ax
    iret
my_isr endp

main proc
    mov ax, @data
    mov ds, ax

    push ds
    mov ax, seg my_isr
    mov ds, ax
    mov dx, offset my_isr
    mov ax, 2560h
    int 21h
    pop ds

    int 60h

    mov ah, 4Ch
    int 21h
main endp
end main
```
