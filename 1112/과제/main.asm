
.386
.model flat, stdcall
option casemap:none

includelib kernel32.lib

ExitProcess PROTO, dwExitCode:DWORD
GetStdHandle PROTO, nStdHandle:DWORD

ReadConsoleW PROTO, hConsoleInput:DWORD, lpBuffer:DWORD, nNumberOfCharsToRead:DWORD, lpNumberOfCharsRead:DWORD, lpReserved:DWORD

WriteConsoleW PROTO, hConsoleOutput:DWORD, lpBuffer:DWORD, nNumberOfCharsToWrite:DWORD, lpNumberOfCharsWritten:DWORD, lpReserved:DWORD

.data
    ; 출력 메시지
    msg1 WORD 'E','n','t','e','r',' ','5',' ','n','u','m','b','e','r','s',':',13,10
    msg2 WORD 'A','v','e','r','a','g','e',':',' '

    ; 입출력 버퍼
    inputBuffer WORD 32 DUP(0)
    outputBuffer WORD 32 DUP(0)

    charsRead DWORD ?
    written DWORD ?

    ; 입력 숫자 및 계산 변수
    numbers SDWORD 5 DUP(0)
    sum SDWORD 0
    avg SDWORD 0

    count DWORD 0
    isNegative DWORD 0

    ; 콘솔 핸들
    hOutput DWORD ?
    hInput DWORD ?

.code
main PROC

    ; 콘솔 핸들 가져오기
    INVOKE GetStdHandle, -11
    mov hOutput, eax

    INVOKE GetStdHandle, -10
    mov hInput, eax

    ; 입력 안내 메시지 출력
    INVOKE WriteConsoleW, hOutput, ADDR msg1, 18, ADDR written, 0

    ; 초기화
    mov count, 0
    mov sum, 0
    mov esi, OFFSET numbers

INPUT_LOOP:

    ; 사용자 입력
    INVOKE ReadConsoleW, hInput, ADDR inputBuffer, 32, ADDR charsRead, 0

    ; 숫자 변환 초기화
    xor edi, edi
    xor ecx, ecx
    mov isNegative, 0

    ; 음수 확인
    cmp WORD PTR inputBuffer[ecx*2], '-'
    jne PARSE_LOOP

    mov isNegative, 1
    inc ecx

PARSE_LOOP:

    movzx eax, WORD PTR inputBuffer[ecx*2]

    ; Enter 입력 확인
    cmp eax, 13
    je PARSE_DONE

    cmp eax, 10
    je PARSE_DONE

    ; 숫자 범위 확인
    cmp eax, '0'
    jb PARSE_DONE

    cmp eax, '9'
    ja PARSE_DONE

    ; 문자열을 정수로 변환
    sub eax, '0'

    imul edi, 10
    add edi, eax

    inc ecx
    jmp PARSE_LOOP

PARSE_DONE:

    ; 음수 처리
    cmp isNegative, 1
    jne SAVE_NUMBER

    neg edi

SAVE_NUMBER:

    ; 배열에 숫자 저장
    mov DWORD PTR [esi], edi
    add esi, 4

    ; 합계 계산
    add sum, edi

    inc count

    ; 5개 입력 확인
    cmp count, 5
    jl INPUT_LOOP

    ; 평균 계산
    mov eax, sum
    cdq
    mov ecx, 5
    idiv ecx

    mov avg, eax

    ; 평균 출력 안내
    INVOKE WriteConsoleW, hOutput, ADDR msg2, 9, ADDR written, 0

    ; 평균값을 문자열로 변환
    mov eax, avg
    xor edi, edi

    ; 음수 확인
    test eax, eax
    jns CONVERT_NUMBER

    mov WORD PTR outputBuffer[edi*2], '-'
    inc edi
    neg eax

CONVERT_NUMBER:

    ; 숫자를 역순으로 추출
    xor ebp, ebp
    mov ecx, 10

DIGIT_LOOP:

    xor edx, edx
    div ecx

    push edx
    inc ebp

    test eax, eax
    jnz DIGIT_LOOP

    ; 숫자를 올바른 순서로 저장
OUTPUT_LOOP:

    pop edx
    add dx, '0'

    mov WORD PTR outputBuffer[edi*2], dx
    inc edi

    dec ebp
    jnz OUTPUT_LOOP

    ; 줄바꿈 추가
    mov WORD PTR outputBuffer[edi*2], 13
    inc edi

    mov WORD PTR outputBuffer[edi*2], 10
    inc edi

    ; 평균값 출력
    INVOKE WriteConsoleW, hOutput, ADDR outputBuffer, edi, ADDR written, 0

    ; 프로그램 종료
    INVOKE ExitProcess, 0

main ENDP
END main
