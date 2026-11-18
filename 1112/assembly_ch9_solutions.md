# 9장 문자열과 배열 (Strings and Arrays) — 연습문제 풀이

> Kip Irvine, *Assembly Language for x86 Processors* 7판, 9.9절~9.10절
> 문제는 한국어로 요약했습니다. 원문은 교재 384~389쪽을 함께 보세요.
>
> 구성: **9.9.1 단답형 14문제 + 9.9.2 알고리즘 연습 12문제 + 9.10 프로그래밍 과제 14문제**

---

## 들어가기 전에 — 9장 핵심 표 4개

### ① 문자열 기본 명령어 5종 ⭐⭐⭐

| 명령어 | 동작 | 쓰는 레지스터 |
|---|---|---|
| `MOVSB/W/D` | `[ESI]` → `[EDI]` **복사** | ESI, EDI |
| `CMPSB/W/D` | `[ESI]` 와 `[EDI]` **비교** | ESI, EDI |
| `SCASB/W/D` | **AL/AX/EAX** 와 `[EDI]` **비교** (찾기) | EDI |
| `STOSB/W/D` | **AL/AX/EAX** → `[EDI]` **저장** (채우기) | EDI |
| `LODSB/W/D` | `[ESI]` → **AL/AX/EAX** **읽기** | ESI |

> **외우는 법**
> - **ESI = Source(읽는 쪽)**, **EDI = Destination(쓰는/비교 대상 쪽)**
> - **SCAS와 STOS는 EDI만**, **LODS는 ESI만** 씁니다
> - 실행할 때마다 ESI/EDI가 **B=1, W=2, D=4** 만큼 자동으로 움직입니다

### ② 방향 플래그 (DF)

| 명령 | DF | ESI/EDI 이동 |
|---|:---:|---|
| `CLD` | 0 | **증가** (앞 → 뒤) |
| `STD` | 1 | **감소** (뒤 → 앞) |

> ⚠️ **DF가 어떤 상태인지 가정하지 마세요.** 문자열 명령을 쓰기 전에는 **항상 `CLD`(또는 `STD`)를 직접** 실행합니다.

### ③ 반복 접두사 ⭐⭐

| 접두사 | 반복 조건 | 주로 같이 쓰는 명령 |
|---|---|---|
| `REP` | ECX > 0 인 동안 | `MOVS`, `STOS` (복사, 채우기) |
| `REPE` / `REPZ` | ECX > 0 **이고 같은 동안** (ZF=1) | `CMPS` (**다른 곳 찾기**) |
| `REPNE` / `REPNZ` | ECX > 0 **이고 다른 동안** (ZF=0) | `SCAS` (**같은 것 찾기**) |

> 반복할 때마다 **ECX가 1씩 감소**합니다.
>
> **헷갈리지 않는 법: 접두사 이름은 "언제까지 계속하는가"입니다.**
> - REPE = 같으면 계속 → **처음으로 다른 곳에서 멈춤**
> - REPNE = 다르면 계속 → **처음으로 같은 곳에서 멈춤**

### ④ 멈춘 뒤 ESI/EDI의 위치 ⭐⭐⭐

```
문자열 "HELLO" 에서 REPNE SCASB 로 'L' 을 찾으면

   H   E   L   L   O
           ↑   ↑
         찾은  EDI가 여기를 가리킴
         위치  (한 칸 지나침)
```

> **문자열 명령은 비교한 뒤에 포인터를 움직입니다.** 그래서 멈췄을 때 EDI는 항상 **찾은 위치의 다음 칸**에 있습니다. 찾은 위치를 얻으려면 **원소 크기만큼 빼야** 합니다 (`dec edi`, `sub edi,2`, `sub edi,4`).

---

## 9.9.1 단답형 (Short Answer)

### 1. 문자열 기본 명령을 실행할 때 인덱스 레지스터가 메모리를 거꾸로 움직이게 하는 방향 플래그 설정은?

**정답: DF = 1** (`STD` 명령으로 설정)

ESI와 EDI가 **감소**하며 높은 주소에서 낮은 주소로 이동합니다.

---

### 2. STOSW에 반복 접두사를 붙이면 인덱스 레지스터에 얼마가 더해지거나 빠지는가?

**정답: 2**

STOSW는 **워드(2바이트)** 단위이므로 반복마다 EDI가 **2씩** 움직입니다. DF=0이면 +2, DF=1이면 −2.

| 접미사 | 크기 | 이동량 |
|:---:|---|:---:|
| B | 바이트 | 1 |
| **W** | **워드** | **2** |
| D | 더블워드 | 4 |

---

### 3. CMPS 명령은 어떤 점에서 모호한가?

**정답: 비교 순서가 CMP와 반대처럼 보입니다.**

- 일반 `CMP 대상, 원본` 은 **대상 − 원본** 으로 플래그를 정합니다
- `CMPS` 는 **`[ESI] − [EDI]`**, 즉 **원본(ESI) − 대상(EDI)** 으로 플래그를 정합니다

ESI가 "원본(source)", EDI가 "대상(destination)"이라는 이름 때문에 CMP처럼 "대상과 원본을 비교한다"고 생각하기 쉬운데, 실제로는 **원본이 앞**에 옵니다. 그래서 조건 점프의 방향을 **거꾸로 해석하는 실수**가 생깁니다.

```asm
    mov  esi,OFFSET source
    mov  edi,OFFSET target
    cmpsd                       ; [ESI] - [EDI] 로 플래그 설정
    ja   L1                     ; ⭐ source > target 일 때 점프
```

> **"CMPS는 ESI가 왼쪽"** 이라고 외우세요. `JA` 는 `source > target` 입니다.

---

### 4. DF가 0이고 SCASB가 일치하는 문자를 찾았을 때 EDI는 어디를 가리키는가?

**정답: 찾은 문자의 바로 다음 바이트**

SCASB는 비교를 끝낸 **뒤에** EDI를 1 증가시킵니다. 그래서 찾은 위치를 얻으려면 `dec edi` 가 필요합니다.

```asm
    repne scasb
    jnz  notFound
    dec  edi                    ; ⭐ EDI = 찾은 문자의 주소
```

---

### 5. 배열에서 특정 문자가 처음 나오는 곳을 찾을 때 가장 알맞은 반복 접두사는?

**정답: `REPNE` (= `REPNZ`)**

"**같지 않은 동안 계속**" 스캔하다가 **처음으로 같은 문자를 만나면 멈춥니다.** 찾기에 딱 맞는 동작입니다.

---

### 6. 9.3절의 Str_trim 프로시저는 방향 플래그를 어떻게 설정하는가?

**정답: 7판의 Str_trim은 문자열 기본 명령을 쓰지 않으므로 방향 플래그와 무관합니다.**

7판 구현은 문자열 끝에서부터 `MOV` / `CMP` / `DEC EDI` / `LOOP` 로 **직접 한 칸씩 뒤로** 움직입니다. SCAS 같은 명령을 쓰지 않으니 DF가 어떤 값이든 상관없습니다.

> 💡 같은 일을 **SCASB로 뒤에서부터 스캔**하는 방식으로 구현한다면 EDI가 감소해야 하므로 **`STD` (DF = 1)** 를 써야 합니다. 이전 판의 Str_trim이 이 방식이었습니다. 시험에서는 두 가지를 함께 써 주면 안전합니다.

---

### 7. Str_trim 프로시저는 왜 JNE 명령을 쓰는가?

**정답: 끝에서부터 거꾸로 보다가 지울 문자가 "아닌" 첫 문자를 만나는 순간 루프를 빠져나오기 위해서입니다.**

동작 순서는 이렇습니다.

1. 문자열의 **마지막 문자**부터 시작
2. 지울 문자와 **같으면** → 한 칸 뒤로 가서 계속
3. **다르면(JNE)** → 거기가 **남겨야 할 마지막 문자**이므로 루프 탈출
4. 그 바로 다음 칸에 **null을 써 넣어** 뒤를 잘라냄

```
"Hello##"  에서 '#' 제거

 H  e  l  l  o  #  #
             ↑  ←  ←  끝에서부터 거꾸로
             'o' ≠ '#'  → JNE 로 탈출
             그 다음 칸에 null → "Hello"
```

> JNE가 **"멈출 지점"** 을 찾는 역할입니다. 같은 동안은 계속, 다르면 정지.

---

### 8. 대상 문자열에 숫자가 들어 있으면 Str_ucase 프로시저에서 어떻게 되는가?

**정답: 아무 변화 없이 그대로 남습니다.**

Str_ucase는 문자가 **`'a'` 이상 `'z'` 이하**일 때만 비트 5를 지워 대문자로 바꿉니다. 숫자 `'0'`~`'9'`(30h~39h)는 이 범위 밖이라 **변환을 건너뜁니다.** 기호, 공백, 이미 대문자인 글자도 마찬가지입니다.

> 범위 검사 없이 무조건 `and al,11011111b` 를 하면 숫자가 망가집니다. 예: `'1'`(31h) → 11h (제어 문자). 범위 검사가 필요한 이유입니다.

---

### 9. Str_length가 SCASB를 쓴다면 어떤 반복 접두사가 가장 알맞은가?

**정답: `REPNE` (= `REPNZ`)**

AL = 0 으로 두고 **null 바이트를 만날 때까지** 스캔하면 됩니다. "0이 아닌 동안 계속" = REPNE.

---

### 10. Str_length가 SCASB를 쓴다면 길이를 어떻게 계산해서 반환하는가?

**정답: null을 찾은 뒤 `EDI − 시작 주소 − 1` 이 길이입니다.**

```asm
Str_length PROC USES ecx edi,
    pString:PTR BYTE

    mov  edi,pString
    mov  al,0                   ; 찾을 값 = null
    mov  ecx,-1                 ; 사실상 무제한 (FFFFFFFFh)
    cld
    repne scasb                 ; null을 찾을 때까지 스캔
    mov  eax,edi
    sub  eax,pString            ; null 다음 위치 - 시작
    dec  eax                    ; null 자체는 빼기
    ret
Str_length ENDP
```

**검산** `"ABC"` 가 100번지에 있으면

```
A(100) B(101) C(102) null(103)
REPNE SCASB 가 null을 찾으면 EDI = 104 (한 칸 지나침)
길이 = 104 - 100 - 1 = 3  ✔
```

> 💡 ECX로도 계산할 수 있습니다. 반복할 때마다 ECX가 1씩 줄었으므로 **길이 = (NOT ECX) − 1**.

---

### 11. 원소가 1,024개인 배열에서 이진 탐색의 최대 비교 횟수는?

**정답: 10번**

