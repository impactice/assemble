# 10장 구조체와 매크로 (Structures and Macros) — 연습문제 풀이

> Kip Irvine, *Assembly Language for x86 Processors* 7판, 10.7절~10.8절
> 문제는 한국어로 요약했습니다. 원문은 교재 440~444쪽을 함께 보세요.
>
> 구성: **10.7.1 단답형 10문제 + 10.7.2 알고리즘 연습 16문제 + 10.8 프로그래밍 과제 10문제**

---

## 들어가기 전에 — 10장 핵심 표 4개

### ① 구조체 (STRUCT) ⭐⭐⭐

```asm
; ① 정의 — 틀만 만듦 (메모리를 차지하지 않음)
COORD STRUCT
    X WORD ?
    Y WORD ?
COORD ENDS

; ② 변수 선언 — 이름이 먼저, 타입이 뒤
.data
p1 COORD <5,10>                 ; X=5, Y=10
p2 COORD <20>                   ; X=20, Y=기본값
p3 COORD <>                     ; 전부 기본값
pts COORD 3 DUP(<0,0>)          ; 구조체 배열

; ③ 필드 접근
.code
mov ax,p1.X                     ; 직접
mov esi,OFFSET p1
mov ax,(COORD PTR [esi]).Y      ; 간접 — PTR로 타입을 알려 줘야 함
```

| 규칙 | 내용 |
|---|---|
| 선언 순서 | **`변수이름 구조체이름 <초기값>`** |
| 초기값 | 필드 순서대로 **왼쪽부터**. 생략한 필드는 기본값 |
| 필드 건너뛰기 | **쉼표만** 두기 → `<,10>` 은 첫 필드 생략 |
| 초기값 개수 | **필드 수보다 많으면 오류** |
| 중첩 구조체 | 꺾쇠 안에 꺾쇠 → `< <0,0>, <5,0> >` |
| 크기 | `TYPE 구조체` = 구조체 하나의 바이트 수 |

### ② 매크로 vs 프로시저 ⭐⭐

| | **매크로 (MACRO)** | **프로시저 (PROC)** |
|---|---|---|
| 처리 시점 | **어셈블할 때** 코드를 **그 자리에 펼쳐 넣음** | **실행할 때** CALL로 점프 |
| 코드 크기 | 호출할 때마다 **늘어남** | 한 번만 존재 |
| 속도 | CALL/RET이 없어 **빠름** | CALL/RET 비용 |
| 인자 | **텍스트 치환** | 스택·레지스터로 전달 |

> **매크로는 "복사-붙여넣기를 어셈블러가 대신 해 주는 것"** 입니다. 실행할 때는 매크로라는 게 존재하지 않습니다.

### ③ 매크로 안에서 쓰는 지시어와 연산자 ⭐⭐⭐

| 기호 | 이름 | 하는 일 |
|---|---|---|
| `LOCAL` | 지역 레이블 | 펼칠 때마다 레이블 이름을 **고유하게** 바꿈 (`??0000`, `??0001`, ...) |
| `:REQ` | 필수 매개변수 | 인자를 빠뜨리면 **어셈블 오류** |
| `:= <값>` | 기본 인자 | 인자를 생략하면 이 값을 씀 |
| `&` | **치환 연산자** | 문자열 안이나 다른 글자에 붙은 **매개변수 이름을 값으로 바꿈** |
| `<>` | **리터럴 텍스트 연산자** | 공백·쉼표가 섞인 텍스트를 **인자 하나로 묶음** |
| `!` | **리터럴 문자 연산자** | 다음 한 글자를 **특수 의미 없이 그냥 글자로** 취급 |
| `%` | **확장 연산자** | 식을 **계산한 값**을 텍스트로 바꿔 넣음 |
| `;;` | 매크로 주석 | 펼친 코드에 **나타나지 않는** 주석 |
| `EXITM` | 매크로 탈출 | 남은 부분을 **펼치지 않고** 끝냄 |

### ④ 조건부 어셈블리 ⭐⭐

| 지시어 | 참이 되는 조건 |
|---|---|
| `IF 식` | 식이 참(0이 아님) |
| `IFB <인자>` / `IFNB <인자>` | 인자가 **비었음** / **비어 있지 않음** |
| `IFIDN <a>,<b>` / `IFIDNI` | 두 텍스트가 **같음** (IFIDNI는 대소문자 무시) |
| `IFDIF <a>,<b>` / `IFDIFI` | 두 텍스트가 **다름** |
| `IFDEF 이름` / `IFNDEF` | 기호가 **정의됨** / **정의 안 됨** |
| `ELSE` / `ELSEIF` | 그 밖의 경우 |
| **`ENDIF`** | **조건 블록의 끝** |
| **`ECHO 메시지`** | **어셈블하는 동안** 콘솔에 메시지 출력 |

**관계 연산자 6개**: `LT`(<) `GT`(>) `EQ`(=) `NE`(≠) `LE`(≤) `GE`(≥)

> ⚠️ **조건부 어셈블리는 어셈블할 때만 동작합니다.** 변수의 실행 시간 값은 볼 수 없고, **상수와 매개변수 텍스트만** 검사할 수 있습니다. 실행 시간 조건은 6장의 `.IF` 나 CMP/점프를 써야 합니다.

---

## 10.7.1 단답형 (Short Answer)

### 1. STRUCT 지시어의 목적은?

**정답: 서로 관련된 여러 변수(필드)를 하나로 묶은 구조체의 "틀(템플릿)"을 정의합니다.**

- STRUCT로 정의만 해서는 **메모리가 잡히지 않습니다.** 설계도일 뿐입니다
- 이 틀을 타입처럼 써서 **구조체 변수를 선언할 때** 비로소 메모리가 할당됩니다
- C 언어의 `struct` 와 같은 개념입니다

---

### 2. 구조체 RentalInvoice 선언의 유효성 판단

**주어진 구조체** RentalInvoice는 필드가 **3개**입니다.

| 필드 | 타입 |
|---|---|
| `invoiceNum` | 5바이트 문자 배열 (공백으로 초기화) |
| `dailyPrice` | WORD |
| `daysRented` | WORD |

**정답**

| | 선언 | 판정 | 이유 |
|:---:|---|:---:|---|
| a | `rentals RentalInvoice <>` | **유효** | 이름 + 타입 + 기본값 |
| b | `RentalInvoice rentals <>` | **무효** | ⭐ **이름과 타입의 순서가 반대** |
| c | `march RentalInvoice <'12345',10,0>` | **유효** | 필드 3개에 초기값 3개. 문자열 5글자가 배열 크기에 딱 맞음 |
| d | `RentalInvoice <,10,0>` | **유효** | 이름 없는 구조체 변수. 첫 필드는 쉼표로 건너뜀 |
| e | `current RentalInvoice <,15,0,0>` | **무효** | ⭐ **초기값이 4개** (빈 칸 포함) — 필드는 3개뿐 |

**(d) 보충** MASM에서는 데이터 정의에 이름(레이블)이 꼭 있어야 하는 건 아닙니다. `BYTE 10` 처럼 이름 없이 써도 되는 것과 같습니다. 이름이 없으니 **이름으로 참조할 수 없을 뿐** 선언 자체는 문법에 맞습니다. 구조체 배열을 여러 줄에 나눠 쓸 때 둘째 줄부터 이름을 생략하는 것도 같은 원리입니다.

**(e) 세는 법** `<,15,0,0>` 은 쉼표가 3개이므로 **초기값 자리가 4개** (첫 자리는 비어 있음)입니다.

> ⭐ 시험에서 가장 많이 틀리는 건 **(b) 순서**와 **(e) 개수**입니다.

---

### 3. (참/거짓) 매크로 안에는 데이터 정의를 넣을 수 없다.

**정답: 거짓**

매크로 안에서 `.data` 로 전환해 변수를 정의하고 다시 `.code` 로 돌아올 수 있습니다. 교재 매크로 라이브러리의 `mWrite` 가 이렇게 문자열을 정의합니다.

```asm
mSayHello MACRO
    LOCAL msg                   ;; 펼칠 때마다 다른 이름이 되도록
    .data
    msg BYTE "Hello",0          ;; ⭐ 매크로 안의 데이터 정의
    .code
    push edx
    mov  edx,OFFSET msg
    call WriteString
    pop  edx
ENDM
```

> 이때 **LOCAL** 이 없으면 매크로를 두 번 펼쳤을 때 `msg` 가 두 번 정의되어 오류가 납니다 (4번 문제).

---

### 4. LOCAL 지시어의 목적은?

**정답: 매크로 안의 레이블(또는 변수 이름)을 펼칠 때마다 고유한 이름으로 바꿔 줍니다.**

