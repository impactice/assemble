# 8장 고급 프로시저 (Advanced Procedures) — 연습문제 풀이

> Kip Irvine, *Assembly Language for x86 Processors* 7판, 8.10절~8.11절
> 문제는 한국어로 요약했습니다. 원문은 교재 348~351쪽을 함께 보세요.
>
> 구성: **8.10.1 단답형 9문제 + 8.10.2 알고리즘 연습 11문제 + 8.11 프로그래밍 과제 10문제**

---

## 들어가기 전에 — 8장 핵심 그림과 표

8장은 **스택 프레임 그림 하나**를 이해하면 거의 다 풀립니다. 이 그림부터 손으로 그릴 수 있게 만드세요.

### ① 스택 프레임 (STDCALL, 매개변수 3개 + 지역 변수 2개) ⭐⭐⭐

```
                 높은 주소
               ┌──────────────────┐
  [EBP+16]  →  │  세 번째 인자      │  ← 가장 먼저 PUSH
               ├──────────────────┤
  [EBP+12]  →  │  두 번째 인자      │
               ├──────────────────┤
  [EBP+8]   →  │  첫 번째 인자      │  ← 가장 나중에 PUSH
               ├──────────────────┤
  [EBP+4]   →  │  복귀 주소         │  ← CALL이 PUSH
               ├──────────────────┤
  [EBP]     →  │  이전 EBP          │  ← push ebp / mov ebp,esp
               ├──────────────────┤
  [EBP-4]   →  │  지역 변수 1       │  ← sub esp,8 로 확보
               ├──────────────────┤
  [EBP-8]   →  │  지역 변수 2       │  ← ESP
               └──────────────────┘
                 낮은 주소
```

> **외우는 법: 매개변수는 `+`, 지역 변수는 `−`. 첫 번째 매개변수는 항상 `[EBP+8]`, 복귀 주소는 항상 `[EBP+4]`.**

### ② 프롤로그와 에필로그

| 단계 | 명령 | 의미 |
|---|---|---|
| 프롤로그 | `push ebp` | 호출한 쪽의 EBP 저장 |
| | `mov ebp,esp` | 이 프로시저의 기준점 설정 |
| | `sub esp,n` | 지역 변수 공간 확보 (있을 때만) |
| 에필로그 | `mov esp,ebp` | 지역 변수 공간 해제 |
| | `pop ebp` | 호출한 쪽의 EBP 복원 |
| | `ret n` | 복귀 + (STDCALL이면) 매개변수 n바이트 정리 |

> `ENTER n,0` = 프롤로그 3줄, `LEAVE` = 에필로그의 앞 2줄

### ③ C vs STDCALL 호출 규약 ⭐⭐

| | **C** | **STDCALL** |
|---|---|---|
| 인자 PUSH 순서 | 오른쪽 → 왼쪽 (역순) | 오른쪽 → 왼쪽 (역순) |
| **스택을 정리하는 쪽** | **호출한 쪽** (`add esp,n`) | **호출된 프로시저** (`ret n`) |
| 가변 인자 (printf 등) | **가능** | 불가능 |
| 사용처 | C/C++ 기본 | Windows API |

### ④ LOCAL 선언 문법

| 선언하려는 것 | 문법 |
|---|---|
| 단일 변수 | `LOCAL var:TYPE` |
| 배열 | `LOCAL arr[개수]:TYPE` |
| 포인터 | `LOCAL ptr:PTR TYPE` |
| 여러 개 | `LOCAL a:DWORD, b[10]:BYTE` |

> **LOCAL은 반드시 PROC 바로 다음 줄에 와야 합니다.** 명령어보다 먼저.

### ⑤ PROC · PROTO · INVOKE · ADDR 관계

```asm
MySub PROTO, a:DWORD, p:PTR BYTE        ; ① 원형 선언 (INVOKE보다 앞에)

    INVOKE MySub, 10, ADDR buffer       ; ② 호출 — 인자를 역순 PUSH 후 CALL

MySub PROC USES ebx, a:DWORD, p:PTR BYTE   ; ③ 정의 — 프롤로그/에필로그 자동 생성
    ...
    ret                                 ;    ret 8 로 자동 변환 (STDCALL)
MySub ENDP
```

| 키워드 | 역할 |
|---|---|
| `PROTO` | 프로시저 **원형** — 매개변수 개수와 타입을 미리 알려 줌 |
| `INVOKE` | 인자 PUSH + CALL을 **한 줄로** — PROTO와 개수·타입이 안 맞으면 어셈블 오류 |
| `ADDR` | INVOKE 안에서만 쓰는 **주소 전달** 연산자 (지역 변수에도 사용 가능) |
| `USES` | 수정하는 레지스터를 **자동 PUSH/POP** — 공백 구분, 반환 레지스터 제외 |

---

## 8.10.1 단답형 (Short Answer)

### 1. 스택 매개변수와 지역 변수를 모두 가진 프로시저의 에필로그에 들어가는 문장은?

**정답**

```asm
mov esp,ebp         ; ① 지역 변수 공간 해제
pop ebp             ; ② 호출한 쪽의 EBP 복원
ret n               ; ③ 복귀 (STDCALL이면 n = 매개변수 바이트 수)
```

`LEAVE` 를 쓰면 ①②를 한 줄로 줄일 수 있습니다.

```asm
leave
ret n
```

> ⚠️ **순서가 중요합니다.** `pop ebp` 를 먼저 하면 ESP가 아직 지역 변수 영역을 가리키고 있어서 **지역 변수 값을 EBP로 꺼내 버립니다.** 그러면 `ret` 이 엉뚱한 주소로 돌아갑니다.

---

### 2. C 함수가 32비트 정수를 반환할 때 반환값은 어디에 저장되는가?

**정답: EAX**

> 반환값 크기별로 정리하면
>
> | 반환 타입 | 위치 |
> |---|---|
> | 8 / 16 / 32비트 정수 | AL / AX / **EAX** |
> | 64비트 정수 (32비트 모드) | **EDX:EAX** |
> | 64비트 모드 정수 | RAX |

---

### 3. STDCALL 호출 규약을 쓰는 프로그램은 호출 후 스택을 어떻게 정리하는가?

**정답: 호출된 프로시저가 `RET n` 으로 정리합니다.**

`n` 은 **매개변수 전체 바이트 수**입니다. RET이 복귀 주소를 꺼낸 다음 ESP에 n을 더해 인자들을 한꺼번에 버립니다.

```asm
AddThree PROC                   ; DWORD 매개변수 3개
    ...
    ret 12                      ; 4바이트 × 3 = 12
AddThree ENDP
```

> **C 규약은 반대로 호출한 쪽이 정리합니다**: `call AddThree` 다음 줄에 `add esp,12`.

---

### 4. LEA 명령어가 OFFSET 연산자보다 강력한 이유는?

**정답: OFFSET은 어셈블할 때 주소가 정해진 것에만 쓸 수 있지만, LEA는 실행 시간에 주소를 계산하므로 스택 매개변수와 지역 변수의 주소도 구할 수 있습니다.**

| | OFFSET | LEA |
|---|---|---|
| 계산 시점 | **어셈블 시간** | **실행 시간** |
| 전역 변수 | ✅ `mov esi,OFFSET array` | ✅ `lea esi,array` |
| 지역 변수 / 스택 매개변수 | ❌ 불가능 | ✅ `lea esi,[ebp-20]` |
| 복잡한 주소식 | ❌ | ✅ `lea eax,[ebx+esi*4+8]` |

**예시** — 지역 배열의 주소를 넘길 때

```asm
MySub PROC
    LOCAL buffer[20]:BYTE
    lea  esi,buffer             ; ✅ 가능 — 실제로는 lea esi,[ebp-20]
    ; mov esi,OFFSET buffer     ; ❌ 불가능 — 지역 변수 주소는 실행할 때마다 다름
```

