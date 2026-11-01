# 7장 정수 산술 (Integer Arithmetic) — 연습문제 풀이

> Kip Irvine, *Assembly Language for x86 Processors* 7판, 7.9절~7.10절
> 문제는 한국어로 요약했습니다. 원문은 교재 281~285쪽을 함께 보세요.
>
> 구성: **7.9.1 단답형 10문제 + 7.9.2 알고리즘 연습 16문제 + 7.10 프로그래밍 과제 8문제**

---

## 들어가기 전에 — 7장 핵심 표 3개

이 세 표를 먼저 외우면 단답형이 거의 다 풀립니다.

### ① 시프트·회전 명령어

| 명령어 | 동작 | 밀려 들어오는 비트 |
|---|---|---|
| `SHL` / `SAL` | 왼쪽 시프트 (둘은 같은 명령) | **0** |
| `SHR` | 오른쪽 **논리** 시프트 | **0** |
| `SAR` | 오른쪽 **산술** 시프트 | **부호 비트 복제** |
| `ROL` | 왼쪽 회전 | 밀려 나간 MSB가 LSB로 |
| `ROR` | 오른쪽 회전 | 밀려 나간 LSB가 MSB로 |
| `RCL` | CF를 포함한 왼쪽 회전 | **CF** (9/17/33/65비트 회전) |
| `RCR` | CF를 포함한 오른쪽 회전 | **CF** |
| `SHLD` / `SHRD` | 2배 정밀도 시프트 | 원본 피연산자의 비트 |

> **밀려 나간 마지막 비트는 항상 CF로 들어갑니다.**

### ② 곱셈·나눗셈의 암묵적 피연산자 ⭐⭐⭐

| 크기 | **MUL / IMUL** (곱) | **DIV / IDIV** (몫, 나머지) |
|:---:|---|---|
| 8비트 | `AX = AL × src` | `AX ÷ src` → 몫 **AL**, 나머지 **AH** |
| 16비트 | `DX:AX = AX × src` | `DX:AX ÷ src` → 몫 **AX**, 나머지 **DX** |
| 32비트 | `EDX:EAX = EAX × src` | `EDX:EAX ÷ src` → 몫 **EAX**, 나머지 **EDX** |
| 64비트 | `RDX:RAX = RAX × src` | `RDX:RAX ÷ src` → 몫 **RAX**, 나머지 **RDX** |

> **나눗셈은 피제수가 결과의 두 배 크기**입니다. 상위 절반(AH/DX/EDX/RDX)을 반드시 먼저 채워야 합니다.

### ③ 부호 확장 명령어

| 명령어 | 확장 |
|---|---|
| `CBW` | AL → **AX** |
| `CWD` | AX → **DX:AX** |
| `CDQ` | EAX → **EDX:EAX** |
| `CQO` | RAX → **RDX:RAX** |

> **IDIV 앞에는 반드시 CBW/CWD/CDQ/CQO.** 빼먹으면 EDX의 쓰레기 값으로 나눗셈을 합니다. 7장에서 가장 자주 틀리는 지점입니다.

---

## 7.9.1 단답형 (Short Answer)

### 1. 각 시프트·회전 명령 실행 후 AL 값은?

```asm
mov al,0D4h
shr al,1        ; (a)
mov al,0D4h
sar al,1        ; (b)
mov al,0D4h
sar al,4        ; (c)
mov al,0D4h
rol al,1        ; (d)
```

**D4h = `1101 0100`** 입니다. 최상위 비트가 1이므로 부호 있는 값으로 보면 음수입니다.

| | 명령 | 결과 | 2진수 |
|:---:|---|:---:|---|
| **(a)** | `shr al,1` | **6Ah** | `0110 1010` |
| **(b)** | `sar al,1` | **EAh** | `1110 1010` |
| **(c)** | `sar al,4` | **FDh** | `1111 1101` |
| **(d)** | `rol al,1` | **A9h** | `1010 1001` |

**풀이**

```
(a) SHR — 왼쪽에 0이 들어온다
    1101 0100  →  0110 1010   (6Ah)
    ↑0 삽입

(b) SAR — 왼쪽에 부호 비트(1)가 들어온다
    1101 0100  →  1110 1010   (EAh)
    ↑1 복제

(c) SAR 4회 — 부호 비트 1이 네 번 들어온다
    1101 0100 → 1110 1010 → 1111 0101 → 1111 1010 → 1111 1101   (FDh)

(d) ROL — MSB가 LSB로 돌아온다
    1101 0100  →  1010 1001   (A9h),  CF = 1
    └──────────────────┘
```

> **SHR과 SAR의 차이가 (a)와 (b)에서 바로 드러납니다.** 논리 시프트는 0, 산술 시프트는 부호 비트를 채웁니다.

---

### 2. 각 시프트·회전 명령 실행 후 AL 값은?

```asm
mov al,0D4h
ror al,3        ; (a)
mov al,0D4h
rol al,7        ; (b)
stc
mov al,0D4h
rcl al,1        ; (c)
stc
mov al,0D4h
rcr al,3        ; (d)
```

| | 명령 | 결과 | 2진수 | CF |
|:---:|---|:---:|---|:---:|
| **(a)** | `ror al,3` | **9Ah** | `1001 1010` | 1 |
| **(b)** | `rol al,7` | **6Ah** | `0110 1010` | 0 |
| **(c)** | `stc` + `rcl al,1` | **A9h** | `1010 1001` | 1 |
| **(d)** | `stc` + `rcr al,3` | **3Ah** | `0011 1010` | 1 |

**풀이**

**(a) ROR 3** — 하위 3비트 `100` 이 상위로 이동
```
1101 0100  →  [100] 1101 01  →  1001 1010   (9Ah)
       └─┘      ↑ 앞으로
```

**(b) ROL 7** — 8비트에서 **왼쪽 7회 = 오른쪽 1회**
```
1101 0100  →(ROR 1)→  0110 1010   (6Ah)
```
> 💡 **회전 횟수가 크면 반대 방향으로 줄여 계산하세요.** `ROL n` = `ROR (8−n)`.

**(c) RCL 1 (CF=1)** — CF를 9번째 비트로 끼워 넣고 회전
```
   CF   AL
   [1] 1101 0100     ← 회전 전 (9비트)
    ↓   왼쪽으로 1칸
   [1] 1010 1001     ← CF였던 1이 LSB로 들어옴
        └ AL = A9h,  새 CF = 밀려 나간 MSB = 1
```

**(d) RCR 3 (CF=1)** — 9비트를 오른쪽으로 3번
```
시작:   CF=1, AL=1101 0100
1회전:  CF=0, AL=1110 1010
2회전:  CF=0, AL=0111 0101
3회전:  CF=1, AL=0011 1010   (3Ah)
```

> **RCL/RCR은 CF를 포함한 9비트(바이트 기준) 회전**입니다. 종이에 CF 칸을 하나 더 그려 놓고 풀면 틀리지 않습니다.

---

### 3. 실행 후 AX와 DX 값은?

```asm
mov dx,0
mov ax,222h
mov cx,100h
mul cx
```

**AX = 2200h, DX = 0002h**

**풀이** `mul cx` 는 **16비트 곱셈**이므로 `DX:AX = AX × CX` 입니다.

```
222h × 100h = 22200h   (20비트 결과)

        DX   :   AX
      0002h  :  2200h
```

> ⚠️ **`mov dx,0` 은 아무 의미가 없습니다.** MUL이 DX를 결과로 덮어쓰기 때문입니다. (DIV와 혼동하게 만들려고 넣은 함정입니다.)
>
> 결과의 상위 절반(DX)이 0이 아니므로 **CF = OF = 1** 입니다.

---

### 4. 실행 후 AX 값은?

```asm
mov ax,63h
mov bl,10h
div bl
```

**AX = 0306h** (AL = 06h = 몫, AH = 03h = 나머지)

**풀이** 피제수가 **8비트 레지스터(BL)** 이므로 `AX ÷ BL` 이고, 몫은 AL, 나머지는 AH입니다.

```
63h = 99 (10진),  10h = 16 (10진)
99 ÷ 16 = 6  나머지 3

AL = 6 = 06h  (몫)
AH = 3 = 03h  (나머지)
→ AX = 0306h
```

> ⚠️ **AH가 상위 바이트**이므로 `AX = 0306h` 입니다. `0603h` 이 아닙니다.

---

### 5. 실행 후 EAX와 EDX 값은?

```asm
mov eax,123400h
mov edx,0
mov ebx,10h
div ebx
```