매크로는 호출한 자리마다 **같은 코드를 복사**하므로, 안에 `L1:` 같은 레이블이 있으면 두 번째 호출에서 **"레이블이 이미 정의됨" 오류**가 납니다. LOCAL로 선언하면 어셈블러가 호출할 때마다 `??0000`, `??0001` 처럼 **다른 이름**으로 바꿔 줍니다.

```asm
mRepeat MACRO count
    LOCAL L1                    ;; ⭐ MACRO 바로 다음 줄에 와야 함
    mov  ecx,count
L1: ; ...
    loop L1
ENDM
```

> ⚠️ **8장의 LOCAL과 혼동하지 마세요.**
>
> | | 8장 (PROC 안) | 10장 (MACRO 안) |
> |---|---|---|
> | 하는 일 | 스택에 **지역 변수** 공간 확보 | 레이블 이름을 **고유하게** 바꿈 |
> | 처리 시점 | 실행할 때 (`sub esp,n`) | 어셈블할 때 (이름 치환) |

---

### 5. 어셈블하는 동안 콘솔에 메시지를 표시하는 지시어는?

**정답: `ECHO`**

```asm
IF count GT 100
    ECHO *** Warning: count is too large ***
ENDIF
```

> 실행할 때가 아니라 **어셈블러가 소스를 처리하는 도중**에 표시됩니다. 매크로에 잘못된 인자가 들어왔을 때 경고하는 용도로 씁니다.

---

### 6. 조건 블록의 끝을 표시하는 지시어는?

**정답: `ENDIF`**

> `IF`, `IFB`, `IFIDN`, `IFDEF` 등 **모든 조건 지시어**는 `ENDIF` 로 끝납니다. (6장의 실행 시간 `.IF` 는 `.ENDIF` — 점이 붙습니다.)

---

### 7. 상수 불리언 식에 쓸 수 있는 관계 연산자를 모두 나열하시오.

**정답: `LT`, `GT`, `EQ`, `NE`, `LE`, `GE`**

| 연산자 | 뜻 | 기억법 |
|:---:|---|---|
| `LT` | < | **L**ess **T**han |
| `GT` | > | **G**reater **T**han |
| `EQ` | = | **EQ**ual |
| `NE` | ≠ | **N**ot **E**qual |
| `LE` | ≤ | **L**ess or **E**qual |
| `GE` | ≥ | **G**reater or **E**qual |

> 6장 조건 점프의 G/L/E와 이름이 같은 계열이라 같이 외우면 됩니다. `<` `>` 기호는 꺾쇠(리터럴 텍스트) 연산자와 겹치기 때문에 영문자 연산자를 씁니다.

---

### 8. 매크로 정의에서 & 연산자의 목적은?

**정답: 치환 연산자 — 문자열 안에 들어 있거나 다른 글자에 붙어 있는 매개변수 이름을 실제 인자 값으로 바꿉니다.**

```asm
mShowName MACRO varName
    LOCAL str1
    .data
    str1 BYTE "Name: &varName",0    ;; & 가 없으면 "varName" 글자 그대로 남음
    .code
    ...
ENDM

    mShowName count                 ; → "Name: count"
```

> 문자열 따옴표 안에서는 매개변수가 자동으로 치환되지 않습니다. **`&` 를 붙여야 "여기가 매개변수다"** 라고 알려 줄 수 있습니다.

---

### 9. 매크로 정의에서 ! 연산자의 목적은?

**정답: 리터럴 문자 연산자 — 바로 다음 한 글자를 특수 의미 없이 평범한 글자로 취급하게 합니다.**

예를 들어 꺾쇠 `< >` 로 묶은 텍스트 안에 `>` 글자를 넣고 싶으면, 그 `>` 가 텍스트의 끝으로 해석되지 않도록 `!` 를 붙입니다.

```asm
    mShowMsg <Value must be !> 0>   ; 인자 텍스트: "Value must be > 0"
```

> `!` 가 없으면 첫 번째 `>` 에서 텍스트가 끝난 것으로 보고 나머지 `0>` 때문에 오류가 납니다.

---

### 10. 매크로 정의에서 % 연산자의 목적은?

**정답: 확장 연산자 — 상수 식을 계산해서 그 결과 값을 텍스트로 바꿔 넣습니다.**

```asm
COUNT = 10
    mShowValue %(COUNT * 2)         ; 인자로 "COUNT * 2" 가 아니라 "20" 이 전달됨
```

| 쓰는 곳 | 효과 |
|---|---|
| 인자 앞의 `%식` | 식을 계산한 **값**으로 치환 |
| 줄 맨 앞의 `%` | 그 줄의 텍스트 매크로를 모두 **펼침** (예: ECHO 메시지 안의 값 표시) |

> **& `<>` ! % 네 연산자를 한 세트로** 외우세요. 이름(치환·리터럴 텍스트·리터럴 문자·확장)과 용도를 짝지어 묻는 문제가 나오기 쉽습니다.

---

## 10.7.2 알고리즘 연습 (Algorithm Workbench)

### 1. 구조체 SampleStruct 정의 (field1: WORD 하나, field2: DWORD 20개 배열, 초기값 없음)

```asm
SampleStruct STRUCT
    field1 WORD ?
    field2 DWORD 20 DUP(?)
SampleStruct ENDS
```

> 크기: `TYPE SampleStruct` = 2 + 4 × 20 = **82바이트**

---

### 2. SYSTEMTIME 구조체의 wHour 필드를 가져오는 문장

```asm
.data
sysTime SYSTEMTIME <>

.code
    mov ax,sysTime.wHour            ; ⭐ wHour는 WORD → AX
```

**구조체 주소가 레지스터에 있을 때**

```asm
    mov esi,OFFSET sysTime
    mov ax,(SYSTEMTIME PTR [esi]).wHour
```

> SYSTEMTIME의 필드는 **전부 WORD** 입니다 (년, 월, 요일, 일, **시**, 분, 초, 밀리초). 그래서 받는 레지스터도 **AX** 입니다.

---

### 3. Triangle 구조체 변수를 선언하고 꼭짓점을 (0,0), (5,0), (7,6)으로 초기화

**주어진 구조체** Triangle은 COORD 필드 3개(Vertex1, Vertex2, Vertex3)로 이루어져 있습니다.

```asm
.data
myTriangle Triangle < <0,0>, <5,0>, <7,6> >
```

**구조**

```
myTriangle Triangle <  <0,0>  ,  <5,0>  ,  <7,6>  >
                    ↑  └Vertex1┘ └Vertex2┘ └Vertex3┘ ↑
                    바깥 꺾쇠 = Triangle    안쪽 꺾쇠 = 각 COORD
```

> ⭐ **구조체 안의 구조체는 꺾쇠 안에 꺾쇠**로 초기화합니다. 바깥이 Triangle, 안쪽이 각 COORD의 (X, Y)입니다.

---

### 4. Triangle 구조체 배열을 선언하고, 각 삼각형의 Vertex1을 (0~10, 0~10) 범위의 난수로 초기화하는 루프

```asm
NumTriangles = 5

.data
triangles Triangle NumTriangles DUP(<>)

.code
    call Randomize
    mov  esi,OFFSET triangles
    mov  ecx,NumTriangles
L1:
    mov  eax,11                         ; 0 ~ 10 (11가지)
    call RandomRange
    mov  (Triangle PTR [esi]).Vertex1.X,ax

    mov  eax,11
    call RandomRange
    mov  (Triangle PTR [esi]).Vertex1.Y,ax

    add  esi,TYPE Triangle              ; ⭐ 다음 삼각형으로 (12바이트)
    loop L1
```

**채점 포인트**
- 0~10을 **포함**하려면 `RandomRange(11)` 입니다. `RandomRange(10)` 은 0~9
- 다음 원소로 갈 때 **`TYPE Triangle`** (= COORD 3개 × 4바이트 = **12**)만큼 이동
- 중첩 필드는 **점을 이어서** 접근: `(Triangle PTR [esi]).Vertex1.X`
- COORD의 X, Y는 WORD이므로 **AX** 로 저장

---

### 5. 문자를 지정한 횟수만큼 출력하는 매크로 mPrintChar

호출 예: `mPrintChar 'X',20`

```asm
mPrintChar MACRO char, count
    LOCAL L1, done              ;; 펼칠 때마다 레이블 이름을 고유하게
    push eax
    push ecx
    mov  al,char
    mov  ecx,count
    jecxz done                  ;; 0번이면 아무것도 안 함
L1: call WriteChar
    loop L1
done:
    pop  ecx
    pop  eax
ENDM
```

**채점 포인트**
- 루프 레이블이 있으므로 **LOCAL 필수**. 없으면 두 번째 호출에서 레이블 중복 오류
- 매크로가 쓰는 레지스터(EAX, ECX)를 **PUSH/POP으로 보존** — 호출하는 쪽은 매크로가 무엇을 바꾸는지 모릅니다
- `jecxz` 로 횟수 0 처리 (LOOP는 ECX=0으로 시작하면 약 43억 번 돕니다)