이진 탐색은 비교할 때마다 범위를 **절반**으로 줄이므로 최대 비교 횟수는 **log₂ n** 입니다.

```
1024 → 512 → 256 → 128 → 64 → 32 → 16 → 8 → 4 → 2 → 1
       1     2     3     4    5    6    7   8   9   10번
```

| 원소 개수 | 순차 탐색 | 이진 탐색 |
|---|---|---|
| 64 | 64 | 6 |
| **1,024** | **1,024** | **10** |
| 65,536 | 65,536 | 16 |

> **2¹⁰ = 1024** 이므로 바로 10이 나옵니다. 1장의 2의 거듭제곱 표가 여기서 쓰입니다.

---

### 12. 9.5절 이진 탐색 예제의 FillArray에서 왜 CLD로 방향 플래그를 지워야 하는가?

**정답: FillArray는 STOSD로 배열을 채우는데, DF가 1이면 EDI가 거꾸로 움직여 배열 밖(앞쪽 메모리)을 덮어쓰기 때문입니다.**

- FillArray는 난수를 하나 만들 때마다 **STOSD** 로 `[EDI]` 에 저장하고 EDI를 이동시킵니다
- DF = 0 이어야 EDI가 **+4씩** 배열 끝 방향으로 갑니다
- 프로시저가 시작될 때 DF가 몇인지는 **알 수 없습니다** (호출한 쪽이나 다른 코드가 STD를 해 뒀을 수 있음)
- 그래서 **직접 CLD를 실행해서 확실하게** 만드는 겁니다

> 방향 플래그는 "기본값이 0일 것"이라고 믿으면 안 되는 대표적인 상태입니다.

---

### 13. BinarySearch 프로시저에서 레이블 L2의 문장을 지워도 결과가 같은 이유는?

**정답: L2의 `CMP` 는 바로 앞에서 했던 비교를 똑같이 반복하는 것이고, 그 사이에 플래그가 바뀌지 않았기 때문입니다.**

BinarySearch의 흐름은 이렇습니다.

```
cmp  values[mid], searchVal     ← 첫 번째 비교
jge  L2                         ← "작지 않으면" L2로
   ...  (작은 경우: first = mid+1)
L2: cmp values[mid], searchVal  ← ⭐ 같은 두 값을 또 비교
    jle  L3                     ← "크지 않으면"(= 같으면) L3로
```

- L2에는 **`jge L2` 로만** 도착합니다
- **점프 명령은 플래그를 바꾸지 않습니다**
- 따라서 L2에 도착했을 때 플래그는 **첫 번째 CMP의 결과 그대로**입니다
- 같은 값을 다시 비교해도 **똑같은 플래그**가 나오므로 L2의 CMP는 **없어도 됩니다** (교재 주석에도 "optional"이라고 되어 있습니다)

> 지울 때는 **레이블 L2 자체는 남겨서** 다음 줄(`jle L3`)에 붙여야 합니다. `jge L2` 가 점프할 곳이 필요하니까요.

---

### 14. BinarySearch 프로시저에서 레이블 L4의 문장을 어떻게 없앨 수 있는가?

**정답: L4로 가는 `jmp L4` 들을 전부 `jmp L1` 로 바꾸면 됩니다.**

L4에는 `jmp L1` 한 줄만 있습니다. 즉 다른 곳에서 **L4로 점프 → 다시 L1로 점프**하는 "점프의 점프"입니다.

```
변경 전                         변경 후
  ...                             ...
  jmp L4      ──┐                 jmp L1     ← 바로 L1로
  ...           │                 ...
  jmp L4      ──┤                 jmp L1     ← 바로 L1로
  ...           │                 ...
L4: jmp L1  ◄──┘                 (L4 삭제)
```

L4 바로 앞 문장은 `jmp L9` 이므로 **L4로 흘러 들어오는 경로도 없습니다.** 그래서 L4를 통째로 지워도 됩니다.

> 💡 13번과 14번은 "**불필요한 비교**"와 "**불필요한 점프**"를 찾는 문제입니다. 아래 프로그래밍 과제 9번에서 이 두 가지를 모두 정리한 이진 탐색을 만들어 봤습니다.

---

## 9.9.2 알고리즘 연습 (Algorithm Workbench)

### 1. 32비트 모드의 base-index 피연산자 예

```asm
mov eax,[ebx+esi]
```

**구조** `[기준 레지스터 + 인덱스 레지스터]`

> 2차원 배열에서 **EBX = 행의 시작 오프셋**, **ESI = 열 위치** 로 쓰는 게 전형적인 용도입니다.

---

### 2. 32비트 모드의 base-index-displacement 피연산자 예

```asm
mov eax,table[ebx+esi]          ; 변위 = 변수 이름(table의 주소)
mov eax,[ebx+esi+8]             ; 변위 = 상수 8
```

**구조** `변위[기준 + 인덱스]` 또는 `[기준 + 인덱스 + 변위]`

| 형태 | 예 |
|---|---|
| base-index | `[ebx+esi]` |
| **base-index-displacement** | `table[ebx+esi]` |
| 비례 계수 추가 | `table[ebx+esi*4]` |

---

### 3. 3행 × 4열 더블워드 2차원 배열에서 2번 행(두 번째 행)의 3번 열(세 번째 열)을 ESI와 EDI로 지정

행과 열 번호는 **0부터** 셉니다 → **행 1, 열 2**

**계산**

```
한 행의 크기 = 4열 × 4바이트 = 16바이트
행 1의 시작   = 1 × 16 = 16
열 2의 위치   = 2 × 4  = 8
전체 오프셋   = 16 + 8 = 24
```

**정답**

```asm
    mov  esi,1 * 16             ; ESI = 행 오프셋 (행 번호 × 행 크기)
    mov  edi,2 * 4              ; EDI = 열 오프셋 (열 번호 × 원소 크기)
    mov  eax,array[esi+edi]     ; array + 24
```

**비례 계수를 쓰면 더 깔끔합니다**

```asm
    mov  esi,16                 ; 행 오프셋
    mov  edi,2                  ; 열 번호 그대로
    mov  eax,array[esi+edi*4]   ; ⭐ 열 번호 × 4 는 CPU가 계산
```

**메모리 배치** (행 우선 순서)

```
오프셋:  0   4   8  12 | 16  20 [24] 28 | 32  36  40  44
        [0][0]...[0][3]|[1][0][1][1][1][2][1][3]|[2][0] ...
        ─── 행 0 ───── | ────── 행 1 ────────── | ─ 행 2 ─
```

---

### 4. CMPSW로 16비트 배열 sourcew와 targetw 비교

```asm
.data
sourcew WORD 10, 20, 30, 40
targetw WORD 10, 20, 35, 40

.code
    mov  esi,OFFSET sourcew
    mov  edi,OFFSET targetw
    mov  ecx,LENGTHOF sourcew
    cld
    repe cmpsw                  ; ⭐ 같은 동안 계속 비교
    jne  notEqual               ; 다른 원소를 만나 멈췄음

    ; --- 모든 원소가 같음 ---
    jmp  done

notEqual:
    ; --- 다른 원소 발견 ---
    ; ESI, EDI는 다른 원소의 "다음" 워드를 가리킴
    ; 다른 원소 주소 = ESI - 2, EDI - 2
done:
```

**판정 방법**

| 멈춘 이유 | ZF | 의미 |
|---|:---:|---|
| ECX = 0 이 될 때까지 계속 같았음 | 1 | **모두 같음** |
| 중간에 다른 원소를 만남 | 0 | **다름** (ESI−2, EDI−2 가 그 위치) |

> 이 데이터에서는 세 번째 원소(30 vs 35)에서 멈춥니다.

---

### 5. SCASW로 wordArray에서 0100h를 찾고 그 원소의 오프셋을 EAX에 저장

```asm
.data
wordArray WORD 0003h, 0020h, 0100h, 0FFFFh

.code
    mov  edi,OFFSET wordArray
    mov  ax,0100h               ; 찾을 값
    mov  ecx,LENGTHOF wordArray
    cld
    repne scasw                 ; ⭐ 찾을 때까지 스캔
    jnz  notFound               ; 끝까지 못 찾음
    sub  edi,2                  ; ⭐ 한 워드 지나쳤으므로 되돌림
    mov  eax,edi                ; 찾은 원소의 오프셋
notFound:
```

**채점 포인트**
- **SCASW는 AX** 와 비교합니다 (B→AL, W→AX, D→EAX)
- 찾은 뒤 EDI는 **한 워드(2바이트) 지나 있으므로 `sub edi,2`**. `dec edi` 는 틀립니다
- `jnz notFound` 는 **REPNE 바로 다음**에 둬야 합니다. `sub` 가 플래그를 바꾸니까요

---

### 6. Str_compare로 두 문자열 중 큰 쪽을 콘솔에 출력

```asm
.data
str1 BYTE "apple",0
str2 BYTE "banana",0

.code
    INVOKE Str_compare, ADDR str1, ADDR str2
    ja   str1Larger             ; str1 > str2
    mov  edx,OFFSET str2        ; str2가 크거나 같음
    jmp  show
str1Larger:
    mov  edx,OFFSET str1
show:
    call WriteString            ; "banana"
    call Crlf
```

**원리** Str_compare는 **CMP와 같은 방식으로 플래그를 설정**합니다 (첫 번째 문자열 − 두 번째 문자열). 그래서 호출 직후 바로 조건 점프를 쓸 수 있습니다.

> ⚠️ 문자는 **부호 없는 값**으로 비교되므로 **`JA`/`JB`** 를 씁니다. `JG`/`JL` 은 틀립니다.

---

### 7. Str_trim으로 문자열 끝의 '@'를 모두 제거

```asm
.data
myStr BYTE "Hello@@@",0

.code
    INVOKE Str_trim, ADDR myStr, '@'
    ; myStr = "Hello"
```

> 두 번째 인자로 **지울 문자**를 넘깁니다. 문자열 끝쪽에 연속된 것만 지우고, 중간의 '@'는 그대로 둡니다. (`"A@B@@"` → `"A@B"`)

---

### 8. Str_ucase를 고쳐서 모든 문자를 소문자로 바꾸기

**바꿀 곳은 두 군데뿐입니다**

| | Str_ucase (대문자로) | **Str_lcase (소문자로)** |
|---|---|---|
| ① 범위 검사 | `'a'` ~ `'z'` | **`'A'` ~ `'Z'`** |
| ② 변환 연산 | `and ..., 11011111b` (비트 5 **지우기**) | **`or ..., 00100000b`** (비트 5 **세우기**) |