> 지역 변수는 프로시저가 **호출될 때마다 스택의 다른 위치**에 생깁니다. 그래서 어셈블 시간에 주소를 알 수 없고, OFFSET으로는 구할 수 없습니다.
>
> 덤: **LEA는 플래그를 바꾸지 않습니다.** 7장 확장 산술에서 포인터 이동에 썼던 이유입니다.

---

### 5. 8.2.3절의 C++ 예제에서 int형 변수는 스택 공간을 얼마나 쓰는가?

**정답: 4바이트 (32비트)**

**근거** 32비트 모드에서 **스택 항목 하나의 기본 크기는 32비트**입니다. 그래서 int 매개변수 하나는 스택에서 4바이트를 차지합니다. 더 작은 타입이라도 **4의 배수로 올림**되어 저장됩니다.

> 예: 매개변수 2개짜리 함수를 호출하면 **인자 4바이트 × 2 + 복귀 주소 4바이트 = 12바이트**의 스택을 씁니다.

---

### 6. C 호출 규약이 STDCALL보다 나은 점은?

**정답: 호출한 쪽이 스택을 정리하므로, 인자 개수가 정해지지 않은 가변 인자 함수(printf 등)를 만들 수 있습니다.**

**이유** STDCALL은 `ret 12` 처럼 **정리할 바이트 수가 프로시저 안에 고정**되어 있습니다. 인자를 몇 개 받을지 모르는 함수는 이걸 쓸 수 없습니다. C 규약에서는 호출한 쪽이 자기가 몇 개를 넣었는지 알기 때문에 그만큼 정확히 정리할 수 있습니다.

```c
printf("%d", a);           // 인자 2개 → 호출한 쪽이 add esp,8
printf("%d %d %d", a,b,c); // 인자 4개 → 호출한 쪽이 add esp,16
```

> 부가 장점: 여러 번 호출한 뒤 **한 번에 정리**할 수 있습니다 (`add esp,24` 한 줄로 두 번의 호출을 정리). 컴파일러가 최적화에 씁니다.
>
> 반대로 STDCALL의 장점은 **정리 코드가 프로시저 안에 한 번만** 있어서 코드가 작아진다는 점입니다.

---

### 7. (참/거짓) PROC 지시어를 쓸 때 모든 매개변수는 같은 줄에 나열해야 한다.

**정답: 거짓**

줄 끝에 **쉼표**를 두면 다음 줄로 이어 쓸 수 있습니다.

```asm
AddThree PROC,
    val1:DWORD,
    val2:DWORD,
    val3:DWORD
```

> **`PROC` 바로 뒤의 쉼표**를 빠뜨리지 마세요. 매개변수가 다음 줄에서 시작한다는 표시입니다.

---

### 8. (참/거짓) 바이트 배열의 오프셋을 담은 변수를, 워드 배열 포인터를 기대하는 프로시저에 넘기면 어셈블러가 오류로 표시한다.

**정답: 거짓**

어셈블러는 **포인터가 무엇을 가리키는지 검사하지 않습니다.** 포인터는 그냥 32비트 주소 값입니다. `PTR BYTE` 든 `PTR WORD` 든 DWORD 하나가 넘어갈 뿐이라 어셈블러는 그대로 통과시킵니다.

> 타입이 맞는지 확인하는 건 **프로그래머의 책임**입니다. 잘못 넘기면 실행 중에 엉뚱한 값을 읽게 됩니다.

---

### 9. (참/거짓) 참조 매개변수를 기대하는 프로시저에 즉시값을 넘기면 일반 보호 오류가 날 수 있다.

**정답: 참**

프로시저는 받은 값을 **주소로 보고 역참조**합니다. 즉시값(예: 10)을 넘기면 메모리 주소 10번지를 읽거나 쓰려 하고, 그곳은 프로그램이 접근할 수 없는 영역이라 **일반 보호 오류(general-protection fault)** 가 발생합니다.

```asm
Swap PROTO, pX:PTR DWORD, pY:PTR DWORD

    INVOKE Swap, 10, 20         ; ❌ 주소가 아니라 값을 넘김
                                ;    Swap 안에서 [10], [20]에 접근 → GP 오류
    INVOKE Swap, ADDR x, ADDR y ; ✅ 올바른 호출
```

> **8번과 9번은 한 쌍입니다.** 어셈블러는 포인터 타입을 검사하지 않으므로(8번), 잘못된 값을 넘겨도 어셈블은 되지만 **실행할 때 터집니다**(9번).

---

## 8.10.2 알고리즘 연습 (Algorithm Workbench)

### 1. AddThree의 스택 프레임 그리기 (EBP를 PUSH한 직후)

**호출 순서 (STDCALL)**

```asm
push 10h
push 20h
push 30h
call AddThree
```

**AddThree 안에서 `push ebp` 를 실행한 직후**

```
                 높은 주소
               ┌──────────────┐
  [ESP+16]  →  │     10h      │  ← 가장 먼저 PUSH → 세 번째 인자
               ├──────────────┤
  [ESP+12]  →  │     20h      │  ← 두 번째 인자
               ├──────────────┤
  [ESP+8]   →  │     30h      │  ← 가장 나중에 PUSH → 첫 번째 인자
               ├──────────────┤
  [ESP+4]   →  │   복귀 주소   │  ← CALL이 PUSH
               ├──────────────┤
  ESP       →  │   이전 EBP    │  ← 방금 PUSH한 EBP
               └──────────────┘
                 낮은 주소
```

이어서 `mov ebp,esp` 를 실행하면 EBP도 같은 곳을 가리키므로, 위 그림의 `ESP` 를 전부 `EBP` 로 바꿔 읽으면 됩니다.

> ⭐ **인자는 역순으로 PUSH됩니다.** 가장 나중에 넣은 30h가 첫 번째 인자(`[EBP+8]`)입니다. C로 쓰면 `AddThree(30h, 20h, 10h)` 를 호출한 것과 같습니다.

---

### 2. 정수 매개변수 3개를 받아 합을 EAX로 반환하는 AddThree 프로시저

**방법 1 — 명시적 스택 매개변수** (1번의 호출 순서와 그대로 맞물림)

```asm
AddThree PROC
    push ebp
    mov  ebp,esp
    mov  eax,[ebp+8]            ; 첫 번째 인자 (30h)
    add  eax,[ebp+12]           ; 두 번째 인자 (20h)
    add  eax,[ebp+16]           ; 세 번째 인자 (10h)
    pop  ebp
    ret  12                     ; STDCALL: 인자 12바이트 정리
AddThree ENDP
```

**결과** EAX = 30h + 20h + 10h = **60h**

**방법 2 — 매개변수 목록 사용** (MASM이 프롤로그·에필로그를 자동 생성)

```asm
AddThree PROC,
    val1:DWORD, val2:DWORD, val3:DWORD

    mov  eax,val1               ; MASM이 [ebp+8]로 바꿔 줌
    add  eax,val2               ; [ebp+12]
    add  eax,val3               ; [ebp+16]
    ret                         ; MASM이 ret 12 로 바꿔 줌
AddThree ENDP
```

> 방법 2로 쓴 코드를 어셈블하면 **방법 1과 똑같은 기계어**가 나옵니다. 매개변수 이름이 `[ebp+n]` 으로 치환될 뿐입니다.

---

### 3 ~ 7. 지역 변수 선언

| 번호 | 선언할 것 | 정답 |
|:---:|---|---|
| **3** | 더블워드 배열을 가리키는 포인터 `pArray` | `LOCAL pArray:PTR DWORD` |
| **4** | 20바이트짜리 배열 `buffer` | `LOCAL buffer[20]:BYTE` |
| **5** | 16비트 부호 없는 정수를 가리키는 포인터 `pwArray` | `LOCAL pwArray:PTR WORD` |
| **6** | 8비트 부호 있는 정수 `myByte` | `LOCAL myByte:SBYTE` |
| **7** | 더블워드 20개짜리 배열 `myArray` | `LOCAL myArray[20]:DWORD` |