---

### 6. 0 ~ n−1 범위의 난수를 만드는 매크로 mGenRandom

```asm
mGenRandom MACRO n
    mov  eax,n
    call RandomRange            ;; EAX = 0 ~ n-1
ENDM
```

**사용 예**

```asm
    call Randomize              ; 프로그램 시작할 때 한 번만
    mGenRandom 100              ; EAX = 0 ~ 99
```

> 결과가 **EAX** 에 담기므로 EAX는 보존하지 않습니다 (반환값).

---

### 7. 안내 문구를 출력하고 정수를 입력받는 매크로 mPromptInteger

호출 예: `mPromptInteger "Enter the minimum value", minVal`

```asm
mPromptInteger MACRO prompt, returnVal
    LOCAL msg
    .data
    msg BYTE prompt,": ",0      ;; ⭐ 문자열 리터럴로 변수를 만듦
    .code
    push eax
    push edx
    mov  edx,OFFSET msg
    call WriteString
    call ReadInt                ;; EAX = 입력한 정수
    mov  returnVal,eax
    pop  edx
    pop  eax
ENDM
```

**사용 예**

```asm
.data
minVal DWORD ?

.code
    mPromptInteger "Enter the minimum value", minVal
```

**펼쳐진 데이터 부분**

```asm
.data
??0000 BYTE "Enter the minimum value",": ",0
```

**채점 포인트**
- 문자열 리터럴은 바로 출력할 수 없으므로 **매크로 안에서 데이터로 정의**합니다 (단답 3번)
- 그 변수 이름은 **LOCAL** 로 고유하게 (단답 4번)
- ⚠️ 변수 이름을 `str` 로 짓지 마세요. **STR은 x86 명령어 이름**이라 충돌합니다

---

### 8. 커서를 옮기고 문자열 리터럴을 출력하는 매크로 mWriteAt

교재 매크로 라이브러리의 `mGotoxy` 와 `mWrite` 를 이용합니다.

```asm
mWriteAt MACRO X, Y, literal
    mGotoxy X, Y                ;; 커서 이동 (열, 행)
    mWrite literal              ;; 문자열 리터럴 출력
ENDM
```

**사용 예**

```asm
    mWriteAt 10, 5, "Hello at (10,5)"
```

> **매크로 안에서 다른 매크로를 호출**할 수 있습니다. 펼칠 때 안쪽 매크로까지 차례로 펼쳐집니다.

---

### 9. `mWriteStr namePrompt` 가 펼쳐진 코드

10.2.5절 매크로 라이브러리의 **mWriteString** 매크로를 호출한 것입니다. (교재 문제에는 이름이 `mWriteStr` 로 줄여 적혀 있습니다.)

```asm
    push edx
    mov  edx,OFFSET namePrompt
    call WriteString
    pop  edx
```

> 매개변수 `buffer` 자리에 인자 `namePrompt` 가 **텍스트 그대로 치환**됩니다. 매크로는 EDX를 쓰므로 PUSH/POP으로 보존합니다.

---

### 10. `mReadStr customerName` 이 펼쳐진 코드

10.2.5절의 **mReadString** 매크로를 호출한 것입니다.

```asm
    push ecx
    push edx
    mov  edx,OFFSET customerName
    mov  ecx,SIZEOF customerName
    call ReadString
    pop  edx
    pop  ecx
```

> ReadString은 **EDX = 버퍼 주소, ECX = 최대 글자 수**를 받습니다 (5장). 매크로는 `SIZEOF` 로 버퍼 크기를 자동으로 넣어 줍니다. 그래서 호출하는 쪽은 변수 이름 하나만 주면 됩니다.

---

### 11. 변수 이름 하나만 받아 mDumpMem을 호출하는 매크로 mDumpMemx

```asm
mDumpMemx MACRO varName
    mDumpMem OFFSET varName, LENGTHOF varName, TYPE varName
ENDM
```

**사용 예**

```asm
.data
array DWORD 10h, 20h, 30h, 40h

.code
    mDumpMemx array
```

**펼치면**

```asm
    mDumpMem OFFSET array, LENGTHOF array, TYPE array
```

> 이름 하나로 **주소·개수·원소 크기 세 가지를 모두 계산**해 넘깁니다. 3장의 `OFFSET`, `LENGTHOF`, `TYPE` 이 매크로와 만나는 문제입니다.

---

### 12. 기본 인자 초기화자가 있는 매크로 매개변수 예

```asm
mWriteLine MACRO text := <" ">      ;; ⭐ 인자를 생략하면 " " (공백)
    mWrite text
    call Crlf
ENDM
```

**사용 예**

```asm
    mWriteLine "Hello"              ; "Hello" 출력 후 줄바꿈
    mWriteLine                      ; 인자 생략 → 공백 출력 후 줄바꿈
```

> 문법: **`매개변수이름 := <기본값>`** — 기본값은 반드시 **꺾쇠로 감쌉니다.**

---

### 13. IF, ELSE, ENDIF를 사용한 짧은 예

```asm
DEBUG = 1

    mov eax,total
IF DEBUG EQ 1
    call DumpRegs                   ; 디버그 모드일 때만 이 줄이 어셈블됨
ELSE
    nop                             ; 아니면 이 줄이 어셈블됨
ENDIF
```

> `DEBUG = 0` 으로 바꾸면 **`call DumpRegs` 가 실행 파일에 아예 들어가지 않습니다.** 실행 시간에 건너뛰는 게 아니라, 어셈블할 때 **코드 자체가 빠집니다.** 이것이 실행 시간 `.IF` 와의 차이입니다.

---

### 14. 매크로 상수 매개변수 Z가 0보다 작으면 어셈블 중에 "Z가 잘못됨" 메시지를 표시하는 IF 문

```asm
IF Z LT 0
    ECHO *** Error: Z is invalid (Z < 0) ***
ENDIF
```

**매크로 안에서 쓰면**

```asm
mCheckZ MACRO Z
    IF Z LT 0
        ECHO *** Error: Z is invalid (Z < 0) ***
        EXITM                       ;; 나머지는 펼치지 않음
    ENDIF
    mov eax,Z
ENDM

    mCheckZ -5                      ; 어셈블할 때 메시지가 뜨고 코드는 생성되지 않음
```

> `<` 기호 대신 **`LT`** 를 씁니다. 메시지는 **`ECHO`** (단답 5번).

---

### 15. 문자열 리터럴 안에 매개변수가 들어갈 때 & 연산자를 쓰는 짧은 매크로

```asm
mShowRegName MACRO regName
    LOCAL nameStr
    .data
    nameStr BYTE "Register: &regName",0     ;; ⭐ &regName → 실제 인자
    .code
    push edx
    mov  edx,OFFSET nameStr
    call WriteString
    call Crlf
    pop  edx
ENDM
```

**사용 예와 결과**

| 호출 | 만들어지는 문자열 |
|---|---|
| `mShowRegName EAX` | `"Register: EAX"` |
| `mShowRegName ESI` | `"Register: ESI"` |

> `&` 를 빼면 인자와 상관없이 항상 `"Register: regName"` 이 출력됩니다. 따옴표 안의 매개변수는 **& 가 있어야만** 치환됩니다.

---

### 16. mLocate 매크로가 각 호출에서 펼쳐지는 코드

**주어진 매크로의 동작**
1. `xval` 이 0보다 작으면 **EXITM** 으로 즉시 끝냄
2. `yval` 이 0보다 작으면 **EXITM** 으로 즉시 끝냄
3. 아니면 BX = 0(화면 페이지), AH = 2(커서 이동 기능), **DH = yval, DL = xval** 로 놓고 **INT 10h**(BIOS)를 호출

```asm
.data
row BYTE 15
col BYTE 60
```

**(a) `mLocate -2,20`**

```asm
    ; (아무 코드도 생성되지 않음)
```

xval = −2 < 0 이므로 첫 IF에서 **EXITM** 합니다. IF·ENDIF 지시어 자체는 코드를 만들지 않으므로 **펼쳐진 결과는 비어 있습니다.**

**(b) `mLocate 10,20`**

```asm
    mov bx,0
    mov ah,2
    mov dh,20
    mov dl,10
    int 10h
```

두 값 모두 0 이상이므로 전부 펼쳐집니다. **DH에 y(20), DL에 x(10)** — 순서가 바뀌어 들어가는 것에 주의하세요.

**(c) `mLocate col,row`**

```asm
    mov bx,0
    mov ah,2
    mov dh,row
    mov dl,col
    int 10h
```

인자가 **텍스트 그대로 치환**되어 `row`, `col` 이라는 **변수 이름**이 들어갑니다. 실행할 때 DH = 15, DL = 60이 됩니다.