```asm
;---------------------------------------------------
; Str_lcase
;   null 종료 문자열을 소문자로 바꾼다.
;   Receives: pString = 문자열 주소
;---------------------------------------------------
Str_lcase PROC USES eax esi,
    pString:PTR BYTE

    mov  esi,pString
L1:
    mov  al,[esi]
    cmp  al,0                   ; 문자열 끝?
    je   L3
    cmp  al,'A'                 ; ① 'A'보다 작으면 건너뜀
    jb   L2
    cmp  al,'Z'                 ; ① 'Z'보다 크면 건너뜀
    ja   L2
    or   BYTE PTR [esi],00100000b   ; ② 비트 5 세우기 → 소문자
L2:
    inc  esi
    jmp  L1
L3:
    ret
Str_lcase ENDP
```

**원리** 대문자와 소문자는 **비트 5 하나만** 다릅니다.

```
'A' = 0100 0001 (41h)
'a' = 0110 0001 (61h)
        ↑ 비트 5
```

> 6장 비트 연산과 그대로 연결됩니다. **AND로 지우고, OR로 세운다.**

---

### 9. Str_trim의 64비트 버전

64비트 버전은 **스택 매개변수 대신 레지스터로 인자를 받고, 32비트 레지스터를 64비트로 바꾸면** 됩니다.

```asm
;---------------------------------------------------
; Str_trim (64비트)
;   문자열 끝에서 지정한 문자를 모두 지운다.
;   Receives: RSI = 문자열 주소, AL = 지울 문자
;   Returns:  없음
;---------------------------------------------------
Str_trim PROC USES rcx rdi
    ;----- 길이 구하기 → RCX -----
    mov  rdi,rsi
    mov  rcx,0
L0: cmp  BYTE PTR [rdi],0
    je   L0done
    inc  rdi
    inc  rcx
    jmp  L0
L0done:
    cmp  rcx,0
    je   L3                     ; 빈 문자열이면 할 일 없음

    dec  rdi                    ; RDI = 마지막 문자
L1: cmp  [rdi],al
    jne  L2                     ; 지울 문자가 아님 → 멈춤
    dec  rdi                    ; 지울 문자 → 한 칸 뒤로
    loop L1                     ; ⭐ 64비트 모드의 LOOP는 RCX 사용
L2: mov  BYTE PTR [rdi+1],0     ; 남길 마지막 문자 다음에 null
L3: ret
Str_trim ENDP
```

**호출 예**

```asm
.data
myStr BYTE "Hello###",0

.code
    mov  rsi,OFFSET myStr
    mov  al,'#'
    call Str_trim               ; myStr = "Hello"
```

**32비트 → 64비트 변환 체크리스트**

| 32비트 | 64비트 |
|---|---|
| `PROC, pString:PTR BYTE, char:BYTE` | **레지스터로 전달** (RSI, AL) |
| `INVOKE` | **`call`** (64비트 MASM에는 INVOKE가 없음) |
| EDI, ECX | **RDI, RCX** |
| LOOP → ECX | LOOP → **RCX** |

> 모든 문자가 지울 문자면(`"###"`) 루프가 끝까지 돌아 RDI가 문자열 **바로 앞**을 가리키고, `[rdi+1]` 은 첫 칸이 되어 빈 문자열이 됩니다. 32비트 원본과 같은 기법입니다.

---

### 10. 64비트 모드의 base-index 피연산자 예

```asm
mov rax,[rbx+rsi]
```

> 32비트와 모양은 같고 레지스터만 64비트입니다.

---

### 11. EBX = 행, EDI = 열일 때 32비트 2차원 배열 myArray의 원소를 EAX로 옮기는 문장 하나

```asm
mov eax,myArray[ebx + edi*TYPE myArray]     ; = myArray[ebx + edi*4]
```

**전제** 교재의 2차원 배열 예제처럼 **EBX에는 행의 시작 오프셋**(행 번호 × 한 행의 바이트 수)이 들어 있고, **EDI는 열 번호**입니다.

| 부분 | 의미 |
|---|---|
| `myArray` | 배열 시작 주소 (변위) |
| `ebx` | 행의 시작 오프셋 |
| `edi*TYPE myArray` | 열 번호 × 4 |

> ⚠️ **비례 계수는 레지스터 하나에만** 붙일 수 있습니다. 그래서 행 번호 × 행 크기는 미리 계산해서 EBX에 넣어 두고, 열 쪽에만 비례 계수를 씁니다.

---

### 12. RBX = 행, RDI = 열일 때 64비트 2차원 배열 myArray의 원소를 RAX로 옮기는 문장 하나

```asm
mov rax,myArray[rbx + rdi*TYPE myArray]     ; = myArray[rbx + rdi*8]
```

> 11번과 같은 구조이고, 원소가 **64비트(8바이트)** 이므로 비례 계수가 **8** 입니다. RBX에는 행의 시작 오프셋이 들어 있습니다.

---

## 9.10 프로그래밍 과제 (Programming Exercises)

> 모든 문자열은 **null 종료 문자열**로 가정합니다. 요청이 없어도 각 프로시저를 시험하는 **짧은 테스트 프로그램(드라이버)** 을 함께 작성하라는 조건이 있어서, 모두 완성 프로그램으로 넣었습니다.
>
> 아래 코드는 모두 Irvine32의 **Str_length** 를 사용합니다 (`INVOKE Str_length, ADDR 문자열` → EAX = 길이, EDI 보존).
>
> **손코딩 분량 (제 판단)** — 교수님이 긴 문제는 안 내시므로 "짧음"이 가장 유력합니다.
>
> | 번호 | 과제 | 분량 | 9장 핵심 개념 |
> |:---:|---|:---:|---|
> | 1 | Str_copyN | **짧음** | `REP MOVSB` |
> | 2 | Str_concat | **짧음** | `REP MOVSB`, 끝 위치 찾기 |
> | 3 | Str_remove | **짧음** | `REP MOVSB`로 당기기 |
> | 4 | Str_find | 보통 | `REPE CMPSB` |
> | 5 | Str_nextWord | **짧음** | `REPNE SCASB` |
> | 6 | Get_frequencies | **짧음** | `LODSB`, 인덱스 주소 지정 |
> | 7 | 에라토스테네스의 체 | 보통 | `REP STOSB`, `.data?` |
> | 8 | 버블 정렬 (교환 플래그) | **짧음** | 지역 변수 플래그 |
> | 9 | 이진 탐색 (레지스터) | 보통 | 단답 13·14번 응용 |
> | 10 | 글자 행렬 | 보통 | `STOSB`, `LODSB`, 난수 |
> | 11 | 글자 행렬 집합 | 김 | 행·열·대각선 순회 |
> | 12 | calc_row_sum | 보통 | 2차원 배열, 명시적 스택 매개변수 |
> | 13 | 앞쪽 문자 지우기 | **짧음** | `REPE SCASB` + `REP MOVSB` |
> | 14 | 문자 집합 지우기 | 보통 | `REPNE SCASB`로 집합 검사 |

---

### 1. Str_copyN — 최대 n글자까지만 복사 ★

**문제 요약** Str_copy는 복사할 글자 수에 제한이 없다. **최대 복사 글자 수**를 추가 매개변수로 받는 `Str_copyN` 을 만드시오.

```asm
; Str_copyN.asm

INCLUDE Irvine32.inc

Str_copyN PROTO,
    source:PTR BYTE,
    target:PTR BYTE,
    maxChars:DWORD

.data
source  BYTE "ABCDEFGHIJ",0
target1 BYTE 20 DUP(0)
target2 BYTE 20 DUP(0)

.code
main PROC
    INVOKE Str_copyN, ADDR source, ADDR target1, 5
    mov  edx,OFFSET target1
    call WriteString            ; ABCDE
    call Crlf

    INVOKE Str_copyN, ADDR source, ADDR target2, 20
    mov  edx,OFFSET target2
    call WriteString            ; ABCDEFGHIJ (원본이 더 짧으면 전부)
    call Crlf
    exit
main ENDP

;---------------------------------------------------
; Str_copyN
;   원본 문자열을 최대 maxChars 글자까지 대상에 복사한다.
;   Receives: source, target = 문자열 주소, maxChars = 최대 글자 수
;   Requires: 대상에 maxChars + 1 바이트 이상의 공간
;---------------------------------------------------
Str_copyN PROC USES eax ecx esi edi,
    source:PTR BYTE,
    target:PTR BYTE,
    maxChars:DWORD

    INVOKE Str_length, source   ; EAX = 원본 길이
    mov  ecx,eax
    cmp  ecx,maxChars
    jbe  L1                     ; 길이 ≤ 최대치면 그대로
    mov  ecx,maxChars           ; ⭐ 아니면 최대치로 자름
L1:
    mov  esi,source
    mov  edi,target
    cld
    rep  movsb                  ; ECX 글자 복사
    mov  BYTE PTR [edi],0       ; ⭐ null 종료자를 직접 붙임
    ret
Str_copyN ENDP
END main
```

**채점 포인트**
- 복사할 글자 수 = **min(원본 길이, maxChars)**
- 잘라서 복사하면 원본의 null이 따라오지 않으므로 **null을 직접 붙여야** 합니다. 이걸 빠뜨리면 문자열이 끝나지 않습니다
- `REP MOVSB` 가 끝나면 EDI는 **마지막으로 쓴 다음 칸**에 있으므로 거기에 바로 null을 쓰면 됩니다

---

### 2. Str_concat — 문자열 이어 붙이기

**문제 요약** 원본 문자열을 대상 문자열 **끝에 이어 붙이는** `Str_concat` 을 작성하시오. 대상에는 충분한 공간이 있다고 가정한다.

```asm
; Str_concat.asm

INCLUDE Irvine32.inc

Str_concat PROTO,
    target:PTR BYTE,
    source:PTR BYTE

.data
targetStr BYTE "ABCDE",10 DUP(0)
sourceStr BYTE "FGH",0

.code
main PROC
    INVOKE Str_concat, ADDR targetStr, ADDR sourceStr
    mov  edx,OFFSET targetStr
    call WriteString            ; ABCDEFGH
    call Crlf
    exit
main ENDP

;---------------------------------------------------
; Str_concat
;   source를 target 끝에 이어 붙인다.
;   Receives: target, source = 문자열 주소
;   Requires: target에 충분한 여유 공간
;---------------------------------------------------
Str_concat PROC USES eax ecx esi edi,
    target:PTR BYTE,
    source:PTR BYTE

    INVOKE Str_length, source
    mov  ecx,eax
    inc  ecx                    ; ⭐ 원본의 null까지 복사

    INVOKE Str_length, target   ; EAX = 대상 길이
    mov  edi,target
    add  edi,eax                ; ⭐ EDI = 대상의 null 위치 (여기부터 덮어씀)

    mov  esi,source
    cld
    rep  movsb
    ret
Str_concat ENDP
END main
```