**EAX = 00012340h, EDX = 00000000h**

**풀이** 피제수가 **32비트 레지스터(EBX)** 이므로 `EDX:EAX ÷ EBX` 입니다.

```
EDX:EAX = 00000000_00123400h
÷ 10h (= 16)

16으로 나누기 = 16진수 한 자리 오른쪽으로 밀기
123400h ÷ 10h = 12340h,  나머지 0

EAX = 00012340h  (몫)
EDX = 00000000h  (나머지)
```

> ✅ 여기서는 `mov edx,0` 이 **반드시 필요합니다.** DIV는 EDX를 피제수의 상위 절반으로 읽기 때문입니다. 3번과 정반대입니다.

---

### 6. 실행 후 AX와 DX 값은?

```asm
mov ax,4000h
mov dx,500h
mov bx,10h
div bx
```

**정답: 값이 나오지 않습니다. 나눗셈 오버플로(divide overflow) 예외가 발생해 프로그램이 중단됩니다.**

**풀이**

```
DX:AX = 0500_4000h = 83,902,464
÷ 10h (= 16)
= 5,243,904 = 500400h

몫 500400h 는 20비트인데, 몫이 들어갈 AX는 16비트 (최대 FFFFh)
→ 담을 수 없음 → divide overflow 예외
```

> ⭐ **빠른 판별법: 피제수의 상위 절반 ≥ 제수 이면 반드시 오버플로입니다.**
>
> 여기서는 `DX(500h) ≥ BX(10h)` 이므로 계산해 보지 않아도 오버플로입니다.
>
> | 나눗셈 | 상위 절반 | 제수 | 판정 |
> |---|---|---|---|
> | 5번 | EDX = 0 | 10h | 0 < 10h → **안전** |
> | 6번 | DX = 500h | 10h | 500h ≥ 10h → **오버플로** |
>
> 5번과 6번을 나란히 놓은 건 이 차이를 묻는 겁니다.

---

### 7. 실행 후 BX 값은?

```asm
mov bx,5
stc
mov ax,60h
adc bx,ax
```

**BX = 0066h**

**풀이** `ADC` 는 **자리올림까지 더합니다**: `BX = BX + AX + CF`

```
BX = 5 + 60h + 1
   = 5 + 96 + 1 = 102 = 66h
```

> `stc` 가 CF를 1로 세워 뒀기 때문에 **+1이 추가**됩니다. 이 1을 빠뜨리면 65h가 나옵니다.
>
> `mov ax,60h` 는 플래그를 바꾸지 않으므로 CF는 그대로 1입니다. (MOV는 플래그에 영향이 없습니다.)

---

### 8. 64비트 모드에서 다음 코드의 출력을 설명하시오

```asm
.data
dividend_hi QWORD 00000108h
dividend_lo QWORD 33300020h
divisor     QWORD 00000100h
.code
mov rdx,dividend_hi
mov rax,dividend_lo
div divisor
```

**정답: 나눗셈 오버플로 예외가 발생합니다. 출력은 없고 프로그램이 중단됩니다.**

**풀이**

```
RDX:RAX = 0000000000000108_0000000033300020h   (128비트 피제수)
÷ 100h (= 256)

몫 = 10800000000333000h   (65비트)
RAX 최대값 = FFFFFFFFFFFFFFFFh (64비트)
→ 담을 수 없음
```

6번과 같은 판별법을 쓰면 더 빠릅니다.

```
RDX = 108h,  divisor = 100h
108h ≥ 100h  →  오버플로 확정
```

> 💡 **6번과 8번은 같은 문제입니다.** 하나는 16비트, 하나는 64비트일 뿐입니다. **상위 절반 ≥ 제수** 한 줄만 기억하세요.

---

### 9. 아래 프로그램은 val1에서 val2를 빼려는 것이다. 논리 오류를 모두 찾아 고치시오

```asm
.data
val1   QWORD 20403004362047A1h
val2   QWORD 055210304A2630B2h
result QWORD 0
.code
    mov cx,8                    ; 루프 카운터
    mov esi,val1                ; 시작 인덱스 설정
    mov edi,val2
    clc                         ; Carry 플래그 지우기
top:
    mov al,BYTE PTR [esi]       ; 첫 번째 수 가져오기
    sbb al,BYTE PTR [edi]       ; 두 번째 수 빼기
    mov BYTE PTR [esi],al       ; 결과 저장
    dec esi
    dec edi
    loop top
```

**오류 4개**

| # | 잘못된 줄 | 문제 | 수정 |
|:---:|---|---|---|
| **①** | `mov cx,8` | 32비트 모드의 **LOOP는 ECX**를 사용합니다. CX만 설정하면 ECX 상위 16비트의 쓰레기 값 때문에 반복 횟수가 엉망이 됩니다 | `mov ecx,8` |
| **②** | `mov esi,val1` | **주소가 아니라 값**을 넣고 있습니다. 게다가 val1은 QWORD(64비트)라서 32비트 ESI에 들어가지도 않습니다 (어셈블 오류) | `mov esi,OFFSET val1` |
| **③** | `dec esi` / `dec edi` | **방향이 반대**입니다. 리틀엔디언이라 **최하위 바이트가 가장 낮은 주소**에 있으므로, 뺄셈은 낮은 주소에서 **위로** 올라가야 합니다 | `inc esi` / `inc edi` |
| **④** | `mov BYTE PTR [esi],al` | 결과를 **val1에 덮어쓰고** 있습니다. `result` 변수가 선언만 되고 쓰이지 않습니다 | result용 포인터를 따로 두기 |

**수정된 프로그램**

```asm
.data
val1   QWORD 20403004362047A1h
val2   QWORD 055210304A2630B2h
result QWORD 0

.code
    mov ecx,8                   ; ① CX → ECX
    mov esi,OFFSET val1         ; ② 값이 아니라 주소
    mov edi,OFFSET val2
    mov ebx,OFFSET result       ; ④ 결과 저장용 포인터
    clc                         ; 자리빌림 초기화
top:
    mov al,BYTE PTR [esi]
    sbb al,BYTE PTR [edi]       ; 자리빌림 포함 뺄셈
    mov BYTE PTR [ebx],al       ; ④ result에 저장
    inc esi                     ; ③ dec → inc
    inc edi
    inc ebx
    loop top
```

**검산**

```
20403004362047A1h
- 055210304A2630B2h
───────────────────
  1AEE1FD3EBFA16EFh
```

**원래 코드에서 "맞게" 되어 있던 부분도 알아 두세요** — 이게 출제 포인트입니다.

- ✅ 루프 **앞에** `clc` — 첫 바이트는 자리빌림 없이 시작해야 합니다
- ✅ `sub`가 아니라 **`sbb`** — 두 번째 바이트부터는 자리빌림을 받아야 합니다
- ✅ 포인터 이동에 `add esi,1` 이 아니라 **`inc esi`** — **INC와 DEC는 CF를 바꾸지 않습니다.** ADD/SUB를 쓰면 애써 만든 자리빌림이 날아갑니다
- ✅ **`loop` 도 플래그를 바꾸지 않습니다** — 그래서 반복 사이에 CF가 살아남습니다

> ⭐ **확장 산술의 철칙: 루프 안에서 CF를 건드리는 명령을 쓰지 말 것.** 안전한 것은 `INC`, `DEC`, `LEA`, `MOV`, `LOOP` 입니다.

---

### 10. 64비트 모드에서 실행 후 RAX의 16진 값은?

```asm
.data
multiplicand QWORD 0001020304050000h
.code
imul rax,multiplicand,4
```

**RAX = 0004080C10140000h**

**풀이** **3-피연산자 IMUL** 입니다: `대상 = 원본 × 즉시값`

```
0001020304050000h × 4
```

4를 곱하는 건 **왼쪽으로 2비트 시프트**와 같습니다. 각 자리에 올림이 생기지 않으므로 니블 단위로 계산해도 됩니다.

| 원본 | 00 | 01 | 02 | 03 | 04 | 05 | 00 | 00 |
|---|---|---|---|---|---|---|---|---|
| **×4** | 00 | **04** | **08** | **0C** | **10** | **14** | 00 | 00 |

**RAX = 0004080C10140000h**

