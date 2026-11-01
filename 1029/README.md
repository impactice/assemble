
# x86 어셈블리: 정수 산술 (Integer Arithmetic)

![Assembler](https://img.shields.io/badge/Assembler-MASM-blue)
![Architecture](https://img.shields.io/badge/Architecture-x86%2032--bit-lightgrey)
![IDE](https://img.shields.io/badge/IDE-Visual%20Studio%202022-5C2D91)
![Chapter](https://img.shields.io/badge/Irvine-Chapter%207-orange)

> Kip R. Irvine, *Assembly Language for x86 Processors* — Chapter 7. Integer Arithmetic 강의 정리
>
> 슬라이드 내용을 절 순서대로 정리하고, 슬라이드에 없는 동작 원리, 추가 예제, 자주 하는 실수를 보충했다. 슬라이드가 비어 있거나 빠뜨린 부분(확장 덧셈 예제, 시프트·회전의 플래그 규칙, 나눗셈 전 준비 규칙, 64비트 모드의 차이)도 채웠다.
> 슬라이드의 오류는 본문에 정정 박스로 표시하고 [부록 G](#부록-g-슬라이드-정정-사항-모음)에 모아 두었다.
> 예제 코드의 주석에 적힌 레지스터·플래그·변수 값과 실행 결과는 직접 어셈블하고 한 명령어씩 실행해서 확인한 값이다([예제 값 확인 방법](#예제-값-확인-방법)).

---

## 한눈에 보기 (TL;DR)

- **시프트**는 비트를 한쪽으로 밀고, 마지막으로 밀려난 비트를 CF에 넣는다. `SHL`(=`SAL`)은 2ⁿ을 곱하고, `SHR`은 부호 없는 수를, `SAR`은 부호 있는 수를 2ⁿ으로 나눈다. 나머지 비트는 버려진다.
- **회전**(`ROL`, `ROR`)은 밀려난 비트를 반대쪽 끝으로 다시 넣으므로 비트를 잃지 않는다. `RCL`, `RCR`은 CF까지 한 비트로 끼워서 회전한다.
- 시프트·회전의 OF는 **횟수가 1일 때만** 의미가 있다. 회전은 SF·ZF·PF를 바꾸지 않는다.
- `SHLD`, `SHRD`는 두 피연산자를 이어 붙인 것처럼 시프트한다. 여러 워드로 된 큰 수를 시프트할 때 쓴다.
- `MUL`(부호 없음)과 `IMUL`(부호 있음)의 1-피연산자 형식은 곱을 두 배 크기(AX, DX:AX, EDX:EAX)에 저장하고, 상위 절반이 필요하면 CF = OF = 1이 된다. `IMUL`의 2·3-피연산자 형식은 곱을 목적지 크기로 잘라 버리므로 반드시 OF를 확인한다.
- `DIV`, `IDIV`는 두 배 크기의 피제수(AX, DX:AX, EDX:EAX)를 나누어 몫과 나머지를 낸다. 나누기 전에 피제수의 상위 절반을 준비해야 한다. 부호 없는 수는 0으로 채우고(`mov edx,0`), 부호 있는 수는 `CBW`·`CWD`·`CDQ`로 부호 확장한다.
- 0으로 나누거나 몫이 목적지에 들어가지 않으면 **나눗셈 오류 예외**(#DE)가 나서 프로그램이 멈춘다. 나눗셈 뒤의 상태 플래그는 모두 정의되지 않는다.
- `ADC`, `SBB`는 CF를 함께 더하고 빼서 자리올림·자리내림을 다음 워드로 넘긴다. 이것으로 길이에 제한이 없는 정수를 더하고 뺀다.
- `AAA`·`AAS`·`AAM`·`AAD`는 ASCII·언팩 10진수 연산을, `DAA`·`DAS`는 팩 10진수 연산을 보정한다. 모두 32비트 모드 전용이고 64비트 모드에서는 쓸 수 없다.

---

## 목차

| 구분 | 내용 |
|---|---|
| [들어가며](#들어가며-6장에서-7장으로) | 6장과의 연결, C 코드와 어셈블리의 대응 |
| [7.1 시프트와 회전 명령어](#71-시프트와-회전-명령어-shift-and-rotate-instructions) | 논리·산술 시프트, SHL, SHR, SAL, SAR, ROL, ROR, RCL, RCR, 부호 있는 오버플로, 플래그 규칙, SHLD, SHRD |
| [7.2 시프트와 회전의 응용](#72-시프트와-회전의-응용-shift-and-rotate-applications) | 여러 워드 시프트, 2진 곱셈, 2진 비트 출력, 파일 날짜 필드 추출, 비트 필드 다루기 |
| [7.3 곱셈과 나눗셈 명령어](#73-곱셈과-나눗셈-명령어-multiplication-and-division-instructions) | MUL, IMUL(1·2·3-피연산자), 실행 시간 측정, DIV, CBW·CWD·CDQ, IDIV, 나눗셈 오버플로, 산술식 구현 |
| [7.4 확장 덧셈과 뺄셈](#74-확장-덧셈과-뺄셈-extended-addition-and-subtraction) | ADC, 확장 덧셈 예제(ExtAdd), SBB, CF 활용 요령 |
| [7.5 ASCII와 언팩 10진수 산술](#75-ascii와-언팩-10진수-산술-ascii-and-unpacked-decimal-arithmetic) | 세 가지 10진수 표현, AAA, 여러 자리 ASCII 덧셈, AAS, AAM, AAD |
| [7.6 팩 10진수 산술](#76-팩-10진수-산술-packed-decimal-arithmetic) | DAA, AddPacked 예제, DAS, 팩 10진수의 쓰임 |
| [보충: 64비트 모드](#보충-64비트-모드에서-달라지는-점) | 64비트 곱셈·나눗셈, CQO, 시프트 횟수, 사라진 10진 보정 명령어 |
| [부록 A](#부록-a-명령어와-플래그-요약) | 명령어와 플래그 요약 |
| [부록 B](#부록-b-곱셈과-나눗셈을-다른-명령어로-하기) | 곱셈과 나눗셈을 다른 명령어로 하기 (시프트·뺄셈 나눗셈, 상수 나눗셈) |
| [부록 C](#부록-c-자주-하는-실수와-오류-메시지) | 자주 하는 실수와 오류 메시지 |
| [부록 D](#부록-d-핵심-용어-정리) | 핵심 용어 정리 |
| [부록 E](#부록-e-복습-문제) | 복습 문제 (단답형, 알고리즘 작성, 정답 접기) |
| [부록 F](#부록-f-프로그래밍-연습-풀이-포함) | 프로그래밍 연습 (풀이 포함) |
| [부록 G](#부록-g-슬라이드-정정-사항-모음) | 슬라이드 정정 사항 모음 |
| [참고 자료](#참고-자료) | 예제 값 확인 방법, 교재, 공식 문서 |

---

## 들어가며: 6장에서 7장으로

6장에서는 `AND`, `OR`, `XOR`, `TEST`로 비트를 고르고, `CMP`와 조건부 점프로 흐름을 나누는 방법을 배웠다. 7장은 그 비트들을 **움직이고**(시프트, 회전), 정수를 **곱하고 나누며**, CPU의 레지스터보다 **큰 수**와 **10진수**를 계산하는 방법을 다룬다.

| 하고 싶은 일 | 이 장에서 배우는 도구 | 절 |
|---|---|---|
| 비트를 왼쪽·오른쪽으로 민다 | `SHL`, `SHR`, `SAL`, `SAR` | 7.1 |
| 비트를 잃지 않고 돌린다 | `ROL`, `ROR`, `RCL`, `RCR` | 7.1 |
| 두 레지스터에 걸쳐 시프트한다 | `SHLD`, `SHRD` | 7.1 |
| 2의 거듭제곱으로 빠르게 곱하고 나눈다, 비트를 뽑아낸다 | 시프트 + `AND`·`OR` | 7.2 |
| 곱하고 나눈다 | `MUL`, `IMUL`, `DIV`, `IDIV`, `CBW`, `CWD`, `CDQ` | 7.3 |
| 32비트보다 큰 수를 더하고 뺀다 | `ADC`, `SBB` | 7.4 |
| 10진수(ASCII, BCD)로 계산한다 | `AAA`, `AAS`, `AAM`, `AAD`, `DAA`, `DAS` | 7.5, 7.6 |

C 코드 한 줄이 어셈블리에서 어떤 모습이 되는지 먼저 보면 이 장의 내용이 한눈에 들어온다. 32비트 변수 `a`는 EAX, `b`는 EBX에 있고, 64비트 변수 `x`는 EDX:EAX, `y`는 EBX:ECX에 있다고 가정했다.

| C 코드 | 어셈블리 | 관련 내용 |
|---|---|---|
| `a << 3` | `shl eax, 3` | SHL |
| `(unsigned)a >> 3` | `shr eax, 3` | SHR |
| `(int)a >> 3` | `sar eax, 3` | SAR (부호 비트를 복사한다) |
| `_rotl(a, 4)` | `rol eax, 4` | ROL |
| `(unsigned long long)a * b` | `mul ebx` → 곱은 EDX:EAX | MUL |
| `int c = a * b;` | `imul eax, ebx` | 2-피연산자 IMUL (곱의 하위 32비트만 남는다) |
| `int q = a / b, r = a % b;` | `cdq` 다음 `idiv ebx` → 몫 EAX, 나머지 EDX | CDQ, IDIV |
| `unsigned q = a / b;` | `mov edx, 0` 다음 `div ebx` | DIV |
| `long long s = x + y;` | `add eax, ecx` 다음 `adc edx, ebx` | ADC |
| `long long d = x - y;` | `sub eax, ecx` 다음 `sbb edx, ebx` | SBB |

> [!NOTE]
> 표에서 눈여겨볼 점이 두 가지 있다. 첫째, C에서 `/`와 `%`는 따로 쓰지만 x86에서는 **나눗셈 한 번으로 몫과 나머지가 함께** 나온다. 둘째, C의 `>>`는 피연산자가 부호 있는 정수이면 대부분의 컴파일러가 `SAR`로, 부호 없는 정수이면 `SHR`로 번역한다. 어셈블리에는 타입이 없으므로 이 선택을 프로그래머가 직접 해야 한다.

---

## 7.1 시프트와 회전 명령어 (Shift and Rotate Instructions)

### 명령어 한눈에 보기

시프트(shift)는 피연산자의 비트를 왼쪽이나 오른쪽으로 **미는** 연산이다. 한쪽 끝에서는 비트가 밀려 나가고 반대쪽 끝에는 빈자리가 생긴다. 무엇으로 빈자리를 채우고 밀려난 비트를 어디에 두느냐에 따라 명령어가 나뉜다(슬라이드의 Table 7-1).

| 명령어 | 이름 | 한 줄 설명 |
|---|---|---|
| `SHL` | Shift left | 왼쪽으로 밀고 빈자리를 0으로 채운다 |
| `SHR` | Shift right | 오른쪽으로 밀고 빈자리를 0으로 채운다 |
| `SAL` | Shift arithmetic left | `SHL`과 완전히 같다 |
| `SAR` | Shift arithmetic right | 오른쪽으로 밀고 빈자리를 **부호 비트**로 채운다 |
| `ROL` | Rotate left | 왼쪽으로 돌린다. 밀려난 최상위 비트가 최하위로 들어간다 |
| `ROR` | Rotate right | 오른쪽으로 돌린다. 밀려난 최하위 비트가 최상위로 들어간다 |
| `RCL` | Rotate carry left | CF를 포함해서 왼쪽으로 돌린다 |
| `RCR` | Rotate carry right | CF를 포함해서 오른쪽으로 돌린다 |
| `SHLD` | Double-precision shift left | 두 피연산자를 이어 붙인 것처럼 왼쪽으로 민다 |
| `SHRD` | Double-precision shift right | 두 피연산자를 이어 붙인 것처럼 오른쪽으로 민다 |

여덟 개의 기본 명령어가 비트를 어떻게 옮기는지 8비트 피연산자로 그려 보면 다음과 같다. `b7`이 최상위 비트(MSB), `b0`이 최하위 비트(LSB)다.

```text
SHL/SAL   CF ← [b7 b6 b5 b4 b3 b2 b1 b0] ← 0
SHR        0 → [b7 b6 b5 b4 b3 b2 b1 b0] → CF
SAR       b7 → [b7 b6 b5 b4 b3 b2 b1 b0] → CF     (b7은 제자리에도 남는다)

ROL       CF ← [b7 b6 b5 b4 b3 b2 b1 b0] ← b7     (밀려난 b7이 b0 자리로)
ROR       b0 → [b7 b6 b5 b4 b3 b2 b1 b0] → CF     (밀려난 b0이 b7 자리로)
RCL       CF ← [b7 b6 b5 b4 b3 b2 b1 b0] ← CF     (이전 CF가 b0 자리로)
RCR       CF → [b7 b6 b5 b4 b3 b2 b1 b0] → CF     (이전 CF가 b7 자리로)
```

| 명령어 | 빈자리에 들어가는 값 | 시프트·회전 뒤의 CF |
|---|---|---|
| `SHL`, `SAL` | 0 | 마지막으로 밀려난 최상위 비트 |
| `SHR` | 0 | 마지막으로 밀려난 최하위 비트 |
| `SAR` | 원래의 부호 비트 | 마지막으로 밀려난 최하위 비트 |
| `ROL` | 밀려난 최상위 비트 | 그 비트의 복사본 |
| `ROR` | 밀려난 최하위 비트 | 그 비트의 복사본 |
| `RCL` | 이전 CF | 밀려난 최상위 비트 |
| `RCR` | 이전 CF | 밀려난 최하위 비트 |

### 논리 시프트와 산술 시프트 (Logical Shifts and Arithmetic Shifts)

오른쪽으로 시프트할 때 빈자리를 채우는 방법은 두 가지다.

- **논리 시프트**(logical shift): 빈자리를 항상 **0**으로 채운다. 비트 패턴을 부호 없는 수로 본다.
- **산술 시프트**(arithmetic shift): 빈자리를 원래의 **부호 비트**로 채운다. 비트 패턴을 부호 있는 수로 보고, 시프트한 뒤에도 부호가 유지되게 한다.

슬라이드의 그림처럼 `11001111`을 오른쪽으로 1비트 밀어 보면 차이가 바로 보인다.

```text
논리 시프트 (SHR, 오른쪽 1비트)
  1 1 0 0 1 1 1 1 → CF
   \ \ \ \ \ \ \
  0 1 1 0 0 1 1 1    CF = 1   (빈자리에 0)

산술 시프트 (SAR, 오른쪽 1비트)
  1 1 0 0 1 1 1 1 → CF
  |\ \ \ \ \ \ \
  1 1 1 0 0 1 1 1    CF = 1   (빈자리에 원래의 부호 비트 1)
```

```asm
mov al,11001111b
shr al,1                ; AL = 01100111b, CF = 1    (논리 시프트)
mov al,11001111b
sar al,1                ; AL = 11100111b, CF = 1    (산술 시프트)
```

부호 있는 수로 읽으면 `11001111b`는 −49다. `SAR`의 결과 `11100111b`는 −25로 여전히 음수지만, `SHR`의 결과 `01100111b`는 +103이 되어 부호가 바뀌었다. 왼쪽 시프트에서는 두 방식의 차이가 없다. 빈자리는 언제나 최하위 비트 쪽에 생기고 그 자리는 0으로 채우면 되기 때문이다. 그래서 `SAL`은 `SHL`과 기계어까지 같은 명령어다.

### 시프트 횟수 지정하기 (보충)

모든 시프트·회전 명령어는 같은 형식을 쓴다. 첫 번째 피연산자가 목적지, 두 번째 피연산자가 **시프트 횟수**(count)다.

```text
SHL reg, imm8          SHL reg, CL
SHL mem, imm8          SHL mem, CL
```

- 횟수에는 **8비트 즉시값**이나 **CL 레지스터**만 쓸 수 있다. `shl eax, bl`이나 `shl eax, ecx`는 어셈블되지 않는다.
- 8086은 즉시값으로 1만 허용했다. 2 이상의 즉시값은 80186부터 쓸 수 있다. 교재가 `.386` 이상을 전제로 하므로 신경 쓰지 않아도 된다.
- CPU는 횟수의 **하위 5비트만** 쓴다(0~31, 80286부터). 그래서 횟수가 33이면 실제로는 1만큼 시프트한다. 피연산자가 8비트나 16비트여도 마찬가지로 5비트로 자른다.
- 횟수가 0이면 결과도 **플래그도 바뀌지 않는다**.

```asm
mov eax,1
mov cl,33               ; 횟수 33 = 100001b
shl eax,cl              ; EAX = 2    (하위 5비트 00001b, 즉 1만큼만 시프트)
stc                     ; CF를 1로 만들어 둔다
mov cl,0
shl eax,cl              ; EAX = 2, CF = 1    (횟수가 0이면 플래그도 그대로)
shl eax,bl              ; 어셈블 오류: 횟수는 CL이나 즉시값만 된다
```

> [!NOTE]
> 마지막 줄을 MASM으로 어셈블하면 "invalid instruction operands" 오류가 난다. 변수에 들어 있는 횟수만큼 시프트하려면 먼저 `mov cl, count`로 CL에 옮겨야 한다. CL이 시프트 횟수 전용으로 묶이므로, `LOOP` 때문에 ECX를 반복 횟수로 쓰는 중이라면 ECX를 스택에 저장했다가 꺼내야 한다. 뒤에 나오는 [SHRD 배열 예제](#예제-shrd로-배열-전체를-시프트하기)가 바로 그렇게 한다.

### SHL 명령어

`SHL`(shift left)은 목적지 피연산자를 왼쪽으로 논리 시프트하고 최하위 비트를 0으로 채운다. 밀려난 최상위 비트는 CF로 가고, 원래 CF에 있던 값은 버려진다.

```text
SHL destination, count

CF ← [b7 b6 b5 b4 b3 b2 b1 b0] ← 0

     1 1 0 0 1 1 1 1          (맨 왼쪽의 1은 CF로 나간다)
      / / / / / / /
     1 0 0 1 1 1 1 0 ← 0      CF = 1
```

슬라이드의 예제다.

```asm
mov bl,8Fh              ; BL = 10001111b
shl bl,1                ; CF = 1, BL = 00011110b
mov al,10000000b
shl al,2                ; CF = 0, AL = 00000000b
```

두 번째 예제에서 CF가 1이 아니라 0인 이유를 따져 보자. 2비트를 시프트하면 첫 번째 시프트에서 최상위 비트 1이 CF로 나가고, 두 번째 시프트에서 그다음 비트 0이 다시 CF로 나가면서 앞의 1을 덮어쓴다. **CF에는 마지막으로 밀려난 비트 하나만 남는다.**

#### 비트 단위 곱셈 (Bitwise Multiplication)

10진수를 왼쪽으로 한 자리 밀면 10배가 되듯이, 2진수를 왼쪽으로 n비트 밀면 **2ⁿ배**가 된다.

```text
mov dl,5     Before: 0 0 0 0 0 1 0 1  = 5
shl dl,1     After:  0 0 0 0 1 0 1 0  = 10
```

```asm
mov dl,5
shl dl,1                ; DL = 10      (5 × 2¹)
mov dl,10               ; DL = 00001010b
shl dl,2                ; DL = 00101000b (40 = 10 × 2²)
```

곱셈 명령어보다 간단하므로 2의 거듭제곱을 곱할 때는 시프트를 쓰는 경우가 많다. 다만 밀려난 비트 중에 1이 있으면 결과가 목적지에 다 들어가지 않은 것이다. 부호 없는 수라면 1비트 시프트 뒤 CF = 1이 그 신호다. 여러 비트를 한 번에 시프트하면 CF로는 마지막 비트만 알 수 있으므로, 넘침을 확인해야 한다면 곱셈 명령어([7.3](#73-곱셈과-나눗셈-명령어-multiplication-and-division-instructions))를 쓰는 편이 낫다.

### SHR 명령어

`SHR`(shift right)은 목적지 피연산자를 오른쪽으로 논리 시프트하고 최상위 비트를 0으로 채운다. 밀려난 최하위 비트는 CF로 간다.

```text
SHR destination, count

0 → [b7 b6 b5 b4 b3 b2 b1 b0] → CF
```

```asm
mov al,0D0h             ; AL = 11010000b
shr al,1                ; AL = 01101000b, CF = 0
mov al,00000010b
shr al,2                ; AL = 00000000b, CF = 1
```

두 번째 예제는 `SHL`의 경우와 반대다. 첫 번째 시프트에서 0, 두 번째 시프트에서 1이 CF로 나가므로 CF = 1이다.

#### 비트 단위 나눗셈 (Bitwise Division)

부호 없는 정수를 오른쪽으로 n비트 밀면 **2ⁿ으로 나눈 몫**이 된다.

```text
mov dl,32    Before: 0 0 1 0 0 0 0 0  = 32
shr dl,1     After:  0 0 0 1 0 0 0 0  = 16
```

```asm
mov dl,32
shr dl,1                ; DL = 16
mov al,01000000b        ; AL = 64
shr al,3                ; AL = 00001000b    (64 ÷ 8 = 8)
```

밀려 나간 비트가 바로 **나머지**다. 2ⁿ으로 나눈 나머지가 필요하면 시프트하기 전에 `AND`로 하위 n비트를 따로 떼어 두면 된다. 1비트만 시프트하면 나머지 비트가 CF로 나가므로 짝수·홀수 판별에도 쓸 수 있다.

```asm
mov eax,37
mov ebx,eax
and ebx,111b            ; EBX = 5    (37을 8로 나눈 나머지 = 하위 3비트)
shr eax,3               ; EAX = 4    (37을 8로 나눈 몫)
mov ecx,37
shr ecx,1               ; ECX = 18, CF = 1    (CF = 1이므로 37은 홀수)
```

### SAL과 SAR 명령어

`SAL`(shift arithmetic left)은 `SHL`과 똑같이 동작한다. 기계어도 같으므로 어느 쪽을 써도 된다. 부호 있는 수를 다루는 코드에서 의도를 드러내고 싶을 때 `SAL`이라고 쓴다.

`SAR`(shift arithmetic right)은 오른쪽으로 산술 시프트한다. 최상위 비트(부호 비트)는 제자리에 남으면서 오른쪽으로 복사되고, 밀려난 최하위 비트는 CF로 간다.

```text
SAR destination, count

   ┌──┐
   ↓  │
  [b7 b6 b5 b4 b3 b2 b1 b0] → CF
```

```asm
mov al,0F0h             ; AL = 11110000b (-16)
sar al,1                ; AL = 11111000b (-8), CF = 0
```

#### 부호 있는 나눗셈 (Signed Division)

`SAR`은 부호 있는 정수를 2ⁿ으로 나눈다.

```asm
mov dl,-128             ; DL = 10000000b
sar dl,3                ; DL = 11110000b (-16 = -128 ÷ 8)
```

#### AX를 EAX로 부호 확장하기 (Sign-Extend AX into EAX)

`SHL`과 `SAR`을 짝지으면 부호 확장을 할 수 있다. AX의 값을 EAX의 상위 16비트로 올려 보낸 뒤, 산술 시프트로 다시 내리면서 부호 비트를 채우는 방법이다.

```asm
mov ax,-128             ; EAX = ????FF80h    (상위 16비트는 알 수 없다)
shl eax,16              ; EAX = FF800000h
sar eax,16              ; EAX = FFFFFF80h
```

> [!TIP]
> 같은 일을 명령어 하나로 하는 방법도 있다. `movsx eax, ax`(4장)나 `cwde`(AX를 EAX로 부호 확장, [7.3](#부호-확장-명령어-cbw-cwd-cdq))를 쓰면 된다. 위의 두 줄짜리 방법은 시프트의 동작을 이해하는 예제로 보면 된다.

#### SAR와 IDIV는 음수를 다르게 반올림한다 (보충)

양수에서는 `SAR`과 나눗셈의 결과가 같지만 **음수 홀수**에서는 1만큼 차이가 난다. `SAR`은 버려지는 비트를 무시하므로 결과가 항상 **작은 쪽(−∞ 방향)으로 내림**되고, `IDIV`와 C 언어의 `/`는 **0 방향으로 버림**하기 때문이다.

```asm
mov al,-7               ; AL = 11111001b
sar al,1                ; AL = -4, CF = 1      (−3.5를 −∞ 방향으로 내림)
mov ax,-7
mov bl,2
idiv bl                 ; AL = -3, AH = -1     (−3.5를 0 방향으로 버림, 나머지 −1)
```

그래서 C 컴파일러는 부호 있는 정수를 2ⁿ으로 나눌 때 `SAR` 하나로 끝내지 않는다. 음수일 때만 2ⁿ − 1을 더한 다음 시프트해서 결과를 0 방향으로 맞춘다. 다음은 `x / 4`를 계산하는 전형적인 번역이다(`CDQ`는 [7.3](#부호-확장-명령어-cbw-cwd-cdq)에서 다룬다).

```asm
mov eax,-7
cdq                     ; EDX = FFFFFFFFh    (EAX가 음수이므로 모두 1)
and edx,3               ; EDX = 3            (음수일 때만 2² − 1, 양수면 0)
add eax,edx             ; EAX = -4
sar eax,2               ; EAX = -1           (C의 −7 / 4와 같다)
```

### ROL 명령어

회전(rotate)은 밀려난 비트를 버리지 않고 **반대쪽 끝으로 다시 넣는다**. 그래서 비트를 하나도 잃지 않는다(Bit rotation does not lose bits). `ROL`(rotate left)은 각 비트를 왼쪽으로 옮기고, 최상위 비트를 CF와 최하위 비트 자리에 **함께** 복사한다.

```text
ROL destination, count

      ┌──────────────────────────┐
      │                          │
CF ← [b7 b6 b5 b4 b3 b2 b1 b0] ←─┘
```

```asm
mov al,40h              ; AL = 01000000b
rol al,1                ; AL = 10000000b, CF = 0
rol al,1                ; AL = 00000001b, CF = 1
rol al,1                ; AL = 00000010b, CF = 0
```

#### 비트 묶음 맞바꾸기 (Exchanging Groups of Bits)

16비트 값을 4비트씩 네 번 회전하면 16진 자릿수가 한 칸씩 돌다가 원래 값으로 돌아온다.

```asm
mov ax,6A4Bh
rol ax,4                ; AX = A4B6h
rol ax,4                ; AX = 4B6Ah
rol ax,4                ; AX = B6A4h
rol ax,4                ; AX = 6A4Bh
```

같은 원리로 피연산자 크기의 **절반**만큼 회전하면 위아래 절반이 맞바뀐다. 8비트를 4비트 회전하면 니블(nibble, 4비트)이, 16비트를 8비트 회전하면 바이트가 맞바뀐다.

```asm
mov al,26h
rol al,4                ; AL = 62h      (상위·하위 니블 교환)
mov ax,1234h
rol ax,8                ; AX = 3412h    (xchg ah, al과 같은 결과)
mov eax,12345678h
bswap eax               ; EAX = 78563412h    (보충: 네 바이트의 순서를 뒤집는다)
```

> [!TIP]
> `BSWAP`(486 이상)은 32비트 레지스터의 바이트 순서를 거꾸로 뒤집는다. 리틀 엔디안 값과 빅 엔디안 값(네트워크 바이트 순서)을 바꿀 때 쓴다. `ROL`로는 바이트 두 개를 바꿀 수 있지만 네 바이트 전체를 뒤집지는 못한다.

### ROR 명령어

`ROR`(rotate right)은 각 비트를 오른쪽으로 옮기고, 최하위 비트를 CF와 최상위 비트 자리에 함께 복사한다.

```text
ROR destination, count

  ┌─────────────────────────┐
  ↓                         │
 [b7 b6 b5 b4 b3 b2 b1 b0] ─┴→ CF
```

```asm
mov al,01h              ; AL = 00000001b
ror al,1                ; AL = 10000000b, CF = 1
ror al,1                ; AL = 01000000b, CF = 0
mov al,00000100b
ror al,3                ; AL = 10000000b, CF = 1
```

마지막 예제는 `00000100b`를 세 번 회전하는 동안 1이 오른쪽 끝을 지나 최상위 비트로 넘어간 경우다. 세 번째 회전에서 넘어간 비트가 1이므로 CF = 1이다.

### RCL과 RCR 명령어

`RCL`(rotate carry left)과 `RCR`(rotate carry right)은 **CF를 피연산자의 한 비트처럼 끼워 넣고** 회전한다. 8비트 피연산자라면 CF까지 9비트를 한 바퀴로 돌리는 셈이다.

- `RCL`: 각 비트를 왼쪽으로 옮기고, 이전 CF를 최하위 비트에, 최상위 비트를 CF에 넣는다.
- `RCR`: 각 비트를 오른쪽으로 옮기고, 이전 CF를 최상위 비트에, 최하위 비트를 CF에 넣는다.

```text
RCL:
  ┌────────────────────────────────┐
  │                                │
  CF ← [b7 b6 b5 b4 b3 b2 b1 b0] ←─┘

RCR:
  ┌──────────────────────────────┐
  ↓                              │
 [b7 b6 b5 b4 b3 b2 b1 b0] → CF ─┘
```

```asm
clc                     ; CF = 0
mov bl,88h              ; CF = 0, BL = 10001000b
rcl bl,1                ; CF = 1, BL = 00010000b
rcl bl,1                ; CF = 0, BL = 00100001b
stc                     ; CF = 1
mov ah,10h              ; AH = 00010000b, CF = 1
rcr ah,1                ; AH = 10001000b, CF = 0
```

> [!NOTE]
> 슬라이드는 `CF,BL = 0 10001000b`, `AH, CF = 00010000 1`처럼 CF와 레지스터를 한데 붙여 적었다. CF가 RCL에서는 피연산자의 **왼쪽**, RCR에서는 **오른쪽**에 붙는 비트라는 점을 그림처럼 보여 주려는 표기다. 여기서는 확인하기 쉽게 따로 적었다.

#### CF에서 비트 되살리기 (보충)

`RCL`과 `RCR`은 **직전 시프트에서 CF로 내보낸 비트를 다시 넣을 수 있다**. 오른쪽으로 밀어서 최하위 비트를 검사해 본 다음, 조건이 맞지 않으면 `RCL`로 원래 값을 되살리는 예다.

```asm
.data
testval BYTE 01101010b
.code
shr testval,1           ; 최하위 비트를 CF로 내보낸다
jc  quit                ; 점프하지 않는다 (최하위 비트가 0이었다)
rcl testval,1           ; testval = 01101010b    (CF를 다시 넣어 원래 값으로)
quit:
```

또 하나 자주 쓰는 용도는 **여러 바이트에 걸친 시프트**다. 한 바이트에서 밀려난 비트를 CF에 잠깐 두었다가 다음 바이트로 넣어 주는 것이다. [7.2](#여러-더블워드-시프트하기-shifting-multiple-doublewords)에서 자세히 본다.

### 부호 있는 오버플로 (Signed Overflow)

부호 있는 정수를 **1비트** 시프트하거나 회전한 결과가 목적지의 부호 있는 범위를 벗어나면 OF가 1이 된다. 실제로는 **부호 비트가 바뀌었는지**로 판단한다.

```asm
mov al,+127             ; AL = 01111111b
rol al,1                ; OF = 1, AL = 11111110b    (+127이 −2가 되었다)
mov al,-128             ; AL = 10000000b
shr al,1                ; OF = 1, AL = 01000000b    (−128이 +64가 되었다)
```

**횟수가 1보다 크면 OF는 정의되지 않는다**(The value of the Overflow flag is undefined when the shift or rotation count is greater than 1). 여러 비트를 시프트하면서 부호 있는 넘침을 확인해야 한다면 1비트씩 나누어 시프트하거나, `IMUL`처럼 넘침을 정확히 알려 주는 명령어를 써야 한다.

인텔 문서가 정한 1비트 시프트·회전의 OF 규칙은 다음과 같다(보충). 모두 결국 "부호 비트가 바뀌었는가"를 계산하는 식이다.

| 명령어 | 횟수가 1일 때 OF | 예 (8비트) |
|---|---|---|
| `SHL`, `SAL` | 결과의 MSB XOR CF | `01000000b` → `10000000b`, CF = 0, OF = 1 |
| `SHR` | 원래 값의 MSB | `10000001b` → `01000000b`, OF = 1 |
| `SAR` | 항상 0 | 부호가 그대로 유지되므로 넘칠 수 없다 |
| `ROL` | 결과의 MSB XOR CF | `01000000b` → `10000000b`, CF = 0, OF = 1 |
| `ROR` | 결과의 위쪽 두 비트의 XOR | `00000001b` → `10000000b`, OF = 1 |
| `RCL` | 결과의 MSB XOR CF | CF = 0, `01000000b` → `10000000b`, CF = 0, OF = 1 |
| `RCR` | 원래 값의 MSB XOR 원래 CF | CF = 1, `00000000b` → `10000000b`, CF = 0, OF = 1 |

```asm
mov al,01000000b
shl al,1                ; AL = 10000000b, CF = 0, OF = 1
mov al,11000000b
shl al,1                ; AL = 10000000b, CF = 1, OF = 0    (−64 × 2 = −128, 범위 안)
mov al,10000001b
shr al,1                ; AL = 01000000b, CF = 1, OF = 1
mov al,10000001b
sar al,1                ; AL = 11000000b, CF = 1, OF = 0
mov al,00000001b
ror al,1                ; AL = 10000000b, CF = 1, OF = 1
stc
mov al,00000000b
rcr al,1                ; AL = 10000000b, CF = 0, OF = 1
```

### 시프트·회전 명령어의 플래그 정리 (보충)

슬라이드에는 흩어져 있는 플래그 규칙을 인텔 문서(SDM)를 기준으로 모아 보면 다음과 같다.

| 명령어 | CF | OF | SF, ZF, PF | AF |
|---|---|---|---|---|
| `SHL`, `SAL`, `SHR`, `SAR` | 마지막으로 밀려난 비트 | 횟수가 1일 때만 정의 | 결과에 따라 설정 | 정의되지 않음 |
| `ROL`, `ROR`, `RCL`, `RCR` | 마지막으로 밀려난 비트 | 횟수가 1일 때만 정의 | **바뀌지 않음** | **바뀌지 않음** |
| `SHLD`, `SHRD` | 마지막으로 밀려난 비트 | 횟수가 1일 때만 정의 | 결과에 따라 설정 | 정의되지 않음 |

- 횟수(하위 5비트로 자른 값)가 0이면 어떤 플래그도 바뀌지 않는다.
- `SHL`, `SHR`에서 횟수가 피연산자 크기 이상이면(예: 8비트 피연산자를 8 이상 시프트) CF는 정의되지 않는다.
- 회전 명령어는 결과가 0이어도 ZF를 바꾸지 않는다. 회전 결과로 분기하려면 `TEST`나 `CMP`로 플래그를 다시 만들어야 한다.

```asm
xor eax,eax             ; EAX = 0, ZF = 1
mov al,1                ; MOV는 플래그를 바꾸지 않는다
rol al,1                ; AL = 2, ZF = 1    (결과가 0이 아닌데도 ZF가 그대로다)
test al,al              ; ZF = 0            (이제야 결과에 맞는 ZF)
```

### SHLD와 SHRD 명령어

`SHLD`(shift left double)는 목적지 피연산자를 지정한 횟수만큼 왼쪽으로 민다. 이때 빈자리를 0이 아니라 **소스 피연산자의 상위 비트**로 채운다. 목적지와 소스를 하나로 이어 붙인 큰 값을 시프트한 뒤 왼쪽 절반만 남기는 것과 같다.

```text
SHLD dest, source, count

SHLD reg16, reg16, CL/imm8          SHLD reg32, reg32, CL/imm8
SHLD mem16, reg16, CL/imm8          SHLD mem32, reg32, CL/imm8
```

`SHRD`(shift right double)는 형식이 같고 방향만 반대다. 목적지를 오른쪽으로 밀고, 빈자리를 **소스 피연산자의 하위 비트**로 채운다.

```text
SHLD, 1비트 (슬라이드 그림)

      Destination              Source
 CF ← 1 1 1 0 0 0 0 0  ←──  1 0 0 1 1 1 0 1
 (1)  1 1 0 0 0 0 0 1 ← 소스의 최상위 비트 1이 들어왔다

SHRD, 1비트 (슬라이드 그림)

        Source                 Destination
  0 0 0 1 1 1 0 1  ──→  1 1 0 0 0 0 0 1 → CF (1)
                        1 1 1 0 0 0 0 0 ← 소스의 최하위 비트 1이 최상위로 들어왔다
```

슬라이드의 그림은 이해를 돕기 위해 8비트로 그렸지만, 실제 `SHLD`와 `SHRD`는 16비트나 32비트 피연산자만 받는다.

- 소스 피연산자는 **레지스터만** 된다. 목적지는 레지스터나 메모리다.
- **소스는 바뀌지 않는다.** 목적지와 플래그만 바뀐다.
- 횟수는 다른 시프트처럼 CL이나 8비트 즉시값이고, 하위 5비트만 쓴다. 16비트 피연산자에서 횟수가 16을 넘으면 결과가 정의되지 않는다.
- 플래그: SF, ZF, PF, CF가 결과에 따라 바뀌고, OF는 횟수가 1일 때만 정의된다. AF는 정의되지 않는다.

> [!WARNING]
> **슬라이드 정정**: SHLD 슬라이드에는 "Sign, Zero, **Auxiliary**, Parity, and Carry flags are affected"라고 되어 있다. 인텔 문서에 따르면 `SHLD`와 `SHRD` 뒤의 **AF는 정의되지 않는다**(undefined). 정의된 값으로 바뀌는 것은 SF, ZF, PF, CF이고, OF는 1비트 시프트일 때만 정의된다.

슬라이드의 두 예제를 보자.

```asm
.data
wval WORD 9BA6h
.code
mov  ax,0AC36h
shld wval,ax,4          ; wval = BA6Ah, CF = 1
mov  ax,234Bh
mov  dx,7654h
shrd ax,dx,4            ; AX = 4234h, CF = 1
```

```text
Example 1: SHLD wval, AX, 4

  wval    AX
  9BA6    AC36      wval의 9를 왼쪽으로 밀어내고
  BA6A    AC36      AX의 최상위 4비트(A)를 오른쪽 끝에 받았다

Example 2: SHRD AX, DX, 4

  DX      AX
  7654    234B      AX의 B를 오른쪽으로 밀어내고
  7654    4234      DX의 최하위 4비트(4)를 왼쪽 끝에 받았다
```

16진수 한 자리가 4비트이므로 4비트 시프트는 16진 자릿수 하나를 미는 것과 같다. 첫 번째 예제에서 `9BA6`의 9가 밀려 나가고 `AC36`의 맨 앞 자릿수 A가 오른쪽 끝에 들어왔다. 밀려난 9(`1001b`) 중 마지막으로 나간 비트가 1이므로 CF = 1이다. 두 번째 예제에서는 `234B`의 B(`1011b`)가 밀려 나가고 `7654`의 맨 끝 자릿수 4가 왼쪽 끝에 들어왔다.

> [!NOTE]
> 이 두 예제와 다음 배열 예제가 있는 슬라이드 세 장(16~18번)의 머리글은 "Conditional Control Flow Directives"로 되어 있다. 6장 슬라이드의 머리글이 잘못 남은 것으로, 내용상 7.1의 SHLD/SHRD 부분이다.

#### 64비트 값을 레지스터 두 개로 시프트하기 (보충)

`SHLD`의 대표적인 용도는 레지스터 두 개에 걸친 64비트 값을 시프트하는 것이다. EDX:EAX를 왼쪽으로 n비트 미는 코드는 두 줄이면 된다. 먼저 상위 절반(EDX)에 하위 절반(EAX)의 위쪽 비트를 받아 넣고, 그다음에 하위 절반을 민다. 순서를 바꾸면 EAX의 위쪽 비트가 이미 사라진 뒤라 안 된다.

```asm
mov  edx,00000001h
mov  eax,80000001h      ; EDX:EAX = 0000000180000001h
mov  cl,4
shld edx,eax,cl         ; EDX = 00000018h    (EAX의 상위 4비트 1000b가 들어왔다)
shl  eax,cl             ; EDX:EAX = 0000001800000010h
```

오른쪽으로 밀 때는 반대로 `shrd eax, edx, cl`로 하위 절반을 먼저 처리하고 `shr edx, cl`(부호 있는 수면 `sar edx, cl`)을 한다. 횟수는 0~31이어야 한다. 32 이상을 밀려면 레지스터를 통째로 옮기는 코드를 따로 써야 한다.

### 예제: SHRD로 배열 전체를 시프트하기

슬라이드는 다음 프로그램을 보여 주고 "Explain the program below."라고 묻는다. 이 프로그램은 다섯 개의 더블워드를 **하나의 160비트 정수**로 보고, 그 정수 전체를 오른쪽으로 4비트 시프트한다. 배열은 리틀 엔디안 순서다. 즉 `array[0]`이 가장 낮은 자리의 더블워드이고 `array[4]`가 가장 높은 자리의 더블워드다.

```asm
; SHRD로 다섯 더블워드(160비트 정수)를 오른쪽으로 4비트 시프트 (교재의 Shrd.asm)
INCLUDE Irvine32.inc

COUNT = 4                                   ; 시프트 횟수

.data
array DWORD 648B2165h,8C943A29h,6DFA4B86h,91F76C04h,8BAF9857h

.code
main PROC
    mov  bl,COUNT                           ; 시프트 횟수
    mov  esi,OFFSET array                   ; 배열의 시작 주소
    mov  ecx,(LENGTHOF array) - 1           ; ECX = 4    (원소 수 − 1 = 이웃한 쌍의 수)
L1: push ecx                                ; 반복 횟수를 저장한다 (CL을 써야 하므로)
    mov  eax,[esi + TYPE DWORD]             ; 한 칸 위의 원소
    mov  cl,bl                              ; 시프트 횟수
    shrd [esi],eax,cl                       ; EAX의 하위 4비트를 [esi]의 상위 4비트로 밀어 넣는다
    add  esi,TYPE DWORD                     ; 다음 원소 쌍을 가리킨다
    pop  ecx                                ; 반복 횟수를 복원한다
    loop L1
    shr  DWORD PTR [esi],COUNT              ; 맨 위 원소는 0을 채우며 시프트한다

    mov  esi,OFFSET array                   ; 결과를 16진수로 출력한다
    mov  ecx,LENGTHOF array
    mov  ebx,TYPE array
    call DumpMem
    exit
main ENDP
END main
```

실행 결과 (첫 줄의 주소는 실행 환경마다 다르므로 …로 줄였다):

```text
Dump of offset …
-------------------------------
9648B216  68C943A2  46DFA4B8  791F76C0  08BAF985
```

**동작 설명.** 배열을 하나의 큰 수로 쓰면 다음과 같다(높은 자리부터).

```text
시프트 전: 8BAF9857 91F76C04 6DFA4B86 8C943A29 648B2165
시프트 후: 08BAF985 791F76C0 46DFA4B8 68C943A2 9648B216
```

40자리 16진수 전체가 한 자리(4비트) 오른쪽으로 이동해서, 맨 앞에는 0이 들어오고 맨 끝의 5는 밀려 나갔다.

1. ESI는 `array[0]`부터 시작한다. 반복할 때마다 `[esi]`(아래 원소)와 `[esi+4]`(위 원소) 한 쌍을 다룬다.
2. `shrd [esi], eax, cl`은 아래 원소를 오른쪽으로 4비트 밀고, 비어 버린 상위 4비트를 **위 원소의 하위 4비트**로 채운다. 위 원소는 소스이므로 이 단계에서는 바뀌지 않는다. 예를 들어 첫 반복에서는 `648B2165h`가 `9648B216h`가 된다(`8C943A29h`의 맨 끝 자릿수 9가 들어왔다).
3. 아래에서 위로 진행하므로 각 원소는 **아직 시프트되지 않은** 위 원소의 비트를 받는다. 위에서 아래로 진행하면 이미 시프트된 값을 받게 되어 틀린다.
4. 원소가 다섯 개이므로 쌍은 네 개다. 그래서 ECX는 `LENGTHOF array − 1`이다.
5. `SHRD`의 횟수로 CL을 써야 해서 ECX가 반복 횟수와 충돌한다. 그래서 `push ecx`/`pop ecx`로 반복 횟수를 지킨다. 횟수가 상수라면 `shrd [esi], eax, COUNT`처럼 즉시값을 써서 push/pop을 없앨 수도 있다.
6. 마지막 원소에는 위에서 받을 비트가 없으므로 `SHR`로 0을 채운다.

> [!WARNING]
> **슬라이드 정정** (Explain the program below 슬라이드)
> - 마지막 줄의 `shr DWORD PTR [esi],COUNT`에 쓰인 `COUNT`가 슬라이드 코드 어디에도 정의되어 있지 않아 그대로는 어셈블되지 않는다. 교재의 원본 프로그램(Shrd.asm)처럼 `COUNT = 4`를 정의하고, 첫 줄도 `mov bl, COUNT`로 맞추는 것이 좋다.
> - `mov ecx,(LENGTHOF array) – 1`의 빼기 기호가 인쇄용 대시(`–`)로 찍혀 있다. 코드로 옮겨 칠 때는 하이픈(`-`)을 써야 어셈블러가 빼기로 인식한다.
> - 같은 줄의 주석 "number of array elements"는 정확히는 "원소 수 − 1(이웃한 원소 쌍의 수)"이다.

---

## 7.2 시프트와 회전의 응용 (Shift and Rotate Applications)

### 여러 더블워드 시프트하기 (Shifting Multiple Doublewords)

레지스터 하나에 들어가지 않는 큰 수는 메모리에 여러 개의 바이트나 더블워드로 나누어 저장한다. 이런 수 전체를 1비트 시프트하려면 한 원소에서 밀려난 비트를 **CF에 잠깐 맡겼다가** 다음 원소로 넣어 주면 된다. 이때 쓰는 것이 `RCR`과 `RCL`이다.

슬라이드는 세 바이트로 된 배열을 오른쪽으로 1비트 시프트한다. 배열은 리틀 엔디안이므로 `[esi+2]`가 가장 높은 자리의 바이트다. 오른쪽 시프트는 **가장 높은 자리부터** 시작한다.

```asm
.data
ArraySize = 3
array BYTE ArraySize DUP(99h)       ; 각 니블이 1001 패턴
.code
mov esi,0
shr array[esi+2],1                  ; CF = 1    (최상위 바이트: 빈자리에 0)
rcr array[esi+1],1                  ; CF = 1    (가운데 바이트: CF가 최상위 비트로)
rcr array[esi],1                    ; CF = 1    (최하위 바이트: CF가 최상위 비트로)
```

| 단계 | 명령어 | `[esi+2]` | `[esi+1]` | `[esi]` | CF |
|---|---|---|---|---|---|
| 시작 | | `10011001` | `10011001` | `10011001` | |
| 1 | `shr [esi+2]` | `01001100` | `10011001` | `10011001` | 1 |
| 2 | `rcr [esi+1]` | `01001100` | `11001100` | `10011001` | 1 |
| 3 | `rcr [esi]` | `01001100` | `11001100` | `11001100` | 1 |

1단계에서 최상위 바이트의 최하위 비트(1)가 CF로 나간다. 2단계의 `RCR`은 그 CF를 가운데 바이트의 최상위 비트로 넣고, 가운데 바이트의 최하위 비트(1)를 다시 CF로 내보낸다. 3단계도 같다. 3단계가 끝나면 24비트 전체가 오른쪽으로 1비트 밀려 있다(After Step 3 is complete, all bits have been shifted 1 position to the right). 마지막 CF에는 24비트 수 전체에서 밀려난 비트가 남는다.

교재의 MultiShift 프로그램은 시프트 앞뒤의 배열을 2진수로 출력한다.

```asm
; 여러 바이트에 걸친 시프트 (교재의 MultiShift.asm)
INCLUDE Irvine32.inc

.data
ArraySize = 3
array BYTE ArraySize DUP(99h)               ; 1001 패턴

.code
main PROC
    call DisplayArray                       ; 시프트 전
    mov  esi,0
    shr  array[esi+2],1                     ; 최상위 바이트
    rcr  array[esi+1],1                     ; 가운데 바이트, CF 포함
    rcr  array[esi],1                       ; 최하위 바이트, CF 포함
    call DisplayArray                       ; 시프트 후
    exit
main ENDP

;----------------------------------------------------
DisplayArray PROC
; 배열을 높은 자리 바이트부터 2진수로 출력한다.
;----------------------------------------------------
    pushad
    mov  ecx,ArraySize
    mov  esi,ArraySize-1
L1: mov  al,array[esi]
    mov  ebx,1                              ; 크기 = 바이트
    call WriteBinB                          ; 2진수로 출력
    mov  al,' '
    call WriteChar
    sub  esi,1
    loop L1
    call Crlf
    popad
    ret
DisplayArray ENDP
END main
```

실행 결과:

```text
1001 1001 1001 1001 1001 1001
0100 1100 1100 1100 1100 1100
```

> [!NOTE]
> 슬라이드 제목은 "Shifting Multiple Doublewords"지만 예제는 바이트 배열이다. 원리는 원소 크기와 상관없이 같다. 더블워드 배열이라면 `shr array[esi+8],1` → `rcr array[esi+4],1` → `rcr array[esi],1`처럼 원소 크기만큼 오프셋을 바꾸면 된다(배열을 DWORD로 선언하면 MASM이 크기를 알아서 정한다).

**왼쪽 시프트는 방향을 뒤집는다.** 가장 낮은 자리부터 `SHL`로 시작하고, 위쪽 원소들은 `RCL`로 처리한다. 밀려난 최상위 비트가 다음(높은 자리) 원소의 최하위 비트로 들어가야 하기 때문이다.

#### 원소가 많을 때: 루프로 일반화하기 (보충)

원소가 많으면 `RCR`을 루프로 돌린다. 이때 **반복 사이에 CF가 바뀌지 않게** 하는 것이 핵심이다. `ADD`나 `SUB`로 포인터를 옮기면 CF가 덮어써진다. 플래그를 건드리지 않는 `LEA`나 CF를 바꾸지 않는 `DEC`, 그리고 `LOOP`를 쓰면 된다.

```asm
.data
array DWORD 00000003h,00000001h,80000000h,00000001h    ; [0]이 가장 낮은 자리
.code
    mov  esi,OFFSET array + (LENGTHOF array - 1) * TYPE array    ; 최상위 원소
    mov  ecx,LENGTHOF array
    clc                                 ; 맨 위로 들어갈 비트 = 0
L1: rcr  DWORD PTR [esi],1              ; CF → 최상위 비트, 최하위 비트 → CF
    lea  esi,[esi - TYPE array]         ; LEA는 플래그를 바꾸지 않는다 (SUB는 CF를 바꾼다)
    loop L1                             ; 끝나면 array = 00000000C00000000000000080000001h, CF = 1
```

배열을 높은 자리부터 이어 쓰면 `00000001 80000000 00000001 00000003`이고, 1비트 시프트한 결과는 `00000000 C0000000 00000000 80000001`이다. 루프가 끝났을 때 CF에는 원래 수의 최하위 비트(1)가 남는다.

### 2진 곱셈 (Binary Multiplication)

시프트는 2의 거듭제곱만 곱할 수 있지만, 어떤 수든 **2의 거듭제곱의 합**으로 나타낼 수 있으므로 시프트와 덧셈을 조합하면 임의의 상수를 곱할 수 있다. 36은 2⁵ + 2²이므로 다음과 같다.

```text
EAX * 36 = EAX * (2⁵ + 2²)
         = EAX * (32 + 4)
         = (EAX * 32) + (EAX * 4)
```

123 × 36을 2진수 곱셈으로 쓰면, 곱하는 수 36(`00100100b`)의 1인 비트(2번, 5번)마다 123을 그만큼 시프트한 값을 더하는 모양이 된다. 손으로 하는 10진수 곱셈과 같은 원리다.

```text
            0 1 1 1 1 0 1 1      123
      ×     0 0 1 0 0 1 0 0       36
      ─────────────────────
          0 1 1 1 1 0 1 1        123 SHL 2   (비트 2)
  +   0 1 1 1 1 0 1 1            123 SHL 5   (비트 5)
  ─────────────────────────
  0 0 0 1 0 0 0 1 0 1 0 0 1 1 0 0   4428
```

```asm
mov eax,123
mov ebx,eax
shl eax,5               ; EAX = 3936    (123 × 2⁵)
shl ebx,2               ; EBX = 492     (123 × 2²)
add eax,ebx             ; EAX = 4428    (= 0000114Ch)
```

#### 시프트-덧셈 곱셈의 일반형 (보충)

곱하는 수가 상수가 아니라 변수라면, 곱하는 수의 비트를 하나씩 검사하면서 1인 비트에서만 시프트한 피승수를 더하면 된다. 이것이 **시프트-덧셈 곱셈**(shift-and-add multiplication)이고, 곱셈 회로가 없던 초기 CPU가 곱셈을 하던 방법이다.

```text
product = 0
while multiplier ≠ 0:
    multiplier를 오른쪽으로 1비트 시프트 (밀려난 비트 → CF)
    CF = 1이면 product += multiplicand
    multiplicand를 왼쪽으로 1비트 시프트
```

[부록 F의 연습 1](#연습-1-비트-단위-곱셈)에서 이 알고리즘을 프로시저로 직접 만들어 본다.

#### LEA로 곱하기 (보충)

컴파일러는 작은 상수를 곱할 때 시프트보다 `LEA`(load effective address)를 즐겨 쓴다. `LEA`는 주소 계산식 `[base + index*scale]`의 **값 자체**를 레지스터에 넣는 명령어인데, scale에 2, 4, 8을 쓸 수 있으므로 한 명령어로 ×3, ×5, ×9를 계산할 수 있다. 플래그도 바꾸지 않는다.

```asm
mov eax,123
lea eax,[eax+eax*8]     ; EAX = 1107    (123 × 9)
shl eax,2               ; EAX = 4428    (× 4 = 123 × 36)
mov ecx,7
lea ecx,[ecx+ecx*4]     ; ECX = 35      (7 × 5)
add ecx,ecx             ; ECX = 70      (× 2 = 7 × 10)
```

### 2진 비트 출력하기 (Displaying Binary Bits)

정수를 화면에 2진수로 보여 주려면 각 비트를 문자 `'0'`이나 `'1'`로 바꾼 ASCII 문자열이 필요하다(A common programming task is converting a binary integer to an ASCII binary string). `SHL`로 최상위 비트를 CF로 밀어낸 다음 CF를 보고 문자를 고르는 일을 32번 반복하면 된다.

```asm
; 32비트 정수를 2진 ASCII 문자열로 바꾸기 (교재의 BinToAsc.asm)
INCLUDE Irvine32.inc

.data
binVal  DWORD 1234ABCDh                 ; 바꿀 값
buffer  BYTE  32 DUP(0),0               ; 32자리 + 끝을 나타내는 0

.code
main PROC
    mov  eax,binVal                     ; EAX = 바꿀 정수
    mov  esi,OFFSET buffer              ; ESI = 버퍼 주소
    call BinToAsc
    mov  edx,OFFSET buffer
    call WriteString
    call Crlf
    exit
main ENDP

;--------------------------------------------------------
BinToAsc PROC
;
; Converts 32-bit binary integer to ASCII binary.
; Receives: EAX = binary integer, ESI points to buffer
; Returns: buffer filled with ASCII binary digits
;--------------------------------------------------------
    push ecx
    push esi
    mov  ecx,32                         ; EAX의 비트 수
L1: shl  eax,1                          ; 최상위 비트를 CF로 밀어낸다
    mov  BYTE PTR [esi],'0'             ; 일단 '0'을 넣는다
    jnc  L2                             ; CF = 0이면 그대로 둔다
    mov  BYTE PTR [esi],'1'             ; CF = 1이면 '1'로 바꾼다
L2: inc  esi                            ; 버퍼의 다음 칸
    loop L1                             ; 다음 비트
    pop  esi
    pop  ecx
    ret
BinToAsc ENDP
END main
```

실행 결과:

```text
00010010001101001010101111001101
```

`MOV`는 플래그를 바꾸지 않으므로 `shl`과 `jnc` 사이에 `mov BYTE PTR [esi],'0'`이 끼어 있어도 CF는 그대로 남아 있다. 이 점을 이용해 "기본값을 먼저 쓰고 필요할 때만 고치는" 짧은 코드가 되었다. 프로시저가 끝나면 EAX는 32번 시프트되어 0이 되어 있다. 원래 값이 필요하면 호출하는 쪽에서 보관해야 한다.

Irvine32 라이브러리의 `WriteBin`도 같은 방식으로 출력하되, 읽기 쉽게 4비트마다 공백을 넣는다.

```asm
mov  eax,1234ABCDh
call WriteBin
call Crlf
```

실행 결과:

```text
0001 0010 0011 0100 1010 1011 1100 1101
```

#### 같은 원리로 16진수 출력하기 (보충)

16진수 한 자리는 4비트다. `ROL`로 최상위 4비트를 최하위로 돌려 내린 다음 `AND 0Fh`로 떼어 내고, 그 값으로 문자표를 찾으면 된다. `ROL`은 비트를 잃지 않으므로 여덟 번 돌고 나면 EAX가 원래 값으로 돌아온다는 점도 `SHL` 방식과 다르다.

```asm
; ROL로 32비트 값을 16진수 문자열로 바꾸기
INCLUDE Irvine32.inc

.data
hexDigits BYTE "0123456789ABCDEF"
buffer    BYTE 8 DUP(0),0

.code
main PROC
    mov  eax,1234ABCDh
    mov  esi,OFFSET buffer
    mov  ecx,8                          ; 16진수 여덟 자리
L1: rol  eax,4                          ; 최상위 4비트를 최하위로 돌려 내린다
    mov  ebx,eax
    and  ebx,0Fh                        ; 그 4비트만 남긴다
    mov  bl,hexDigits[ebx]              ; 문자표에서 찾는다
    mov  [esi],bl
    inc  esi
    loop L1                             ; 끝나면 EAX = 1234ABCDh  (원래 값 그대로)
    mov  edx,OFFSET buffer
    call WriteString
    call Crlf
    exit
main ENDP
END main
```

실행 결과:

```text
1234ABCD
```

### 파일 날짜 필드 추출하기 (Extracting File Date Fields)

저장 공간을 아끼려고 여러 값을 한 정수의 비트 묶음(**비트 필드**, bit field)에 나누어 담는 경우가 많다. 대표적인 예가 MS-DOS 시절부터 쓰인 파일 날짜 형식이다. 16비트 하나에 연도·월·일이 들어 있다.

| 필드 | 비트 | 비트 수 | 값의 범위 |
|---|---|---|---|
| 연도 | 9~15 | 7 | 0~127 (1980년부터 센 연도, 1980~2107년) |
| 월 | 5~8 | 4 | 1~12 |
| 일 | 0~4 | 5 | 1~31 |

1999년 3월 10일에 마지막으로 고친 파일이라면 날짜 값은 DX에 다음처럼 들어 있다(연도는 1980년 기준이므로 1999 − 1980 = 19).

```text
bit    15 14 13 12 11 10  9  8  7  6  5  4  3  2  1  0
DX      0  0  1  0  0  1  1  0  0  1  1  0  1  0  1  0    = 266Ah
      [------ year -------][- month --][---- day ----]
          0010011 = 19       0011 = 3    01010 = 10
      [--------- DH ---------][--------- DL ---------]
```

각 필드를 꺼내는 방법은 같다. **필요한 비트를 최하위로 시프트하고, 나머지 비트를 `AND`로 지운다.**

```asm
.data
day   BYTE ?
month BYTE ?
year  WORD ?
.code
mov  dx,266Ah                       ; 1999년 3월 10일
mov  al,dl                          ; DL을 복사한다
and  al,00011111b                   ; 비트 5~7을 지운다
mov  day,al                         ; day = 10
mov  ax,dx                          ; DX를 복사한다
shr  ax,5                           ; 오른쪽으로 5비트 시프트
and  al,00001111b                   ; 비트 4~7을 지운다
mov  month,al                       ; month = 3
mov  al,dh                          ; DH를 복사한다
shr  al,1                           ; 오른쪽으로 1비트 시프트
mov  ah,0                           ; AH를 0으로
add  ax,1980                        ; 연도는 1980년 기준
mov  year,ax                        ; year = 1999
```

- **일**은 이미 최하위에 있으므로 시프트 없이 `AND`만 하면 된다.
- **월**은 DL과 DH에 걸쳐 있다(비트 5~8). 그래서 DX 전체를 AX로 복사한 다음 5비트 시프트한다.
- **연도**는 DH의 상위 7비트이므로 DH만 1비트 시프트하면 된다. 시프트 뒤 AL의 최상위 비트는 0이므로 따로 `AND`할 필요가 없다. 여기에 1980을 더하려면 16비트 덧셈이 필요하므로 AH를 0으로 만든다.

#### 거꾸로: 필드를 모아 날짜 값 만들기 (보충)

꺼내는 것의 반대는 **시프트해서 제자리에 보낸 뒤 `OR`로 합치는** 것이다.

```asm
mov  ax,1999
sub  ax,1980                        ; AX = 19
shl  ax,9                           ; 연도를 비트 9~15로
mov  bx,3
shl  bx,5                           ; 월을 비트 5~8로
or   ax,bx
or   ax,10                          ; AX = 266Ah    (일은 비트 0~4 그대로)
```

파일 시간도 같은 방식이다. 시(비트 11~15), 분(비트 5~10), 초÷2(비트 0~4)가 16비트에 들어간다. 초를 2로 나누어 저장하므로 시간 해상도는 2초다. [부록 F의 연습 3](#연습-3-파일-시간-표시하기)에서 이 형식을 다룬다.

### 비트 필드 다루기의 일반 패턴 (보충)

위치가 `pos`이고 폭이 `w`비트인 필드를 다루는 방법은 두 가지로 정리된다. `mask`는 하위 `w`비트가 1인 값(2ʷ − 1)이다.

| 작업 | 식 | 어셈블리 |
|---|---|---|
| 꺼내기 | `(x >> pos) AND mask` | `SHR`으로 내린 뒤 `AND` |
| 넣기 | `(x AND NOT (mask << pos)) OR (v << pos)` | 자리를 `AND`로 비운 뒤, 시프트한 새 값을 `OR` |

넣기의 예로, 날짜 값 `266Ah`(1999년 3월 10일)의 월만 12로 바꿔 보자. 월 필드는 `pos` = 5, `w` = 4이므로 지울 자리의 마스크는 `0000000111100000b` = `01E0h`이다.

```asm
mov  dx,266Ah                       ; 1999년 3월 10일
and  dx,NOT 01E0h                   ; DX = 260Ah    (월 필드를 0으로 비운다)
mov  ax,12
shl  ax,5                           ; AX = 0180h    (12를 월 자리로)
or   dx,ax                          ; DX = 278Ah    (1999년 12월 10일)
```

`NOT 01E0h`는 CPU 명령어가 아니라 MASM이 어셈블할 때 계산하는 **상수식**이다(결과는 `0FE1Fh`). 마스크를 직접 계산해서 적는 것보다 실수가 적다.

---

## 7.3 곱셈과 나눗셈 명령어 (Multiplication and Division Instructions)

x86의 정수 곱셈·나눗셈 명령어는 네 개다. 부호 없는 수를 위한 `MUL`, `DIV`와 부호 있는 수를 위한 `IMUL`, `IDIV`다. 덧셈·뺄셈과 달리 곱셈과 나눗셈은 **부호 있는 수와 부호 없는 수의 결과 비트가 다르므로** 명령어가 따로 있다.

### MUL 명령어

`MUL`(unsigned multiply)은 부호 없는 정수를 곱한다. 피연산자를 **하나만** 적는데, 그것이 곱하는 수(multiplier)다. 곱해지는 수(multiplicand)는 피연산자 크기에 맞는 누산기(AL, AX, EAX)로 정해져 있고, 곱은 **두 배 크기**의 자리에 들어간다(The multiplier and multiplicand must always be the same size, and the product is twice their size).

```text
MUL reg/mem8
MUL reg/mem16
MUL reg/mem32
```

| 곱해지는 수 (Multiplicand) | 곱하는 수 (Multiplier) | 곱 (Product) |
|---|---|---|
| AL | reg/mem8 | AX |
| AX | reg/mem16 | DX:AX |
| EAX | reg/mem32 | EDX:EAX |

`DX:AX`는 DX가 상위 16비트, AX가 하위 16비트인 32비트 값이라는 뜻이다. n비트 수 두 개의 곱은 최대 (2ⁿ − 1)²이고 이 값은 2²ⁿ보다 작으므로, 곱을 두 배 크기에 담으면 **절대 넘치지 않는다**.

- 피연산자로 **즉시값은 쓸 수 없다.** `mul 10`은 어셈블되지 않으므로 상수를 곱하려면 먼저 레지스터에 넣어야 한다.
- 곱의 상위 절반(AH, DX, EDX)이 0이 아니면 CF = OF = 1, 0이면 CF = OF = 0이 된다. SF, ZF, AF, PF는 정의되지 않는다.
- 그래서 `MUL` 뒤에 CF를 보면 **곱의 상위 절반을 무시해도 되는지** 알 수 있다(A good reason for checking the Carry flag after executing MUL is to know whether the upper half of the product can safely be ignored).

```asm
mov al,5h
mov bl,10h
mul bl                  ; AX = 0050h, CF = 0
```

```text
  AL      BL         AX     CF
  05  ×   10   →    0050    0      (상위 바이트 AH가 0이다)
```

```asm
.data
val1 WORD 2000h
val2 WORD 0100h
.code
mov ax,val1             ; AX = 2000h
mul val2                ; DX:AX = 00200000h, CF = 1
```

```text
  AX       val2        DX   AX      CF
 2000  ×  0100   →   0020 0000      1      (상위 워드 DX가 0이 아니다)
```

> [!NOTE]
> **슬라이드 정정**: 위 예제의 그림에서 곱하는 수의 이름이 `BX`로 적혀 있지만, 코드에서 곱하는 수는 메모리 변수 `val2`다. BX는 쓰이지도 바뀌지도 않는다.

```asm
mov eax,12345h
mov ebx,1000h
mul ebx                 ; EDX:EAX = 0000000012345000h, CF = 0
```

```text
   EAX         EBX            EDX       EAX      CF
 00012345 × 00001000  →  00000000  12345000    0
```

곱이 작아도 `MUL`은 **상위 절반 레지스터를 항상 덮어쓴다**. 16비트 `MUL`은 DX를, 32비트 `MUL`은 EDX를 바꾸므로 그 레지스터에 다른 값을 두고 있었다면 미리 저장해야 한다.

```asm
mov edx,12345678h
mov ax,2
mov bx,3
mul bx                  ; AX = 6, DX = 0, EDX = 12340000h    (DX만 0으로 덮였다)
mul 10                  ; 어셈블 오류: MUL은 즉시값 피연산자를 받지 않는다
```

### IMUL 명령어

`IMUL`(signed multiply)은 부호 있는 정수를 곱한다. 형식이 세 가지다.

#### 1-피연산자 형식 (Single-Operand Formats)

`MUL`과 똑같이 AL, AX, EAX에 피연산자를 곱해 AX, DX:AX, EDX:EAX에 저장한다(The one-operand formats store the product in AX, DX:AX, or EDX:EAX).

```text
IMUL reg/mem8           ; AX = AL * reg/mem8
IMUL reg/mem16          ; DX:AX = AX * reg/mem16
IMUL reg/mem32          ; EDX:EAX = EAX * reg/mem32
```

곱이 두 배 크기에 담기므로 역시 넘치지 않는다. 다만 플래그의 의미가 `MUL`과 다르다. **상위 절반이 하위 절반의 부호 확장이 아니면** CF = OF = 1이다. 다시 말해 곱을 하위 절반만으로는 부호 있는 수로 나타낼 수 없을 때 1이 된다.

```asm
mov  al,48
mov  bl,4
imul bl                 ; AX = 00C0h, OF = 1
mov  al,-4
mov  bl,4
imul bl                 ; AX = FFF0h, OF = 0
```

첫 번째 곱 192(`00C0h`)는 부호 있는 8비트 범위(−128~+127)를 넘으므로 AH가 AL의 부호 확장이 아니다(AL = `C0h`의 최상위 비트는 1인데 AH는 `00h`). 그래서 OF = 1이다. 두 번째 곱 −16(`FFF0h`)은 AL = `F0h`만으로도 −16이고 AH = `FFh`는 그 부호 확장이므로 OF = 0이다.

```asm
mov  ax,48
mov  bx,4
imul bx                 ; DX:AX = 000000C0h, OF = 0
mov  eax,+4823424
mov  ebx,-423
imul ebx                ; EDX:EAX = FFFFFFFF86635D80h, OF = 0
```

4,823,424 × (−423) = −2,040,308,352은 부호 있는 32비트 범위(약 ±21억) 안에 들어가므로 EDX는 EAX의 부호 확장(`FFFFFFFFh`)이고 OF = 0이다.

#### 2-피연산자 형식 (Two-Operand Formats, 32-Bit Mode)

```text
IMUL reg16, reg/mem16           IMUL reg32, reg/mem32
IMUL reg16, imm8                IMUL reg32, imm8
IMUL reg16, imm16               IMUL reg32, imm32
```

첫 번째 피연산자(레지스터)에 두 번째 피연산자를 곱해 **첫 번째 피연산자에** 저장한다. C의 `a *= b`와 같은 모양이다. 곱이 두 배 크기로 늘어나지 않고 **목적지 크기로 잘린다**(The two-operand formats truncate the product to the length of the destination). 잘려 나간 부분에 의미 있는 자릿수가 있었으면 OF와 CF가 1이 되므로, 2-피연산자 형식을 쓴 뒤에는 둘 중 하나를 꼭 확인해야 한다.

```asm
.data
word1  SWORD  4
dword1 SDWORD 4
.code
mov  ax,-16             ; AX = -16
mov  bx,2               ; BX = 2
imul bx,ax              ; BX = -32
imul bx,2               ; BX = -64
imul bx,word1           ; BX = -256
mov  eax,-16            ; EAX = -16
mov  ebx,2              ; EBX = 2
imul ebx,eax            ; EBX = -32
imul ebx,2              ; EBX = -64
imul ebx,dword1         ; EBX = -256
```

#### 3-피연산자 형식 (Three-Operand Formats)

```text
IMUL reg16, reg/mem16, imm8     IMUL reg32, reg/mem32, imm8
IMUL reg16, reg/mem16, imm16    IMUL reg32, reg/mem32, imm32
```

두 번째 피연산자(레지스터나 메모리)에 세 번째 피연산자(즉시값)를 곱해 첫 번째 피연산자(레지스터)에 저장한다. 원래 값을 보존하면서 곱을 다른 레지스터에 받을 수 있다. 2-피연산자 형식처럼 곱이 잘리므로 OF를 확인해야 한다(If significant digits are lost when IMUL executes, the Overflow and Carry flags are set).

```asm
.data
word1  SWORD  4
dword1 SDWORD 4
.code
mov  ax,-32000
imul ax,2                       ; AX = 0600h, OF = 1, CF = 1    (−64000은 16비트에 들어가지 않는다)
imul bx,word1,-16               ; BX = -64       (word1 × −16)
imul ebx,dword1,-16             ; EBX = -64      (dword1 × −16)
imul ebx,dword1,-2000000000     ; EBX = 2329B000h, OF = 1, CF = 1    (부호 있는 오버플로)
```

마지막 줄의 참값은 4 × (−2,000,000,000) = −8,000,000,000인데, 하위 32비트만 남은 EBX는 +589,934,592(`2329B000h`)로 부호까지 틀렸다. 2·3-피연산자 형식은 목적지 크기가 곱하는 수의 크기와 같으므로 이런 부호 있는 오버플로가 얼마든지 생긴다. 이 형식을 쓴 뒤에는 **반드시 OF를 확인하자**(Always check the Overflow flag after executing these types of IMUL instructions).

> [!TIP]
> `mov ax,-32000` 다음의 `imul ax,2`는 슬라이드에서 3-피연산자 예제와 함께 나오지만 사실은 2-피연산자 형식(`IMUL reg16, imm8`)이다. 어셈블러는 `imul ax, ax, 2`와 같은 기계어로 만든다.

#### MUL과 IMUL은 무엇이 다른가 (보충)

같은 비트 패턴이라도 부호 없는 수로 보느냐 부호 있는 수로 보느냐에 따라 곱의 **상위 절반**이 달라진다. `FFh`는 부호 없는 수로 255, 부호 있는 수로 −1이다.

```asm
mov  al,0FFh
mov  bl,0FFh
mul  bl                 ; AX = FE01h, CF = 1    (255 × 255 = 65025)
mov  al,0FFh
imul bl                 ; AX = 0001h, CF = 0    ((−1) × (−1) = 1)
```

두 결과의 **하위 바이트는 똑같이 `01h`다.** 곱의 하위 절반은 부호와 상관없이 항상 같다. 그래서 곱을 목적지 크기로 자르는 2·3-피연산자 형식에는 부호 없는 버전이 따로 없다. 부호 없는 수끼리 곱할 때도 `imul eax, ebx`로 하위 32비트를 얻을 수 있다.

다만 **플래그의 의미는 다르다.** IMUL의 OF와 CF는 부호 있는 오버플로를 알려 준다. 부호 없는 수의 넘침을 확인하려면 `MUL`을 써야 한다.

```asm
mov  eax,2000000000
imul eax,2              ; EAX = 4000000000, OF = 1    (부호 있는 수로는 넘쳤다)
mov  eax,2000000000
mov  ebx,2
mul  ebx                ; EAX = 4000000000, EDX = 0, CF = 0    (부호 없는 수로는 정상)
```

40억은 부호 없는 32비트에는 들어가지만 부호 있는 32비트 범위는 넘는다. 같은 비트 결과(`EE6B2800h`)를 두고 IMUL은 넘쳤다고, MUL은 괜찮다고 보고한다.

### 프로그램 실행 시간 측정하기 (Measuring Program Execution Times)

Irvine32 라이브러리의 `GetMseconds`는 **자정부터 지난 시간**을 밀리초 단위로 EAX에 돌려준다. 측정할 코드의 앞뒤에서 한 번씩 호출해 차이를 구하면 실행 시간이 된다.

```asm
.data
startTime DWORD ?
procTime1 DWORD ?
.code
call GetMseconds                ; 시작 시각
mov  startTime,eax
;    ... 측정할 코드 (예: call FirstProcedureToTest)
call GetMseconds                ; 끝난 시각
sub  eax,startTime              ; 걸린 시간을 계산한다
mov  procTime1,eax              ; 걸린 시간을 저장한다
```

교재의 CompareMult 프로그램은 이 방법으로 **시프트로 곱하기**와 **MUL로 곱하기**를 비교한다. 두 프로시저 모두 EAX × 36을 `0FFFFFFFFh`번(약 43억 번) 반복한다.

```asm
; 시프트 곱셈과 MUL의 실행 시간 비교 (교재의 CompareMult.asm)
INCLUDE Irvine32.inc
LOOP_COUNT = 0FFFFFFFFh

.data
intval    DWORD 5
startTime DWORD ?

.code
main PROC
    call GetMseconds                ; 시프트 방식
    mov  startTime,eax
    mov  eax,intval
    call mult_by_shifting
    call GetMseconds
    sub  eax,startTime
    call WriteDec                   ; 걸린 시간(ms)
    call Crlf

    call GetMseconds                ; MUL 방식
    mov  startTime,eax
    mov  eax,intval
    call mult_by_MUL
    call GetMseconds
    sub  eax,startTime
    call WriteDec
    call Crlf
    exit
main ENDP

mult_by_shifting PROC               ; EAX × 36을 시프트로, LOOP_COUNT번
    mov  ecx,LOOP_COUNT
L1: push eax                        ; 원래 EAX 보관
    mov  ebx,eax
    shl  eax,5
    shl  ebx,2
    add  eax,ebx
    pop  eax                        ; 원래 EAX 복원
    loop L1
    ret
mult_by_shifting ENDP

mult_by_MUL PROC                    ; EAX × 36을 MUL로, LOOP_COUNT번
    mov  ecx,LOOP_COUNT
L1: push eax
    mov  ebx,36
    mul  ebx
    pop  eax
    loop L1
    ret
mult_by_MUL ENDP
END main
```

교재는 시프트 방식이 훨씬 빠르다고 소개하지만, 이 결과는 **CPU에 따라 크게 다르다.** 8086에서는 16비트 `MUL` 한 번에 100클록이 넘게 걸렸고 386·486에서도 최대 수십 클록이 걸렸으므로, 그 시절에는 시프트가 확실히 빨랐다. 요즘 CPU는 곱셈기가 빨라서 정수 곱셈의 지연 시간이 몇 클록에 불과하다(Agner Fog의 명령어 표 참고). 이 문서를 만들면서 2.8GHz Xeon 가상 머신(리눅스)에서 같은 프로그램을 돌려 보니 시프트 방식 8,364ms, MUL 방식 8,274ms로 사실상 차이가 없었다. 루프 안의 `push`/`pop`과 `loop`가 시간의 대부분을 차지하기 때문이기도 하다.

> [!CAUTION]
> `GetMseconds`는 **자정부터 센** 시간이므로, 측정하는 동안 자정이 지나면 끝 시각이 시작 시각보다 작아져 뺄셈 결과가 엉터리가 된다. 또 해상도가 10ms 안팎이라(라이브러리 소스의 설명) 아주 짧은 코드는 여러 번 반복해서 재야 한다. 더 정밀하게 재려면 CPU의 클록 카운터를 읽는 `RDTSC` 명령어를 쓰는 방법도 있다.

### DIV 명령어

`DIV`(unsigned divide)는 부호 없는 정수를 나눈다. 피연산자로 적는 것은 **제수**(divisor, 나누는 수)이고, **피제수**(dividend, 나뉘는 수)는 제수의 **두 배 크기**로 정해진 레지스터에 있어야 한다. 나눗셈 한 번으로 **몫**(quotient)과 **나머지**(remainder)가 함께 나온다.

```text
DIV reg/mem8
DIV reg/mem16
DIV reg/mem32
```

| 피제수 (Dividend) | 제수 (Divisor) | 몫 (Quotient) | 나머지 (Remainder) |
|---|---|---|---|
| AX | reg/mem8 | AL | AH |
| DX:AX | reg/mem16 | AX | DX |
| EDX:EAX | reg/mem32 | EAX | EDX |

곱셈 표를 거꾸로 읽은 모양이다. 곱셈이 두 배 크기의 곱을 만들므로, 나눗셈은 두 배 크기의 피제수를 받아 원래 크기의 몫과 나머지를 만든다. `DIV`와 `IDIV` 뒤의 상태 플래그(CF, OF, SF, ZF, AF, PF)는 **모두 정의되지 않는다**(All arithmetic status flag values are undefined after executing DIV and IDIV). 나눗셈 결과로 분기하려면 `CMP`나 `TEST`를 다시 해야 한다.

```asm
mov ax,0083h            ; 피제수
mov bl,2                ; 제수
div bl                  ; AL = 41h, AH = 01h    (131 ÷ 2 = 65 나머지 1)
```

```text
  AX      BL        AL    AH
 0083  /  02   →    41    01        (몫은 AL, 나머지는 AH)
```

```asm
mov dx,0                ; 피제수의 상위 절반을 0으로
mov ax,8003h            ; 피제수의 하위 절반
mov cx,100h             ; 제수
div cx                  ; AX = 0080h, DX = 0003h
```

```text
  DX   AX      CX        AX     DX
 0000 8003 / 0100  →   0080   0003      (몫은 AX, 나머지는 DX)
```

64비트 피제수를 32비트로 나눌 때는 피제수를 메모리에 QWORD로 두고 두 번에 나누어 EDX와 EAX로 읽는다. 리틀 엔디안이므로 `dividend + 4`가 상위 더블워드다.

```asm
.data
dividend QWORD 0000000800300020h
divisor  DWORD 00000100h
.code
mov edx,DWORD PTR dividend + 4      ; 상위 더블워드
mov eax,DWORD PTR dividend          ; 하위 더블워드
div divisor                         ; EAX = 08003000h, EDX = 00000020h
```

```text
   EDX       EAX          Divisor         EAX        EDX
 00000008  00300020  /  00000100   →   08003000   00000020
```

몫은 EAX, 나머지는 EDX에 들어간다.

> [!IMPORTANT]
> **부호 없는 나눗셈 전에는 피제수의 상위 절반을 0으로 만든다.** 32비트 값을 나누고 싶은데 EDX에 쓰레기 값이 남아 있으면 `DIV`는 EDX:EAX 전체를 피제수로 보므로 엉뚱한 몫이 나오거나 [나눗셈 오버플로](#나눗셈-오버플로-divide-overflow)로 프로그램이 멈춘다. 8비트 나눗셈이면 `mov ah,0`, 16비트면 `mov dx,0`, 32비트면 `mov edx,0`(또는 `xor edx,edx`)을 나눗셈 바로 앞에 둔다.

### 부호 있는 정수 나눗셈 (Signed Integer Division)

`IDIV`(signed divide)는 `DIV`와 같은 피연산자 형식으로 부호 있는 정수를 나눈다. 차이는 하나다. **피제수를 미리 부호 확장해 두어야 한다.**

왜 그런지 부호 확장을 빠뜨린 경우부터 보자. −101을 2로 나누려고 AX에 −101을 넣고 DX는 0으로 두었다.

```asm
.data
wordVal SWORD -101          ; FF9Bh
.code
mov  edx,0                  ; DX:AX의 상위 절반을 0으로 둔다 (부호 확장을 빠뜨렸다)
mov  ax,wordVal             ; DX:AX = 0000FF9Bh    (+65435로 읽힌다)
mov  bx,2                   ; BX가 제수
idiv bx                     ; 몫 AX = 32717, 나머지 DX = 1    (틀린 답)
```

16비트 `IDIV`의 피제수는 AX만이 아니라 **DX:AX 전체**다. AX만 보면 `FF9Bh`는 −101이지만, DX가 0이면 DX:AX = `0000FF9Bh`는 +65,435다. 그래서 몫이 +32,717이라는 엉뚱한 값이 나왔다(Unfortunately, the 009Bh in EAX is not really equal to 101). 올바르게 하려면 `CWD`(convert word to doubleword)로 AX의 부호 비트를 DX 전체에 복사해야 한다.

```asm
.data
wordVal SWORD -101          ; FF9Bh
.code
mov  ax,wordVal             ; AX = FF9Bh
cwd                         ; DX:AX = FFFFFF9Bh    (−101)
mov  bx,2                   ; BX가 제수
idiv bx                     ; 몫 AX = -50, 나머지 DX = -1
```

> [!WARNING]
> **슬라이드 정정** (Signed Integer Division 슬라이드)
> - `wordVal SWORD -101 ; 009Bh`: −101을 16비트로 나타내면 `FF9Bh`다. `9Bh`는 8비트로 나타낸 −101이다.
> - `mov ax,wordVal ; EAX = 0000009Bh (+155)`: `mov eax,0` 다음에 AX에 `FF9Bh`를 넣었으므로 EAX = `0000FF9Bh`(+65,435)다. 아래 파란 글씨의 "009Bh"도 같은 이유로 "FF9Bh(DX = 0이면 +65,435)"가 맞다.
> - `mov bx,2 ; EBX is the divisor`: 제수는 EBX가 아니라 **BX**다.
> - `idiv bx ; divide EAX by BX`: 16비트 `IDIV`가 나누는 것은 EAX가 아니라 **DX:AX**다. 슬라이드의 코드는 DX를 정하지 않았으므로 DX에 남아 있던 값에 따라 결과가 달라지고, 경우에 따라서는 나눗셈 오버플로로 멈출 수도 있다. 위 예제처럼 `mov edx,0`(또는 `mov dx,0`)을 두어야 결과가 정해진다.
> - `cwd ; EAX = FFFFFF9Bh (-101)`: `CWD`는 EAX를 바꾸지 않는다. AX의 부호를 **DX**로 확장하므로 결과는 DX:AX = `FFFF:FF9Bh`, 즉 DX = `FFFFh`, AX = `FF9Bh`다. EAX를 `FFFFFF9Bh`로 만드는 명령어는 `CWDE`다.

#### 부호 확장 명령어 CBW, CWD, CDQ

부호 있는 나눗셈 앞에서 피제수를 준비하는 명령어 세 개다. 모두 피연산자가 없고 정해진 레지스터만 다룬다. 플래그는 바꾸지 않는다.

```asm
.data
byteVal  SBYTE  -101        ; 9Bh
wordVal  SWORD  -101        ; FF9Bh
dwordVal SDWORD -101        ; FFFFFF9Bh
.code
mov  al,byteVal             ; AL = 9Bh
cbw                         ; AX = FF9Bh                 (convert byte to word)
mov  ax,wordVal             ; AX = FF9Bh
cwd                         ; DX:AX = FFFFFF9Bh          (convert word to doubleword)
mov  eax,dwordVal
cdq                         ; EDX:EAX = FFFFFFFFFFFFFF9Bh  (convert doubleword to quadword)
```

| 명령어 | 동작 | 언제 쓰나 |
|---|---|---|
| `CBW` | AL의 부호를 AH로 확장 (AL → AX) | 8비트 `IDIV` 앞 |
| `CWD` | AX의 부호를 DX로 확장 (AX → DX:AX) | 16비트 `IDIV` 앞 |
| `CDQ` | EAX의 부호를 EDX로 확장 (EAX → EDX:EAX) | 32비트 `IDIV` 앞 |
| `CWDE` (보충) | AX의 부호를 EAX 상위 16비트로 확장 (AX → EAX) | 나눗셈과 상관없이 16비트 값을 32비트로 넓힐 때 |
| `CQO` (보충) | RAX의 부호를 RDX로 확장 (RAX → RDX:RAX) | 64비트 모드의 64비트 `IDIV` 앞 |

`CWD`와 `CWDE`는 이름이 비슷하지만 결과가 들어가는 곳이 다르다. `CWD`는 DX와 AX **두 레지스터**에 걸친 32비트 값을 만들고, `CWDE`는 EAX **한 레지스터**를 32비트로 채운다. `CWDE`는 4장의 `movsx eax, ax`와 같은 일을 한다.

```asm
mov  ax,-101
cwde                        ; EAX = FFFFFF9Bh
mov  bx,-101
movsx ebx,bx                ; EBX = FFFFFF9Bh    (같은 결과, 아무 레지스터에나 쓸 수 있다)
```

#### IDIV 명령어

슬라이드의 예제 세 개다. 8비트 나눗셈 앞에서는 AX 전체가 부호 확장되어 있어야 한다(Before executing 8-bit division, the dividend (AX) must be completely sign-extended).

```asm
.data
byteVal SBYTE -48           ; D0 hexadecimal
.code
mov  al,byteVal             ; 피제수의 하위 절반
cbw                         ; AX = FFD0h    (AL을 AH로 확장)
mov  bl,+5                  ; 제수
idiv bl                     ; AL = -9, AH = -3
```

```text
AL:                            1 1 0 1 0 0 0 0     (−48)
AX after CBW:  1 1 1 1 1 1 1 1 1 1 0 1 0 0 0 0     (−48)
               |---- AH -----| |---- AL -----|
```

`CBW`는 AL의 부호 비트(1)를 AH의 여덟 비트에 모두 복사한다. AL은 그대로이고, AX 전체가 −48을 나타내게 된다.

```asm
.data
wordVal SWORD -5000
.code
mov  ax,wordVal             ; 피제수의 하위 절반
cwd                         ; AX를 DX로 확장
mov  bx,+256                ; 제수
idiv bx                     ; 몫 AX = -19, 나머지 DX = -136
```

```asm
.data
dwordVal SDWORD +50000
.code
mov  eax,dwordVal           ; 피제수의 하위 절반
cdq                         ; EAX를 EDX로 확장
mov  ebx,-256               ; 제수
idiv ebx                    ; 몫 EAX = -195, 나머지 EDX = +80
```

#### 몫과 나머지의 부호 (보충)

`IDIV`는 C 언어의 `/`, `%`와 같은 규칙을 따른다.

- **몫은 0 방향으로 버린다.** −7 ÷ 2 = −3.5이므로 몫은 −3이다(−4가 아니다).
- **나머지의 부호는 피제수의 부호와 같다.** 항상 `피제수 = 제수 × 몫 + 나머지`가 성립하고, 나머지의 절댓값은 제수의 절댓값보다 작다.

| 피제수 | 제수 | 몫 | 나머지 | 검산 |
|---|---|---|---|---|
| 7 | 2 | 3 | 1 | 2 × 3 + 1 = 7 |
| −7 | 2 | −3 | −1 | 2 × (−3) − 1 = −7 |
| 7 | −2 | −3 | 1 | (−2) × (−3) + 1 = 7 |
| −7 | −2 | 3 | −1 | (−2) × 3 − 1 = −7 |

```asm
mov  ebx,2
mov  eax,7
cdq
idiv ebx                    ; EAX = 3, EDX = 1
mov  eax,-7
cdq
idiv ebx                    ; EAX = -3, EDX = -1
mov  ebx,-2
mov  eax,7
cdq
idiv ebx                    ; EAX = -3, EDX = 1
mov  eax,-7
cdq
idiv ebx                    ; EAX = 3, EDX = -1
```

나눗셈 앞의 준비를 한 표로 정리하면 다음과 같다.

| 나눗셈 | 피제수의 상위 절반 준비 | 코드 |
|---|---|---|
| 8비트, 부호 없음 | AH = 0 | `mov ah,0` → `div bl` |
| 16비트, 부호 없음 | DX = 0 | `mov dx,0` → `div bx` |
| 32비트, 부호 없음 | EDX = 0 | `mov edx,0` → `div ebx` |
| 8비트, 부호 있음 | AL을 AX로 부호 확장 | `cbw` → `idiv bl` |
| 16비트, 부호 있음 | AX를 DX:AX로 부호 확장 | `cwd` → `idiv bx` |
| 32비트, 부호 있음 | EAX를 EDX:EAX로 부호 확장 | `cdq` → `idiv ebx` |

### 나눗셈 오버플로 (Divide Overflow)

나눗셈의 몫이 목적지(AL, AX, EAX)에 들어가지 않으면 **나눗셈 오버플로**(divide overflow)가 된다. 이때 CPU는 결과를 쓰지 않고 **나눗셈 오류 예외**(divide error, #DE)를 일으키며, 운영체제가 프로그램을 멈춘다(This causes a processor exception and halts the current program). **0으로 나누는 것**도 같은 예외를 일으킨다. 덧셈의 오버플로처럼 플래그만 세우고 넘어가는 것이 아니라는 점에 주의하자.

```asm
mov ax,1000h
mov bl,10h
div bl                      ; #DE: 몫 100h가 AL에 들어가지 않는다
```

4096 ÷ 16 = 256(`100h`)이라 계산 자체는 문제가 없지만, 8비트 나눗셈의 몫은 AL(최대 255)에 들어가야 하므로 예외가 난다. CPU가 일으키는 예외는 두 경우 모두 #DE 하나지만, Windows는 제수가 0인지를 따로 확인해서 0으로 나누기는 `0xC0000094: Integer division by zero`, 몫이 넘친 경우는 `0xC0000095: Integer overflow`로 보고한다. Visual Studio에서 실행하면 이 메시지와 함께 처리되지 않은 예외로 멈춘다. 리눅스에서는 이름과 달리 "Floating point exception"(SIGFPE)으로 끝난다.

슬라이드의 제안처럼 **더 큰 나눗셈**을 쓰면 오버플로 가능성이 줄어든다(use a 32-bit divisor and 64-bit dividend to reduce the probability of a divide overflow condition).

```asm
mov eax,1000h
cdq                         ; EDX = 0
mov ebx,10h
div ebx                     ; EAX = 00000100h
```

> [!CAUTION]
> 위 코드(슬라이드와 교재의 코드)는 **부호 없는** `DIV` 앞에서 `CDQ`를 썼다. `1000h`가 양수라서 EDX가 우연히 0이 되었을 뿐이다. EAX의 최상위 비트가 1이면 `CDQ`가 EDX를 `FFFFFFFFh`로 채우므로, 부호 없는 나눗셈에서는 오히려 오버플로를 **일으킨다**. `DIV` 앞에는 `mov edx,0`, `IDIV` 앞에는 `CDQ`로 짝을 맞추자.
>
> ```asm
> mov eax,80000000h           ; 부호 없는 수 2,147,483,648
> cdq                         ; EDX = FFFFFFFFh    (최상위 비트가 1이라 음수로 보고 채웠다)
> mov ebx,10h
> div ebx                     ; #DE: EDX:EAX가 너무 커서 몫이 32비트를 넘는다
> ```
>
> ```asm
> mov eax,80000000h
> mov edx,0                   ; 부호 없는 나눗셈은 0으로 채운다
> mov ebx,10h
> div ebx                     ; EAX = 08000000h, EDX = 0
> ```

#### 0으로 나누기 막기

0으로 나누기를 막으려면 나누기 전에 제수를 검사한다(To prevent division by zero, test the divisor before dividing). 슬라이드의 코드 조각을 실행할 수 있는 프로그램으로 만들었다.

```asm
; 나누기 전에 제수가 0인지 검사한다
INCLUDE Irvine32.inc

.data
dividend WORD 1000
divisor  BYTE 0
msgZero  BYTE "Attempt to divide by zero",0

.code
main PROC
    mov  ax,dividend
    mov  bl,divisor
    cmp  bl,0                   ; 제수를 검사한다
    je   NoDivideZero           ; 점프한다 (제수가 0이다)
    div  bl                     ; 실행되지 않는다
    jmp  quit                   ; 실행되지 않는다
NoDivideZero:
    mov  edx,OFFSET msgZero     ; 오류 메시지를 출력한다
    call WriteString
    call Crlf
quit:
    exit
main ENDP
END main
```

실행 결과:

```text
Attempt to divide by zero
```

#### 몫이 넘칠지 미리 알아보기 (보충)

0이 아닌 제수라도 몫이 넘칠 수 있다. 부호 없는 나눗셈에서는 간단한 판별법이 있다. **피제수의 상위 절반이 제수보다 작으면** 몫이 목적지에 들어간다. 예를 들어 32비트 `DIV`라면 EDX < 제수일 때만 안전하다.

```asm
mov  edx,1
mov  eax,0                  ; EDX:EAX = 100000000h (2³²)
mov  ebx,1
cmp  edx,ebx                ; 몫이 32비트에 들어가려면 EDX < 제수여야 한다
jae  TooBig                 ; 점프한다 (몫 2³²는 32비트를 넘는다)
div  ebx                    ; 실행되지 않는다
TooBig:
```

부호 있는 나눗셈에는 눈여겨볼 특별한 경우가 하나 있다. **가장 작은 음수를 −1로 나누는 것**이다. 32비트에서 −2,147,483,648 ÷ (−1) = +2,147,483,648인데, 이 값은 부호 있는 32비트의 최댓값(+2,147,483,647)보다 1이 크므로 오버플로가 된다.

```asm
mov  eax,80000000h          ; −2,147,483,648
cdq                         ; EDX = FFFFFFFFh
mov  ebx,-1
idiv ebx                    ; #DE: 몫 +2,147,483,648이 EAX에 들어가지 않는다
```

### 산술식 구현하기 (Implementing Arithmetic Expressions)

4장에서는 덧셈과 뺄셈만으로 된 식을 어셈블리로 옮겼다. 곱셈과 나눗셈이 섞이면 신경 쓸 것이 늘어난다. 어느 레지스터가 암묵적으로 쓰이는지(EAX, EDX), 결과가 넘치지 않는지, 부호 있는 연산인지를 따져야 한다. 교재의 Express 프로그램처럼 `var1 = 3`, `var2 = 6`, `var3 = 4`로 두고 따라가 보자.

**예제 1: `var4 = (var1 + var2) * var3;`** (부호 없는 수)

```asm
.data
var1   DWORD 3
var2   DWORD 6
var3   DWORD 4
var4   DWORD ?
msgBig BYTE "Unsigned overflow!",0
.code
    mov  eax,var1
    add  eax,var2               ; EAX = 9
    mul  var3                   ; EDX:EAX = 36    (EAX × var3)
    jc   tooBig                 ; 점프하지 않는다 (상위 절반이 0이다)
    mov  var4,eax               ; var4 = 36
    jmp  next
tooBig:                         ; 오류 메시지를 출력한다
    mov  edx,OFFSET msgBig
    call WriteString
next:
```

`MUL` 뒤의 CF가 1이면 곱이 EAX 하나에 들어가지 않은 것이다(unsigned overflow). 엄밀하게 하려면 `ADD` 뒤에도 `jc tooBig`를 두어야 한다. `var1 + var2`가 이미 32비트를 넘었을 수도 있기 때문이다.

**예제 2: `var4 = (var1 * 5) / (var2 - 3);`** (부호 없는 수)

```asm
.data
var1 DWORD 3
var2 DWORD 6
var4 DWORD ?
.code
    mov  eax,var1               ; 왼쪽 식
    mov  ebx,5
    mul  ebx                    ; EDX:EAX = 15    (곱)
    mov  ebx,var2               ; 오른쪽 식
    sub  ebx,3                  ; EBX = 3
    div  ebx                    ; EAX = 5    (최종 나눗셈)
    mov  var4,eax               ; var4 = 5
```

`MUL`이 만든 64비트 곱 EDX:EAX가 그대로 `DIV`의 피제수가 된다. 곱이 32비트를 넘어도 몫만 32비트에 들어가면 정확한 답이 나오므로, 곱셈과 나눗셈이 이어진 식에서는 이 짝이 편리하다. 반대로 `MUL`과 `DIV` 사이에서 EDX를 다른 용도로 쓰면 안 된다.

**예제 3: `var4 = (var1 * -5) / (-var2 % var3);`** (부호 있는 수)

```asm
.data
var1 SDWORD 3
var2 SDWORD 6
var3 SDWORD 4
var4 SDWORD ?
.code
    mov  eax,var2               ; 오른쪽 식부터 계산한다
    neg  eax                    ; EAX = -6
    cdq                         ; 피제수를 부호 확장한다
    idiv var3                   ; EDX = -2    (나머지 = −6 % 4)
    mov  ebx,edx                ; EBX = -2    (오른쪽 식의 값)
    mov  eax,-5                 ; 왼쪽 식
    imul var1                   ; EDX:EAX = -15
    idiv ebx                    ; EAX = 7, EDX = -1    (−15 ÷ −2: 몫 7, 나머지 −1)
    mov  var4,eax               ; var4 = 7
```

이번에는 **오른쪽 식을 먼저** 계산했다. 왼쪽 식의 곱은 EDX:EAX에 나오고 그것이 곧 마지막 `IDIV`의 피제수가 되어야 하는데, 오른쪽 식을 나중에 계산하면 그 `IDIV`가 EDX:EAX를 덮어쓰기 때문이다. 오른쪽 식의 값(나머지)은 EDX에 나오므로 EBX로 옮겨 제수로 쓴다. `%` 연산은 나머지만 쓰면 되므로 몫(EAX)은 버린다.

#### 부호 있는 수로 예제 1을 다시 쓰기 (보충)

변수가 부호 있는 수라면 `MUL`과 `JC` 대신 `IMUL`과 `JO`를 쓴다. 2-피연산자 `IMUL`은 곱을 바로 EAX에 남기므로 코드도 짧아진다.

```asm
.data
var1 SDWORD -3
var2 SDWORD 6
var3 SDWORD -4
var4 SDWORD ?
.code
    mov  eax,var1
    add  eax,var2               ; EAX = 3
    jo   tooBig                 ; 점프하지 않는다
    imul eax,var3               ; EAX = -12
    jo   tooBig                 ; 점프하지 않는다
    mov  var4,eax               ; var4 = -12
    jmp  next
tooBig:                         ; (오류 처리)
next:
```

---

## 7.4 확장 덧셈과 뺄셈 (Extended Addition and Subtraction)

32비트 CPU의 `ADD`와 `SUB`는 한 번에 32비트까지만 계산한다. 그보다 큰 정수, 예를 들어 64비트나 1024비트 정수는 32비트(또는 8비트) 조각으로 나누어 **낮은 자리부터** 계산하고, 각 조각에서 생긴 자리올림(carry)이나 자리내림(borrow)을 다음 조각에 넘겨주면 된다. 손으로 하는 10진수 덧셈에서 "받아올림"을 다음 자리에 더하는 것과 같은 원리다. 이 "넘겨주기"를 하는 명령어가 `ADC`와 `SBB`다.

### ADC 명령어

`ADC`(add with carry)는 소스 피연산자와 **CF의 값까지** 목적지에 더한다(The ADC instruction adds both a source operand and the contents of the Carry flag to a destination operand).

```text
ADC destination, source        ; destination = destination + source + CF

ADC reg, reg        ADC mem, reg        ADC reg, mem
ADC mem, imm        ADC reg, imm
```

피연산자 형식은 `ADD`와 같고, 플래그(CF, OF, SF, ZF, AF, PF)도 `ADD`처럼 결과에 따라 바뀐다. 따라서 `ADC`가 만든 새 자리올림이 다시 CF에 남아 그다음 `ADC`로 넘어간다.

슬라이드의 예제는 8비트 두 개를 더한 결과를 16비트(DL:AL)로 받는다.

```asm
mov dl,0
mov al,0FFh
add al,0FFh             ; AL = FEh, CF = 1
adc dl,0                ; DL:AL = 01FEh    (DL에는 0 + 0 + CF가 들어갔다)
```

```text
ADD AL,0FFh:  AL = 11111111 + 11111111          = 11111110,  CF = 1
ADC DL,0:     DL = 00000000 + 00000000 + 1 (CF) = 00000001
```

255 + 255 = 510 = `01FEh`이다. 하위 바이트의 덧셈에서 넘친 1이 CF를 거쳐 상위 바이트로 들어갔다. `DL:AL`(슬라이드의 표기로는 `DL/AL`)은 DL을 상위, AL을 하위로 이어 읽은 16비트 값이라는 뜻이다.

#### 64비트 정수 더하기 (보충)

메모리에 있는 64비트 정수 두 개를 더해 보자. 리틀 엔디안이므로 각 QWORD의 앞 4바이트가 하위 더블워드, 뒤 4바이트(`+4`)가 상위 더블워드다.

```asm
.data
op1  QWORD 00000001FFFFFFFFh
op2  QWORD 0000000200000001h
sum  QWORD ?
.code
mov  eax,DWORD PTR op1
add  eax,DWORD PTR op2              ; EAX = 00000000h, CF = 1    (하위 32비트, 자리올림 발생)
mov  DWORD PTR sum,eax              ; MOV는 CF를 바꾸지 않는다
mov  eax,DWORD PTR op1+4
adc  eax,DWORD PTR op2+4            ; EAX = 00000004h    (1 + 2 + CF)
mov  DWORD PTR sum+4,eax            ; sum = 0000000400000000h
```

첫 `ADD`와 `ADC` 사이에 `MOV`가 두 개 끼어 있지만 `MOV`는 플래그를 바꾸지 않으므로 CF가 그대로 전달된다. 이 사이에 `ADD`, `SUB`, `CMP` 같은 명령어를 넣으면 CF가 덮어써지므로 조심해야 한다.

### 확장 덧셈 예제 (Extended Addition Example)

슬라이드에서는 빠져 있지만(빈 슬라이드) 교재 7.4.2절의 ExtAdd 프로그램은 길이에 제한 없는 정수를 더하는 프로시저를 보여 준다. 두 정수는 **바이트 배열**로, 가장 낮은 자리 바이트가 가장 낮은 주소에 오도록(리틀 엔디안) 저장한다.

```asm
; 두 8바이트 정수의 합 (교재의 ExtAdd.asm)
INCLUDE Irvine32.inc

.data
op1 BYTE 34h,12h,98h,74h,06h,0A4h,0B2h,0A2h     ; A2B2A40674981234h
op2 BYTE 02h,45h,23h,00h,00h,87h,10h,80h        ; 8010870000234502h
sum BYTE 9 DUP(0)                               ; 0122C32B0674BB5736h가 될 자리

.code
main PROC
    mov  esi,OFFSET op1                 ; 첫 번째 피연산자
    mov  edi,OFFSET op2                 ; 두 번째 피연산자
    mov  ebx,OFFSET sum                 ; 합
    mov  ecx,LENGTHOF op1               ; 바이트 수
    call Extended_Add
    mov  esi,OFFSET sum                 ; 합을 출력한다
    mov  ecx,LENGTHOF sum
    call Display_Sum
    call Crlf
    exit
main ENDP

;--------------------------------------------------------
Extended_Add PROC
;
; 바이트 배열로 저장된 두 정수를 더한다.
; Receives: ESI, EDI = 두 정수의 주소, EBX = 합을 저장할 주소,
;           ECX = 더할 바이트 수
; 합을 저장할 곳은 피연산자보다 한 바이트 길어야 한다.
; Returns: nothing
;--------------------------------------------------------
    pushad
    clc                                 ; 첫 자리에는 들어올 자리올림이 없다
L1: mov  al,[esi]                       ; 첫 번째 정수의 바이트
    adc  al,[edi]                       ; 두 번째 정수의 바이트 + CF
    pushfd                              ; CF를 저장한다
    mov  [ebx],al                       ; 부분 합 저장
    add  esi,1                          ; 세 포인터를 모두 전진
    add  edi,1
    add  ebx,1
    popfd                               ; CF를 복원한다
    loop L1                             ; 반복

    mov  byte ptr [ebx],0               ; 합의 최상위 바이트를 0으로
    adc  byte ptr [ebx],0               ; 남은 자리올림을 더한다
    popad
    ret
Extended_Add ENDP

;-----------------------------------------------------------
Display_Sum PROC
;
; 리틀 엔디안으로 저장된 큰 정수를 최상위 바이트부터 16진수로 출력한다.
; Receives: ESI = 배열의 주소, ECX = 배열의 크기
;-----------------------------------------------------------
    pushad
    add  esi,ecx                        ; 배열의 마지막 바이트를 가리킨다
    sub  esi,TYPE BYTE
    mov  ebx,TYPE BYTE
L1: mov  al,[esi]                       ; 바이트 하나를 가져와
    call WriteHexB                      ; 16진수로 출력
    sub  esi,TYPE BYTE                  ; 앞 바이트로
    loop L1
    popad
    ret
Display_Sum ENDP
END main
```

실행 결과:

```text
0122C32B0674BB5736
```

```text
      A2 B2 A4 06 74 98 12 34      op1 (높은 자리부터)
  +   80 10 87 00 00 23 45 02      op2
  ───────────────────────────
   01 22 C3 2B 06 74 BB 57 36      sum (9바이트: 맨 앞 01은 마지막 자리올림)
```

- `CLC`로 시작하는 이유: 루프 안에는 `ADD`가 따로 없고 처음부터 `ADC`를 쓴다. 첫 바이트에는 더할 자리올림이 없으므로 CF를 0으로 만들어 두어야 한다.
- `PUSHFD`/`POPFD`로 CF를 지키는 이유: 포인터를 옮기는 `add esi,1` 같은 명령어가 CF를 덮어쓰기 때문이다. `LOOP`는 플래그를 바꾸지 않으므로 그대로 둬도 된다.
- 합을 저장할 배열이 한 바이트 더 긴 이유: 맨 마지막 덧셈에서 자리올림이 생길 수 있다. 루프가 끝난 뒤 `adc byte ptr [ebx],0`으로 그 자리올림을 최상위 바이트에 넣는다.
- `Display_Sum`은 배열의 끝(최상위 바이트)부터 앞으로 거꾸로 출력해서 사람이 읽는 순서로 보여 준다.

#### 더 간단하게: CF를 건드리지 않는 명령어로 포인터 옮기기 (보충)

`INC`와 `DEC`는 다른 플래그는 바꾸지만 **CF는 바꾸지 않는다**(4장). 포인터를 `INC`로 옮기면 `PUSHFD`/`POPFD`가 필요 없다.

```asm
.data
num1  BYTE 34h,12h,98h,74h,06h,0A4h,0B2h,0A2h
num2  BYTE 02h,45h,23h,00h,00h,87h,10h,80h
total BYTE 9 DUP(0)
.code
    mov  esi,OFFSET num1
    mov  edi,OFFSET num2
    mov  ebx,OFFSET total
    mov  ecx,LENGTHOF num1
    clc
L1: mov  al,[esi]
    adc  al,[edi]
    mov  [ebx],al
    inc  esi                            ; INC는 CF를 바꾸지 않는다
    inc  edi
    inc  ebx
    loop L1
    mov  BYTE PTR [ebx],0
    adc  BYTE PTR [ebx],0               ; total = 0122C32B0674BB5736h
```

32비트 CPU라면 한 번에 4바이트씩 더하는 편이 빠르다. 피연산자를 DWORD 배열로 두고 `adc eax,[edi]`로 더한 뒤 포인터를 4씩 옮기면 된다. 포인터를 4씩 옮길 때는 `lea esi,[esi+4]`처럼 플래그를 바꾸지 않는 `LEA`를 쓰면 된다.

### SBB 명령어

`SBB`(subtract with borrow)는 소스 피연산자와 **CF의 값까지** 목적지에서 뺀다(The SBB instruction subtracts both a source operand and the value of the Carry flag from a destination operand). 뺄셈에서 CF는 "빌려 온 1"(borrow)을 뜻하므로, 아래 자리에서 빌린 만큼 위 자리에서 하나 더 빼는 것이다.

```text
SBB destination, source        ; destination = destination - source - CF
```

피연산자 형식과 플래그 동작은 `SUB`와 같다. 슬라이드의 예제는 EDX:EAX에 들어 있는 64비트 정수에서 2를 뺀다.

```asm
mov edx,7               ; 상위 절반
mov eax,1               ; 하위 절반    (EDX:EAX = 0000000700000001h)
sub eax,2               ; EAX = FFFFFFFFh, CF = 1    (하위 절반에서 2를 빼며 자리내림)
sbb edx,0               ; EDX:EAX = 00000006FFFFFFFFh    (상위 절반에서 빌린 1을 뺀다)
```

```text
          EDX        EAX
Before:  00000007   00000001

            EAX                     EAX
SUB EAX,2  00000001 − 00000002 →  FFFFFFFF
                                  ↓ CF = 1
            EDX                         EDX
SBB EDX,0  00000007 − 00000000 − 1 →  00000006

          EDX        EAX
After:   00000006   FFFFFFFF
```

64비트로 보면 `700000001h − 2 = 6FFFFFFFFh`다. 하위 절반의 `1 − 2`는 음수가 되므로 2³²를 빌려 와서 `FFFFFFFFh`가 되고(CF = 1), 그 빌린 1을 상위 절반에서 갚아 7이 6이 되었다.

### CF를 활용하는 요령 (보충)

확장 연산을 짤 때는 **어떤 명령어가 CF를 바꾸고 어떤 명령어가 그대로 두는지**를 알아야 한다.

| CF를 그대로 두는 명령어 | CF를 바꾸는 명령어 |
|---|---|
| `MOV`, `MOVZX`, `MOVSX`, `LEA`, `XCHG`, `PUSH`, `POP` | `ADD`, `SUB`, `ADC`, `SBB`, `CMP`, `NEG` |
| `INC`, `DEC` (다른 플래그는 바꾼다) | `AND`, `OR`, `XOR`, `TEST` (CF를 0으로 만든다) |
| `NOT`, `LOOP`, `JMP`와 조건부 점프 | 시프트·회전, `MUL`, `IMUL` (나눗셈 뒤 CF는 정의되지 않는다) |
| `CBW`, `CWD`, `CDQ` | `CLC`(CF = 0), `STC`(CF = 1), `CMC`(CF 반전), `POPFD` |

#### 64비트 정수의 부호 바꾸기

`NEG`는 피연산자가 0이 아니면 CF = 1로 만든다. 0에서 빼는 것으로 보면 0이 아닌 값을 뺄 때는 항상 자리내림이 생기기 때문이다. 이 성질을 이용하면 EDX:EAX에 있는 64비트 정수의 부호를 세 줄로 바꿀 수 있다.

```asm
mov  edx,0
mov  eax,5                  ; EDX:EAX = 5
neg  edx                    ; 상위 절반의 부호를 바꾼다
neg  eax                    ; EAX = FFFFFFFBh, CF = 1    (하위 절반이 0이 아니므로 자리내림)
sbb  edx,0                  ; EDX:EAX = FFFFFFFFFFFFFFFBh    (−5)
```

64비트 수 −x는 0 − x다. 상위·하위 절반을 따로 `NEG`하면 각각 0 − (그 절반)이 되는데, 하위 절반의 뺄셈에서 생긴 자리내림을 상위 절반에서 한 번 더 빼 주어야 한다. 그 일을 `SBB edx,0`이 한다.

#### CF를 0 또는 −1로 바꾸기

`SBB`에 같은 레지스터를 두 번 쓰면 `reg − reg − CF = −CF`이므로, CF가 1이면 `FFFFFFFFh`(−1), 0이면 0이 된다. 비교 결과를 분기 없이 **마스크**로 만들 때 쓰는 요령이다.

```asm
mov  eax,3
mov  ebx,5
cmp  eax,ebx                ; 부호 없는 수로 3 < 5이므로 CF = 1
sbb  ecx,ecx                ; ECX = FFFFFFFFh    (CF가 1이었다)
cmp  ebx,eax                ; 5 < 3은 거짓이므로 CF = 0
sbb  edx,edx                ; EDX = 0
```

#### CF를 세어 1인 비트 개수 구하기

시프트로 밀려난 비트는 CF에 남고, `ADC reg, 0`은 CF를 더한다. 둘을 붙이면 1인 비트의 개수(population count)를 셀 수 있다.

```asm
    mov  eax,12345678h
    mov  ebx,0                  ; 1인 비트의 개수
L1: shr  eax,1                  ; 최하위 비트를 CF로 밀어낸다
    adc  ebx,0                  ; CF를 더한다
    test eax,eax                ; 남은 1 비트가 있는가?
    jnz  L1                     ; 끝나면 EBX = 13
```

`12345678h`의 각 16진 자릿수 1, 2, 3, 4, 5, 6, 7, 8에 들어 있는 1의 개수는 1, 1, 2, 1, 2, 2, 3, 1이므로 합은 13이다. `TEST`는 CF를 0으로 만들지만, 그 전에 `ADC`가 이미 CF를 더했으므로 문제가 없다.

---

## 7.5 ASCII와 언팩 10진수 산술 (ASCII and Unpacked Decimal Arithmetic)

### 세 가지 10진수 표현

CPU는 2진수로 계산하지만 사람은 10진수로 입력하고 읽는다. 키보드로 들어온 숫자는 문자(ASCII)이고, 금액처럼 10진수 자릿수를 정확히 지켜야 하는 데이터도 있다. 그래서 x86은 **10진수를 한 자리씩 저장한 데이터**를 직접 계산하는 명령어를 갖고 있다. 10진수를 저장하는 방법은 세 가지다.

| 표현 | 한 바이트에 담는 것 | 3402를 저장한 모습 (16진수) |
|---|---|---|
| ASCII 10진수 (ASCII decimal) | 숫자 문자 하나 (`'0'` ~ `'9'` = `30h` ~ `39h`) | `33 34 30 32` |
| 언팩 10진수 (unpacked decimal) | 숫자 하나 (`00h` ~ `09h`) | `03 04 00 02` |
| 팩 10진수 (packed decimal, BCD) | 숫자 두 개 (니블마다 하나) | `34 02` |

ASCII 10진수와 언팩 10진수는 **하위 4비트가 같고 상위 4비트만 다르다**. 언팩 10진수의 상위 4비트는 항상 0이고, ASCII 숫자의 상위 4비트는 `0011b`다(The high 4 bits of an unpacked decimal integer are always zeros, whereas the same bits in an ASCII decimal number are equal to 0011b). 그래서 둘 사이의 변환은 비트 연산 하나로 끝난다.

```asm
mov al,'7'              ; AL = 37h    (ASCII)
and al,0Fh              ; AL = 07h    (언팩: 상위 4비트를 지운다)
or  al,30h              ; AL = 37h    (다시 ASCII: 상위 4비트를 0011b로)
```

> [!NOTE]
> 표의 ASCII와 언팩 10진수는 **사람이 읽는 순서대로**(높은 자리 숫자가 낮은 주소에) 저장한 것이다. 문자열이 그렇게 저장되기 때문이다. 팩 10진수 `3402`를 `WORD 3402h`로 선언하면 메모리에는 리틀 엔디안에 따라 `02 34` 순서로 들어간다. 어느 순서로 다루는지는 프로그램마다 정해야 한다.

ASCII·언팩 10진수 연산은 이렇게 한다. **먼저 보통의 `ADD`, `SUB`, `MUL`로 2진 연산을 하고, 그 결과를 보정(adjust) 명령어로 10진수 모양으로 고친다.** 나눗셈만은 거꾸로 `DIV` **전에** 보정한다.

| 명령어 | 이름 | 하는 일 |
|---|---|---|
| `AAA` | ASCII adjust after addition | `ADD`/`ADC` 뒤에 AL의 합을 한 자리 숫자와 자리올림(AH)으로 고친다 |
| `AAS` | ASCII adjust after subtraction | `SUB`/`SBB` 뒤에 AL의 차를 한 자리 숫자와 자리내림(AH)으로 고친다 |
| `AAM` | ASCII adjust after multiplication | `MUL` 뒤에 AL의 곱(0~81)을 두 자리 언팩 10진수(AH:AL)로 바꾼다 |
| `AAD` | ASCII adjust before division | `DIV` 전에 AH:AL의 두 자리 언팩 10진수를 2진수(AL)로 바꾼다 |

- 네 명령어 모두 피연산자가 없고 AL과 AH만 다룬다. 한 번에 **한 자리**씩 계산한다.
- 이름은 "ASCII adjust"지만 `AAA`와 `AAS`는 AL의 하위 4비트(와 AF)만 보므로, 피연산자가 ASCII든 언팩이든 똑같이 동작한다. 반면 `AAM`과 `AAD`는 AL·AH의 값 전체로 곱셈·나눗셈을 하므로 반드시 **언팩 10진수**(상위 4비트가 0)를 써야 한다.
- 결과는 언팩 10진수로 나온다. 화면에 출력하려면 `OR 30h`로 ASCII로 바꾼다.
- 32비트 모드 전용이다. 64비트 모드에서는 쓸 수 없다([보충: 64비트 모드](#보충-64비트-모드에서-달라지는-점)).

### AAA 명령어

`AAA`(ASCII adjust after addition)는 `ADD`나 `ADC`가 AL에 남긴 2진 합을 한 자리 10진수로 고친다(AAA instruction adjusts the binary result of an ADD or ADC instruction). 인텔 문서에 적힌 동작은 다음과 같다.

```text
if (AL의 하위 4비트 > 9) 또는 (AF = 1) 이면
    AX = AX + 106h       ; AL에 6을 더하고 AH에 1을 더한다 (자리올림)
    AF = 1, CF = 1
아니면
    AF = 0, CF = 0
AL = AL AND 0Fh          ; 상위 4비트를 지운다
```

AL에 6을 더하는 이유는 4비트가 셀 수 있는 16과 10진수 한 자리가 담는 10의 차이가 6이기 때문이다. 하위 4비트가 10~15가 되었거나 하위 4비트에서 자리올림(AF = 1)이 생겼다면 6을 더해서 16진 자리올림을 10진 자리올림으로 바꾼다. OF, SF, ZF, PF는 정의되지 않는다.

```asm
mov ah,0
mov al,'8'              ; AX = 0038h
add al,'2'              ; AX = 006Ah
aaa                     ; AX = 0100h    (ASCII adjust result)
or  ax,3030h            ; AX = 3130h    (= '10', ASCII로 변환)
```

`6Ah`의 하위 4비트 A는 9보다 크다. 그래서 AX에 `106h`를 더해 `0170h`를 만들고, AL의 상위 4비트를 지워 `0100h`가 되었다. AH = 1은 자리올림, AL = 0은 일의 자리다. 즉 8 + 2 = **10**이다. 마지막으로 두 바이트 모두에 `30h`를 OR해서 `'1'`, `'0'` 문자로 바꿨다.

**AF가 필요한 경우(보충)**: `'9' + '9'` = `39h + 39h` = `72h`다. 하위 4비트는 2라서 9보다 크지 않지만, 9 + 9 = 18이 4비트를 넘으며 AF = 1이 되었다. `AAA`는 AF를 보고 이 경우도 보정한다.

```asm
mov ah,0
mov al,'9'
add al,'9'              ; AL = 72h    (하위 4비트는 2지만 AF = 1)
aaa                     ; AX = 0108h, CF = 1    (9 + 9 = 18)
```

`ADD`와 `AAA` 사이에 AF를 바꾸는 명령어(`ADD`, `SUB`, `INC`, `AND` 등)를 끼우면 보정이 틀어진다. `MOV`처럼 플래그를 건드리지 않는 명령어만 끼울 수 있다.

### AAA로 여러 자리 더하기 (Multibyte Addition Using AAA)

여러 자리 ASCII 수는 **가장 낮은 자리(문자열의 끝)부터** 한 자리씩 더하면서 자리올림을 다음 자리에 넘긴다. 슬라이드의 의사 코드다.

```text
esi (index) = length of first_number - 1
edi (index) = length of first_number
ecx = length of first_number
set carry value to 0
Loop
    acc = first_number[esi]
    add previous carry to acc
    save carry in carry1
    acc += second_number[esi]
    OR the carry with carry1
    sum[edi] = acc
    dec edi
Until ecx == 0
Store last carry digit in sum
```

교재의 ASCII_add 프로그램은 소수점이 있다고 가정한 15자리 수 두 개를 더한다.

```asm
; ASCII 덧셈 (교재의 ASCII_add.asm)
; 소수점의 위치가 정해져 있다고 가정한 숫자 문자열을 ASCII 연산으로 더한다.
INCLUDE Irvine32.inc

DECIMAL_OFFSET = 5                              ; 오른쪽에서 센 소수점 위치

.data
decimal_one BYTE "100123456789765"              ; 1001234567.89765
decimal_two BYTE "900402076502015"              ; 9004020765.02015
sum BYTE (SIZEOF decimal_one + 1) DUP(0),0

.code
main PROC
; 마지막 자리부터 시작한다.
    mov  esi,SIZEOF decimal_one - 1
    mov  edi,SIZEOF decimal_one
    mov  ecx,SIZEOF decimal_one
    mov  bh,0                                   ; 자리올림 값을 0으로

L1: mov  ah,0                                   ; 더하기 전에 AH를 0으로
    mov  al,decimal_one[esi]                    ; 첫 번째 수의 숫자
    add  al,bh                                  ; 이전 자리올림을 더한다
    aaa                                         ; 합을 보정한다 (AH = 자리올림)
    mov  bh,ah                                  ; 자리올림을 carry1에 저장
    or   bh,30h                                 ; ASCII로 바꾼다
    add  al,decimal_two[esi]                    ; 두 번째 수의 숫자를 더한다
    aaa                                         ; 합을 보정한다 (AH = 자리올림)
    or   bh,ah                                  ; carry1과 자리올림을 OR한다
    or   bh,30h                                 ; ASCII로 바꾼다
    or   al,30h                                 ; AL을 다시 ASCII로
    mov  sum[edi],al                            ; 합에 저장
    dec  esi                                    ; 한 자리 앞으로
    dec  edi
    loop L1
    mov  sum[edi],bh                            ; 마지막 자리올림을 저장

; 합을 문자열로 출력한다.
    mov  edx,OFFSET sum
    call WriteString
    call Crlf
    exit
main ENDP
END main
```

실행 결과:

```text
1000525533291780
```

100123456789765 + 900402076502015 = 1000525533291780이다. 15자리 두 수의 합이 16자리가 되었고, 맨 앞의 `1`은 마지막에 저장한 자리올림이다.

**한 자리를 더하는 과정을 따라가 보자.** 한 자리의 합은 "첫 번째 숫자 + 이전 자리올림 + 두 번째 숫자"다. 이를 두 번의 덧셈으로 나누고 덧셈마다 `AAA`를 한다.

1. `add al,bh` 다음 `aaa`: 첫 번째 숫자에 이전 자리올림을 더한다. 자리올림이 생기는 경우는 9 + 1뿐이고, 그러면 AL = 0, AH = 1이 된다. 그 자리올림을 BH(carry1)에 옮긴다.
2. `add al,decimal_two[esi]` 다음 `aaa`: 두 번째 숫자를 더한다. 여기서 자리올림이 생기면 `AAA`가 AH에 1을 더해 남긴다.
3. `or bh,ah`: 두 덧셈의 자리올림을 합친다. 1단계에서 자리올림이 생기면 AL = 0이 되므로 2단계에서는 자리올림이 생길 수 없다. 둘 중 많아야 하나만 1이므로 OR로 합쳐도 된다.

BH에는 자리올림을 `'0'`이나 `'1'` 문자(`30h`, `31h`)로 담는다. 다음 자리에서 `add al,bh`를 하면 ASCII 숫자에 `30h`나 `31h`가 더해져 AL의 상위 4비트가 엉망이 되지만, `AAA`는 하위 4비트와 AF만 보므로 결과가 맞는다. 첫 자리에서는 BH가 2진수 0이지만 같은 이유로 문제가 없다.

> [!NOTE]
> `DECIMAL_OFFSET = 5`는 선언만 하고 쓰지 않는다. 주석처럼 두 수를 소수점 아래 다섯 자리인 수로 보면 합은 10005255332.91780인데, 프로그램은 소수점 없이 숫자만 출력한다. [부록 F의 연습 5](#연습-5-소수점-넣어-출력하기)에서 이 상수로 소수점을 넣어 출력해 본다.

### AAS 명령어

`AAS`(ASCII adjust after subtraction)는 `SUB`나 `SBB`로 언팩 10진수(또는 ASCII 숫자)끼리 뺀 결과를 AL에 한 자리 10진수로 고친다(AAS instruction follows a SUB or SBB instruction that has subtracted one unpacked decimal value from another and stored the result in AL).

```text
if (AL의 하위 4비트 > 9) 또는 (AF = 1) 이면
    AX = AX - 6,  AH = AH - 1     ; 아래 자리에서 빌려 온 것을 갚는다
    AF = 1, CF = 1
아니면
    AF = 0, CF = 0
AL = AL AND 0Fh
```

```asm
.data
val1 BYTE '8'
val2 BYTE '9'
.code
mov  ah,0
mov  al,val1                ; AX = 0038h
sub  al,val2                ; AX = 00FFh
aas                         ; AX = FF09h, CF = 1
pushf                       ; CF를 저장한다
or   al,30h                 ; AX = FF39h
popf                        ; CF = 1    (CF를 복원한다)
```

8 − 9 = −1이다. `AAS`는 이것을 "자리내림(borrow) 1, 숫자 9"로 고친다. 10진수 뺄셈에서 윗자리에서 10을 빌려 와 18 − 9 = 9를 쓰는 것과 같다. 그래서 AL = 9, CF = 1이고, AH도 1이 줄어 `FFh`가 되었다.

`OR` 명령어는 CF를 0으로 만든다. 자리내림 정보를 다음 자리에서 써야 하므로 `PUSHF`/`POPF`로 CF를 지켰다. 슬라이드의 `pushf`/`popf`는 16비트 플래그(FLAGS)를 저장·복원하는 형식이라 32비트 프로그램에서는 `pushfd`/`popfd`를 쓰는 편이 자연스럽다. 상태 플래그는 하위 16비트에 다 들어 있으므로 결과는 같다.

### AAM 명령어

`AAM`(ASCII adjust after multiplication)은 `MUL`이 AL에 만든 2진 곱을 **두 자리 언팩 10진수**로 바꾼다(AAM instruction converts the binary product produced by MUL to unpacked decimal). 하는 일은 단순하다. **AL을 10으로 나눠 몫을 AH에, 나머지를 AL에** 넣는다.

```text
AH = AL / 10     ; 10의 자리
AL = AL MOD 10   ; 1의 자리
```

```asm
.data
AscVal BYTE 05h,06h
.code
mov bl,ascVal               ; 첫 번째 피연산자
mov al,[ascVal+1]           ; 두 번째 피연산자
mul bl                      ; AX = 001Eh    (5 × 6 = 30)
aam                         ; AX = 0300h    (3과 0)
```

- 곱하기 전의 두 피연산자는 반드시 **언팩 10진수**여야 한다. 변수 이름은 `AscVal`이지만 들어 있는 값은 ASCII(`35h`, `36h`)가 아니라 언팩(`05h`, `06h`)이다. ASCII 숫자였다면 `and al,0Fh`로 상위 4비트를 먼저 지워야 한다.
- 한 자리끼리의 곱은 최대 9 × 9 = 81이므로 AL 하나로 충분하고, `AAM`의 결과도 두 자리면 된다.
- 플래그는 SF, ZF, PF가 AL에 따라 정해지고 OF, AF, CF는 정의되지 않는다.

> [!NOTE]
> 슬라이드 코드는 `AscVal`로 선언하고 `ascVal`로 쓴다. MASM은 기본 설정에서 식별자의 대소문자를 구분하지 않으므로 어셈블은 된다. 하지만 `OPTION CASEMAP:NONE`을 켜면(Irvine32.inc에 주석으로 들어 있는 옵션이다) 정의되지 않은 기호 오류가 나므로, 선언과 사용의 대소문자를 맞추는 습관을 들이자.

`AAM`의 기계어는 `D4 0A`인데, 뒤의 `0A`(10)가 나누는 수다. 사실상 "AL을 10으로 나누기" 명령어이므로 곱셈과 상관없이 0~99의 2진수를 두 자릿수로 쪼갤 때도 쓸 수 있다(보충).

```asm
mov al,57
aam                         ; AX = 0507h
or  ax,3030h                ; AX = 3537h    ('5', '7')
```

### AAD 명령어

`AAD`(ASCII adjust before division)는 다른 셋과 달리 **연산 전에** 쓴다. AX에 든 두 자리 언팩 10진수(AH = 10의 자리, AL = 1의 자리)를 `DIV`가 쓸 수 있도록 2진수로 바꾼다(AAD instruction converts an unpacked decimal dividend in AX to binary in preparation for executing the DIV instruction).

```text
AL = AH × 10 + AL
AH = 0
```

```asm
.data
quotient  BYTE ?
remainder BYTE ?
.code
mov ax,0307h                ; 피제수 (언팩 10진수 37)
aad                         ; AX = 0025h    (2진수 37)
mov bl,5                    ; 제수
div bl                      ; AX = 0207h    (몫 7, 나머지 2)
mov quotient,al             ; quotient = 7
mov remainder,ah            ; remainder = 2
```

`AAD`의 기계어는 `D5 0A`이고, 역시 `0A`(10)가 곱하는 수다. 플래그는 SF, ZF, PF가 AL에 따라 정해지고 나머지는 정의되지 않는다.

---

## 7.6 팩 10진수 산술 (Packed Decimal Arithmetic)

**팩 10진수**(packed decimal, BCD: binary-coded decimal)는 한 바이트에 10진수 두 자리를 담는다. 상위 니블이 10의 자리, 하위 니블이 1의 자리다. 예를 들어 10진수 4536은 `4536h`로 저장한다. 16진수로 읽은 모양이 그대로 10진수가 되므로 출력하기 쉽고, 언팩 10진수보다 공간을 반만 쓴다.

팩 10진수에는 덧셈과 뺄셈의 보정 명령어 두 개만 있다. 곱셈과 나눗셈은 직접 지원하지 않는다. 둘 다 AL의 두 자리를 다루므로 여러 바이트로 된 수는 `ADC`/`SBB`로 자리올림을 이어 가며 한 바이트씩 처리한다.

### DAA 명령어

`DAA`(decimal adjust after addition)는 `ADD`나 `ADC`가 AL에 만든 2진 합을 팩 10진수로 고친다(DAA instruction converts a binary sum produced by ADD or ADC in AL to packed decimal format). 1의 자리와 10의 자리를 차례로 `AAA`처럼 보정한다고 보면 된다.

```text
old_AL = AL, old_CF = CF
if (AL의 하위 4비트 > 9) 또는 (AF = 1) 이면     ; 1의 자리 보정
    AL = AL + 6, AF = 1
아니면
    AF = 0
if (old_AL > 99h) 또는 (old_CF = 1) 이면        ; 10의 자리 보정
    AL = AL + 60h, CF = 1
아니면
    CF = 0
```

```asm
mov al,35h
add al,48h                  ; AL = 7Dh
daa                         ; AL = 83h    (adjusted result: 35 + 48 = 83)
```

`7Dh`의 하위 4비트 D가 9보다 크므로 6을 더해 `83h`가 되었다. 10의 자리는 보정할 필요가 없었으므로 CF = 0이다. 다음 두 예는 10의 자리 보정과 AF의 역할을 보여 준다(보충).

```asm
mov al,99h
add al,01h                  ; AL = 9Ah
daa                         ; AL = 00h, CF = 1    (99 + 1 = 100: 자리올림 1, 나머지 00)
mov al,28h
add al,19h                  ; AL = 41h    (하위 4비트는 1이지만 8 + 9에서 AF = 1)
daa                         ; AL = 47h    (28 + 19 = 47)
```

`DAA`의 플래그는 CF와 AF가 위 규칙대로, SF, ZF, PF는 결과에 따라 정해지고 OF는 정의되지 않는다.

### 예제: 팩 10진수 덧셈 (AddPacked)

두 바이트(네 자리) 팩 10진수 두 개를 더해 세 바이트 결과를 만든다. 낮은 바이트끼리 `ADD` + `DAA`, 높은 바이트끼리 `ADC` + `DAA`를 하고, 마지막 자리올림을 세 번째 바이트에 넣는다.

```asm
; 팩 10진수 덧셈 (교재의 AddPacked.asm)
INCLUDE Irvine32.inc

.data
packed_1 WORD 4536h
packed_2 WORD 7207h
sum      DWORD ?

.code
main PROC
; 합과 인덱스를 초기화한다.
    mov  sum,0
    mov  esi,0
; 낮은 바이트를 더한다.
    mov  al,BYTE PTR packed_1[esi]      ; AL = 36h
    add  al,BYTE PTR packed_2[esi]      ; AL = 3Dh
    daa                                 ; AL = 43h, CF = 0
    mov  BYTE PTR sum[esi],al
; 높은 바이트를 자리올림과 함께 더한다.
    inc  esi
    mov  al,BYTE PTR packed_1[esi]      ; AL = 45h
    adc  al,BYTE PTR packed_2[esi]      ; AL = B7h
    daa                                 ; AL = 17h, CF = 1
    mov  BYTE PTR sum[esi],al
; 마지막 자리올림이 있으면 더한다.
    inc  esi
    mov  al,0
    adc  al,0                           ; AL = 1
    mov  BYTE PTR sum[esi],al           ; sum = 00011743h
; 합을 16진수로 출력한다.
    mov  eax,sum
    call WriteHex
    call Crlf
    exit
main ENDP
END main
```

실행 결과:

```text
00011743
```

4536 + 7207 = 11743이고, 출력된 16진수가 그대로 10진수 답으로 읽힌다. 높은 바이트의 `45h + 72h = B7h`는 하위 4비트 7이 9 이하라서 1의 자리 보정은 없지만, `B7h`가 `99h`보다 크므로 `60h`를 더해 `17h`가 되고 CF = 1이 되었다. `INC`와 `MOV`는 CF를 바꾸지 않으므로 그 CF가 마지막 `adc al,0`까지 살아남는다.

### DAS 명령어

`DAS`(decimal adjust after subtraction)는 `SUB`나 `SBB`가 AL에 만든 2진 차를 팩 10진수로 고친다(DAS instruction converts the binary result of a SUB or SBB instruction in AL to packed decimal format). 규칙은 `DAA`에서 더하기를 빼기로 바꾼 것이다.

```text
old_AL = AL, old_CF = CF
if (AL의 하위 4비트 > 9) 또는 (AF = 1) 이면
    AL = AL - 6, AF = 1
아니면
    AF = 0
if (old_AL > 99h) 또는 (old_CF = 1) 이면
    AL = AL - 60h, CF = 1
아니면
    CF = 0
```

```asm
mov bl,48h
mov al,85h
sub al,bl                   ; AL = 3Dh
das                         ; AL = 37h    (adjusted result: 85 − 48 = 37)
```

빼는 수가 더 크면 CF = 1(자리내림)이 되고, AL에는 100에 대한 보수가 남는다(보충).

```asm
mov al,12h
sub al,34h                  ; AL = DEh, CF = 1
das                         ; AL = 78h, CF = 1    (12 − 34 = −22 → 자리내림 1, 100 − 22 = 78)
```

### 팩 10진수는 어디에 쓰이나 (보충)

- **부동소수점 장치(FPU)**: 3장에서 본 `TBYTE` 팩 BCD(18자리)를 `FBLD`, `FBSTP` 명령어로 읽고 쓸 수 있다. 큰 정수를 10진수 문자열로 바꿀 때 쓰인다.
- **하드웨어 시계**: PC의 실시간 시계(RTC) 칩은 날짜와 시각을 BCD로 저장하는 경우가 많다. 예를 들어 59분은 `59h`로 읽힌다.
- **금액 계산**: 0.1 같은 10진 소수는 2진 부동소수점으로 정확히 나타낼 수 없다. 10진수 자릿수를 그대로 계산하면 반올림 오차가 생기지 않는다. 오늘날에는 이런 계산을 대부분 소프트웨어(Java의 `BigDecimal`, C#의 `decimal` 등)로 처리한다.

이렇게 쓰임이 줄면서 x86-64의 64비트 모드에서는 `AAA`, `AAS`, `AAM`, `AAD`, `DAA`, `DAS`가 모두 빠졌다. 이 명령어들의 기계어는 64비트 모드에서 무효 명령어가 되었고, 필요하면 다른 명령어로 같은 보정을 직접 하면 된다.

---

## 보충: 64비트 모드에서 달라지는 점

교재 7장은 32비트 모드를 기준으로 설명한다. 같은 명령어를 64비트 모드(x86-64)에서 쓰면 다음이 달라진다.

| 항목 | 32비트 모드 | 64비트 모드 |
|---|---|---|
| 1-피연산자 `MUL`·`IMUL`의 가장 큰 형식 | EAX × r/m32 → EDX:EAX | RAX × r/m64 → **RDX:RAX** |
| `DIV`·`IDIV`의 가장 큰 형식 | EDX:EAX ÷ r/m32 → EAX, EDX | **RDX:RAX** ÷ r/m64 → RAX, RDX |
| 부호 확장 | `CBW`, `CWD`, `CDQ` | 추가로 `CDQE`(EAX → RAX), **`CQO`**(RAX → RDX:RAX) |
| 시프트·회전 횟수 | 하위 5비트(0~31) | 64비트 피연산자는 하위 **6비트**(0~63) |
| `SHLD`, `SHRD` | 16·32비트 | 64비트 피연산자도 가능 |
| 2·3-피연산자 `IMUL` | 즉시값은 최대 32비트 | 64비트 레지스터에 쓰면 32비트 즉시값을 부호 확장한다 |
| `AAA`, `AAS`, `AAM`, `AAD`, `DAA`, `DAS` | 사용 가능 | **사용 불가**(무효 명령어 예외 #UD) |

```asm
; 64비트 모드 예 (ml64)
mov  rax,1000000000000      ; 1조
mov  rbx,3
mul  rbx                    ; RDX:RAX = 3조 (RDX = 0)
mov  rax,-7
cqo                         ; RDX = FFFFFFFFFFFFFFFFh
mov  rbx,2
idiv rbx                    ; RAX = -3, RDX = -1
mov  rax,1
mov  cl,63
shl  rax,cl                 ; RAX = 8000000000000000h (63 < 64이므로 그대로 시프트)
```

32비트 모드의 `ADC`/`SBB` 사슬은 64비트 모드에서도 그대로 쓰인다. 다만 한 번에 64비트씩 처리하므로 128비트 덧셈이 `add rax, rcx` + `adc rdx, rbx` 두 줄이 된다.

---

## 부록 A. 명령어와 플래그 요약

### 명령어

| 명령어 | 형식 | 동작 |
|---|---|---|
| `SHL`, `SAL` | `SHL dest, imm8/CL` | 왼쪽으로 밀고 빈자리를 0으로. 2ⁿ을 곱한다 |
| `SHR` | `SHR dest, imm8/CL` | 오른쪽으로 밀고 빈자리를 0으로. 부호 없는 수를 2ⁿ으로 나눈다 |
| `SAR` | `SAR dest, imm8/CL` | 오른쪽으로 밀고 빈자리를 부호 비트로. 부호 있는 수를 2ⁿ으로 나눈다(−∞ 방향 내림) |
| `ROL`, `ROR` | `ROL dest, imm8/CL` | 회전. 밀려난 비트가 반대쪽 끝과 CF로 간다 |
| `RCL`, `RCR` | `RCL dest, imm8/CL` | CF를 포함한 회전. 이전 CF가 빈자리로 들어간다 |
| `SHLD` | `SHLD dest, reg, imm8/CL` | dest를 왼쪽으로 밀고 빈자리를 reg의 상위 비트로 채운다 |
| `SHRD` | `SHRD dest, reg, imm8/CL` | dest를 오른쪽으로 밀고 빈자리를 reg의 하위 비트로 채운다 |
| `MUL` | `MUL r/m8/16/32` | AX ← AL × src, DX:AX ← AX × src, EDX:EAX ← EAX × src (부호 없음) |
| `IMUL` (1-피연산자) | `IMUL r/m8/16/32` | `MUL`과 같은 자리에 부호 있는 곱 |
| `IMUL` (2-피연산자) | `IMUL reg, r/m` 또는 `IMUL reg, imm` | reg ← reg × src (목적지 크기로 잘림) |
| `IMUL` (3-피연산자) | `IMUL reg, r/m, imm` | reg ← src × imm (목적지 크기로 잘림) |
| `DIV` | `DIV r/m8/16/32` | AX ÷ src → AL 몫, AH 나머지 / DX:AX ÷ src → AX, DX / EDX:EAX ÷ src → EAX, EDX |
| `IDIV` | `IDIV r/m8/16/32` | `DIV`와 같은 자리에 부호 있는 몫(0 방향 버림)과 나머지(피제수의 부호) |
| `CBW`, `CWD`, `CDQ` | 피연산자 없음 | AL → AX, AX → DX:AX, EAX → EDX:EAX 부호 확장 |
| `CWDE` (보충) | 피연산자 없음 | AX → EAX 부호 확장 |
| `ADC` | `ADC dest, src` | dest ← dest + src + CF |
| `SBB` | `SBB dest, src` | dest ← dest − src − CF |
| `AAA`, `AAS` | 피연산자 없음 | `ADD`/`SUB` 뒤 AL을 한 자리 10진수로, 자리올림·내림은 AH와 CF로 |
| `AAM` | 피연산자 없음 | AH ← AL ÷ 10, AL ← AL mod 10 |
| `AAD` | 피연산자 없음 | AL ← AH × 10 + AL, AH ← 0 (`DIV` 전에) |
| `DAA`, `DAS` | 피연산자 없음 | `ADD`/`SUB` 뒤 AL을 두 자리 팩 10진수로 |
| `BSWAP` (보충) | `BSWAP reg32` | 레지스터의 바이트 순서를 뒤집는다 |

### 플래그

"결과"는 결과에 따라 0이나 1로 정해진다는 뜻이고, "—"는 바뀌지 않는다는 뜻이다.

| 명령어 | CF | OF | SF, ZF, PF | AF |
|---|---|---|---|---|
| `SHL`, `SAL`, `SHR`, `SAR` | 마지막으로 밀려난 비트 | 횟수 1일 때만 정의 | 결과 | 정의되지 않음 |
| `ROL`, `ROR`, `RCL`, `RCR` | 마지막으로 밀려난 비트 | 횟수 1일 때만 정의 | — | — |
| `SHLD`, `SHRD` | 마지막으로 밀려난 비트 | 횟수 1일 때만 정의 | 결과 | 정의되지 않음 |
| `MUL` | 상위 절반 ≠ 0이면 1 | CF와 같음 | 정의되지 않음 | 정의되지 않음 |
| `IMUL` | 의미 있는 비트를 잃으면 1 | CF와 같음 | 정의되지 않음 | 정의되지 않음 |
| `DIV`, `IDIV` | 정의되지 않음 | 정의되지 않음 | 정의되지 않음 | 정의되지 않음 |
| `CBW`, `CWD`, `CDQ`, `CWDE`, `BSWAP` | — | — | — | — |
| `ADC`, `SBB` | 결과 | 결과 | 결과 | 결과 |
| `AAA`, `AAS` | 보정했으면 1 | 정의되지 않음 | 정의되지 않음 | 보정했으면 1 |
| `AAM`, `AAD` | 정의되지 않음 | 정의되지 않음 | 결과 | 정의되지 않음 |
| `DAA`, `DAS` | 10의 자리 보정 시 1 | 정의되지 않음 | 결과 | 1의 자리 보정 시 1 |

시프트·회전에서 횟수(하위 5비트)가 0이면 어떤 플래그도 바뀌지 않는다. "IMUL"의 "의미 있는 비트를 잃으면"은 1-피연산자 형식에서는 "상위 절반이 하위 절반의 부호 확장이 아니면", 2·3-피연산자 형식에서는 "잘린 결과가 참값과 다르면"이라는 뜻이다.

---

## 부록 B. 곱셈과 나눗셈을 다른 명령어로 하기

곱셈 명령어가 시프트와 덧셈으로 대신할 수 있듯이([7.2](#2진-곱셈-binary-multiplication)), 나눗셈도 시프트와 뺄셈으로 할 수 있다. 반대로 나눗셈을 곱셈으로 바꾸는 방법도 있다. 두 방법 모두 이 장의 명령어를 응용한 것이고, 컴파일러와 CPU 내부에서 실제로 쓰인다.

### B.1 시프트와 뺄셈으로 나누기

손으로 하는 긴 나눗셈(long division)을 2진수로 하면 각 자리에서 할 일은 "제수를 뺄 수 있는가?" 하나뿐이다. 몫의 각 자리는 0 아니면 1이기 때문이다.

```text
remainder = 0
피제수의 비트를 최상위부터 하나씩 꺼내면서:
    remainder = remainder × 2 + 꺼낸 비트     ; 다음 자리를 내려 받는다
    if remainder ≥ divisor:
        remainder = remainder − divisor
        몫 비트 = 1
    else:
        몫 비트 = 0
```

`SHL`로 피제수의 최상위 비트를 CF로 밀어내고 `RCL`로 그 비트를 나머지에 받아 넣으면 된다. 피제수를 왼쪽으로 밀면 EAX의 최하위 비트가 비므로, 그 자리에 몫 비트를 차곡차곡 쌓으면 32번 반복한 뒤 EAX에 몫이 남는다. 레지스터 하나를 피제수와 몫이 함께 쓰는 셈이다.

```asm
; 시프트와 뺄셈으로 나누기 (부호 없는 32비트)
INCLUDE Irvine32.inc

.data
tests  DWORD 1000,7, 0FFFFFFFFh,80000001h, 123456789,10, 5,9
msgDiv BYTE " / ",0
msgEq  BYTE " = ",0
msgRem BYTE " rem ",0

.code
main PROC
    mov  esi,OFFSET tests
    mov  ecx,LENGTHOF tests / 2         ; 시험할 (피제수, 제수) 쌍의 수
L1: mov  eax,[esi]                      ; 피제수
    mov  ebx,[esi+4]                    ; 제수
    call WriteDec
    mov  edx,OFFSET msgDiv
    call WriteString
    xchg eax,ebx
    call WriteDec
    xchg eax,ebx
    mov  edx,OFFSET msgEq
    call WriteString
    call ShiftDivide                    ; EAX = 몫, EDX = 나머지
    call WriteDec
    mov  eax,edx
    mov  edx,OFFSET msgRem
    call WriteString
    call WriteDec
    call Crlf
    add  esi,8
    loop L1
    exit
main ENDP

;--------------------------------------------------------
ShiftDivide PROC
;
; 시프트와 뺄셈으로 부호 없는 32비트 나눗셈을 한다.
; Receives: EAX = 피제수, EBX = 제수(0이 아니어야 한다)
; Returns:  EAX = 몫, EDX = 나머지
;--------------------------------------------------------
    push ecx
    mov  edx,0                          ; 나머지 = 0
    mov  ecx,32                         ; 피제수의 비트 수
SD1: shl  eax,1                         ; 피제수의 최상위 비트 → CF
    rcl  edx,1                          ; CF → 나머지의 최하위 비트
    jc   SD2                            ; 나머지가 32비트를 넘었다면 제수보다 크다
    cmp  edx,ebx
    jb   SD3                            ; 나머지 < 제수이면 몫 비트는 0
SD2: sub  edx,ebx                       ; 나머지에서 제수를 뺀다
    inc  eax                            ; 몫 비트 = 1 (SHL이 비워 둔 최하위 비트)
SD3: loop SD1
    pop  ecx
    ret
ShiftDivide ENDP
END main
```

실행 결과:

```text
1000 / 7 = 142 rem 6
4294967295 / 2147483649 = 1 rem 2147483646
123456789 / 10 = 12345678 rem 9
5 / 9 = 0 rem 5
```

`jc SD2`는 제수가 2³¹ 이상일 때를 위한 것이다. 이때는 나머지를 왼쪽으로 밀면서 33번째 비트가 CF로 나갈 수 있는데, 그렇다면 나머지는 2³² 이상이므로 제수보다 당연히 크다. 32비트 뺄셈은 2³²를 법으로 계산하므로 빠져나간 비트를 신경 쓰지 않고 그냥 빼도 정확한 나머지가 남는다. 이런 방식을 복원형 나눗셈(restoring division)이라고 한다. 초기 CPU도 마이크로코드로 몫을 한 비트씩 구하는 이런 방식의 나눗셈을 했기 때문에 나눗셈 명령어가 특히 느렸다.

### B.2 상수로 나누기를 곱셈으로 바꾸기

`DIV`는 곱셈보다 몇 배 느리다. 그래서 컴파일러는 **상수로 나누는** 코드를 "곱하고 시프트하기"로 바꾼다. x ÷ 10은 x × (2³⁵ ÷ 10) ÷ 2³⁵와 같으므로, 2³⁵ ÷ 10을 올림한 정수 `0CCCCCCCDh`(3,435,973,837)를 곱한 다음 곱의 상위 32비트(EDX)를 3비트 더 오른쪽으로 밀면 된다. `MUL`이 만든 EDX는 이미 곱을 2³²로 나눈 값이기 때문이다.

```asm
mov  eax,4294967295         ; x (32비트 최댓값)
mov  ecx,eax                ; x를 보관한다
mov  edx,0CCCCCCCDh         ; ⌈2³⁵ ÷ 10⌉
mul  edx                    ; EDX:EAX = x × 0CCCCCCCDh
shr  edx,3                  ; EDX = 429496729    (몫: 곱 ÷ 2³⁵)
lea  eax,[edx+edx*4]        ; EAX = 2147483645   (몫 × 5)
add  eax,eax                ; EAX = 4294967290   (몫 × 10)
sub  ecx,eax                ; ECX = 5            (나머지 = x − 몫 × 10)
```

곱하는 수가 2³⁵ ÷ 10보다 아주 조금 크기 때문에 결과가 참값보다 커질 위험이 있지만, 그 오차가 1보다 작게 유지되어 **모든 32비트 x에 대해 정확**하다는 것이 증명되어 있다(Granlund & Montgomery, 1994). 이 문서를 만들면서 32비트 x 전체(2³²개)에 대해 이 식이 x ÷ 10과 같은지 프로그램으로 확인했고, 다른 값은 하나도 없었다. 나머지는 `몫 × 10`을 `LEA`와 `ADD`로 만들어 원래 값에서 빼서 구했다.

실제 컴파일러도 이렇게 번역한다. `unsigned f(unsigned x) { return x / 10; }`를 GCC로 32비트 최적화 컴파일(`gcc -m32 -O2 -masm=intel`)하면 다음 코드가 나온다. `-858993459`는 `0CCCCCCCDh`를 부호 있는 수로 읽은 값이고, 마지막 결과가 EAX로 가는 것만 다르다.

```text
f:
    mov  eax, -858993459
    mul  DWORD PTR [esp+4]
    mov  eax, edx
    shr  eax, 3
    ret
```

---

## 부록 C. 자주 하는 실수와 오류 메시지

### 어셈블할 때 걸리는 오류

MASM(ml.exe)에서는 대개 아래의 두 오류 중 하나가 난다. `error A2070: invalid instruction operands`(피연산자 조합이 그 명령어에 없다)와 `error A2022: instruction operands must be the same size`(피연산자 크기가 다르다)다.

| 잘못된 코드 | 오류 | 이유와 고치는 방법 |
|---|---|---|
| `shl eax, bl` | A2070 | 시프트 횟수는 CL이나 8비트 즉시값만 된다. `mov cl, bl` 다음 `shl eax, cl` |
| `shl eax, ecx` | A2070 | 위와 같다. ECX가 아니라 CL을 쓴다 |
| `mul 10`, `div 4` | A2070 | `MUL`, `DIV`, 1-피연산자 `IMUL`은 즉시값을 받지 않는다. 레지스터에 넣고 곱하거나, 2·3-피연산자 `IMUL`을 쓴다 |
| `shld eax, var1, 4` | A2070 | `SHLD`/`SHRD`의 두 번째 피연산자(소스)는 레지스터여야 한다 |
| `imul bl, 2` | A2070 | 2·3-피연산자 `IMUL`은 16·32비트 레지스터만 목적지로 받는다 |
| `imul eax, ebx, ecx` | A2070 | 3-피연산자 형식의 세 번째 피연산자는 즉시값이어야 한다 |
| `adc eax, bx` | A2022 | `ADC`/`SBB`도 `ADD`처럼 두 피연산자의 크기가 같아야 한다 |
| `aaa`, `daa` (ml64) | 오류 | 64비트 모드에는 10진 보정 명령어가 없다 |

### 어셈블은 되지만 틀리게 동작하는 실수

- **`DIV` 전에 상위 절반을 비우지 않았다.** EDX(또는 DX, AH)에 남은 값이 피제수의 일부가 되어 몫이 틀리거나 나눗셈 오버플로가 난다. `mov edx,0`을 습관처럼 넣자.
- **부호 없는 `DIV` 앞에 `CDQ`를 썼다.** EAX가 `80000000h` 이상이면 EDX가 `FFFFFFFFh`가 되어 나눗셈 오버플로가 난다. 반대로 `IDIV` 앞에 `CDQ`를 빠뜨려도 틀린다.
- **`MUL`이 EDX를 바꾼다는 것을 잊었다.** 곱이 작아도 32비트 `MUL`은 EDX를 0으로 덮어쓴다. EDX를 포인터나 카운터로 쓰고 있었다면 값이 사라진다.
- **2·3-피연산자 `IMUL` 뒤에 OF를 확인하지 않았다.** 곱이 잘려도 아무 경고 없이 다음 명령어로 넘어간다. 또 부호 없는 수의 넘침은 이 OF로 알 수 없다.
- **음수를 `SAR`로 나누면서 C의 `/`와 같다고 생각했다.** `SAR`은 −∞ 방향으로 내리고 `IDIV`는 0 방향으로 버린다. −7 SAR 1 = −4, −7 ÷ 2 = −3.
- **여러 비트를 시프트한 뒤 OF를, 회전한 뒤 ZF를 믿었다.** 횟수가 1보다 크면 OF는 정의되지 않고, 회전은 ZF·SF를 바꾸지 않는다.
- **시프트 횟수가 32 이상이면 모두 밀려 0이 된다고 생각했다.** 횟수는 하위 5비트만 쓰이므로 `shl eax,32`는 아무것도 바꾸지 않고, `shl eax,33`은 1비트 시프트다.
- **`ADC`/`SBB` 사슬 사이에서 CF를 망가뜨렸다.** 포인터를 `ADD`로 옮기거나 `CMP`로 비교하면 CF가 바뀐다. `INC`, `DEC`, `LEA`, `MOV`, `LOOP`는 CF를 바꾸지 않는다. 그리고 첫 `ADC` 앞에 `CLC`를 빠뜨리지 말자.
- **몫이 목적지에 들어가지 않는 나눗셈을 했다.** 8비트 `DIV`의 몫은 255를 넘을 수 없다. 큰 피제수는 32비트 나눗셈으로 나누자. 부호 있는 나눗셈에서는 가장 작은 음수를 −1로 나누는 것도 오버플로다.
- **ASCII 숫자를 그대로 `MUL`한 뒤 `AAM`했다.** `AAM`과 `AAD`는 언팩 10진수만 다룬다. `and al,0Fh`로 상위 4비트를 먼저 지우자.
- **`ADD`와 `AAA`(또는 `DAA`) 사이에 다른 연산을 끼웠다.** 보정 명령어는 직전 덧셈이 남긴 AF와 CF를 보고 동작한다. 그 사이에는 `MOV`처럼 플래그를 건드리지 않는 명령어만 둔다.
- **ECX를 반복 횟수로 쓰면서 CL을 시프트 횟수로 썼다.** CL은 ECX의 일부다. `push ecx`/`pop ecx`로 지키거나 즉시값 횟수를 쓰자.
- **자정을 넘겨 `GetMseconds`로 시간을 쟀다.** 끝 시각이 시작 시각보다 작아져 걸린 시간이 엉터리가 된다.

---

## 부록 D. 핵심 용어 정리

| 용어 | 뜻 |
|---|---|
| 시프트 (shift) | 비트를 한 방향으로 밀어 한쪽 끝의 비트를 내보내고 반대쪽 끝을 채우는 연산 |
| 논리 시프트 (logical shift) | 빈자리를 0으로 채우는 시프트. 부호 없는 수의 곱셈·나눗셈에 해당한다 |
| 산술 시프트 (arithmetic shift) | 오른쪽으로 밀 때 빈자리를 부호 비트로 채우는 시프트. 부호 있는 수의 나눗셈에 해당한다 |
| 회전 (rotate) | 밀려난 비트를 반대쪽 끝으로 다시 넣는 시프트. 비트를 잃지 않는다 |
| CF를 통한 회전 (rotate through carry) | `RCL`, `RCR`. CF를 피연산자의 한 비트처럼 끼워 회전한다 |
| 이중 정밀도 시프트 (double-precision shift) | `SHLD`, `SHRD`. 두 피연산자를 이어 붙인 것처럼 시프트한다 |
| 시프트 횟수 (count) | CL이나 8비트 즉시값. 하위 5비트(64비트 피연산자는 6비트)만 쓰인다 |
| 비트 필드 (bit field) | 정수 안의 연속된 몇 비트에 담은 값. 시프트와 `AND`·`OR`로 꺼내고 넣는다 |
| 곱해지는 수 / 곱하는 수 (multiplicand / multiplier) | `MUL`의 AL·AX·EAX / 피연산자로 적는 값 |
| 피제수 / 제수 (dividend / divisor) | 나뉘는 수(AX, DX:AX, EDX:EAX) / 나누는 수(피연산자) |
| 몫 / 나머지 (quotient / remainder) | 나눗셈 결과. AL·AX·EAX와 AH·DX·EDX에 나온다 |
| 부호 확장 (sign extension) | 부호 비트를 상위 비트 전체에 복사해 값을 유지한 채 넓히는 것. `CBW`, `CWD`, `CDQ` |
| 나눗셈 오버플로 (divide overflow) | 몫이 목적지에 들어가지 않는 경우. 0으로 나누기와 함께 #DE 예외를 일으킨다 |
| 나눗셈 오류 예외 (#DE, divide error) | CPU가 나눗셈 오버플로나 0으로 나누기를 만났을 때 일으키는 예외. 프로그램이 멈춘다 |
| 확장 정밀도 연산 (extended-precision arithmetic) | 레지스터보다 큰 정수를 여러 조각으로 나누어 `ADC`/`SBB`로 계산하는 것 |
| 자리올림 / 자리내림 (carry / borrow) | 덧셈에서 위 자리로 넘기는 1 / 뺄셈에서 위 자리에서 빌려 오는 1. 둘 다 CF에 남는다 |
| ASCII 10진수 (ASCII decimal) | 숫자를 문자 `'0'`~`'9'`(`30h`~`39h`)로 한 바이트에 하나씩 저장한 형태 |
| 언팩 10진수 (unpacked decimal) | 숫자 하나를 0~9의 값으로 한 바이트에 저장한 형태. 상위 4비트가 0이다 |
| 팩 10진수, BCD (packed decimal) | 한 바이트에 10진수 두 자리를 니블 단위로 저장한 형태 |
| 10진 보정 (decimal adjust) | 2진 연산 결과를 10진수 형태로 고치는 것. `AAA`, `AAS`, `AAM`, `AAD`, `DAA`, `DAS` |
| 보조 캐리 (AF, auxiliary carry) | 하위 4비트에서 생긴 자리올림·내림. 10진 보정 명령어가 참고한다 |
| 강도 감소 (strength reduction) | 비싼 연산을 싼 연산으로 바꾸는 최적화. 곱셈을 시프트·`LEA`로, 나눗셈을 곱셈으로 바꾼다 |

---

## 부록 E. 복습 문제

교재 7.9절(Review Questions and Exercises)과 같은 유형의 문제를 직접 만들었다. **단답형**은 코드의 결과를 예측하는 문제, **알고리즘 작성**은 짧은 코드를 직접 써 보는 문제다. 각 문제의 **정답 보기**를 누르면 답과 해설이 펼쳐진다. 답에 나오는 값은 모두 실행해서 확인했다.

### 단답형 (Short Answer)

**Q1.** AL = `0D4h`(`11010100b`)일 때 다음 명령어를 **각각** 실행하면 AL과 CF는 어떻게 되는가?
(a) `shr al,1` (b) `sar al,1` (c) `sar al,4` (d) `rol al,1` (e) `ror al,3`

<details>
<summary>정답 보기</summary>

```asm
mov al,0D4h
shr al,1                ; AL = 01101010b, CF = 0    (a) 6Ah
mov al,0D4h
sar al,1                ; AL = 11101010b, CF = 0    (b) EAh
mov al,0D4h
sar al,4                ; AL = 11111101b, CF = 0    (c) FDh
mov al,0D4h
rol al,1                ; AL = 10101001b, CF = 1    (d) A9h
mov al,0D4h
ror al,3                ; AL = 10011010b, CF = 1    (e) 9Ah
```

(c)에서 밀려 나가는 네 비트는 `0100`이고, 마지막으로 나간 비트(원래의 3번 비트)가 0이므로 CF = 0이다. 부호 있는 수로 보면 −44 ÷ 16 = −2.75를 −∞ 방향으로 내린 −3(`FDh`)이다. (e)에서는 하위 세 비트 `100`이 상위로 돌아가고, 마지막으로 돈 비트 1이 CF에 복사된다.

</details>

**Q2.** 다음 두 코드를 실행한 뒤 AL과 CF는?

```asm
clc
mov al,0D4h
rcl al,1
stc
mov al,0D4h
rcr al,1
```

<details>
<summary>정답 보기</summary>

```asm
clc
mov al,0D4h
rcl al,1                ; AL = 10101000b, CF = 1    (A8h: 이전 CF 0이 최하위로)
stc
mov al,0D4h
rcr al,1                ; AL = 11101010b, CF = 0    (EAh: 이전 CF 1이 최상위로)
```

</details>

**Q3.** `SHL`과 `SAL`은 무엇이 다른가? `SHR`과 `SAR`은?

<details>
<summary>정답 보기</summary>

`SHL`과 `SAL`은 이름만 다르고 기계어까지 같은 명령어다. 왼쪽 시프트는 빈자리(최하위 비트)를 항상 0으로 채우면 되기 때문이다. `SHR`과 `SAR`은 다르다. `SHR`은 최상위 비트를 0으로, `SAR`은 원래의 부호 비트로 채운다. 그래서 `SHR`은 부호 없는 나눗셈, `SAR`은 부호 있는 나눗셈에 쓴다.

</details>

**Q4.** `mov al,40h` 다음에 `shl al,2`를 하면 OF는 1인가? 이 OF를 믿어도 되는가?

<details>
<summary>정답 보기</summary>

믿으면 안 된다. 시프트·회전 명령어의 OF는 **횟수가 1일 때만** 정의된다. 횟수가 2 이상이면 OF는 정의되지 않으므로 CPU마다 값이 다를 수 있다. 부호 있는 오버플로를 확인하려면 `shl al,1`을 두 번 하면서 매번 OF를 확인하거나, 곱셈 명령어(`IMUL`)를 써야 한다. 참고로 이 경우 AL은 `00h`가 되고 CF = 1이다(두 번째로 밀려난 비트가 원래의 6번 비트 1이다).

</details>

**Q5.** `shl eax,bl`은 어셈블되지 않는다. 이유와 고치는 방법은? 그리고 `mov cl,40` 다음 `shl eax,cl`은 몇 비트를 시프트하는가?

<details>
<summary>정답 보기</summary>

시프트 횟수는 **CL이나 8비트 즉시값**만 쓸 수 있다. `mov cl,bl` 다음 `shl eax,cl`로 고친다. CPU는 횟수의 하위 5비트만 쓰므로 40(`101000b`)은 8(`01000b`)로 처리되어 8비트를 시프트한다.

```asm
mov eax,1
mov cl,40
shl eax,cl              ; EAX = 00000100h    (40 AND 31 = 8)
```

</details>

**Q6.** 다음 두 곱셈의 결과(DX:AX)와 CF·OF는?

```asm
mov ax,7FFFh
mov bx,2
mul bx
mov ax,7FFFh
mov bx,2
imul bx
```

<details>
<summary>정답 보기</summary>

```asm
mov ax,7FFFh
mov bx,2
mul bx                  ; DX:AX = 0000FFFEh, CF = 0, OF = 0
mov ax,7FFFh
mov bx,2
imul bx                 ; DX:AX = 0000FFFEh, CF = 1, OF = 1
```

곱(65,534)은 두 경우 모두 같다. 부호 없는 수로는 상위 절반 DX가 0이므로 AX만으로 충분해 CF = 0이다. 부호 있는 수로는 65,534가 16비트 부호 있는 범위(최대 32,767)를 넘는다. AX = `FFFEh`만 보면 −2가 되어 버리므로, DX가 AX의 부호 확장(`FFFFh`)이 아니라는 뜻으로 CF = OF = 1이다.

</details>

**Q7.** 다음 나눗셈을 실행한 뒤 몫과 나머지가 들어 있는 레지스터와 그 값은?
(a) `mov dx,0` / `mov ax,222h` / `mov cx,10h` / `div cx`
(b) `mov ax,63h` / `mov bl,10h` / `div bl`

<details>
<summary>정답 보기</summary>

```asm
mov dx,0
mov ax,222h
mov cx,10h
div cx                  ; AX = 0022h, DX = 0002h    (a) 546 ÷ 16 = 34 나머지 2
mov ax,63h
mov bl,10h
div bl                  ; AL = 06h, AH = 03h        (b) 99 ÷ 16 = 6 나머지 3
```

16진수로 16으로 나누는 것은 맨 끝 자릿수를 떼어 내는 것과 같다. 그래서 몫은 끝 자리를 뗀 수, 나머지는 끝 자리다.

</details>

**Q8.** 다음 코드를 실행한 뒤 AX와 DX는? 10진수로 답하라.

```asm
mov  ax,-25
cwd
mov  bx,4
idiv bx
```

<details>
<summary>정답 보기</summary>

```asm
mov  ax,-25
cwd                     ; DX = FFFFh
mov  bx,4
idiv bx                 ; AX = -6, DX = -1
```

−25 ÷ 4 = −6.25이고, `IDIV`는 0 방향으로 버리므로 몫은 −6이다. 나머지는 피제수와 부호가 같아 −1이다(4 × (−6) − 1 = −25). 같은 값을 `sar ax,2`로 나누면 −∞ 방향으로 내려 −7이 된다.

</details>

**Q9.** 다음 코드는 왜 프로그램을 멈추게 하는가? 같은 계산을 안전하게 하려면 어떻게 고쳐야 하는가?

```asm
mov ax,0FFFFh
mov bl,1
div bl                  ; 몫은 어디에 들어가야 하는가?
```

<details>
<summary>정답 보기</summary>

8비트 `DIV`의 몫은 AL에 들어가야 한다. 65,535 ÷ 1 = 65,535는 AL(최대 255)에 들어가지 않으므로 **나눗셈 오버플로**(#DE)가 나서 프로그램이 멈춘다. 몫이 커질 수 있으면 더 큰 나눗셈을 쓴다.

```asm
mov ax,0FFFFh
mov bl,1
div bl                  ; #DE: 몫 65,535가 AL에 들어가지 않는다
```

```asm
mov dx,0                ; 16비트 나눗셈으로 바꾼다
mov ax,0FFFFh
mov bx,1
div bx                  ; AX = 0FFFFh, DX = 0
```

</details>

**Q10.** `DIV` 바로 뒤에서 `jz`로 "몫이 0이면 점프"할 수 있는가?

<details>
<summary>정답 보기</summary>

할 수 없다. `DIV`와 `IDIV` 뒤의 상태 플래그는 **모두 정의되지 않는다.** 몫을 검사하려면 `test eax,eax`(또는 `cmp eax,0`)로 플래그를 다시 만든 다음 `jz`를 써야 한다.

</details>

**Q11.** `CBW`, `CWD`, `CDQ`는 각각 어느 레지스터를 바꾸는가? `CWD`와 `CWDE`의 차이는?

<details>
<summary>정답 보기</summary>

`CBW`는 AH, `CWD`는 DX, `CDQ`는 EDX를 바꾼다(각각 AL, AX, EAX의 부호 비트로 채운다). `CWD`는 AX를 **DX:AX**(두 레지스터)로, `CWDE`는 AX를 **EAX**(한 레지스터)로 확장한다. 나눗셈 준비에는 `CWD`, 단순히 32비트로 넓힐 때는 `CWDE`나 `MOVSX`를 쓴다.

</details>

**Q12.** 다음 코드를 실행한 뒤 EDX:EAX는? 이 코드가 하는 일은?

```asm
mov eax,0FFFFFFFFh
mov edx,0
add eax,1
adc edx,0
```

<details>
<summary>정답 보기</summary>

```asm
mov eax,0FFFFFFFFh
mov edx,0
add eax,1               ; EAX = 0, CF = 1
adc edx,0               ; EDX:EAX = 0000000100000000h
```

EDX:EAX를 하나의 64비트 정수로 보고 1을 더했다. 하위 절반에서 생긴 자리올림이 `ADC`로 상위 절반에 더해졌다.

</details>

**Q13.** 여러 바이트로 된 정수를 `ADC` 루프로 더할 때 루프 앞에 `CLC`가 필요한 이유는? 그리고 루프 안에서 포인터를 `add esi,1` 대신 `inc esi`로 옮기면 무엇이 좋은가?

<details>
<summary>정답 보기</summary>

루프 안에서는 첫 바이트도 `ADC`로 더하므로, 첫 바이트에 엉뚱한 자리올림이 더해지지 않게 CF를 0으로 만들어 두어야 한다. `ADD`는 CF를 바꾸지만 `INC`는 CF를 바꾸지 않으므로, `INC`로 포인터를 옮기면 `ADC`가 만든 자리올림이 다음 반복까지 살아남는다. 그래서 `PUSHFD`/`POPFD`로 CF를 저장할 필요가 없어진다([7.4](#더-간단하게-cf를-건드리지-않는-명령어로-포인터-옮기기-보충)).

</details>

**Q14.** 다음 코드를 실행한 뒤 AX는? 이것을 문자로 읽으면?

```asm
mov ah,0
mov al,'7'
add al,'6'
aaa
or  ax,3030h
```

<details>
<summary>정답 보기</summary>

```asm
mov ah,0
mov al,'7'
add al,'6'              ; AL = 6Dh
aaa                     ; AX = 0103h, CF = 1
or  ax,3030h            ; AX = 3133h
```

AH = `31h`(`'1'`), AL = `33h`(`'3'`)이므로 `"13"`이다. 7 + 6 = 13이 두 자리 ASCII로 만들어졌다.

</details>

**Q15.** 다음 두 코드를 실행한 뒤 AL과 CF는? 결과를 10진수로 읽어라.

```asm
mov al,56h
add al,92h
daa
mov al,42h
sub al,19h
das
```

<details>
<summary>정답 보기</summary>

```asm
mov al,56h
add al,92h              ; AL = E8h
daa                     ; AL = 48h, CF = 1    (56 + 92 = 148: 자리올림 1, 나머지 48)
mov al,42h
sub al,19h              ; AL = 29h    (하위 4비트에서 빌려 와서 AF = 1)
das                     ; AL = 23h, CF = 0    (42 − 19 = 23)
```

`E8h`의 하위 4비트 8은 9 이하이고 AF = 0이라 1의 자리는 그대로지만, `E8h`가 `99h`보다 크므로 `60h`를 더하고 CF = 1이 된다. 뺄셈에서는 2 − 9에서 빌려 왔으므로 AF = 1이고, `DAS`가 6을 빼서 `23h`가 되었다.

</details>

**Q16.** 다음 코드를 실행한 뒤 AX는?

```asm
mov al,9
mov bl,8
mul bl
aam
mov ax,0408h
aad
mov bl,6
div bl
```

<details>
<summary>정답 보기</summary>

```asm
mov al,9
mov bl,8
mul bl                  ; AX = 0048h    (72)
aam                     ; AX = 0702h    (7과 2)
mov ax,0408h            ; 언팩 10진수 48
aad                     ; AX = 0030h    (2진수 48)
mov bl,6
div bl                  ; AX = 0008h    (몫 8, 나머지 0)
```

</details>

**Q17.** 2·3-피연산자 `IMUL`이 부호 없는 수의 곱에도 쓰일 수 있는 이유와, 그때 조심해야 할 점은?

<details>
<summary>정답 보기</summary>

곱의 **하위 절반**은 부호가 있든 없든 같은 비트가 나오기 때문이다. 2·3-피연산자 `IMUL`은 하위 절반만 남기므로 부호 없는 수의 곱도 비트가 똑같다. 다만 OF와 CF는 **부호 있는** 오버플로를 기준으로 정해진다. 부호 없는 곱이 32비트에 들어가도 OF가 1이 될 수 있고(예: 2,000,000,000 × 2), 그 반대도 있다. 부호 없는 넘침을 확인해야 하면 `MUL`과 CF를 쓴다.

</details>

**Q18.** 64비트 모드에서 `AAA`나 `DAA`를 쓰면 어떻게 되는가?

<details>
<summary>정답 보기</summary>

64비트 모드에서는 이 명령어들의 기계어가 무효로 정해져 있어 실행하면 무효 명령어 예외(#UD)가 난다. 어셈블러(ml64)도 받아 주지 않는다. 64비트 코드에서 10진수를 다루려면 일반 산술 명령어와 시프트, `AND`/`OR`로 직접 보정해야 한다.

</details>

### 알고리즘 작성 (Algorithm Workbench)

**W1.** EBX의 최하위 비트를 EAX의 최상위 비트로 넣으면서 EAX를 오른쪽으로 1비트 시프트하라. 두 가지 방법으로 써 보라.

<details>
<summary>정답 보기</summary>

```asm
mov  eax,12345678h
mov  ebx,1
shr  ebx,1              ; 방법 1: EBX의 최하위 비트 → CF
rcr  eax,1              ; EAX = 891A2B3Ch    (CF → EAX의 최상위 비트)
mov  eax,12345678h
mov  ebx,1
shrd eax,ebx,1          ; EAX = 891A2B3Ch    (방법 2: 한 명령어, EBX는 그대로)
```

방법 1은 EBX도 시프트되어 바뀌지만, 방법 2의 `SHRD`는 소스(EBX)를 바꾸지 않는다.

</details>

**W2.** 곱셈 명령어를 쓰지 않고 EAX에 24를 곱하라.

<details>
<summary>정답 보기</summary>

24 = 16 + 8이므로 EAX × 16과 EAX × 8을 더한다. `LEA`로 3을 곱한 뒤 8을 곱해도 된다(24 = 3 × 8).

```asm
mov eax,25
mov ebx,eax
shl eax,4               ; EAX = 400    (× 16)
shl ebx,3               ; EBX = 200    (× 8)
add eax,ebx             ; EAX = 600
mov ecx,25
lea ecx,[ecx+ecx*2]     ; ECX = 75     (× 3)
shl ecx,3               ; ECX = 600    (× 8)
```

</details>

**W3.** EBX의 값(부호 없음)을 나눗셈 명령어 없이 4로 나누어 몫은 EBX에, 나머지는 ECX에 넣어라.

<details>
<summary>정답 보기</summary>

```asm
mov ebx,103
mov ecx,ebx
and ecx,3               ; ECX = 3     (나머지: 하위 2비트)
shr ebx,2               ; EBX = 25    (몫)
```

</details>

**W4.** EAX의 상위 16비트와 하위 16비트를 맞바꿔라. 또 EAX의 네 바이트 순서를 거꾸로 뒤집어라.

<details>
<summary>정답 보기</summary>

```asm
mov   eax,12345678h
ror   eax,16            ; EAX = 56781234h    (절반끼리 교환, rol eax,16도 같다)
mov   eax,12345678h
bswap eax               ; EAX = 78563412h    (바이트 순서 반전)
```

</details>

**W5.** `MOVSX`, `CBW` 같은 부호 확장 명령어를 쓰지 않고 AL의 값을 EBX로 부호 확장하라.

<details>
<summary>정답 보기</summary>

AL을 EBX의 최상위 바이트로 올린 다음 `SAR`로 24비트 내린다. 내려오는 동안 부호 비트가 위를 채운다.

```asm
mov   al,9Bh            ; −101
movzx ebx,al            ; EBX = 0000009Bh
shl   ebx,24            ; EBX = 9B000000h
sar   ebx,24            ; EBX = FFFFFF9Bh    (−101)
```

</details>

**W6.** 부호 없는 32비트 변수에 대해 `val1 = (val2 * val3) / (val4 - 3)`을 구현하라. 곱은 64비트까지 커질 수 있다고 가정한다.

<details>
<summary>정답 보기</summary>

`MUL`이 만든 64비트 곱 EDX:EAX를 그대로 `DIV`의 피제수로 쓴다. 그래서 곱과 나눗셈 사이에 EDX를 건드리면 안 된다.

```asm
.data
val1 DWORD ?
val2 DWORD 12
val3 DWORD 9
val4 DWORD 7
.code
mov  eax,val2
mul  val3               ; EDX:EAX = 108
mov  ebx,val4
sub  ebx,3              ; EBX = 4
div  ebx                ; EAX = 27
mov  val1,eax           ; val1 = 27
```

</details>

**W7.** 부호 있는 32비트 변수에 대해 `val1 = (val2 / val3) * (val1 + val2)`를 구현하라. 곱은 32비트에 들어간다고 가정한다.

<details>
<summary>정답 보기</summary>

```asm
.data
val1 SDWORD 5
val2 SDWORD -40
val3 SDWORD 6
.code
mov  eax,val2
cdq                     ; 피제수 부호 확장
idiv val3               ; EAX = -6    (−40 ÷ 6, 0 방향 버림)
mov  ebx,val1
add  ebx,val2           ; EBX = -35
imul ebx                ; EAX = 210
mov  val1,eax           ; val1 = 210
```

`val1 + val2`를 먼저 EBX에 계산해 두지 않고 `IDIV` 뒤에 계산했다. `IDIV`가 EDX를 바꾸지만 EBX는 그대로이므로 문제없다.

</details>

**W8.** EDX:EAX에 있는 64비트 값을 왼쪽으로 1비트 **회전**하라(최상위 비트가 최하위 비트로 돌아와야 한다).

<details>
<summary>정답 보기</summary>

`SHL`과 `RCL`로 64비트 시프트를 한 다음, 맨 위에서 밀려나 CF에 남은 비트를 `ADC`로 최하위 비트에 더한다(`SHL`이 최하위 비트를 0으로 비워 두었으므로 더하기가 곧 넣기다).

```asm
mov  edx,80000000h
mov  eax,00000001h      ; EDX:EAX = 8000000000000001h
shl  eax,1              ; 하위 절반의 최상위 비트 → CF
rcl  edx,1              ; 그 비트가 상위 절반으로, 상위 절반의 최상위 비트 → CF
adc  eax,0              ; EDX:EAX = 0000000000000003h
```

</details>

**W9.** AL의 비트 순서를 거꾸로 뒤집어 BL에 넣어라(예: `11010100b` → `00101011b`).

<details>
<summary>정답 보기</summary>

AL에서 최하위 비트부터 하나씩 CF로 내보내고, 그 비트를 BL의 최하위로 넣으면서 BL을 왼쪽으로 민다. 먼저 나간 비트가 가장 멀리 밀려 올라가므로 순서가 뒤집힌다.

```asm
    mov  al,11010100b
    mov  bl,0
    mov  ecx,8
L1: shr  al,1                   ; AL의 최하위 비트 → CF
    rcl  bl,1                   ; CF → BL의 최하위 비트
    loop L1                     ; 끝나면 BL = 00101011b
```

</details>

**W10.** AH와 AL에 두 자리 ASCII 숫자가 들어 있다(예: AH = `'4'`, AL = `'7'`). 이것을 2진수로 바꿔 AL에 넣어라.

<details>
<summary>정답 보기</summary>

`AAD`는 언팩 10진수를 받으므로 먼저 두 바이트의 상위 4비트를 한 번에 지운다.

```asm
mov ah,'4'
mov al,'7'              ; AX = 3437h
and ax,0F0Fh            ; AX = 0407h    (언팩 10진수로)
aad                     ; AX = 002Fh    (47)
```

</details>

---

## 부록 F. 프로그래밍 연습 (풀이 포함)

교재 7.10절 Programming Exercises와 같은 유형의 문제를 이 장에서 배운 명령어로 풀어 본다. 먼저 직접 풀어 본 다음 **풀이 보기**를 펼쳐 비교해 보자. 모든 풀이는 그대로 붙여 넣어 실행할 수 있는 완전한 프로그램(Irvine32 사용)이고, 실행 결과를 확인했다.

### 연습 1. 비트 단위 곱셈

`MUL`이나 `IMUL` 없이 **시프트와 덧셈만으로** EAX × EBX(부호 없음)를 계산해 EAX에 돌려주는 프로시저 `BitwiseMultiply`를 작성하라. 곱은 32비트에 들어간다고 가정한다. 여러 쌍을 시험하면서 `MUL`의 결과와 나란히 출력하라.

<details>
<summary>풀이 보기</summary>

[7.2의 시프트-덧셈 곱셈](#시프트-덧셈-곱셈의-일반형-보충)을 그대로 옮긴다. 곱하는 수(EBX)를 오른쪽으로 밀면서 CF로 나온 비트가 1일 때만 곱해지는 수(EAX)를 더하고, 곱해지는 수는 매번 왼쪽으로 밀어 2배로 만든다. 곱하는 수가 0이 되면 더 더할 것이 없으므로 일찍 끝낸다.

```asm
; 연습 1: 시프트와 덧셈만으로 곱하기
INCLUDE Irvine32.inc

.data
pairs  DWORD 123,36, 7,0, 65535,65537, 1000,1000
msgX   BYTE " x ",0
msgEq  BYTE " = ",0
msgMul BYTE "   (MUL: ",0
msgEnd BYTE ")",0

.code
main PROC
    mov  esi,OFFSET pairs
    mov  ecx,LENGTHOF pairs / 2
L1: mov  eax,[esi]
    call WriteDec
    mov  edx,OFFSET msgX
    call WriteString
    mov  eax,[esi+4]
    call WriteDec
    mov  edx,OFFSET msgEq
    call WriteString
    mov  eax,[esi]
    mov  ebx,[esi+4]
    call BitwiseMultiply                ; EAX = EAX × EBX
    call WriteDec
    mov  edx,OFFSET msgMul
    call WriteString
    mov  eax,[esi]
    mul  DWORD PTR [esi+4]              ; 비교용: MUL의 결과 (하위 32비트)
    call WriteDec
    mov  edx,OFFSET msgEnd
    call WriteString
    call Crlf
    add  esi,8
    loop L1
    exit
main ENDP

;-----------------------------------------------------
BitwiseMultiply PROC
; 시프트와 덧셈으로 부호 없는 곱셈을 한다.
; Receives: EAX = 곱해지는 수, EBX = 곱하는 수
; Returns:  EAX = 곱 (하위 32비트)
;-----------------------------------------------------
    push ebx
    push edx
    mov  edx,0                          ; 곱을 모을 곳
BM1: test ebx,ebx                       ; 곱하는 수에 1인 비트가 남았는가?
    jz   BM3
    shr  ebx,1                          ; 최하위 비트 → CF
    jnc  BM2                            ; 0이면 더하지 않는다
    add  edx,eax                        ; 1이면 지금의 곱해지는 수를 더한다
BM2: shl  eax,1                         ; 곱해지는 수를 2배로
    jmp  BM1
BM3: mov  eax,edx
    pop  edx
    pop  ebx
    ret
BitwiseMultiply ENDP
END main
```

실행 결과:

```text
123 x 36 = 4428   (MUL: 4428)
7 x 0 = 0   (MUL: 0)
65535 x 65537 = 4294967295   (MUL: 4294967295)
1000 x 1000 = 1000000   (MUL: 1000000)
```

반복 횟수는 곱하는 수의 **가장 높은 1 비트의 위치**만큼이다. 곱하는 수가 작을수록 빨리 끝나므로, 두 수 중 작은 쪽을 EBX에 두면 유리하다.

</details>

### 연습 2. 확장 뺄셈 프로시저

DWORD 배열(리틀 엔디안)로 저장된 길이 제한 없는 두 정수를 빼는 프로시저 `Extended_Sub`를 작성하라. ESI − EDI의 결과를 EBX가 가리키는 배열에 저장하고, 결과가 음수(마지막 자리내림)이면 CF = 1로 돌려준다. 96비트 정수 두 개를 양쪽 순서로 빼서 시험하라.

<details>
<summary>풀이 보기</summary>

[7.4의 확장 덧셈](#확장-덧셈-예제-extended-addition-example)에서 `ADC`를 `SBB`로 바꾸면 된다. 포인터는 플래그를 건드리지 않는 `LEA`로 옮기고, `POPAD`와 `RET`도 플래그를 바꾸지 않으므로 마지막 CF가 호출한 쪽까지 그대로 전달된다.

```asm
; 연습 2: 확장 뺄셈
INCLUDE Irvine32.inc

.data
op1  DWORD 5,0,1                        ; 00000001 00000000 00000005h
op2  DWORD 7,1,0                        ; 00000000 00000001 00000007h
diff DWORD 3 DUP(0)
msgBorrow BYTE "  (borrow: negative)",0

.code
main PROC
    mov  esi,OFFSET op1                 ; op1 − op2
    mov  edi,OFFSET op2
    call SubAndShow
    mov  esi,OFFSET op2                 ; op2 − op1
    mov  edi,OFFSET op1
    call SubAndShow
    exit
main ENDP

;-----------------------------------------------------
SubAndShow PROC
; ESI − EDI를 diff에 계산하고 높은 자리부터 출력한다.
;-----------------------------------------------------
    pushad
    mov  ebx,OFFSET diff
    mov  ecx,LENGTHOF diff
    call Extended_Sub
    pushfd                              ; 출력하는 동안 CF를 보관
    mov  esi,OFFSET diff + SIZEOF diff - 4
    mov  ecx,LENGTHOF diff
SS1: mov  eax,[esi]
    call WriteHex
    sub  esi,4
    loop SS1
    popfd
    jnc  SS2
    mov  edx,OFFSET msgBorrow
    call WriteString
SS2: call Crlf
    popad
    ret
SubAndShow ENDP

;-----------------------------------------------------
Extended_Sub PROC
; 길이 제한 없는 정수의 뺄셈: [EBX] = [ESI] − [EDI]
; Receives: ESI = 빼어지는 수, EDI = 빼는 수, EBX = 차를 저장할 곳,
;           ECX = 더블워드 개수 (모두 리틀 엔디안 DWORD 배열)
; Returns:  CF = 1이면 결과가 음수(마지막 자리내림)
;-----------------------------------------------------
    pushad
    clc                                 ; 첫 자리에는 빌려 갈 것이 없다
ES1: mov  eax,[esi]
    sbb  eax,[edi]                      ; 빼고, 아래 자리에서 빌려 간 1도 뺀다
    mov  [ebx],eax
    lea  esi,[esi+4]                    ; LEA는 플래그를 바꾸지 않는다
    lea  edi,[edi+4]
    lea  ebx,[ebx+4]
    loop ES1
    popad                               ; POPAD도 플래그를 바꾸지 않는다
    ret
Extended_Sub ENDP
END main
```

실행 결과:

```text
00000000FFFFFFFEFFFFFFFE
FFFFFFFF0000000100000002  (borrow: negative)
```

첫 줄은 (2⁶⁴ + 5) − (2³² + 7) = `FFFFFFFEFFFFFFFEh`다. 둘째 줄은 그 음수를 96비트 2의 보수로 나타낸 값이고, 마지막 자리내림 때문에 CF = 1이 되어 "borrow"가 출력되었다.

</details>

### 연습 3. 파일 시간 표시하기

MS-DOS 파일 시간 형식은 16비트에 시(비트 11~15), 분(비트 5~10), 초 ÷ 2(비트 0~4)를 담는다. AX에 이 형식의 값을 받아 `hh:mm:ss`로 출력하는 프로시저 `ShowFileTime`을 작성하라. 한 자리 숫자 앞에는 0을 붙인다.

<details>
<summary>풀이 보기</summary>

[7.2의 날짜 필드 추출](#파일-날짜-필드-추출하기-extracting-file-date-fields)처럼 시프트와 `AND`로 각 필드를 꺼낸다. 초 필드는 2로 나눈 값이므로 `SHL`로 2를 곱해 되돌린다. 두 자리 출력에는 `AAM`을 썼다. AL을 10으로 나눠 10의 자리와 1의 자리로 쪼개 주므로 0~59를 두 자리로 찍기에 딱 맞다.

```asm
; 연습 3: 파일 시간을 hh:mm:ss로 출력
INCLUDE Irvine32.inc

.data
times WORD 746Bh, 48A4h, 0BF7Dh         ; 14:35:22, 09:05:08, 23:59:58

.code
main PROC
    mov  esi,OFFSET times
    mov  ecx,LENGTHOF times
L1: mov  ax,[esi]
    call ShowFileTime
    call Crlf
    add  esi,TYPE times
    loop L1
    exit
main ENDP

;-----------------------------------------------------
ShowFileTime PROC
; Receives: AX = MS-DOS 파일 시간
; 시(11~15), 분(5~10), 초/2(0~4)를 hh:mm:ss로 출력한다.
;-----------------------------------------------------
    pushad
    mov  bx,ax                          ; 원래 값을 보관
    shr  ax,11                          ; 시
    call WriteTwoDigits
    mov  al,':'
    call WriteChar
    mov  ax,bx
    shr  ax,5
    and  ax,111111b                     ; 분 (6비트)
    call WriteTwoDigits
    mov  al,':'
    call WriteChar
    mov  ax,bx
    and  ax,11111b                      ; 초 ÷ 2 (5비트)
    shl  ax,1                           ; × 2 = 초
    call WriteTwoDigits
    popad
    ret
ShowFileTime ENDP

;-----------------------------------------------------
WriteTwoDigits PROC
; Receives: AL에 든 0~99의 값을 두 자리 10진수로 출력한다.
;-----------------------------------------------------
    push eax
    aam                                 ; AH = 10의 자리, AL = 1의 자리
    or   ax,3030h                       ; 두 자리 모두 ASCII로
    push eax
    mov  al,ah
    call WriteChar                      ; 10의 자리
    pop  eax
    call WriteChar                      ; 1의 자리
    pop  eax
    ret
WriteTwoDigits ENDP
END main
```

실행 결과:

```text
14:35:22
09:05:08
23:59:58
```

시험값은 거꾸로 계산해서 만들었다. 14:35:22라면 (14 << 11) OR (35 << 5) OR (22 ÷ 2) = `746Bh`다.

</details>

### 연습 4. 여러 더블워드를 왼쪽으로 시프트

DWORD 배열(리틀 엔디안)로 저장된 큰 정수를 왼쪽으로 n비트(1 ≤ n ≤ 31) 시프트하는 프로시저 `ShiftLeftMulti`를 `SHLD`로 작성하라. 128비트 정수 `123456789ABCDEF00FEDCBA987654321h`를 8비트 시프트해서 시험하라.

<details>
<summary>풀이 보기</summary>

[7.1의 SHRD 예제](#예제-shrd로-배열-전체를-시프트하기)를 뒤집은 것이다. 왼쪽으로 밀 때는 각 원소가 **한 칸 아래 원소의 상위 비트**를 받아야 하므로, 그 아래 원소가 바뀌기 전에 처리되도록 **가장 높은 원소부터** 내려온다. 맨 아래 원소는 받을 비트가 없으므로 `SHL`로 0을 채운다.

```asm
; 연습 4: SHLD로 여러 더블워드를 왼쪽으로 시프트
INCLUDE Irvine32.inc

.data
bigNum DWORD 87654321h,0FEDCBA9h,9ABCDEF0h,12345678h   ; [0]이 가장 낮은 자리

.code
main PROC
    call ShowBig                        ; 시프트 전
    mov  esi,OFFSET bigNum
    mov  ecx,LENGTHOF bigNum
    mov  bl,8                           ; 8비트 시프트
    call ShiftLeftMulti
    call ShowBig                        ; 시프트 후
    exit
main ENDP

;-----------------------------------------------------
ShiftLeftMulti PROC
; Receives: ESI = DWORD 배열, ECX = 원소 수(2 이상), BL = 시프트 횟수(1~31)
;-----------------------------------------------------
    pushad
    lea  edi,[esi+ecx*4-4]              ; 가장 높은 원소
    dec  ecx                            ; 이웃한 쌍의 수
    mov  edx,ecx
    mov  cl,bl                          ; CL = 시프트 횟수
SL1: mov  eax,[edi-4]                   ; 한 칸 아래 원소
    shld [edi],eax,cl                   ; 아래 원소의 상위 비트를 받아 왼쪽으로
    sub  edi,4
    dec  edx
    jnz  SL1
    shl  DWORD PTR [edi],cl             ; 맨 아래 원소
    popad
    ret
ShiftLeftMulti ENDP

;-----------------------------------------------------
ShowBig PROC
; bigNum을 높은 자리부터 16진수로 출력한다.
;-----------------------------------------------------
    pushad
    mov  esi,OFFSET bigNum + SIZEOF bigNum - 4
    mov  ecx,LENGTHOF bigNum
SB1: mov  eax,[esi]
    call WriteHex
    mov  al,' '
    call WriteChar
    sub  esi,4
    loop SB1
    call Crlf
    popad
    ret
ShowBig ENDP
END main
```

실행 결과:

```text
12345678 9ABCDEF0 0FEDCBA9 87654321
3456789A BCDEF00F EDCBA987 65432100
```

8비트는 16진수 두 자리다. 32자리 전체가 두 자리씩 왼쪽으로 이동해 맨 앞의 `12`가 밀려 나가고 맨 끝에 `00`이 들어왔다. 시프트 횟수로 CL을 써야 하므로 반복 횟수는 ECX 대신 EDX로 셌다.

</details>

### 연습 5. 소수점 넣어 출력하기

[7.5의 ASCII_add 프로그램](#aaa로-여러-자리-더하기-multibyte-addition-using-aaa)은 `DECIMAL_OFFSET = 5`를 선언만 하고 쓰지 않았다. 숫자 문자열(EDX = 주소, ECX = 길이)을 출력하되 오른쪽에서 EBX번째 자리 앞에 소수점을 넣는 프로시저 `WriteScaled`를 작성하고, 두 피연산자와 합을 소수점을 넣어 출력하라.

<details>
<summary>풀이 보기</summary>

소수점 앞의 자릿수는 `길이 − EBX`다. 그만큼 문자를 출력하고, `'.'`을 찍은 뒤 나머지 EBX개를 출력한다. 덧셈 부분은 ASCII_add와 같다.

```asm
; 연습 5: 소수점 위치를 지정해 ASCII 숫자 출력
INCLUDE Irvine32.inc

DECIMAL_OFFSET = 5                              ; 오른쪽에서 센 소수점 위치

.data
decimal_one BYTE "100123456789765"              ; 1001234567.89765
decimal_two BYTE "900402076502015"              ; 9004020765.02015
sum BYTE (SIZEOF decimal_one + 1) DUP(0),0
sPlus  BYTE "+ ",0
sEqual BYTE "= ",0
sSpace BYTE "  ",0

.code
main PROC
    mov  esi,SIZEOF decimal_one - 1             ; ASCII_add와 같은 덧셈
    mov  edi,SIZEOF decimal_one
    mov  ecx,SIZEOF decimal_one
    mov  bh,0
L1: mov  ah,0
    mov  al,decimal_one[esi]
    add  al,bh
    aaa
    mov  bh,ah
    or   bh,30h
    add  al,decimal_two[esi]
    aaa
    or   bh,ah
    or   bh,30h
    or   al,30h
    mov  sum[edi],al
    dec  esi
    dec  edi
    loop L1
    mov  sum[edi],bh

    mov  ebx,DECIMAL_OFFSET                     ; 세 수를 소수점을 넣어 출력
    mov  edx,OFFSET sSpace
    call WriteString
    mov  edx,OFFSET decimal_one
    mov  ecx,SIZEOF decimal_one
    call WriteScaled
    call Crlf
    mov  edx,OFFSET sPlus
    call WriteString
    mov  edx,OFFSET decimal_two
    mov  ecx,SIZEOF decimal_two
    call WriteScaled
    call Crlf
    mov  edx,OFFSET sEqual
    call WriteString
    mov  edx,OFFSET sum
    mov  ecx,SIZEOF sum - 1                     ; 끝의 0은 빼고
    call WriteScaled
    call Crlf
    exit
main ENDP

;-----------------------------------------------------
WriteScaled PROC
; Receives: EDX = 숫자 문자열, ECX = 자릿수, EBX = 소수점 아래 자릿수
;           (ECX > EBX ≥ 1이라고 가정)
;-----------------------------------------------------
    pushad
    mov  esi,edx
    sub  ecx,ebx                                ; 소수점 앞의 자릿수
WS1: mov  al,[esi]
    call WriteChar
    inc  esi
    loop WS1
    mov  al,'.'
    call WriteChar
    mov  ecx,ebx                                ; 소수점 뒤의 자릿수
WS2: mov  al,[esi]
    call WriteChar
    inc  esi
    loop WS2
    popad
    ret
WriteScaled ENDP
END main
```

실행 결과:

```text
  1001234567.89765
+ 9004020765.02015
= 10005255332.91780
```

</details>

### 연습 6. 최대공약수

두 부호 없는 정수의 최대공약수(GCD)를 유클리드 호제법으로 구하는 프로시저 `GCD`를 작성하라. EAX와 EBX로 두 수를 받아 EAX로 돌려준다.

<details>
<summary>풀이 보기</summary>

유클리드 호제법은 `b ≠ 0인 동안 (a, b) = (b, a mod b)`를 반복하고, b가 0이 되면 a가 답이다. 나머지는 `DIV`의 EDX로 바로 얻을 수 있다. 부호 없는 나눗셈이므로 나누기 전에 EDX를 0으로 만드는 것을 잊지 말자.

```asm
; 연습 6: 유클리드 호제법으로 최대공약수 구하기
INCLUDE Irvine32.inc

.data
pairs  DWORD 48,18, 1071,462, 17,5, 0,9, 100,75
msgGcd BYTE "GCD(",0
msgCom BYTE ", ",0
msgEq  BYTE ") = ",0

.code
main PROC
    mov  esi,OFFSET pairs
    mov  ecx,LENGTHOF pairs / 2
L1: mov  edx,OFFSET msgGcd
    call WriteString
    mov  eax,[esi]
    call WriteDec
    mov  edx,OFFSET msgCom
    call WriteString
    mov  eax,[esi+4]
    call WriteDec
    mov  edx,OFFSET msgEq
    call WriteString
    mov  eax,[esi]
    mov  ebx,[esi+4]
    call GCD
    call WriteDec
    call Crlf
    add  esi,8
    loop L1
    exit
main ENDP

;-----------------------------------------------------
GCD PROC
; Receives: EAX, EBX = 부호 없는 정수 (둘 다 0이면 안 된다)
; Returns:  EAX = 최대공약수
;-----------------------------------------------------
    push ebx
    push edx
G1: cmp  ebx,0
    je   G2                             ; b = 0이면 a가 답이다
    mov  edx,0                          ; 부호 없는 나눗셈 준비
    div  ebx                            ; EDX = a mod b
    mov  eax,ebx                        ; a = b
    mov  ebx,edx                        ; b = a mod b
    jmp  G1
G2: pop  edx
    pop  ebx
    ret
GCD ENDP
END main
```

실행 결과:

```text
GCD(48, 18) = 6
GCD(1071, 462) = 21
GCD(17, 5) = 1
GCD(0, 9) = 9
GCD(100, 75) = 25
```

</details>

### 연습 7. 소수 판별

EAX의 값이 소수이면 ZF = 1, 아니면 ZF = 0으로 돌려주는 프로시저 `IsPrime`을 작성하고, 100보다 작은 소수를 모두 출력하라.

<details>
<summary>풀이 보기</summary>

2부터 시작해 d × d ≤ n인 동안 n을 d로 나눠 본다. 나누어떨어지는 d가 하나라도 있으면 소수가 아니다. d × d는 `MUL`로 계산하는데, `MUL` 뒤에 CF = 1이면 곱이 32비트를 넘은 것이므로 n보다 확실히 크다. 결과는 ZF로 돌려주어야 하므로 `POPAD`(플래그를 바꾸지 않는다) 바로 앞에서 ZF를 만든다.

```asm
; 연습 7: 100보다 작은 소수 출력
INCLUDE Irvine32.inc

.code
main PROC
    mov  eax,2
L1: call IsPrime
    jnz  L2                             ; 소수가 아니면 건너뛴다
    call WriteDec
    push eax
    mov  al,' '
    call WriteChar
    pop  eax
L2: inc  eax
    cmp  eax,100
    jb   L1
    call Crlf
    exit
main ENDP

;-----------------------------------------------------
IsPrime PROC
; Receives: EAX = 검사할 부호 없는 정수
; Returns:  ZF = 1이면 소수, ZF = 0이면 소수가 아니다
;-----------------------------------------------------
    pushad
    cmp  eax,2
    jb   NotPrime                       ; 0과 1은 소수가 아니다
    mov  esi,eax                        ; ESI = n
    mov  ebx,2                          ; EBX = 나눠 볼 수 d
IP1: mov  eax,ebx
    mul  ebx                            ; EDX:EAX = d × d
    jc   Prime                          ; 32비트를 넘으면 n보다 크다
    cmp  eax,esi
    ja   Prime                          ; d × d > n이면 더 볼 필요 없다
    mov  eax,esi
    mov  edx,0
    div  ebx                            ; EDX = n mod d
    cmp  edx,0
    je   NotPrime                       ; 나누어떨어지면 소수가 아니다
    inc  ebx
    jmp  IP1
Prime:
    cmp  eax,eax                        ; ZF = 1
    jmp  IP9
NotPrime:
    or   esi,1                          ; ESI는 POPAD로 복원되므로 마음대로 쓴다
    test esi,esi                        ; ZF = 0
IP9:
    popad                               ; POPAD는 플래그를 바꾸지 않는다
    ret
IsPrime ENDP
END main
```

실행 결과:

```text
2 3 5 7 11 13 17 19 23 29 31 37 41 43 47 53 59 61 67 71 73 79 83 89 97
```

</details>

### 연습 8. 팩 10진수를 ASCII로

8자리 팩 10진수가 들어 있는 DWORD를 ASCII 숫자 문자열로 바꾸는 프로시저 `PackedToAsc`를 작성하라. EAX로 값을, ESI로 9바이트 버퍼의 주소를 받는다. 다섯 개 이상의 값으로 시험하라.

<details>
<summary>풀이 보기</summary>

팩 10진수의 각 니블이 숫자 하나다. [7.2의 16진수 출력](#같은-원리로-16진수-출력하기-보충)처럼 `ROL eax,4`로 가장 높은 니블을 최하위로 돌려 내리고, `AND 0Fh`로 떼어 낸 뒤 `OR 30h`로 ASCII 숫자로 만든다. 니블이 0~9뿐이므로 16진수 출력과 달리 문자표가 필요 없다.

```asm
; 연습 8: 팩 10진수를 ASCII 숫자 문자열로
INCLUDE Irvine32.inc

.data
values DWORD 87654321h, 00012345h, 20261101h, 99999999h, 00000000h
buffer BYTE 9 DUP(0)

.code
main PROC
    mov  edi,OFFSET values
    mov  ecx,LENGTHOF values
L1: mov  eax,[edi]
    mov  esi,OFFSET buffer
    call PackedToAsc
    mov  edx,OFFSET buffer
    call WriteString
    call Crlf
    add  edi,4
    loop L1
    exit
main ENDP

;-----------------------------------------------------
PackedToAsc PROC
; Receives: EAX = 8자리 팩 10진수, ESI = 9바이트 버퍼
; Returns:  버퍼에 ASCII 숫자 8개와 끝을 나타내는 0
;-----------------------------------------------------
    pushad
    mov  ecx,8
PA1: rol  eax,4                         ; 가장 높은 자리 숫자를 최하위 니블로
    mov  bl,al
    and  bl,0Fh                         ; 그 숫자만 남긴다
    or   bl,30h                         ; ASCII로
    mov  [esi],bl
    inc  esi
    loop PA1
    mov  BYTE PTR [esi],0
    popad
    ret
PackedToAsc ENDP
END main
```

실행 결과:

```text
87654321
00012345
20261101
99999999
00000000
```

</details>

### 연습 9. 회전으로 암호화하기

평문의 각 바이트를 키 배열의 값만큼 **왼쪽으로 회전**해서 암호화하고, 같은 값만큼 **오른쪽으로 회전**해서 복호화하는 프로그램을 작성하라. 키가 평문보다 짧으면 처음부터 반복해서 쓴다. 키는 `2, 5, 7, 1, 4, 3`, 평문은 `"Hello, World!"`로 하고, 암호문은 16진수 바이트로 출력하라.

<details>
<summary>풀이 보기</summary>

회전은 비트를 잃지 않으므로 반대 방향으로 같은 횟수만큼 회전하면 정확히 원래 값이 돌아온다. 이것이 XOR 암호(6장)와 함께 회전이 간단한 암호화에 쓰이는 이유다. 키 인덱스는 키 길이에 이르면 0으로 되돌린다.

```asm
; 연습 9: 회전을 이용한 간단한 암호화와 복호화
INCLUDE Irvine32.inc

.data
key     BYTE 2,5,7,1,4,3
message BYTE "Hello, World!",0
msgP    BYTE "Plain : ",0
msgC    BYTE "Cipher: ",0
msgD    BYTE "Decode: ",0

.code
main PROC
    mov  edx,OFFSET msgP
    call WriteString
    mov  edx,OFFSET message
    call WriteString
    call Crlf

    mov  bl,0                           ; 0 = 암호화(ROL)
    call Crypt
    mov  edx,OFFSET msgC                ; 암호문을 16진수로
    call WriteString
    mov  esi,OFFSET message
    mov  ecx,(SIZEOF message) - 1
    mov  ebx,1                          ; WriteHexB: 1바이트
L1: mov  al,[esi]
    call WriteHexB
    mov  al,' '
    call WriteChar
    inc  esi
    loop L1
    call Crlf

    mov  bl,1                           ; 1 = 복호화(ROR)
    call Crypt
    mov  edx,OFFSET msgD
    call WriteString
    mov  edx,OFFSET message
    call WriteString
    call Crlf
    exit
main ENDP

;-----------------------------------------------------
Crypt PROC
; message의 각 바이트를 key 값만큼 회전한다.
; Receives: BL = 0이면 ROL(암호화), 1이면 ROR(복호화)
;-----------------------------------------------------
    pushad
    mov  esi,OFFSET message
    mov  edi,0                          ; 키 인덱스
    mov  edx,(SIZEOF message) - 1       ; 바이트 수 (끝의 0은 빼고)
C1: mov  cl,key[edi]                    ; 회전 횟수
    cmp  bl,0
    jne  C2
    rol  BYTE PTR [esi],cl
    jmp  C3
C2: ror  BYTE PTR [esi],cl
C3: inc  esi
    inc  edi
    cmp  edi,LENGTHOF key
    jb   C4
    mov  edi,0                          ; 키를 처음부터 다시
C4: dec  edx
    jnz  C1
    popad
    ret
Crypt ENDP
END main
```

실행 결과:

```text
Plain : Hello, World!
Cipher: 21 AC 36 D8 F6 61 80 EA B7 E4 C6 23 84
Decode: Hello, World!
```

`'H'`(`48h` = `01001000b`)를 왼쪽으로 2비트 회전하면 `00100001b` = `21h`다. 암호문에는 쉼표(`2Ch`)나 공백(`20h`)이 어디 있는지 겉으로 드러나지 않는다. 다만 이 정도 암호는 키 길이만 알면 쉽게 풀리므로 실제 보안에는 쓸 수 없다.

</details>

### 연습 10. 64비트 정수를 10진수로 출력하기

EDX:EAX에 들어 있는 부호 없는 64비트 정수를 10진수로 출력하는 프로시저 `WriteDec64`를 작성하라. 2⁶⁴ − 1 = 18446744073709551615도 올바르게 출력해야 한다.

<details>
<summary>풀이 보기</summary>

10진수로 바꾸는 기본 방법은 "10으로 나눈 나머지가 끝 자리"를 반복하는 것이다(Irvine32의 `WriteDec`도 그렇게 한다). 문제는 64비트 피제수를 10으로 나누면 몫도 64비트라서 `DIV` 한 번으로는 [나눗셈 오버플로](#나눗셈-오버플로-divide-overflow)가 난다는 점이다. 손으로 하는 긴 나눗셈처럼 **상위 절반부터 두 번 나누면** 해결된다.

1. 상위 절반 ÷ 10: 몫은 새 상위 절반, 나머지 r은 EDX에 남는다.
2. (r : 하위 절반) ÷ 10: r < 10이므로 몫은 반드시 32비트에 들어간다. 몫은 새 하위 절반, 나머지는 이번 자릿수다.

```asm
; 연습 10: 64비트 정수를 10진수로 출력
INCLUDE Irvine32.inc

.data
nums QWORD 0FFFFFFFFFFFFFFFFh, 0AB54A98CEB1F0AD2h, 100000000h, 0

.code
main PROC
    mov  esi,OFFSET nums
    mov  ecx,LENGTHOF nums
L1: mov  eax,DWORD PTR [esi]            ; 하위 절반
    mov  edx,DWORD PTR [esi+4]          ; 상위 절반
    call WriteDec64
    call Crlf
    add  esi,8
    loop L1
    exit
main ENDP

;-----------------------------------------------------
WriteDec64 PROC
; Receives: EDX:EAX = 부호 없는 64비트 정수. 10진수로 출력한다.
;-----------------------------------------------------
    pushad
    mov  esi,eax                        ; ESI = 하위 절반
    mov  edi,edx                        ; EDI = 상위 절반
    mov  ebx,10
    mov  ecx,0                          ; 자릿수
WD1: mov  eax,edi
    mov  edx,0
    div  ebx                            ; 상위 절반 ÷ 10, 나머지는 EDX에
    mov  edi,eax
    mov  eax,esi
    div  ebx                            ; (나머지:하위 절반) ÷ 10
    mov  esi,eax
    push edx                            ; 이번 자릿수(0~9)
    inc  ecx
    mov  eax,esi
    or   eax,edi                        ; 몫이 0이 되었는가?
    jnz  WD1
WD2: pop  eax                           ; 높은 자리부터 꺼내 출력
    or   al,'0'
    call WriteChar
    loop WD2
    popad
    ret
WriteDec64 ENDP
END main
```

실행 결과:

```text
18446744073709551615
12345678901234567890
4294967296
0
```

자릿수는 낮은 자리부터 나오므로 스택에 넣었다가 거꾸로 꺼내 출력했다. 같은 방법으로 상위 절반부터 차례로 나누면 128비트, 256비트 정수도 10진수로 바꿀 수 있다.

</details>

---

## 부록 G. 슬라이드 정정 사항 모음

본문의 정정 박스에 적은 내용을 한곳에 모았다. 슬라이드 번호는 표지를 1번으로 센 것이다.

| 위치 | 슬라이드 표기 | 올바른 내용 |
|---|---|---|
| 14번 SHLD/SHRD Instructions | "Sign, Zero, Auxiliary, Parity, and Carry flags are affected" | **AF는 정의되지 않는다.** SF, ZF, PF, CF가 결과에 따라 바뀌고, OF는 1비트 시프트일 때만 정의된다 |
| 16~18번 머리글 | "Conditional Control Flow Directives" | 내용은 7.1 Shift and Rotate Instructions다. 6장 슬라이드의 머리글이 남았다 |
| 17번 Explain the program below | `shr DWORD PTR [esi],COUNT` | `COUNT`가 정의되어 있지 않아 어셈블되지 않는다. `COUNT = 4`를 정의하고 첫 줄도 `mov bl,COUNT`로 맞춘다 |
| 17번 같은 코드 | `mov ecx,(LENGTHOF array) – 1` | 빼기 기호는 하이픈(`-`)으로 써야 한다 |
| 17번 같은 코드 | 주석 "number of array elements" | 정확히는 "원소 수 − 1"(이웃한 원소 쌍의 수)이다 |
| 26번 MUL Examples | 두 번째 그림의 곱하는 수 `BX` | 코드에서 곱하는 수는 메모리 변수 `val2`다 |
| 37번 Signed Integer Division | `wordVal SWORD -101 ; 009Bh` | 16비트 −101은 `FF9Bh`다 (`9Bh`는 8비트 −101) |
| 37번 같은 코드 | `mov ax,wordVal ; EAX = 0000009Bh (+155)` | `mov eax,0` 다음이므로 EAX = `0000FF9Bh` (+65,435) |
| 37번 파란 글씨 | "the 009Bh in EAX is not really equal to 101" | `FF9Bh`도 DX = 0과 함께 DX:AX로 읽으면 +65,435라서 −101이 아니다 |
| 37번 같은 코드 | `mov bx,2 ; EBX is the divisor` | 제수는 BX다 |
| 37번 같은 코드 | `idiv bx ; divide EAX by BX` | 16비트 `IDIV`는 **DX:AX**를 나눈다. 코드가 DX를 정하지 않아 결과가 DX에 남은 값에 따라 달라지고, 나눗셈 오버플로가 날 수도 있다 |
| 37번 두 번째 코드 | `cwd ; EAX = FFFFFF9Bh (-101)` | `CWD`는 DX를 바꾼다. DX:AX = `FFFF:FF9Bh`이고 EAX는 그대로다. EAX를 `FFFFFF9Bh`로 만드는 명령어는 `CWDE`다 |

틀린 것은 아니지만 그대로 따라 하면 오해하기 쉬운 부분은 다음과 같다.

| 위치 | 슬라이드 내용 | 주의할 점 |
|---|---|---|
| 32번 IMUL | `mov ax,-32000` / `imul ax,2`가 3-피연산자 예제와 함께 나온다 | 실제로는 2-피연산자 형식(`IMUL reg16, imm8`)이다 |
| 33번 Measuring Program Execution Times | 시프트가 `MUL`보다 빠르다는 전제 | 요즘 CPU에서는 차이가 거의 없다. 실제로 재 보니 8,364ms 대 8,274ms였다 |
| 41번 Divide Overflow | `mov eax,1000h` / `cdq` / `div ebx` | 부호 없는 `DIV` 앞에는 `mov edx,0`이 맞다. `CDQ`는 EAX가 양수일 때만 우연히 0을 만든다 |
| 55번 AAS Instruction | `pushf` / `popf` | 16비트 플래그를 저장하는 형식이다. 32비트 코드에서는 `pushfd`/`popfd`가 자연스럽다(결과는 같다) |
| 56번 AAM Instruction | `AscVal`로 선언하고 `ascVal`로 사용 | 기본 설정에서는 대소문자를 구분하지 않아 어셈블되지만 `OPTION CASEMAP:NONE`이면 오류다. 값도 이름과 달리 ASCII가 아니라 언팩 10진수다 |

슬라이드 18, 24, 46, 49, 58, 62번은 머리글만 있는 빈 슬라이드다. 슬라이드에 없어서 보충한 부분은 다음과 같다.

| 내용 | 근거 |
|---|---|
| 시프트 횟수 규칙(CL·즉시값, 하위 5비트, 0이면 플래그 그대로), 1비트 시프트·회전의 OF 규칙, 플래그 정리 표 | 인텔 SDM, 실행으로 확인 |
| SAR와 IDIV의 반올림 차이, 컴파일러의 부호 있는 2ⁿ 나눗셈 | 실행으로 확인 |
| BSWAP, 니블·바이트 교환, 레지스터 두 개에 걸친 64비트 시프트 | 인텔 SDM |
| 여러 원소 시프트 루프, ROL로 16진수 출력, 날짜 필드 만들기, 비트 필드 패턴, LEA 곱셈 | 이 장의 명령어 응용 |
| MUL의 상위 절반 덮어쓰기, MUL과 IMUL의 차이, 실행 시간 측정의 주의점 | 인텔 SDM, Irvine32 라이브러리 소스, 실측 |
| CWDE, CQO, 몫·나머지의 부호, 나눗셈 준비 표, 몫이 넘칠지 미리 알아보기, 최소 음수 ÷ −1 | 인텔 SDM |
| 확장 덧셈 예제(ExtAdd) | 교재 7.4.2절 (빈 슬라이드 49번 자리) |
| 64비트 덧셈과 부호 바꾸기, CF를 그대로 두는 명령어, SBB 마스크, 1인 비트 세기 | 인텔 SDM, 실행으로 확인 |
| AAA의 AF 예, AAM·AAD의 기계어, DAA·DAS의 규칙과 추가 예, 팩 10진수의 쓰임 | 인텔 SDM |
| 64비트 모드에서 달라지는 점 | 인텔 SDM, 64비트 빌드로 확인 |
| 부록 B (시프트-뺄셈 나눗셈, 상수 나눗셈을 곱셈으로) | Granlund & Montgomery(1994), GCC 출력 |

---

## 참고 자료

### 예제 값 확인 방법

이 문서의 예제는 눈으로만 검토하지 않고 실제로 돌려서 확인했다.

- `asm` 코드 블록 133개 전체를 MASM 호환 어셈블러(JWasm 2.21)로 어셈블했다(64비트 예제 1개는 64비트 모드로). 조각 코드는 프로그램 틀을 씌웠고, Irvine32 프로시저는 같은 이름과 출력 형식으로 만든 리눅스용 대체 라이브러리에 링크했다.
- 실행 파일을 디버거(gdb)로 한 명령어씩 실행하면서 주석에 적힌 레지스터·플래그·변수 값, 점프 여부, 실행되지 않아야 할 줄, 나눗셈 오류 예외(#DE)를 실제 상태와 비교했다. 이렇게 비교한 항목은 405개이고 모두 일치했다.
- "실행 결과" 블록 20개는 프로그램의 실제 출력과 한 줄씩 비교했다. 부록 E의 정답과 부록 F의 풀이도 같은 방법으로 확인했다.
- 64비트 모드 예제는 64비트로 따로 빌드해서 결과를 스스로 검사하는 프로그램으로 확인했다. CompareMult는 실행 시간이 길어 직접 실행해서 시간을 쟀고, 부록 B.2의 상수 나눗셈은 32비트 정수 2³²개 전체에 대해 C 프로그램으로 확인했다.

다만 다음은 확인 범위 밖이다.

- Windows의 `ml.exe`와 Visual Studio에서 직접 실행한 것은 아니다. 명령어의 동작과 플래그는 어셈블러와 운영체제에 상관없이 같지만, 빌드 과정의 사소한 차이는 있을 수 있다.
- `DumpMem`이 출력하는 주소처럼 실행 환경마다 다른 값은 …로 줄였다.
- 부록 C의 오류 번호(A2070, A2022)는 MASM의 오류 메시지를 기준으로 적었다. 같은 코드를 JWasm으로 어셈블해 오류가 나는 것은 확인했지만, `ml.exe`의 메시지 문구는 버전에 따라 조금 다를 수 있다.
- 실행 시간(8,364ms, 8,274ms)은 이 문서를 만든 환경 한 곳에서 잰 값이다. CPU와 운영체제에 따라 크게 달라진다.

### 문헌과 링크

- Kip R. Irvine, *Assembly Language for x86 Processors* (7th / 8th Edition), Pearson — Chapter 7. Integer Arithmetic
- [Kip Irvine 교재 공식 사이트](https://www.asmirvine.com/) (Irvine32 라이브러리와 예제 프로그램)
- [intelligentcm 블로그 — Assembly 카테고리](https://intelligentcm.tistory.com/category/Assembly)
- [Microsoft Learn — Microsoft Macro Assembler(MASM) 참조](https://learn.microsoft.com/ko-kr/cpp/assembler/masm/microsoft-macro-assembler-reference)
- [Intel® 64 and IA-32 Architectures Software Developer's Manuals](https://www.intel.com/content/www/us/en/developer/articles/technical/intel-sdm.html) (Volume 2의 SAL/SAR/SHL/SHR, ROL/ROR/RCL/RCR, SHLD, SHRD, MUL, IMUL, DIV, IDIV, CBW/CWDE/CDQE, CWD/CDQ/CQO, ADC, SBB, AAA, AAS, AAM, AAD, DAA, DAS 항목)
- [Agner Fog — Software optimization resources](https://www.agner.org/optimize/) (Instruction tables: CPU별 명령어 지연 시간)
- [Raymond Chen, The Old New Thing — 0으로 나누기와 나눗셈 오버플로를 Windows가 구별하는 방법](https://devblogs.microsoft.com/oldnewthing/20141002-00/?p=43933)
- [Microsoft Learn — ML and ML64 Command-Line Reference](https://learn.microsoft.com/en-us/previous-versions/visualstudio/visual-studio-2008/s0ksfwcf(v=vs.90)) (`/Cu`가 기본: 식별자의 대소문자를 구분하지 않는다)
- Torbjörn Granlund, Peter L. Montgomery, "Division by Invariant Integers using Multiplication", *Proceedings of PLDI '94*, 1994

<br>

> 이 문서는 강의 슬라이드를 바탕으로 개인 학습용으로 정리한 노트입니다.