> ⚠️ **(c)의 함정 — 조건부 어셈블리는 변수의 값을 모릅니다.**
>
> `IF col LT 0` 은 어셈블할 때 처리되는데, 그 시점에 col의 **실행 시간 값(60)은 알 수 없습니다.** 그래서 이 검사는 "변수 값이 음수인지"를 확인해 주지 **못합니다.** 교재가 기대하는 답은 위처럼 그대로 펼쳐진 코드지만, 어셈블러에 따라서는 IF에 상수가 아닌 것이 들어왔다고 오류를 낼 수도 있습니다.
>
> **결론: IF로는 상수만 검사할 수 있다.** 변수 값을 검사하려면 실행 시간 명령(CMP + 점프)이 필요합니다.
>
> 참고로 `INT 10h` 는 BIOS 기능이라 **실제 주소 모드(16비트 DOS)** 에서만 동작합니다. 32비트 Windows 프로그램에서는 Gotoxy를 써야 합니다.

---

## 10.8 프로그래밍 과제 (Programming Exercises)

> **손코딩 분량 (제 판단)** — 교수님이 긴 문제는 안 내시므로 "짧음"이 가장 유력합니다. 매크로 과제는 대부분 짧습니다.
>
> | 번호 | 과제 | 분량 | 10장 핵심 개념 |
> |:---:|---|:---:|---|
> | 1 | mReadkey | **매우 짧음** | 매크로 + 레지스터 보존 |
> | 2 | mWriteStringAttr | **짧음** | 매크로 + 색 저장/복구 |
> | 3 | mMove32 | **매우 짧음** | 메모리→메모리 이동 |
> | 4 | mMult32 | **매우 짧음** | 매크로 + IMUL |
> | 5 | mReadInt | **짧음** | **조건부 어셈블리 (TYPE)** |
> | 6 | mWriteInt | **짧음** | **조건부 어셈블리 (TYPE)** |
> | 7 | 잃어버린 휴대폰 | 김 | 구조체 배열 |
> | 8 | 방향 확률이 있는 산책 | 김 | 구조체 + 확률 |
> | 9 | mShiftDoublewords | 보통 | IFIDNI, SHRD/SHLD |
> | 10 | 세 피연산자 매크로 | **짧음** | 매크로 4개 + IDIV/CDQ |

---

### 1. mReadkey — 키 입력을 기다렸다가 ASCII 코드와 스캔 코드 반환

**문제 요약** 키 하나를 누를 때까지 기다렸다가 **ASCII 코드와 키보드 스캔 코드**를 두 인자에 돌려주는 매크로를 작성하시오. (ReadChar 사용)

```asm
; ReadKey.asm

INCLUDE Irvine32.inc

;---------------------------------------------------
; mReadkey — 키 하나를 기다려 ASCII 코드와 스캔 코드를 돌려준다
;---------------------------------------------------
mReadkey MACRO ascii, scan
    push eax
    call ReadChar               ;; AL = ASCII 코드, AH = 스캔 코드 (확장 키)
    mov  ascii,al
    mov  scan,ah
    pop  eax
ENDM

.data
ascii BYTE ?
scan  BYTE ?
msg0  BYTE "Press keys (ESC to quit)",0dh,0ah,0
msg1  BYTE "ASCII = ",0
msg2  BYTE "h   Scan = ",0
msg3  BYTE "h",0dh,0ah,0

.code
main PROC
    mov  edx,OFFSET msg0
    call WriteString
L1:
    mReadkey ascii, scan

    mov  edx,OFFSET msg1
    call WriteString
    movzx eax,ascii
    mov  ebx,1                  ; WriteHexB: 1바이트 크기로 표시
    call WriteHexB
    mov  edx,OFFSET msg2
    call WriteString
    movzx eax,scan
    call WriteHexB
    mov  edx,OFFSET msg3
    call WriteString

    cmp  ascii,1Bh              ; ESC면 종료
    jne  L1
    exit
main ENDP
END main
```

**출력 예**

```
Press keys (ESC to quit)
ASCII = 41h   Scan = ..h        ← 'A'
ASCII = 00h   Scan = 48h        ← ↑ 화살표 (확장 키)
```

**채점 포인트**
- **ReadChar의 반환**: 일반 키는 **AL = ASCII 코드**. 화살표·F1 같은 **확장 키는 AL = 0, AH = 스캔 코드**
- 교재는 확장 키일 때만 AH의 스캔 코드를 보장한다고 설명합니다. 일반 키의 스캔 코드가 꼭 필요하면 11장의 Win32 콘솔 입력 함수를 써야 합니다
- 매크로가 EAX를 쓰므로 **PUSH/POP으로 보존**

---

### 2. mWriteStringAttr — 지정한 색으로 문자열 출력

**문제 요약** null 종료 문자열을 **지정한 텍스트 색**으로 출력하는 매크로를 작성하시오. 매개변수는 문자열 이름과 색. (SetTextColor 사용)

```asm
; ColorString.asm

INCLUDE Irvine32.inc

;---------------------------------------------------
; mWriteStringAttr — 문자열을 지정한 색으로 출력하고 원래 색으로 되돌린다
;---------------------------------------------------
mWriteStringAttr MACRO string, color
    push eax
    push edx
    call GetTextColor           ;; AL = 현재 색
    movzx eax,al
    push eax                    ;; ⭐ 원래 색 보관
    mov  eax,color
    call SetTextColor
    mov  edx,OFFSET string
    call WriteString
    pop  eax
    call SetTextColor           ;; ⭐ 원래 색으로 복구
    pop  edx
    pop  eax
ENDM

.data
str1 BYTE "This line is yellow",0dh,0ah,0
str2 BYTE "This line is light green",0dh,0ah,0
str3 BYTE "White text on a blue background",0dh,0ah,0
str4 BYTE "Back to the original color",0dh,0ah,0

.code
main PROC
    mWriteStringAttr str1, yellow
    mWriteStringAttr str2, lightGreen
    mWriteStringAttr str3, <white + (blue * 16)>    ; ⭐ 꺾쇠로 하나의 인자로 묶음
    mov  edx,OFFSET str4
    call WriteString
    exit
main ENDP
END main
```

**채점 포인트**
- 색 공식: **전경색 + (배경색 × 16)** (5장)
- **GetTextColor로 원래 색을 저장했다가 복구**합니다. 안 그러면 이후 출력이 전부 마지막 색으로 나옵니다
- 공백이 들어간 인자는 **`< >` 로 묶어** 하나의 인자로 넘깁니다 — 리터럴 텍스트 연산자의 실제 용도입니다
- 교재 문제의 호출 예에는 매크로 이름이 `mWritestring` 으로 적혀 있는데, 라이브러리의 `mWriteString` 과 겹치지 않게 문제 제목의 이름을 썼습니다

---

### 3. mMove32 — 32비트 메모리에서 메모리로 이동

**문제 요약** 32비트 메모리 피연산자 두 개를 받아 **원본을 대상으로 옮기는** 매크로를 작성하시오.

```asm
; Move32.asm

INCLUDE Irvine32.inc

;---------------------------------------------------
; mMove32 — 32비트 메모리 원본을 메모리 대상으로 옮긴다
;---------------------------------------------------
mMove32 MACRO destination, source
    push eax
    mov  eax,source             ;; ⭐ 메모리 → 레지스터
    mov  destination,eax        ;; ⭐ 레지스터 → 메모리
    pop  eax
ENDM

.data
val1 DWORD 12345678h
val2 DWORD 0

.code
main PROC
    mMove32 val2, val1          ; val2 ← val1

    mov  eax,val2
    call WriteHex               ; 12345678
    call Crlf
    exit
main ENDP
END main
```

**채점 포인트**
- **MOV는 메모리 → 메모리가 불가능**합니다 (4장). 그래서 레지스터를 **경유**해야 합니다
- 경유한 레지스터(EAX)를 **PUSH/POP으로 보존**해서 매크로가 부작용을 남기지 않게 합니다
- 이 매크로를 쓰면 마치 `mov 메모리,메모리` 가 되는 것처럼 보입니다 — 매크로로 명령어 세트를 "확장"하는 예입니다

---

### 4. mMult32 — 32비트 메모리 피연산자 두 개의 곱 (32비트 결과)

**문제 요약** 32비트 메모리 피연산자 두 개를 곱해 **32비트 곱**을 만드는 매크로를 작성하시오.