> **IMUL의 세 가지 형태를 구분하세요.**
>
> | 형태 | 예 | 의미 |
> |---|---|---|
> | 1-피연산자 | `imul ebx` | `EDX:EAX = EAX × EBX` (MUL과 같은 구조) |
> | 2-피연산자 | `imul eax,ebx` | `EAX = EAX × EBX` (결과가 32비트로 잘림) |
> | **3-피연산자** | `imul rax,mem,4` | `RAX = mem × 4` |
>
> 2·3-피연산자 형태는 **결과가 대상 크기를 넘으면 CF = OF = 1** 로 알려 줍니다. MUL에는 이 형태가 없습니다.

---

## 7.9.2 알고리즘 연습 (Algorithm Workbench)

### 1. AX를 EAX로 부호 확장하는 시프트 명령들 (CWD 사용 금지)

```asm
shl eax,16          ; AX를 상위 16비트 자리로 올린다
sar eax,16          ; 부호 비트를 복제하면서 되돌린다
```

**원리**

```
EAX = ????????  1101 0100 0000 0001    (상위 16비트는 쓰레기)
         ↓ shl eax,16
EAX = 1101 0100 0000 0001  0000 0000 0000 0000
      ↑ AX의 부호 비트가 EAX의 bit 31로 올라감
         ↓ sar eax,16  (부호 비트 복제)
EAX = 1111 1111 1111 1111  1101 0100 0000 0001
      └── 부호 확장 완료 ──┘
```

> **SHL로 부호 비트를 맨 위로 올리고, SAR로 그 비트를 복제하며 되돌린다** — 이게 핵심 아이디어입니다.
> 참고로 교재의 정식 방법은 `cwde` (AX → EAX) 입니다. 이 문제는 그걸 쓰지 말라는 거죠.

---

### 2. 회전 명령 없이 SHR과 조건 점프로 AL을 오른쪽 1비트 회전

```asm
    shr al,1                ; 최하위 비트가 CF로 밀려 나감
    jnc next                ; CF = 0 이면 채울 것이 없음
    or  al,10000000b        ; CF = 1 이면 최상위 비트를 세움
next:
```

**원리** ROR이 하는 일은 "밀려 나간 LSB를 MSB 자리에 다시 넣는 것"입니다. SHR이 그 비트를 CF에 남겨 주므로, CF를 보고 MSB를 직접 세우면 됩니다.

```
1101 0101
   ↓ shr al,1
0110 1010,  CF = 1
   ↓ CF가 1이므로 or al,80h
1110 1010   ← ROR 1 의 결과와 동일
```

---

### 3. EAX를 16배 하는 논리 시프트 명령

```asm
shl eax,4               ; 2^4 = 16
```

> **왼쪽으로 n비트 = ×2ⁿ**

---

### 4. EBX를 4로 나누는 논리 시프트 명령

```asm
shr ebx,2               ; 2^2 = 4
```

> **오른쪽으로 n비트 = ÷2ⁿ**
>
> ⚠️ 문제가 "**logical** shift"라고 했으므로 `SHR` 입니다. **부호 있는** 값이면 `SAR`를 써야 합니다.
>
> 그리고 SAR는 IDIV와 결과가 다를 수 있습니다. SAR는 **음의 무한대 방향**으로, IDIV는 **0 방향**으로 버립니다.
>
> | | −5 ÷ 2 |
> |---|---|
> | `sar eax,1` | **−3** |
> | `idiv` | **−2** |

---

### 5. DL의 상위 절반과 하위 절반을 교환하는 회전 명령 하나

```asm
rol dl,4                ; ror dl,4 도 같은 결과
```

**원리** DL은 8비트이고 절반은 4비트입니다. 8비트를 4칸 회전하면 상·하위가 맞바뀝니다.

```
1010 0011  →(rol dl,4)→  0011 1010
└──┘ └──┘                └──┘ └──┘
 상    하                   하    상
```

> 8비트에서 **ROL 4 = ROR 4** 입니다. 절반이니까요.

---

### 6. AX의 최상위 비트를 DX의 최하위 비트로 밀어 넣으면서 DX를 왼쪽 1비트 시프트하는 SHLD 명령 하나

```asm
shld dx,ax,1
```

**원리** `SHLD 대상, 원본, 횟수` 는 **대상을 왼쪽으로 시프트하고, 비어 버린 하위 비트를 원본의 상위 비트로 채웁니다.** 원본 자체는 변하지 않습니다.

```
DX = 1011 0010 0110 1001
AX = 1... (최상위 비트가 1)

   ↓ shld dx,ax,1

DX = 0110 0100 1101 0011
                       ↑ AX의 bit 15가 들어옴
```

> `SHRD` 는 반대 방향입니다. 대상을 오른쪽으로 밀고 **원본의 하위 비트**로 상위를 채웁니다.

---

### 7. 메모리의 바이트 3개를 오른쪽으로 1비트 시프트

```asm
.data
byteArray BYTE 81h,20h,33h
```

```asm
    shr byteArray+2,1           ; 최상위 바이트부터 — 밀려난 비트가 CF로
    rcr byteArray+1,1           ; CF를 받아 들이면서 시프트
    rcr byteArray,1             ; 마지막 바이트
```

**원리** 여러 바이트를 하나의 큰 수처럼 시프트하려면, **밀려 나간 비트를 옆 바이트로 전달**해야 합니다. 그 전달 통로가 CF이고, 받아 주는 명령이 RCR입니다.

```
오른쪽 시프트 → 높은 주소(최상위)부터 시작

[+2] 0011 0011 ──shr──→ 0001 1001,  CF=1
                                      ↓
[+1] 0010 0000 ──rcr──→ 1001 0000,  CF=0
                                      ↓
[+0] 1000 0001 ──rcr──→ 0100 0000,  CF=1
```

**결과** 메모리(낮은 주소부터) = **`40 90 19`**

> ⭐ **방향 규칙 (7·8번의 핵심)**
>
> | 시프트 방향 | 시작 위치 | 첫 명령 | 이후 명령 |
> |---|---|---|---|
> | **오른쪽** | **최상위**(높은 주소) | `SHR` | `RCR` |
> | **왼쪽** | **최하위**(낮은 주소) | `SHL` | `RCL` |
>
> 외우는 법: **비트가 가는 방향의 반대쪽에서 시작합니다.**

---

### 8. 메모리의 워드 3개를 왼쪽으로 1비트 시프트

```asm
.data
wordArray WORD 810Dh, 0C064h, 93ABh
```

```asm
    shl wordArray,1             ; 최하위 워드부터 — 밀려난 비트가 CF로
    rcl wordArray+2,1           ; WORD는 2바이트이므로 +2
    rcl wordArray+4,1
```

**원리** 7번과 **반대 방향**입니다. 왼쪽 시프트이므로 **최하위 워드(낮은 주소)부터** 시작합니다.

```
[+0] 810Dh = 1000 0001 0000 1101 ──shl──→ 0000 0010 0001 1010,  CF=1
                                                                  ↓
[+2] C064h = 1100 0000 0110 0100 ──rcl──→ 1000 0000 1100 1001,  CF=1
                                                                  ↓
[+4] 93ABh = 1001 0011 1010 1011 ──rcl──→ 0010 0111 0101 0111,  CF=1
```

**결과** (낮은 주소부터) **`021Ah`, `80C9h`, `2757h`**, 최종 CF = 1

> ⚠️ **오프셋이 +1이 아니라 +2씩**입니다. WORD는 2바이트니까요. 7번(BYTE, +1씩)과 비교해서 보세요.

---

### 9. 5 × 3을 계산해 16비트 변수 val1에 저장

```asm
.data
val1 WORD ?

.code
    mov al,5
    mov bl,3
    mul bl                      ; AX = AL × BL = 15
    mov val1,ax
```

> **8비트 MUL의 결과는 AX(16비트)** 로 나옵니다. 그래서 val1이 WORD인 것이 자연스럽습니다.

---

### 10. 276 ÷ 10을 계산해 16비트 변수 val1에 저장

```asm
.data
val1 WORD ?

.code
    mov dx,0                    ; ⚠️ 상위 절반을 반드시 0으로
    mov ax,276
    mov bx,10
    div bx                      ; AX = 27 (몫), DX = 6 (나머지)
    mov val1,ax
```

**검산** 276 ÷ 10 = 27 나머지 6

> ⚠️ **276은 8비트(최대 255)에 들어가지 않으므로** 16비트 나눗셈을 써야 합니다. 그러면 피제수는 `DX:AX` 이고, **`mov dx,0` 을 빠뜨리면** DX의 쓰레기 값 때문에 엉뚱한 결과나 오버플로가 납니다.

---

### 11. C++ 식을 어셈블리로 — 32비트 **부호 없는** 피연산자