**한 프로시저 안에 모아 쓰면**

```asm
MySub PROC
    LOCAL pArray:PTR DWORD,
          buffer[20]:BYTE,
          pwArray:PTR WORD,
          myByte:SBYTE,
          myArray[20]:DWORD

    ; 여기서부터 명령어
    ret
MySub ENDP
```

**문법 정리**

| 형태 | 규칙 |
|---|---|
| 배열 | 이름 뒤 **대괄호**에 개수 → `buffer[20]:BYTE` |
| 포인터 | **`PTR`** + 가리키는 타입 → `PTR DWORD` |
| 부호 있는 타입 | **S** 붙이기 → `SBYTE`, `SWORD`, `SDWORD` |
| 위치 | **PROC 바로 다음** (명령어보다 앞) |

> ⚠️ 헷갈리기 쉬운 것: `pwArray` 는 이름이 Array여도 **"16비트 정수를 가리키는 포인터"** 이므로 `PTR WORD` 입니다. 배열 선언이 아닙니다.
>
> MASM은 LOCAL을 보고 `sub esp,n` 과 `[ebp-x]` 참조를 자동으로 만들어 줍니다.

---

### 8. 스택 매개변수 forecolor, backcolor를 받아 SetTextColor를 호출하는 SetColor 프로시저

```asm
;---------------------------------------------------
; SetColor
;   전경색과 배경색을 받아 텍스트 색을 설정한다.
;   Receives: forecolor, backcolor (0~15)
;---------------------------------------------------
SetColor PROC USES eax,
    forecolor:DWORD,
    backcolor:DWORD

    mov  eax,backcolor
    shl  eax,4                  ; 배경색 × 16
    add  eax,forecolor          ; + 전경색
    call SetTextColor           ; EAX = 색 속성
    ret
SetColor ENDP
```

**호출 예**

```asm
    INVOKE SetColor, yellow, blue       ; 파란 배경에 노란 글자
```

> **색 속성 공식: `전경색 + (배경색 × 16)`** — 5장에서 나온 그 공식입니다. ×16을 `shl eax,4` 로 처리했습니다 (7장 시프트 곱셈).
>
> USES 문법: **`USES` 가 쉼표보다 앞**에 옵니다. `PROC USES eax, forecolor:DWORD, ...`

---

### 9. 스택 매개변수 char, forecolor, backcolor를 받아 문자 하나를 지정한 색으로 출력하는 WriteColorChar

```asm
;---------------------------------------------------
; WriteColorChar
;   문자 하나를 지정한 전경색/배경색으로 출력한다.
;   Receives: char, forecolor, backcolor
;---------------------------------------------------
WriteColorChar PROC USES eax,
    char:DWORD,
    forecolor:DWORD,
    backcolor:DWORD

    INVOKE SetColor, forecolor, backcolor   ; 8번 프로시저 재사용
    mov  eax,char
    call WriteChar                          ; AL의 문자 출력
    ret
WriteColorChar ENDP
```

**호출 예**

```asm
    INVOKE WriteColorChar, 'A', white, red  ; 빨간 배경에 흰 글자 'A'
```

> **8번을 그대로 불러 쓰는 것이 핵심입니다.** "짧고 한 가지 일만 하는 프로시저를 조합한다"는 8장의 설계 원칙을 보여 주는 문제입니다.
>
> 매개변수를 `char:BYTE` 로 선언해도 됩니다. 32비트 모드에서 INVOKE는 BYTE 인자도 **4바이트로 넓혀서 PUSH**합니다. 여기서는 단순하게 DWORD로 받았습니다.

---

### 10. Irvine32의 DumpMem을 감싸는 DumpMemory 프로시저 (선언된 매개변수 + USES 사용)

호출 형식: `INVOKE DumpMemory, OFFSET array, LENGTHOF array, TYPE array`

```asm
;---------------------------------------------------
; DumpMemory
;   DumpMem을 매개변수 방식으로 감싼다.
;   Receives: address       = 시작 주소
;             itemCount     = 원소 개수
;             componentSize = 원소 크기 (1, 2, 4)
;---------------------------------------------------
DumpMemory PROC USES esi ecx ebx,
    address:DWORD,
    itemCount:DWORD,
    componentSize:DWORD

    mov  esi,address            ; DumpMem은 ESI = 시작 주소
    mov  ecx,itemCount          ;            ECX = 원소 개수
    mov  ebx,componentSize      ;            EBX = 원소 크기
    call DumpMem
    ret
DumpMemory ENDP
```

**호출 예**

```asm
.data
array DWORD 1,2,3,4,5

.code
    INVOKE DumpMemory, OFFSET array, LENGTHOF array, TYPE array
```

> **레지스터 매개변수 → 스택 매개변수 변환** 문제입니다. DumpMem은 ESI·ECX·EBX로 인자를 받는데, 이걸 INVOKE로 부를 수 있게 포장하는 겁니다.
>
> **USES로 ESI·ECX·EBX를 보존**하는 이유: 호출한 쪽은 DumpMemory가 이 레지스터들을 바꾼다는 걸 모르기 때문입니다.

---

### 11. 더블워드 배열 포인터 2개와 원소 개수를 받는 MultArray 프로시저 선언 + PROTO

**PROTO 선언** (INVOKE보다 앞, 보통 파일 맨 위)

```asm
MultArray PROTO,
    pArray1:PTR DWORD,          ; 첫 번째 배열 포인터
    pArray2:PTR DWORD,          ; 두 번째 배열 포인터
    count:DWORD                 ; 원소 개수
```

**PROC 선언**

```asm
MultArray PROC,
    pArray1:PTR DWORD,
    pArray2:PTR DWORD,
    count:DWORD

    ; (본문)
    ret
MultArray ENDP
```

**본문 예시** — 대응하는 원소끼리 곱해 첫 번째 배열에 저장

```asm
MultArray PROC USES eax ecx edx esi edi,
    pArray1:PTR DWORD,
    pArray2:PTR DWORD,
    count:DWORD

    mov  esi,pArray1
    mov  edi,pArray2
    mov  ecx,count
    jecxz done
L1:
    mov  eax,[esi]
    mul  DWORD PTR [edi]        ; EDX:EAX = x × y (EDX는 버림)
    mov  [esi],eax
    add  esi,4
    add  edi,4
    loop L1
done:
    ret
MultArray ENDP
```

**호출 예**

```asm
    INVOKE MultArray, ADDR arr1, ADDR arr2, LENGTHOF arr1
```

> ⭐ **PROTO와 PROC의 매개변수 목록은 개수·순서·타입이 일치해야 합니다.** 이름은 달라도 되지만 같게 쓰는 게 안전합니다.
>
> **PROC 줄을 복사해서 `PROC` → `PROTO` 로 바꾸고 USES만 지우면** PROTO가 됩니다. 시험에서 이렇게 쓰면 실수가 없습니다.

---

## 8.11 프로그래밍 과제 (Programming Exercises)

> **손코딩 분량 (제 판단)** — 교수님이 긴 문제는 안 내시므로 "짧음"이 가장 유력합니다.
>
> | 번호 | 과제 | 분량 | 8장 핵심 개념 |
> |:---:|---|:---:|---|
> | 1 | FindLargest | **짧음** | 매개변수 목록, PROTO, 부호 있는 비교 |
> | 2 | 체스판 | 보통 | 짧은 프로시저 조합, 전역 변수 없이 |
> | 3 | 체스판 색 바꾸기 | 보통 | 2번 + 매개변수 추가, Delay |
> | 4 | FindThrees | **짧음** | 매개변수 목록, 연속 카운트 |
> | 5 | DifferentInputs | **매우 짧음** | PROTO, INVOKE, 단락 평가 |
> | 6 | 정수 쌍 교환 | **짧음** | 참조 매개변수 (Swap) |
> | 7 | 재귀 GCD | **짧음** | **재귀** |
> | 8 | CountMatches | **짧음** | INVOKE, PROTO, 포인터 2개 |
> | 9 | CountNearMatches | 보통 | 8번 + 절댓값 |
> | 10 | ShowParams | 보통 | **호출한 쪽의 스택 프레임 읽기** |