```asm
; Mult32.asm

INCLUDE Irvine32.inc

;---------------------------------------------------
; mMult32 — 두 32비트 메모리 피연산자를 곱한다
;   결과: EAX = 곱의 하위 32비트
;         OF = CF = 1 이면 32비트를 넘쳤음
;---------------------------------------------------
mMult32 MACRO op1, op2
    mov  eax,op1
    imul eax,op2                ;; ⭐ 2-피연산자 IMUL: EAX = EAX × op2
ENDM

.data
a1 SDWORD 1234
b1 SDWORD 56
a2 SDWORD -25
b2 SDWORD 4
a3 SDWORD 100000
b3 SDWORD 100000
ovMsg BYTE "  (overflow!)",0

.code
main PROC
    mMult32 a1, b1
    call ShowProduct            ; +69104

    mMult32 a2, b2
    call ShowProduct            ; -100

    mMult32 a3, b3
    call ShowProduct            ; +1410065408  (overflow!)
    exit
main ENDP

;---------------------------------------------------
; ShowProduct — EAX를 출력하고, 넘쳤으면 표시
;   CALL과 PUSH는 플래그를 바꾸지 않으므로
;   mMult32가 남긴 OF를 여기서 그대로 볼 수 있다
;---------------------------------------------------
ShowProduct PROC USES edx
    pushfd                      ; ⭐ 플래그 보관 (WriteInt가 플래그를 바꿈)
    call WriteInt
    popfd
    jno  done
    mov  edx,OFFSET ovMsg
    call WriteString
done:
    call Crlf
    ret
ShowProduct ENDP
END main
```

**채점 포인트**
- **2-피연산자 IMUL** (`imul eax,op2`) 은 결과를 **대상 크기(32비트)로 잘라서** 넣습니다. 문제가 원하는 "32비트 곱"에 딱 맞습니다 (7장)
- 이 형태는 **EDX를 건드리지 않습니다.** MUL을 쓰면 EDX:EAX에 결과가 나와 EDX를 보존해야 합니다
- 결과가 32비트에 안 들어가면 **OF = CF = 1**. 100000 × 100000 = 10¹⁰ 은 32비트를 넘으므로 오버플로
- 결과를 EAX로 돌려주므로 EAX는 보존하지 않습니다

---

### 5. mReadInt — 16비트 또는 32비트 정수 입력 (크기에 맞게 자동 조정)

**문제 요약** 표준 입력에서 **16비트 또는 32비트 부호 있는 정수**를 읽어 인자에 저장하는 매크로를 작성하시오. **조건부 연산자**로 인자의 크기에 맞게 동작을 바꾼다.

```asm
; MacroReadInt.asm

INCLUDE Irvine32.inc

;---------------------------------------------------
; mReadInt — 인자의 크기(TYPE)에 맞게 정수를 읽어 저장한다
;---------------------------------------------------
mReadInt MACRO intVal
    IF (TYPE intVal) EQ 2
        push eax
        call ReadInt            ;; EAX = 입력한 정수
        mov  intVal,ax          ;; ⭐ 16비트면 AX만 저장
        pop  eax
    ELSEIF (TYPE intVal) EQ 4
        push eax
        call ReadInt
        mov  intVal,eax         ;; ⭐ 32비트면 EAX 전체 저장
        pop  eax
    ELSE
        ECHO mReadInt: argument must be a 16-bit or 32-bit variable
    ENDIF
ENDM

.data
wordVal  SWORD ?
dwordVal SDWORD ?
prompt1  BYTE "Enter a 16-bit integer: ",0
prompt2  BYTE "Enter a 32-bit integer: ",0

.code
main PROC
    mov  edx,OFFSET prompt1
    call WriteString
    mReadInt wordVal            ; 16비트 버전으로 펼쳐짐

    mov  edx,OFFSET prompt2
    call WriteString
    mReadInt dwordVal           ; 32비트 버전으로 펼쳐짐

    movsx eax,wordVal           ; 확인 출력
    call WriteInt
    call Crlf
    mov  eax,dwordVal
    call WriteInt
    call Crlf
    exit
main ENDP
END main
```

**펼쳐지는 모습**

| 호출 | 펼쳐진 코드 (핵심) |
|---|---|
| `mReadInt wordVal` | `call ReadInt` → **`mov wordVal,ax`** |
| `mReadInt dwordVal` | `call ReadInt` → **`mov dwordVal,eax`** |

**채점 포인트**
- **`TYPE 인자`** 로 크기를 알아내 **IF / ELSEIF** 로 분기합니다. 이 분기는 **어셈블할 때** 결정되므로 실행 파일에는 맞는 쪽 코드만 들어갑니다
- 크기가 맞지 않는 인자를 주면 **ECHO** 로 어셈블 중에 경고
- 16비트 변수에 −32,768 ~ 32,767 밖의 값을 입력하면 하위 16비트만 저장됩니다

---

### 6. mWriteInt — 바이트·워드·더블워드 정수 출력 (크기에 맞게 자동 조정)

**문제 요약** 부호 있는 정수를 WriteInt로 출력하는 매크로를 작성하시오. 인자는 **바이트·워드·더블워드** 모두 가능하고, 조건부 연산자로 크기에 맞게 동작한다.

```asm
; MacroWriteInt.asm

INCLUDE Irvine32.inc

;---------------------------------------------------
; mWriteInt — 인자의 크기에 맞게 부호 확장한 뒤 출력한다
;---------------------------------------------------
mWriteInt MACRO intVal
    push eax
    IF (TYPE intVal) LT 4
        movsx eax,intVal        ;; ⭐ 바이트·워드 → 32비트로 부호 확장
    ELSE
        mov  eax,intVal         ;; 더블워드는 그대로
    ENDIF
    call WriteInt
    pop  eax
ENDM

.data
byteVal  SBYTE  -5
wordVal  SWORD  -1000
dwordVal SDWORD 123456

.code
main PROC
    mWriteInt byteVal           ; -5
    call Crlf
    mWriteInt wordVal           ; -1000
    call Crlf
    mWriteInt dwordVal          ; +123456
    call Crlf
    exit
main ENDP
END main
```

**채점 포인트**
- WriteInt는 **EAX 전체**를 출력하므로, 작은 값은 **MOVSX로 부호 확장**해서 넣어야 합니다 (4장)
- **MOVZX를 쓰면 틀립니다.** −5(FBh)가 251로 출력됩니다
- `IF (TYPE intVal) LT 4` 하나로 바이트·워드를 함께 처리했습니다. MOVSX는 원본이 바이트든 워드든 다 받기 때문입니다 — 관계 연산자 **LT** 의 실제 사용 예입니다
- 5번(mReadInt)과 한 쌍입니다. 둘 다 **TYPE + 조건부 어셈블리**로 "크기에 맞춰 다른 코드를 펼치는" 매크로입니다

---

### 7. 교수님의 잃어버린 휴대폰

**문제 요약** 10.1.6절의 "술 취한 교수의 산책" 시뮬레이션에서, 교수가 걷는 도중 **무작위 시점에 휴대폰을 떨어뜨리게** 하시오. 실행할 때마다 떨어뜨리는 시점(과 위치)이 달라야 한다.

**설계** 교재 예제의 구조(걸음마다 위치를 COORD 배열에 기록)를 따르되 직접 다시 작성했습니다.
- 시작할 때 **휴대폰을 떨어뜨릴 걸음 번호를 난수로** 정해 둡니다
- 걷다가 그 걸음이 되면 **그때의 위치를 기록**합니다
- 산책이 끝나면 그 위치에 `P` 를 노란색으로 찍고 결과를 출력합니다