```
val1 = (val2 * val3) / (val4 - 3)
```

```asm
    mov eax,val2
    mul val3                    ; EDX:EAX = val2 × val3
    mov ebx,val4
    sub ebx,3                   ; EBX = val4 - 3
    div ebx                     ; EAX = 몫
    mov val1,eax
```

> ⭐ **이 문제의 묘미: MUL의 결과가 `EDX:EAX`이고 DIV의 피제수도 `EDX:EAX`라서 그대로 이어집니다.** EDX를 손댈 필요가 전혀 없습니다. 오히려 `mov edx,0` 을 넣으면 **곱셈의 상위 절반을 날려서 틀립니다.**
>
> 부호 **없는** 연산이므로 `MUL`/`DIV` 입니다.

---

### 12. C++ 식을 어셈블리로 — 32비트 **부호 있는** 피연산자

```
val1 = (val2 / val3) * (val1 + val2)
```

```asm
    mov eax,val2
    cdq                         ; ⭐ EDX:EAX로 부호 확장 (필수!)
    idiv val3                   ; EAX = val2 / val3

    mov ebx,val1
    add ebx,val2                ; EBX = val1 + val2

    imul ebx                    ; EDX:EAX = EAX × EBX
    mov val1,eax
```

> ⭐ **`cdq` 가 이 문제의 전부입니다.** 부호 있는 나눗셈 앞에는 반드시 부호 확장이 와야 합니다.
>
> `mov edx,0` 을 쓰면 **양수일 때만 맞고 음수일 때 완전히 틀립니다.** val2가 −10이면 EDX는 0이 아니라 FFFFFFFFh여야 하니까요.
>
> **11번은 `MUL`/`DIV` + EDX 건드리지 않기, 12번은 `IMUL`/`IDIV` + `CDQ`.** 두 문제를 나란히 놓은 건 이 대비를 보여 주려는 겁니다.

---

### 13. 부호 없는 8비트 값(AL, 0~99)을 10진수로 출력하는 프로시저

조건: **WriteChar만** 호출 가능, 명령어 **8개 정도**

```asm
;---------------------------------------------------
; showDecimal8
;   AL의 부호 없는 8비트 값(0~99)을 10진수로 출력한다.
;   Receives: AL = 출력할 값
;   Returns:  없음
;---------------------------------------------------
showDecimal8 PROC
    mov ah,0                    ; AX = AL (0~99)
    mov dl,10
    div dl                      ; AL = 십의 자리, AH = 일의 자리
    add ax,3030h                ; ⭐ 두 자리를 한 번에 ASCII로
    push ax                     ; 일의 자리(AH) 보존
    call WriteChar              ; AL = 십의 자리 출력
    pop ax
    mov al,ah                   ; 일의 자리를 AL로
    call WriteChar              ; 출력
    ret
showDecimal8 ENDP
```

**호출 예**

```asm
    mov al,65
    call showDecimal8           ; "65" 출력
```

**동작 추적** (AL = 65)

| 단계 | AX | 설명 |
|---|---|---|
| `mov ah,0` | `0041h` | AX = 65 |
| `div dl` | `0506h` | 65 ÷ 10 = 6 나머지 5 → AL=6, AH=5 |
| `add ax,3030h` | `3536h` | AL=36h('6'), AH=35h('5') |
| 1차 `WriteChar` | | AL = '6' 출력 |
| `mov al,ah` | | AL = '5' |
| 2차 `WriteChar` | | '5' 출력 |

> ⭐ **`add ax,3030h` 한 줄로 두 자리를 동시에 ASCII로 바꾸는 게 핵심 기교입니다.** AH와 AL을 따로 `add al,30h` / `add ah,30h` 하면 명령어가 하나 더 듭니다.
>
> ⚠️ **출력 순서 주의**: DIV의 몫(AL)이 **십의 자리**, 나머지(AH)가 **일의 자리**입니다. 십의 자리를 먼저 출력해야 합니다.

---

### 14. (도전) AX = 0072h이고 AF가 세트된 상태에서 AAA를 실행하면?

**정답: AX = 0108h, CF = 1, AF = 1**

**풀이** AAA(ASCII Adjust After Addition)의 동작은 이렇습니다.

```
IF ((AL AND 0Fh) > 9) OR (AF = 1) THEN
    AX ← AX + 106h
    AF ← 1
    CF ← 1
ELSE
    AF ← 0
    CF ← 0
END IF
AL ← AL AND 0Fh
```

적용해 보면

```
AX = 0072h  →  AL = 72h, AH = 00h

조건 검사: (72h AND 0Fh) = 2,  2 > 9? 아니오
           AF = 1?  예  →  조정 분기 실행

AX = 0072h + 0106h = 0178h
CF = 1, AF = 1

AL = 78h AND 0Fh = 08h

→ AX = 0108h
```

**해석** AH = 01h는 **자리올림 자리**, AL = 08h는 **일의 자리**입니다. 즉 결과는 10진수 **18**을 두 자리로 나눠 담은 것입니다.

> **조건에 `OR (AF = 1)` 이 있다는 점이 이 문제의 전부입니다.** 하위 니블이 2라서 9 이하인데도, **AF가 1이면 무조건 조정**이 일어납니다. 두 ASCII 숫자를 더했을 때 니블 자리에서 올림이 생겼다는 뜻이니까요.
>
> ⚠️ **AAA, AAS, AAM, AAD, DAA, DAS는 64비트 모드에서 사용할 수 없습니다.**

---

### 15. (도전) SUB, MOV, AND만 써서 `x = n mod y` 계산 (y는 2의 거듭제곱)

```asm
    mov eax,n
    mov ebx,y
    sub ebx,1                   ; EBX = y - 1  (마스크)
    and eax,ebx                 ; x = n AND (y-1)
    mov x,eax
```

**원리** y = 2ᵏ 이면 **`n mod y = n AND (y − 1)`** 입니다.

```
y = 8 = 1000b  →  y-1 = 7 = 0111b  (하위 3비트 마스크)

n = 29 = 11101b
       AND 00111b
       = 00101b = 5

검산: 29 mod 8 = 5  ✔
```

**왜 되는가** 2ᵏ으로 나눈 나머지는 **하위 k비트**가 그대로입니다. `y−1`은 하위 k비트가 전부 1인 마스크이므로, AND 하면 하위 k비트만 남습니다.

> 나눗셈 명령 없이 나머지를 구하는 기법이라 실제 코드에서도 많이 쓰입니다. **단, y가 2의 거듭제곱일 때만** 성립합니다.

---

### 16. (도전) SAR, ADD, XOR만 써서 EAX의 절댓값 계산 (조건 점프 금지)

```asm
    mov edx,eax
    sar edx,31                  ; 마스크 생성: 음수면 FFFFFFFFh, 양수면 00000000h
    add eax,edx                 ; 음수면 -1 (= +FFFFFFFFh), 양수면 +0
    xor eax,edx                 ; 음수면 비트 반전, 양수면 그대로
```

**원리** `~(n − 1) = −n` 이라는 항등식을 씁니다.

**`sar edx,31`** 이 핵심입니다. 부호 비트를 32칸 밀어 복제하므로

| EAX | EDX (마스크) |
|---|---|
| 양수 또는 0 | `00000000h` (전부 0) |
| 음수 | `FFFFFFFFh` (전부 1) |

이 마스크를 쓰면 **분기 없이** 두 경우를 동시에 처리합니다.

| | 양수일 때 | 음수일 때 |
|---|---|---|
| `add eax,edx` | +0 (변화 없음) | −1 (`+FFFFFFFFh`) |
| `xor eax,edx` | ^0 (변화 없음) | 비트 전부 반전 |
| **결과** | **그대로** | **−n** |

**검산** EAX = −5

```
EAX = FFFFFFFBh (-5)
EDX = sar(-5, 31) = FFFFFFFFh

add eax,edx : FFFFFFFBh + FFFFFFFFh = FFFFFFFAh  (-6)
xor eax,edx : FFFFFFFAh XOR FFFFFFFFh = 00000005h  = 5  ✔
```

EAX = 5

```
EDX = 00000000h
add eax,edx : 5 + 0 = 5
xor eax,edx : 5 XOR 0 = 5  ✔
```

> 분기가 없으므로 CPU의 분기 예측 실패가 없습니다. 실무에서 쓰이는 **branchless(분기 없는) 기법**의 대표 예입니다.
> (MOV는 마스크를 담을 레지스터를 준비하는 데만 썼습니다.)

---

## 7.10 프로그래밍 과제 (Programming Exercises)