---

### 1. FindLargest — 부호 있는 배열의 최댓값

**문제 요약** 부호 있는 더블워드 배열의 포인터와 길이를 받아 **가장 큰 값을 EAX로 반환**하는 `FindLargest` 를 작성하시오. 매개변수 목록이 있는 PROC으로 선언하고, EAX를 제외한 수정 레지스터는 모두 보존한다. 음수를 포함한 길이가 다른 배열 3개로 테스트하고, PROTO 선언도 만든다.

```asm
; FindLargest.asm

INCLUDE Irvine32.inc

FindLargest PROTO,
    pArray:PTR SDWORD,
    count:DWORD

.data
array1 SDWORD -5, 12, 7, -30, 45, 3
array2 SDWORD -100, -20, -3, -50
array3 SDWORD 8, 8, 1000, -1000, 999, 0, 42, -7

.code
main PROC
    INVOKE FindLargest, ADDR array1, LENGTHOF array1
    call WriteInt               ; +45
    call Crlf

    INVOKE FindLargest, ADDR array2, LENGTHOF array2
    call WriteInt               ; -3
    call Crlf

    INVOKE FindLargest, ADDR array3, LENGTHOF array3
    call WriteInt               ; +1000
    call Crlf

    exit
main ENDP

;---------------------------------------------------
; FindLargest
;   부호 있는 더블워드 배열에서 최댓값을 찾는다.
;   Receives: pArray = 배열 주소, count = 원소 개수
;   Returns:  EAX = 최댓값 (원소가 없으면 80000000h)
;---------------------------------------------------
FindLargest PROC USES ecx esi,
    pArray:PTR SDWORD,
    count:DWORD

    mov  esi,pArray
    mov  ecx,count
    mov  eax,80000000h          ; ⭐ 가장 작은 부호 있는 정수로 시작
    jecxz done                  ; 원소가 없으면 바로 종료

L1:
    cmp  [esi],eax
    jle  next                   ; ⭐ 부호 있는 비교 (JBE 아님!)
    mov  eax,[esi]              ; 더 크면 최댓값 갱신
next:
    add  esi,TYPE SDWORD        ; 4바이트씩
    loop L1

done:
    ret
FindLargest ENDP
END main
```

**실행 결과**

```
+45
-3
+1000
```

**채점 포인트**
- **`80000000h`(−2,147,483,648)로 시작**하면 첫 원소를 따로 처리할 필요가 없습니다. 0으로 시작하면 **전부 음수인 array2에서 틀린 답(0)** 이 나옵니다 — 이 문제가 음수를 넣으라고 한 이유입니다
- 부호 있는 배열이므로 **`JLE`** (G/L 계열). `JBE` 를 쓰면 −3보다 45를 작다고 판단합니다
- **반환값 EAX는 USES에 넣지 않습니다**
- 6장에서 나온 **`JECXZ`** 로 빈 배열을 처리합니다 (중간고사 12번 문제!)

---

### 2. 체스판 그리기

**문제 요약** 회색과 흰색이 번갈아 나오는 8×8 체스판을 그리시오. SetTextColor와 Gotoxy를 사용하고, **전역 변수 없이** 모든 프로시저에서 선언된 매개변수를 쓰며, **한 가지 일만 하는 짧은 프로시저**로 나눈다.

```asm
; ChessBoard.asm

INCLUDE Irvine32.inc

DrawBoard  PROTO
DrawRow    PROTO, row:DWORD
DrawSquare PROTO, row:DWORD, col:DWORD, color:DWORD

.code
main PROC
    call Clrscr
    INVOKE DrawBoard

    mov  eax,lightGray + (black * 16)   ; 원래 색으로 복구
    call SetTextColor
    mov  dh,9                           ; 판 아래로 커서 이동
    mov  dl,0
    call Gotoxy
    exit
main ENDP

;---------------------------------------------------
; DrawBoard — 행 8개를 차례로 그린다
;---------------------------------------------------
DrawBoard PROC USES ecx
    mov  ecx,0                  ; 행 번호
L1:
    INVOKE DrawRow, ecx
    inc  ecx
    cmp  ecx,8
    jb   L1
    ret
DrawBoard ENDP

;---------------------------------------------------
; DrawRow — 한 행에 칸 8개를 번갈아 그린다
;   Receives: row = 행 번호 (0~7)
;---------------------------------------------------
DrawRow PROC USES eax ecx,
    row:DWORD

    mov  ecx,0                  ; 열 번호
L1:
    mov  eax,row
    add  eax,ecx                ; 행 + 열
    test eax,1                  ; 홀수 → 회색, 짝수 → 흰색
    jnz  graySquare
    INVOKE DrawSquare, row, ecx, white * 16
    jmp  next
graySquare:
    INVOKE DrawSquare, row, ecx, gray * 16
next:
    inc  ecx
    cmp  ecx,8
    jb   L1
    ret
DrawRow ENDP

;---------------------------------------------------
; DrawSquare — 지정한 위치에 색칠한 칸 하나를 그린다
;   한 칸 = 공백 2글자 (콘솔 글자는 세로로 길어서
;           2글자를 나란히 놓으면 정사각형에 가까워진다)
;   Receives: row, col = 칸 위치, color = 배경색 × 16
;---------------------------------------------------
DrawSquare PROC USES eax edx,
    row:DWORD, col:DWORD, color:DWORD

    mov  eax,color
    call SetTextColor           ; 배경색 지정

    mov  eax,col
    shl  eax,1                  ; 화면 열 = col × 2
    mov  dl,al
    mov  eax,row
    mov  dh,al                  ; 화면 행 = row
    call Gotoxy

    mov  al,' '
    call WriteChar
    call WriteChar              ; 공백 2개 = 한 칸
    ret
DrawSquare ENDP
END main
```

**설계 포인트**

```
main
 └─ DrawBoard            "판 전체" — 행 8번 반복
     └─ DrawRow(row)     "한 행" — 칸 8번 반복, 색 결정
         └─ DrawSquare(row, col, color)   "한 칸" — 커서 이동 + 출력
```

- **`.data` 섹션이 아예 없습니다.** 문제의 "전역 변수 금지" 조건을 만족합니다. 모든 정보가 매개변수로 전달됩니다
- 색 결정: **(행 + 열)이 짝수면 흰색, 홀수면 회색.** `test eax,1` 로 최하위 비트만 보면 홀짝을 알 수 있습니다 (6장 TEST)
- 배경색은 **색 번호 × 16** (`white * 16`, `gray * 16`). 공백만 출력하므로 전경색은 상관없습니다

---

### 3. 색이 바뀌는 체스판

**문제 요약** 2번을 확장해서, **500밀리초마다** 회색 칸의 색을 바꿔 다시 그리시오. 4비트 배경색 16가지를 모두 써서 판을 16번 보여 준다. (흰 칸은 계속 흰색)