```asm
; LostPhone.asm

INCLUDE Irvine32.inc

MaxSteps = 50
StartX   = 35
StartY   = 11
MinX = 1
MaxX = 70
MinY = 1
MaxY = 22

;----- 산책 기록 구조체 -----
WalkData STRUCT
    steps     COORD MaxSteps DUP(<>)    ; 지나간 위치 (맨 앞 필드)
    phoneStep DWORD ?                   ; 휴대폰을 떨어뜨린 걸음 번호
    phonePos  COORD <>                  ; 휴대폰이 떨어진 위치
WalkData ENDS

TakeWalk PROTO, pWalk:PTR WalkData
PlotAt   PROTO, x:WORD, y:WORD, char:BYTE

.data
aWalk WalkData <>
msg1  BYTE "The phone was dropped at step ",0
msg2  BYTE ", location (",0
msg3  BYTE ", ",0
msg4  BYTE ")",0

.code
main PROC
    call Randomize
    call Clrscr
    INVOKE TakeWalk, ADDR aWalk

    ;----- 휴대폰 위치에 노란 P -----
    mov  eax,yellow + (black * 16)
    call SetTextColor
    INVOKE PlotAt, aWalk.phonePos.X, aWalk.phonePos.Y, 'P'
    mov  eax,lightGray + (black * 16)
    call SetTextColor

    ;----- 결과 메시지 -----
    mov  dh,MaxY + 2
    mov  dl,0
    call Gotoxy
    mov  edx,OFFSET msg1
    call WriteString
    mov  eax,aWalk.phoneStep
    call WriteDec
    mov  edx,OFFSET msg2
    call WriteString
    movzx eax,aWalk.phonePos.X
    call WriteDec
    mov  edx,OFFSET msg3
    call WriteString
    movzx eax,aWalk.phonePos.Y
    call WriteDec
    mov  edx,OFFSET msg4
    call WriteString
    call Crlf
    exit
main ENDP

;---------------------------------------------------
; TakeWalk
;   MaxSteps 걸음을 무작위 방향으로 걸으며 위치를 기록·표시한다.
;   걷는 도중 난수로 정한 걸음에서 휴대폰을 떨어뜨린다.
;   Receives: pWalk = WalkData 구조체 주소
;---------------------------------------------------
TakeWalk PROC USES eax ebx esi edi,
    pWalk:PTR WalkData
    LOCAL currX:WORD, currY:WORD

    mov  esi,pWalk
    mov  currX,StartX
    mov  currY,StartY

    ;----- ⭐ 휴대폰을 떨어뜨릴 걸음을 미리 정함 (0 ~ MaxSteps-1) -----
    mov  eax,MaxSteps
    call RandomRange
    mov  (WalkData PTR [esi]).phoneStep,eax

    mov  edi,esi                ; EDI = steps 배열 (구조체 맨 앞, 오프셋 0)
    mov  ebx,0                  ; EBX = 현재 걸음 번호

Again:
    ;----- 현재 위치 기록 + 표시 -----
    mov  ax,currX
    mov  (COORD PTR [edi]).X,ax
    mov  ax,currY
    mov  (COORD PTR [edi]).Y,ax
    INVOKE PlotAt, currX, currY, '*'

    ;----- ⭐ 지금이 휴대폰을 떨어뜨리는 걸음인가? -----
    cmp  ebx,(WalkData PTR [esi]).phoneStep
    jne  chooseDir
    mov  ax,currX
    mov  (WalkData PTR [esi]).phonePos.X,ax
    mov  ax,currY
    mov  (WalkData PTR [esi]).phonePos.Y,ax

chooseDir:
    ;----- 방향 0~3: 북, 남, 서, 동 (경계에 닿으면 제자리) -----
    mov  eax,4
    call RandomRange
    cmp  eax,0
    jne  notNorth
    cmp  currY,MinY
    jbe  moved
    dec  currY
    jmp  moved
notNorth:
    cmp  eax,1
    jne  notSouth
    cmp  currY,MaxY
    jae  moved
    inc  currY
    jmp  moved
notSouth:
    cmp  eax,2
    jne  isEast
    cmp  currX,MinX
    jbe  moved
    dec  currX
    jmp  moved
isEast:
    cmp  currX,MaxX
    jae  moved
    inc  currX

moved:
    mov  eax,100
    call Delay                  ; 걷는 모습이 보이도록 0.1초
    add  edi,TYPE COORD         ; 다음 기록 칸
    inc  ebx
    cmp  ebx,MaxSteps
    jb   Again
    ret
TakeWalk ENDP

;---------------------------------------------------
; PlotAt — (x, y) 위치에 문자 하나를 찍는다
;---------------------------------------------------
PlotAt PROC USES eax edx,
    x:WORD, y:WORD, char:BYTE

    mov  dl,BYTE PTR x          ; 열
    mov  dh,BYTE PTR y          ; 행
    call Gotoxy
    mov  al,char
    call WriteChar
    ret
PlotAt ENDP
END main
```

**출력 예**

```
            *****
            *   ****P*
              ...
The phone was dropped at step 17, location (38, 9)
```

**채점 포인트**
- **떨어뜨릴 시점을 미리 난수로 정해 두고**, 걸음 번호가 그 값과 같아지는 순간 위치를 기록하는 게 핵심입니다
- `Randomize` 를 시작할 때 호출하므로 **실행할 때마다 다른 시점·위치**가 나옵니다
- 구조체 필드 접근: `(WalkData PTR [esi]).phonePos.X` — 구조체 안의 구조체는 **점을 이어서**
- 경계 검사를 넣어 커서 좌표가 음수가 되지 않게 했습니다
- 루프 본문이 길어서 LOOP 대신 **`inc` / `cmp` / `jb`** 를 썼습니다. LOOP는 **−128 ~ +127바이트** 안으로만 점프할 수 있어서 본문이 길면 어셈블 오류가 납니다

---

### 8. 방향 확률이 있는 술 취한 산책

**문제 요약** 4방향이 같은 확률이면 교수가 출발점에서 멀리 가지 못한다. **50% 확률로 직전과 같은 방향**, **10% 확률로 반대 방향**, **20% 확률로 오른쪽**, **20% 확률로 왼쪽**으로 걷게 바꾸시오. 루프 전에 기본 방향을 정한다.

**설계 아이디어 — 방향을 시계 방향 순서로 번호 매기기**

```
        북(0)
  서(3)   +   동(1)
        남(2)
```

이렇게 매기면 **회전이 덧셈 하나**로 끝납니다.

| 동작 | 계산 |
|---|---|
| 같은 방향 | `dir` |
| 오른쪽으로 돌기 | `(dir + 1) AND 3` |
| 반대로 돌기 | `(dir + 2) AND 3` |
| 왼쪽으로 돌기 | `(dir + 3) AND 3` |

`AND 3` 은 **mod 4** 입니다 (7장: n mod 2ᵏ = n AND (2ᵏ − 1)).

**확률 나누기** — `RandomRange(10)` 의 결과 0~9를

| 값 | 비율 | 동작 |
|---|:---:|---|
| 0 ~ 4 | 50% | 같은 방향 |
| 5 | 10% | 반대 |
| 6 ~ 7 | 20% | 오른쪽 |
| 8 ~ 9 | 20% | 왼쪽 |

```asm
; WalkProb.asm

INCLUDE Irvine32.inc

MaxSteps = 50
StartX   = 35
StartY   = 11
MinX = 1
MaxX = 70
MinY = 1
MaxY = 22

NORTH = 0                       ; 시계 방향 순서
EAST  = 1
SOUTH = 2
WEST  = 3

WalkData STRUCT
    steps COORD MaxSteps DUP(<>)
WalkData ENDS

TakeWalk PROTO, pWalk:PTR WalkData
NextDir  PROTO, dir:DWORD
PlotAt   PROTO, x:WORD, y:WORD, char:BYTE

.data
aWalk WalkData <>

.code
main PROC
    call Randomize
    call Clrscr
    INVOKE TakeWalk, ADDR aWalk
    mov  dh,MaxY + 2
    mov  dl,0
    call Gotoxy
    exit
main ENDP

;---------------------------------------------------
; NextDir
;   직전 방향을 받아 다음 방향을 정한다.
;     50% 같은 방향 / 10% 반대 / 20% 오른쪽 / 20% 왼쪽
;   Receives: dir = 직전 방향 (0~3)
;   Returns:  EAX = 새 방향 (0~3)
;---------------------------------------------------
NextDir PROC USES ebx,
    dir:DWORD

    mov  ebx,dir
    mov  eax,10
    call RandomRange            ; EAX = 0 ~ 9
    cmp  eax,5
    jb   same                   ; 0~4 → 같은 방향 (50%)
    je   reverse                ; 5   → 반대 (10%)  ⭐ 같은 CMP의 플래그 재사용
    cmp  eax,8
    jb   turnRight              ; 6~7 → 오른쪽 (20%)
                                ; 8~9 → 왼쪽 (20%)
    add  ebx,3                  ; 왼쪽 = +3
    jmp  wrap
turnRight:
    add  ebx,1                  ; 오른쪽 = +1
    jmp  wrap
reverse:
    add  ebx,2                  ; 반대 = +2
wrap:
    and  ebx,3                  ; ⭐ mod 4
same:
    mov  eax,ebx
    ret
NextDir ENDP

;---------------------------------------------------
; TakeWalk — 방향 확률을 적용해 MaxSteps 걸음을 걷는다
;---------------------------------------------------
TakeWalk PROC USES eax ecx edi,
    pWalk:PTR WalkData
    LOCAL currX:WORD, currY:WORD, dir:DWORD

    mov  currX,StartX
    mov  currY,StartY
    mov  dir,NORTH              ; ⭐ 루프 전에 기본 방향 지정
    mov  edi,pWalk              ; steps는 구조체 맨 앞
    mov  ecx,MaxSteps

Again:
    mov  ax,currX
    mov  (COORD PTR [edi]).X,ax
    mov  ax,currY
    mov  (COORD PTR [edi]).Y,ax
    INVOKE PlotAt, currX, currY, '*'

    INVOKE NextDir, dir         ; 다음 방향 결정
    mov  dir,eax

    ;----- 방향대로 한 칸 (경계에서는 제자리) -----
    cmp  eax,NORTH
    jne  notN
    cmp  currY,MinY
    jbe  moved
    dec  currY
    jmp  moved
notN:
    cmp  eax,EAST
    jne  notE
    cmp  currX,MaxX
    jae  moved
    inc  currX
    jmp  moved
notE:
    cmp  eax,SOUTH
    jne  isW
    cmp  currY,MaxY
    jae  moved
    inc  currY
    jmp  moved
isW:
    cmp  currX,MinX
    jbe  moved
    dec  currX

moved:
    mov  eax,100
    call Delay
    add  edi,TYPE COORD
    dec  ecx
    jnz  Again                  ; 본문이 길어서 LOOP 대신 DEC + JNZ
    ret
TakeWalk ENDP

;---------------------------------------------------
; PlotAt — 7번과 동일
;---------------------------------------------------
PlotAt PROC USES eax edx,
    x:WORD, y:WORD, char:BYTE
    mov  dl,BYTE PTR x
    mov  dh,BYTE PTR y
    call Gotoxy
    mov  al,char
    call WriteChar
    ret
PlotAt ENDP
END main
```