> 손으로 쓰는 시험이라면 난이도 **★** 인 1·2번이 가장 유력합니다.

### 1. WriteScaled — 소수점이 암시된 ASCII 10진수 출력 ★

**문제 요약** 숫자 문자열에 소수점을 끼워 넣어 출력하는 `WriteScaled` 프로시저를 작성하시오. `DECIMAL_OFFSET`은 오른쪽에서 몇 번째에 소수점을 넣을지를 나타낸다. EDX에 숫자의 오프셋, ECX에 길이, EBX에 소수점 위치를 전달한다.

```
decimal_one BYTE "100123456789765"   (DECIMAL_OFFSET = 5)
→ 출력:  1001234567.89765
```

```asm
; WriteScaled.asm

INCLUDE Irvine32.inc

DECIMAL_OFFSET = 5

.data
decimal_one   BYTE "100123456789765"
decimal_two   BYTE "876543210"
decimal_three BYTE "4000000"

.code
main PROC
    mov edx,OFFSET decimal_one
    mov ecx,LENGTHOF decimal_one
    mov ebx,DECIMAL_OFFSET
    call WriteScaled
    call Crlf

    mov edx,OFFSET decimal_two
    mov ecx,LENGTHOF decimal_two
    mov ebx,3
    call WriteScaled
    call Crlf

    mov edx,OFFSET decimal_three
    mov ecx,LENGTHOF decimal_three
    mov ebx,2
    call WriteScaled
    call Crlf

    exit
main ENDP

;---------------------------------------------------
; WriteScaled
;   소수점이 암시된 ASCII 10진수를 출력한다.
;   Receives: EDX = 숫자 문자열의 오프셋
;             ECX = 숫자의 자릿수
;             EBX = 오른쪽에서 소수점까지의 자리 수
;   Returns:  없음
;---------------------------------------------------
WriteScaled PROC USES eax ebx ecx edx esi edi
    mov esi,edx                 ; 문자열 포인터
    mov edi,ecx
    sub edi,ebx                 ; EDI = 소수점 앞에 올 자릿수

L1:
    cmp edi,0
    jnz noPoint                 ; 아직 0이 아니면 소수점 없음
    mov al,'.'
    call WriteChar              ; 여기서 소수점 출력
noPoint:
    mov al,[esi]
    call WriteChar              ; 숫자 한 자리 출력
    inc esi
    dec edi                     ; 0을 지나 음수가 되므로 다시 찍히지 않음
    loop L1

    ret
WriteScaled ENDP
END main
```

**동작 추적** (`decimal_one`, 길이 15, 소수점 오프셋 5)

| | EDI | 출력 |
|---|:---:|---|
| 시작 | 15 − 5 = 10 | |
| 1~10번째 | 10 → 0 | `1001234567` |
| **11번째** | **0** | **`.`** 먼저, 그다음 `8` |
| 12~15번째 | 음수 | `9765` |

**결과** `1001234567.89765` ✔

**채점 포인트**
- EDI가 0이 되는 **순간에만** 소수점을 찍고, 이후 음수로 내려가므로 두 번 찍히지 않습니다
- 소수점을 찍은 **뒤에도 그 자리의 숫자를 출력**해야 합니다 (`jnz` 로 건너뛰는 건 소수점뿐)
- `LENGTHOF` 로 문자열 길이를 얻습니다 (널 종료자가 없으므로 문자 수 그대로)

---

### 2. Extended_Sub — 임의 크기의 확장 뺄셈 ★

**문제 요약** 크기가 같고 32비트의 배수인 두 2진 정수를 빼는 `Extended_Sub` 프로시저를 작성하시오. 최소 10바이트 이상의 정수 쌍을 여러 개 넘기는 테스트 프로그램도 작성한다.

```asm
; ExtendedSub.asm

INCLUDE Irvine32.inc

.data
; 각 수는 더블워드 3개 = 12바이트 (리틀엔디언: 낮은 주소가 최하위)
num1   DWORD 0FFFFFFFFh, 00000002h, 00000001h
num2   DWORD 00000001h,  00000001h, 00000000h
diff   DWORD 3 DUP(?)

msg    BYTE "Difference: ",0

.code
main PROC
    mov esi,OFFSET num1
    mov edi,OFFSET num2
    mov ebx,OFFSET diff
    mov ecx,LENGTHOF num1       ; 더블워드 개수 = 3
    call Extended_Sub

    mov edx,OFFSET msg
    call WriteString
    call ShowResult
    call Crlf

    exit
main ENDP

;---------------------------------------------------
; Extended_Sub
;   임의 크기의 두 2진 정수를 뺀다 (크기는 32비트의 배수).
;   Receives: ESI = 피감수 포인터 (빼어지는 수)
;             EDI = 감수 포인터   (빼는 수)
;             EBX = 결과 포인터
;             ECX = 더블워드 개수
;   Returns:  없음
;---------------------------------------------------
Extended_Sub PROC USES eax ebx ecx esi edi
    clc                         ; 자리빌림 초기화
L1:
    mov eax,[esi]
    sbb eax,[edi]               ; 자리빌림 포함 뺄셈
    mov [ebx],eax

    lea esi,[esi+4]             ; ⭐ LEA는 플래그를 바꾸지 않는다
    lea edi,[edi+4]
    lea ebx,[ebx+4]
    loop L1                     ; LOOP도 플래그를 바꾸지 않는다

    ret
Extended_Sub ENDP

;---------------------------------------------------
; ShowResult — diff를 최상위 더블워드부터 16진수로 출력
;---------------------------------------------------
ShowResult PROC USES eax ecx esi
    mov ecx,LENGTHOF diff
    mov esi,OFFSET diff + SIZEOF diff - 4   ; 마지막 더블워드부터
L1:
    mov eax,[esi]
    call WriteHex
    sub esi,4
    loop L1
    ret
ShowResult ENDP
END main
```

**채점 포인트 ⭐**
- **포인터 이동에 `add esi,4` 를 쓰면 안 됩니다.** ADD가 CF를 덮어써서 자리빌림이 날아갑니다
- **`lea esi,[esi+4]` 는 플래그를 전혀 바꾸지 않습니다.** 4바이트씩 이동해야 하므로 `inc` 를 네 번 쓸 수도 있지만 LEA가 깔끔합니다
- 낮은 주소(최하위)에서 **위로** 진행합니다
- 루프 **앞에** `clc`, 루프 **안에는** `sbb`

> 9번 단답형 문제와 같은 원리입니다. 그쪽은 바이트 단위, 이쪽은 더블워드 단위일 뿐입니다.

---

### 3. PackedToAsc — packed decimal을 ASCII 문자열로 변환 ★★

**문제 요약** 4바이트 packed decimal 정수를 ASCII 10진 숫자 문자열로 바꾸는 `PackedToAsc` 프로시저를 작성하시오. packed 정수와 ASCII 버퍼의 주소를 전달한다.

> **packed decimal**: 한 바이트에 10진 숫자 **두 개**를 니블 단위로 담는 형식. 4바이트면 **8자리**입니다.
> 예) `12345678h` 는 10진수 12,345,678을 나타냅니다.

```asm
; PackedToAsc.asm

INCLUDE Irvine32.inc

.data
packed1 DWORD 12345678h
packed2 DWORD 00009999h
packed3 DWORD 87654321h
packed4 DWORD 00000001h
packed5 DWORD 50607080h

buffer  BYTE 9 DUP(0)           ; 8자리 + 널 종료자

.code
main PROC
    mov eax,packed1
    mov edi,OFFSET buffer
    call PackedToAsc
    mov edx,OFFSET buffer
    call WriteString
    call Crlf

    mov eax,packed2
    mov edi,OFFSET buffer
    call PackedToAsc
    mov edx,OFFSET buffer
    call WriteString
    call Crlf

    mov eax,packed3
    mov edi,OFFSET buffer
    call PackedToAsc
    mov edx,OFFSET buffer
    call WriteString
    call Crlf

    mov eax,packed4
    mov edi,OFFSET buffer
    call PackedToAsc
    mov edx,OFFSET buffer
    call WriteString
    call Crlf

    mov eax,packed5
    mov edi,OFFSET buffer
    call PackedToAsc
    mov edx,OFFSET buffer
    call WriteString
    call Crlf

    exit
main ENDP

;---------------------------------------------------
; PackedToAsc
;   4바이트 packed decimal 정수를 ASCII 숫자 문자열로 바꾼다.
;   Receives: EAX = packed decimal 값
;             EDI = 결과 버퍼 주소 (최소 9바이트)
;   Returns:  버퍼에 널 종료 ASCII 문자열
;---------------------------------------------------
PackedToAsc PROC USES eax ebx ecx edi
    mov ebx,eax                 ; 값을 EBX에 보관
    add edi,8                   ; ⭐ 버퍼 끝에서부터 거꾸로 채운다
    mov BYTE PTR [edi],0        ; 널 종료자
    mov ecx,4                   ; 바이트 4개

L1:
    mov al,bl                   ; 최하위 바이트

    ; --- 하위 니블 (오른쪽 자리) ---
    mov ah,al                   ; 원본 보관
    and al,0Fh
    or  al,30h                  ; ASCII로
    dec edi
    mov [edi],al

    ; --- 상위 니블 (왼쪽 자리) ---
    mov al,ah
    shr al,4
    or  al,30h
    dec edi
    mov [edi],al

    shr ebx,8                   ; 다음 바이트로
    loop L1

    ret
PackedToAsc ENDP
END main
```