```asm
; ChessBoard2.asm

INCLUDE Irvine32.inc

DrawBoard  PROTO, darkColor:DWORD
DrawRow    PROTO, row:DWORD, darkColor:DWORD
DrawSquare PROTO, row:DWORD, col:DWORD, color:DWORD

.code
main PROC
    call Clrscr
    mov  ecx,0                  ; 배경색 번호 0~15
L1:
    mov  eax,ecx
    shl  eax,4                  ; 배경색 = 색 번호 × 16
    INVOKE DrawBoard, eax

    mov  eax,500
    call Delay                  ; 500ms 대기

    inc  ecx
    cmp  ecx,16
    jb   L1

    mov  eax,lightGray + (black * 16)
    call SetTextColor
    mov  dh,9
    mov  dl,0
    call Gotoxy
    exit
main ENDP

;---------------------------------------------------
; DrawBoard — 행 8개를 그린다
;   Receives: darkColor = 색칠할 칸의 배경색 (× 16 된 값)
;---------------------------------------------------
DrawBoard PROC USES ecx,
    darkColor:DWORD

    mov  ecx,0
L1:
    INVOKE DrawRow, ecx, darkColor
    inc  ecx
    cmp  ecx,8
    jb   L1
    ret
DrawBoard ENDP

;---------------------------------------------------
; DrawRow — 한 행을 그린다
;   Receives: row = 행 번호, darkColor = 색칠할 칸의 배경색
;---------------------------------------------------
DrawRow PROC USES eax ecx,
    row:DWORD, darkColor:DWORD

    mov  ecx,0
L1:
    mov  eax,row
    add  eax,ecx
    test eax,1
    jnz  colored
    INVOKE DrawSquare, row, ecx, white * 16     ; 흰 칸은 고정
    jmp  next
colored:
    INVOKE DrawSquare, row, ecx, darkColor      ; ⭐ 매개변수로 받은 색
next:
    inc  ecx
    cmp  ecx,8
    jb   L1
    ret
DrawRow ENDP

;---------------------------------------------------
; DrawSquare — 2번과 동일
;---------------------------------------------------
DrawSquare PROC USES eax edx,
    row:DWORD, col:DWORD, color:DWORD

    mov  eax,color
    call SetTextColor
    mov  eax,col
    shl  eax,1
    mov  dl,al
    mov  eax,row
    mov  dh,al
    call Gotoxy
    mov  al,' '
    call WriteChar
    call WriteChar
    ret
DrawSquare ENDP
END main
```

**2번에서 바뀐 것은 딱 두 가지입니다**

| 변경 | 내용 |
|---|---|
| ① 색을 매개변수로 | DrawBoard와 DrawRow에 `darkColor` 매개변수 추가 → 아래로 그대로 전달 |
| ② main에 반복 + 대기 | 0~15번 색으로 16번 그리고, 매번 **`Delay`** (EAX = 밀리초) |

> 💡 **매개변수로 설계해 둔 덕분에 DrawSquare는 한 글자도 바뀌지 않았습니다.** 전역 변수로 색을 관리했다면 여러 곳을 고쳐야 했을 겁니다. 2번이 "전역 변수 금지"를 요구한 이유가 여기서 드러납니다.
>
> 15번 색(흰색)일 때는 모든 칸이 흰색이 되어 판이 잠깐 하얗게 보입니다. 16가지를 **모두** 쓰라는 조건 때문이니 정상입니다.

---

### 4. FindThrees — 3이 세 번 연속으로 나오는지 찾기

**문제 요약** 배열 어딘가에 **3이 세 번 연속**으로 나오면 1, 아니면 0을 반환하는 `FindThrees` 를 작성하시오. 매개변수는 배열 포인터와 크기. 매개변수 목록이 있는 PROC으로 선언하고, EAX 외의 수정 레지스터는 보존한다.

```asm
; FindThrees.asm

INCLUDE Irvine32.inc

FindThrees PROTO,
    pArray:PTR DWORD,
    count:DWORD

.data
arr1 DWORD 1, 3, 3, 3, 5                ; 있음 → 1
arr2 DWORD 3, 3, 1, 3, 3                ; 없음 → 0  (끊김)
arr3 DWORD 3, 3, 3                      ; 있음 → 1  (배열 전체)
arr4 DWORD 7, 3, 3, 8, 3, 3, 3, 2       ; 있음 → 1  (두 번째 구간)
arr5 DWORD 3, 3                         ; 없음 → 0  (두 개뿐)

.code
main PROC
    INVOKE FindThrees, ADDR arr1, LENGTHOF arr1
    call WriteDec
    call Crlf
    INVOKE FindThrees, ADDR arr2, LENGTHOF arr2
    call WriteDec
    call Crlf
    INVOKE FindThrees, ADDR arr3, LENGTHOF arr3
    call WriteDec
    call Crlf
    INVOKE FindThrees, ADDR arr4, LENGTHOF arr4
    call WriteDec
    call Crlf
    INVOKE FindThrees, ADDR arr5, LENGTHOF arr5
    call WriteDec
    call Crlf
    exit
main ENDP

;---------------------------------------------------
; FindThrees
;   배열에 3이 세 번 연속 나오는지 검사한다.
;   Receives: pArray = 배열 주소, count = 원소 개수
;   Returns:  EAX = 1 (있음) / 0 (없음)
;---------------------------------------------------
FindThrees PROC USES ecx edx esi,
    pArray:PTR DWORD,
    count:DWORD

    mov  esi,pArray
    mov  ecx,count
    mov  edx,0                  ; 지금까지 연속된 3의 개수
    jecxz notFound

L1:
    cmp  DWORD PTR [esi],3
    jne  reset
    inc  edx                    ; 3이면 연속 횟수 +1
    cmp  edx,3
    je   found                  ; ⭐ 세 번 연속 → 바로 성공
    jmp  next
reset:
    mov  edx,0                  ; ⭐ 3이 아니면 연속이 끊김
next:
    add  esi,4
    loop L1

notFound:
    mov  eax,0
    ret
found:
    mov  eax,1
    ret
FindThrees ENDP
END main
```

**실행 결과** `1 0 1 1 0`

**동작 추적** (arr2 = 3, 3, 1, 3, 3)

| 원소 | 3인가? | EDX (연속 횟수) |
|---|:---:|:---:|
| 3 | 예 | 1 |
| 3 | 예 | 2 |
| **1** | **아니오** | **0 ← 리셋** |
| 3 | 예 | 1 |
| 3 | 예 | 2 |
| 끝 | | 3에 도달 못 함 → **0 반환** |

**채점 포인트**
- **3이 아니면 카운터를 0으로 리셋**하는 것이 핵심입니다. 이걸 빼면 "3이 총 3개 이상"을 세게 되어 arr2에서 틀립니다
- 세 번에 도달하면 **즉시 반환** — 나머지를 볼 필요가 없습니다
- 프로시저 안에 **`ret` 이 두 개**여도 됩니다. MASM이 **각 RET 앞에 USES의 POP을 자동으로** 넣어 줍니다

---

### 5. DifferentInputs — 세 입력이 모두 다른지 검사

**문제 요약** 세 입력 매개변수가 **모두 다르면 EAX = 1**, 아니면 0을 반환하는 `DifferentInputs` 를 작성하시오. 매개변수 목록이 있는 PROC, PROTO 선언, 테스트 프로그램에서 5번 호출.

```asm
; DifferentInputs.asm

INCLUDE Irvine32.inc

DifferentInputs PROTO,
    v1:DWORD, v2:DWORD, v3:DWORD

.code
main PROC
    INVOKE DifferentInputs, 1, 2, 3         ; → 1
    call WriteDec
    call Crlf
    INVOKE DifferentInputs, 5, 5, 6         ; → 0  (v1 = v2)
    call WriteDec
    call Crlf
    INVOKE DifferentInputs, 7, 8, 7         ; → 0  (v1 = v3)
    call WriteDec
    call Crlf
    INVOKE DifferentInputs, 9, 4, 4         ; → 0  (v2 = v3)
    call WriteDec
    call Crlf
    INVOKE DifferentInputs, -1, 0, 1        ; → 1
    call WriteDec
    call Crlf
    exit
main ENDP

;---------------------------------------------------
; DifferentInputs
;   세 값이 모두 다른지 검사한다.
;   Receives: v1, v2, v3
;   Returns:  EAX = 1 (모두 다름) / 0 (같은 쌍이 있음)
;---------------------------------------------------
DifferentInputs PROC USES ebx,
    v1:DWORD, v2:DWORD, v3:DWORD

    mov  eax,0                  ; 기본값: 같은 쌍이 있다
    mov  ebx,v1
    cmp  ebx,v2
    je   done                   ; v1 = v2 → 0
    cmp  ebx,v3
    je   done                   ; v1 = v3 → 0
    mov  ebx,v2
    cmp  ebx,v3
    je   done                   ; v2 = v3 → 0
    mov  eax,1                  ; 세 비교를 모두 통과 → 모두 다름
done:
    ret
DifferentInputs ENDP
END main
```