**원리**

```
targetStr:  A B C D E \0 . . . . .
                      ↑ 여기(길이 5 위치)부터 덮어씀
sourceStr:  F G H \0   (4바이트 복사)

결과:       A B C D E F G H \0
```

**채점 포인트**
- 대상의 **null 위치 = 시작 주소 + 길이**. 거기서부터 덮어써야 null이 사라지고 이어집니다
- 복사할 바이트 수 = **원본 길이 + 1** (원본의 null까지 가져와야 결과가 끝남)
- 매개변수 순서는 교재 호출 예처럼 **대상이 먼저**입니다

---

### 3. Str_remove — 문자열 중간의 n글자 삭제

**문제 요약** 문자열에서 **n글자를 지우는** `Str_remove` 를 작성하시오. 지울 위치의 포인터와 지울 글자 수를 넘긴다.

```asm
; Str_remove.asm

INCLUDE Irvine32.inc

Str_remove PROTO,
    pStart:PTR BYTE,
    nChars:DWORD

.data
target BYTE "abcxxxxdefghijklmop",0

.code
main PROC
    INVOKE Str_remove, ADDR [target+3], 4
    mov  edx,OFFSET target
    call WriteString            ; abcdefghijklmop
    call Crlf
    exit
main ENDP

;---------------------------------------------------
; Str_remove
;   pStart 위치부터 nChars 글자를 지운다.
;   Receives: pStart = 지울 위치, nChars = 지울 글자 수
;---------------------------------------------------
Str_remove PROC USES eax ecx esi edi,
    pStart:PTR BYTE,
    nChars:DWORD

    ;----- 남은 글자보다 많이 지우라고 하면 끝까지만 -----
    INVOKE Str_length, pStart   ; EAX = 지울 위치부터 끝까지의 길이
    cmp  nChars,eax
    jbe  L1
    mov  nChars,eax
L1:
    mov  edi,pStart             ; 덮어쓸 곳 = 지울 위치
    mov  esi,edi
    add  esi,nChars             ; ⭐ 가져올 곳 = 지운 구간 바로 뒤

    INVOKE Str_length, esi      ; 뒤에 남는 부분의 길이
    mov  ecx,eax
    inc  ecx                    ; null 포함

    cld
    rep  movsb                  ; ⭐ 뒷부분을 앞으로 당김
    ret
Str_remove ENDP
END main
```

**원리**

```
a b c x x x x d e f ... p \0
      ↑       ↑
     EDI     ESI (EDI + 4)

ESI의 내용("defg...p\0")을 EDI 위치로 당겨 옴
→ a b c d e f ... p \0
```

**채점 포인트**
- 삭제 = **뒷부분을 앞으로 당겨 덮어쓰기**
- 복사 원본(ESI)이 대상(EDI)보다 **뒤에** 있으므로 **CLD(앞에서부터)** 로 복사해야 안전합니다. 겹치는 영역이어도 아직 읽지 않은 바이트를 덮어쓰지 않기 때문입니다
- `ADDR [target+3]` 처럼 **문자열 중간의 주소**를 넘길 수 있습니다

---

### 4. Str_find — 부분 문자열 찾기

**문제 요약** 대상 문자열 안에서 원본 문자열이 **처음 나오는 위치**를 찾는 `Str_find` 를 작성하시오. 찾으면 **ZF = 1, EAX = 대상 안의 일치 위치**, 못 찾으면 **ZF = 0** (EAX는 의미 없음).

```asm
; Str_find.asm

INCLUDE Irvine32.inc

Str_find PROTO,
    pSource:PTR BYTE,
    pTarget:PTR BYTE

.data
target BYTE "123ABC342432",0
source BYTE "ABC",0
pos    DWORD ?
msgYes BYTE "Found at position ",0
msgNo  BYTE "Not found",0

.code
main PROC
    INVOKE Str_find, ADDR source, ADDR target
    jnz  notFound               ; ⭐ ZF로 결과 판단
    mov  pos,eax                ; 일치 위치 저장

    mov  edx,OFFSET msgYes
    call WriteString
    sub  eax,OFFSET target      ; 문자열 시작 기준 위치
    call WriteDec               ; 3
    call Crlf
    jmp  quit

notFound:
    mov  edx,OFFSET msgNo
    call WriteString
    call Crlf
quit:
    exit
main ENDP

;---------------------------------------------------
; Str_find
;   pTarget 안에서 pSource가 처음 나오는 곳을 찾는다.
;   Receives: pSource = 찾을 문자열, pTarget = 대상 문자열
;   Returns:  찾음  → ZF = 1, EAX = 일치 위치의 주소
;             못 찾음 → ZF = 0
;---------------------------------------------------
Str_find PROC USES ebx ecx edx esi edi,
    pSource:PTR BYTE,
    pTarget:PTR BYTE

    INVOKE Str_length, pSource
    mov  ebx,eax                ; EBX = 찾을 문자열 길이
    INVOKE Str_length, pTarget  ; EAX = 대상 길이
    cmp  eax,ebx
    jb   notFound               ; 대상이 더 짧으면 불가능
    sub  eax,ebx
    lea  edx,[eax+1]            ; EDX = 비교를 시작해 볼 위치의 개수
    mov  eax,pTarget            ; EAX = 현재 시작 위치
    cld

L1:
    mov  esi,pSource
    mov  edi,eax
    mov  ecx,ebx
    cmp  ecx,ecx                ; ZF = 1 로 시작 (빈 문자열 대비)
    repe cmpsb                  ; ⭐ 같은 동안 계속 비교
    je   found                  ; 끝까지 같았음 → ZF = 1 유지
    inc  eax                    ; 한 칸 옮겨서 다시 시도
    dec  edx
    jnz  L1

notFound:
    or   eax,1                  ; ⭐ 결과가 0이 아니므로 ZF = 0
found:
    ret                         ; POP/RET은 플래그를 바꾸지 않음
Str_find ENDP
END main
```

**동작** ("ABC" 를 "123ABC342432" 에서)

| 시작 위치 | 비교 | 결과 |
|:---:|---|---|
| 0 | `1` vs `A` | 다름 → 다음 |
| 1 | `2` vs `A` | 다름 → 다음 |
| 2 | `3` vs `A` | 다름 → 다음 |
| **3** | `ABC` vs `ABC` | **세 글자 모두 같음 → 찾음** |

**채점 포인트**
- 시작 위치마다 **`REPE CMPSB`** 로 원본 길이만큼 비교합니다. 끝까지 같으면 찾은 것
- 시도할 위치는 **대상 길이 − 원본 길이 + 1** 개면 충분합니다 (그 뒤로는 남은 글자가 모자람)
- 결과를 **ZF로 돌려주므로**, 마지막 RET까지 **플래그를 바꾸는 명령을 쓰면 안 됩니다.** USES가 만드는 POP과 RET은 플래그를 바꾸지 않습니다
- 못 찾았을 때 ZF = 0을 만드는 요령: `or eax,1` (결과가 0이 될 수 없으므로 ZF = 0)
- `cmp ecx,ecx` 는 찾을 문자열이 빈 문자열일 때 대비입니다. ECX = 0이면 REPE CMPSB가 한 번도 실행되지 않아 플래그가 그대로 남기 때문에, 미리 ZF = 1로 만들어 둡니다

---

### 5. Str_nextWord — 구분자로 단어 끊기

**문제 요약** 문자열에서 **구분자가 처음 나오는 곳**을 찾아 **null로 바꾸는** `Str_nextWord` 를 작성하시오. 찾으면 **ZF = 1, EAX = 구분자 다음 문자의 주소**, 못 찾으면 ZF = 0.

```asm
; Str_nextWord.asm

INCLUDE Irvine32.inc

Str_nextWord PROTO,
    pString:PTR BYTE,
    delimiter:BYTE

.data
target BYTE "Johnson,Calvin",0
msgNo  BYTE "Delimiter not found",0

.code
main PROC
    INVOKE Str_nextWord, ADDR target, ','
    jnz  notFound

    push eax                    ; 다음 단어 주소 보관
    mov  edx,OFFSET target
    call WriteString            ; Johnson  (쉼표가 null로 바뀌었으므로)
    call Crlf
    pop  edx
    call WriteString            ; Calvin
    call Crlf
    jmp  quit

notFound:
    mov  edx,OFFSET msgNo
    call WriteString
    call Crlf
quit:
    exit
main ENDP

;---------------------------------------------------
; Str_nextWord
;   첫 번째 구분자를 null로 바꾸고 다음 단어의 주소를 돌려준다.
;   Receives: pString = 문자열 주소, delimiter = 구분 문자
;   Returns:  찾음  → ZF = 1, EAX = 구분자 다음 문자의 주소
;             못 찾음 → ZF = 0
;---------------------------------------------------
Str_nextWord PROC USES ecx edi,
    pString:PTR BYTE,
    delimiter:BYTE

    INVOKE Str_length, pString
    mov  ecx,eax                ; ECX = 문자열 길이
    jecxz notFound              ; 빈 문자열
    mov  edi,pString
    mov  al,delimiter
    cld
    repne scasb                 ; ⭐ 구분자를 찾을 때까지 스캔
    jne  notFound               ; 끝까지 없었음

    mov  BYTE PTR [edi-1],0     ; ⭐ 구분자 → null (EDI는 한 칸 지나 있음)
    mov  eax,edi                ; 구분자 다음 = 다음 단어의 시작
    ret                         ; MOV는 플래그를 안 바꾸므로 ZF = 1 유지

notFound:
    or   eax,1                  ; ZF = 0
    ret
Str_nextWord ENDP
END main
```

**동작**

```
호출 전:  J o h n s o n , C a l v i n \0
                        ↑ 쉼표 발견, EDI는 'C'를 가리킴

호출 후:  J o h n s o n \0 C a l v i n \0
                           ↑ EAX
```

**채점 포인트**
- 구분자 찾기 = **`REPNE SCASB`** (단답 5번과 같은 원리)
- 찾은 뒤 EDI는 **한 칸 지나 있으므로** 구분자는 `[edi-1]`, 다음 단어는 `edi`
- 성공 경로에서 SCASB가 만든 **ZF = 1을 RET까지 유지**해야 합니다. MOV만 썼으므로 안전합니다

> 💡 이 프로시저를 반복 호출하면 `"a,b,c,d"` 같은 문자열을 단어 단위로 차례로 끊어 낼 수 있습니다. C 언어의 `strtok` 과 같은 발상입니다.