**동작 추적** (EAX = `12345678h`)

| 반복 | BL | 하위 니블 | 상위 니블 | 버퍼 |
|:---:|---|---|---|---|
| 1 | 78h | 8 → `'8'` | 7 → `'7'` | `......78` |
| 2 | 56h | 6 → `'6'` | 5 → `'5'` | `....5678` |
| 3 | 34h | 4 → `'4'` | 3 → `'3'` | `..345678` |
| 4 | 12h | 2 → `'2'` | 1 → `'1'` | `12345678` |

**출력** `12345678`

**채점 포인트**
- **버퍼를 뒤에서 앞으로 채웁니다.** 최하위 바이트가 가장 오른쪽 자리이기 때문입니다
- 한 바이트에서 **하위 니블을 먼저, 상위 니블을 나중에** 꺼냅니다 (오른쪽 자리가 먼저니까요)
- `and al,0Fh` 로 하위 니블, `shr al,4` 로 상위 니블
- `or al,30h` 로 ASCII 변환 (0~9 → 30h~39h)

---

### 4. 회전 연산을 이용한 암호화 ★★

**문제 요약** 평문의 각 바이트를 키 값만큼 회전시켜 암호화하는 프로시저를 작성하시오. 키가 **음수면 왼쪽**, **양수면 오른쪽**으로 회전하고, 값의 크기가 회전 횟수다. 키를 메시지의 처음 10바이트에 맞추고, 다음 10바이트에 다시 맞추는 식으로 반복한다.

```asm
key BYTE -2, 4, 1, 0, -3, 5, 2, -4, -4, 6
```

```asm
; RotateCipher.asm

INCLUDE Irvine32.inc

.data
key      BYTE -2, 4, 1, 0, -3, 5, 2, -4, -4, 6
message  BYTE "Attack at dawn, bring reinforcements!",0
msgLen   = ($ - message) - 1            ; 널 종료자 제외

msg1     BYTE "Plain text:  ",0
msg2     BYTE "Encrypted:   ",0
msg3     BYTE "Decrypted:   ",0

.code
main PROC
    mov edx,OFFSET msg1
    call WriteString
    mov edx,OFFSET message
    call WriteString
    call Crlf

    ; --- 암호화 ---
    mov esi,OFFSET message
    mov ecx,msgLen
    call Encrypt
    mov edx,OFFSET msg2
    call WriteString
    mov edx,OFFSET message
    call WriteString
    call Crlf

    ; --- 복호화 (반대 방향으로 회전) ---
    mov esi,OFFSET message
    mov ecx,msgLen
    call Decrypt
    mov edx,OFFSET msg3
    call WriteString
    mov edx,OFFSET message
    call WriteString
    call Crlf

    exit
main ENDP

;---------------------------------------------------
; Encrypt
;   각 평문 바이트를 키 값만큼 회전시킨다.
;   키가 음수면 왼쪽(ROL), 양수면 오른쪽(ROR).
;   Receives: ESI = 메시지 주소, ECX = 메시지 길이
;   Returns:  메시지가 제자리에서 암호화됨
;---------------------------------------------------
Encrypt PROC USES eax ebx ecx edx esi
    mov ebx,0                   ; 키 인덱스
L1:
    push ecx                    ; ⭐ CL을 회전 횟수로 쓸 것이므로 보존
    mov al,[esi]                ; 평문 바이트
    mov cl,key[ebx]             ; 키 값

    cmp cl,0
    jl  rotLeft
    ror al,cl                   ; 양수 → 오른쪽
    jmp store
rotLeft:
    neg cl                      ; 절댓값으로
    rol al,cl                   ; 음수 → 왼쪽
store:
    mov [esi],al
    pop ecx

    inc esi
    inc ebx
    cmp ebx,LENGTHOF key
    jb  nextByte
    mov ebx,0                   ; ⭐ 키를 처음으로 되감기
nextByte:
    loop L1
    ret
Encrypt ENDP

;---------------------------------------------------
; Decrypt — 방향만 반대로
;   Receives: ESI = 메시지 주소, ECX = 메시지 길이
;---------------------------------------------------
Decrypt PROC USES eax ebx ecx edx esi
    mov ebx,0
L1:
    push ecx
    mov al,[esi]
    mov cl,key[ebx]

    cmp cl,0
    jl  rotRight                ; 암호화와 반대
    rol al,cl
    jmp store
rotRight:
    neg cl
    ror al,cl
store:
    mov [esi],al
    pop ecx

    inc esi
    inc ebx
    cmp ebx,LENGTHOF key
    jb  nextByte
    mov ebx,0
nextByte:
    loop L1
    ret
Decrypt ENDP
END main
```

**채점 포인트 ⭐**
- **회전 횟수는 반드시 CL에 넣어야 합니다.** `rol al,cl` 이 유일한 가변 횟수 형태입니다
- 그런데 ECX는 루프 카운터이기도 하므로 **`push ecx` / `pop ecx` 로 보호**해야 합니다. 이게 빠지면 동작하지 않습니다
- 키 인덱스가 키 길이에 도달하면 **0으로 되감아** 10바이트마다 키를 다시 맞춥니다
- **복호화는 방향만 반대**입니다. 회전은 가역 연산이라 되돌릴 수 있습니다

---

### 5. 소수 찾기 — 에라토스테네스의 체 (2 ~ 1000) ★★★

```asm
; Primes.asm

INCLUDE Irvine32.inc

LIMIT = 1000

.data
sieve BYTE LIMIT+1 DUP(1)       ; 1 = 소수 후보, 0 = 걸러짐
msg   BYTE "Prime numbers from 2 to 1000:",0dh,0ah,0

.code
main PROC
    mov edx,OFFSET msg
    call WriteString

    ; 0과 1은 소수가 아님
    mov BYTE PTR sieve[0],0
    mov BYTE PTR sieve[1],0

    ;----- 체로 거르기 -----
    mov ebx,2                   ; 현재 후보
outerLoop:
    mov eax,ebx
    mul ebx                     ; EAX = ebx²  (EDX도 바뀌지만 여기선 무관)
    cmp eax,LIMIT
    ja  doneSieve               ; ebx² > LIMIT 이면 체질 끝

    cmp BYTE PTR sieve[ebx],0
    je  nextCandidate           ; 이미 걸러진 수면 건너뜀

    mov esi,eax                 ; ⭐ ebx² 부터 표시 시작
markLoop:
    cmp esi,LIMIT
    ja  nextCandidate
    mov BYTE PTR sieve[esi],0   ; 배수를 걸러냄
    add esi,ebx
    jmp markLoop

nextCandidate:
    inc ebx
    jmp outerLoop

doneSieve:
    ;----- 출력 -----
    mov esi,2
printLoop:
    cmp esi,LIMIT
    ja  allDone
    cmp BYTE PTR sieve[esi],0
    je  skipPrint

    mov eax,esi
    call WriteDec
    mov al,' '
    call WriteChar

skipPrint:
    inc esi
    jmp printLoop

allDone:
    call Crlf
    exit
main ENDP
END main
```

**알고리즘**

1. 2부터 1000까지 전부 "소수 후보"로 표시해 둔다
2. 가장 작은 후보 p를 고른다
3. **p² 부터** p씩 건너뛰며 전부 지운다 (p보다 작은 배수는 이미 지워졌으므로)
4. p² > 1000 이 되면 끝. 남은 것이 전부 소수