**실행 결과** `1 0 0 0 1`

**채점 포인트**
- 비교할 쌍은 **세 개뿐**입니다: (v1,v2), (v1,v3), (v2,v3)
- **`cmp v1,v2` 는 불가능합니다** (메모리 ↔ 메모리). 매개변수도 결국 `[ebp+8]` 같은 메모리라서, 하나를 **레지스터로 먼저 옮겨야** 합니다
- **같은 쌍을 하나라도 찾으면 즉시 종료** — 6장 **단락 평가**(OR 조건) 패턴 그대로입니다
- 같다/다르다만 보므로 부호와 무관하게 **`JE`** 를 씁니다

> ⭐ **8장에서 가장 짧은 프로그래밍 과제입니다.** 손코딩 출제 1순위 후보로 보세요.

---

### 6. 정수 쌍 교환 (Swap 프로시저 활용)

**문제 요약** 무작위 순서의 정수 배열을 만들고, 8.4.6절의 Swap 프로시저를 써서 **연속된 두 원소씩 맞바꾸는** 루프를 작성하시오.

```asm
; ExchangePairs.asm

INCLUDE Irvine32.inc

Swap PROTO,
    pValX:PTR DWORD,
    pValY:PTR DWORD

.data
array DWORD 47, 12, 85, 3, 61, 29, 70, 5    ; 무작위 순서

.code
main PROC
    call ShowArray              ; 47 12 85 3 61 29 70 5

    mov  esi,OFFSET array
    mov  ecx,LENGTHOF array / 2 ; 쌍의 개수 = 4
L1:
    mov  edi,esi
    add  edi,TYPE array         ; 짝이 되는 다음 원소의 주소
    INVOKE Swap, esi, edi       ; ⭐ 주소(참조)를 넘긴다
    add  esi,TYPE array * 2     ; 다음 쌍으로 (8바이트)
    loop L1

    call ShowArray              ; 12 47 3 85 29 61 5 70
    exit
main ENDP

;---------------------------------------------------
; Swap
;   두 더블워드의 값을 맞바꾼다.
;   Receives: pValX, pValY = 두 값의 주소
;---------------------------------------------------
Swap PROC USES eax esi edi,
    pValX:PTR DWORD,
    pValY:PTR DWORD

    mov  esi,pValX              ; 첫 번째 주소
    mov  edi,pValY              ; 두 번째 주소
    mov  eax,[esi]              ; X 값
    xchg eax,[edi]              ; X ↔ Y
    mov  [esi],eax              ; Y 값을 X 자리에
    ret
Swap ENDP

;---------------------------------------------------
; ShowArray — 배열 출력 (테스트용)
;---------------------------------------------------
ShowArray PROC USES eax ecx esi
    mov  esi,OFFSET array
    mov  ecx,LENGTHOF array
L1:
    mov  eax,[esi]
    call WriteDec
    mov  al,' '
    call WriteChar
    add  esi,4
    loop L1
    call Crlf
    ret
ShowArray ENDP
END main
```

**실행 결과**

```
47 12 85 3 61 29 70 5
12 47 3 85 29 61 5 70
```

**채점 포인트**
- **Swap에는 값이 아니라 주소를 넘깁니다** (참조 매개변수). 값을 넘기면 Swap 안에서 바꿔도 배열은 그대로입니다 — 단답형 9번과 연결
- 쌍 개수 = `LENGTHOF array / 2`. 원소가 홀수 개면 마지막 하나는 짝이 없어 그대로 남습니다
- 다음 쌍으로 갈 때 **8바이트**(원소 2개) 이동

> 💡 배열을 실행할 때마다 무작위로 채우려면 `call Randomize` 후 루프에서 `mov eax,100` / `call RandomRange` / `mov [esi],eax` 로 채우면 됩니다.

---

### 7. 재귀로 구현하는 최대공약수 (GCD) ⭐

**문제 요약** 유클리드 호제법을 **재귀**로 구현하시오. (5,20), (24,18), (11,7), (432,226), (26,13) 다섯 쌍으로 호출하고 각 결과를 출력한다.

**재귀 정의**

```
GCD(x, y) = x                    (y = 0 일 때)  ← 기저 조건
          = GCD(y, x mod y)      (그 외)        ← 재귀 호출
```

```asm
; RecursiveGCD.asm

INCLUDE Irvine32.inc

GCD     PROTO, x:DWORD, y:DWORD
ShowGCD PROTO, x:DWORD, y:DWORD

.data
msg1 BYTE "GCD(",0
msg2 BYTE ", ",0
msg3 BYTE ") = ",0

.code
main PROC
    INVOKE ShowGCD, 5, 20
    INVOKE ShowGCD, 24, 18
    INVOKE ShowGCD, 11, 7
    INVOKE ShowGCD, 432, 226
    INVOKE ShowGCD, 26, 13
    exit
main ENDP

;---------------------------------------------------
; GCD — 유클리드 호제법 (재귀)
;   Receives: x, y (부호 없는 정수)
;   Returns:  EAX = 최대공약수
;---------------------------------------------------
GCD PROC USES edx,
    x:DWORD, y:DWORD

    mov  eax,x
    cmp  y,0
    je   done                   ; ⭐ 기저 조건: y = 0 이면 x가 답

    mov  edx,0                  ; 피제수 상위 절반 = 0
    div  y                      ; EDX = x mod y
    INVOKE GCD, y, edx          ; ⭐ 재귀: GCD(y, x mod y)
                                ;    결과는 이미 EAX에 있음
done:
    ret
GCD ENDP

;---------------------------------------------------
; ShowGCD — "GCD(x, y) = z" 형식으로 출력
;---------------------------------------------------
ShowGCD PROC USES eax edx,
    x:DWORD, y:DWORD

    mov  edx,OFFSET msg1
    call WriteString
    mov  eax,x
    call WriteDec
    mov  edx,OFFSET msg2
    call WriteString
    mov  eax,y
    call WriteDec
    mov  edx,OFFSET msg3
    call WriteString

    INVOKE GCD, x, y
    call WriteDec               ; EAX = 결과
    call Crlf
    ret
ShowGCD ENDP
END main
```

**실행 결과**

```
GCD(5, 20) = 5
GCD(24, 18) = 6
GCD(11, 7) = 1
GCD(432, 226) = 2
GCD(26, 13) = 13
```

**재귀 추적** — GCD(432, 226)

| 깊이 | 호출 | x mod y | 다음 호출 |
|:---:|---|---|---|
| 1 | GCD(432, 226) | 432 mod 226 = 206 | GCD(226, 206) |
| 2 | GCD(226, 206) | 20 | GCD(206, 20) |
| 3 | GCD(206, 20) | 6 | GCD(20, 6) |
| 4 | GCD(20, 6) | 2 | GCD(6, 2) |
| 5 | GCD(6, 2) | 0 | GCD(2, 0) |
| 6 | GCD(2, 0) | — | **y = 0 → 2 반환** |

여기서 2가 EAX에 담긴 채로 **깊이 6 → 5 → … → 1 순서로 RET**하며 그대로 올라옵니다.

**재귀 중 스택 모습** (깊이 3일 때)

```
  높은 주소
  ┌──────────────────────┐
  │ GCD(432,226)의 프레임 │  y=226, x=432, 복귀주소, EBP, EDX
  ├──────────────────────┤
  │ GCD(226,206)의 프레임 │  y=206, x=226, 복귀주소, EBP, EDX
  ├──────────────────────┤
  │ GCD(206,20)의 프레임  │  ← 현재 실행 중
  └──────────────────────┘
  낮은 주소 (ESP)
```