**회전 검산**

| 현재 | 반대 | 오른쪽 | 왼쪽 |
|:---:|:---:|:---:|:---:|
| 북(0) | 남(2) | 동(1) | 서(3) |
| 동(1) | 서(3) | 남(2) | 북(0) |
| 남(2) | 북(0) | 서(3) | 동(1) |
| 서(3) | 동(1) | 북(0) | 남(2) |

**채점 포인트**
- **방향 번호를 시계 방향 순서**로 정한 것이 이 문제의 열쇠입니다. 그러면 오른쪽 = +1, 반대 = +2, 왼쪽 = +3 이 되고, `AND 3` 으로 0~3 범위로 되돌립니다
- 확률은 **RandomRange(10)의 결과를 구간으로 나눠서** 만듭니다
- `cmp eax,5` 다음에 `jb` 와 `je` 를 이어 쓰면 **비교 한 번으로 두 갈래**를 판정합니다 (9장 단답 13번과 같은 원리)
- 직전 방향을 **지역 변수 dir** 에 보관해야 다음 걸음에서 "같은 방향"을 알 수 있습니다

> 실행해 보면 7번(균등 확률)보다 **훨씬 멀리, 직선에 가깝게** 걸어갑니다. 50% 확률로 같은 방향을 유지하기 때문입니다.

---

### 9. mShiftDoublewords — 더블워드 배열 전체를 여러 비트 시프트

**문제 요약** **SHRD와 SHLD**로 32비트 정수 배열 전체를 **지정한 방향(R/L)으로 지정한 비트 수만큼** 시프트하는 매크로를 작성하시오. 배열은 리틀엔디언(0번 원소가 최하위)이다. 같은 배열을 양쪽으로 시프트해 결과를 출력하는 테스트 프로그램도 작성한다.

**원리** (7장 단답 6번 SHLD/SHRD의 확장)

| 방향 | 처리 순서 | 각 원소 | 마지막 원소 |
|---|---|---|---|
| **오른쪽 (R)** | **최하위 원소부터 위로** | `SHRD 현재, 위쪽원소, n` — 빈 상위 비트를 위쪽 원소의 하위 비트로 채움 | 최상위는 `SHR` (0으로 채움) |
| **왼쪽 (L)** | **최상위 원소부터 아래로** | `SHLD 현재, 아래원소, n` — 빈 하위 비트를 아래 원소의 상위 비트로 채움 | 최하위는 `SHL` |

> 순서가 중요합니다. **아직 바뀌지 않은 이웃 원소**에서 비트를 가져와야 하기 때문입니다 (7장 다중 바이트 시프트와 같은 규칙: 비트가 가는 방향의 반대쪽에서 시작).

```asm
; ShiftDwords.asm

INCLUDE Irvine32.inc

;---------------------------------------------------
; mShiftDoublewords — 더블워드 배열 전체를 numberOfBits(1~31)만큼 시프트
;   direction: R (오른쪽) 또는 L (왼쪽)
;---------------------------------------------------
mShiftDoublewords MACRO arrayName, direction, numberOfBits
    LOCAL rLoop, rLast, lLoop, lLast
    push eax
    push ecx
    push edx
    push esi
    mov  cl,numberOfBits                ;; 시프트 횟수는 CL (SHRD/SHLD 규칙)
    mov  edx,LENGTHOF arrayName - 1     ;; 이웃이 있는 원소 개수

  IFIDNI <direction>,<R>
    ;;----- 오른쪽: 최하위 원소부터 위로 -----
    mov  esi,OFFSET arrayName
rLoop:
    test edx,edx
    jz   rLast
    mov  eax,[esi+4]                    ;; 바로 위(상위) 원소
    shrd DWORD PTR [esi],eax,cl         ;; ⭐ 빈 상위 비트 ← 위 원소의 하위 비트
    add  esi,4
    dec  edx
    jmp  rLoop
rLast:
    shr  DWORD PTR [esi],cl             ;; 최상위 원소는 0으로 채움

  ELSEIFIDNI <direction>,<L>
    ;;----- 왼쪽: 최상위 원소부터 아래로 -----
    mov  esi,OFFSET arrayName + SIZEOF arrayName - 4
lLoop:
    test edx,edx
    jz   lLast
    mov  eax,[esi-4]                    ;; 바로 아래(하위) 원소
    shld DWORD PTR [esi],eax,cl         ;; ⭐ 빈 하위 비트 ← 아래 원소의 상위 비트
    sub  esi,4
    dec  edx
    jmp  lLoop
lLast:
    shl  DWORD PTR [esi],cl             ;; 최하위 원소는 0으로 채움

  ELSE
    ECHO mShiftDoublewords: direction must be R or L
  ENDIF

    pop  esi
    pop  edx
    pop  ecx
    pop  eax
ENDM

.data
array DWORD 12345678h, 9ABCDEF0h, 0FEDCBA9h     ; 0번 원소가 최하위
msg0  BYTE "Original  : ",0
msg1  BYTE "Right 4   : ",0
msg2  BYTE "Then left 4: ",0

.code
main PROC
    mov  edx,OFFSET msg0
    call WriteString
    call ShowArray

    mShiftDoublewords array, R, 4
    mov  edx,OFFSET msg1
    call WriteString
    call ShowArray

    mShiftDoublewords array, L, 4
    mov  edx,OFFSET msg2
    call WriteString
    call ShowArray
    exit
main ENDP

;---------------------------------------------------
; ShowArray — 최상위 원소부터 16진수로 출력 (하나의 큰 수처럼 읽힘)
;---------------------------------------------------
ShowArray PROC USES eax ecx esi
    mov  esi,OFFSET array + SIZEOF array - 4
    mov  ecx,LENGTHOF array
L1:
    mov  eax,[esi]
    call WriteHex
    mov  al,' '
    call WriteChar
    sub  esi,4
    loop L1
    call Crlf
    ret
ShowArray ENDP
END main
```

**실행 결과** (최상위 원소부터 표시)

```
Original   : 0FEDCBA9 9ABCDEF0 12345678
Right 4    : 00FEDCBA 99ABCDEF 01234567
Then left 4: 0FEDCBA9 9ABCDEF0 12345670
```

> 오른쪽으로 밀 때 최하위 니블 `8` 이 밀려 나가 사라졌기 때문에, 다시 왼쪽으로 밀면 마지막 자리가 `0` 이 됩니다. 시프트는 회전과 달리 **밀려 나간 비트를 되찾을 수 없습니다.**

**채점 포인트**
- SHRD/SHLD의 가변 횟수는 **CL** 에만 넣을 수 있습니다. 그래서 루프 카운터로 ECX 대신 **EDX** 를 썼습니다
- 방향 문자는 **`IFIDNI`** (대소문자 무시 텍스트 비교)로 판단합니다. 인자를 **따옴표 없이** `R` 로 넘겨야 `<R>` 과 같다고 판정됩니다
- 매크로 안의 레이블 4개는 모두 **LOCAL**
- 매크로가 쓰는 EAX, ECX, EDX, ESI를 **모두 보존**

---

### 10. 세 피연산자 명령어 매크로 (add3, sub3, mul3, div3)

**문제 요약** `대상 = 원본1 연산 원본2` 형태의 세 피연산자 명령을 흉내 내는 매크로 네 개를 작성하시오. **EAX는 매크로 전용**이라 보존하지 않고, **다른 레지스터는 보존**한다. 모든 매개변수는 부호 있는 메모리 더블워드다. 여러 연산이 섞인 식 4개로 테스트한다.