**채점 포인트**
- **`p²` 부터 지우기 시작**하는 것이 최적화의 핵심입니다. `2p` 부터 시작하면 중복 작업이 많아집니다
- 종료 조건이 **`p² > LIMIT`** 입니다. p > LIMIT 까지 돌 필요가 없습니다 (1000이면 p ≤ 31까지만)
- 배열 크기를 `LIMIT+1` 로 잡아야 인덱스 1000을 쓸 수 있습니다

---

### 6. 최대공약수 (GCD) ★★★

**의사코드**

```
int GCD(int x, int y) {
    x = abs(x)
    y = abs(y)
    do {
        int n = x % y
        x = y
        y = n
    } while (y > 0)
    return x
}
```

```asm
; GCD.asm

INCLUDE Irvine32.inc

.data
msg1 BYTE "GCD(",0
msg2 BYTE ", ",0
msg3 BYTE ") = ",0

.code
main PROC
    mov eax,24
    mov ebx,18
    call ShowGCD

    mov eax,1071
    mov ebx,462
    call ShowGCD

    mov eax,-48
    mov ebx,36
    call ShowGCD

    mov eax,17
    mov ebx,5
    call ShowGCD

    exit
main ENDP

;---------------------------------------------------
; GCD
;   두 정수의 최대공약수를 구한다 (유클리드 호제법).
;   Receives: EAX = x, EBX = y
;   Returns:  EAX = 최대공약수
;---------------------------------------------------
GCD PROC USES ebx ecx edx
    ;----- 절댓값 -----
    cmp eax,0
    jge chkY
    neg eax
chkY:
    cmp ebx,0
    jge chkZero
    neg ebx

chkZero:
    cmp ebx,0
    je  finished                ; y = 0 이면 GCD = x (0으로 나누기 방지)

    ;----- do { n = x % y;  x = y;  y = n } while (y > 0) -----
L1:
    mov ecx,ebx                 ; ECX = y 보관
    mov edx,0                   ; ⭐ 피제수 상위 절반 0으로
    div ebx                     ; EDX = x % y,  EAX = 몫(버림)
    mov eax,ecx                 ; x ← y
    mov ebx,edx                 ; y ← n
    cmp ebx,0
    ja  L1                      ; y > 0 이면 반복

finished:
    ret                         ; EAX = GCD
GCD ENDP

;---------------------------------------------------
; ShowGCD — "GCD(x, y) = z" 형태로 출력
;   Receives: EAX = x, EBX = y
;---------------------------------------------------
ShowGCD PROC USES eax ebx edx
    push eax
    push ebx

    mov edx,OFFSET msg1
    call WriteString
    pop ebx
    pop eax
    push eax
    push ebx
    call WriteInt               ; x 출력

    mov edx,OFFSET msg2
    call WriteString
    pop ebx
    mov eax,ebx
    call WriteInt               ; y 출력
    push ebx

    mov edx,OFFSET msg3
    call WriteString

    pop ebx
    pop eax
    call GCD
    call WriteDec               ; 결과 출력
    call Crlf
    ret
ShowGCD ENDP
END main
```

**검산**

| 호출 | 과정 | 결과 |
|---|---|---|
| GCD(24, 18) | 24%18=6 → (18,6) → 18%6=0 → (6,0) | **6** |
| GCD(1071, 462) | →(462,147)→(147,21)→(21,0) | **21** |
| GCD(−48, 36) | abs → (48,36)→(36,12)→(12,0) | **12** |
| GCD(17, 5) | →(5,2)→(2,1)→(1,0) | **1** |

**채점 포인트**
- **`mov edx,0` 을 DIV 앞에 반드시** 넣어야 합니다. 루프를 돌 때마다 EDX에 이전 나머지가 남아 있으니까요
- **y = 0 인 경우를 먼저 걸러야** 0으로 나누기 예외를 피합니다
- 반환 레지스터 EAX는 **USES에 넣지 않습니다**

---

### 7. BitwiseMultiply — 시프트와 덧셈만으로 곱셈 ★★★

**문제 요약** 시프트와 덧셈만 써서 부호 없는 32비트 정수를 EAX와 곱하는 `BitwiseMultiply` 프로시저를 작성하시오. 정수는 EBX로 전달하고 곱은 EAX로 반환한다. (곱이 32비트를 넘지 않는다고 가정)

```asm
; BitwiseMul.asm

INCLUDE Irvine32.inc

.data
msg BYTE " x ",0
msg2 BYTE " = ",0

.code
main PROC
    mov eax,5
    mov ebx,3
    call ShowProduct            ; 15

    mov eax,25
    mov ebx,12
    call ShowProduct            ; 300

    mov eax,1000
    mov ebx,1000
    call ShowProduct            ; 1000000

    mov eax,7
    mov ebx,0
    call ShowProduct            ; 0

    exit
main ENDP

;---------------------------------------------------
; BitwiseMultiply
;   시프트와 덧셈만으로 EAX × EBX 를 계산한다.
;   Receives: EAX = 피승수, EBX = 승수
;   Returns:  EAX = 곱 (32비트를 넘지 않는다고 가정)
;---------------------------------------------------
BitwiseMultiply PROC USES ebx ecx edx
    mov edx,eax                 ; EDX = 피승수
    mov eax,0                   ; 누적 결과
    mov ecx,32                  ; 최대 32비트

L1:
    shr ebx,1                   ; 승수의 최하위 비트 → CF
    jnc skipAdd
    add eax,edx                 ; 그 비트가 1이면 현재 피승수를 더한다
skipAdd:
    shl edx,1                   ; 피승수를 2배로

    cmp ebx,0
    je  finished                ; 승수가 0이 되면 끝
    loop L1

finished:
    ret
BitwiseMultiply ENDP

;---------------------------------------------------
; ShowProduct — "x × y = z" 출력
;---------------------------------------------------
ShowProduct PROC USES eax ebx edx
    push eax
    push ebx
    call WriteDec               ; 피승수
    mov edx,OFFSET msg
    call WriteString
    pop ebx
    mov eax,ebx
    call WriteDec               ; 승수
    push ebx
    mov edx,OFFSET msg2
    call WriteString
    pop ebx
    pop eax
    call BitwiseMultiply
    call WriteDec               ; 곱
    call Crlf
    ret
ShowProduct ENDP
END main
```

**원리** 2진수 곱셈은 초등학교 곱셈과 같습니다. 승수의 각 비트가 1이면 그 자리만큼 밀린 피승수를 더합니다.

**동작 추적** (5 × 3)

| 반복 | EBX (승수) | CF | EDX (피승수) | EAX (누적) |
|:---:|---|:---:|---|---|
| 시작 | 3 = `11b` | | 5 | 0 |
| 1 | `1b` | **1** | 5 → 10 | 0 + 5 = **5** |
| 2 | `0b` | **1** | 10 → 20 | 5 + 10 = **15** |
| 종료 | 0 | | | **15** ✔ |

**채점 포인트**
- `shr ebx,1` 다음에 **`jnc`** 로 CF를 검사합니다 (밀려 나간 비트가 1인지)
- **`shl edx,1`** 은 비트가 0이어도 매번 해야 합니다 (자리값이 올라가니까요)
- `shl` 이 플래그를 바꾸므로 **`cmp ebx,0` 을 따로** 써야 합니다
- 승수가 0이 되면 **조기 종료**해서 불필요한 반복을 막습니다

---

### 8. AddPacked 확장 — 임의 크기의 packed decimal 덧셈 ★★★

**문제 요약** 7.6.1절의 AddPacked 프로시저를 확장해 임의 크기(길이가 같은)의 packed decimal 정수 두 개를 더하게 하시오. 4·8·16바이트 쌍을 넘기는 테스트 프로그램도 작성한다.