---

### 6. Get_frequencies — 문자 빈도표 만들기

**문제 요약** 문자열을 훑어 **각 문자가 몇 번 나왔는지** 세는 `Get_frequencies` 를 작성하시오. 0으로 초기화된 더블워드 256개짜리 배열을 받아, **문자의 ASCII 코드를 인덱스**로 써서 개수를 기록한다.

```asm
; Frequencies.asm

INCLUDE Irvine32.inc

Get_frequencies PROTO,
    pString:PTR BYTE,
    pTable:PTR DWORD

.data
target    BYTE "AAEBDCFBBC",0
freqTable DWORD 256 DUP(0)

.code
main PROC
    INVOKE Get_frequencies, ADDR target, ADDR freqTable

    ;----- 'A'(41h) ~ 'G'(47h) 칸 출력 -----
    mov  esi,'A'
L1:
    mov  eax,esi
    call WriteChar              ; 문자
    mov  al,':'
    call WriteChar
    mov  eax,freqTable[esi*4]   ; 그 문자의 개수
    call WriteDec
    mov  al,' '
    call WriteChar
    inc  esi
    cmp  esi,'G'
    jbe  L1
    call Crlf                   ; A:2 B:3 C:2 D:1 E:1 F:1 G:0
    exit
main ENDP

;---------------------------------------------------
; Get_frequencies
;   문자열의 문자 빈도표를 만든다.
;   Receives: pString = 문자열 주소
;             pTable  = 0으로 초기화된 DWORD 256개 배열
;---------------------------------------------------
Get_frequencies PROC USES eax ebx esi,
    pString:PTR BYTE,
    pTable:PTR DWORD

    mov  esi,pString
    mov  ebx,pTable
    mov  eax,0                  ; ⭐ 상위 24비트를 0으로 (인덱스로 쓸 것이므로)
    cld
L1:
    lodsb                       ; AL = 다음 문자, ESI++
    cmp  al,0
    je   done                   ; null이면 끝
    inc  DWORD PTR [ebx + eax*4]    ; ⭐ table[문자 코드]++
    jmp  L1
done:
    ret
Get_frequencies ENDP
END main
```

**원리**

```
문자 'B' = 42h = 66
→ table[66] 을 1 증가
→ 주소 = 표 시작 + 66 × 4
```

| 인덱스 | 41h (A) | 42h (B) | 43h (C) | 44h (D) | 45h (E) | 46h (F) | 47h (G) |
|---|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| 개수 | 2 | 3 | 2 | 1 | 1 | 1 | 0 |

**채점 포인트**
- **`LODSB`** 는 AL만 채우므로, EAX 전체를 인덱스로 쓰려면 **처음에 EAX를 0으로** 만들어 둬야 합니다. 루프 안에서는 AL만 바뀌므로 한 번이면 충분합니다
- 표가 DWORD 배열이므로 **비례 계수 ×4** (`[ebx + eax*4]`)
- 메모리 값을 직접 올릴 때는 **`inc DWORD PTR`** 로 크기를 지정합니다

---

### 7. 에라토스테네스의 체 (2 ~ 65,000)

**문제 요약** 원소 65,000개짜리 바이트 배열로 소수를 찾으시오. 배열은 **초기화되지 않은 데이터 영역**(`.data?`)에 선언하고 **STOSB로 0을 채운 뒤**, 소수의 배수 위치에 **1을 표시**한다. 표시되지 않은 위치가 소수다.

```asm
; Sieve.asm

INCLUDE Irvine32.inc

LIMIT = 65000

.data?
sieve BYTE LIMIT DUP(?)         ; ⭐ 초기화되지 않은 데이터 — 실행 파일 크기를 안 늘림

.code
main PROC
    ;----- REP STOSB 로 전부 0 채우기 -----
    mov  edi,OFFSET sieve
    mov  ecx,LIMIT
    mov  al,0
    cld
    rep  stosb

    ;----- 체로 거르기: 배수에 1 표시 -----
    mov  ebx,2                  ; 현재 후보
outer:
    mov  eax,ebx
    mul  ebx                    ; EAX = ebx²
    cmp  eax,LIMIT
    jae  doneSieve              ; ebx² 가 범위를 넘으면 끝
    cmp  sieve[ebx],0
    jne  nextCandidate          ; 이미 표시됨 → 소수 아님
    mov  esi,eax                ; ebx² 부터 표시
mark:
    cmp  esi,LIMIT
    jae  nextCandidate
    mov  sieve[esi],1           ; ⭐ 배수에 1
    add  esi,ebx
    jmp  mark
nextCandidate:
    inc  ebx
    jmp  outer

doneSieve:
    ;----- 0으로 남은 칸이 소수 -----
    mov  esi,2
print:
    cmp  esi,LIMIT
    jae  allDone
    cmp  sieve[esi],0
    jne  skip
    mov  eax,esi
    call WriteDec
    mov  al,' '
    call WriteChar
skip:
    inc  esi
    jmp  print
allDone:
    call Crlf
    exit
main ENDP
END main
```

**출력** `2 3 5 7 11 13 17 19 23 29 ... 64951 64969 64997` (총 **6,493개**)

**채점 포인트**
- **`.data?`** 는 초기값이 없는 데이터 영역입니다. 65,000바이트를 `.data` 에 두면 실행 파일이 그만큼 커지지만, `.data?` 는 **실행할 때 메모리만 잡습니다** (3장 내용)
- 초기값이 정해지지 않으므로 **REP STOSB로 직접 0을 채워야** 합니다
- 이 문제는 **"배수에 1 표시, 0이 소수"** 방식입니다. 7장 프로그래밍 과제 5번(1이 소수 후보, 0이 걸러짐)과 표시 방향이 반대이니 헷갈리지 마세요
- 외부 루프는 **ebx² ≥ 65000** 이 되면 멈춥니다 (255² = 65,025 이므로 254까지만 확인)

---

### 8. 버블 정렬 — 교환 플래그로 조기 종료 ★

**문제 요약** 9.5.1절의 BubbleSort에 **교환이 일어날 때마다 1이 되는 변수**를 추가해서, 한 바퀴를 도는 동안 교환이 한 번도 없으면 **정렬을 일찍 끝내도록** 하시오.

```asm
; BubbleSortFlag.asm

INCLUDE Irvine32.inc

BubbleSort PROTO,
    pArray:PTR DWORD,
    Count:DWORD

.data
array DWORD 45, -12, 7, 30, -5, 18, 0, 22

.code
main PROC
    INVOKE BubbleSort, ADDR array, LENGTHOF array

    mov  esi,OFFSET array
    mov  ecx,LENGTHOF array
L1:
    mov  eax,[esi]
    call WriteInt               ; -12 -5 +0 +7 +18 +22 +30 +45
    mov  al,' '
    call WriteChar
    add  esi,4
    loop L1
    call Crlf
    exit
main ENDP

;---------------------------------------------------
; BubbleSort (교환 플래그 추가)
;   부호 있는 정수 배열을 오름차순으로 정렬한다.
;   Receives: pArray = 배열 주소, Count = 원소 개수
;---------------------------------------------------
BubbleSort PROC USES eax ecx esi,
    pArray:PTR DWORD,
    Count:DWORD
    LOCAL exchanged:DWORD       ; ⭐ 교환 플래그

    mov  ecx,Count
    dec  ecx                    ; 바깥 루프 = Count - 1 번
    jle  done                   ; 원소가 1개 이하면 할 일 없음

L1:
    push ecx                    ; 바깥 카운터 보존
    mov  esi,pArray
    mov  exchanged,0            ; ⭐ 이번 바퀴: 아직 교환 없음

L2:
    mov  eax,[esi]
    cmp  [esi+4],eax
    jge  L3                     ; 다음 값 ≥ 현재 값 → 순서 맞음
    xchg eax,[esi+4]            ; 두 값 교환
    mov  [esi],eax
    mov  exchanged,1            ; ⭐ 교환 발생
L3:
    add  esi,4
    loop L2

    pop  ecx
    cmp  exchanged,0
    je   done                   ; ⭐ 한 번도 안 바꿨으면 이미 정렬됨 → 종료
    loop L1

done:
    ret
BubbleSort ENDP
END main
```

**채점 포인트**
- 플래그는 **매 바퀴 시작마다 0으로 초기화**, 교환하면 1
- 바퀴가 끝났을 때 **0이면 이미 정렬된 것**이므로 바로 끝냅니다. 이미 정렬된 배열이면 **한 바퀴만** 돌고 끝납니다
- 문제가 "**변수**를 추가하라"고 했으므로 **LOCAL** 지역 변수로 만들었습니다 (8장). 6장 과제 10번처럼 레지스터(BL)를 써도 원리는 같습니다
- 중첩 루프이므로 **`push ecx` / `pop ecx`** 로 바깥 카운터 보호
- 부호 있는 배열이므로 **`JGE`** (G/L 계열)

---

### 9. 이진 탐색 — mid, first, last를 레지스터로

**문제 요약** 이 장의 이진 탐색 프로시저를 **mid, first, last를 레지스터로** 바꿔 다시 작성하고, 레지스터 용도를 주석으로 밝히시오.

