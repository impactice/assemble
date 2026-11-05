
.386
.model flat, stdcall
option casemap:none

includelib kernel32.lib

ExitProcess PROTO, dwExitCode:DWORD
GetStdHandle PROTO, nStdHandle:DWORD

WriteConsoleW PROTO, hConsoleOutput:DWORD, lpBuffer:DWORD, nNumberOfCharsToWrite:DWORD, lpNumberOfCharsWritten:DWORD, lpReserved:DWORD

.data
    ; 학번 
    studentID WORD 0032h, 0030h, 0032h, 0031h, 0039h
                  WORD  0036h, 0033h, 0030h, 0036h, 0036h
                  WORD 000Dh, 000Ah

    ; 이름 
    studentName WORD 0C815h, 0C6D0h, 0D76Ch
                     WORD 000Dh, 000Ah

    written DWORD ?

.code
main PROC

    INVOKE GetStdHandle, -11
    mov ebx, eax

    ; 학번 출력
    INVOKE WriteConsoleW, ebx, ADDR studentID, 12, ADDR written, 0

    ; 이름 출력
    INVOKE WriteConsoleW, ebx, ADDR studentName, 5, ADDR written, 0

    INVOKE ExitProcess, 0

main ENDP
END main
