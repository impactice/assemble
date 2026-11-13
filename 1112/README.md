# x86 어셈블리: 문자열과 배열 (Strings and Arrays)

![Assembler](https://img.shields.io/badge/Assembler-MASM-blue)
![Architecture](https://img.shields.io/badge/Architecture-x86%2032--bit-lightgrey)
![IDE](https://img.shields.io/badge/IDE-Visual%20Studio%202022-5C2D91)
![Chapter](https://img.shields.io/badge/Irvine-Chapter%209-orange)

> Kip R. Irvine, *Assembly Language for x86 Processors* — Chapter 9. Strings and Arrays 강의 정리
>
> 슬라이드 내용을 절 순서대로 정리하고, 슬라이드에 없는 동작 원리, 추가 예제, 자주 하는 실수를 보충했다. 슬라이드가 비어 있거나 다루지 않은 부분(String Library Demo의 실행 결과, 열 단위 처리와 64비트 2차원 배열, 이진 검색 테스트 프로그램의 코드, 자바 바이트코드의 문자열 처리)도 채웠다.
> 슬라이드의 오류는 본문에 정정 박스로 표시하고 [부록 G](#부록-g-슬라이드-정정-사항-모음)에 모아 두었다.
> 예제 코드의 주석에 적힌 레지스터·플래그·변수·문자열 값과 실행 결과는 직접 어셈블하고 한 명령어씩 실행해서 확인한 값이다([예제 값 확인 방법](#예제-값-확인-방법)).

---

## 한눈에 보기 (TL;DR)

- **문자열 기본 명령어**(string primitive)는 `MOVS`(복사), `CMPS`(비교), `SCAS`(찾기), `STOS`(저장), `LODS`(읽기)의 다섯 가지이고, 각각 바이트·워드·더블워드용(`B`, `W`, `D`)이 있다. 원본은 **ESI**, 대상은 **EDI**, 값은 누산기(AL·AX·EAX)로 정해져 있어 피연산자를 적지 않는다.
- 한 번 실행할 때마다 ESI·EDI가 데이터 크기(1·2·4)만큼 **자동으로** 움직인다. 방향은 **방향 플래그 DF**가 정한다. `CLD`(DF = 0)이면 증가, `STD`(DF = 1)이면 감소다. Windows와 C 런타임은 DF = 0을 전제로 하므로, `STD`를 썼다면 돌아가기 전에 반드시 `CLD`로 되돌린다.
- **반복 접두사**를 붙이면 ECX를 카운터로 삼아 명령어 하나가 배열 전체를 처리한다. `REP`는 ECX가 0이 될 때까지, `REPE`(`REPZ`)는 같은 동안, `REPNE`(`REPNZ`)는 다른 동안 반복한다. 반복이 끝난 뒤 ESI·EDI는 마지막으로 처리한 원소의 **다음**을 가리킨다.
- `CMPS`와 `SCAS`는 `CMP`처럼 플래그를 바꾸고, `MOVS`·`STOS`·`LODS`는 플래그를 바꾸지 않는다. `REPE CMPS`나 `REPNE SCAS` 뒤에는 ZF를 보고 **왜 멈췄는지**(끝까지 갔는지, 다른·같은 원소를 만났는지) 판단한다.
- Irvine32의 문자열 프로시저 `Str_compare`, `Str_length`, `Str_copy`, `Str_trim`, `Str_ucase`는 널로 끝나는 문자열을 다룬다. `Str_compare`는 결과를 `CMP`와 같은 방식으로 CF·ZF에 남긴다. `Str_copy`는 대상의 크기를 검사하지 않는다.
- **2차원 배열**은 메모리에 한 줄로 저장된다. C처럼 **행 우선**(row-major)이면 원소 (행, 열)의 주소는 `기준 주소 + (행 × 행의 바이트 수) + 열 × 원소 크기`다. 이것을 `[ebx + esi]`(베이스-인덱스)나 `table[ebx + esi*TYPE table]`(베이스-인덱스-변위)로 표현한다.
- **버블 정렬**은 이웃한 두 원소를 비교해 교환하기를 n − 1번 반복한다(비교 약 n²/2번). **이진 검색**은 정렬된 배열에서 범위를 절반씩 줄여 log₂n번 남짓한 비교로 값을 찾는다.

---

## 목차

| 구분 | 내용 |
|---|---|
| [들어가며](#들어가며-8장에서-9장으로) | 8장과의 연결, C 코드와 어셈블리의 대응 |
| [9.2 문자열 기본 명령어](#92-문자열-기본-명령어-string-primitive-instructions) | 반복 접두사, 방향 플래그, MOVS, CMPS, SCAS, STOS, LODS, 실제 속도 |
| [9.3 문자열 프로시저](#93-문자열-프로시저-selected-string-procedures) | Str_compare, Str_length, Str_copy, Str_trim, Str_ucase, String Library Demo, Irvine64의 문자열 프로시저 |
| [9.4 2차원 배열](#94-2차원-배열-two-dimensional-arrays) | 행 우선·열 우선, 베이스-인덱스, 행의 합, 배율, 베이스-인덱스-변위, 열 단위 처리, 64비트 모드 |
| [9.5 정수 배열의 정렬과 검색](#95-정수-배열의-정렬과-검색-searching-and-sorting-integer-arrays) | 버블 정렬, 이진 검색, 테스트 프로그램, 비교 횟수 |
| [9.6 자바 바이트코드: 문자열 처리](#96-자바-바이트코드-문자열-처리-java-bytecodes-string-processing-보충) | `charAt` 루프와 문자열 연결의 바이트코드 |
| [부록 A](#부록-a-핵심-정리-표) | 핵심 정리 표 (문자열 명령어, 반복 접두사, 주소 지정) |
| [부록 B](#부록-b-c-컴파일러가-만든-문자열배열-코드) | C 컴파일러가 만든 문자열·배열 코드 |
| [부록 C](#부록-c-자주-하는-실수와-오류-메시지) | 자주 하는 실수와 오류 메시지 |
| [부록 D](#부록-d-핵심-용어-정리) | 핵심 용어 정리 |
| [부록 E](#부록-e-복습-문제) | 복습 문제 (단답형 15문제, 알고리즘 작성 6문제, 정답 접기) |
| [부록 F](#부록-f-프로그래밍-연습-풀이-포함) | 프로그래밍 연습 11문제와 풀이 (문자열 프로시저 만들기, 빈도표, 에라토스테네스의 체, 정렬·검색, 2차원 배열) |
| [부록 G](#부록-g-슬라이드-정정-사항-모음) | 슬라이드 정정 사항 모음 |
| [참고 자료](#참고-자료) | 예제 값 확인 방법, 교재, 공식 문서 |

---

## 들어가며: 8장에서 9장으로

8장까지는 배열을 다룰 때 `[esi]`로 원소를 읽고, `add esi,4`로 다음 원소로 옮기고, `loop`로 반복하는 세 단계를 직접 썼다. x86에는 이 세 단계를 **명령어 하나**로 묶은 문자열 기본 명령어가 있다. 이름은 "문자열"이지만 바이트 문자열뿐 아니라 워드·더블워드 배열에도 그대로 쓸 수 있다. 9장은 이 명령어들, Irvine32의 문자열 프로시저, 2차원 배열을 주소로 다루는 법, 그리고 배열을 정렬하고 검색하는 대표적인 알고리즘을 다룬다.

| 하고 싶은 일 | 이 장에서 배우는 도구 | 절 |
|---|---|---|
| 메모리 블록을 통째로 복사한다 | `REP MOVSB`, `REP MOVSD` | 9.2 |
| 두 블록이 같은지, 어디서 다른지 찾는다 | `REPE CMPSB` | 9.2 |
| 특정 값이 처음 나오는 곳을 찾는다 | `REPNE SCASB` | 9.2 |
| 메모리를 한 값으로 채운다 | `REP STOSB`, `REP STOSD` | 9.2 |
| 배열을 차례로 읽으며 처리한다 | `LODSD` + `STOSD` | 9.2 |
| 널로 끝나는 문자열을 다룬다 | `Str_length`, `Str_copy`, `Str_compare`, `Str_trim`, `Str_ucase` | 9.3 |
| 표(행렬)의 원소에 접근한다 | `[ebx + esi]`, `table[ebx + esi*TYPE table]` | 9.4 |
| 배열을 정렬하고 값을 찾는다 | 버블 정렬, 이진 검색 | 9.5 |

C 표준 라이브러리 함수가 어셈블리에서 어떤 모습인지 먼저 보면 이 장의 내용이 한눈에 들어온다. ESI가 원본(`src`), EDI가 대상(`dst`), ECX가 개수(`n`)라고 가정했다.

| C 코드 | 어셈블리 | 관련 내용 |
|---|---|---|
| `memcpy(dst, src, n);` | `cld` / `rep movsb` | MOVS |
| `memset(dst, 0FFh, n);` | `mov al,0FFh` / `cld` / `rep stosb` | STOS |
| `memcmp(src, dst, n) == 0` | `cld` / `repe cmpsb` 다음 ZF 검사 | CMPS |
| `memchr(dst, 'F', n)` | `mov al,'F'` / `cld` / `repne scasb` 다음 ZF 검사 | SCAS |
| `strlen(s)` | `Str_length` 또는 `repne scasb`로 0 찾기 | 9.3, 9.2 |
| `strcpy(t, s)` / `strcmp(a, b)` | `Str_copy` / `Str_compare` | 9.3 |
| `x = table[r][c];` (BYTE) | `mov al,[ebx + esi]` (EBX = 행의 시작, ESI = c) | 9.4 |
| `x = table[r][c];` (DWORD) | `mov eax,table[ebx + esi*4]` (EBX = r × 행의 바이트 수) | 9.4 |

> [!NOTE]
> 문자열 명령어는 반복문을 짧게 만들어 줄 뿐 아니라 대체로 빠르다. 다만 종류마다 차이가 있다. 직접 재 보니 큰 블록을 복사하고 채우는 `REP MOVS`·`REP STOS`는 C 라이브러리의 `memcpy`·`memset`만큼 빨랐다. 반면 `REPNE SCAS`·`REPE CMPS`는 단순한 바이트 루프보다는 빨랐지만, SIMD 명령어를 쓰는 `memchr`·`memcmp`보다는 몇 배 느렸다([9.2절 끝](#문자열-명령어는-빠를까-보충)).

---

## 9.2 문자열 기본 명령어 (String Primitive Instructions)

32비트 모드에서 다음 표의 명령어들은 메모리 주소로 ESI나 EDI, 또는 둘 다를 **암시적으로** 쓴다. 누산기를 쓰는 명령어는 데이터 크기에 따라 AL, AX, EAX 중 하나를 쓴다(References to the accumulator imply the use of AL, AX, or EAX, depending on the instruction data size). 문자열 기본 명령어는 반복과 배열 인덱스 증가를 스스로 하므로 효율적이다(String primitives execute efficiently because they automatically repeat and increment array indexes).

| 명령어 (Instruction) | 하는 일 (Description) | 쓰는 레지스터 | 플래그 |
|---|---|---|---|
| `MOVSB`, `MOVSW`, `MOVSD` | 문자열 데이터 이동: ESI가 가리키는 메모리의 데이터를 EDI가 가리키는 메모리로 복사한다 | ESI, EDI | 바꾸지 않는다 |
| `CMPSB`, `CMPSW`, `CMPSD` | 문자열 비교: ESI와 EDI가 가리키는 두 메모리의 내용을 비교한다 | ESI, EDI | `CMP`처럼 바꾼다 |
| `SCASB`, `SCASW`, `SCASD` | 문자열 검색: 누산기(AL, AX, EAX)와 EDI가 가리키는 메모리를 비교한다 | EDI, 누산기 | `CMP`처럼 바꾼다 |
| `STOSB`, `STOSW`, `STOSD` | 문자열 저장: 누산기의 값을 EDI가 가리키는 메모리에 저장한다 | EDI, 누산기 | 바꾸지 않는다 |
| `LODSB`, `LODSW`, `LODSD` | 문자열 읽기: ESI가 가리키는 메모리를 누산기로 읽는다 | ESI, 누산기 | 바꾸지 않는다 |

이름 끝의 `B`, `W`, `D`가 데이터 크기(바이트, 워드, 더블워드)를 나타낸다. 명령어를 한 번 실행하면 데이터 하나를 처리한 뒤 ESI·EDI가 그 크기(1, 2, 4)만큼 **자동으로** 다음 원소로 움직인다. 그래서 루프에서 `add esi,4` 같은 포인터 증가를 따로 쓰지 않아도 된다.

> [!NOTE]
> MASM은 `movs BYTE PTR [edi],BYTE PTR [esi]`처럼 피연산자를 적는 일반형(`MOVS`, `CMPS`, `SCAS`, `STOS`, `LODS`)도 받아들인다. 그러나 피연산자는 데이터 크기를 알려 줄 뿐이다. 실제로 쓰이는 주소는 **언제나 ESI와 EDI**다. 예를 들어 `movs dst,src`는 `movsb`와 똑같은 기계어(`A4`)가 되며, ESI·EDI에 `src`·`dst`의 주소를 넣어 주지 않는다. 주소는 반드시 먼저 ESI·EDI에 직접 넣어야 한다.

### 반복 접두사 (Using a Repeat Prefix)

문자열 기본 명령어 하나는 그 자체로는 메모리 값 하나(또는 한 쌍)만 처리한다. 앞에 **반복 접두사**(repeat prefix)를 붙이면 ECX를 카운터로 써서 명령어가 반복된다. 반복 접두사 덕분에 배열 전체를 명령어 하나로 처리할 수 있다(The repeat prefix permits you to process an entire array using a single instruction).

| 접두사 | 반복 조건 | 함께 쓰는 명령어 |
|---|---|---|
| `REP` | ECX > 0인 동안 반복 (Repeat while ECX > 0) | `MOVS`, `STOS` (`LODS`) |
| `REPZ`, `REPE` | ZF = 1이고 ECX > 0인 동안 반복 (Repeat while the Zero flag is set and ECX > 0) | `CMPS`, `SCAS` |
| `REPNZ`, `REPNE` | ZF = 0이고 ECX > 0인 동안 반복 (Repeat while the Zero flag is clear and ECX > 0) | `CMPS`, `SCAS` |

**예: 문자열 복사하기** (Example: Copy a String). ESI와 EDI에 원본과 대상의 주소를, ECX에 개수를 넣고 `rep movsb` 한 줄로 10바이트를 복사한다.

```asm
.data
string1 BYTE "ABCDEFGHIJ",0
string2 BYTE 11 DUP(0)
.code
cld                             ; clear direction flag
mov  esi,OFFSET string1         ; ESI points to source
mov  edi,OFFSET string2         ; EDI points to target
mov  ecx,10                     ; set counter to 10
rep  movsb                      ; move 10 bytes: ECX = 0, string2 = "ABCDEFGHIJ"
```

ECX > 0이면 ECX를 하나 줄이고 명령어를 반복한다(If ECX > 0, ECX is decremented and the instruction repeats). `MOVSB`가 반복될 때 ESI와 EDI는 자동으로 증가하며, 이 동작은 CPU의 방향 플래그가 정한다(This behavior is controlled by the CPU's Direction flag).

반복 접두사의 동작을 정확히 쓰면 다음과 같다. **ECX를 먼저 검사**하므로 ECX가 처음부터 0이면 한 번도 실행되지 않고, `REPE`·`REPNE`는 한 번 실행할 때마다 ECX를 줄인 **뒤에** ZF를 검사한다.

```text
while ECX != 0:
    문자열 명령어를 한 번 실행한다 (ESI, EDI가 움직인다)
    ECX = ECX - 1                ; 플래그는 바꾸지 않는다
    if REPE  and ZF = 0: break   ; 다른 것을 만났다
    if REPNE and ZF = 1: break   ; 같은 것을 만났다
```

```asm
.data
string1 BYTE "ABCDEFGHIJ",0
string2 BYTE 11 DUP(0)
.code
cld
mov  esi,OFFSET string1
mov  edi,OFFSET string2
mov  ebx,esi                    ; 처음 ESI를 기억해 둔다
mov  ecx,0
rep  movsb                      ; ECX가 0이면 한 번도 반복하지 않는다: ESI = EBX, string2 = ""
mov  ecx,4
rep  movsb                      ; 4바이트 복사 뒤 ESI는 다음 바이트를 가리킨다: ESI = EBX+4
```

반복이 끝나면 ESI·EDI는 마지막으로 처리한 원소의 **다음** 원소를 가리킨다. 이 성질은 `SCAS`로 무언가를 찾은 뒤 위치를 계산할 때 중요하다.

### 방향 플래그 (Direction Flag)

문자열 기본 명령어는 **방향 플래그**(Direction flag, DF)의 상태에 따라 ESI와 EDI를 증가시키거나 감소시킨다. 방향 플래그는 `CLD`와 `STD`로 직접 바꿀 수 있다(The Direction flag can be explicitly modified using the CLD and STD instructions).

```text
CLD         ; clear Direction flag (forward direction)
STD         ; set Direction flag (reverse direction)
```

| 방향 플래그 (Value of the Direction Flag) | ESI와 EDI에 미치는 효과 (Effect on ESI and EDI) | 주소 순서 (Address Sequence) |
|---|---|---|
| 0 (Clear) | 증가 (Incremented) | 낮은 주소 → 높은 주소 (Low-high) |
| 1 (Set) | 감소 (Decremented) | 높은 주소 → 낮은 주소 (High-low) |

거꾸로 처리해야 하는 대표적인 경우는 **겹치는 영역의 복사**다. 배열의 원소를 한 칸씩 뒤로 밀려면 원본(앞쪽)과 대상(한 칸 뒤)이 겹친다. 앞에서부터 복사하면 아직 옮기지 않은 원소를 덮어써 버린다.

```asm
.data
arrayA DWORD 1,2,3,4,5,0
arrayB DWORD 1,2,3,4,5,0
.code
; 앞에서부터 복사하면 첫 원소가 계속 번진다
cld
mov  esi,OFFSET arrayA          ; 원본: 원소 0
mov  edi,OFFSET arrayA + 4      ; 대상: 원소 1
mov  ecx,5
rep  movsd                      ; arrayA = [1, 1, 1, 1, 1, 1]
; 뒤에서부터 복사하면 올바르게 한 칸씩 밀린다
std                             ; DF = 1
mov  esi,OFFSET arrayB + 16     ; 원본: 마지막 원소(원소 4)
mov  edi,OFFSET arrayB + 20     ; 대상: 원소 5
mov  ecx,5
rep  movsd                      ; arrayB = [1, 1, 2, 3, 4, 5]
cld                             ; 반드시 DF = 0으로 되돌린다
```

C의 `memmove`가 겹치는 영역을 안전하게 복사하기 위해 하는 일이 바로 이것이다(대상이 원본보다 뒤에 있으면 뒤에서부터 복사한다).

> [!WARNING]
> **`STD`를 썼다면 반드시 `CLD`로 되돌린다.** Microsoft의 x64 규약 문서는 함수가 끝날 때와 C 런타임 함수·Windows 시스템 호출에 들어갈 때 방향 플래그가 0이어야 한다고 정하고 있다. C 런타임의 문자열·버퍼 함수도 DF = 0을 전제로 작성되어 있다. DF = 1인 채로 라이브러리 함수를 부르면 그 함수 안의 문자열 명령어가 거꾸로 동작해 엉뚱한 메모리를 망가뜨린다. 반대로, 문자열 명령어를 쓰는 프로시저는 들어올 때 DF가 0이라고 믿지 말고 스스로 `CLD`를 실행해 두는 것이 안전하다(Irvine32의 `Str_copy`도 그렇게 한다).

### MOVSB, MOVSW, MOVSD

`MOVSB`, `MOVSW`, `MOVSD`는 ESI가 가리키는 메모리의 데이터를 EDI가 가리키는 메모리로 복사한다. 두 레지스터는 방향 플래그에 따라 자동으로 증가하거나 감소한다.

| 명령어 | 하는 일 | ESI·EDI에 더하거나 빼는 값 |
|---|---|---|
| `MOVSB` | 바이트 복사 (Move bytes) | 1 |
| `MOVSW` | 워드 복사 (Move words) | 2 |
| `MOVSD` | 더블워드 복사 (Move doublewords) | 4 |

**예: 더블워드 배열 복사하기** (Example: Copy Doubleword Array)

```asm
.data
source DWORD 20 DUP(0FFFFFFFFh)
target DWORD 20 DUP(?)
.code
cld                             ; direction = forward
mov  ecx,LENGTHOF source        ; set REP counter
mov  esi,OFFSET source          ; ESI points to source
mov  edi,OFFSET target          ; EDI points to target
rep  movsd                      ; copy doublewords: ECX = 0, target = [0FFFFFFFFh, 0FFFFFFFFh, 0FFFFFFFFh]
mov  eax,target + 76            ; 마지막 원소까지 복사되었다: EAX = 0FFFFFFFFh
```

ECX에는 **바이트 수가 아니라 반복 횟수(원소 수)** 를 넣는다. 20개짜리 DWORD 배열이면 `LENGTHOF source`(20)이고, `SIZEOF source`(80)를 넣으면 80개의 더블워드, 즉 320바이트를 복사해 `target` 뒤의 메모리까지 덮어쓴다. 바이트 수를 알고 있다면 `MOVSB`를 쓰거나, 4로 나눈 값을 `MOVSD`의 횟수로 쓴다.

### CMPSB, CMPSW, CMPSD

`CMPSB`, `CMPSW`, `CMPSD`는 ESI가 가리키는 메모리 피연산자와 EDI가 가리키는 메모리 피연산자를 비교한다(each compare a memory operand pointed to by ESI to a memory operand pointed to by EDI). 플래그는 `CMP [esi],[edi]`(즉 `[ESI] − [EDI]`)를 계산했을 때와 같이 바뀐다. 그래서 비교 뒤에는 `CMP` 다음처럼 조건부 점프를 쓴다. 부호 없는 값이면 `JA`·`JB`, 부호 있는 값이면 `JG`·`JL`이다.

| 명령어 | 하는 일 |
|---|---|
| `CMPSB` | 바이트 비교 (Compare bytes) |
| `CMPSW` | 워드 비교 (Compare words) |
| `CMPSD` | 더블워드 비교 (Compare doublewords) |

**예: 더블워드 비교하기** (Example: Comparing Doublewords). `CMPSD`로 더블워드 한 쌍을 비교해 보자.

```asm
.data
source DWORD 1234h
target DWORD 5678h
.code
mov  esi,OFFSET source
mov  edi,OFFSET target
cmpsd                           ; compare doublewords: CF = 1, ZF = 0
ja   L1                         ; jump if source > target (점프하지 않는다)
```

1234h − 5678h는 자리내림이 생기므로 CF = 1이다. `source`가 `target`보다 작으므로 `JA`는 점프하지 않는다.

여러 더블워드를 비교하려면 방향 플래그를 지우고(정방향), ECX를 카운터로 초기화하고, `CMPSD`에 반복 접두사를 붙인다(To compare multiple doublewords, clear the Direction flag (forward direction), initialize ECX as a counter, and use a repeat prefix with CMPSD).

```asm
mov  esi,OFFSET source
mov  edi,OFFSET target
cld                             ; direction = forward
mov  ecx,LENGTHOF source        ; repetition counter
repe cmpsd                      ; repeat while equal
```

`REPE`는 ESI와 EDI를 자동으로 증가시키며 비교를 반복하다가, ECX가 0이 되거나 서로 다른 더블워드 쌍을 만나면 멈춘다(until ECX equals zero or a pair of doublewords is found to be different). 멈춘 뒤에는 **왜 멈췄는지**를 ZF로 판단한다.

| 멈춘 뒤의 상태 | 뜻 | 다른 원소의 위치 |
|---|---|---|
| ZF = 1 (이때 ECX = 0) | 끝까지 모두 같았다 | 없음 |
| ZF = 0 | 다른 쌍을 만났다. 대소 관계는 CF(부호 없음) 또는 SF·OF(부호 있음)로 안다 | ESI − 4, EDI − 4 (인덱스 = 개수 − ECX − 1) |

```asm
.data
source DWORD 10, 20, 30, 40, 50
target DWORD 10, 20, 35, 40, 50
.code
mov  esi,OFFSET source
mov  edi,OFFSET target
cld
mov  ecx,LENGTHOF source
repe cmpsd                      ; 세 번째 쌍에서 멈춘다: ZF = 0, CF = 1, ECX = 2
mov  eax,[esi-4]                ; 멈춘 원소는 바로 앞에 있다: EAX = 30
mov  ebx,LENGTHOF source
sub  ebx,ecx
dec  ebx                        ; 다른 원소의 인덱스: EBX = 2
```

`ZF = 0`이고 30 < 35이므로 CF = 1, 즉 `source`가 `target`보다 작다. 비교는 세 번 실행되었으므로 ECX는 5 − 3 = 2이고, ESI는 다른 원소(인덱스 2)의 **다음**을 가리킨다.

교재 예제 `Cmpsb.asm`은 같은 길이의 두 문자열을 `REPE CMPSB`로 비교한다.

```asm
; Comparing Strings            (Cmpsb.asm)
INCLUDE Irvine32.inc

.data
source BYTE "MARTIN  "
dest   BYTE "MARTINEZ"
str1   BYTE "Source is smaller",0dh,0ah,0
str2   BYTE "Source is not smaller",0dh,0ah,0

.code
main PROC
    cld                         ; direction = forward
    mov  esi,OFFSET source
    mov  edi,OFFSET dest
    mov  ecx,LENGTHOF source
    repe cmpsb                  ; ' '(20h)와 'E'(45h)에서 멈춘다: ZF = 0, CF = 1, ECX = 1
    jb   source_smaller         ; 점프한다
    mov  edx,OFFSET str2
    jmp  done
source_smaller:
    mov  edx,OFFSET str1
done:
    call WriteString
    exit
main ENDP
END main
```

실행 결과:

```text
Source is smaller
```

일곱 번째 문자 공백(20h)이 `E`(45h)보다 작으므로 CF = 1이 되어 `JB`가 점프한다. 사전식 비교에서 "MARTIN"이 "MARTINEZ"보다 앞에 오는 것과 같은 결과다.

> [!TIP]
> 교재의 원본 `Cmpsb.asm`은 카운터를 `mov cx,LENGTHOF source`로 넣는다. 32비트 코드에서 반복 접두사는 ECX 전체를 카운터로 쓰므로, CX만 넣으면 ECX의 상위 16비트에 남아 있던 값까지 횟수에 섞인다. 위 코드처럼 `mov ecx,…`로 써야 안전하다.

### SCASB, SCASW, SCASD

`SCASB`, `SCASW`, `SCASD`는 AL·AX·EAX의 값을 EDI가 가리키는 바이트·워드·더블워드와 비교한다. 플래그는 `CMP 누산기,[edi]`를 계산했을 때와 같다. 긴 문자열이나 배열에서 특정 값을 찾을 때 유용하다.

**일치하는 문자 찾기** (Scan for a Matching Character). 다음 예에서는 문자열 `alpha`에서 글자 F를 찾는다.

```asm
.data
alpha BYTE "ABCDEFGH",0
.code
mov  edi,OFFSET alpha           ; EDI points to the string
mov  al,'F'                     ; search for the letter F
mov  ecx,LENGTHOF alpha         ; set the search count
cld                             ; direction = forward
repne scasb                     ; repeat while not equal: ZF = 1, ECX = 3
jnz  quit                       ; quit if letter not found (점프하지 않는다)
dec  edi                        ; found: back up EDI
mov  dl,[edi]                   ; EDI는 F를 가리킨다: DL = 46h
```

`REPNE SCASB`는 같은 문자를 만나면 멈춘다. 이때 EDI는 이미 다음 문자로 넘어가 있으므로 `dec edi`로 한 칸 되돌려야 F의 위치가 된다. 끝까지 찾지 못하고 ECX가 0이 되어 멈췄다면 ZF = 0이므로 `jnz quit`가 점프한다.

#### REPNE SCASB로 문자열 길이 구하기 (보충)

널 문자(0)를 찾으면 문자열의 길이를 알 수 있다. ECX를 −1(사실상 무한)로 시작하면, 멈췄을 때 줄어든 양이 "검사한 바이트 수 = 길이 + 1"이다.

```asm
.data
myString BYTE "Hello, World",0
.code
mov  edi,OFFSET myString
mov  al,0                       ; 찾을 값: 널 문자
mov  ecx,-1                     ; 최대 횟수 (FFFFFFFFh)
cld
repne scasb                     ; 널에서 멈춘다: ECX = -14
not  ecx                        ; ECX = 13 (검사한 바이트 수)
dec  ecx                        ; 널은 빼고: ECX = 12
```

13바이트(글자 12개 + 널)를 검사했으므로 ECX = −1 − 13 = −14이다. `NOT`은 −14를 13으로 바꾸고(2의 보수에서 `NOT x` = −x − 1), 널을 빼면 길이 12가 된다.

#### REPE SCASB로 앞쪽 공백 건너뛰기 (보충)

`REPE`를 쓰면 반대로 **같은 값이 계속되는 동안** 건너뛴다. 문자열 앞의 공백을 건너뛰어 첫 번째 단어를 찾는 데 쓸 수 있다.

```asm
.data
line BYTE "    MASM",0
.code
mov  edi,OFFSET line
mov  al,' '
mov  ecx,LENGTHOF line
cld
repe scasb                      ; 공백이 아닌 첫 문자에서 멈춘다: ZF = 0
dec  edi                        ; 그 문자로 되돌아간다
mov  bl,[edi]                   ; BL = 4Dh
```

`4Dh`는 `'M'`이다. 문자열 전체가 공백이라면 ECX가 0이 될 때까지 ZF = 1로 끝나므로, 실제 프로그램에서는 ZF를 먼저 검사해야 한다.

### STOSB, STOSW, STOSD

`STOSB`, `STOSW`, `STOSD`는 AL·AX·EAX의 내용을 EDI가 가리키는 오프셋의 메모리에 저장한다. 반복 접두사와 함께 쓰면 문자열이나 배열 전체를 한 값으로 채울 수 있다. 다음 코드는 `string1`의 바이트를 모두 0FFh로 초기화한다(initializes each byte in string1 to 0FFh).

```asm
.data
Count = 100
string1 BYTE Count DUP(?)
.code
mov  al,0FFh                    ; value to be stored
mov  edi,OFFSET string1         ; EDI points to target
mov  ecx,Count                  ; character count
cld                             ; direction = forward
rep  stosb                      ; fill with contents of AL: ECX = 0, string1 = [0FFh, 0FFh, 0FFh]
mov  bl,string1 + 99            ; 마지막 바이트까지 채워졌다: BL = 0FFh
```

인텔 매뉴얼은 `REP STOS`를 큰 메모리 블록을 초기화하는 가장 빠른 방법이라고 설명한다. 더블워드 배열을 0으로 지우려면 EAX = 0으로 두고 `rep stosd`를 쓴다.

```asm
.data
counts DWORD 26 DUP(5)
.code
mov  eax,0
mov  edi,OFFSET counts
mov  ecx,LENGTHOF counts        ; 원소 수
cld
rep  stosd                      ; counts = [0, 0, 0, 0]
mov  ebx,counts + 100           ; 마지막 원소: EBX = 0
```

### LODSB, LODSW, LODSD

`LODSB`, `LODSW`, `LODSD`는 ESI가 가리키는 메모리에서 바이트·워드·더블워드를 읽어 AL·AX·EAX에 넣는다. 읽을 때마다 누산기를 덮어쓰므로 `REP`와 함께 쓰는 일은 거의 없고, 보통 루프 안에서 `STOS`와 짝을 지어 "읽기 → 처리 → 쓰기"를 한다. 다음 프로그램은 더블워드 배열의 각 원소에 상수를 곱한다(multiplies each element of a doubleword array by a constant value).

```asm
; Multiply an Array            (Mult.asm)
; This program multiplies each element of an array
; of 32-bit integers by a constant value.
INCLUDE Irvine32.inc

.data
array      DWORD 1,2,3,4,5,6,7,8,9,10   ; test data
multiplier DWORD 10                     ; test data

.code
main PROC
    cld                         ; direction = forward
    mov  esi,OFFSET array       ; source index
    mov  edi,esi                ; destination index
    mov  ecx,LENGTHOF array     ; loop counter
L1: lodsd                       ; load [ESI] into EAX: EAX = 1 → 2 → 3 차례로
    mul  multiplier             ; multiply by a value: EAX = 10 → 20 → 30 차례로
    stosd                       ; store EAX into [EDI]
    loop L1                     ; 끝나면 array = [10, 20, 30, 40, 50, 60, 70, 80, 90, 100]
    exit
main ENDP
END main
```

ESI와 EDI가 **같은 배열**을 가리키게 하면 읽은 자리에 결과를 다시 쓰게 된다. `LODSD`가 ESI를, `STOSD`가 EDI를 각각 4씩 옮기므로 두 포인터는 나란히 움직인다. `MUL`이 EDX를 바꾸므로 EDX에 중요한 값이 있으면 미리 저장해야 한다.

#### LODSB와 STOSB로 변환하며 복사하기 (보충)

`LODSB`와 `STOSB`를 짝지으면 문자열을 읽으면서 바꿔 쓸 수 있다. 다음 코드는 소문자를 대문자로 바꾸면서 복사하고, 널 문자까지 복사하면 멈춘다.

```asm
.data
source BYTE "Hello, asm!",0
target BYTE 12 DUP(?)
.code
mov  esi,OFFSET source
mov  edi,OFFSET target
cld
L1: lodsb                       ; AL = [ESI], ESI + 1
    cmp  al,'a'
    jb   L2
    cmp  al,'z'
    ja   L2
    sub  al,20h                 ; 소문자 → 대문자
L2: stosb                       ; [EDI] = AL, EDI + 1
    cmp  al,0                   ; 널을 복사했으면 끝
    jne  L1                     ; 끝나면 target = "HELLO, ASM!"
```

### 문자열 명령어는 빠를까 (보충)

명령어 하나로 반복하니 당연히 빠를 것 같지만, 실제 속도는 명령어마다 다르다. 64MiB 블록을 각 방법으로 처리하는 시간을 재 보았다(이 문서를 만든 환경의 Intel Xeon 2.3GHz, 64비트 빌드에서 같은 명령어를 RSI·RDI·RCX로 실행, 다섯 번 중 가장 빠른 값을 세 번 잰 범위).

| 작업 | 문자열 명령어 | 단순 바이트 루프 | C 라이브러리 |
|---|---|---|---|
| 복사 | `rep movsb` 10~13ms (`rep movsd`도 비슷) | 30~32ms | `memcpy` 11~13ms |
| 채우기 | `rep stosb` 3~5ms | 19~20ms | `memset` 4~7ms |
| 값 찾기 | `repne scasb` 18~21ms | 33~39ms | `memchr` 3~6ms |
| 비교 | `repe cmpsb` 21~23ms | 32~38ms | `memcmp` 9~12ms |

- `REP MOVSB`·`REP STOSB`는 C 라이브러리의 `memcpy`·`memset`과 맞먹는다. 인텔 매뉴얼에 따르면 최근 프로세서는 이 두 명령어를 내부적으로 여러 원소씩 묶어 처리하는 **빠른 문자열 연산**(fast-string operation)을 지원하고, `CPUID`의 해당 비트(EAX = 7, ECX = 0일 때 EBX의 9번 비트)로 강화된 `REP MOVSB`·`REP STOSB` 지원 여부를 알려 준다.
- `REPNE SCASB`·`REPE CMPSB`는 단순한 바이트 루프보다는 빨랐지만 한 번에 한 바이트씩 비교하므로, SIMD 명령어로 16~32바이트씩 비교하는 `memchr`·`memcmp`보다 몇 배 느렸다.

측정값은 CPU와 데이터 크기에 따라 크게 달라진다. 결론만 기억하자면, 복사와 채우기에는 `REP MOVS`·`REP STOS`를 마음 놓고 쓰되, 아주 큰 데이터를 검색·비교하는 코드가 성능에 중요하다면 라이브러리 함수나 SIMD 명령어를 쓰는 편이 낫다.

---

## 9.3 문자열 프로시저 (Selected String Procedures)

이 절에서는 Irvine32 라이브러리에서 **널로 끝나는 문자열**(null-terminated string)을 다루는 프로시저 몇 가지를 살펴본다(In this section, we will demonstrate several procedures from the Irvine32 library that manipulate null-terminated strings). 모두 `Irvine32.inc`에 원형이 있으므로 `INVOKE`로 부른다.

| 프로시저 | 원형 (`Irvine32.inc`) | 하는 일 | C 표준 함수 |
|---|---|---|---|
| `Str_compare` | `Str_compare PROTO, string1:PTR BYTE, string2:PTR BYTE` | 두 문자열을 비교해 결과를 CF·ZF에 남긴다 | `strcmp` |
| `Str_length` | `Str_length PROTO, pString:PTR BYTE` | 길이를 EAX로 돌려준다 | `strlen` |
| `Str_copy` | `Str_copy PROTO, source:PTR BYTE, target:PTR BYTE` | 원본을 대상으로 복사한다 | `strcpy` |
| `Str_trim` | `Str_trim PROTO, pString:PTR BYTE, char:BYTE` | 끝에 붙은 지정 문자를 모두 지운다 | (없음) |
| `Str_ucase` | `Str_ucase PROTO, pString:PTR BYTE` | 문자열을 대문자로 바꾼다 | (`_strupr`, 비표준) |

### Str_compare 프로시저 (Str_compare Procedure)

```text
INVOKE Str_compare, ADDR string1, ADDR string2
```

`Str_compare`는 두 문자열을 첫 바이트부터 앞으로 차례로 비교한다. 대문자와 소문자는 ASCII 코드가 다르므로 대소문자를 구분한다(The comparison is case sensitive because ASCII codes are different for uppercase and lowercase letters). 반환값은 없고, 결과는 CF와 ZF로 알 수 있다(교재 Table 9-3).

| 관계 (Relation) | CF (Carry Flag) | ZF (Zero Flag) | 참이면 점프 (Branch If True) |
|---|---|---|---|
| string1 < string2 | 1 | 0 | `JB` |
| string1 = string2 | 0 | 1 | `JE` |
| string1 > string2 | 0 | 0 | `JA` |

```asm
;-----------------------------------------------------------
Str_compare PROC USES eax edx esi edi,
    string1:PTR BYTE,
    string2:PTR BYTE
;
; Compares two strings.
; Returns nothing, but the Zero and Carry flags are affected
; exactly as they would be by the CMP instruction.
;-----------------------------------------------------------
    mov  esi,string1
    mov  edi,string2
L1: mov  al,[esi]
    mov  dl,[edi]
    cmp  al,0                   ; end of string1?
    jne  L2                     ; no
    cmp  dl,0                   ; yes: end of string2?
    jne  L2                     ; no
    jmp  L3                     ; yes, exit with ZF = 1
L2: inc  esi                    ; point to next
    inc  edi
    cmp  al,dl                  ; characters equal?
    je   L1                     ; yes: continue loop
                                ; no: exit with flags set
L3: ret
Str_compare ENDP
```

두 문자열이 동시에 끝나면(둘 다 널) `jmp L3`로 빠져나가는데, 바로 앞의 `cmp dl,0`이 ZF = 1을 남겼으므로 "같다"가 된다. 그렇지 않으면 두 문자가 다를 때 `cmp al,dl`의 결과를 그대로 들고 돌아간다. `INC`는 CF를 바꾸지 않고, 마지막 `CMP` 뒤에는 `JE`와 `RET`만 있으므로 CF·ZF가 그대로 호출한 쪽에 전달된다. 한쪽 문자열이 먼저 끝나면 널(0)과 다른 문자를 비교하게 되어, 짧은 쪽이 작다고 판정된다.

`REPE CMPSB`를 쓰지 않은 이유는 두 문자열의 길이를 미리 모르기 때문이다. 슬라이드의 설명처럼 `CMPSB`는 길이를 아는 큰 문자열이나 배열을 다룰 때 가장 효과적이다(CMPSB is most effective when dealing with large strings or arrays of known length).

직접 여러 쌍을 비교해 보자. 표에서 문자열 주소 두 개씩을 꺼내 `Str_compare`를 부르고, CF·ZF에 따라 `<`, `=`, `>`를 출력한다.

```asm
; Str_compare의 결과 확인하기
INCLUDE Irvine32.inc

.data
s1 BYTE "ABC",0
s2 BYTE "ABD",0
s3 BYTE "ABCD",0
s4 BYTE "abc",0
s5 BYTE 0                       ; 빈 문자열
pairs DWORD s1,s1, s1,s2, s3,s1, s4,s1, s5,s1
quote BYTE '"',0

.code
main PROC
    mov  esi,OFFSET pairs
    mov  ecx,LENGTHOF pairs / 2
L1: INVOKE Str_compare, [esi], [esi+4]
    mov  al,'='
    je   L2                     ; ZF가 1이면 같다
    mov  al,'<'
    jb   L2                     ; CF가 1이면 작다
    mov  al,'>'                 ; 나머지: 크다
L2: push eax
    mov  edx,[esi]
    call ShowQuoted
    pop  eax
    call WriteChar
    mov  edx,[esi+4]
    call ShowQuoted
    call Crlf
    add  esi,8
    loop L1
    exit
main ENDP

ShowQuoted PROC                 ; " + EDX가 가리키는 문자열 + " 를 출력한다
    push edx
    mov  edx,OFFSET quote
    call WriteString
    pop  edx
    call WriteString
    mov  edx,OFFSET quote
    call WriteString
    ret
ShowQuoted ENDP
END main
```

실행 결과:

```text
"ABC"="ABC"
"ABC"<"ABD"
"ABCD">"ABC"
"abc">"ABC"
""<"ABC"
```

- `"ABCD"`와 `"ABC"`는 네 번째 자리에서 `'D'`(44h)와 널(0)을 비교하게 되어 `"ABCD"`가 크다.
- `"abc"`가 `"ABC"`보다 큰 것은 소문자 `'a'`(61h)가 대문자 `'A'`(41h)보다 크기 때문이다. 대소문자를 무시하고 비교하려면 두 문자열을 모두 `Str_ucase`로 바꾼 뒤 비교하거나, 비교하기 전에 각 문자를 대문자로 바꾸는 프로시저를 따로 만든다.
- `MOV`는 플래그를 바꾸지 않으므로, `mov al,'='`처럼 사이에 끼워 넣어도 `JE`·`JB`가 `Str_compare`의 결과를 그대로 본다.

### Str_length 프로시저 (Str_length Procedure)

`Str_length`는 문자열의 길이를 EAX로 돌려준다. 부를 때는 문자열의 오프셋을 넘긴다(When you call it, pass the string's offset).

```text
INVOKE Str_length, ADDR myString
```

```asm
Str_length PROC USES edi,
    pString:PTR BYTE            ; pointer to string
    mov  edi,pString
    mov  eax,0                  ; character count
L1: cmp  BYTE PTR [edi],0       ; end of string?
    je   L2                     ; yes: quit
    inc  edi                    ; no: point to next
    inc  eax                    ; add 1 to count
    jmp  L1
L2: ret
Str_length ENDP
```

널 문자를 만날 때까지 포인터와 카운터를 함께 늘린다. 9.2절의 `REPNE SCASB` 방법과 결과는 같다. 길이에 널은 들어가지 않으므로, 문자열을 담는 데 필요한 바이트 수는 `Str_length`의 결과 + 1이다.

```asm
.data
empty BYTE 0
greet BYTE "Hello, World",0
.code
INVOKE Str_length, ADDR empty   ; EAX = 0
INVOKE Str_length, ADDR greet   ; EAX = 12
```

### Str_copy 프로시저 (Str_copy Procedure)

`Str_copy`는 널로 끝나는 문자열을 원본 위치에서 대상 위치로 복사한다. 부르기 전에 대상이 복사될 문자열을 담을 만큼 큰지 반드시 확인해야 한다(Before calling this procedure, you must make sure the target operand is large enough to hold the copied string).

```text
INVOKE Str_copy, ADDR source, ADDR target
```

```asm
;-----------------------------------------------------------
Str_copy PROC USES eax ecx esi edi,
    source:PTR BYTE,            ; source string
    target:PTR BYTE             ; target string
;
; Copies a string from source to target.
; Requires: the target string must contain enough
;           space to hold a copy of the source string.
;-----------------------------------------------------------
    INVOKE Str_length,source    ; EAX에 원본의 길이
    mov  ecx,eax                ; REP count
    inc  ecx                    ; add 1 for null byte
    mov  esi,source
    mov  edi,target
    cld                         ; direction = forward
    rep  movsb                  ; copy the string
    ret
Str_copy ENDP
```

길이를 먼저 구한 다음, 널까지 포함해 (길이 + 1)바이트를 `REP MOVSB`로 한 번에 복사한다. 이 프로시저는 대상의 크기를 알 방법이 없으므로, 대상이 작으면 그 뒤의 메모리를 그대로 덮어쓴다. C의 `strcpy`가 위험하다고 하는 이유와 같다.

```asm
.data
source BYTE "HELLO WORLD",0     ; 12바이트 (널 포함)
target BYTE 6 DUP(0)            ; 6바이트밖에 없다
next   BYTE "*****",0           ; target 바로 뒤의 다른 변수
.code
INVOKE Str_copy, ADDR source, ADDR target   ; next = "WORLD"
```

`target`에 들어가지 못한 7바이트(`"WORLD"`와 널)가 바로 뒤의 변수 `next`를 덮어썼다. 대상의 크기를 함께 받아 그 이상은 복사하지 않는 프로시저는 [부록 F 연습 1](#연습-1-길이를-제한하는-문자열-복사)에서 만든다.

### Str_trim 프로시저 (Str_trim Procedure)

`Str_trim`은 널로 끝나는 문자열의 **끝에 붙은** 지정 문자를 모두 지운다(removes all occurrences of a selected trailing character from a null terminated string).

```text
INVOKE Str_trim, ADDR string, char_to_trim
```

이 프로시저가 처리해야 하는 경우는 다음 다섯 가지다.

1. 문자열이 비어 있다.
2. 다른 문자 뒤에 지울 문자가 하나 이상 붙어 있다. 예: `"Hello##"`
3. 지울 문자 하나로만 이루어져 있다. 예: `"#"`
4. 지울 문자가 없다. 예: `"Hello"`, `"H"`
5. 지울 문자가 앞에 있고 그 뒤에 다른 문자가 있다. 예: `"#H"`, `"###Hello"`

```asm
;-----------------------------------------------------------
; Str_trim
; Remove all occurrences of a given delimiter
; character from the end of a string.
; Returns: nothing
;-----------------------------------------------------------
Str_trim PROC USES eax ecx edi,
    pString:PTR BYTE,           ; points to string
    char:BYTE                   ; character to remove
    mov  edi,pString            ; prepare to call Str_length
    INVOKE Str_length,edi       ; returns the length in EAX
    cmp  eax,0                  ; is the length equal to zero?
    je   L3                     ; yes: exit now
    mov  ecx,eax                ; no: ECX에 문자열 길이
    dec  eax
    add  edi,eax                ; point to last character
L1: mov  al,[edi]               ; get a character
    cmp  al,char                ; is it the delimiter?
    jne  L2                     ; no: insert null byte
    dec  edi                    ; yes: keep backing up
    loop L1                     ; until beginning reached
L2: mov  BYTE PTR [edi+1],0     ; insert a null byte
L3: ret
Str_trim ENDP
```

> [!NOTE]
> **슬라이드 정정**: 슬라이드 16번 코드의 마지막 줄은 `Stmr_trim ENDP`로 되어 있다. `ENDP` 앞의 이름은 `PROC`의 이름과 같아야 하므로 이대로는 어셈블되지 않는다. `Str_trim ENDP`가 맞다.

**알고리즘** (Detailed Description): 문자열의 끝에서 시작해 거꾸로 훑으며 지울 문자가 아닌 첫 문자를 찾는다. 찾으면 그 문자 바로 다음 위치에 널 바이트를 넣는다(When it finds one, a null byte is inserted into the string just after the character position).

```text
ecx = length(str)
if length(str) > 0 then
    edi = length - 1
    do while ecx > 0
        if str[edi] != delimiter then
            str[edi+1] = null
            break
        else
            edi = edi - 1
        end if
        ecx = ecx - 1
    end do
```

가장 까다로운 것은 **문자열 전체가 지울 문자**인 경우(`"#"`, `"###"`)다. 이때는 `loop L1`이 ECX = 0으로 끝날 때까지 지울 문자가 아닌 것을 찾지 못하고, EDI는 첫 문자의 한 칸 **앞**까지 내려간다. 그 상태로 `L2`에 떨어져 `[edi+1]`, 즉 첫 문자 자리에 널을 넣으므로 빈 문자열이 된다. 유사 코드에는 이 경우가 따로 적혀 있지 않지만, 어셈블리 코드에서는 루프가 끝나면 자연스럽게 `L2`로 이어지게 해서 처리한다.

교재 예제 `Trim.asm`처럼 결과를 대괄호로 감싸 출력하면 빈 문자열도 눈으로 확인할 수 있다(교재 Table 9-4의 경우에 `"###"`를 더했다). 슬라이드 15번의 `INVOKE ShowString,ADDR string_1`에 나오는 `ShowString`은 Irvine32 라이브러리의 프로시저가 아니라 `Trim.asm` 안에 정의된 프로시저다. 그래서 아래 프로그램에도 직접 정의해 두었다.

```asm
; Str_trim 시험하기 (Trim.asm을 바탕으로)
INCLUDE Irvine32.inc

ShowString PROTO, pString:PTR BYTE

.data
string_1 BYTE 0                 ; case 1: 빈 문자열
string_2 BYTE "#",0             ; case 3
string_3 BYTE "Hello##",0       ; case 2
string_4 BYTE "Hello",0         ; case 4
string_5 BYTE "H",0             ; case 4
string_6 BYTE "#H",0            ; case 5
string_7 BYTE "###",0           ; 전부 지울 문자
strings DWORD string_1, string_2, string_3, string_4, string_5, string_6, string_7

.code
main PROC
    mov  esi,OFFSET strings
    mov  ecx,LENGTHOF strings
L1: INVOKE Str_trim, [esi], '#'
    INVOKE ShowString, [esi]
    add  esi,4
    loop L1
    exit
main ENDP

;-----------------------------------------------------------
ShowString PROC USES edx, pString:PTR BYTE
; Display a string surrounded by brackets.
;-----------------------------------------------------------
.data
lbracket BYTE "[",0
rbracket BYTE "]",0
.code
    mov  edx,OFFSET lbracket
    call WriteString
    mov  edx,pString
    call WriteString
    mov  edx,OFFSET rbracket
    call WriteString
    call Crlf
    ret
ShowString ENDP
END main
```

실행 결과:

```text
[]
[]
[Hello]
[Hello]
[H]
[#H]
[]
```

| 입력 문자열 (Input String) | 결과 (Expected Modified String) |
|---|---|
| `""` | `""` |
| `"Hello##"` | `"Hello"` |
| `"#"` | `""` (빈 문자열) |
| `"Hello"` | `"Hello"` |
| `"H"` | `"H"` |
| `"#H"` | `"#H"` |
| `"###"` | `""` |

`"#H"`처럼 지울 문자가 **앞**에 있는 경우는 그대로 남는다. `Str_trim`은 끝에 붙은 문자만 지운다.

#### SCASB로 만든 옛 버전과 방향 플래그 (보충)

Irvine32 라이브러리 소스에는 주석으로 막아 둔 옛 버전의 `Str_trim`이 남아 있다. 문자열의 끝에서 `STD`와 `REPE SCASB`로 거꾸로 훑는 방식인데, `STD`로 바꾼 방향 플래그를 되돌리지 않고 돌아간다. 그러면 그 뒤에 `CLD` 없이 문자열 명령어를 쓰는 코드가 모두 거꾸로 동작한다.

```asm
; 방향 플래그를 되돌리지 않는 프로시저의 부작용
INCLUDE Irvine32.inc

OldTrim PROTO, pString:PTR BYTE, char:BYTE

.data
text   BYTE "Hi!!!",0
source BYTE "ABC",0
target BYTE "xyz",0

.code
main PROC
    cld
    INVOKE OldTrim, ADDR text, '!'  ; text = "Hi", DF = 1
    mov  esi,OFFSET source          ; CLD 없이 복사하면
    mov  edi,OFFSET target
    mov  ecx,3
    rep  movsb                      ; 거꾸로 복사된다: target = "Ayz", source = "AB!"
    cld                             ; DF = 0
    exit
main ENDP

;-----------------------------------------------------------
; 라이브러리 소스에 주석으로 남아 있는 옛 Str_trim
; (이름만 OldTrim으로 바꿨다)
;-----------------------------------------------------------
OldTrim PROC USES eax ecx edi,
    pString:PTR BYTE,           ; points to string
    char:BYTE                   ; char to remove
    mov  edi,pString
    INVOKE Str_length,edi       ; returns length in EAX
    cmp  eax,0                  ; zero-length string?
    je   L2                     ; yes: exit
    mov  ecx,eax                ; no: counter = string length
    dec  eax
    add  edi,eax                ; EDI points to last char
    mov  al,char                ; char to trim
    std                         ; direction = reverse
    repe scasb                  ; skip past trim character
    jne  L1                     ; removed first character?
    dec  edi                    ; adjust EDI (ZF가 1이고 ECX가 0일 때)
L1: mov  BYTE PTR [edi+2],0     ; insert null byte
L2: ret                         ; DF를 1로 둔 채 돌아간다
OldTrim ENDP
END main
```

`DF = 1`인 채로 `rep movsb`를 실행하면 첫 바이트 `'A'`를 복사한 뒤 ESI·EDI가 **감소**해 `source`와 `target`의 앞쪽 메모리로 나머지 두 바이트를 옮긴다. 그래서 `target`은 첫 글자만 바뀐 `"Ayz"`가 되고, `target` 앞에 있던 `source`의 끝부분이 `text`에 남아 있던 `'!'`로 덮어쓰여 `"AB!"`가 된다. 현재 라이브러리의 `Str_trim`이 문자열 명령어 대신 평범한 루프를 쓰는 것도 이런 부작용이 없다는 장점이 있다. 문자열 명령어로 거꾸로 훑었다면 돌아가기 전에 반드시 `CLD`를 실행한다.

### Str_ucase 프로시저 (Str_ucase Procedure)

`Str_ucase`는 문자열의 문자를 모두 대문자로 바꾼다. 반환값은 없다(It returns no value).

```text
INVOKE Str_ucase, ADDR myString
```

```asm
;-----------------------------------------------------------
; Str_ucase
; Converts a null-terminated string to uppercase.
; Returns: nothing
;-----------------------------------------------------------
Str_ucase PROC USES eax esi,
    pString:PTR BYTE
    mov  esi,pString
L1: mov  al,[esi]               ; get char
    cmp  al,0                   ; end of string?
    je   L3                     ; yes: quit
    cmp  al,'a'                 ; below "a"?
    jb   L2
    cmp  al,'z'                 ; above "z"?
    ja   L2
    and  BYTE PTR [esi],11011111b   ; convert the char
L2: inc  esi                    ; next char
    jmp  L1
L3: ret
Str_ucase ENDP
```

ASCII에서 소문자와 대문자는 **5번 비트**(20h) 하나만 다르다(`'a'` = 61h = 0110 0001b, `'A'` = 41h = 0100 0001b). 그래서 `11011111b`(DFh)와 `AND`하면 5번 비트만 지워져 대문자가 된다. 소문자 범위(`'a'`~`'z'`)인지 먼저 확인하는 것은, 숫자나 기호처럼 5번 비트가 1인 다른 문자를 망가뜨리지 않기 위해서다. 예를 들어 `'1'`(31h)에 그대로 `AND`하면 11h라는 제어 문자가 된다.

```asm
.data
myString BYTE "Hello, asm 9!",0
.code
INVOKE Str_ucase, ADDR myString ; myString = "HELLO, ASM 9!"
```

### 문자열 라이브러리 시연 프로그램 (String Library Demo Program)

교재의 `StringDemo.asm`은 이 절의 프로시저를 한 프로그램에서 차례로 부른다. `compare_strings`에서는 MASM의 고급 조건문 `.IF`·`.ELSEIF`·`.ELSE`·`.ENDIF`와 플래그 검사 연산자 `ZERO?`, `CARRY?`를 썼다. 어셈블러가 이것들을 `JE`·`JB` 같은 조건부 점프로 바꿔 준다.

```asm
; String Library Demo          (StringDemo.asm)
; This program demonstrates the string-handling procedures in
; the book's link library.
INCLUDE Irvine32.inc

.data
string_1 BYTE "abcde////",0
string_2 BYTE "ABCDE",0
msg0     BYTE "string_1 in upper case: ",0
msg1     BYTE "string_1 and string_2 are equal",0
msg2     BYTE "string_1 is less than string_2",0
msg3     BYTE "string_2 is less than string_1",0
msg4     BYTE "Length of string_2 is ",0
msg5     BYTE "string_1 after trimming: ",0

.code
main PROC
    call trim_string
    call upper_case
    call compare_strings
    call print_length
    exit
main ENDP

trim_string PROC
; Remove trailing characters from string_1.
    INVOKE Str_trim, ADDR string_1, '/'     ; string_1 = "abcde"
    mov  edx,OFFSET msg5
    call WriteString
    mov  edx,OFFSET string_1
    call WriteString
    call Crlf
    ret
trim_string ENDP

upper_case PROC
; Convert string_1 to upper case.
    mov  edx,OFFSET msg0
    call WriteString
    INVOKE Str_ucase, ADDR string_1         ; string_1 = "ABCDE"
    mov  edx,OFFSET string_1
    call WriteString
    call Crlf
    ret
upper_case ENDP

compare_strings PROC
; Compare string_1 to string_2.
    INVOKE Str_compare, ADDR string_1, ADDR string_2  ; ZF = 1
    .IF ZERO?
      mov  edx,OFFSET msg1
    .ELSEIF CARRY?
      mov  edx,OFFSET msg2      ; string 1 is less than...
    .ELSE
      mov  edx,OFFSET msg3      ; string 2 is less than...
    .ENDIF
    call WriteString
    call Crlf
    ret
compare_strings ENDP

print_length PROC
; Display the length of string_2.
    mov  edx,OFFSET msg4
    call WriteString
    INVOKE Str_length, ADDR string_2        ; EAX = 5
    call WriteDec
    call Crlf
    ret
print_length ENDP
END main
```

실행 결과(슬라이드 23번은 비어 있어 실행 결과로 채웠다):

```text
string_1 after trimming: abcde
string_1 in upper case: ABCDE
string_1 and string_2 are equal
Length of string_2 is 5
```

`string_1`은 끝의 `/` 네 개가 지워져 `"abcde"`가 되고, 대문자로 바뀐 뒤에는 `string_2`와 같아진다. 프로시저들이 `string_1`을 **제자리에서**(in place) 바꾸므로 호출 순서가 결과에 영향을 준다. 예를 들어 `compare_strings`를 `upper_case`보다 먼저 부르면 `"abcde"` > `"ABCDE"`이므로 msg3이 출력된다.

### Irvine64 라이브러리의 문자열 프로시저 (보충)

교재 9.3.7절의 내용이다. 64비트 라이브러리 `Irvine64`에도 `Str_compare`, `Str_copy`, `Str_length`가 있지만, 64비트 MASM에는 `INVOKE`가 없으므로 인수를 **레지스터**로 받는다.

| 프로시저 | 받는 값 | 돌려주는 값 |
|---|---|---|
| `Str_compare` | RSI = 원본 문자열, RDI = 대상 문자열 | CF·ZF (32비트 버전과 같은 의미) |
| `Str_copy` | RSI = 원본, RDI = 대상 | 없음 |
| `Str_length` | RCX = 문자열 | RAX = 길이 |

본문의 코드는 32비트 버전과 같고 레지스터 이름만 64비트(RSI, RDI, RAX)로 바뀌었다. `Str_copy`는 `Str_length`를 부르기 위해 RSI의 값을 RCX에 옮긴 뒤 `rep movsb`로 복사한다. 교재 예제 `StringLib64Test.asm`은 `Str_length`를 부르기 전에 문자열 주소를 RAX에 넣는데, `Irvine64.asm`의 `Str_length`는 RCX를 읽으므로 그대로 쓰려면 `mov rcx,OFFSET source`로 고쳐야 한다.

---

## 9.4 2차원 배열 (Two-Dimensional Arrays)

### 행과 열의 순서 (Ordering of Rows and Columns)

메모리는 한 줄로 늘어선 바이트들이므로, 2차원 배열(표, 행렬)도 실제로는 1차원으로 펼쳐서 저장한다. 펼치는 방법은 두 가지다(교재 Figure 9-1).

```text
 Logical arrangement:   10  20  30  40  50
                        60  70  80  90  A0
                        B0  C0  D0  E0  F0

 Row-major order:       10 20 30 40 50 | 60 70 80 90 A0 | B0 C0 D0 E0 F0
 Column-major order:    10 60 B0 | 20 70 C0 | 30 80 D0 | 40 90 E0 | 50 A0 F0
```

| 순서 | 저장하는 방법 | 쓰는 언어 (예) |
|---|---|---|
| **행 우선** (row-major order) | 첫 번째 행을 통째로 저장하고, 이어서 두 번째 행, … | C, C++(C 스타일 배열), 파스칼 |
| **열 우선** (column-major order) | 첫 번째 열을 통째로 저장하고, 이어서 두 번째 열, … | 포트란(Fortran), MATLAB, R, Julia |

자바의 2차원 배열은 "배열의 배열"이라 행들이 메모리에 이어져 있다는 보장이 없다. 어셈블리에서는 어느 순서로 저장할지를 프로그래머가 정하고, 그에 맞게 주소를 계산한다. 이 장의 예제는 모두 행 우선이다. 행이 R개, 열이 C개, 원소 크기가 S바이트인 배열에서 원소 (r, c)의 위치는 다음과 같다(행·열 번호는 0부터 센다).

| 순서 | 원소 (r, c)의 오프셋 |
|---|---|
| 행 우선 | (r × C + c) × S = **r × (행의 바이트 수)** + c × S |
| 열 우선 | (c × R + r) × S |

위 그림의 3 × 5 바이트 배열에서 원소 (1, 2)인 80h의 오프셋은 행 우선이면 1 × 5 + 2 = 7, 열 우선이면 2 × 3 + 1 = 7이다(우연히 같다). 원소 (2, 1)인 C0h는 행 우선이면 11, 열 우선이면 5로 서로 다르다.

### 베이스-인덱스 피연산자 (Base-Index Operands)

**베이스-인덱스 피연산자**는 두 레지스터(베이스 base와 인덱스 index라고 부른다)의 값을 더해 오프셋 주소를 만든다(adds the values of two registers, producing an offset address).

```text
[base + index]
```

32비트 모드에서는 32비트 범용 레지스터 두 개를 아무것이나 쓸 수 있다(단, ESP는 인덱스가 될 수 없다).

```asm
.data
array WORD 1000h,2000h,3000h
.code
mov  ebx,OFFSET array
mov  esi,2
mov  ax,[ebx+esi]               ; AX = 2000h
mov  edi,OFFSET array
mov  ecx,4
mov  ax,[edi+ecx]               ; AX = 3000h
mov  ebp,OFFSET array
mov  esi,0
mov  ax,[ebp+esi]               ; AX = 1000h
```

인덱스(2, 4)는 원소 번호가 아니라 **바이트 오프셋**이다. WORD 배열이므로 2는 두 번째 원소, 4는 세 번째 원소다.

> [!TIP]
> 마지막 예처럼 EBP를 베이스로 쓰면 CPU는 기본적으로 스택 세그먼트(SS)를 기준으로 주소를 계산한다. 평면(flat) 메모리 모델에서는 SS와 DS가 같은 메모리를 가리키므로 결과는 같지만, EBP는 8장에서 본 것처럼 스택 프레임의 기준점이므로 일반 데이터를 가리키는 데에는 쓰지 않는 것이 좋다. 함수 안에서 EBP를 바꾸면 매개변수와 지역 변수에 접근할 수 없게 된다.

#### 2차원 배열 (Two-Dimensional Array)

행 우선 순서로 2차원 배열에 접근할 때는 **행의 오프셋**을 베이스 레지스터에, **열의 오프셋**을 인덱스 레지스터에 둔다(the row offset is held in the base register and the column offset is in the index register).

```asm
.data
tableB  BYTE   10h,  20h,  30h,  40h,  50h
Rowsize = ($ - tableB)
        BYTE   60h,  70h,  80h,  90h, 0A0h
        BYTE  0B0h, 0C0h, 0D0h, 0E0h, 0F0h
.code
row_index = 1
column_index = 2
mov  ebx,OFFSET tableB          ; table offset
add  ebx,RowSize * row_index    ; row offset
mov  esi,column_index
mov  al,[ebx + esi]             ; AL = 80h
```

`Rowsize = ($ - tableB)`는 첫 행을 정의한 직후의 위치 카운터(`$`)에서 `tableB`의 시작을 뺀 것이므로 첫 행의 바이트 수, 즉 5다. 행의 바이트 수를 상수로 직접 쓰지 않고 이렇게 계산하면 행의 길이를 바꿔도 코드를 고칠 필요가 없다.

```text
 offset:  0150           0155  0157
          10 20 30 40 50 60 70 80 90 A0 B0 C0 D0 E0 F0
                         ^     ^
                       [ebx]  [ebx + esi]
```

`tableB`가 0150h에서 시작한다면, EBX는 행 1의 시작인 0150h + 5 = 0155h, `[ebx + esi]`는 0155h + 2 = 0157h이고 그 자리에 80h가 있다(교재 Figure 9-2).

> [!NOTE]
> 슬라이드 26번과 28번은 상수를 `Rowsize`(`RowsizeW`)로 정의하고 `RowSize`(`RowSizeW`)로 쓴다. MASM은 기본 설정에서 대소문자를 구분하지 않으므로 어셈블되지만, `OPTION CASEMAP:NONE`을 쓰면 정의되지 않은 기호라는 오류가 난다. 정의와 사용의 대소문자를 맞춰 쓰는 습관을 들이자.

### 행의 합 구하기 (Calculating a Row Sum)

다음 `calc_row_sum` 프로시저는 8비트 정수 행렬에서 선택한 행의 합을 구한다(calculates the sum of a selected row in a matrix of 8-bit integers).

```asm
;------------------------------------------------------------
; calc_row_sum
; Calculates the sum of a row in a byte matrix.
; Receives: EBX에 표의 오프셋, EAX에 행 번호,
;           ECX에 행의 크기(바이트)
; Returns:  EAX에 그 행의 합
;------------------------------------------------------------
calc_row_sum PROC USES ebx ecx edx esi
    mul  ecx                    ; row index * row size
    add  ebx,eax                ; row offset
    mov  eax,0                  ; accumulator
    mov  esi,0                  ; column index
L1: movzx edx,BYTE PTR [ebx + esi]  ; get a byte
    add  eax,edx                ; add to accumulator
    inc  esi                    ; next byte in row
    loop L1
    ret
calc_row_sum ENDP
```

`MUL`로 "행 번호 × 행의 크기"를 구해 행의 시작 오프셋을 만들고, ESI를 열 번호로 0부터 늘려 가며 `[ebx + esi]`로 원소를 읽는다. `MUL`이 EDX를 바꾸고 루프 안에서도 EDX를 쓰므로 `USES`에 EDX가 들어 있다. 바이트를 `MOVZX`로 32비트로 넓혀 더하므로 합이 255를 넘어도 넘치지 않는다. 교재 예제 `RowSum.asm`처럼 행 번호를 입력받아 합을 출력해 보자.

```asm
; Row Sum Calculation          (RowSum.asm)
INCLUDE Irvine32.inc

.data
tableB  BYTE  10h,  20h,  30h,  40h,  50h
        BYTE  60h,  70h,  80h,  90h, 0A0h
        BYTE  0B0h, 0C0h, 0D0h, 0E0h, 0F0h
RowSize = 5
msg1    BYTE "Enter row number: ",0
msg2    BYTE "The sum is: ",0

.code
main PROC
    mov  edx,OFFSET msg1        ; "Enter row number:"
    call WriteString
    call ReadInt                ; EAX = row number
    mov  ebx,OFFSET tableB
    mov  ecx,RowSize
    call calc_row_sum           ; EAX = 280h
    mov  edx,OFFSET msg2        ; "The sum is:"
    call WriteString
    call WriteHex               ; write sum in EAX
    call Crlf
    exit
main ENDP

calc_row_sum PROC USES ebx ecx edx esi
    mul  ecx                    ; row index * row size
    add  ebx,eax                ; row offset
    mov  eax,0                  ; accumulator
    mov  esi,0                  ; column index
L1: movzx edx,BYTE PTR [ebx + esi]  ; get a byte
    add  eax,edx                ; add to accumulator
    inc  esi                    ; next byte in row
    loop L1
    ret
calc_row_sum ENDP
END main
```

1을 입력했을 때의 실행 결과:

```text
Enter row number: 1
The sum is: 00000280
```

행 1의 합은 60h + 70h + 80h + 90h + A0h = 280h이다. 이 프로그램은 입력한 행 번호가 0~2 범위인지 검사하지 않는다. 3 이상을 넣으면 표 밖의 메모리를 더해 버리므로, 실제 프로그램이라면 `calc_row_sum`을 부르기 전에 범위를 검사해야 한다.

### 배율 (Scale Factors)

WORD 배열이라면 인덱스 피연산자에 배율 2를 곱한다(If you're writing code for an array of WORD, multiply the index operand by a scale factor of 2). 배율을 쓰면 인덱스 레지스터에 바이트 오프셋 대신 **원소 번호**를 그대로 둘 수 있다. 배율로 쓸 수 있는 값은 1, 2, 4, 8뿐이고, 원소 크기를 `TYPE`으로 쓰면 배열의 타입이 바뀌어도 코드를 고치지 않아도 된다.

```asm
.data
tableW  WORD   10h,  20h,  30h,  40h,  50h
RowsizeW = ($ - tableW)
        WORD   60h,  70h,  80h,  90h, 0A0h
        WORD  0B0h, 0C0h, 0D0h, 0E0h, 0F0h
.code
row_index = 1
column_index = 2
mov  ebx,OFFSET tableW              ; table offset
add  ebx,RowsizeW * row_index       ; row offset
mov  esi,column_index
mov  ax,[ebx + esi*TYPE tableW]     ; AX = 0080h
```

`RowsizeW`는 첫 행의 **바이트 수**(5 × 2 = 10)이므로 행 오프셋에는 배율을 곱하지 않고, 열 번호에만 `TYPE tableW`(2)를 곱한다. DWORD 배열이라면 같은 방식으로 `[ebx + esi*TYPE tableD]`(배율 4)를 쓴다.

```text
tableD DWORD 10h, 20h, ...etc.
.code
mov  eax,[ebx + esi*TYPE tableD]
```

### 베이스-인덱스-변위 피연산자 (Base-Index-Displacement Operands)

**베이스-인덱스-변위 피연산자**는 변위(displacement), 베이스 레지스터, 인덱스 레지스터, 그리고 선택적인 배율을 합쳐 유효 주소를 만든다. 변위는 변수 이름이나 상수식일 수 있다(Displacement can be the name of a variable or a constant expression).

```text
[base + index + displacement]
displacement[base + index]
```

변수 이름을 변위로 쓰면 표의 시작 주소를 레지스터에 따로 넣지 않아도 된다. 베이스 레지스터에는 행의 오프셋을, 인덱스 레지스터에는 열 번호를 둔다.

**더블워드 배열의 예** (Doubleword Array Example)

```asm
.data
tableD DWORD  10h,  20h,  30h,  40h,  50h
Rowsize = ($ - tableD)
       DWORD  60h,  70h,  80h,  90h, 0A0h
       DWORD 0B0h, 0C0h, 0D0h, 0E0h, 0F0h
.code
mov  ebx,Rowsize                    ; 행 1의 오프셋(바이트): EBX = 14h
mov  esi,2                          ; column index
mov  eax,tableD[ebx + esi*TYPE tableD]  ; EAX = 80h
```

```text
 offset:  0150             0164  016C
          10 20 30 40 50 | 60 70 80 90 A0 | B0 C0 D0 E0 F0     (DWORD 15개)
          ^                ^     ^
          tableD           |     tableD[ebx + esi*4]
                           tableD[ebx]                  (Rowsize = 0014h)
```

`tableD`가 0150h에서 시작하면, 행 1은 0150h + 14h = 0164h, 그 행의 열 2는 0164h + 2 × 4 = 016Ch이고 거기에 80h가 있다(교재 Figure 9-3).

> [!NOTE]
> **슬라이드 정정**: 슬라이드 29번의 `mov ebx,Rowsize`에는 주석이 `; row index`로 붙어 있다. 그러나 EBX에 들어가는 값은 행 번호(1)가 아니라 **행 1의 바이트 오프셋**(Rowsize = 20)이다. 행 번호 r을 쓰려면 `r × Rowsize`를 계산해 넣어야 한다. 교재 예제 `Base-Index.asm`의 `get_tableDval`이 그렇게 한다.

```asm
; 행·열 번호로 tableD의 값을 꺼내는 프로시저 (Base-Index.asm에서)
INCLUDE Irvine32.inc

.data
tableD DWORD  10000h,  20000h,  30000h,  40000h,  50000h
RowSizeD = ($ - tableD)
       DWORD  60000h,  70000h,  80000h,  90000h, 0A0000h
       DWORD 0B0000h, 0C0000h, 0D0000h, 0E0000h, 0F0000h

.code
main PROC
    mov  eax,2                  ; row index
    mov  esi,4                  ; column index
    call get_tableDval          ; get the value: EAX = 0F0000h
    call WriteHex               ; display EAX
    call Crlf
    exit
main ENDP

;------------------------------------------------------
get_tableDval PROC USES ebx edx
; Returns the array value at a given row and column
; in tableD, a two-dimensional array of doublewords.
; Receives: EAX에 행 번호, ESI에 열 번호
; Returns:  EAX에 그 원소의 값
;------------------------------------------------------
    mov  ebx,RowSizeD
    mul  ebx                    ; EAX에 행의 오프셋
    mov  eax,tableD[eax + esi*TYPE tableD]
    ret
get_tableDval ENDP
END main
```

실행 결과:

```text
000F0000
```

EAX를 베이스 레지스터로 썼다는 점에 주목하자. 베이스와 인덱스로는 ESP를 인덱스로 쓰는 경우를 빼고 어떤 32비트 범용 레지스터든 쓸 수 있다. 교재의 원본은 `USES ebx`만 지정했는데, `MUL`이 EDX를 바꾸므로 위 코드에서는 EDX도 지키도록 `USES ebx edx`로 고쳤다.

### 열 단위 처리와 순회 순서 (보충)

슬라이드 30번은 비어 있으므로 여기서는 **열**을 처리하는 방법과, 순회 순서가 속도에 주는 영향을 보충한다. 행 우선 배열에서 한 열의 원소들은 메모리에서 **행의 바이트 수만큼 떨어져** 있다. 그래서 열을 따라 내려갈 때는 베이스 레지스터에 행의 크기를 더한다.

```asm
; 각 열의 합 구하기
INCLUDE Irvine32.inc

.data
tableB  BYTE  10h,  20h,  30h,  40h,  50h
RowSize = ($ - tableB)
        BYTE  60h,  70h,  80h,  90h, 0A0h
        BYTE  0B0h, 0C0h, 0D0h, 0E0h, 0F0h
NumRows = ($ - tableB) / RowSize
colSums DWORD RowSize DUP(?)

.code
main PROC
    mov  esi,0                      ; 열 번호
L1: mov  ebx,OFFSET tableB          ; 행 0부터
    mov  eax,0                      ; 이 열의 합
    mov  ecx,NumRows
L2: movzx edx,BYTE PTR [ebx + esi]  ; (행, 열)의 원소
    add  eax,edx
    add  ebx,RowSize                ; 다음 행의 같은 열로
    loop L2
    mov  colSums[esi*4],eax         ; 열의 합 저장
    call WriteHex
    mov  al,' '
    call WriteChar
    inc  esi
    cmp  esi,RowSize
    jb   L1                         ; 끝나면 colSums = [120h, 150h, 180h, 1B0h, 1E0h]
    call Crlf
    exit
main ENDP
END main
```

실행 결과:

```text
00000120 00000150 00000180 000001B0 000001E0
```

첫 열의 합은 10h + 60h + B0h = 120h다. 행의 합에서는 ESI(열)를 1씩 늘렸고, 열의 합에서는 EBX(행의 시작)를 `RowSize`씩 늘린다는 점이 다르다. `NumRows = ($ - tableB) / RowSize`처럼 행의 개수도 어셈블할 때 계산할 수 있다.

**순회 순서와 캐시.** 행 우선 배열을 행 순서로 훑으면 메모리를 연속으로 읽지만, 열 순서로 훑으면 행의 크기만큼씩 건너뛰며 읽는다. CPU의 캐시는 연속된 주소를 한꺼번에 가져오므로 이 차이가 속도에 크게 나타난다. 4096 × 4096 크기의 `int` 배열(64MiB)의 합을 C로 구해 보니, 이 문서를 만든 환경에서 행 순서는 약 12ms, 열 순서는 약 153ms로 열 순서가 11~13배 느렸다(합은 같았다). 2차원 배열을 다루는 루프는 저장 순서와 같은 순서로 도는 것이 좋다.

### 64비트 모드의 베이스-인덱스 피연산자 (보충)

교재 9.4.4절의 내용이다. 64비트 모드에서는 64비트 레지스터로 같은 주소 지정을 한다. 교재 예제 `TwoDimArrays.asm`은 QWORD 표에서 행·열 번호로 값을 꺼낸다.

```asm
; 64비트 모드 예 (ml64): TwoDimArrays.asm의 get_tableVal
.data
table QWORD 1,2,3,4,5
RowSize = ($ - table)
      QWORD 6,7,8,9,10
      QWORD 11,12,13,14,15
.code
;------------------------------------------------------
; Returns the array value at a given row and column
; in a two-dimensional array of quadwords.
; Receives: RAX에 행 번호, RSI에 열 번호
; Returns:  RAX에 그 원소의 값
;------------------------------------------------------
get_tableVal PROC USES rbx
    mov  rbx,RowSize
    mul  rbx                        ; 행의 오프셋 (RDX도 바뀐다)
    mov  rax,table[rax + rsi*TYPE table]
    ret
get_tableVal ENDP

; 같은 일을 하되 table의 주소를 LEA로 구하는 버전
get_tableVal2 PROC USES rbx rdx
    mov  rbx,RowSize
    mul  rbx
    lea  rbx,table                  ; RIP 상대 주소로 table의 주소를 구한다
    add  rbx,rax                    ; 행의 시작
    mov  rax,[rbx + rsi*TYPE table]
    ret
get_tableVal2 ENDP
```

행 1, 열 4를 넘기면 10이 나온다(행 0이 1~5, 행 1이 6~10이다). 주의할 점이 하나 있다. 64비트 모드에서 변수 이름을 RIP 상대 주소로 바꿀 수 있는 것은 레지스터가 없는 `[변수]` 꼴뿐이다. `table[rax + rsi*8]`처럼 레지스터와 함께 쓰면 `table`의 주소가 **32비트 변위**로 명령어에 들어간다. 이 변위는 부호 확장되므로, 프로그램이 2GB 아래 주소에 놓일 때만 동작한다. Visual Studio에서는 이런 코드를 링크하면 `/LARGEADDRESSAWARE:NO`가 없으면 안 된다는 링커 오류(LNK2017)가 난다. 어디에 놓이든 동작해야 한다면 두 번째 버전처럼 먼저 `lea rbx,table`로 주소를 레지스터에 넣는다. 두 버전 모두 64비트로 빌드해 15개 원소를 모두 꺼내 보는 C 프로그램으로 확인했고, 첫 번째 버전은 위치 독립 실행 파일(PIE)로는 링크되지 않는 것도 확인했다.

---

## 9.5 정수 배열의 정렬과 검색 (Searching and Sorting Integer Arrays)

배열을 다루는 프로그램에서 가장 자주 하는 일은 정렬(sorting)과 검색(searching)이다. 이 절에서는 가장 단순한 정렬 알고리즘인 **버블 정렬**과, 정렬된 배열에서 빠르게 값을 찾는 **이진 검색**을 어셈블리로 구현한다.

### 버블 정렬 (Bubble Sort)

버블 정렬은 0번과 1번 위치부터 시작해 **이웃한 두 값**을 비교한다. 두 값의 순서가 거꾸로 되어 있으면 서로 바꾼다(If the compared values are in reverse order, they are exchanged). 배열 끝까지 한 번 훑고 나면 아직 정렬이 끝나지는 않았지만, **가장 큰 값**이 가장 높은 인덱스 위치로 가 있다(the largest value is now in the highest index position). 바깥 루프가 다시 훑기를 시작하고, n − 1번 훑고 나면 배열은 반드시 정렬된다(After n-1 passes, the array is guaranteed to be sorted).

교재 Figure 9-4의 배열 [3, 1, 7, 5, 2, 9, 4, 3]로 첫 번째 훑기를 따라가 보자.

| 비교한 쌍 (위치) | 값 | 교환 | 비교 뒤의 배열 |
|---|---|---|---|
| 0, 1 | 3, 1 | 교환 | 1 3 7 5 2 9 4 3 |
| 1, 2 | 3, 7 | — | 1 3 7 5 2 9 4 3 |
| 2, 3 | 7, 5 | 교환 | 1 3 5 7 2 9 4 3 |
| 3, 4 | 7, 2 | 교환 | 1 3 5 2 7 9 4 3 |
| 4, 5 | 7, 9 | — | 1 3 5 2 7 9 4 3 |
| 5, 6 | 9, 4 | 교환 | 1 3 5 2 7 4 9 3 |
| 6, 7 | 9, 3 | 교환 | 1 3 5 2 7 4 3 9 |

큰 값(7, 그다음 9)이 거품처럼 오른쪽으로 떠올라 가서 "버블" 정렬이라고 부른다. 첫 훑기만 하는 코드로 확인해 보자.

```asm
; 버블 정렬의 첫 번째 훑기 (교재 Figure 9-4)
INCLUDE Irvine32.inc

.data
array SDWORD 3, 1, 7, 5, 2, 9, 4, 3

.code
main PROC
    mov  esi,OFFSET array
    mov  ecx,LENGTHOF array - 1     ; 비교할 쌍의 수
L2: mov  eax,[esi]                  ; get array value
    cmp  [esi+4],eax                ; compare a pair of values
    jge  L3                         ; 이미 순서대로면 교환하지 않는다
    xchg eax,[esi+4]                ; exchange the pair
    mov  [esi],eax
L3: add  esi,4                      ; move both pointers forward
    loop L2                         ; 끝나면 array = [1, 3, 5, 2, 7, 4, 3, 9]
    exit
main ENDP
END main
```

> [!NOTE]
> **슬라이드 정정**: 슬라이드 31번 그림(교재 Figure 9-4)의 마지막 열은 위에서부터 1, 3, 5, **7, 2**, 4, 3, 9로 그려져 있다. 바로 앞 단계에서 이미 2와 7의 순서가 바뀌었으므로 마지막 열은 1, 3, 5, **2, 7**, 4, 3, 9여야 한다(마지막 단계에서는 9와 3만 교환된다). 위 코드를 실행한 결과도 [1, 3, 5, 2, 7, 4, 3, 9]다.

**유사 코드** (Pseudocode). 바깥 루프의 카운터 `cx1`과 안쪽 루프의 카운터 `cx2`를 쓴다.

```text
cx1 = N - 1
while( cx1 > 0 )
{
    esi = addr(array)
    cx2 = cx1
    while( cx2 > 0 )
    {
        if( array[esi] > array[esi+4] )
            exchange( array[esi], array[esi+4] )
        add esi,4
        dec cx2
    }
    dec cx1
}
```

한 번 훑을 때마다 가장 큰 값이 끝으로 가므로, 다음 훑기에서는 비교할 쌍을 하나씩 줄여도 된다. 그래서 안쪽 루프의 횟수 `cx2`가 바깥 루프의 카운터 `cx1`에서 시작한다.

**어셈블리 언어** (Assembly Language). 두 루프가 모두 `LOOP`를 쓰므로 ECX 하나를 두 카운터로 번갈아 쓴다. 안쪽 루프에 들어가기 전에 바깥 루프의 카운터를 `push ecx`로 맡겨 두고, 안쪽 루프가 끝나면 `pop ecx`로 되찾는다.

```asm
;------------------------------------------------------
; BubbleSort
; Sort an array of 32-bit signed integers in ascending
; order, using the bubble sort algorithm.
; Receives: pointer to array, array size
; Returns: nothing
;------------------------------------------------------
BubbleSort PROC USES eax ecx esi,
    pArray:PTR DWORD,           ; pointer to array
    Count:DWORD                 ; array size
    mov  ecx,Count
    dec  ecx                    ; decrement count by 1
L1: push ecx                    ; save outer loop count
    mov  esi,pArray             ; point to first value
L2: mov  eax,[esi]              ; get array value
    cmp  [esi+4],eax            ; compare a pair of values
    jge  L3                     ; if [ESI] <= [ESI+4], no exchange
    xchg eax,[esi+4]            ; exchange the pair
    mov  [esi],eax
L3: add  esi,4                  ; move both pointers forward
    loop L2                     ; inner loop
    pop  ecx                    ; retrieve outer loop count
    loop L1                     ; else repeat outer loop
L4: ret
BubbleSort ENDP
```

> [!NOTE]
> **슬라이드 정정**: 슬라이드 33번의 코드는 `jg L3`이지만 주석은 "if [ESI] <= [ESI+4], no exchange"다. `JG`는 `[ESI+4] > [ESI]`일 때만 점프하므로, 두 값이 **같을 때도** 교환이 일어난다(결과는 같지만 쓸데없는 교환이다). 주석대로 동작하려면 위 코드와 교재 예제 파일 `BubbleSort.asm`처럼 `jge L3`를 써야 한다.

`CMP [esi+4],eax`는 `[ESI+4] − [ESI]`를 계산하므로, 부호 있는 비교 `JGE`는 `[ESI+4] ≥ [ESI]`, 즉 이미 오름차순일 때 점프해 교환을 건너뛴다. `XCHG`로 EAX(앞 원소)와 뒤 원소를 맞바꾼 다음, EAX에 들어온 뒤 원소를 앞 자리에 쓰면 교환이 끝난다. 전체 정렬을 실행해 보자.

```asm
; BubbleSort 실행하기
INCLUDE Irvine32.inc

BubbleSort PROTO, pArray:PTR DWORD, Count:DWORD

.data
array SDWORD 3, 1, 7, 5, 2, 9, 4, 3
one   SDWORD 42                 ; 원소가 하나뿐인 배열

.code
main PROC
    INVOKE BubbleSort, ADDR array, LENGTHOF array   ; array = [1, 2, 3, 3, 4, 5, 7, 9]
    INVOKE BubbleSort, ADDR one, 1                  ; one = [42]
    exit
main ENDP

BubbleSort PROC USES eax ecx esi,
    pArray:PTR DWORD,           ; pointer to array
    Count:DWORD                 ; array size
    mov  ecx,Count
    dec  ecx                    ; decrement count by 1
    jle  L4                     ; 원소가 0개나 1개면 할 일이 없다
L1: push ecx                    ; save outer loop count
    mov  esi,pArray             ; point to first value
L2: mov  eax,[esi]              ; get array value
    cmp  [esi+4],eax            ; compare a pair of values
    jge  L3                     ; if [ESI] <= [ESI+4], no exchange
    xchg eax,[esi+4]            ; exchange the pair
    mov  [esi],eax
L3: add  esi,4                  ; move both pointers forward
    loop L2                     ; inner loop
    pop  ecx                    ; retrieve outer loop count
    loop L1                     ; else repeat outer loop
L4: ret
BubbleSort ENDP
END main
```

> [!WARNING]
> 슬라이드의 `BubbleSort`는 `Count`가 1 이하인 경우를 검사하지 않는다. `Count`가 1이면 `dec ecx` 뒤에 ECX = 0인 채로 안쪽 루프에 들어가는데, `LOOP`는 ECX를 **먼저 줄이고** 0인지 검사하므로 0이 FFFFFFFFh가 되어 약 43억 번을 반복하며 배열 밖의 메모리를 읽고 쓴다. 위 코드는 `dec ecx` 다음에 `jle L4`를 넣어(쓰이지 않던 레이블 `L4`를 활용했다) 이 경우를 막았다. `DEC`는 ZF와 SF를 바꾸므로, ECX가 0이 되었거나(Count = 1) 음수가 되었으면(Count = 0) 바로 돌아간다.

비교 횟수는 (n − 1) + (n − 2) + … + 1 = n(n − 1)/2이다. 원소가 8개면 28번, 1,000개면 499,500번이다. 원소 수가 10배가 되면 비교는 약 100배가 되므로(O(n²)), 버블 정렬은 원소가 수백 개를 넘는 배열에는 적합하지 않다. 이미 정렬된 배열이라면 한 번 훑는 동안 교환이 한 번도 없다는 것을 보고 바로 끝낼 수 있는데, 이 개선은 [부록 F 연습 8](#연습-8-교환-여부로-일찍-끝나는-버블-정렬)에서 해 본다.

### 이진 검색 (Binary Search)

**이진 검색**(binary search)은 **정렬된** 배열에서 값을 찾는 방법이다. 매번 범위의 가운데 값과 비교해 찾는 범위를 절반으로 줄인다. 검색을 시작하기 전에 사용자에게 찾을 정수를 입력받는다. 이것을 `searchVal`이라고 하자.

1. 검색할 배열의 범위는 첨자 `first`와 `last`로 나타낸다. `first > last`이면 검색을 끝내고 찾지 못했다고 알린다.
2. `first`와 `last` 사이의 가운데 첨자(midpoint)를 계산한다.
3. `searchVal`을 가운데 위치의 정수와 비교한다.
   - 두 값이 같으면 가운데 첨자를 EAX에 넣고 프로시저에서 돌아간다. 이 반환값은 배열에서 값을 찾았다는 뜻이다.
   - `searchVal`이 가운데 값보다 크면 `first`를 가운데보다 한 칸 뒤로 옮긴다.
   - `searchVal`이 가운데 값보다 작으면 `last`를 가운데보다 한 칸 앞으로 옮긴다.
4. 1단계로 돌아간다.

> [!NOTE]
> **슬라이드 정정**: 슬라이드 34번 1단계의 "If f irst last, exit the search"는 단어가 깨지고 부등호가 빠졌다. "If **first > last**, exit the search"이다.

다음은 부호 있는 정수 배열에서 동작하도록 만든 C++ 이진 검색 함수다.

```cpp
int BinSearch( int values[], const int searchVal, int count )
{
    int first = 0;
    int last = count - 1;
    while( first <= last )
    {
        int mid = (last + first) / 2;
        if( values[mid] < searchVal )
            first = mid + 1;
        else if( values[mid] > searchVal )
            last = mid - 1;
        else
            return mid;      // success
    }
    return -1;               // not found
}
```

다음은 위 C++ 코드를 어셈블리로 구현한 것이다(The following listing shows an assembly language implementation of the sample C++ code). `first`, `last`, `mid`는 `LOCAL` 변수로 만들었다.

```asm
;-------------------------------------------------------------
; BinarySearch
; Searches an array of signed integers for a single value.
; Receives: Pointer to array, array size, search value.
; Returns: 찾으면 EAX에 그 원소의 위치(첨자),
;          못 찾으면 EAX에 -1
;-------------------------------------------------------------
BinarySearch PROC USES ebx edx esi edi,
    pArray:PTR DWORD,           ; pointer to array
    Count:DWORD,                ; array size
    searchVal:DWORD             ; search value
    LOCAL first:DWORD,          ; first position
    last:DWORD,                 ; last position
    mid:DWORD                   ; midpoint
    mov  first,0                ; first = 0
    mov  eax,Count              ; last = (count - 1)
    dec  eax
    mov  last,eax
    mov  edi,searchVal          ; EDI = searchVal
    mov  ebx,pArray             ; EBX points to the array
L1:                             ; while first <= last
    mov  eax,first
    cmp  eax,last
    jg   L5                     ; exit search
; mid = (last + first) / 2
    mov  eax,last
    add  eax,first
    shr  eax,1
    mov  mid,eax
; EDX = values[mid]
    mov  esi,mid
    shl  esi,2                  ; scale mid value by 4
    mov  edx,[ebx+esi]          ; EDX = values[mid]
; if ( EDX < searchVal(EDI) )
    cmp  edx,edi
    jge  L2
; first = mid + 1
    mov  eax,mid
    inc  eax
    mov  first,eax
    jmp  L4
; else if( EDX > searchVal(EDI) )
L2: cmp  edx,edi                ; optional
    jle  L3
; last = mid - 1
    mov  eax,mid
    dec  eax
    mov  last,eax
    jmp  L4
; else return mid
L3: mov  eax,mid                ; value found
    jmp  L9                     ; return (mid)
L4: jmp  L1                     ; continue the loop
L5: mov  eax,-1                 ; search failed
L9: ret
BinarySearch ENDP
```

- `mid`를 `shl esi,2`로 4배 해서 바이트 오프셋을 만들었다. `mov edx,[ebx+esi*4]`처럼 배율을 쓰면 `SHL` 없이도 된다.
- `L2`의 `cmp edx,edi`에 "optional"이라는 주석이 붙은 이유는, 바로 앞의 `CMP`와 `JGE` 사이에서 플래그가 바뀌지 않았으므로 다시 비교하지 않아도 같은 플래그가 남아 있기 때문이다.
- 비교는 부호 있는 점프(`JG`, `JGE`, `JLE`)로 한다. 배열이 부호 있는 정수이기 때문이다.

정렬된 배열 [2, 5, 8, 12, 16, 23, 38, 56, 72, 91]에서 23과 7을 찾으며 `mid`가 어떻게 움직이는지 보자.

```asm
; BinarySearch로 23과 7 찾기
INCLUDE Irvine32.inc

BinarySearch PROTO, pArray:PTR DWORD, Count:DWORD, searchVal:DWORD

.data
values SDWORD 2, 5, 8, 12, 16, 23, 38, 56, 72, 91

.code
main PROC
    INVOKE BinarySearch, ADDR values, LENGTHOF values, 23  ; EAX = 5
    INVOKE BinarySearch, ADDR values, LENGTHOF values, 7   ; EAX = -1
    exit
main ENDP

BinarySearch PROC USES ebx edx esi edi,
    pArray:PTR DWORD, Count:DWORD, searchVal:DWORD
    LOCAL first:DWORD, last:DWORD, mid:DWORD
    mov  first,0
    mov  eax,Count
    dec  eax
    mov  last,eax
    mov  edi,searchVal
    mov  ebx,pArray
L1: mov  eax,first
    cmp  eax,last
    jg   L5
    mov  eax,last
    add  eax,first
    shr  eax,1
    mov  mid,eax                ; 23을 찾을 때: EAX = 4 → 7 → 5 차례로
    mov  esi,mid
    shl  esi,2
    mov  edx,[ebx+esi]          ; EDX = 16 → 56 → 23 차례로
    cmp  edx,edi
    jge  L2
    mov  eax,mid
    inc  eax
    mov  first,eax
    jmp  L4
L2: cmp  edx,edi
    jle  L3
    mov  eax,mid
    dec  eax
    mov  last,eax
    jmp  L4
L3: mov  eax,mid
    jmp  L9
L4: jmp  L1
L5: mov  eax,-1
L9: ret
BinarySearch ENDP
END main
```

| 단계 | first | last | mid | values[mid] | 판단 |
|---|---|---|---|---|---|
| 1 | 0 | 9 | 4 | 16 | 16 < 23 → first = 5 |
| 2 | 5 | 9 | 7 | 56 | 56 > 23 → last = 6 |
| 3 | 5 | 6 | 5 | 23 | 같다 → 5를 돌려준다 |

7을 찾을 때는 mid = 4(16), 1(5), 2(8)를 거친 뒤 first = 2, last = 1이 되어 `first > last`로 끝나고 −1을 돌려준다. 원소가 n개이면 비교는 최대 ⌊log₂n⌋ + 1번이다. 10개면 4번, 50개면 6번, 백만 개라도 20번이면 충분하다. 버블 정렬의 비교 횟수와 비교하면, 정렬에 드는 비용을 한 번 치르고 나면 검색은 거의 공짜에 가깝다.

> [!TIP]
> `(last + first) / 2`는 `first`와 `last`가 모두 아주 크면 더하는 순간 넘칠 수 있다(원소가 2³⁰개를 넘는 배열). 32비트 프로그램에서는 그만한 배열을 만들 수 없어 문제가 되지 않지만, 일반적으로는 `first + (last − first) / 2`로 계산하면 안전하다. 위 코드는 합을 `SHR`(부호 없는 나눗셈)로 나누므로, 합이 2³¹ 이상이 되어도 부호 없는 값으로는 올바르다.

### 테스트 프로그램 (Test Program)

교재의 테스트 프로그램은 다음 일을 한다(슬라이드 38번).

- 배열을 난수로 채운다 (Fills an array with random integers)
- 배열을 출력한다 (Displays the array)
- 버블 정렬로 배열을 정렬한다 (Sorts the array using a bubble sort)
- 배열을 다시 출력한다 (Redisplays the array)
- 사용자에게 정수를 입력받는다 (Asks the user to enter an integer)
- 그 정수를 배열에서 이진 검색한다 (Performs a binary search for the user's integer)
- 검색 결과를 출력한다 (Displays the results of the binary search)

슬라이드 39번은 비어 있으므로 교재 예제(`BinarySearchTest.asm`, `FillArray.asm`, `PrintArray.asm`, `BubbleSort.asm`, `BinarySearch.asm`의 다섯 모듈)를 한 파일로 합친 코드로 채운다. 결과를 똑같이 재현할 수 있도록 `call Randomize`와 `WaitMsg`를 빼고, 배열 크기를 50에서 20으로, 값의 범위를 정하는 `LOWVAL`·`HIGHVAL`을 −5000·+5000에서 −50·+50으로 줄였다. `FillArray`는 `STOSD`로, `PrintArray`는 `LODSD`로 배열을 다룬다는 점도 눈여겨보자.

```asm
; Bubble Sort and Binary Search (BinarySearchTest.asm 등을 한 파일로)
INCLUDE Irvine32.inc

BinarySearch PROTO, pArray:PTR DWORD, Count:DWORD, searchVal:DWORD
FillArray    PROTO, pArray:PTR DWORD, Count:DWORD, LowerRange:SDWORD, UpperRange:SDWORD
PrintArray   PROTO, pArray:PTR DWORD, Count:DWORD
BubbleSort   PROTO, pArray:PTR DWORD, Count:DWORD

LOWVAL = -50                    ; minimum value
HIGHVAL = +50                   ; maximum value
ARRAY_SIZE = 20                 ; size of the array

.data
array DWORD ARRAY_SIZE DUP(?)

.code
main PROC
    ; Fill an array with random signed integers
    INVOKE FillArray, ADDR array, ARRAY_SIZE, LOWVAL, HIGHVAL
    ; Display the array
    INVOKE PrintArray, ADDR array, ARRAY_SIZE
    ; Perform a bubble sort and redisplay the array
    INVOKE BubbleSort, ADDR array, ARRAY_SIZE
    INVOKE PrintArray, ADDR array, ARRAY_SIZE
    ; Demonstrate a binary search
    call AskForSearchVal        ; returned in EAX
    INVOKE BinarySearch,
        ADDR array, ARRAY_SIZE, eax
    call ShowResults
    exit
main ENDP

;--------------------------------------------------------
AskForSearchVal PROC
; Prompt the user for a signed integer.
; Returns: EAX에 사용자가 입력한 값
;--------------------------------------------------------
.data
prompt BYTE "Enter a signed decimal integer "
       BYTE "to find in the array: ",0
.code
    call Crlf
    mov  edx,OFFSET prompt
    call WriteString
    call ReadInt
    ret
AskForSearchVal ENDP

;--------------------------------------------------------
ShowResults PROC
; Display the resulting value from the binary search.
; Receives: EAX에 찾은 위치 (못 찾았으면 -1)
;--------------------------------------------------------
.data
msg1 BYTE "The value was not found.",0
msg2 BYTE "The value was found at position ",0
.code
.IF eax == -1
    mov  edx,OFFSET msg1
    call WriteString
.ELSE
    mov  edx,OFFSET msg2
    call WriteString
    call WriteDec
.ENDIF
    call Crlf
    ret
ShowResults ENDP

;------------------------------------------------------------
FillArray PROC USES eax edi ecx edx,
    pArray:PTR DWORD,           ; pointer to array
    Count:DWORD,                ; number of elements
    LowerRange:SDWORD,          ; lower range
    UpperRange:SDWORD           ; upper range
; Fills an array with a random sequence of 32-bit signed
; integers between LowerRange and (UpperRange - 1).
;------------------------------------------------------------
    mov  edi,pArray             ; EDI points to the array
    mov  ecx,Count              ; loop counter
    mov  edx,UpperRange
    sub  edx,LowerRange         ; EDX = absolute range (0..n)
    cld                         ; clear direction flag
L1: mov  eax,edx                ; get absolute range
    call RandomRange
    add  eax,LowerRange         ; bias the result
    stosd                       ; store EAX into [edi]
    loop L1
    ret
FillArray ENDP

;------------------------------------------------------------
PrintArray PROC USES eax ecx edx esi,
    pArray:PTR DWORD,           ; pointer to array
    Count:DWORD                 ; number of elements
; Writes an array of 32-bit signed decimal integers to
; standard output, separated by commas
;------------------------------------------------------------
.data
comma BYTE ", ",0
.code
    mov  esi,pArray
    mov  ecx,Count
    cld                         ; direction = forward
L1: lodsd                       ; load [ESI] into EAX
    call WriteInt               ; send to output
    mov  edx,OFFSET comma
    call WriteString            ; display comma
    loop L1
    call Crlf
    ret
PrintArray ENDP

;------------------------------------------------------------
BubbleSort PROC USES eax ecx esi,
    pArray:PTR DWORD,           ; pointer to array
    Count:DWORD                 ; array size
;------------------------------------------------------------
    mov  ecx,Count
    dec  ecx                    ; decrement count by 1
    jle  L4                     ; 원소가 0개나 1개면 할 일이 없다
L1: push ecx                    ; save outer loop count
    mov  esi,pArray             ; point to first value
L2: mov  eax,[esi]              ; get array value
    cmp  [esi+4],eax            ; compare a pair of values
    jge  L3                     ; if [esi] <= [esi+4], don't exchange
    xchg eax,[esi+4]            ; exchange the pair
    mov  [esi],eax
L3: add  esi,4                  ; move both pointers forward
    loop L2                     ; inner loop
    pop  ecx                    ; retrieve outer loop count
    loop L1                     ; else repeat outer loop
L4: ret
BubbleSort ENDP

;-------------------------------------------------------------
BinarySearch PROC USES ebx edx esi edi,
    pArray:PTR DWORD,           ; pointer to array
    Count:DWORD,                ; array size
    searchVal:DWORD             ; search value
    LOCAL first:DWORD, last:DWORD, mid:DWORD
;-------------------------------------------------------------
    mov  first,0                ; first = 0
    mov  eax,Count              ; last = (count - 1)
    dec  eax
    mov  last,eax
    mov  edi,searchVal          ; EDI = searchVal
    mov  ebx,pArray             ; EBX points to the array
L1: mov  eax,first              ; while first <= last
    cmp  eax,last
    jg   L5                     ; exit search
    mov  eax,last               ; mid = (last + first) / 2
    add  eax,first
    shr  eax,1
    mov  mid,eax                ; 23을 찾을 때: EAX = 9 → 14 → 11 → 12 → 13 차례로
    mov  esi,mid                ; EDX = values[mid]
    shl  esi,2
    mov  edx,[ebx+esi]
    cmp  edx,edi                ; if ( EDX < searchVal )
    jge  L2
    mov  eax,mid                ;     first = mid + 1
    inc  eax
    mov  first,eax
    jmp  L4
L2: cmp  edx,edi                ; else if ( EDX > searchVal )
    jle  L3
    mov  eax,mid                ;     last = mid - 1
    dec  eax
    mov  last,eax
    jmp  L4
L3: mov  eax,mid                ; else return mid
    jmp  L9
L4: jmp  L1                     ; continue the loop
L5: mov  eax,-1                 ; search failed
L9: ret
BinarySearch ENDP
END main
```

23을 입력했을 때의 실행 결과:

```text
+44, -48, +17, +7, -43, -10, +8, -2, +23, +44, -34, +27, +38, -34, +31, -13, -29, +44, -48, -43,
-48, -48, -43, -43, -34, -34, -29, -13, -10, -2, +7, +8, +17, +23, +27, +31, +38, +44, +44, +44,

Enter a signed decimal integer to find in the array: 23
The value was found at position 13
```

- 첫 줄은 `FillArray`가 만든 배열, 둘째 줄은 정렬한 배열이다. `RandomRange`는 0~(범위 − 1)의 값을 돌려주므로, `HIGHVAL − LOWVAL` = 100을 넘겨 0~99를 받고 −50을 더해 −50~+49를 만든다. `Randomize`를 부르지 않았으므로 Windows의 Irvine32 라이브러리에서도 같은 배열이 나온다.
- 위치 13은 0부터 센 첨자다. 정렬된 배열에서 23은 14번째 원소다. 23을 찾는 동안 mid는 9, 14, 11, 12, 13 순서로 움직였다.
- 44처럼 같은 값이 여러 개 있으면, 이진 검색은 그중 **어느 하나**의 위치를 돌려준다. 가장 앞의 것을 원한다면 찾은 뒤에 앞쪽으로 같은 값이 있는지 더 살펴야 한다.
- `ShowResults`의 `.IF eax == -1`은 MASM의 고급 조건문으로, 어셈블러가 `cmp eax,-1`과 조건부 점프로 바꿔 준다.
- `PrintArray`는 마지막 원소 뒤에도 쉼표를 출력한다. 교재 코드를 그대로 두었다.

---

## 9.6 자바 바이트코드: 문자열 처리 (Java Bytecodes: String Processing, 보충)

교재 9.6절(선택 주제)의 내용이다. 8장에서 본 것처럼 자바 가상 머신(JVM)은 피연산자 스택으로 계산한다. 여기서는 문자열과 배열을 다루는 메서드가 어떤 바이트코드가 되는지 본다. x86의 문자열 명령어처럼 "문자열 전체를 한 번에 처리하는 명령어"는 바이트코드에 없고, 문자열은 `String` 객체의 메서드(`length`, `charAt`)를 호출해서 다룬다.

```java
public class StringDemo {
    static int countChar(String s, char c) {
        int count = 0;
        for (int i = 0; i < s.length(); i++)
            if (s.charAt(i) == c)
                count++;
        return count;
    }

    static int sum(int[] a) {
        int total = 0;
        for (int i = 0; i < a.length; i++)
            total += a[i];
        return total;
    }

    static String greet(String name) {
        return "Hello, " + name + "!";
    }
}
```

`javac`(JDK 21)로 컴파일하고 `javap -c`로 역어셈블한 결과:

```text
  static int countChar(java.lang.String, char);
    Code:
       0: iconst_0
       1: istore_2
       2: iconst_0
       3: istore_3
       4: iload_3
       5: aload_0
       6: invokevirtual #7                  // Method java/lang/String.length:()I
       9: if_icmpge     30
      12: aload_0
      13: iload_3
      14: invokevirtual #13                 // Method java/lang/String.charAt:(I)C
      17: iload_1
      18: if_icmpne     24
      21: iinc          2, 1
      24: iinc          3, 1
      27: goto          4
      30: iload_2
      31: ireturn

  static int sum(int[]);
    Code:
       0: iconst_0
       1: istore_1
       2: iconst_0
       3: istore_2
       4: iload_2
       5: aload_0
       6: arraylength
       7: if_icmpge     22
      10: iload_1
      11: aload_0
      12: iload_2
      13: iaload
      14: iadd
      15: istore_1
      16: iinc          2, 1
      19: goto          4
      22: iload_1
      23: ireturn

  static java.lang.String greet(java.lang.String);
    Code:
       0: aload_0
       1: invokedynamic #17,  0             // InvokeDynamic #0:makeConcatWithConstants:(Ljava/lang/String;)Ljava/lang/String;
       6: areturn
```

| 바이트코드 | 하는 일 | 비슷한 x86 코드 |
|---|---|---|
| `aload_0` | 지역 변수 0번(참조, 여기서는 문자열이나 배열)을 스택에 넣는다 | `mov esi,[ebp+8]` (포인터 읽기) |
| `invokevirtual String.length` | 문자열의 길이를 구한다 | `INVOKE Str_length, …` |
| `invokevirtual String.charAt` | i번째 문자를 구한다 (자바의 `char`는 16비트) | `movzx eax,WORD PTR [esi+ecx*2]` |
| `arraylength` | 배열의 길이를 스택에 넣는다 | (어셈블리 배열에는 길이 정보가 없다) |
| `iaload` | 배열 참조와 첨자를 꺼내 int 원소를 넣는다 | `mov eax,[esi+ecx*4]` |
| `if_icmpne`, `if_icmpge` | 두 int를 꺼내 비교해 점프 | `cmp` + `jne`, `jge` |
| `invokedynamic … makeConcatWithConstants` | 문자열 연결 | `Str_copy` 여러 번 + 버퍼 |

- **`countChar`**: 매개변수 `s`는 지역 변수 0번, `c`는 1번, `count`는 2번, `i`는 3번이다. 반복할 때마다 `invokevirtual`로 `length()`를 다시 부르고, `charAt(i)`의 결과를 `c`와 비교해 다르면(`if_icmpne`) `count++`를 건너뛴다.
- **`sum`**: 배열은 길이를 함께 가지고 있어서 `arraylength` 한 명령어로 길이를 얻는다. `iaload`는 첨자가 범위를 벗어나면 `ArrayIndexOutOfBoundsException`을 일으킨다. 어셈블리의 `[esi+ecx*4]`는 범위를 검사하지 않으므로, 9.4절의 `RowSum`처럼 표 밖의 메모리를 그대로 읽게 된다. 이것이 두 세계의 큰 차이다.
- **`greet`**: JDK 9부터 `javac`는 문자열 연결을 `StringBuilder.append` 호출의 연속 대신 `invokedynamic` 한 명령어로 만든다(JEP 280). 실제 연결 방법은 실행할 때 `StringConcatFactory`가 정한다. 그래서 바이트코드에는 `"Hello, "`와 `"!"`가 상수 풀의 레시피로만 남아 있다.

`#7`, `#13` 같은 번호는 상수 풀(constant pool)의 항목 번호로 컴파일러 버전에 따라 달라질 수 있다. 이 클래스로 `countChar("Mississippi", 's')`, `sum(new int[]{10, 20, 30})`, `greet("asm")`을 실행하면 4, 60, `Hello, asm!`이 나온다.

---

## 부록 A. 핵심 정리 표

### 문자열 기본 명령어

| 명령어 | 동작 (DF = 0일 때, n = 1·2·4) | 플래그 | 함께 쓰는 접두사 |
|---|---|---|---|
| `MOVSB`/`MOVSW`/`MOVSD` | `[EDI] ← [ESI]`, ESI += n, EDI += n | 바꾸지 않는다 | `REP` |
| `CMPSB`/`CMPSW`/`CMPSD` | `[ESI] − [EDI]`를 계산해 플래그만 바꾼다, ESI += n, EDI += n | `CMP`처럼 | `REPE`, `REPNE` |
| `SCASB`/`SCASW`/`SCASD` | `누산기 − [EDI]`를 계산해 플래그만 바꾼다, EDI += n | `CMP`처럼 | `REPE`, `REPNE` |
| `STOSB`/`STOSW`/`STOSD` | `[EDI] ← 누산기`, EDI += n | 바꾸지 않는다 | `REP` |
| `LODSB`/`LODSW`/`LODSD` | `누산기 ← [ESI]`, ESI += n | 바꾸지 않는다 | (거의 쓰지 않는다) |

DF = 1이면 ESI·EDI가 n만큼 **감소**한다. 누산기는 크기에 따라 AL, AX, EAX다.

### 반복 접두사와 끝난 뒤의 상태

| 접두사 | 반복 조건 | 끝난 뒤 확인할 것 |
|---|---|---|
| `REP` | ECX ≠ 0 | ECX = 0 |
| `REPE`/`REPZ` | ECX ≠ 0 그리고 ZF = 1 | ZF = 1이면 끝까지 같았다. ZF = 0이면 다른 원소가 ESI − n, EDI − n에 있다 |
| `REPNE`/`REPNZ` | ECX ≠ 0 그리고 ZF = 0 | ZF = 1이면 찾았다(EDI − n). ZF = 0이면 없다 |

- 반복하기 전에 ECX를 먼저 검사하므로 ECX = 0이면 한 번도 실행하지 않는다.
- ECX는 반복할 **횟수**(원소 수)다. 바이트 수가 아니다.
- 방향을 바꿨다면(`STD`) 끝난 뒤 반드시 `CLD`로 되돌린다.

### Irvine32 문자열 프로시저

| 프로시저 | 호출 | 결과 | 바꾸는 레지스터 |
|---|---|---|---|
| `Str_compare` | `INVOKE Str_compare, ADDR s1, ADDR s2` | CF·ZF (`CMP s1,s2`처럼) | 없음 |
| `Str_length` | `INVOKE Str_length, ADDR s` | EAX = 길이 | EAX |
| `Str_copy` | `INVOKE Str_copy, ADDR src, ADDR dst` | dst ← src (널 포함) | 없음 |
| `Str_trim` | `INVOKE Str_trim, ADDR s, '#'` | 끝의 `'#'`를 모두 지운다 | 없음 |
| `Str_ucase` | `INVOKE Str_ucase, ADDR s` | 소문자를 대문자로 | 없음 |

### 2차원 배열의 주소 지정 (행 우선, 원소 크기 S, 행의 바이트 수 RowSize)

| 방식 | 형식 | 레지스터에 넣는 것 |
|---|---|---|
| 베이스-인덱스 | `[ebx + esi]` | EBX = 표의 주소 + r × RowSize, ESI = c × S |
| 베이스-인덱스 (배율) | `[ebx + esi*TYPE table]` | EBX = 표의 주소 + r × RowSize, ESI = c |
| 베이스-인덱스-변위 | `table[ebx + esi*TYPE table]` | EBX = r × RowSize, ESI = c |

배율은 1, 2, 4, 8만 쓸 수 있고, 배율을 곱할 수 있는 인덱스 레지스터는 하나뿐이며, ESP는 인덱스가 될 수 없다.

### 알고리즘

| 알고리즘 | 조건 | 비교 횟수 (n개) | 특징 |
|---|---|---|---|
| 버블 정렬 | 없음 | n(n − 1)/2 | 이웃한 쌍을 교환한다. 한 번 훑을 때마다 가장 큰 값이 끝으로 간다 |
| 이진 검색 | 배열이 정렬되어 있어야 한다 | 최대 ⌊log₂n⌋ + 1 | 범위를 절반씩 줄인다. 같은 값이 여럿이면 그중 하나를 찾는다 |

---

## 부록 B. C 컴파일러가 만든 문자열·배열 코드

C 컴파일러도 이 장의 명령어와 주소 지정 방식을 그대로 쓴다. 다음 C 코드를 GCC 13으로 32비트(`-m32`) 어셈블리로 컴파일해 보았다(인텔 문법, `-fno-pic -fno-stack-protector -fcf-protection=none -fno-asynchronous-unwind-tables`).

```c
struct Rec { int id; char name[56]; };

void copyRec(struct Rec *dst, const struct Rec *src)
{
    *dst = *src;
}

void clear100(int *a)
{
    for (int i = 0; i < 100; i++)
        a[i] = 0;
}

int get(int table[][5], int r, int c)
{
    return table[r][c];
}

unsigned my_strlen(const char *s)
{
    unsigned n = 0;
    while (s[n])
        n++;
    return n;
}
```

### B.1 크기를 줄이는 최적화 (`-Os`)

```nasm
copyRec:
    push    ebp
    mov     ecx, 15
    mov     ebp, esp
    push    edi
    mov     edi, DWORD PTR [ebp+8]
    push    esi
    mov     esi, DWORD PTR [ebp+12]
    rep movsd
    pop     esi
    pop     edi
    pop     ebp
    ret
clear100:
    push    ebp
    mov     ecx, 100
    xor     eax, eax
    mov     ebp, esp
    push    edi
    mov     edi, DWORD PTR [ebp+8]
    rep stosd
    pop     edi
    pop     ebp
    ret
get:
    push    ebp
    mov     ebp, esp
    mov     edx, DWORD PTR [ebp+16]
    imul    eax, DWORD PTR [ebp+12], 20
    add     eax, DWORD PTR [ebp+8]
    pop     ebp
    mov     eax, DWORD PTR [eax+edx*4]
    ret
my_strlen:
    jmp     strlen
```

- **구조체 복사**: 60바이트짜리 구조체 대입 `*dst = *src`가 `mov ecx,15` / `rep movsd`가 되었다. 15 = 60 ÷ 4, 즉 ECX에는 **더블워드의 개수**가 들어간다. ESI·EDI는 호출한 쪽의 값을 지켜야 하는 레지스터이므로 `push`/`pop`으로 저장했다.
- **배열 초기화**: 100개의 `int`를 0으로 채우는 루프가 EAX = 0, ECX = 100인 `rep stosd` 한 줄이 되었다.
- **2차원 배열**: `table[r][c]`는 `imul eax,…,20`으로 r × 20(한 행의 바이트 수 = 5 × 4)을 구해 표의 주소에 더한 다음, `[eax+edx*4]`로 열(c × 4)을 더해 읽는다. 9.4절의 베이스-인덱스 피연산자에 배율 4를 쓴 것과 같다.
- **문자열 길이**: 컴파일러가 `while (s[n]) n++;`가 `strlen`과 같은 일을 한다는 것을 알아보고 라이브러리 함수로 바꿔 버렸다(`jmp strlen`).

### B.2 속도를 높이는 최적화 (`-O2`)

`-O2`에서는 `copyRec`이 `REP MOVSD` 대신 `mov` 30개(읽기 15번, 쓰기 15번)로 펼쳐졌다. 나머지 세 함수는 다음과 같다.

```nasm
clear100:
    push    edi
    mov     eax, DWORD PTR [esp+8]
    lea     edi, [eax+4]
    mov     DWORD PTR [eax], 0
    mov     DWORD PTR [eax+396], 0
    and     edi, -4
    sub     eax, edi
    lea     ecx, [eax+400]
    xor     eax, eax
    shr     ecx, 2
    rep stosd
    pop     edi
    ret
get:
    mov     eax, DWORD PTR [esp+8]
    mov     edx, DWORD PTR [esp+4]
    lea     eax, [eax+eax*4]
    lea     eax, [edx+eax*4]
    mov     edx, DWORD PTR [esp+12]
    mov     eax, DWORD PTR [eax+edx*4]
    ret
my_strlen:
    sub     esp, 12
    mov     eax, DWORD PTR [esp+16]
    cmp     BYTE PTR [eax], 0
    je      .L8
    sub     esp, 12
    add     eax, 1
    push    eax
    call    strlen
    add     esp, 16
    add     eax, 1
    add     esp, 12
    ret
.L8:
    xor     eax, eax
    add     esp, 12
    ret
```

- `clear100`은 첫 원소와 마지막 원소를 먼저 `mov`로 지운 다음, EDI를 4의 배수로 맞춘(`and edi,-4`) 구간만 `rep stosd`로 채운다. 배열의 시작 주소가 4의 배수가 아닐 수도 있다고 보고 정렬된 주소에서 `REP STOSD`를 실행하려는 것이다. 9.2절에서 측정한 것처럼 `REP STOS`는 큰 블록을 채우는 데 빠르기 때문에 `-O2`에서도 그대로 쓰인다.
- `get`은 `IMUL` 대신 `LEA` 두 개로 r × 20을 계산했다. `lea eax,[eax+eax*4]`가 r × 5, `lea eax,[edx+eax*4]`가 표의 주소 + (r × 5) × 4다. `LEA`로 하는 곱셈은 7장에서 본 요령이다.
- `my_strlen`은 첫 문자가 0인지만 직접 확인하고, 나머지는 `strlen(s + 1) + 1`로 계산한다.

ELF 형식이라 함수 이름 앞에 밑줄이 없고, 리눅스의 32비트 호출 규약에 따라 스택을 16바이트 단위로 맞추는 코드(`sub esp,12`)가 들어 있다는 점이 Windows용 코드와 다르다.

---

## 부록 C. 자주 하는 실수와 오류 메시지

### 어셈블할 때 걸리는 오류

이 문서의 예제를 JWasm으로 어셈블해서 확인한 오류다. MASM의 메시지 문구와 번호는 조금 다를 수 있다.

| 잘못된 코드 | 원인 | 고치는 방법 |
|---|---|---|
| `Str_trim PROC` … `Stmr_trim ENDP` | `ENDP`의 이름이 `PROC`와 다르다 (`Unmatched block nesting`) | 같은 이름으로 쓴다 |
| `mov al,[ebx + esi*3]` | 배율은 1, 2, 4, 8만 된다 (`Scale factor must be 1, 2, 4 or 8`) | 3을 곱하려면 `lea esi,[esi+esi*2]`로 먼저 계산한다 |
| `mov eax,[esi*2 + edi*2]` | 배율을 곱할 수 있는 인덱스 레지스터는 하나뿐이다 (`Multiple index registers not allowed`) | 한쪽은 배율 없이 쓰거나 미리 계산한다 |
| `mov al,tbl[esp*2]` | ESP는 인덱스 레지스터가 될 수 없다 (`Cannot be used as index register`) | 다른 레지스터를 쓴다 |
| `rep cmpsb`, `repe movsb` | JWasm은 `CMPS`·`SCAS`에는 `REPE`/`REPNE`만, `MOVS`·`STOS`·`LODS`에는 `REP`만 받는다 (`Instruction prefix not allowed`) | 명령어에 맞는 접두사를 쓴다 |
| `OPTION CASEMAP:NONE`에서 `Rowsize`를 정의하고 `RowSize`로 씀 | 대소문자가 다른 이름은 다른 기호다 (`Symbol not defined`) | 정의와 사용의 대소문자를 맞춘다 |
| 전역 변수 `source`가 있는 파일에 `Str_copyN PROC, source:PTR BYTE, …` | 매개변수 이름이 전역 변수 이름과 겹친다 (`Symbol redefinition`). 라이브러리의 `Str_copy`처럼 따로 어셈블하는 모듈에서는 문제가 없지만, 같은 파일에 넣으면 충돌한다 | 매개변수 이름을 `pSource`처럼 바꾼다 ([부록 F 연습 1](#연습-1-길이를-제한하는-문자열-복사)) |

### 어셈블은 되지만 틀리게 동작하는 실수

| 실수 | 증상 | 고치는 방법 |
|---|---|---|
| `CLD`를 하지 않음 | 다른 코드가 DF = 1로 남겨 두었다면 거꾸로 복사·비교한다 | 문자열 명령어 앞에서 `CLD`를 실행한다 |
| `STD` 뒤에 `CLD`로 되돌리지 않음 | 그 뒤의 라이브러리 함수와 문자열 명령어가 모두 거꾸로 동작한다 | 끝나면 바로 `CLD` |
| ECX에 바이트 수를 넣고 `MOVSD`/`STOSD` | 4배를 처리해 배열 뒤의 메모리를 덮어쓴다 | ECX = 원소 수(`LENGTHOF`) |
| ECX 대신 CX만 설정 (`mov cx,LENGTHOF s`) | ECX의 상위 16비트에 남은 값까지 횟수가 된다 | `mov ecx,…` |
| `REPNE SCASB`로 찾은 뒤 EDI를 그대로 씀 | EDI는 찾은 원소의 **다음**을 가리킨다 | `dec edi` (워드면 2, 더블워드면 4를 뺀다) |
| `REPE CMPSB`가 끝난 뒤 ZF를 보지 않음 | 끝까지 같아서 멈춘 것인지, 다른 곳에서 멈춘 것인지 모른다 | ZF로 같은지 판단한 다음, `JB`/`JA`(부호 없는 비교)나 `JL`/`JG`(부호 있는 비교)로 대소를 본다 |
| `MOVS dst,src`가 주소를 넣어 준다고 생각함 | 피연산자는 크기만 알려 준다. 실제로는 ESI·EDI가 쓰인다 | ESI·EDI에 주소를 직접 넣는다 |
| `Str_copy`의 대상 버퍼가 작음 | 버퍼 뒤의 다른 변수를 덮어쓴다 | 대상 크기를 확인하거나 길이를 제한하는 프로시저를 쓴다 |
| `Str_compare` 뒤에 플래그를 바꾸는 명령어를 넣고 점프 | 비교 결과가 사라진다 | `JE`/`JB`/`JA`를 바로 뒤에 둔다(`MOV`는 괜찮다) |
| 2차원 배열의 열 번호에 배율을 곱하지 않음 (WORD·DWORD 배열) | 원소 경계가 어긋난 값을 읽는다 | `[ebx + esi*TYPE table]` |
| 행 오프셋에 배율을 또 곱함 | 엉뚱한 행을 읽는다 | 행 오프셋은 이미 바이트 단위(`RowSize`)다 |
| `BubbleSort`에 원소 1개 이하를 넘김 | `LOOP`가 ECX = 0에서 시작해 약 43억 번 반복한다 | `dec ecx` 다음에 `jle` 로 빠져나간다 |
| 정렬하지 않은 배열에 이진 검색 | 있는 값도 못 찾는다 | 먼저 정렬한다 |

---

## 부록 D. 핵심 용어 정리

| 용어 | 설명 |
|---|---|
| 문자열 기본 명령어 (string primitive instruction) | ESI·EDI로 메모리를 다루고 포인터를 자동으로 옮기는 `MOVS`, `CMPS`, `SCAS`, `STOS`, `LODS` |
| 반복 접두사 (repeat prefix) | 문자열 명령어를 ECX를 카운터로 반복하게 하는 `REP`, `REPE`/`REPZ`, `REPNE`/`REPNZ` |
| 방향 플래그 (Direction flag, DF) | 문자열 명령어가 ESI·EDI를 증가(DF = 0)시킬지 감소(DF = 1)시킬지 정하는 플래그. `CLD`, `STD`로 바꾼다 |
| 누산기 (accumulator) | 크기에 따라 AL, AX, EAX. `SCAS`, `STOS`, `LODS`가 쓴다 |
| 널로 끝나는 문자열 (null-terminated string) | 끝을 0 바이트로 표시하는 문자열. C 문자열과 같다 |
| 빠른 문자열 연산 (fast-string operation) | 프로세서가 `REP MOVS`·`REP STOS`를 여러 원소씩 묶어 처리하는 기능 |
| 행 우선 순서 (row-major order) | 2차원 배열을 행 단위로 이어 저장하는 방법. C, C++ |
| 열 우선 순서 (column-major order) | 2차원 배열을 열 단위로 이어 저장하는 방법. 포트란, MATLAB |
| 베이스-인덱스 피연산자 (base-index operand) | 두 레지스터의 합으로 주소를 만드는 피연산자 `[base + index]` |
| 베이스-인덱스-변위 피연산자 (base-index-displacement operand) | 변위(변수 이름이나 상수)까지 더하는 피연산자 `table[base + index]` |
| 배율 (scale factor) | 인덱스 레지스터에 곱하는 1, 2, 4, 8. 원소 번호를 바이트 오프셋으로 바꾼다 |
| 버블 정렬 (bubble sort) | 이웃한 원소를 비교해 교환하기를 반복하는 정렬. 비교 n(n − 1)/2번 |
| 이진 검색 (binary search) | 정렬된 배열에서 범위를 절반씩 줄여 찾는 검색. 비교 약 log₂n번 |
| 상수 풀 (constant pool) | 자바 클래스 파일에서 문자열 상수, 메서드 이름 등을 모아 둔 표 |

---

## 부록 E. 복습 문제

교재 9.9절(Review Questions and Exercises)과 같은 유형의 문제를 직접 만들었다. **단답형**은 코드의 결과를 예측하는 문제, **알고리즘 작성**은 짧은 코드를 직접 써 보는 문제다. 각 문제의 **정답 보기**를 누르면 답과 해설이 펼쳐진다. 답에 나오는 값은 모두 실행해서 확인했다.

### 단답형 (Short Answer)

**Q1.** 다섯 가지 문자열 기본 명령어가 각각 쓰는 레지스터(ESI, EDI, 누산기)를 정리하라. 플래그를 바꾸는 것은 어느 것인가?

<details>
<summary>정답 보기</summary>

| 명령어 | ESI | EDI | 누산기 | 플래그 |
|---|---|---|---|---|
| `MOVS` | 원본 | 대상 | — | 바꾸지 않는다 |
| `CMPS` | 첫째 피연산자 | 둘째 피연산자 | — | 바꾼다 |
| `SCAS` | — | 검사할 곳 | 찾는 값 | 바꾼다 |
| `STOS` | — | 저장할 곳 | 저장할 값 | 바꾸지 않는다 |
| `LODS` | 읽을 곳 | — | 읽은 값 | 바꾸지 않는다 |

플래그를 바꾸는 것은 비교 명령어인 `CMPS`와 `SCAS`뿐이다. 그래서 `REPE`·`REPNE`(ZF를 보는 접두사)는 이 둘과만 쓴다.

</details>

**Q2.** 다음 코드를 실행한 뒤 ESI와 EDI는 처음보다 얼마나 늘어나는가? ECX는?

```asm
.data
src DWORD 1,2,3,4,5
dst DWORD 5 DUP(?)
.code
cld
mov  esi,OFFSET src
mov  edi,OFFSET dst
mov  ecx,5
rep  movsd
```

<details>
<summary>정답 보기</summary>

더블워드 5개를 복사했으므로 ESI와 EDI는 각각 20(5 × 4)씩 늘어나고, ECX는 0이 된다.

```asm
.data
src DWORD 1,2,3,4,5
dst DWORD 5 DUP(?)
.code
cld
mov  esi,OFFSET src
mov  edi,OFFSET dst
mov  ebx,esi                    ; 처음 ESI
mov  edx,edi                    ; 처음 EDI
mov  ecx,5
rep  movsd                      ; ECX = 0, ESI = EBX+20, EDI = EDX+20, dst = [1, 2, 3, 4, 5]
```

</details>

**Q3.** DF = 1인 상태에서 `LODSW`를 한 번 실행하면 ESI는 어떻게 바뀌는가? AX에는 무엇이 들어가는가?

<details>
<summary>정답 보기</summary>

ESI가 가리키는 워드를 AX에 읽은 **뒤** ESI가 2 감소한다.

```asm
.data
words WORD 1111h,2222h,3333h
.code
std
mov  esi,OFFSET words + 4       ; 마지막 원소
mov  ebx,esi
lodsw                           ; AX = 3333h, ESI = EBX-2
lodsw                           ; AX = 2222h, ESI = EBX-4
cld
```

</details>

**Q4.** 문자열 `"ABC",0`에서 `REPNE SCASB`로 `'Z'`를 찾았다(ECX = `LENGTHOF`). 끝난 뒤 ZF, ECX, EDI는?

<details>
<summary>정답 보기</summary>

찾지 못했으므로 ZF = 0이고, 네 바이트(널 포함)를 모두 검사해 ECX = 0, EDI는 처음보다 4 뒤를 가리킨다.

```asm
.data
str1 BYTE "ABC",0
.code
mov  edi,OFFSET str1
mov  ebx,edi
mov  al,'Z'
mov  ecx,LENGTHOF str1
cld
repne scasb                     ; ZF = 0, ECX = 0, EDI = EBX+4
```

ECX가 0이 되어 멈춘 것인지 찾아서 멈춘 것인지는 ZF로만 구별할 수 있다. 마지막 원소에서 찾은 경우에도 ECX = 0이 되기 때문이다.

</details>

**Q5.** WORD 배열 10개를 모두 1234h로 채우는 코드를 문자열 명령어로 쓰라.

<details>
<summary>정답 보기</summary>

```asm
.data
wArray WORD 10 DUP(0)
.code
mov  ax,1234h                   ; 저장할 값 (STOSW는 AX를 쓴다)
mov  edi,OFFSET wArray
mov  ecx,LENGTHOF wArray        ; 원소 10개
cld
rep  stosw                      ; wArray = [1234h, 1234h, 1234h]
mov  bx,wArray + 18             ; 마지막 원소: BX = 1234h
```

</details>

**Q6.** 다음 코드를 실행한 뒤 ECX, ZF, CF는? ESI − 4가 가리키는 값은?

```asm
.data
a1 DWORD 1,2,3,4
a2 DWORD 1,2,9,4
.code
mov  esi,OFFSET a1
mov  edi,OFFSET a2
mov  ecx,LENGTHOF a1
cld
repe cmpsd
```

<details>
<summary>정답 보기</summary>

세 번째 쌍(3과 9)에서 멈춘다. 비교를 세 번 했으므로 ECX = 1, 다르므로 ZF = 0, 3 < 9이므로 CF = 1이다. ESI − 4는 다른 원소 3을 가리킨다.

```asm
.data
a1 DWORD 1,2,3,4
a2 DWORD 1,2,9,4
.code
mov  esi,OFFSET a1
mov  edi,OFFSET a2
mov  ecx,LENGTHOF a1
cld
repe cmpsd                      ; ECX = 1, ZF = 0, CF = 1
mov  eax,[esi-4]                ; EAX = 3
```

</details>

**Q7.** `INVOKE Str_compare, ADDR s1, ADDR s2`에서 s1 = `"Zebra"`, s2 = `"apple"`이다. `JB`, `JE`, `JA` 중 어느 것이 점프하는가?

<details>
<summary>정답 보기</summary>

`JB`가 점프한다. `'Z'`(5Ah)가 `'a'`(61h)보다 작으므로 s1 < s2이고 CF = 1이다. 사전순으로는 apple이 먼저일 것 같지만, ASCII에서는 대문자가 모두 소문자보다 앞에 온다.

```asm
.data
s1 BYTE "Zebra",0
s2 BYTE "apple",0
.code
INVOKE Str_compare, ADDR s1, ADDR s2    ; CF = 1, ZF = 0
jb   below                              ; 점프한다
mov  eax,0
below:
```

</details>

**Q8.** `"##A##"`에 `Str_trim`을 `'#'`로 실행하면 결과는? `"####"`이면?

<details>
<summary>정답 보기</summary>

`"##A"`와 `""`(빈 문자열)이다. 끝에 붙은 `#`만 지우므로 앞의 `##`는 남는다.

```asm
.data
t1 BYTE "##A##",0
t2 BYTE "####",0
.code
INVOKE Str_trim, ADDR t1, '#'   ; t1 = "##A"
INVOKE Str_trim, ADDR t2, '#'   ; t2 = ""
```

</details>

**Q9.** 3행 × 4열의 BYTE 표(행 우선)에서 원소 (2, 3)의 오프셋은? 같은 모양의 DWORD 표라면?

<details>
<summary>정답 보기</summary>

BYTE 표는 2 × 4 + 3 = 11, DWORD 표는 그 4배인 44다.

```asm
.data
tblB BYTE  0,1,2,3, 4,5,6,7, 8,9,10,11
tblD DWORD 0,1,2,3, 4,5,6,7, 8,9,10,11
.code
mov  al,tblB[11]                ; 원소 (2, 3): AL = 11
mov  ebx,2 * 16                 ; 행 2의 오프셋 = 2 × (4 × 4)
mov  esi,3                      ; 열 3
mov  eax,tblD[ebx + esi*TYPE tblD]  ; EAX = 11
```

</details>

**Q10.** 열이 5개인 DWORD 표 `tableD`에서 `mov eax,tableD[ebx + esi*TYPE tableD]`로 원소 (2, 1)을 읽으려면 EBX와 ESI에 무엇을 넣어야 하는가?

<details>
<summary>정답 보기</summary>

EBX에는 행 2의 바이트 오프셋 2 × (5 × 4) = 40을, ESI에는 열 번호 1을 넣는다. 배율 4가 ESI에만 곱해진다는 점에 주의한다.

```asm
.data
tableD DWORD  10h,  20h,  30h,  40h,  50h
       DWORD  60h,  70h,  80h,  90h, 0A0h
       DWORD 0B0h, 0C0h, 0D0h, 0E0h, 0F0h
.code
mov  ebx,2 * (5 * TYPE tableD)  ; EBX = 40
mov  esi,1
mov  eax,tableD[ebx + esi*TYPE tableD]  ; EAX = 0C0h
```

</details>

**Q11.** 원소가 1,000개인 정렬된 배열을 이진 검색할 때 비교는 최대 몇 번인가? 버블 정렬로 이 배열을 정렬할 때의 비교 횟수는?

<details>
<summary>정답 보기</summary>

이진 검색은 ⌊log₂1000⌋ + 1 = 9 + 1 = **10번**이면 충분하다(2¹⁰ = 1024 > 1000). 버블 정렬은 1000 × 999 / 2 = **499,500번** 비교한다. 정렬은 한 번만 하고 검색을 여러 번 한다면, 정렬의 비용을 치를 가치가 있다.

</details>

**Q12.** 9.5절의 `BubbleSort`로 [5, 4, 3, 2, 1]을 정렬하면 교환은 모두 몇 번 일어나는가?

<details>
<summary>정답 보기</summary>

거꾸로 정렬된 배열은 모든 비교에서 교환이 일어나므로 5 × 4 / 2 = **10번**이다. 교환할 때마다 카운터를 늘리는 코드로 확인했다.

```asm
; Q12 확인: 교환 횟수 세기
INCLUDE Irvine32.inc

.data
arr   SDWORD 5, 4, 3, 2, 1
swaps DWORD 0

.code
main PROC
    mov  ecx,LENGTHOF arr - 1
L1: push ecx
    mov  esi,OFFSET arr
L2: mov  eax,[esi]
    cmp  [esi+4],eax
    jge  L3
    xchg eax,[esi+4]
    mov  [esi],eax
    inc  swaps                  ; 교환 횟수
L3: add  esi,4
    loop L2
    pop  ecx
    loop L1                     ; 끝나면 swaps = 10, arr = [1, 2, 3, 4, 5]
    exit
main ENDP
END main
```

</details>

**Q13.** 다음 코드의 문제는 무엇인가? 실행하면 `after`는 어떻게 되는가?

```asm
.data
arr   DWORD 10 DUP(7)
after DWORD 12345678h
.code
mov  eax,0
mov  edi,OFFSET arr
mov  ecx,SIZEOF arr
cld
rep  stosd
```

<details>
<summary>정답 보기</summary>

`SIZEOF arr`는 바이트 수(40)이므로 `REP STOSD`가 더블워드를 40개, 즉 160바이트를 쓴다. 배열 뒤의 `after`까지 0으로 덮어써진다. ECX에는 `LENGTHOF arr`(10)를 넣어야 한다.

```asm
.data
arr   DWORD 10 DUP(7)
after DWORD 12345678h
pad   DWORD 120 DUP(0)          ; (덮어쓸 자리를 확인용으로 마련해 둔다)
.code
mov  eax,0
mov  edi,OFFSET arr
mov  ecx,SIZEOF arr             ; ECX = 40 (잘못)
cld
rep  stosd                      ; after = 0
```

</details>

**Q14.** ESI와 EDI를 설정하지 않고 `movs dst,src`를 실행하면 무슨 일이 일어나는가?

<details>
<summary>정답 보기</summary>

`movs dst,src`는 `movsb`와 같은 기계어(`A4`)이고, 피연산자 `dst`·`src`는 바이트 크기라는 것을 알려 줄 뿐이다. 실제로는 그때 ESI와 EDI에 들어 있던 **아무 주소**에서 아무 주소로 한 바이트가 복사된다. 운이 좋으면 접근 위반으로 멈추고, 운이 나쁘면 다른 데이터를 조용히 망가뜨린다.

</details>

**Q15.** 3행 × 5열의 배열을 **열 우선**으로 저장했다. 원소 (r, c)의 오프셋(원소 크기 S)과, 원소 (1, 3)의 BYTE 오프셋은?

<details>
<summary>정답 보기</summary>

열 우선이면 한 열(원소 3개)이 이어져 저장되므로 오프셋은 (c × 3 + r) × S이고, (1, 3)은 3 × 3 + 1 = **10**이다. 같은 원소의 행 우선 오프셋은 1 × 5 + 3 = 8이다. 9.4절 첫 그림(교재 Figure 9-1)의 3 × 5 배열로 확인할 수 있다. 원소 (1, 3)은 `90`이고, 열 우선 순서에서 10번째 칸(0부터 셈)과 행 우선 순서에서 8번째 칸이 모두 `90`이다.

</details>

### 알고리즘 작성 (Algorithm Workbench)

**W1.** 문자열 `"ABCDE"`를 거꾸로 `target`에 복사하는 코드를 `STD`와 `LODSB`로 작성하라.

<details>
<summary>정답 보기</summary>

방향 플래그는 ESI와 EDI에 똑같이 적용되므로, 원본은 `LODSB`(DF = 1)로 뒤에서부터 읽고 대상은 `mov [edi],al` / `inc edi`로 앞에서부터 쓴다.

```asm
.data
source BYTE "ABCDE",0
target BYTE 6 DUP(0)
.code
mov  esi,OFFSET source + LENGTHOF source - 2    ; 마지막 문자 'E'
mov  edi,OFFSET target
mov  ecx,LENGTHOF source - 1                    ; 문자 5개
std                             ; ESI를 감소시키며 읽는다
L1: lodsb
    mov  [edi],al
    inc  edi
    loop L1
cld                             ; 반드시 되돌린다: target = "EDCBA"
```

</details>

**W2.** `REPNE SCASB`를 루프 안에서 반복해, 문자열에 특정 문자가 몇 번 나오는지 세는 코드를 작성하라. `"Mississippi"`에서 `'s'`를 세라.

<details>
<summary>정답 보기</summary>

찾을 때마다 카운터를 늘리고, ECX와 EDI가 이미 "찾은 다음 위치"를 가리키므로 그대로 다시 `REPNE SCASB`를 실행한다.

```asm
.data
text BYTE "Mississippi",0
.code
mov  edi,OFFSET text
mov  ecx,LENGTHOF text - 1      ; 널은 빼고 검사한다
mov  al,'s'
mov  edx,0                      ; 개수
cld
L1: repne scasb
    jnz  L2                     ; 더 없다
    inc  edx
    jecxz L2                    ; 마지막 문자에서 찾았으면 끝
    jmp  L1
L2: mov  ebx,edx                ; EBX = 4
```

찾은 문자가 마지막 문자라서 ECX가 0이 된 경우에도 ZF = 1이므로 먼저 개수를 센 다음 ECX를 검사해야 한다.

</details>

**W3.** 길이가 같은 두 문자열에서 처음으로 다른 위치(인덱스)를 EAX로 구하는 코드를 `REPE CMPSB`로 작성하라. 모두 같으면 EAX = −1이다.

<details>
<summary>정답 보기</summary>

```asm
.data
strA BYTE "assembly"
strB BYTE "assemble"
.code
mov  esi,OFFSET strA
mov  edi,OFFSET strB
mov  ecx,LENGTHOF strA
cld
repe cmpsb
mov  eax,-1
jz   done                       ; 끝까지 같았다
mov  eax,esi                    ; ESI는 다른 바이트의 다음을 가리킨다
sub  eax,OFFSET strA + 1        ; EAX = 7
done:
```

`"assembly"`와 `"assemble"`은 마지막 글자(인덱스 7)에서 처음 다르다. 멈춘 뒤 ESI − 1이 다른 바이트의 주소이므로 `ESI − (OFFSET strA + 1)`이 인덱스다.

</details>

**W4.** 4 × 4 DWORD 행렬의 주대각선(행 번호 = 열 번호인 원소) 합을 베이스-인덱스-변위 피연산자로 구하라.

<details>
<summary>정답 보기</summary>

행 i의 오프셋은 i × 16, 열 i는 i × 4이므로 한 번에 (16 + 4) = 20바이트씩 건너뛰어도 된다. 여기서는 개념이 드러나도록 행과 열을 따로 둔다.

```asm
.data
matrix DWORD  1,  2,  3,  4
       DWORD  5,  6,  7,  8
       DWORD  9, 10, 11, 12
       DWORD 13, 14, 15, 16
RowBytes = 4 * TYPE matrix
.code
mov  eax,0                      ; 합
mov  ebx,0                      ; 행의 오프셋
mov  esi,0                      ; 열 번호
mov  ecx,4
L1: add  eax,matrix[ebx + esi*TYPE matrix]
    add  ebx,RowBytes           ; 다음 행
    inc  esi                    ; 다음 열
    loop L1                     ; 끝나면 EAX = 34
```

1 + 6 + 11 + 16 = 34다.

</details>

**W5.** 문자열의 공백을 모두 밑줄(`_`)로 바꾸는 코드를 `LODSB`와 `STOSB`로 작성하라(같은 문자열을 제자리에서 바꾼다).

<details>
<summary>정답 보기</summary>

```asm
.data
phrase BYTE "x86 is fun to learn",0
.code
mov  esi,OFFSET phrase
mov  edi,esi                    ; 읽는 곳과 쓰는 곳이 같다
cld
L1: lodsb
    cmp  al,' '
    jne  L2
    mov  al,'_'
L2: stosb
    cmp  al,0
    jne  L1                     ; 끝나면 phrase = "x86_is_fun_to_learn"
```

</details>

**W6.** 부호 있는 DWORD 배열이 오름차순으로 정렬되어 있으면 EAX = 1, 아니면 0을 돌려주는 프로시저 `IsSorted`를 작성하라. 이진 검색 전에 검사하는 데 쓸 수 있다.

<details>
<summary>정답 보기</summary>

```asm
; W6: 정렬 여부 검사
INCLUDE Irvine32.inc

IsSorted PROTO, pArray:PTR SDWORD, Count:DWORD

.data
good SDWORD -5, 0, 0, 7, 12
bad  SDWORD 1, 3, 2

.code
main PROC
    INVOKE IsSorted, ADDR good, LENGTHOF good   ; EAX = 1
    INVOKE IsSorted, ADDR bad, LENGTHOF bad     ; EAX = 0
    exit
main ENDP

IsSorted PROC USES ecx esi, pArray:PTR SDWORD, Count:DWORD
    mov  eax,1                  ; 일단 정렬되었다고 본다
    mov  ecx,Count
    dec  ecx                    ; 비교할 쌍의 수
    jle  Done                   ; 원소가 1개 이하면 정렬된 것
    mov  esi,pArray
L1: mov  edx,[esi]
    cmp  edx,[esi+4]
    jg   NotSorted              ; 앞 원소가 더 크면 정렬되지 않았다
    add  esi,4
    loop L1
    jmp  Done
NotSorted:
    mov  eax,0
Done:
    ret
IsSorted ENDP
END main
```

`EDX`를 쓰지만 `USES`에 넣지 않았으므로 호출한 쪽의 EDX가 바뀐다. 라이브러리처럼 쓸 프로시저라면 EDX도 넣는 것이 좋다.

</details>

---

## 부록 F. 프로그래밍 연습 (풀이 포함)

교재 9.10절 Programming Exercises와 같은 유형의 문제를 이 장에서 배운 방법으로 풀어 본다. 먼저 직접 풀어 본 다음 **풀이 보기**를 펼쳐 비교해 보자. 모든 풀이는 그대로 붙여 넣어 실행할 수 있는 완전한 프로그램(Irvine32 사용)이고, 실행 결과를 확인했다.

| 연습 | 주제 | 주로 쓰는 것 |
|---|---|---|
| 1 | 길이를 제한하는 문자열 복사 | `REP MOVSB`, 널 직접 붙이기 |
| 2 | 문자열 이어 붙이기 | `REPNE SCASB`로 끝 찾기 |
| 3 | 문자열의 일부 지우기 | 겹치는 영역의 정방향 복사 |
| 4 | 문자열 찾기 | `REPE CMPSB`, ZF로 결과 알리기 |
| 5 | 구분 문자로 단어 나누기 | `LODSB`, `PUSHFD`/`POPFD` |
| 6 | 문자 빈도표 | `REP STOSD`, `[edi + eax*4]` |
| 7 | 에라토스테네스의 체 | `REP STOSB`, `LODSB` |
| 8 | 교환 여부로 일찍 끝나는 버블 정렬 | 교환 플래그 |
| 9 | 레지스터만 쓰는 이진 검색 | 지역 변수 대신 레지스터 |
| 10 | 원소 크기에 상관없는 행 합 | 배율 1, 2, 4 |
| 11 | 행렬 전치 | 베이스-인덱스-변위 |

### 연습 1. 길이를 제한하는 문자열 복사

9.3절의 `Str_copy`는 대상의 크기를 검사하지 않아서 뒤의 변수를 덮어쓸 수 있었다. 복사할 최대 문자 수 `maxChars`를 함께 받아 그보다 많이는 복사하지 않고, 결과를 항상 널로 끝내는 `Str_copyN`을 작성하라(대상 버퍼는 maxChars + 1바이트 이상이어야 한다). 9.3절의 예처럼 6바이트짜리 `target` 바로 뒤에 `next`가 있을 때 `next`가 망가지지 않는지 확인하라.

<details>
<summary>풀이 보기</summary>

```asm
; 연습 1: 길이를 제한하는 문자열 복사
INCLUDE Irvine32.inc

Str_copyN PROTO, pSource:PTR BYTE, pTarget:PTR BYTE, maxChars:DWORD

.data
source BYTE "HELLO WORLD",0
target BYTE 6 DUP(0)            ; 문자 5개 + 널
next   BYTE "*****",0           ; target 바로 뒤의 다른 변수
short1 BYTE "Hi",0

.code
main PROC
    INVOKE Str_copyN, ADDR source, ADDR target, SIZEOF target - 1  ; target = "HELLO", next = "*****"
    mov  edx,OFFSET target
    call ShowBracketed
    mov  edx,OFFSET next
    call ShowBracketed
    INVOKE Str_copyN, ADDR short1, ADDR target, SIZEOF target - 1  ; target = "Hi"
    mov  edx,OFFSET target
    call ShowBracketed
    INVOKE Str_copyN, ADDR source, ADDR target, 0                  ; target = ""
    mov  edx,OFFSET target
    call ShowBracketed
    exit
main ENDP

;-----------------------------------------------------------
Str_copyN PROC USES eax ecx esi edi,
    pSource:PTR BYTE,           ; 원본 문자열
    pTarget:PTR BYTE,           ; 대상 버퍼
    maxChars:DWORD              ; 복사할 최대 문자 수 (널 제외)
;
; 원본을 최대 maxChars 문자까지 대상으로 복사하고 널로 끝낸다.
; Requires: 대상 버퍼는 maxChars + 1바이트 이상
;-----------------------------------------------------------
    INVOKE Str_length,pSource   ; EAX = 원본의 길이
    mov  ecx,maxChars
    cmp  eax,ecx
    jae  L1                     ; 원본이 길면 maxChars개만
    mov  ecx,eax                ; 짧으면 원본 전체
L1: mov  esi,pSource
    mov  edi,pTarget
    cld
    rep  movsb                  ; ECX개 복사 (ECX가 0이면 한 번도 반복하지 않는다)
    mov  BYTE PTR [edi],0       ; 널은 항상 따로 붙인다
    ret
Str_copyN ENDP

ShowBracketed PROC              ; EDX가 가리키는 문자열을 [ ] 안에 출력한다
    mov  al,'['
    call WriteChar
    call WriteString
    mov  al,']'
    call WriteChar
    call Crlf
    ret
ShowBracketed ENDP
END main
```

실행 결과:

```text
[HELLO]
[*****]
[Hi]
[]
```

원본의 길이와 `maxChars` 중 작은 쪽만큼만 `REP MOVSB`로 복사하고, 널은 항상 따로 붙인다. 그래서 원본이 짧든 길든 같은 코드로 처리된다. 호출할 때 `maxChars`로 `SIZEOF target - 1`을 넘기면 버퍼 크기를 바꿔도 호출 코드를 고칠 필요가 없다.

C의 `strncpy`는 이름은 비슷하지만 동작이 다르다. 원본이 n 문자 이상이면 널을 붙이지 않고, 원본이 짧으면 나머지를 모두 널로 채운다. 그래서 이 풀이처럼 항상 널로 끝내는 BSD의 `strlcpy` 같은 함수가 따로 쓰인다.

</details>

### 연습 2. 문자열 이어 붙이기

대상 문자열의 끝에 원본 문자열을 덧붙이는 `Str_concat PROTO, target:PTR BYTE, source:PTR BYTE`를 작성하라. 대상의 끝(널)은 `REPNE SCASB`로 찾는다. 대상 버퍼에는 공간이 충분하다고 가정한다. 빈 문자열을 덧붙이는 경우도 시험하라.

<details>
<summary>풀이 보기</summary>

```asm
; 연습 2: 문자열 이어 붙이기
INCLUDE Irvine32.inc

Str_concat PROTO, target:PTR BYTE, source:PTR BYTE

.data
buffer BYTE "Hello",20 DUP(0)   ; 덧붙일 공간을 넉넉히 둔다
part1  BYTE ", ",0
part2  BYTE "assembly",0
part3  BYTE 0                   ; 빈 문자열
part4  BYTE "!",0

.code
main PROC
    INVOKE Str_concat, ADDR buffer, ADDR part1  ; buffer = "Hello, "
    call ShowBuffer
    INVOKE Str_concat, ADDR buffer, ADDR part2  ; buffer = "Hello, assembly"
    call ShowBuffer
    INVOKE Str_concat, ADDR buffer, ADDR part3  ; buffer = "Hello, assembly"
    call ShowBuffer
    INVOKE Str_concat, ADDR buffer, ADDR part4  ; buffer = "Hello, assembly!"
    call ShowBuffer
    exit
main ENDP

;-----------------------------------------------------------
Str_concat PROC USES eax ecx esi edi,
    target:PTR BYTE,            ; 덧붙일 곳 (공간이 충분해야 한다)
    source:PTR BYTE             ; 덧붙일 문자열
;
; target 문자열의 끝에 source 문자열을 덧붙인다.
;-----------------------------------------------------------
    mov  edi,target
    mov  al,0                   ; 널을 찾는다
    mov  ecx,-1                 ; 길이를 모르므로 가장 큰 값
    cld
    repne scasb                 ; EDI = 널의 다음 주소
    dec  edi                    ; EDI = 널의 주소 (여기부터 덮어쓴다)
    INVOKE Str_length,source    ; EAX = 덧붙일 길이
    mov  ecx,eax
    inc  ecx                    ; 널까지 복사한다
    mov  esi,source
    rep  movsb
    ret
Str_concat ENDP

ShowBuffer PROC                 ; buffer를 [ ] 안에 출력한다
    mov  al,'['
    call WriteChar
    mov  edx,OFFSET buffer
    call WriteString
    mov  al,']'
    call WriteChar
    call Crlf
    ret
ShowBuffer ENDP
END main
```

실행 결과:

```text
[Hello, ]
[Hello, assembly]
[Hello, assembly]
[Hello, assembly!]
```

`mov ecx,-1`은 ECX를 0FFFFFFFFh로 만들어 사실상 "널을 찾을 때까지" 검사하게 하는 관용구로, 9.2절 [REPNE SCASB로 문자열 길이 구하기](#repne-scasb로-문자열-길이-구하기-보충)와 같다. `Str_length`는 `USES edi`로 EDI를 보존하므로 호출한 뒤에도 EDI가 그대로 덧붙일 위치를 가리킨다. 빈 문자열을 덧붙이면 길이가 0이라 널 한 바이트만 복사되고 결과는 바뀌지 않는다.

이어 붙일 때마다 대상을 처음부터 훑어 끝을 찾으므로, 긴 문자열에 조금씩 여러 번 이어 붙이면 갈수록 느려진다. 조엘 스폴스키(Joel Spolsky)는 C의 `strcat`을 예로 들어 이를 "페인트공 슐레미엘의 알고리즘(Shlemiel the painter's algorithm)"이라고 불렀다. 끝의 주소를 기억해 두었다가 다음번에 거기서 시작하면 피할 수 있다.

</details>

### 연습 3. 문자열의 일부 지우기

문자열의 지정한 위치부터 문자 n개를 지우고 뒤의 문자들을 앞으로 당기는 `Str_remove PROTO, pStart:PTR BYTE, nChars:DWORD`를 작성하라. 남은 문자보다 많이 지우라고 하면 끝까지만 지운다.

<details>
<summary>풀이 보기</summary>

```asm
; 연습 3: 문자열의 일부 지우기
INCLUDE Irvine32.inc

Str_remove PROTO, pStart:PTR BYTE, nChars:DWORD

.data
str1 BYTE "abcXXXXdefg",0
str2 BYTE "Hello, World",0
str3 BYTE "ABC",0
str4 BYTE "  two spaces",0

.code
main PROC
    INVOKE Str_remove, OFFSET str1 + 3, 4       ; str1 = "abcdefg"
    mov  edx,OFFSET str1
    call ShowBracketed
    INVOKE Str_remove, OFFSET str2 + 5, 100     ; str2 = "Hello"
    mov  edx,OFFSET str2
    call ShowBracketed
    INVOKE Str_remove, ADDR str3, 0             ; str3 = "ABC"
    mov  edx,OFFSET str3
    call ShowBracketed
    INVOKE Str_remove, ADDR str4, 2             ; str4 = "two spaces"
    mov  edx,OFFSET str4
    call ShowBracketed
    exit
main ENDP

;-----------------------------------------------------------
Str_remove PROC USES eax ecx esi edi,
    pStart:PTR BYTE,            ; 지우기 시작할 위치
    nChars:DWORD                ; 지울 문자 수
;
; pStart부터 nChars개의 문자를 지우고 뒤의 문자를 앞으로 당긴다.
;-----------------------------------------------------------
    INVOKE Str_length,pStart    ; EAX = pStart부터 끝까지의 길이
    mov  ecx,nChars
    cmp  ecx,eax
    jbe  L1
    mov  ecx,eax                ; 남은 것보다 많으면 남은 것만 지운다
L1: mov  edi,pStart             ; 여기에 덮어쓴다
    mov  esi,edi
    add  esi,ecx                ; 지울 부분의 바로 뒤
    sub  eax,ecx                ; EAX = 당겨 올 문자 수
    mov  ecx,eax
    inc  ecx                    ; 널까지 옮긴다
    cld                         ; 앞쪽으로 옮기므로 정방향이 안전하다
    rep  movsb
    ret
Str_remove ENDP

ShowBracketed PROC              ; EDX가 가리키는 문자열을 [ ] 안에 출력한다
    mov  al,'['
    call WriteChar
    call WriteString
    mov  al,']'
    call WriteChar
    call Crlf
    ret
ShowBracketed ENDP
END main
```

실행 결과:

```text
[abcdefg]
[Hello]
[ABC]
[two spaces]
```

원본(ESI)이 대상(EDI)보다 **뒤**에 있으므로 앞에서부터 옮겨도 아직 읽지 않은 바이트를 덮어쓰지 않는다. 반대로 문자를 끼워 넣으려고 뒤로 밀 때는 대상이 원본보다 뒤에 있으므로, `STD`를 쓰고 끝에서부터 옮겨야 한다(9.2절 [방향 플래그](#방향-플래그-direction-flag)의 겹치는 복사 예). C 표준도 `memcpy`는 두 영역이 겹치면 동작을 정의하지 않고, 겹칠 수 있을 때는 `memmove`를 쓰도록 한다.

전역 변수 안의 주소는 `OFFSET str1 + 3`처럼 상수 식으로 넘길 수 있다. 4번째 예처럼 앞쪽의 문자를 지우는 데에도 그대로 쓸 수 있다.

</details>

### 연습 4. 문자열 찾기

문자열 `target`에서 문자열 `source`가 처음 나오는 위치를 찾는 `Str_find PROTO, source:PTR BYTE, target:PTR BYTE`를 작성하라. 찾으면 ZF = 1과 EAX = 위치(0부터 센 인덱스)를, 못 찾으면 ZF = 0과 EAX = −1을 돌려준다. 찾을 문자열이 비었거나 대상보다 긴 경우도 처리하라.

<details>
<summary>풀이 보기</summary>

```asm
; 연습 4: 문자열 찾기
INCLUDE Irvine32.inc

Str_find PROTO, source:PTR BYTE, target:PTR BYTE

.data
target1 BYTE "ABABCABCABD",0
find1   BYTE "ABCABD",0
find2   BYTE "ABD",0
find3   BYTE "XYZ",0
find4   BYTE 0                  ; 빈 문자열
find5   BYTE "ABABCABCABDX",0   ; target1보다 길다
msgAt   BYTE " found at index ",0
msgNo   BYTE " not found",0

.code
main PROC
    INVOKE Str_find, ADDR find1, ADDR target1   ; ZF = 1, EAX = 5
    mov  ebx,OFFSET find1
    call ShowFind
    mov  ebx,OFFSET find2
    call ShowFind
    mov  ebx,OFFSET find3
    call ShowFind
    mov  ebx,OFFSET find4
    call ShowFind
    mov  ebx,OFFSET find5
    call ShowFind
    exit
main ENDP

;-----------------------------------------------------------
Str_find PROC USES ebx ecx edx esi edi,
    source:PTR BYTE,            ; 찾을 문자열
    target:PTR BYTE             ; 찾을 곳
;
; target에서 source가 처음 나오는 위치를 찾는다.
; Returns: 찾으면 ZF를 1로, EAX에 위치(인덱스)를
;          못 찾으면 ZF를 0으로, EAX에 -1을 돌려준다
;-----------------------------------------------------------
    INVOKE Str_length,source
    mov  edx,eax                ; EDX = 찾을 문자열의 길이
    INVOKE Str_length,target
    mov  ebx,eax
    sub  ebx,edx                ; EBX = 비교를 시작할 수 있는 마지막 위치
    jl   NotFound               ; 찾을 문자열이 더 길다
    mov  eax,0                  ; EAX = 이번에 비교를 시작할 위치
    cmp  edx,0
    je   Found                  ; 빈 문자열은 위치 0에 있는 것으로 본다
    cld
L1: mov  esi,source
    mov  edi,target
    add  edi,eax
    mov  ecx,edx
    repe cmpsb                  ; 같은 동안 비교한다
    je   Found                  ; 끝까지 같았다
    inc  eax                    ; 한 칸 뒤에서 다시 비교한다
    cmp  eax,ebx
    jle  L1
NotFound:
    mov  eax,-1
    test eax,eax                ; ZF = 0
    ret
Found:
    cmp  eax,eax                ; ZF = 1 (EAX는 그대로)
    ret
Str_find ENDP

ShowFind PROC USES eax edx
; EBX가 가리키는 문자열을 target1에서 찾아 결과를 출력한다
    mov  al,'"'
    call WriteChar
    mov  edx,ebx
    call WriteString
    mov  al,'"'
    call WriteChar
    INVOKE Str_find, ebx, ADDR target1
    jnz  L1                     ; 못 찾았다
    mov  edx,OFFSET msgAt
    call WriteString
    call WriteDec               ; EAX = 위치
    jmp  L2
L1: mov  edx,OFFSET msgNo
    call WriteString
L2: call Crlf
    ret
ShowFind ENDP
END main
```

실행 결과:

```text
"ABCABD" found at index 5
"ABD" found at index 8
"XYZ" not found
"" found at index 0
"ABABCABCABDX" not found
```

시작 위치를 한 칸씩 옮겨 가며 `REPE CMPSB`로 비교하는 가장 단순한 방법(brute force)이다. 최악의 경우 비교 횟수는 (대상의 길이) × (찾을 문자열의 길이)에 비례한다. `"ABCABD"`를 찾을 때 위치 2에서는 다섯 글자가 같다가 마지막 글자에서 어긋나는데, 이 방법은 그 정보를 버리고 위치 3에서 처음부터 다시 비교한다. 크누스-모리스-프랫(KMP) 알고리즘은 이미 비교한 정보를 이용해 대상 문자열을 되돌아가 읽지 않고 찾는다.

결과를 플래그로 돌려줄 때는 `ret` 직전에 플래그를 정해야 한다. `USES`와 매개변수 때문에 어셈블러가 `ret` 앞에 넣는 에필로그(`POP`, `LEAVE` 또는 `MOV ESP,EBP`/`POP EBP`)는 플래그를 바꾸지 않으므로, 호출한 쪽에서 `JZ`/`JNZ`로 바로 검사할 수 있다. 빈 문자열을 위치 0에서 찾은 것으로 보는 것은 C의 `strstr`과 같은 규칙이다.

</details>

### 연습 5. 구분 문자로 단어 나누기

문자열에서 구분 문자를 찾아 그 자리를 널로 바꾸는 `Str_nextWord PROTO, pString:PTR BYTE, delimiter:BYTE`를 작성하라. 찾으면 ZF = 1과 EAX = 구분 문자 다음 문자의 주소를, 못 찾으면 ZF = 0을 돌려준다. 이 프로시저를 되풀이해 불러서 쉼표로 구분된 목록을 한 줄에 한 단어씩 출력하라.

<details>
<summary>풀이 보기</summary>

```asm
; 연습 5: 구분 문자로 단어 나누기
INCLUDE Irvine32.inc

Str_nextWord PROTO, pString:PTR BYTE, delimiter:BYTE

.data
list    BYTE "x86,ARM,RISC-V,MIPS",0
msgList BYTE "list now holds: ",0

.code
main PROC
    mov  esi,OFFSET list        ; ESI = 지금 단어의 시작
L1: INVOKE Str_nextWord, esi, ','
    pushfd                      ; ZF를 보관한다 (출력하면 플래그가 바뀐다)
    mov  edx,esi
    call WriteString            ; 단어 하나 (구분 문자 자리가 널이 되었다)
    call Crlf
    popfd
    jnz  L2                     ; 마지막 단어였다
    mov  esi,eax                ; 다음 단어의 시작
    jmp  L1
L2: mov  edx,OFFSET msgList     ; list = "x86"
    call WriteString
    mov  edx,OFFSET list
    call WriteString
    call Crlf
    exit
main ENDP

;-----------------------------------------------------------
Str_nextWord PROC USES esi,
    pString:PTR BYTE,           ; 검사할 문자열
    delimiter:BYTE              ; 구분 문자
;
; 문자열에서 구분 문자를 찾아 널로 바꾼다.
; Returns: 찾으면 ZF를 1로, EAX에 구분 문자 다음 문자의 주소를
;          못 찾으면 ZF를 0으로 돌려준다
;-----------------------------------------------------------
    mov  esi,pString
    cld
L1: lodsb                       ; AL에 읽고 ESI를 1 늘린다
    cmp  al,delimiter
    je   Found
    cmp  al,0
    jne  L1
    or   al,1                   ; 널을 만났다: ZF = 0으로 만든다
    ret
Found:
    mov  BYTE PTR [esi-1],0     ; 구분 문자를 널로 바꾼다
    mov  eax,esi                ; ESI는 이미 다음 문자를 가리킨다
    cmp  eax,eax                ; ZF = 1
    ret
Str_nextWord ENDP
END main
```

실행 결과:

```text
x86
ARM
RISC-V
MIPS
list now holds: x86
```

`LODSB`는 읽은 다음 ESI를 늘리므로, 구분 문자를 찾은 순간 ESI는 이미 다음 단어의 첫 글자를 가리킨다. 그래서 구분 문자의 주소는 `[esi-1]`이다. 널을 만나 루프를 빠져나올 때는 `cmp al,0` 때문에 ZF = 1이므로, `OR AL,1`로 ZF를 0으로 바꾼 다음 돌아간다.

마지막 줄에서 보듯 원래 문자열 `list`가 바뀌었다(쉼표 자리마다 널이 들어가 처음 단어만 남은 것처럼 보인다). C의 `strtok`도 이렇게 원래 문자열을 고치므로, 원본을 보존해야 하면 복사본을 만들어 나눠야 한다. `strtok`은 다음에 검사할 위치를 함수 안에 숨겨 두기 때문에 두 문자열을 번갈아 나눌 수 없지만, 이 풀이처럼 다음 위치를 호출한 쪽에 돌려주는 방식(POSIX의 `strtok_r`과 같은 방식)은 그런 제약이 없다.

</details>

### 연습 6. 문자 빈도표

널로 끝나는 문자열에 나오는 각 문자의 개수를 DWORD 256개짜리 표에 세는 `Get_frequencies PROTO, pString:PTR BYTE, pTable:PTR DWORD`를 작성하라. 표의 i번째 원소는 문자 코드가 i인 문자의 개수다. 결과에서 0이 아닌 항목만 막대그래프처럼 출력하라.

<details>
<summary>풀이 보기</summary>

```asm
; 연습 6: 문자 빈도표
INCLUDE Irvine32.inc

Get_frequencies PROTO, pString:PTR BYTE, pTable:PTR DWORD

.data
text      BYTE "MISSISSIPPI RIVER",0
freqTable DWORD 256 DUP(?)

.code
main PROC
    INVOKE Get_frequencies, ADDR text, ADDR freqTable
    mov  eax,freqTable['S' * TYPE freqTable]    ; EAX = 4
    mov  esi,0                  ; 문자 코드 0~255
L1: mov  ecx,freqTable[esi*4]   ; ECX = 그 문자의 개수
    jecxz L3                    ; 나오지 않은 문자는 건너뛴다
    mov  al,"'"
    call WriteChar
    mov  eax,esi
    call WriteChar              ; 문자
    mov  al,"'"
    call WriteChar
    mov  al,' '
    call WriteChar
    mov  eax,ecx
    call WriteDec               ; 개수
    mov  al,' '
    call WriteChar
    mov  al,'*'
L2: call WriteChar              ; 개수만큼 별표
    loop L2
    call Crlf
L3: inc  esi
    cmp  esi,256
    jb   L1
    exit
main ENDP

;-----------------------------------------------------------
Get_frequencies PROC USES eax ecx esi edi,
    pString:PTR BYTE,           ; 널로 끝나는 문자열
    pTable:PTR DWORD            ; DWORD 256개짜리 표
;
; 문자열에 나오는 각 문자(바이트)의 개수를 센다.
; 표의 i번째 원소 = 문자 코드가 i인 문자의 개수
;-----------------------------------------------------------
    mov  edi,pTable             ; 먼저 표를 0으로 채운다
    mov  ecx,256
    mov  eax,0
    cld
    rep  stosd                  ; EAX는 0인 채로 남는다
    mov  edi,pTable
    mov  esi,pString
L1: lodsb                       ; AL = 다음 문자 (EAX의 위쪽 24비트는 0)
    cmp  al,0
    je   L2                     ; 문자열의 끝
    inc  DWORD PTR [edi + eax*4]    ; 그 문자의 칸을 1 늘린다
    jmp  L1
L2: ret
Get_frequencies ENDP
END main
```

실행 결과:

```text
' ' 1 *
'E' 1 *
'I' 5 *****
'M' 1 *
'P' 2 **
'R' 2 **
'S' 4 ****
'V' 1 *
```

문자 코드를 그대로 표의 인덱스로 쓰므로 문자를 하나씩 비교해 찾을 필요가 없다. `LODSB`는 AL만 바꾸므로 EAX를 미리 0으로 만들어 두면 EAX 전체가 곧 문자 코드(0~255)가 되고, `[edi + eax*4]`로 그 칸에 바로 접근할 수 있다. 여기서는 `REP STOSD`로 표를 지운 뒤 EAX가 0인 채로 남는 것을 그대로 이용했다. 문자열을 한 번만 훑으면 되므로 시간은 문자열의 길이에 비례하고, 표의 크기는 문자열과 상관없이 256칸으로 일정하다. 출력할 때처럼 표를 0번부터 차례로 읽어 내려가면 문자가 코드 순서로 나오는데, 이것이 계수 정렬(counting sort)의 원리다.

`freqTable['S' * TYPE freqTable]`처럼 문자 상수로 계산한 변위를 써서 특정 문자의 칸을 바로 읽을 수도 있다.

</details>

### 연습 7. 에라토스테네스의 체

에라토스테네스의 체(sieve of Eratosthenes)로 1,000 이하의 소수를 모두 구하라. 바이트 배열을 `REP STOSB`로 한 번에 1(소수 후보)로 채운 다음, 소수의 배수를 0으로 지운다. 100 이하의 소수를 출력하고, 1,000 이하 소수의 개수를 세라.

<details>
<summary>풀이 보기</summary>

```asm
; 연습 7: 에라토스테네스의 체
INCLUDE Irvine32.inc

N = 1000

.data
sieve    BYTE N+1 DUP(?)        ; sieve[i] = 1이면 i는 소수
msgList  BYTE "Primes up to 100:",0
msgCount BYTE "Number of primes up to 1000: ",0

.code
main PROC
    ; 1. 모두 1(소수 후보)로 채운다
    mov  edi,OFFSET sieve
    mov  ecx,N+1
    mov  al,1
    cld
    rep  stosb
    mov  sieve[0],0             ; 0과 1은 소수가 아니다
    mov  sieve[1],0
    ; 2. 소수 i의 배수를 지운다 (i * i <= N인 동안)
    mov  ebx,2                  ; EBX = i
L1: mov  eax,ebx
    mul  ebx                    ; EAX = i * i
    cmp  eax,N
    ja   L4                     ; i * i > N이면 끝
    cmp  sieve[ebx],0
    je   L3                     ; 이미 지워진 수(합성수)는 건너뛴다
L2: mov  sieve[eax],0           ; i * i, i * i + i, i * i + 2i, ...
    add  eax,ebx
    cmp  eax,N
    jbe  L2
L3: inc  ebx
    jmp  L1
    ; 3. 100 이하의 소수를 출력한다
L4: mov  edx,OFFSET msgList
    call WriteString
    mov  esi,2
L5: cmp  sieve[esi],0
    je   L6
    mov  al,' '
    call WriteChar
    mov  eax,esi
    call WriteDec
L6: inc  esi
    cmp  esi,100
    jbe  L5
    call Crlf
    ; 4. 1000 이하의 소수를 센다 (각 칸이 0 또는 1이므로 모두 더한다)
    mov  esi,OFFSET sieve
    mov  ecx,N+1
    mov  ebx,0                  ; 개수
L7: lodsb
    movzx eax,al
    add  ebx,eax
    loop L7
    mov  edx,OFFSET msgCount
    call WriteString
    mov  eax,ebx                ; EAX = 168
    call WriteDec
    call Crlf
    exit
main ENDP
END main
```

실행 결과:

```text
Primes up to 100: 2 3 5 7 11 13 17 19 23 29 31 37 41 43 47 53 59 61 67 71 73 79 83 89 97
Number of primes up to 1000: 168
```

소수 i의 배수 중 i × i보다 작은 것(2i, 3i, …, (i − 1)i)은 i보다 작은 소수의 배수로 이미 지워졌으므로 i × i부터 지운다. 같은 이유로 i × i가 N을 넘으면 더 지울 것이 없다. N = 1,000이면 i = 31(31² = 961)까지만 보면 된다. 체의 시간 복잡도는 O(N log log N)으로, 수마다 나눗셈으로 소수인지 검사하는 것보다 훨씬 빠르다.

배열 초기화는 `REP STOSB` 한 번으로 끝난다. C의 `memset`이 하는 일과 같다(9.2절의 측정에서 `memset`과 비슷한 속도였다). 마지막에 개수를 셀 때는 각 칸이 0 또는 1이므로 `LODSB`로 읽어 그대로 더하면 된다.

</details>

### 연습 8. 교환 여부로 일찍 끝나는 버블 정렬

9.5절의 `BubbleSort`는 배열이 이미 정렬되어 있어도 n − 1번을 모두 훑는다. 한 번 훑는 동안 교환이 한 번도 없으면 바로 끝내도록 고친 `BubbleSort2`를 작성하라. 확인을 위해 훑은 횟수를 EDX로 돌려주고, 이미 정렬된 배열, 두 군데만 뒤바뀐 배열, 거꾸로 정렬된 배열, 원소가 1개인 배열로 시험하라.

<details>
<summary>풀이 보기</summary>

```asm
; 연습 8: 교환 여부로 일찍 끝나는 버블 정렬
INCLUDE Irvine32.inc

BubbleSort2 PROTO, pArray:PTR SDWORD, Count:DWORD
ShowResult  PROTO, pArray:PTR SDWORD, Count:DWORD

.data
arrA SDWORD -20, -5, 0, 3, 8, 15, 42, 99    ; 이미 정렬됨
arrB SDWORD -20, 0, -5, 3, 8, 15, 99, 42    ; 두 군데만 뒤바뀜
arrC SDWORD 99, 42, 15, 8, 3, 0, -5, -20    ; 거꾸로 정렬됨
arrD SDWORD 7                               ; 원소 1개
msgPass BYTE "(passes: ",0

.code
main PROC
    INVOKE BubbleSort2, ADDR arrA, LENGTHOF arrA    ; EDX = 1
    INVOKE ShowResult, ADDR arrA, LENGTHOF arrA
    INVOKE BubbleSort2, ADDR arrB, LENGTHOF arrB    ; EDX = 2, arrB = [-20, -5, 0, 3, 8, 15, 42, 99]
    INVOKE ShowResult, ADDR arrB, LENGTHOF arrB
    INVOKE BubbleSort2, ADDR arrC, LENGTHOF arrC    ; EDX = 7, arrC = [-20, -5, 0, 3, 8, 15, 42, 99]
    INVOKE ShowResult, ADDR arrC, LENGTHOF arrC
    INVOKE BubbleSort2, ADDR arrD, LENGTHOF arrD    ; EDX = 0
    INVOKE ShowResult, ADDR arrD, LENGTHOF arrD
    exit
main ENDP

;-----------------------------------------------------------
BubbleSort2 PROC USES eax ebx ecx esi,
    pArray:PTR SDWORD,          ; 배열의 주소
    Count:DWORD                 ; 원소 개수
;
; 부호 있는 DWORD 배열을 오름차순으로 정렬한다.
; 한 번 훑는 동안 교환이 없으면 정렬이 끝난 것으로 보고 멈춘다.
; Returns: EDX = 훑은 횟수 (확인용)
;-----------------------------------------------------------
    mov  edx,0                  ; 훑은 횟수
    mov  ecx,Count
    dec  ecx                    ; 바깥 루프 횟수 = Count - 1
    jle  L4                     ; 원소가 1개 이하면 할 일이 없다
L1: push ecx                    ; 바깥 루프 카운터 저장
    inc  edx
    mov  ebx,0                  ; 교환 플래그: 0 = 아직 교환 없음
    mov  esi,pArray
L2: mov  eax,[esi]
    cmp  [esi+4],eax
    jge  L3                     ; [esi+4] >= [esi]이면 그대로 둔다
    xchg eax,[esi+4]            ; 두 원소를 바꾼다
    mov  [esi],eax
    mov  ebx,1                  ; 교환했다
L3: add  esi,4
    loop L2
    pop  ecx
    cmp  ebx,0
    je   L4                     ; 교환이 없었다: 정렬 끝
    loop L1
L4: ret
BubbleSort2 ENDP

;-----------------------------------------------------------
ShowResult PROC USES eax ecx edx esi,
    pArray:PTR SDWORD,          ; 배열의 주소
    Count:DWORD                 ; 원소 개수
; 배열을 한 줄로 출력하고 이어서 EDX(훑은 횟수)를 출력한다
;-----------------------------------------------------------
    mov  esi,pArray
    mov  ecx,Count
L1: mov  eax,[esi]
    call WriteInt
    mov  al,' '
    call WriteChar
    add  esi,4
    loop L1
    mov  eax,edx                ; 훑은 횟수
    mov  edx,OFFSET msgPass
    call WriteString
    call WriteDec
    mov  al,')'
    call WriteChar
    call Crlf
    ret
ShowResult ENDP
END main
```

실행 결과:

```text
-20 -5 +0 +3 +8 +15 +42 +99 (passes: 1)
-20 -5 +0 +3 +8 +15 +42 +99 (passes: 2)
-20 -5 +0 +3 +8 +15 +42 +99 (passes: 7)
+7 (passes: 0)
```

한 번 훑는 동안 교환이 없었다면 이웃한 모든 쌍이 순서대로라는 뜻이므로 배열 전체가 정렬된 것이다.

| 배열 | 훑은 횟수 | 비교 횟수 (원래 `BubbleSort`는 항상 28번) |
|---|---|---|
| 이미 정렬됨 | 1 | 7 |
| 두 군데만 뒤바뀜 | 2 | 7 + 6 = 13 |
| 거꾸로 정렬됨 | 7 | 7 + 6 + … + 1 = 28 |

거꾸로 정렬된 배열은 매번 교환이 일어나므로 원래 알고리즘과 똑같이 모두 훑는다. 최악의 경우는 여전히 O(n²)이지만, 이미 정렬된 배열에서는 한 번만 훑으므로 최선의 경우가 O(n)이 된다. 정렬된 배열에 원소를 몇 개 추가한 뒤 다시 정렬하는 경우처럼 "거의 정렬된" 데이터에서 효과가 크다. 원소가 1개 이하면 `jle L4`로 바로 끝나므로 9.5절 WARNING에서 본 문제(Count가 0이나 1일 때)도 생기지 않는다.

</details>

### 연습 9. 레지스터만 쓰는 이진 검색

9.5절의 `BinarySearch`는 first, last, mid를 지역 변수(스택 메모리)에 두었다. 이 세 값을 모두 레지스터에 두도록 다시 작성하고, 각 레지스터에 무엇이 들어 있는지 주석으로 밝혀라. 배열의 모든 원소를 찾아보고, 배열에 없는 값(맨 앞보다 작은 값, 원소 사이의 값, 맨 뒤보다 큰 값)도 시험하라.

<details>
<summary>풀이 보기</summary>

```asm
; 연습 9: 레지스터만 쓰는 이진 검색
INCLUDE Irvine32.inc

BinSearch2 PROTO, pArray:PTR SDWORD, Count:DWORD, searchVal:SDWORD

.data
array   SDWORD -30, -12, 0, 7, 15, 23, 41, 56, 78, 99
missing SDWORD -31, 8, 24, 100  ; 배열에 없는 값
msgHit  BYTE "positions:",0
msgMiss BYTE "missing values:",0

.code
main PROC
    INVOKE BinSearch2, ADDR array, LENGTHOF array, 56   ; EAX = 7
    ; 1. 모든 원소를 찾아본다
    mov  edx,OFFSET msgHit
    call WriteString
    mov  esi,0
L1: mov  al,' '
    call WriteChar
    INVOKE BinSearch2, ADDR array, LENGTHOF array, array[esi*4]
    call WriteDec               ; 찾은 위치
    inc  esi
    cmp  esi,LENGTHOF array
    jb   L1
    call Crlf
    ; 2. 배열에 없는 값을 찾아본다
    mov  edx,OFFSET msgMiss
    call WriteString
    mov  esi,0
L2: mov  al,' '
    call WriteChar
    INVOKE BinSearch2, ADDR array, LENGTHOF array, missing[esi*4]
    call WriteInt               ; -1이어야 한다
    inc  esi
    cmp  esi,LENGTHOF missing
    jb   L2
    call Crlf
    exit
main ENDP

;-----------------------------------------------------------
BinSearch2 PROC USES ebx ecx edx esi,
    pArray:PTR SDWORD,          ; 정렬된 배열의 주소
    Count:DWORD,                ; 원소 개수
    searchVal:SDWORD            ; 찾을 값
;
; 지역 변수 없이 레지스터만으로 이진 검색을 한다.
;   EBX = first, EDX = last, ECX = mid
;   ESI = 배열의 주소, EAX = 찾을 값
; Returns: 찾으면 EAX에 위치를, 못 찾으면 EAX에 -1을 돌려준다
;-----------------------------------------------------------
    mov  esi,pArray
    mov  eax,searchVal
    mov  ebx,0                  ; first = 0
    mov  edx,Count
    dec  edx                    ; last = Count - 1
L1: cmp  ebx,edx
    jg   NotFound               ; first > last면 없다
    mov  ecx,edx
    sub  ecx,ebx
    shr  ecx,1
    add  ecx,ebx                ; mid = first + (last - first) / 2
    cmp  eax,[esi + ecx*4]      ; 찾을 값과 array[mid]를 비교한다
    je   Found
    jl   L2
    mov  ebx,ecx                ; 찾을 값 > array[mid]이면
    inc  ebx                    ;   first = mid + 1
    jmp  L1
L2: mov  edx,ecx                ; 찾을 값 < array[mid]이면
    dec  edx                    ;   last = mid - 1
    jmp  L1
Found:
    mov  eax,ecx                ; 찾은 위치
    ret
NotFound:
    mov  eax,-1
    ret
BinSearch2 ENDP
END main
```

실행 결과:

```text
positions: 0 1 2 3 4 5 6 7 8 9
missing values: -1 -1 -1 -1
```

레지스터는 메모리보다 훨씬 빨리 읽고 쓸 수 있고, 지역 변수를 위한 스택 프레임(`LOCAL`)도 필요 없다. 대신 범용 레지스터가 몇 개 없으므로, 어느 레지스터에 무엇을 둘지 정하고 주석으로 분명히 해 두는 것이 중요하다. 컴파일러가 최적화하면서 하는 레지스터 할당(register allocation)이 바로 이 일이다.

mid는 9.5절의 TIP처럼 first + (last − first) / 2로 구해 덧셈 넘침을 피했다. 원소가 10개이므로 어느 값이든 비교는 최대 ⌊log₂10⌋ + 1 = 4번이면 끝난다. 처음에 last = Count − 1이므로 원소가 0개인 배열이면 last = −1이 되어 첫 비교(`first > last`)에서 바로 −1을 돌려준다.

</details>

### 연습 10. 원소 크기에 상관없는 행 합

9.4절의 `calc_row_sum`은 BYTE 표만 처리했다. 원소 크기(1, 2, 4바이트)를 매개변수로 받아 BYTE, WORD, DWORD 표 모두에서 한 행의 합을 구하는 `calc_row_sum2`를 작성하라(원소는 부호 없는 정수로 본다). 원소 크기만 다르고 값의 모양이 같은 세 표로 시험하라.

<details>
<summary>풀이 보기</summary>

```asm
; 연습 10: 원소 크기에 상관없는 행 합
INCLUDE Irvine32.inc

calc_row_sum2 PROTO, pTable:PTR BYTE, rowIndex:DWORD, colCount:DWORD, eltSize:DWORD
ShowRowSums   PROTO, pTable:PTR BYTE, eltSize:DWORD

ROWS = 3
COLS = 4

.data
tblB BYTE    10h,   20h,   30h,   40h
     BYTE    50h,   60h,   70h,   80h
     BYTE    90h,  0A0h,  0B0h,  0C0h
tblW WORD  1000h, 2000h, 3000h, 4000h
     WORD  5000h, 6000h, 7000h, 8000h
     WORD  9000h,0A000h,0B000h,0C000h
tblD DWORD 100000h, 200000h, 300000h, 400000h
     DWORD 500000h, 600000h, 700000h, 800000h
     DWORD 900000h,0A00000h,0B00000h,0C00000h
msgB BYTE "BYTE :",0
msgW BYTE "WORD :",0
msgD BYTE "DWORD:",0

.code
main PROC
    INVOKE calc_row_sum2, ADDR tblW, 2, COLS, TYPE tblW     ; EAX = 2A000h
    mov  edx,OFFSET msgB
    call WriteString
    INVOKE ShowRowSums, ADDR tblB, TYPE tblB
    mov  edx,OFFSET msgW
    call WriteString
    INVOKE ShowRowSums, ADDR tblW, TYPE tblW
    mov  edx,OFFSET msgD
    call WriteString
    INVOKE ShowRowSums, ADDR tblD, TYPE tblD
    exit
main ENDP

;-----------------------------------------------------------
calc_row_sum2 PROC USES ebx ecx edx esi,
    pTable:PTR BYTE,            ; 표의 주소
    rowIndex:DWORD,             ; 행 번호 (0부터)
    colCount:DWORD,             ; 한 행의 원소 수
    eltSize:DWORD               ; 원소 크기: 1, 2, 4
;
; 원소 크기가 1, 2, 4바이트인 2차원 표(행 우선)에서
; 한 행의 합을 구한다. 원소는 부호 없는 정수로 본다.
; Returns: EAX = 합
;-----------------------------------------------------------
    mov  eax,colCount
    mul  eltSize                ; EAX = 한 행의 바이트 수
    mul  rowIndex               ; EAX = 행의 오프셋
    mov  ebx,pTable
    add  ebx,eax                ; EBX = 행의 시작 주소
    mov  eax,0                  ; 합
    mov  esi,0                  ; 열 번호
    mov  ecx,colCount
    cmp  eltSize,1
    je   SumBytes
    cmp  eltSize,2
    je   SumWords
SumDwords:                      ; 원소 크기 4: 배율 4
    add  eax,[ebx + esi*4]
    inc  esi
    loop SumDwords
    ret
SumBytes:                       ; 원소 크기 1: 배율 1
    movzx edx,BYTE PTR [ebx + esi]
    add  eax,edx
    inc  esi
    loop SumBytes
    ret
SumWords:                       ; 원소 크기 2: 배율 2
    movzx edx,WORD PTR [ebx + esi*2]
    add  eax,edx
    inc  esi
    loop SumWords
    ret
calc_row_sum2 ENDP

;-----------------------------------------------------------
ShowRowSums PROC USES eax ecx,
    pTable:PTR BYTE,            ; 표의 주소
    eltSize:DWORD               ; 원소 크기
; 표의 각 행의 합을 16진수로 한 줄에 출력한다
;-----------------------------------------------------------
    mov  ecx,0                  ; 행 번호
L1: mov  al,' '
    call WriteChar
    INVOKE calc_row_sum2, pTable, ecx, COLS, eltSize
    call WriteHex
    inc  ecx
    cmp  ecx,ROWS
    jb   L1
    call Crlf
    ret
ShowRowSums ENDP
END main
```

실행 결과:

```text
BYTE : 000000A0 000001A0 000002A0
WORD : 0000A000 0001A000 0002A000
DWORD: 00A00000 01A00000 02A00000
```

배율은 명령어의 기계어(SIB 바이트)에 새겨지는 상수라서 실행 중에 레지스터 값으로 바꿀 수 없다. 그래서 원소 크기에 따라 서로 다른 루프로 갈라지게 했다. 세 루프 모두 ESI는 열 번호이고, 배율 1, 2, 4가 열 번호를 바이트 오프셋으로 바꿔 준다. 행의 오프셋은 "행 번호 × 열 수 × 원소 크기"로 `MUL` 두 번이면 구해진다.

BYTE와 WORD 원소는 `MOVZX`로 32비트로 넓혀서 더하므로, 합이 원소의 범위를 넘어도(WORD 표의 2행 합 2A000h처럼) 넘치지 않는다. 세 표의 값이 같은 모양이므로 결과도 자릿수만 다른 같은 모양이 된다.

</details>

### 연습 11. 행렬 전치

3행 4열인 DWORD 행렬 A의 전치 행렬 B(4행 3열, B[c][r] = A[r][c])를 만드는 프로그램을 작성하라. A와 B 모두 베이스-인덱스-변위 피연산자로 접근하고, 두 행렬을 출력하라.

<details>
<summary>풀이 보기</summary>

```asm
; 연습 11: 행렬 전치
INCLUDE Irvine32.inc

PrintMatrix PROTO, pMat:PTR DWORD, nRows:DWORD, nCols:DWORD

ROWS = 3
COLS = 4

.data
matA DWORD  1,  2,  3,  4
     DWORD  5,  6,  7,  8
     DWORD  9, 10, 11, 12
matB DWORD COLS * ROWS DUP(0)   ; 4행 3열
msgA BYTE "A (3 x 4):",0
msgB BYTE "B = transpose of A (4 x 3):",0

.code
main PROC
    mov  ebx,0                  ; A의 행 오프셋 (r * COLS * 4)
    mov  edx,0                  ; r
L1: mov  esi,0                  ; c
    mov  edi,0                  ; B의 행 오프셋 (c * ROWS * 4)
L2: mov  eax,matA[ebx + esi*TYPE matA]      ; A[r][c]
    mov  matB[edi + edx*TYPE matB],eax      ; B[c][r]
    inc  esi                    ; 다음 열
    add  edi,ROWS * TYPE matB   ; B에서는 다음 행
    cmp  esi,COLS
    jb   L2
    add  ebx,COLS * TYPE matA   ; A의 다음 행
    inc  edx
    cmp  edx,ROWS
    jb   L1                     ; 끝나면 matB = [1, 5, 9, 2, 6, 10, 3, 7, 11, 4, 8, 12]
    mov  edx,OFFSET msgA
    call WriteString
    call Crlf
    INVOKE PrintMatrix, ADDR matA, ROWS, COLS
    mov  edx,OFFSET msgB
    call WriteString
    call Crlf
    INVOKE PrintMatrix, ADDR matB, COLS, ROWS
    exit
main ENDP

;-----------------------------------------------------------
PrintMatrix PROC USES eax ecx edx esi,
    pMat:PTR DWORD,             ; 행렬의 주소 (행 우선)
    nRows:DWORD,                ; 행 수
    nCols:DWORD                 ; 열 수
; 행렬을 한 행에 한 줄씩, 원소마다 3칸 폭으로 출력한다
;-----------------------------------------------------------
    mov  esi,pMat
    mov  edx,nRows
L1: mov  ecx,nCols
L2: mov  al,' '
    call WriteChar
    cmp  DWORD PTR [esi],10
    jae  L3
    call WriteChar              ; 한 자리 수는 한 칸 더 띄운다
L3: mov  eax,[esi]
    call WriteDec
    add  esi,4
    loop L2
    call Crlf
    dec  edx
    jnz  L1
    ret
PrintMatrix ENDP
END main
```

실행 결과:

```text
A (3 x 4):
  1  2  3  4
  5  6  7  8
  9 10 11 12
B = transpose of A (4 x 3):
  1  5  9
  2  6 10
  3  7 11
  4  8 12
```

A는 한 행을 따라 차례로 읽지만, B에는 쓸 때마다 B의 한 행(3 × 4 = 12바이트)씩 건너뛰며 쓴다. 두 행렬에서 같은 원소를 가리키는 데 레지스터 역할이 서로 바뀐다는 점이 핵심이다. A에서는 EBX가 행 오프셋, ESI가 열 번호지만, B에서는 EDI(= c × 12)가 행 오프셋이고 EDX(= r)가 열 번호다.

9.4절 [열 단위 처리와 순회 순서](#열-단위-처리와-순회-순서-보충)에서 본 것처럼, 큰 행렬에서는 이렇게 띄엄띄엄 접근하는 쪽이 캐시 때문에 느려진다. 그래서 큰 행렬의 전치는 캐시에 들어가는 작은 블록 단위로 나눠서 처리한다(blocking 또는 tiling이라고 한다). 정사각 행렬이라면 B 없이 A[r][c]와 A[c][r](c > r)을 맞바꿔 제자리에서 전치할 수도 있다.

</details>

---

## 부록 G. 슬라이드 정정 사항 모음

본문의 정정 박스에 적은 내용을 한곳에 모았다. 슬라이드 번호는 표지를 1번으로 센 것이다.

| 위치 | 슬라이드 표기 | 올바른 내용 |
|---|---|---|
| 16번 Str_trim 코드 | 마지막 줄 `Stmr_trim ENDP` | `ENDP` 앞의 이름은 `PROC`의 이름과 같아야 한다. `Str_trim ENDP` |
| 29번 Base-Index-Displacement | `mov ebx,Rowsize`의 주석 `; row index` | EBX에 들어가는 것은 행 번호(1)가 아니라 행 1의 **바이트 오프셋**(Rowsize = 20)이다. 행 번호 r로 접근하려면 `r × Rowsize`를 넣어야 한다 |
| 31번 그림 (Figure 9-4) | 마지막 열이 1, 3, 5, **7, 2**, 4, 3, 9 | 바로 앞 단계에서 2와 7이 이미 바뀌었으므로 1, 3, 5, **2, 7**, 4, 3, 9 (마지막 단계에서는 9와 3만 바뀐다) |
| 33번 BubbleSort | `jg L3`, 주석은 "if [ESI] <= [ESI+4], no exchange" | 주석대로라면 `jge L3`다(교재 예제 `BubbleSort.asm`과 32번 유사 코드도 같은 뜻). `jg`이면 같은 값끼리도 쓸데없이 교환한다 |
| 34번 Binary Search 1단계 | "If f irst last, exit the search" | 단어가 깨지고 부등호가 빠졌다. "If **first > last**, exit the search" |

틀린 것은 아니지만 그대로 따라 하면 오해하기 쉬운 부분은 다음과 같다.

| 위치 | 슬라이드 내용 | 주의할 점 |
|---|---|---|
| 3번 Using a Repeat Prefix | "a single mem ory value" | 단어 가운데에 공백이 들어갔다("memory"). 25번의 "off set address"도 마찬가지다("offset") |
| 11번 머리글 | "String Primitive Instructions" | 내용은 9.3절 Selected String Procedures(`Str_compare`)다. 머리글은 12번부터 바뀐다 |
| 15번 Str_trim | `INVOKE ShowString,ADDR string_1` | `ShowString`은 Irvine32 라이브러리의 프로시저가 아니라 교재 예제 `Trim.asm` 안에 정의된 프로시저다 |
| 26·28번 | 상수를 `Rowsize`(`RowsizeW`)로 정의하고 `RowSize`(`RowSizeW`)로 사용 | 기본 설정에서는 대소문자를 구분하지 않아 어셈블되지만 `OPTION CASEMAP:NONE`이면 정의되지 않은 기호 오류가 난다 |
| 31~39번 머리글 | "Searching and Sorting Integers Arrays" | 교재의 절 제목은 "Searching and Sorting Integer Arrays"다 |
| 33번 BubbleSort | `Count`가 1 이하인 경우를 검사하지 않는다 | `Count`가 1이면 안쪽 루프가 ECX = 0에서 시작해 `LOOP`가 약 43억 번 반복한다. `dec ecx` 다음에 `jle`로 빠져나가야 한다 |

교재 예제 파일에서 발견한 점도 함께 적어 둔다.

| 파일 | 내용 | 주의할 점 |
|---|---|---|
| `Cmpsb.asm` | `mov cx,LENGTHOF source` | 32비트 코드의 반복 접두사는 ECX 전체를 카운터로 쓴다. `mov ecx,…`로 써야 ECX의 위쪽 16비트에 남은 값이 섞이지 않는다 |
| `Base-Index.asm` | `get_tableDval PROC USES ebx` | `MUL`이 EDX를 바꾸므로 `USES ebx edx`가 안전하다 |
| `StringLib64Test.asm` | `Str_length`를 부르기 전에 문자열 주소를 RAX에 넣는다 | `Irvine64.asm`의 `Str_length`는 RCX에서 주소를 읽는다. `mov rcx,OFFSET source`로 고쳐야 한다 |
| `Irvine32.asm` | `COMMENT` 블록 안의 예전 `Str_trim` | `STD`를 쓰고 `CLD`로 되돌리지 않는다. 지금 쓰이는 버전은 아니지만 방향 플래그를 잊으면 어떻게 되는지 보여 주는 예다 |

슬라이드 23, 30, 39번은 머리글만 있는 빈 슬라이드이고, 42번은 "Github upload"라는 안내만 있다. 슬라이드에 없어서 보충한 부분은 다음과 같다.

| 내용 | 근거 |
|---|---|
| 일반형 `MOVS dst,src`가 만드는 기계어, `REP`의 동작(ECX가 0이면 한 번도 반복하지 않는다) | 인텔 SDM, JWasm 목록 파일, 실행으로 확인 |
| 겹치는 영역의 정방향·역방향 복사, 방향 플래그 규약 | Microsoft Learn(x64 규약, Direction flag), 실행으로 확인 |
| `REPE CMPSD`가 멈춘 뒤의 레지스터 표, `REPNE SCASB`로 길이 구하기, `REPE SCASB`로 공백 건너뛰기, `STOSD`로 지우기, `LODSB`/`STOSB` 변환 복사 | 실행으로 확인 |
| 문자열 명령어와 C 라이브러리 함수의 속도 비교 | 직접 측정, 인텔 SDM |
| `Str_compare`의 비교 예, `Str_copy`의 넘침, `Str_trim`의 모든 경우, 예전 `Str_trim`의 방향 플래그 문제, `Str_ucase`의 비트 5 | Irvine32 라이브러리 소스, 실행으로 확인 |
| String Library Demo의 실행 결과(빈 슬라이드 23번 자리) | 실행으로 확인 |
| Irvine64 라이브러리의 문자열 프로시저 | 교재 9.3.7절, `Irvine64.asm` |
| 열 단위 처리와 순회 순서에 따른 속도 차이(빈 슬라이드 30번 자리) | 직접 측정 |
| 64비트 모드의 베이스-인덱스 피연산자와 2GB 제약 | 교재 9.4.4절, Microsoft Learn(LNK2017), 64비트 빌드로 확인 |
| 버블 정렬 첫 단계의 검증, 비교 횟수, 이진 검색의 단계별 추적과 mid 계산의 넘침 | 실행으로 확인 |
| 이진 검색 테스트 프로그램 전체 코드(빈 슬라이드 39번 자리) | 교재 예제 다섯 모듈, 실행으로 확인 |
| 9.6 자바 바이트코드 | 교재 9.6절, JVM 명세, JEP 280, `javac`/`javap`(JDK 21) |
| 부록 B (C 컴파일러가 만든 문자열·배열 코드) | GCC 13 출력 |

---

## 참고 자료

### 예제 값 확인 방법

이 문서의 예제는 눈으로만 검토하지 않고 실제로 돌려서 확인했다.

- `asm` 코드 블록 73개를 MASM 호환 어셈블러(JWasm 2.21)로 어셈블했다(64비트 예제 1개는 64비트 모드로 따로). 조각 코드는 프로그램 틀을 씌웠다. Irvine32 프로시저는 같은 이름과 출력 형식으로 만든 리눅스용 대체 라이브러리에 링크했으며, `Str_compare`·`Str_length`·`Str_copy`·`Str_trim`·`Str_ucase`와 `Random32`·`RandomRange`는 원래 라이브러리 소스와 같은 코드를 썼다.
- 실행 파일을 디버거(gdb)로 한 명령어씩 실행하면서 주석에 적힌 값을 실제 결과와 비교했다. 레지스터·플래그·변수 값, 문자열 변수의 내용(`target = "HELLO"`), 배열의 앞부분(`array = [1, 2, 3]`), `ESI = EBX+20` 같은 레지스터 사이의 관계, 반복할 때마다 바뀌는 값("차례로"), 루프가 끝난 뒤의 값("끝나면"), 점프 여부, 실행되지 않아야 할 줄, 어셈블 오류가 비교 대상이다. 반복 접두사가 붙은 명령어는 반복이 모두 끝난 뒤의 상태와, `CALL`·`INVOKE` 줄은 그 호출이 돌아온 직후의 상태와 비교했다. 이렇게 비교한 항목은 151개이고 모두 일치했다.
- "실행 결과" 블록 19개는 프로그램의 실제 출력과 한 줄씩 비교했다. 부록 E의 정답과 부록 F의 풀이도 같은 방법으로 확인했다.
- 64비트 예제는 64비트로 따로 빌드해 C 프로그램에서 불러 15개 원소를 모두 꺼내 확인했다. 9.2절의 속도 비교와 9.4절의 순회 순서 측정은 C로 작성한 측정 프로그램의 결과다. 부록 B는 GCC 13의 실제 출력이고, 9.6절의 바이트코드는 `javac`/`javap`(JDK 21)의 실제 출력이다.

다만 다음은 확인 범위 밖이다.

- Windows의 `ml.exe`와 Visual Studio에서 직접 실행한 것은 아니다. 명령어의 동작은 운영체제에 상관없이 같지만, 오류 메시지의 문구 등은 MASM과 다를 수 있다. 링커 오류 LNK2017처럼 MASM·Visual Studio의 동작으로 적은 부분은 교재·슬라이드와 Microsoft 문서를 근거로 했다.
- 속도 측정값은 이 문서를 만든 환경(Intel Xeon 2.3GHz)에서 잰 것으로, CPU와 데이터 크기에 따라 크게 달라진다.
- 난수를 쓰는 테스트 프로그램의 출력은 `Randomize`를 부르지 않았을 때의 값이다. 대체 라이브러리의 `Random32`가 원래 라이브러리와 같은 계산식과 초깃값을 쓰므로 같은 수열이 나온다.

### 문헌과 링크

- Kip R. Irvine, *Assembly Language for x86 Processors* (7th / 8th Edition), Pearson — Chapter 9. Strings and Arrays
- [Kip Irvine 교재 공식 사이트](https://www.asmirvine.com/) (Irvine32 라이브러리와 예제 프로그램)
- [intelligentcm 블로그 — Assembly 카테고리](https://intelligentcm.tistory.com/category/Assembly)
- [Microsoft Learn — Microsoft Macro Assembler(MASM) 참조](https://learn.microsoft.com/ko-kr/cpp/assembler/masm/microsoft-macro-assembler-reference)
- [Microsoft Learn — x64 ABI conventions](https://learn.microsoft.com/en-us/cpp/build/x64-software-conventions) (함수가 끝날 때와 C 런타임·시스템 호출에 들어갈 때 방향 플래그는 0)
- [Microsoft Learn — Direction flag](https://learn.microsoft.com/en-us/cpp/c-runtime-library/direction-flag) (C 런타임 함수는 방향 플래그가 0이라고 가정한다)
- [Microsoft Learn — Linker Tools Error LNK2017](https://learn.microsoft.com/en-us/cpp/error-messages/tool-errors/linker-tools-error-lnk2017) (`/LARGEADDRESSAWARE:NO` 없이 32비트 주소를 쓴 64비트 코드)
- [Intel® 64 and IA-32 Architectures Software Developer's Manuals](https://www.intel.com/content/www/us/en/developer/articles/technical/intel-sdm.html) (Volume 1의 빠른 문자열 연산, Volume 2의 MOVS, CMPS, SCAS, STOS, LODS, REP, CPUID 항목)
- [Wikipedia — Row- and column-major order](https://en.wikipedia.org/wiki/Row-_and_column-major_order) (언어별 저장 순서)
- [Joel Spolsky, Back to Basics](https://www.joelonsoftware.com/2001/12/11/back-to-basics/) (`strcat`과 페인트공 슐레미엘의 알고리즘)
- [JEP 280: Indify String Concatenation](https://openjdk.org/jeps/280) (JDK 9부터 문자열 연결에 `invokedynamic` 사용)
- [The Java® Virtual Machine Specification, Java SE 21 — Chapter 6](https://docs.oracle.com/javase/specs/jvms/se21/html/jvms-6.html) (`arraylength`, `iaload`, `invokevirtual`, `invokedynamic`)

<br>

> 이 문서는 강의 슬라이드를 바탕으로 개인 학습용으로 정리한 노트입니다.