```asm
; BinarySearchReg.asm

INCLUDE Irvine32.inc

BinarySearch PROTO,
    pArray:PTR DWORD,
    Count:DWORD,
    searchVal:SDWORD

.data
array  SDWORD -30, -10, 0, 5, 12, 20, 45, 60    ; ⭐ 정렬되어 있어야 함
prompt BYTE "Index: ",0

.code
main PROC
    INVOKE BinarySearch, ADDR array, LENGTHOF array, 12
    call WriteInt               ; +4
    call Crlf
    INVOKE BinarySearch, ADDR array, LENGTHOF array, -30
    call WriteInt               ; +0
    call Crlf
    INVOKE BinarySearch, ADDR array, LENGTHOF array, 60
    call WriteInt               ; +7
    call Crlf
    INVOKE BinarySearch, ADDR array, LENGTHOF array, 7
    call WriteInt               ; -1 (없음)
    call Crlf
    exit
main ENDP

;---------------------------------------------------
; BinarySearch (레지스터 버전)
;   정렬된 부호 있는 정수 배열에서 값을 찾는다.
;   Receives: pArray, Count, searchVal
;   Returns:  EAX = 찾은 위치 (못 찾으면 -1)
;
;   레지스터 용도
;     EBX = 배열 시작 주소
;     EDI = 찾는 값 (searchVal)
;     ESI = first  (탐색 구간의 왼쪽 끝)
;     ECX = last   (탐색 구간의 오른쪽 끝)
;     EDX = mid    (가운데 위치)
;     EAX = values[mid], 마지막에는 반환값
;---------------------------------------------------
BinarySearch PROC USES ebx ecx edx esi edi,
    pArray:PTR DWORD,
    Count:DWORD,
    searchVal:SDWORD

    mov  ebx,pArray             ; EBX = 배열 주소
    mov  edi,searchVal          ; EDI = 찾는 값
    mov  esi,0                  ; first = 0
    mov  ecx,Count
    dec  ecx                    ; last = Count - 1

L1: cmp  esi,ecx                ; while (first <= last)
    jg   notFound               ; ⭐ 부호 있는 비교 (last가 -1이 될 수 있음)

    mov  edx,esi
    add  edx,ecx
    shr  edx,1                  ; mid = (first + last) / 2

    mov  eax,[ebx + edx*4]      ; EAX = values[mid]
    cmp  eax,edi                ; ⭐ 비교는 한 번만
    jl   goRight                ; values[mid] < 찾는 값 → 오른쪽 절반
    jg   goLeft                 ; values[mid] > 찾는 값 → 왼쪽 절반

    mov  eax,edx                ; 같음 → mid 반환
    jmp  done

goRight:
    lea  esi,[edx+1]            ; first = mid + 1
    jmp  L1                     ; ⭐ 바로 L1로 (점프의 점프 없음)
goLeft:
    lea  ecx,[edx-1]            ; last = mid - 1
    jmp  L1

notFound:
    mov  eax,-1
done:
    ret
BinarySearch ENDP
END main
```

**동작 추적** (12 찾기)

| 단계 | first (ESI) | last (ECX) | mid (EDX) | values[mid] | 판단 |
|:---:|:---:|:---:|:---:|:---:|---|
| 1 | 0 | 7 | 3 | 5 | 5 < 12 → 오른쪽 |
| 2 | 4 | 7 | 5 | 20 | 20 > 12 → 왼쪽 |
| 3 | 4 | 4 | 4 | **12** | **같음 → 4 반환** |

**원본과 달라진 점**

| | 원본 (지역 변수) | 레지스터 버전 |
|---|---|---|
| first, last, mid | `LOCAL` 메모리 변수 | **ESI, ECX, EDX** |
| 비교 | 두 번 (L2에서 다시) | **한 번** — `JL` 과 `JG` 가 같은 플래그를 씀 (단답 13번) |
| 반복 | `jmp L4` → `jmp L1` | **바로 `jmp L1`** (단답 14번) |
| `first = mid + 1` | MOV, INC, MOV 3줄 | **`lea esi,[edx+1]`** 1줄 |

> 레지스터는 메모리보다 훨씬 빠르므로 루프 안에서 자주 쓰는 값은 레지스터에 두는 게 유리합니다.

---

### 10. 글자 행렬 — 모음 확률 50%

**문제 요약** **4×4 무작위 대문자 행렬**을 만드는 프로시저를 작성하시오. 각 글자가 **모음일 확률은 50%** 여야 한다. 프로시저를 5번 호출해 매번 행렬을 출력하는 테스트 프로그램도 작성한다.

```asm
; LetterMatrix.asm

INCLUDE Irvine32.inc

MakeLetterMatrix PROTO, pMatrix:PTR BYTE
ShowMatrix       PROTO, pMatrix:PTR BYTE

.data
vowels     BYTE "AEIOU"
consonants BYTE "BCDFGHJKLMNPQRSTVWXYZ"     ; 21개
matrix     BYTE 16 DUP(?)

.code
main PROC
    call Randomize              ; 난수 시드 초기화 (한 번만)
    mov  ecx,5
L1:
    INVOKE MakeLetterMatrix, ADDR matrix
    INVOKE ShowMatrix, ADDR matrix
    call Crlf
    loop L1
    exit
main ENDP

;---------------------------------------------------
; RandomLetter
;   50% 확률로 모음, 50% 확률로 자음을 하나 고른다.
;   Returns: AL = 고른 대문자
;---------------------------------------------------
RandomLetter PROC
    mov  eax,2
    call RandomRange            ; EAX = 0 또는 1
    cmp  eax,0
    jne  consonant

    mov  eax,LENGTHOF vowels    ; ⭐ 0 → 모음 중에서
    call RandomRange
    mov  al,vowels[eax]
    ret
consonant:
    mov  eax,LENGTHOF consonants    ; 1 → 자음 중에서
    call RandomRange
    mov  al,consonants[eax]
    ret
RandomLetter ENDP

;---------------------------------------------------
; MakeLetterMatrix — 16칸을 무작위 글자로 채운다
;---------------------------------------------------
MakeLetterMatrix PROC USES eax ecx edi,
    pMatrix:PTR BYTE

    mov  edi,pMatrix
    mov  ecx,16
    cld
L1:
    call RandomLetter           ; AL = 글자
    stosb                       ; ⭐ [EDI] ← AL, EDI++
    loop L1
    ret
MakeLetterMatrix ENDP

;---------------------------------------------------
; ShowMatrix — 4×4로 출력한다
;---------------------------------------------------
ShowMatrix PROC USES eax ecx edx esi,
    pMatrix:PTR BYTE

    mov  esi,pMatrix
    mov  edx,4                  ; 행 4개
    cld
R1:
    mov  ecx,4                  ; 열 4개
C1:
    lodsb                       ; ⭐ AL ← [ESI], ESI++
    call WriteChar
    mov  al,' '
    call WriteChar
    loop C1
    call Crlf
    dec  edx
    jnz  R1
    ret
ShowMatrix ENDP
END main
```

**출력 예**

```
D W A L
S I V W
U I O L
L A I I
...
```

**채점 포인트**
- **50% 확률 만들기**: 먼저 `RandomRange(2)` 로 0/1을 뽑아 **모음 그룹이냐 자음 그룹이냐**를 정하고, 그 그룹 안에서 다시 한 글자를 뽑습니다. 26글자 중에서 그냥 뽑으면 모음 확률이 5/26 ≈ 19%밖에 안 됩니다
- **`Randomize` 는 프로그램 시작 시 한 번만.** 루프 안에서 부르면 같은 시드로 같은 행렬이 반복될 수 있습니다
- 채울 때는 **STOSB**, 읽을 때는 **LODSB** — 9장 문자열 명령 연습

---

### 11. 글자 행렬에서 모음이 정확히 2개인 4글자 집합 찾기

**문제 요약** 10번의 글자 행렬을 하나 만든 뒤, **각 행·각 열·두 대각선**을 따라 4글자 집합 10개를 만들고, **모음이 정확히 2개인 집합만** 출력하시오.

**아이디어** 16칸 배열에서 4글자를 뽑는 방법은 **(시작 위치, 간격)** 두 숫자로 표현할 수 있습니다.

| 집합 | 시작 | 간격 | 뽑히는 칸 |
|---|:---:|:---:|---|
| 행 r | r × 4 | **1** | 가로로 4칸 |
| 열 c | c | **4** | 세로로 4칸 |
| 주대각선 | 0 | **5** | 0, 5, 10, 15 |
| 반대 대각선 | 3 | **3** | 3, 6, 9, 12 |

```asm
; LetterSets.asm

INCLUDE Irvine32.inc

MakeLetterMatrix PROTO, pMatrix:PTR BYTE
ShowMatrix       PROTO, pMatrix:PTR BYTE
CheckSet         PROTO, pMatrix:PTR BYTE, start:DWORD, step:DWORD
CheckAllSets     PROTO, pMatrix:PTR BYTE

.data
vowels     BYTE "AEIOU"
consonants BYTE "BCDFGHJKLMNPQRSTVWXYZ"
matrix     BYTE 16 DUP(?)
testMatrix BYTE "POAZAEAUGKAEIAGD"      ; 교재 예시 행렬 (검증용)

; (시작, 간격) 10쌍: 행 4개, 열 4개, 대각선 2개
setTable   BYTE 0,1, 4,1, 8,1, 12,1
           BYTE 0,4, 1,4, 2,4,  3,4
           BYTE 0,5, 3,3

.code
main PROC
    ;----- ① 교재 예시 행렬로 검증 -----
    INVOKE ShowMatrix, ADDR testMatrix
    call Crlf
    INVOKE CheckAllSets, ADDR testMatrix
    call Crlf

    ;----- ② 무작위 행렬 -----
    call Randomize
    INVOKE MakeLetterMatrix, ADDR matrix
    INVOKE ShowMatrix, ADDR matrix
    call Crlf
    INVOKE CheckAllSets, ADDR matrix
    exit
main ENDP

;---------------------------------------------------
; CheckAllSets — 10개 집합을 모두 검사한다
;---------------------------------------------------
CheckAllSets PROC USES eax ebx ecx esi,
    pMatrix:PTR BYTE

    mov  esi,OFFSET setTable
    mov  ecx,10
L1:
    movzx eax,BYTE PTR [esi]        ; 시작
    movzx ebx,BYTE PTR [esi+1]      ; 간격
    INVOKE CheckSet, pMatrix, eax, ebx
    add  esi,2
    loop L1
    ret
CheckAllSets ENDP

;---------------------------------------------------
; CheckSet
;   (시작, 간격)으로 4글자를 뽑아 모음이 정확히 2개면 출력한다.
;---------------------------------------------------
CheckSet PROC USES eax ebx ecx edx esi,
    pMatrix:PTR BYTE,
    start:DWORD,
    step:DWORD
    LOCAL letters[5]:BYTE       ; 4글자 + null

    mov  esi,pMatrix
    add  esi,start              ; 첫 글자 위치
    lea  ebx,letters            ; ⭐ 지역 배열 주소는 LEA (8장)
    mov  edx,0                  ; 모음 개수
    mov  ecx,4
L1:
    mov  al,[esi]
    mov  [ebx],al               ; 글자 모으기
    call IsVowel
    jne  notVowel
    inc  edx
notVowel:
    add  esi,step               ; 다음 칸 (간격만큼)
    inc  ebx
    loop L1
    mov  BYTE PTR [ebx],0       ; null 종료

    cmp  edx,2
    jne  done                   ; 모음이 정확히 2개일 때만
    lea  edx,letters
    call WriteString
    call Crlf
done:
    ret
CheckSet ENDP

;---------------------------------------------------
; IsVowel
;   Receives: AL = 문자
;   Returns:  ZF = 1 이면 모음
;---------------------------------------------------
IsVowel PROC USES ecx edi
    mov  edi,OFFSET vowels
    mov  ecx,LENGTHOF vowels
    cld
    repne scasb                 ; ⭐ 모음 목록에서 AL을 찾음
    ret                         ; 찾으면 ZF = 1
IsVowel ENDP

;---------------------------------------------------
; RandomLetter / MakeLetterMatrix / ShowMatrix — 10번과 동일
;---------------------------------------------------
RandomLetter PROC
    mov  eax,2
    call RandomRange
    cmp  eax,0
    jne  consonant
    mov  eax,LENGTHOF vowels
    call RandomRange
    mov  al,vowels[eax]
    ret
consonant:
    mov  eax,LENGTHOF consonants
    call RandomRange
    mov  al,consonants[eax]
    ret
RandomLetter ENDP

MakeLetterMatrix PROC USES eax ecx edi,
    pMatrix:PTR BYTE
    mov  edi,pMatrix
    mov  ecx,16
    cld
L1: call RandomLetter
    stosb
    loop L1
    ret
MakeLetterMatrix ENDP

ShowMatrix PROC USES eax ecx edx esi,
    pMatrix:PTR BYTE
    mov  esi,pMatrix
    mov  edx,4
    cld
R1: mov  ecx,4
C1: lodsb
    call WriteChar
    mov  al,' '
    call WriteChar
    loop C1
    call Crlf
    dec  edx
    jnz  R1
    ret
ShowMatrix ENDP
END main
```