**채점 포인트**
- **기저 조건(y = 0)을 먼저** 검사합니다. 이게 없으면 0으로 나누기 오류가 나거나 무한 재귀로 **스택 오버플로**가 납니다
- 재귀 호출이 반환한 값이 **이미 EAX에 있으므로** 그냥 `ret` 하면 됩니다. 별도로 옮길 필요 없습니다
- **호출마다 새 스택 프레임**이 생깁니다. 그래서 x, y 매개변수가 깊이마다 독립적으로 유지됩니다 — 재귀가 가능한 이유입니다
- DIV 앞의 **`mov edx,0`** (7장)

> ⭐ **재귀는 8장의 핵심 주제입니다.** 이 문제는 짧으면서 재귀의 세 요소(기저 조건 / 재귀 호출 / 결과 전달)가 다 들어 있어서 손코딩 출제 가능성이 높습니다. 7장 프로그래밍 과제 6번(반복문 GCD)과 비교해 보세요.

---

### 8. CountMatches — 같은 위치의 일치하는 원소 세기

**문제 요약** 부호 있는 더블워드 배열 두 개의 포인터와 길이를 받아, 같은 위치의 원소 xᵢ와 yᵢ가 **같으면 카운트**해서 개수를 EAX로 반환하는 `CountMatches` 를 작성하시오. INVOKE로 호출하고, PROTO를 만들고, EAX 외의 레지스터는 보존한다.

```asm
; CountMatches.asm

INCLUDE Irvine32.inc

CountMatches PROTO,
    pArr1:PTR SDWORD,
    pArr2:PTR SDWORD,
    count:DWORD

.data
arrA1 SDWORD  5, -3,  8, 10, -7,  2
arrB1 SDWORD  5,  3,  8,  9, -7,  1     ; 일치: 5, 8, -7 → 3개

arrA2 SDWORD -1, -2, -3, -4
arrB2 SDWORD -1, -2, -3, -4             ; 전부 일치 → 4개

.code
main PROC
    INVOKE CountMatches, ADDR arrA1, ADDR arrB1, LENGTHOF arrA1
    call WriteDec               ; 3
    call Crlf

    INVOKE CountMatches, ADDR arrA2, ADDR arrB2, LENGTHOF arrA2
    call WriteDec               ; 4
    call Crlf
    exit
main ENDP

;---------------------------------------------------
; CountMatches
;   두 배열에서 같은 위치의 원소가 같은 개수를 센다.
;   Receives: pArr1, pArr2 = 배열 주소, count = 원소 개수
;   Returns:  EAX = 일치하는 원소 개수
;---------------------------------------------------
CountMatches PROC USES ebx ecx esi edi,
    pArr1:PTR SDWORD,
    pArr2:PTR SDWORD,
    count:DWORD

    mov  esi,pArr1
    mov  edi,pArr2
    mov  ecx,count
    mov  eax,0                  ; 일치 개수
    jecxz done

L1:
    mov  ebx,[esi]
    cmp  ebx,[edi]              ; xᵢ = yᵢ ?
    jne  next
    inc  eax
next:
    add  esi,4
    add  edi,4
    loop L1

done:
    ret
CountMatches ENDP
END main
```

**채점 포인트**
- **포인터 두 개(ESI, EDI)를 나란히** 이동시킵니다
- 메모리끼리 비교할 수 없으므로 **EBX를 경유**합니다
- EAX를 카운터로 쓰다가 그대로 반환합니다. **USES에서 EAX 제외**

---

### 9. CountNearMatches — 차이가 diff 이하인 원소 세기

**문제 요약** 8번에 **최대 허용 차이 diff** 매개변수를 추가해서, |xᵢ − yᵢ| ≤ diff 이면 카운트하는 `CountNearMatches` 를 작성하시오.

> 📝 교재 문제 끝에 "CountMatches의 PROTO를 만들라"고 되어 있는데, 문맥상 **CountNearMatches의 PROTO**를 말하는 것으로 보입니다.

```asm
; CountNearMatches.asm

INCLUDE Irvine32.inc

CountNearMatches PROTO,
    pArr1:PTR SDWORD,
    pArr2:PTR SDWORD,
    count:DWORD,
    diff:DWORD

.data
arrA1 SDWORD  5, -3,  8, 10, -7,  2
arrB1 SDWORD  5,  3,  8,  9, -7,  1     ; diff=1 → 5개 (|-3-3|=6만 탈락)

arrC1 SDWORD 100, 200, 300, 400
arrC2 SDWORD 103, 198, 310, 400         ; diff=3 → 3개 (|300-310|=10만 탈락)

.code
main PROC
    INVOKE CountNearMatches, ADDR arrA1, ADDR arrB1, LENGTHOF arrA1, 1
    call WriteDec               ; 5
    call Crlf

    INVOKE CountNearMatches, ADDR arrC1, ADDR arrC2, LENGTHOF arrC1, 3
    call WriteDec               ; 3
    call Crlf
    exit
main ENDP

;---------------------------------------------------
; CountNearMatches
;   |xᵢ - yᵢ| <= diff 인 원소 개수를 센다.
;   Receives: pArr1, pArr2 = 배열 주소, count = 원소 개수,
;             diff = 허용 차이
;   Returns:  EAX = 조건을 만족하는 원소 개수
;---------------------------------------------------
CountNearMatches PROC USES ebx ecx esi edi,
    pArr1:PTR SDWORD,
    pArr2:PTR SDWORD,
    count:DWORD,
    diff:DWORD

    mov  esi,pArr1
    mov  edi,pArr2
    mov  ecx,count
    mov  eax,0
    jecxz done

L1:
    mov  ebx,[esi]
    sub  ebx,[edi]              ; EBX = xᵢ - yᵢ
    jns  notNeg                 ; ⭐ 음수가 아니면 그대로
    neg  ebx                    ;    음수면 부호를 뒤집어 절댓값으로
notNeg:
    cmp  ebx,diff
    jg   next                   ; 차이 > diff 이면 건너뜀
    inc  eax
next:
    add  esi,4
    add  edi,4
    loop L1

done:
    ret
CountNearMatches ENDP
END main
```

**8번에서 바뀐 부분**

| 8번 | 9번 |
|---|---|
| `cmp ebx,[edi]` / `jne next` | `sub ebx,[edi]` → **절댓값** → `cmp ebx,diff` / `jg next` |

**채점 포인트**
- **절댓값 = `SUB` 후 `JNS` + `NEG`.** SUB 결과의 부호 플래그(SF)를 보고 음수일 때만 NEG합니다
- 7장 알고리즘 연습 16번의 **분기 없는 절댓값**(`sar`/`add`/`xor`)을 써도 됩니다
- 부호 있는 배열이므로 **`JG`** (G/L 계열)

---

### 10. ShowParams — 호출한 프로시저의 스택 매개변수 출력

**문제 요약** 자신을 호출한 프로시저의 **스택 매개변수들의 주소와 16진 값**을 낮은 주소부터 출력하는 `ShowParams` 를 작성하시오. 입력은 출력할 매개변수 개수 하나다.

**출력 형식**

```
Stack parameters:
---------------------------
Address 0019FF20 = 00001234
Address 0019FF24 = 00005000
Address 0019FF28 = 00006543
```

(주소는 실행 환경마다 다릅니다)