```asm
; ThreeOperand.asm

INCLUDE Irvine32.inc

;---------------------------------------------------
; 세 피연산자 매크로 — EAX는 보존하지 않음
;---------------------------------------------------
add3 MACRO destination, source1, source2
    mov  eax,source1
    add  eax,source2
    mov  destination,eax
ENDM

sub3 MACRO destination, source1, source2
    mov  eax,source1
    sub  eax,source2
    mov  destination,eax
ENDM

mul3 MACRO destination, source1, source2
    mov  eax,source1
    imul eax,source2            ;; ⭐ 2-피연산자 IMUL — EDX를 건드리지 않음
    mov  destination,eax
ENDM

div3 MACRO destination, source1, source2
    push edx                    ;; ⭐ IDIV가 EDX를 쓰므로 보존
    mov  eax,source1
    cdq                         ;; ⭐ 부호 확장 (7장)
    idiv source2
    mov  destination,eax        ;; 몫
    pop  edx
ENDM

.data
w  SDWORD 10
y  SDWORD 5
z  SDWORD 3
k  SDWORD 4
t1 SDWORD ?                     ; 중간 결과용
t2 SDWORD ?
x1 SDWORD ?
x2 SDWORD ?
x3 SDWORD ?
x4 SDWORD ?

.code
main PROC
    ;----- x1 = (w + y) * z -----
    add3 t1, w, y               ; t1 = 15
    mul3 x1, t1, z              ; x1 = 45

    ;----- x2 = (w * z) - (y * k) -----
    mul3 t1, w, z               ; t1 = 30
    mul3 t2, y, k               ; t2 = 20
    sub3 x2, t1, t2             ; x2 = 10

    ;----- x3 = (w + y) / (z - k) -----
    add3 t1, w, y               ; t1 = 15
    sub3 t2, z, k               ; t2 = -1
    div3 x3, t1, t2             ; x3 = -15

    ;----- x4 = (y - w) * (z + k) -----
    sub3 t1, y, w               ; t1 = -5
    add3 t2, z, k               ; t2 = 7
    mul3 x4, t1, t2             ; x4 = -35

    ;----- 결과 출력 -----
    mov  eax,x1
    call WriteInt               ; +45
    call Crlf
    mov  eax,x2
    call WriteInt               ; +10
    call Crlf
    mov  eax,x3
    call WriteInt               ; -15
    call Crlf
    mov  eax,x4
    call WriteInt               ; -35
    call Crlf
    exit
main ENDP
END main
```

**검산** (w = 10, y = 5, z = 3, k = 4)

| 식 | 계산 | 결과 |
|---|---|:---:|
| x1 = (w + y) × z | 15 × 3 | **45** |
| x2 = (w × z) − (y × k) | 30 − 20 | **10** |
| x3 = (w + y) ÷ (z − k) | 15 ÷ (−1) | **−15** |
| x4 = (y − w) × (z + k) | (−5) × 7 | **−35** |

**채점 포인트**
- **메모리 → 메모리 연산이 불가능**하므로 모든 매크로가 EAX를 경유합니다. 문제가 "EAX는 매크로 전용"이라고 한 이유입니다
- **mul3은 2-피연산자 IMUL** 을 쓰면 EDX를 건드리지 않아 보존할 필요가 없습니다
- **div3은 IDIV 앞에 반드시 CDQ.** `mov edx,0` 을 쓰면 음수에서 틀립니다 (x3 = −15를 확인하는 테스트를 일부러 넣었습니다)
- IDIV가 EDX를 덮어쓰므로 div3만 **EDX를 PUSH/POP**
- 부호 있는 데이터이므로 MUL/DIV가 아니라 **IMUL/IDIV**

> 💡 이 매크로들은 "명령어 세트를 매크로로 확장하는" 예입니다. 컴파일러의 중간 언어(3-주소 코드)가 이런 모양입니다.

---

# 10장 시험 대비 요점

## 가장 많이 틀리는 7가지

| # | 함정 | 정답 |
|:---:|---|---|
| 1 | **구조체 변수 선언 순서** | **`이름 구조체타입 <초기값>`**. 타입이 앞에 오면 무효 |
| 2 | **초기값 개수** | 필드 수보다 **많으면 오류**. 쉼표로 건너뛴 빈 자리도 한 개로 셈 |
| 3 | **중첩 구조체 초기화** | **꺾쇠 안에 꺾쇠**: `< <0,0>, <5,0> >` |
| 4 | **간접 필드 접근** | `(COORD PTR [esi]).X` — **PTR로 타입을 알려 줘야** 함 |
| 5 | **매크로 안의 레이블** | **LOCAL 필수**. 없으면 두 번째 호출에서 중복 오류 |
| 6 | **두 가지 LOCAL** | PROC 안 = **지역 변수**, MACRO 안 = **고유 레이블** |
| 7 | **IF는 어셈블 시간** | 변수의 실행 시간 값은 검사 못 함. **상수와 인자 텍스트만** |

## 네 가지 특수 연산자 ⭐⭐⭐

| 연산자 | 이름 | 한 줄 예 |
|:---:|---|---|
| `&` | 치환 | `"Reg: &regName"` → `"Reg: EAX"` |
| `<>` | 리터럴 텍스트 | `mMacro <a, b c>` → 공백·쉼표가 있어도 인자 하나 |
| `!` | 리터럴 문자 | `<x !> 0>` → `>` 를 글자로 |
| `%` | 확장 | `%(COUNT*2)` → 계산한 값 `20` |

## 매크로 작성 체크리스트

```asm
mExample MACRO param1, param2:REQ, param3 := <0>
    LOCAL L1, msg                   ;; ① LOCAL은 MACRO 바로 다음 줄
    push eax                        ;; ② 쓰는 레지스터 보존 (반환용 제외)
    .data
    msg BYTE "Value of &param1",0   ;; ③ 데이터 정의 가능, & 로 치환
    .code
    IF param3 LT 0                  ;; ④ 조건부 어셈블리 (상수만)
        ECHO param3 must not be negative
        EXITM
    ENDIF
L1: ...                             ;; ⑤ LOCAL로 선언한 레이블
    pop  eax
ENDM                                ;; ⑥ ENDM으로 끝
```

| 줄 | 규칙 |
|:---:|---|
| ① | `LOCAL` 은 **MACRO 바로 다음** |
| ② | 매크로가 바꾸는 레지스터는 **PUSH/POP** (반환 레지스터 제외) |
| ③ | 문자열 안의 매개변수는 **`&`** |
| ④ | 조건 검사는 **`IF` … `ENDIF`**, 메시지는 **`ECHO`** |
| ⑤ | 레이블은 **LOCAL** |
| ⑥ | 끝은 **`ENDM`** (프로시저는 `ENDP`, 구조체는 `ENDS`) |

> ⚠️ **끝 지시어 세 가지를 헷갈리지 마세요**: 구조체 **`ENDS`**, 프로시저 **`ENDP`**, 매크로 **`ENDM`**

## 구조체 문법 한눈에

```asm
Point STRUCT                        ; 정의
    X WORD ?
    Y WORD ?
Point ENDS

Line STRUCT                         ; 구조체 안의 구조체
    p1 Point <>
    p2 Point <>
Line ENDS

.data
pt   Point <3,4>                    ; 선언 (이름 먼저!)
ln   Line < <0,0>, <10,5> >         ; 중첩 초기화
pts  Point 10 DUP(<0,0>)            ; 배열

.code
mov  ax,pt.X                        ; 직접 접근
mov  ax,ln.p2.Y                     ; 중첩 접근
mov  esi,OFFSET pts
mov  ax,(Point PTR [esi]).Y         ; 간접 접근
add  esi,TYPE Point                 ; 다음 원소 (4바이트)
```

## 출제 예상 (교수님 2/2/1~2 배분 기준)

| 섹션 | ★★★ 우선 | 이유 |
|---|---|---|
| **10.7.1 단답형** | **2** | 구조체 선언 유효성 — 함정이 두 개(순서, 개수) |
| | **4, 5, 6, 7** | LOCAL, ECHO, ENDIF, 관계 연산자 — 한 단어로 답함 |
| | **8, 9, 10** | 특수 연산자 세 개 — 한 세트로 나오기 쉬움 |
| **10.7.2 알고리즘** | **1, 3** | 구조체 정의·중첩 초기화 — 한두 줄 |
| | **5, 6** | 짧은 매크로 작성 |
| | **9, 10, 16** | 매크로 펼치기 — 계산 문제처럼 답이 명확 |
| **10.8 프로그래밍** | **3, 4** | mMove32, mMult32 — 매크로 본문이 2~3줄 |
| | **10** | 세 피연산자 매크로 — 짧고 4장·7장 개념까지 확인 |
| | **5, 6** | TYPE + 조건부 어셈블리 — 10장의 특징을 가장 잘 보여 줌 |

> 중간고사 패턴(짧은 단답 + 프로그래밍 1개)을 그대로 적용하면, 10장에서는 **구조체 선언 유효성 또는 특수 연산자 단답 1문제 + 매크로 펼치기 또는 구조체 초기화 1문제 + 짧은 매크로 작성 1개** 조합이 가장 유력합니다.