**교재 예시 행렬로 검증한 결과**

```
P O A Z
A E A U
G K A E
I A G D
```

| 집합 | 글자 | 모음 수 | 출력 |
|---|---|:---:|:---:|
| 행 0 | **POAZ** | 2 | ✅ |
| 행 1 | AEAU | 4 | |
| 행 2 | **GKAE** | 2 | ✅ |
| 행 3 | **IAGD** | 2 | ✅ |
| 열 0 | **PAGI** | 2 | ✅ |
| 열 1 | OEKA | 3 | |
| 열 2 | AAAG | 3 | |
| 열 3 | **ZUED** | 2 | ✅ |
| 주대각선 | **PEAD** | 2 | ✅ |
| 반대 대각선 | **ZAKI** | 2 | ✅ |

→ **POAZ, GKAE, IAGD, PAGI, ZUED, PEAD, ZAKI** — 교재에 제시된 답과 일치합니다.

**채점 포인트**
- 행·열·대각선을 각각 따로 코딩하지 않고 **(시작, 간격) 표 하나로 통일**한 게 핵심입니다. 코드가 짧아지고 실수가 줄어듭니다
- 모음 판별에 **`REPNE SCASB`** 로 모음 목록을 검색합니다
- `IsVowel` 이 ECX를 쓰므로 **USES로 보존**해야 바깥 LOOP가 망가지지 않습니다

---

### 12. calc_row_sum — 2차원 배열의 한 행 합계

**문제 요약** 바이트·워드·더블워드 2차원 배열의 **한 행의 합**을 구하는 `calc_row_sum` 을 작성하시오. 스택 매개변수는 **배열 오프셋, 행 크기, 배열 타입, 행 번호**이고 합은 EAX로 반환한다. **INVOKE나 매개변수 목록 PROC을 쓰지 말고 명시적 스택 매개변수**로 작성한다. 사용자에게 행 번호를 입력받아 세 가지 배열의 해당 행 합을 출력한다.

```asm
; RowSum.asm

INCLUDE Irvine32.inc

.data
byteArray  BYTE  1,  2,  3,  4
RowSizeB = ($ - byteArray)              ; 한 행 = 4바이트
           BYTE  5,  6,  7,  8
           BYTE  9, 10, 11, 12

wordArray  WORD 100, 200, 300
RowSizeW = ($ - wordArray)              ; 한 행 = 6바이트
           WORD 400, 500, 600
           WORD 700, 800, 900

dwordArray DWORD 1000, 2000
RowSizeD = ($ - dwordArray)             ; 한 행 = 8바이트
           DWORD 3000, 4000
           DWORD 5000, 6000

prompt BYTE "Enter row index (0-2): ",0
msgB   BYTE "BYTE  row sum: ",0
msgW   BYTE "WORD  row sum: ",0
msgD   BYTE "DWORD row sum: ",0

.code
main PROC
    mov  edx,OFFSET prompt
    call WriteString
    call ReadDec                ; EAX = 행 번호
    mov  ebx,eax                ; 보관

    ;----- BYTE 배열 -----
    push ebx                    ; ④ 행 번호
    push TYPE byteArray         ; ③ 타입 (1)
    push RowSizeB               ; ② 행 크기 (바이트)
    push OFFSET byteArray       ; ① 배열 오프셋
    call calc_row_sum
    mov  edx,OFFSET msgB
    call WriteString
    call WriteDec
    call Crlf

    ;----- WORD 배열 -----
    push ebx
    push TYPE wordArray         ; 2
    push RowSizeW
    push OFFSET wordArray
    call calc_row_sum
    mov  edx,OFFSET msgW
    call WriteString
    call WriteDec
    call Crlf

    ;----- DWORD 배열 -----
    push ebx
    push TYPE dwordArray        ; 4
    push RowSizeD
    push OFFSET dwordArray
    call calc_row_sum
    mov  edx,OFFSET msgD
    call WriteString
    call WriteDec
    call Crlf
    exit
main ENDP

;---------------------------------------------------
; calc_row_sum
;   2차원 배열의 한 행의 합을 구한다.
;   스택 매개변수 (명시적)
;     [ebp+8]  = 배열 오프셋
;     [ebp+12] = 행 크기 (바이트)
;     [ebp+16] = 배열 타입 (1, 2, 4)
;     [ebp+20] = 행 번호
;   Returns:  EAX = 합계
;---------------------------------------------------
calc_row_sum PROC
    push ebp
    mov  ebp,esp
    push ebx
    push ecx
    push edx
    push esi

    ;----- 행의 시작 주소 = 배열 + 행 번호 × 행 크기 -----
    mov  eax,[ebp+12]           ; 행 크기
    mul  DWORD PTR [ebp+20]     ; × 행 번호 (EDX도 바뀜)
    mov  esi,[ebp+8]
    add  esi,eax                ; ESI = 행의 시작

    ;----- 원소 개수 = 행 크기 ÷ 타입 -----
    mov  eax,[ebp+12]
    mov  edx,0
    div  DWORD PTR [ebp+16]
    mov  ecx,eax                ; ECX = 원소 개수

    mov  eax,0                  ; 합계
    mov  ebx,[ebp+16]           ; EBX = 타입 (원소 크기)
L1:
    cmp  ebx,1
    jne  notByte
    movzx edx,BYTE PTR [esi]    ; ⭐ 바이트 → 32비트로 확장
    jmp  addIt
notByte:
    cmp  ebx,2
    jne  isDword
    movzx edx,WORD PTR [esi]    ; ⭐ 워드 → 32비트로 확장
    jmp  addIt
isDword:
    mov  edx,[esi]
addIt:
    add  eax,edx
    add  esi,ebx                ; 다음 원소 (타입 크기만큼)
    loop L1

    pop  esi
    pop  edx
    pop  ecx
    pop  ebx
    pop  ebp
    ret  16                     ; ⭐ 매개변수 4개 × 4바이트 정리
calc_row_sum ENDP
END main
```

**실행 예**

| 입력 | BYTE 행 합 | WORD 행 합 | DWORD 행 합 |
|:---:|:---:|:---:|:---:|
| 0 | 10 | 600 | 3000 |
| 1 | 26 | 1500 | 7000 |
| 2 | 42 | 2400 | 11000 |

**채점 포인트**
- 인자는 **역순 PUSH** (행 번호 → 타입 → 행 크기 → 오프셋). 그래야 첫 번째 매개변수가 `[ebp+8]` 에 옵니다 (8장)
- 행 시작 = **배열 + 행 번호 × 행 크기**, 원소 개수 = **행 크기 ÷ 타입**
- 바이트·워드는 **MOVZX** 로 32비트로 넓혀서 더합니다 (값을 부호 없는 수로 취급)
- `RowSizeB = ($ - byteArray)` 는 **첫 행만 선언한 직후**에 둬야 한 행의 크기가 됩니다
- 명시적 스택 매개변수이므로 **`ret 16`** 을 직접 써야 합니다 (STDCALL)

---

### 13. 앞쪽의 특정 문자 모두 지우기

**문제 요약** Str_trim의 변형으로, 문자열 **앞쪽에 연속된** 지정 문자를 모두 지우는 프로시저를 만드시오. 예: `"###ABC"` 에서 `'#'` → `"ABC"`.

```asm
; TrimLeading.asm

INCLUDE Irvine32.inc

Str_trimLeading PROTO,
    pString:PTR BYTE,
    char:BYTE
ShowBracketed PROTO, pString:PTR BYTE

.data
str1 BYTE "###ABC",0
str2 BYTE "ABC",0
str3 BYTE "###",0
str4 BYTE "##A#B",0

.code
main PROC
    INVOKE Str_trimLeading, ADDR str1, '#'
    INVOKE ShowBracketed, ADDR str1         ; [ABC]
    INVOKE Str_trimLeading, ADDR str2, '#'
    INVOKE ShowBracketed, ADDR str2         ; [ABC]
    INVOKE Str_trimLeading, ADDR str3, '#'
    INVOKE ShowBracketed, ADDR str3         ; []
    INVOKE Str_trimLeading, ADDR str4, '#'
    INVOKE ShowBracketed, ADDR str4         ; [A#B]  (중간의 #은 유지)
    exit
main ENDP

;---------------------------------------------------
; Str_trimLeading
;   문자열 앞쪽에 연속된 char를 모두 지운다.
;   Receives: pString = 문자열 주소, char = 지울 문자
;---------------------------------------------------
Str_trimLeading PROC USES eax ecx esi edi,
    pString:PTR BYTE,
    char:BYTE

    INVOKE Str_length, pString
    mov  ecx,eax                ; ECX = 길이
    jecxz done                  ; 빈 문자열
    mov  edi,pString
    mov  al,char
    cld
    repe scasb                  ; ⭐ 지울 문자가 이어지는 동안 건너뜀
    jne  foundOther             ; 다른 문자를 만났음

    ;----- 전부 지울 문자였음 → 빈 문자열 -----
    mov  edi,pString
    mov  BYTE PTR [edi],0
    jmp  done

foundOther:
    dec  edi                    ; ⭐ 한 칸 지나쳤으므로 되돌림 → 남길 첫 문자
    mov  esi,edi                ; 복사 원본 = 남길 부분의 시작
    mov  edi,pString            ; 복사 대상 = 문자열 맨 앞
    add  ecx,2                  ; ⭐ 남길 글자 수 = ECX + 1, 여기에 null 1개
    rep  movsb                  ; 앞으로 당김
done:
    ret
Str_trimLeading ENDP

;---------------------------------------------------
; ShowBracketed — 문자열을 [ ] 로 감싸 출력 (빈 문자열 확인용)
;---------------------------------------------------
ShowBracketed PROC USES eax edx,
    pString:PTR BYTE
    mov  al,'['
    call WriteChar
    mov  edx,pString
    call WriteString
    mov  al,']'
    call WriteChar
    call Crlf
    ret
ShowBracketed ENDP
END main
```