```asm
; ShowParams.asm

INCLUDE Irvine32.inc

MySample   PROTO, first:DWORD, second:DWORD, third:DWORD
ShowParams PROTO, nParams:DWORD

.data
heading BYTE "Stack parameters:",0dh,0ah
        BYTE "---------------------------",0dh,0ah,0
addrMsg BYTE "Address ",0
eqMsg   BYTE " = ",0

.code
main PROC
    INVOKE MySample, 1234h, 5000h, 6543h
    exit
main ENDP

;---------------------------------------------------
; MySample — 매개변수 3개를 받아 ShowParams로 확인한다
;---------------------------------------------------
MySample PROC,
    first:DWORD, second:DWORD, third:DWORD

    paramCount = 3
    INVOKE ShowParams, paramCount
    ret
MySample ENDP

;---------------------------------------------------
; ShowParams
;   자신을 호출한 프로시저의 스택 매개변수를
;   낮은 주소부터 주소와 16진 값으로 출력한다.
;   Receives: nParams = 출력할 매개변수 개수
;---------------------------------------------------
ShowParams PROC USES eax ecx edx esi,
    nParams:DWORD

    mov  edx,OFFSET heading
    call WriteString

    mov  esi,[ebp]              ; ⭐⭐ 호출한 프로시저(MySample)의 EBP
    add  esi,8                  ; ⭐   그 첫 번째 매개변수의 주소
    mov  ecx,nParams
    jecxz done

L1:
    mov  edx,OFFSET addrMsg
    call WriteString
    mov  eax,esi
    call WriteHex               ; 주소
    mov  edx,OFFSET eqMsg
    call WriteString
    mov  eax,[esi]
    call WriteHex               ; 값
    call Crlf
    add  esi,4                  ; 다음 매개변수 (높은 주소 쪽)
    loop L1

done:
    ret
ShowParams ENDP
END main
```

**핵심: `mov esi,[ebp]` 한 줄이 이 문제의 전부입니다**

ShowParams가 실행 중일 때 스택은 이렇게 생겼습니다.

```
                 높은 주소
               ┌────────────────────┐
               │  6543h  (third)    │  [MySample의 EBP + 16]
               │  5000h  (second)   │  [MySample의 EBP + 12]
               │  1234h  (first)    │  [MySample의 EBP + 8]  ← 여기를 찾아야 함
               │  main으로의 복귀주소 │  [MySample의 EBP + 4]
  MySample의 →  │  main의 EBP        │  ◄─────────────┐
  EBP          ├────────────────────┤                │
               │  3  (nParams)      │  [EBP + 8]     │
               │  MySample로의 복귀  │  [EBP + 4]     │
  ShowParams → │  MySample의 EBP ───┼────────────────┘
  의 EBP       ├────────────────────┤
               │  USES로 저장한 것들 │
               └────────────────────┘
                 낮은 주소
```

1. ShowParams의 **`[EBP]`** 에는 프롤로그의 `push ebp` 때 저장한 **MySample의 EBP**가 들어 있습니다
2. MySample의 매개변수는 **MySample의 EBP + 8** 부터 시작합니다
3. 그래서 `mov esi,[ebp]` → `add esi,8` 이면 MySample의 첫 매개변수 주소가 됩니다
4. 거기서 **4바이트씩 위로** 올라가며 출력하면 낮은 주소부터 차례로 나옵니다

> ⭐ **저장된 EBP들은 사슬처럼 연결되어 있습니다.** 각 프레임의 `[EBP]` 가 바로 위(호출한 쪽) 프레임의 EBP를 가리킵니다. 디버거가 "호출 스택(call stack)"을 보여 줄 수 있는 원리가 바로 이것입니다.
>
> 📝 교재 문제에는 `call ShowParams, paramCount` 로 되어 있는데, **CALL은 인자를 받을 수 없으므로 INVOKE로 써야** 합니다.
>
> ⚠️ ShowParams의 매개변수 이름을 `paramCount` 로 지으면 MySample의 상수 `paramCount = 3` 과 이름이 겹쳐 어셈블 오류가 날 수 있습니다. 그래서 `nParams` 로 바꿨습니다.

---

# 8장 시험 대비 요점

## 가장 많이 틀리는 7가지

| # | 함정 | 정답 |
|:---:|---|---|
| 1 | **매개변수 오프셋** | 첫 번째 매개변수는 **`[EBP+8]`**. `[EBP+4]` 는 **복귀 주소** |
| 2 | **인자 PUSH 순서** | **역순**. 마지막에 PUSH한 것이 첫 번째 인자 |
| 3 | **에필로그 순서** | `mov esp,ebp` → `pop ebp` → `ret`. **pop을 먼저 하면 망가짐** |
| 4 | **STDCALL vs C** | STDCALL은 **피호출자가 `ret n`**, C는 **호출자가 `add esp,n`** |
| 5 | **OFFSET vs LEA** | 지역 변수 주소는 **LEA만** 가능 (OFFSET은 어셈블 시간 상수) |
| 6 | **참조 매개변수** | 주소를 넘겨야 할 곳에 값을 넘기면 **GP 오류**. 어셈블러는 못 잡음 |
| 7 | **USES 위치** | `PROC USES eax ebx, param:DWORD` — **USES가 쉼표보다 앞**, 레지스터는 **공백 구분** |

## 스택 프레임 한 장 요약 ⭐⭐⭐

```
  [EBP+12]   두 번째 인자
  [EBP+8]    첫 번째 인자      ← 매개변수는 +
  [EBP+4]    복귀 주소
  [EBP]      이전 EBP
  [EBP-4]    첫 번째 지역 변수  ← 지역 변수는 −
  [EBP-8]    두 번째 지역 변수
```

## 프롤로그 / 에필로그

```asm
; 직접 쓰기                     ; ENTER / LEAVE
push ebp                        enter 8,0
mov  ebp,esp
sub  esp,8

; ... 본문 ...                  ; ... 본문 ...

mov  esp,ebp                    leave
pop  ebp
ret  12                         ret 12
```

## 지시어 문법 모음

```asm
MySub PROTO, a:DWORD, p:PTR BYTE            ; 원형

MySub PROC USES ebx esi,                    ; 정의
    a:DWORD,
    p:PTR BYTE
    LOCAL temp:DWORD,                       ; 지역 변수 (PROC 바로 다음)
          buf[20]:BYTE

    lea  esi,buf                            ; 지역 변수 주소는 LEA
    ...
    ret                                     ; MASM이 ret 8 로 변환
MySub ENDP

    INVOKE MySub, 10, ADDR msg              ; 호출
```

## 재귀의 세 요소

| 요소 | GCD 예시 |
|---|---|
| ① **기저 조건** (먼저 검사) | `cmp y,0` / `je done` |
| ② **재귀 호출** (문제를 작게) | `INVOKE GCD, y, edx` |
| ③ **결과 전달** | EAX에 담긴 채로 `ret` |

> 기저 조건이 없으면 **스택 오버플로**. 호출마다 새 프레임(인자 + 복귀 주소 + EBP)이 쌓이기 때문입니다.

## 출제 예상 (교수님 2/2/1~2 배분 기준)

| 섹션 | ★★★ 우선 | 이유 |
|---|---|---|
| **8.10.1 단답형** | **1, 2, 3, 4** | 에필로그·반환 레지스터·STDCALL 정리·LEA vs OFFSET. 한 줄로 답할 수 있음 |
| | **7, 8, 9** | 참/거짓. 8·9번은 한 쌍 |
| **8.10.2 알고리즘** | **1** | 스택 프레임 그림 — 8장의 핵심 그 자체 |
| | **3 ~ 7** | LOCAL 선언 한 줄씩. 다섯 문제가 같은 유형이라 가성비 최고 |
| | **2, 11** | PROC 매개변수 목록 / PROTO 선언 |
| **8.11 프로그래밍** | **5** | DifferentInputs — 8장에서 가장 짧음 |
| | **7** | 재귀 GCD — 짧고 8장 핵심 주제(재귀) |
| | **1, 8** | FindLargest, CountMatches — 짧고 PROTO/INVOKE 연습 |

> 중간고사 패턴(짧은 단답 + 프로그래밍 1개)을 그대로 적용하면, 8장에서는 **스택 프레임 그림 또는 오프셋 1문제 + LOCAL/PROTO 선언 1문제 + 짧은 프로시저 1개** 조합이 가장 유력합니다.