```asm
; AddPackedExt.asm   (32비트 모드 전용 — DAA는 64비트 모드에 없습니다)

INCLUDE Irvine32.inc

.data
; packed decimal, 리틀엔디언 (낮은 주소 = 최하위 자리)
; 4바이트: 12345678 + 11111111 = 23456789
pk1_a BYTE 78h,56h,34h,12h
pk1_b BYTE 11h,11h,11h,11h
sum1  BYTE 4 DUP(0)

; 8바이트: 99999999_99999999 + 00000000_00000001
pk2_a BYTE 99h,99h,99h,99h,99h,99h,99h,99h
pk2_b BYTE 01h,00h,00h,00h,00h,00h,00h,00h
sum2  BYTE 8 DUP(0)

; 16바이트
pk3_a BYTE 50h,50h,50h,50h,50h,50h,50h,50h,50h,50h,50h,50h,50h,50h,50h,50h
pk3_b BYTE 50h,50h,50h,50h,50h,50h,50h,50h,50h,50h,50h,50h,50h,50h,50h,50h
sum3  BYTE 16 DUP(0)

lbl   BYTE "Sum: ",0

.code
main PROC
    mov esi,OFFSET pk1_a
    mov edi,OFFSET pk1_b
    mov edx,OFFSET sum1
    mov ecx,LENGTHOF pk1_a
    call AddPacked
    mov esi,OFFSET sum1
    mov ecx,LENGTHOF sum1
    call ShowPacked

    mov esi,OFFSET pk2_a
    mov edi,OFFSET pk2_b
    mov edx,OFFSET sum2
    mov ecx,LENGTHOF pk2_a
    call AddPacked
    mov esi,OFFSET sum2
    mov ecx,LENGTHOF sum2
    call ShowPacked

    mov esi,OFFSET pk3_a
    mov edi,OFFSET pk3_b
    mov edx,OFFSET sum3
    mov ecx,LENGTHOF pk3_a
    call AddPacked
    mov esi,OFFSET sum3
    mov ecx,LENGTHOF sum3
    call ShowPacked

    exit
main ENDP

;---------------------------------------------------
; AddPacked
;   임의 크기의 packed decimal 정수 두 개를 더한다.
;   Receives: ESI = 첫 번째 수 포인터
;             EDI = 두 번째 수 포인터
;             EDX = 합을 저장할 포인터
;             ECX = 더할 바이트 수
;   Returns:  없음 (CF = 최종 자리올림)
;---------------------------------------------------
AddPacked PROC USES eax ecx edx esi edi
    clc                         ; 자리올림 초기화
L1:
    mov al,[esi]
    adc al,[edi]                ; 자리올림 포함 덧셈
    daa                         ; ⭐ BCD 보정 — CF도 함께 설정된다
    mov [edx],al

    lea esi,[esi+1]             ; ⭐ 플래그를 건드리지 않는 포인터 이동
    lea edi,[edi+1]
    lea edx,[edx+1]
    loop L1

    ret
AddPacked ENDP

;---------------------------------------------------
; ShowPacked — packed decimal을 최상위 바이트부터 출력
;   Receives: ESI = 버퍼 주소, ECX = 바이트 수
;---------------------------------------------------
ShowPacked PROC USES eax ecx edx esi
    push ecx
    mov edx,OFFSET lbl
    call WriteString
    pop ecx

    add esi,ecx
    dec esi                     ; 마지막(최상위) 바이트로
L1:
    mov al,[esi]
    mov ah,al
    shr al,4                    ; 상위 니블
    or  al,30h
    call WriteChar
    mov al,ah
    and al,0Fh                  ; 하위 니블
    or  al,30h
    call WriteChar
    dec esi
    loop L1

    call Crlf
    ret
ShowPacked ENDP
END main
```

**DAA가 하는 일**

`ADC` 는 **2진 덧셈**을 하므로 BCD로는 틀린 값이 나옵니다. `DAA` 가 그걸 바로잡습니다.

```
예) 18h + 09h  (BCD로는 18 + 9 = 27 이어야 함)

adc al,09h :  18h + 09h = 21h      ← 2진 결과 (BCD로는 틀림)
daa        :  하위 니블 1이 9 이하지만 보정 규칙에 따라 +6
           →  27h                   ← BCD로 올바름  ✔
```

**채점 포인트 ⭐**
- **`adc` 다음에 반드시 `daa`** — 순서가 바뀌면 안 됩니다
- **DAA가 CF를 설정**하므로 다음 바이트의 ADC가 그 자리올림을 받습니다
- 포인터 이동에 **`lea`** 를 써서 CF를 보존합니다 (2번 문제와 같은 이유)
- ⚠️ **DAA·DAS·AAA·AAS·AAM·AAD는 64비트 모드에서 사용할 수 없습니다.** 이 프로그램은 32비트 전용입니다

---

# 7장 시험 대비 요점

## 가장 많이 틀리는 7가지

| # | 함정 | 정답 |
|:---:|---|---|
| 1 | **SHR vs SAR** | SHR은 **0**을 채우고, SAR는 **부호 비트**를 복제합니다 |
| 2 | **나눗셈 오버플로** | **피제수의 상위 절반 ≥ 제수** 이면 반드시 오버플로 |
| 3 | **DIV 앞의 EDX** | DIV 앞에는 `mov edx,0`, **IDIV 앞에는 `cdq`** |
| 4 | **MUL 다음의 DIV** | `MUL` 결과가 `EDX:EAX`이고 `DIV` 피제수도 `EDX:EAX` — **EDX를 지우면 안 됩니다** |
| 5 | **확장 산술의 포인터 이동** | `add esi,4` 는 **CF를 날립니다**. `inc` 또는 `lea`를 쓰세요 |
| 6 | **다중 바이트 시프트 방향** | 오른쪽은 **최상위부터**, 왼쪽은 **최하위부터** |
| 7 | **BCD 명령의 모드 제약** | `AAA·AAS·AAM·AAD·DAA·DAS`는 **64비트 모드에서 사용 불가** |

## 나눗셈 오버플로 판별법 ⭐⭐⭐

```
DIV 전에 이것만 보세요:

   피제수 상위 절반  ≥  제수   →  오버플로 확정
   (AH / DX / EDX / RDX)

   AH ≥ 제수  →  AL에 안 들어감
   DX ≥ 제수  →  AX에 안 들어감
   EDX ≥ 제수 →  EAX에 안 들어감
   RDX ≥ 제수 →  RAX에 안 들어감
```

| 교재 문제 | 상위 절반 | 제수 | 판정 |
|---|---|---|---|
| 7.9.1-4 | AH = 0 | 10h | 안전 |
| 7.9.1-5 | EDX = 0 | 10h | 안전 |
| **7.9.1-6** | **DX = 500h** | **10h** | **오버플로** |
| **7.9.1-8** | **RDX = 108h** | **100h** | **오버플로** |

## 시프트로 곱하고 나누기

| 연산 | 명령 |
|---|---|
| × 2ⁿ | `shl reg,n` |
| ÷ 2ⁿ (**부호 없음**) | `shr reg,n` |
| ÷ 2ⁿ (**부호 있음**) | `sar reg,n` |
| mod 2ⁿ | `and reg,(2ⁿ − 1)` |

> ⚠️ **SAR와 IDIV는 음수에서 결과가 다릅니다.** SAR는 **−∞ 방향**, IDIV는 **0 방향**으로 버립니다. (−5 ÷ 2 → SAR는 −3, IDIV는 −2)

## 확장 산술의 철칙

```asm
    clc                     ; ① 루프 앞에서 CF 초기화
L1:
    mov al,[esi]
    adc al,[edi]            ; ② 루프 안에서는 ADC / SBB
    mov [ebx],al
    inc esi                 ; ③ CF를 바꾸지 않는 명령만 사용
    inc edi                 ;    안전: INC, DEC, LEA, MOV, LOOP
    inc ebx                 ;    위험: ADD, SUB, CMP, 비트 연산
    loop L1                 ; ④ LOOP도 플래그를 바꾸지 않음
```

**리틀엔디언이므로 낮은 주소(최하위)에서 위로 진행합니다.**

## 다중 바이트 시프트 패턴

```asm
; 오른쪽 1비트 — 최상위부터 아래로
    shr arr+2,1         ; 첫 명령은 SHR
    rcr arr+1,1         ; 나머지는 RCR
    rcr arr,1

; 왼쪽 1비트 — 최하위부터 위로
    shl arr,1           ; 첫 명령은 SHL
    rcl arr+2,1         ; 나머지는 RCL
    rcl arr+4,1
```

## 외워야 할 명령어 요약

| 명령어 | 한 줄 설명 |
|---|---|
| `ADC` | `dest = dest + src + CF` |
| `SBB` | `dest = dest − src − CF` |
| `CBW` / `CWD` / `CDQ` / `CQO` | AL→AX / AX→DX:AX / EAX→EDX:EAX / RAX→RDX:RAX |
| `DAA` / `DAS` | **packed** BCD 덧셈/뺄셈 보정 |
| `AAA` / `AAS` / `AAM` / `AAD` | **unpacked(ASCII)** BCD 보정 |
| `SHLD` / `SHRD` | 2배 정밀도 시프트 — 빈 자리를 원본의 비트로 채움 |
| `LEA` | 주소 계산 — **플래그를 바꾸지 않음** |