**복사할 바이트 수 계산** (`"###ABC"`, 길이 6)

```
# # # A B C \0
REPE SCASB:  '#' 같음(ECX 5) → '#'(4) → '#'(3) → 'A' 다름 → 멈춤, ECX = 2
             EDI는 'B'를 가리킴 → dec edi 로 'A'

남길 글자 "ABC" = 3개 = ECX(2) + 1   (방금 다르다고 판정한 'A' 포함)
null 1개 추가                        → 총 ECX + 2 = 4바이트
```

**채점 포인트**
- 앞쪽 건너뛰기 = **`REPE SCASB`** (같은 동안 계속 → 처음으로 다른 곳에서 멈춤)
- 멈췄을 때 ECX는 **아직 검사하지 않은 글자 수**입니다. 방금 다르다고 판정한 글자 1개와 null 1개를 더해야 합니다
- 원본(ESI)이 대상(EDI)보다 뒤에 있으므로 **앞에서부터 복사(CLD)** 해도 안전합니다 (3번 Str_remove와 같은 원리)
- 끝까지 전부 지울 문자면 REPE가 ZF = 1로 끝나므로 **빈 문자열**로 만듭니다

---

### 14. 문자열 끝에서 문자 집합 지우기

**문제 요약** Str_trim의 변형으로, 문자열 **끝쪽에서 필터 집합에 속한 문자**를 모두 지우는 프로시저를 만드시오. 예: `"ABC#$&"` 에 필터 `"%#!;$&*"` → `"ABC"`.

```asm
; TrimSet.asm

INCLUDE Irvine32.inc

Str_trimSet PROTO,
    pString:PTR BYTE,
    pFilter:PTR BYTE
IsInSet PROTO,
    char:DWORD,
    pSet:PTR BYTE
ShowBracketed PROTO, pString:PTR BYTE

.data
filter BYTE "%#!;$&*",0
str1   BYTE "ABC#$&",0
str2   BYTE "Hello!!;",0
str3   BYTE "#$&",0
str4   BYTE "A#B$",0

.code
main PROC
    INVOKE Str_trimSet, ADDR str1, ADDR filter
    INVOKE ShowBracketed, ADDR str1         ; [ABC]
    INVOKE Str_trimSet, ADDR str2, ADDR filter
    INVOKE ShowBracketed, ADDR str2         ; [Hello]
    INVOKE Str_trimSet, ADDR str3, ADDR filter
    INVOKE ShowBracketed, ADDR str3         ; []
    INVOKE Str_trimSet, ADDR str4, ADDR filter
    INVOKE ShowBracketed, ADDR str4         ; [A#B]  (중간의 #은 유지)
    exit
main ENDP

;---------------------------------------------------
; Str_trimSet
;   문자열 끝에서 필터 집합에 속한 문자를 모두 지운다.
;   Receives: pString = 문자열 주소, pFilter = 필터 문자열 주소
;---------------------------------------------------
Str_trimSet PROC USES eax ecx esi,
    pString:PTR BYTE,
    pFilter:PTR BYTE

    INVOKE Str_length, pString
    mov  ecx,eax
    jecxz done                  ; 빈 문자열
    mov  esi,pString
    add  esi,ecx
    dec  esi                    ; ESI = 마지막 문자
L1:
    movzx eax,BYTE PTR [esi]
    INVOKE IsInSet, eax, pFilter
    jne  keep                   ; ⭐ 필터에 없는 문자 → 여기서 멈춤
    dec  esi                    ; 필터에 있음 → 한 칸 뒤로
    loop L1
keep:
    mov  BYTE PTR [esi+1],0     ; 남길 마지막 문자 다음에 null
done:
    ret
Str_trimSet ENDP

;---------------------------------------------------
; IsInSet
;   문자가 집합(문자열)에 들어 있는지 검사한다.
;   Receives: char = 문자, pSet = 집합 문자열 주소
;   Returns:  ZF = 1 (있음) / 0 (없음)
;---------------------------------------------------
IsInSet PROC USES eax ecx edi,
    char:DWORD,
    pSet:PTR BYTE

    INVOKE Str_length, pSet
    mov  ecx,eax
    jecxz notIn                 ; 빈 집합
    mov  edi,pSet
    mov  eax,char               ; AL = 찾을 문자
    cld
    repne scasb                 ; ⭐ 집합에서 문자를 찾음
    ret                         ; 찾으면 ZF = 1, 못 찾으면 ZF = 0
notIn:
    or   ecx,1                  ; ZF = 0
    ret
IsInSet ENDP

;---------------------------------------------------
; ShowBracketed — 13번과 동일
;---------------------------------------------------
ShowBracketed PROC USES eax edx,
    pString:PTR BYTE
    mov  al,'['
    call WriteChar
    mov  edx,pString
    call WriteString
    mov  al,']'
    call WriteChar
    call Crlf
    ret
ShowBracketed ENDP
END main
```

**Str_trim과 비교**

| | Str_trim | **Str_trimSet** |
|---|---|---|
| 지울 대상 | 문자 **하나** | 문자 **집합** |
| 판정 | `cmp al,char` | **`IsInSet`** (집합에서 `REPNE SCASB`) |
| 나머지 구조 | 끝에서 거꾸로 → 멈춘 곳 다음에 null | **동일** |

**채점 포인트**
- "집합에 속하는가" 검사를 **별도 프로시저**로 빼면 본체는 Str_trim과 거의 같아집니다
- 집합 검사 = **`REPNE SCASB`** 로 필터 문자열에서 찾기 (11번 IsVowel과 같은 기법)
- 모든 문자가 필터에 속하면 루프가 끝까지 돌아 ESI가 문자열 **바로 앞**을 가리키고, `[esi+1]` 이 첫 칸이 되어 **빈 문자열**이 됩니다 (단답 7번 Str_trim과 같은 기법)
- `IsInSet` 이 **USES로 ECX를 보존**해야 바깥 LOOP가 정상 동작합니다

---

# 9장 시험 대비 요점

## 가장 많이 틀리는 7가지

| # | 함정 | 정답 |
|:---:|---|---|
| 1 | **찾은 뒤 EDI 위치** | 일치한 원소의 **다음 칸**. `dec edi` / `sub edi,2` / `sub edi,4` 로 되돌리기 |
| 2 | **REPE vs REPNE** | REPE = 같은 동안 계속(**다른 곳** 찾기), REPNE = 다른 동안 계속(**같은 것** 찾기) |
| 3 | **CMPS의 비교 순서** | **`[ESI] − [EDI]`**. CMP와 반대처럼 보이니 주의 |
| 4 | **SCAS/STOS의 레지스터** | **AL/AX/EAX** 와 **EDI**. ESI는 쓰지 않음 |
| 5 | **방향 플래그** | 문자열 명령 전에 **항상 CLD**. 기본값을 믿지 말 것 |
| 6 | **이동량** | B=1, **W=2**, D=4 |
| 7 | **2차원 배열 주소** | 행 오프셋 = 행 번호 × **한 행의 바이트 수**. 비례 계수는 **열 쪽 한 레지스터에만** |

## 용도별 명령어 선택

| 하고 싶은 일 | 명령 |
|---|---|
| 배열·문자열 **복사** | `cld` + `rep movsb` |
| 배열을 한 값으로 **채우기** | `cld` + `rep stosb` |
| 특정 값 **찾기** | `cld` + `repne scasb` |
| 두 배열이 **같은지 비교** | `cld` + `repe cmpsb` |
| 원소를 **하나씩 읽기** | `lodsb` |
| 문자열 **길이** | `mov al,0` + `repne scasb` → `EDI − 시작 − 1` |

## 자주 쓰는 패턴

```asm
; 찾기 — 찾은 위치를 EDI에
    mov  edi,OFFSET arr
    mov  al,찾을값
    mov  ecx,LENGTHOF arr
    cld
    repne scasb
    jnz  notFound
    dec  edi                    ; ⭐ 한 칸 되돌리기

; 비교 — 다른 곳에서 멈춤
    mov  esi,OFFSET a
    mov  edi,OFFSET b
    mov  ecx,LENGTHOF a
    cld
    repe cmpsb
    jne  different              ; ZF = 0 이면 다름

; 채우기
    mov  edi,OFFSET arr
    mov  al,0
    mov  ecx,LENGTHOF arr
    cld
    rep  stosb
```

## 2차원 배열 공식

```
원소 주소 = 배열 시작 + (행 번호 × 한 행의 바이트 수) + (열 번호 × 원소 크기)
                        └──── 기준 레지스터 ────┘   └──── 인덱스 × 비례 계수 ───┘

    mov  eax, table[ebx + esi*TYPE table]
```

## 출제 예상 (교수님 2/2/1~2 배분 기준)

| 섹션 | ★★★ 우선 | 이유 |
|---|---|---|
| **9.9.1 단답형** | **1, 2, 4, 5, 9** | 방향 플래그, 이동량, EDI 위치, 접두사 선택. 한 줄로 답함 |
| | **3, 11** | CMPS 비교 순서, 이진 탐색 횟수(log₂n) |
| | **8, 12** | 코드를 안 외워도 원리로 답할 수 있음 |
| **9.9.2 알고리즘** | **1, 2, 10** | 주소 지정 형식 한 줄씩 |
| | **3, 11** | 2차원 배열 주소 계산 — 9장 계산 문제의 핵심 |
| | **4, 5** | `REPE CMPSW`, `REPNE SCASW` — 짧고 9장 명령 그 자체 |
| **9.10 프로그래밍** | **1, 2, 5** | Str_copyN, Str_concat, Str_nextWord — 짧고 문자열 명령 중심 |
| | **8** | 교환 플래그 버블 정렬 — 짧음 |
| | **13** | 앞쪽 문자 지우기 — 짧고 `REPE SCASB` + `REP MOVSB` 조합 |

> 중간고사 패턴(짧은 단답 + 프로그래밍 1개)을 그대로 적용하면, 9장에서는 **접두사·방향 플래그 단답 1문제 + 2차원 배열 주소 또는 SCAS/CMPS 짧은 코드 1문제 + 짧은 문자열 프로시저 1개** 조합이 가장 유력합니다.
