# x86 어셈블리: 고급 프로시저 (Advanced Procedures)

![Assembler](https://img.shields.io/badge/Assembler-MASM-blue)
![Architecture](https://img.shields.io/badge/Architecture-x86%2032--bit-lightgrey)
![IDE](https://img.shields.io/badge/IDE-Visual%20Studio%202022-5C2D91)
![Chapter](https://img.shields.io/badge/Irvine-Chapter%208-orange)

> Kip R. Irvine, *Assembly Language for x86 Processors* — Chapter 8. Advanced Procedures 강의 정리
>
> 슬라이드 내용을 절 순서대로 정리하고, 슬라이드에 없는 동작 원리, 추가 예제, 자주 하는 실수를 보충했다. 슬라이드가 비어 있거나 다루지 않은 부분(Microsoft x64 호출 규약, PROTO 지시어, ArraySum 다중 모듈 코드, 매개변수 고급 활용, 자바 바이트코드)도 채웠다.
> 슬라이드의 오류는 본문에 정정 박스로 표시하고 [부록 G](#부록-g-슬라이드-정정-사항-모음)에 모아 두었다.
> 예제 코드의 주석에 적힌 레지스터·스택·변수 값과 실행 결과는 직접 어셈블하고 한 명령어씩 실행해서 확인한 값이다([예제 값 확인 방법](#예제-값-확인-방법)).

---

## 한눈에 보기 (TL;DR)

- **스택 프레임**(stack frame, 활성 레코드 activation record)은 프로시저 하나가 스택에 차지하는 영역이다. 인수, 복귀 주소, 저장된 EBP, 지역 변수, 저장된 레지스터가 차례로 쌓인다.
- 프로시저는 `push ebp` / `mov ebp,esp`로 시작해 **EBP를 기준점**으로 삼는다. 그러면 인수는 `[ebp+8]`, `[ebp+12]`, …, 지역 변수는 `[ebp-4]`, `[ebp-8]`, …처럼 고정된 위치에 있다. ESP는 `PUSH`·`POP`마다 바뀌므로 기준점으로 쓰기 어렵다.
- 인수를 스택에서 치우는 쪽은 **호출 규약**이 정한다. **C 규약**은 호출한 쪽이 `add esp,n`으로, **STDCALL**은 호출된 쪽이 `ret n`으로 치운다. 이것이 어긋나면 `RET`이 엉뚱한 값을 복귀 주소로 꺼내 프로그램이 무너진다.
- **값 전달**은 값의 복사본을, **참조 전달**은 주소를 넘긴다. 배열은 항상 주소로 넘긴다. 실행 중에만 정해지는 스택 변수의 주소는 `OFFSET`이 아니라 `LEA`로 구한다.
- `ENTER`/`LEAVE`는 프레임을 만들고 없애는 명령어이고, `LOCAL`은 이름 있는 지역 변수를 선언하는 지시어다.
- **재귀** 프로시저는 반드시 종료 조건이 있어야 한다. 호출할 때마다 새 스택 프레임이 쌓이므로, 끝나지 않는 재귀는 결국 스택을 다 써 버린다(stack overflow).
- `INVOKE`, `ADDR`, `PROC`의 매개변수 목록, `PROTO`는 MASM의 고급 기능이다. 어셈블러가 인수 `push`, `call`, 프롤로그·에필로그, `ret n`을 대신 만들어 준다. 그 대신 EAX를 몰래 덮어쓰는 경우가 있고, `INVOKE`와 `ADDR`은 32비트 MASM에서만 쓸 수 있다.
- **다중 모듈** 프로그램은 모듈마다 따로 어셈블하고 링커가 합친다. `PUBLIC`·`EXTERN`·`EXTERNDEF`로 이름을 내보내고 가져오며, STDCALL 프로시저의 이름은 `_AddTwo@8`처럼 인수 바이트 수가 붙은 이름이 된다.
- 64비트 Windows는 호출 규약이 하나뿐이다. 앞의 정수 인수 네 개를 RCX, RDX, R8, R9로 넘기고, 호출한 쪽이 32바이트 섀도 공간을 마련한다.

---

## 목차

| 구분 | 내용 |
|---|---|
| [들어가며](#들어가며-5장에서-8장으로) | 5장과의 연결, C 코드와 어셈블리의 대응 |
| [8.2 스택 프레임](#82-스택-프레임-stack-frames) | 스택 매개변수, 레지스터 매개변수의 단점, 값·참조 전달, 매개변수 접근, 스택 정리, C·STDCALL 규약, 레지스터 저장, 지역 변수, 참조 매개변수, LEA, ENTER·LEAVE, LOCAL, x64 호출 규약 |
| [8.3 재귀](#83-재귀-recursion) | 끝없는 재귀, 재귀로 합 구하기, 팩토리얼, 재귀의 비용 |
| [8.4 INVOKE, ADDR, PROC, PROTO](#84-invoke-addr-proc-proto) | INVOKE, ADDR, PROC, PROTO, 매개변수 분류, Swap 예제, 디버깅 팁, WriteStackFrame |
| [8.5 다중 모듈 프로그램](#85-다중-모듈-프로그램-creating-multimodule-programs) | 이름 숨기기와 내보내기, 외부 프로시저 호출, 모듈 간 변수 공유, ArraySum 다중 모듈 예제 |
| [8.6 매개변수 고급 활용](#86-매개변수-고급-활용-advanced-use-of-parameters-보충) | USES와 스택, 8·16비트 인수, 64비트 인수, 더블워드가 아닌 지역 변수 |
| [8.7 자바 바이트코드](#87-자바-바이트코드-java-bytecodes-보충) | JVM의 피연산자 스택, 바이트코드 역어셈블 예 |
| [부록 A](#부록-a-핵심-정리-표) | 핵심 정리 표 (프레임 오프셋, 호출 규약, 지시어) |
| [부록 B](#부록-b-c-컴파일러가-만든-스택-프레임) | C 컴파일러가 만든 스택 프레임 |
| [부록 C](#부록-c-자주-하는-실수와-오류-메시지) | 자주 하는 실수와 오류 메시지 |
| [부록 D](#부록-d-핵심-용어-정리) | 핵심 용어 정리 |
| [부록 E](#부록-e-복습-문제) | 복습 문제 (단답형, 알고리즘 작성, 정답 접기) |
| [부록 F](#부록-f-프로그래밍-연습-풀이-포함) | 프로그래밍 연습 (풀이 포함) |
| [부록 G](#부록-g-슬라이드-정정-사항-모음) | 슬라이드 정정 사항 모음 |
| [참고 자료](#참고-자료) | 예제 값 확인 방법, 교재, 공식 문서 |

---

## 들어가며: 5장에서 8장으로

5장에서는 `CALL`과 `RET`으로 프로시저를 부르고, 인수를 **레지스터**로 넘겼다. `WriteDec`에 EAX를, `DumpMem`에 ESI·ECX·EBX를 넣어 주는 식이다. 이 방식은 간단하지만 인수가 많아지면 레지스터가 모자라고, 프로시저가 다른 프로시저를 부를 때마다 레지스터를 저장하고 되살리느라 코드가 복잡해진다.

8장은 C·C++ 같은 고급 언어가 실제로 쓰는 방법을 다룬다. 인수와 지역 변수를 **스택**에 두고, 그 영역을 EBP로 가리키며 다룬다. 이 구조를 이해하면 재귀가 어떻게 가능한지, 컴파일러가 만든 코드가 왜 그런 모양인지, 어셈블리와 C를 섞어 쓸 때 무엇을 맞춰야 하는지가 보인다.

| 하고 싶은 일 | 이 장에서 배우는 도구 | 절 |
|---|---|---|
| 인수를 스택으로 넘기고 꺼내 쓴다 | `PUSH`, `[ebp+8]`, `ret n` | 8.2 |
| 프로시저 안에 지역 변수를 만든다 | `sub esp,n`, `ENTER`·`LEAVE`, `LOCAL` | 8.2 |
| 스택 변수의 주소를 구한다 | `LEA` | 8.2 |
| 프로시저가 자기 자신을 부른다 | 재귀, 종료 조건 | 8.3 |
| 인수 전달과 프레임 관리를 어셈블러에 맡긴다 | `INVOKE`, `ADDR`, `PROC`, `PROTO`, `USES` | 8.4 |
| 프로그램을 여러 소스 파일로 나눈다 | `PUBLIC`, `EXTERN`, `EXTERNDEF` | 8.5 |

C 코드 한 줄이 어셈블리에서 어떤 모습이 되는지 먼저 보면 이 장의 내용이 한눈에 들어온다. 32비트 STDCALL 규약으로 번역했다고 가정했다.

| C 코드 | 어셈블리 | 관련 내용 |
|---|---|---|
| `sum = AddTwo(5, 6);` | `push 6` / `push 5` / `call AddTwo` / `mov sum,eax` | 인수는 오른쪽부터 넣고, 반환값은 EAX |
| `int AddTwo(int x, int y)`의 `x`, `y` | `[ebp+8]`, `[ebp+12]` | 스택 매개변수 |
| 함수 안의 `int x = 10;` | `mov DWORD PTR [ebp-4],10` | 지역 변수 |
| `Swap(&a, &b);` | `push OFFSET b` / `push OFFSET a` / `call Swap` | 참조 전달 |
| `char s[30]; char *p = s;` | `lea esi,[ebp-30]` | 실행 중에 주소 계산 |
| `return n * factorial(n - 1);` | `push eax` / `call Factorial` / `mul ebx` | 재귀 |
| `extern int count;` | `EXTERN count:DWORD` | 다중 모듈 |

> [!NOTE]
> 표의 첫 줄에서 인수를 **오른쪽부터** 넣는 데 주목하자. 그래야 첫 번째 인수가 스택 맨 위(낮은 주소)에 오고, 호출된 쪽에서는 인수 개수와 상관없이 첫 번째 인수가 언제나 `[ebp+8]`에 있다. C의 `printf`처럼 인수 개수가 정해지지 않은 함수가 가능한 것도 이 순서 덕분이다.

---

## 8.2 스택 프레임 (Stack Frames)

### 스택 매개변수 (Stack Parameters)

**스택 프레임**(stack frame) 또는 **활성 레코드**(activation record)는 프로시저 하나를 위해 스택에 마련한 영역이다. 넘겨받은 인수, 복귀 주소, 지역 변수, 저장한 레지스터가 여기에 들어간다(A stack frame is the area of the stack set aside for passed arguments, subroutine return address, local variables, and saved registers).

스택 프레임은 다음 순서로 만들어진다. 1~2는 호출하는 쪽이, 3~6은 호출된 프로시저의 첫 부분(**프롤로그** prologue)이 한다.

1. **인수를 넣는다** (Push Arguments). 인수가 있으면 스택에 `PUSH`한다.
2. **프로시저를 부른다** (Call Subroutine). `CALL`이 복귀 주소를 스택에 넣고 프로시저로 점프한다.
3. **EBP를 넣는다** (Push EBP). 호출한 쪽이 쓰던 EBP를 저장한다.
4. **EBP = ESP로 만든다** (Set EBP to ESP). 이때부터 EBP가 이 프레임의 기준점이 된다.
5. **지역 변수 자리를 만든다** (Allocate Local Variables). ESP에서 필요한 바이트 수를 뺀다.
6. **레지스터를 저장한다** (Save Registers). 프로시저가 바꿀 레지스터를 `PUSH`한다.

프로시저가 끝날 때(**에필로그** epilogue)는 거꾸로 한다. 저장한 레지스터를 꺼내고, ESP를 EBP로 되돌려 지역 변수를 없애고, EBP를 꺼낸 다음 `RET`으로 돌아간다. 완성된 프레임은 다음과 같다. 스택은 아래쪽(낮은 주소)으로 자라므로 나중에 넣은 것일수록 아래에 있다.

```text
 높은 주소
           +------------------+
 [EBP+12]  |  argument 2      |             1. 호출한 쪽이 넣은 인수
 [EBP+8]   |  argument 1      |
 [EBP+4]   |  return address  |             2. CALL이 넣은 복귀 주소
 [EBP]     |  saved EBP       |   <- EBP    3. 호출한 쪽의 EBP (4. 여기가 기준점)
 [EBP-4]   |  local 1         |             5. 지역 변수
 [EBP-8]   |  local 2         |
 [EBP-12]  |  saved register  |   <- ESP    6. 저장한 레지스터
           +------------------+
 낮은 주소
```

첫 번째 인수가 `[ebp+8]`인 이유는 그 사이에 4바이트짜리가 두 개 있기 때문이다. `[ebp]`에는 저장된 EBP가, `[ebp+4]`에는 복귀 주소가 있다. 인수와 지역 변수가 모두 EBP를 기준으로 **고정된 거리**에 있으므로, 프로시저 안에서 `PUSH`·`POP`을 몇 번 하든 같은 주소식으로 접근할 수 있다.

### 레지스터 매개변수의 단점 (Disadvantages of Register Parameters)

5장의 Irvine32 프로시저들은 인수를 레지스터로 받는다. 그런데 레지스터는 호출하는 쪽도 쓰고 있는 경우가 많다. 그래서 인수로 쓸 레지스터를 먼저 스택에 저장하고, 인수 값을 넣고, 호출이 끝나면 다시 원래 값으로 되살려야 한다(Any registers used as parameters must first be pushed on the stack before procedure calls, assigned the values of procedure arguments, and later restored to their original values after the procedure returns).

```asm
push  ebx                       ; save register values
push  ecx
push  esi
mov   esi,OFFSET array          ; starting OFFSET
mov   ecx,LENGTHOF array        ; size, in units
mov   ebx,TYPE array            ; doubleword format
call  DumpMem                   ; display memory
pop   esi                       ; restore register values
pop   ecx
pop   ebx
```

`DumpMem` 한 번 부르는 데 `PUSH` 세 번과 `POP` 세 번이 붙었다. 이런 코드는 읽기 어려울 뿐 아니라, 레지스터로 인수를 넘겨서 얻으려던 속도 이점까지 없애 버린다(Not only do all the extra pushes and pops create code clutter, they tend to eliminate the very performance advantage we hoped to gain by using register parameters).

> [!NOTE]
> **슬라이드 정정**: 슬라이드 3번은 "the performance advantage we hoped to gain by **avoiding** register parameters"라고 적었지만, 속도 이점은 레지스터 매개변수를 **쓸 때** 얻으려던 것이다. "by **using** register parameters"가 맞다.

레지스터 매개변수 자체가 나쁜 것은 아니다. 메모리(스택)보다 레지스터가 빠르므로, 저장·복원할 필요가 없는 경우라면 레지스터로 넘기는 편이 빠르다. 그래서 실제 호출 규약도 레지스터를 섞어 쓴다.

- **`__fastcall`** (Microsoft 32비트): 왼쪽부터 처음 두 개의 DWORD 이하 인수를 **ECX, EDX**로 넘기고 나머지는 스택에 오른쪽부터 넣는다. 인수는 호출된 함수가 치운다. 이름은 `@AddTwo@8`처럼 장식된다.
- **Microsoft x64 호출 규약**: 64비트에서는 처음 네 개의 정수 인수를 **RCX, RDX, R8, R9**로 넘기는 것이 기본이다([이 절 끝](#microsoft-x64-호출-규약-보충)에서 다룬다).

### 값 전달과 참조 전달 (Passing by Value and by Reference)

인수를 넘기는 방법은 두 가지다. 슬라이드 4번의 그림은 이 둘을 대비한다.

| 구분 | 스택에 넣는 것 | 호출된 쪽이 원래 변수를 바꿀 수 있나 | C 표현 |
|---|---|---|---|
| **값 전달** (pass by value) | 값의 **복사본** | 없다 (복사본만 바뀐다) | `AddTwo(val1, val2)` |
| **참조 전달** (pass by reference) | 변수의 **주소**(오프셋) | 있다 (주소를 따라가 바꾼다) | `Swap(&val1, &val2)` |

> [!NOTE]
> **슬라이드 정정**: 슬라이드 4번 그림의 큰 글씨 "VALVE"는 "VALUE"의 오타다.

#### 값 전달 (Passing by Value)

값으로 넘기면 변수의 값이 복사되어 스택에 들어간다(When an argument is passed by value, a copy of the value is pushed on the stack). C의 `int sum = AddTwo(val1, val2);`는 다음과 같이 번역된다. 인수를 오른쪽(`val2`)부터 넣으므로 첫 번째 인수 `val1`이 스택 맨 위에 온다.

```asm
.data
val1  DWORD 5
val2  DWORD 6
.code
push  val2
push  val1                      ; [ESP] = 5, [ESP+4] = 6
call  AddTwo                    ; EAX = 11
```

```text
           +------------------+
 (val2)    |  6               |
 (val1)    |  5               |   <- ESP
           +------------------+
```

#### 참조 전달 (Passing by Reference)

참조로 넘기면 변수의 **주소**가 스택에 들어간다(An argument passed by reference consists of the address (offset) of an object). 호출된 쪽은 이 주소를 따라가서 호출한 쪽의 변수를 직접 읽고 쓸 수 있다. C의 `Swap(&val1, &val2);`에 해당한다.

```asm
.data
val1  DWORD 5
val2  DWORD 6
.code
push  OFFSET val2
push  OFFSET val1
call  Swap                      ; val1 = 6, val2 = 5
```

```text
           +------------------+
           |  offset (val2)   |
           |  offset (val1)   |   <- ESP
           +------------------+
```

`Swap`이 돌아온 뒤 `val1`과 `val2`의 값이 서로 바뀌어 있다. 값으로 넘겼다면 `Swap`은 스택에 있는 복사본만 바꿀 수 있으므로 이런 일은 불가능하다.

#### 배열 전달 (Passing Arrays)

고급 언어는 배열을 언제나 참조로 넘긴다. 즉 배열의 **주소**를 스택에 넣는다(High-level languages always pass arrays to subroutines by reference). 원소가 50개인 배열을 값으로 넘기려면 50번 `PUSH`해야 하고 그만큼 스택을 차지하지만, 주소는 4바이트 하나면 된다.

```asm
.data
array DWORD 50 DUP(?)
.code
push  OFFSET array
call  ArrayFill
```

### 스택 매개변수 접근하기 (Accessing Stack Parameters)

C의 `AddTwo` 함수와 같은 일을 하는 어셈블리 프로시저를 보자. 프로시저는 `push ebp` / `mov ebp,esp`로 시작해 EBP를 프레임의 기준점(base of stack frame)으로 만든 다음, EBP에서 일정한 거리에 있는 인수를 꺼낸다.

```c
int AddTwo( int x, int y )
{
    return x + y;
}
```

```asm
; AddTwo: 스택으로 받은 두 정수를 더한다
INCLUDE Irvine32.inc

.code
main PROC
    push 6                  ; 두 번째 인수 y
    push 5                  ; 첫 번째 인수 x
    call AddTwo             ; EAX = 11
    add  esp,8              ; 인수 두 개(8바이트)를 치운다
    call WriteDec
    call Crlf
    exit
main ENDP

AddTwo PROC
    push ebp
    mov  ebp,esp            ; base of stack frame: EBP = ESP, [ebp+8] = 5, [ebp+12] = 6
    mov  eax,[ebp+12]       ; second parameter: EAX = 6
    add  eax,[ebp+8]        ; first parameter: EAX = 11
    pop  ebp
    ret
AddTwo ENDP
END main
```

실행 결과:

```text
11
```

`mov ebp,esp` 직후의 스택은 다음과 같다. 이때는 EBP와 ESP가 같은 곳을 가리킨다.

```text
           +------------------+
 [EBP+12]  |  6               |   y
 [EBP+8]   |  5               |   x
 [EBP+4]   |  return address  |
 [EBP]     |  EBP             |   <- EBP, ESP
           +------------------+
```

반환값은 **EAX**에 넣어 돌려준다. C 컴파일러도 32비트 정수 반환값을 EAX로 돌려주므로, 이 규칙을 지키면 어셈블리 프로시저를 C에서 부를 수 있다. `AddTwo`는 `ret`만 하므로 인수 8바이트는 호출한 쪽(`main`)이 `add esp,8`로 치웠다. 이것이 [C 호출 규약](#32비트-호출-규약-32-bit-calling-conventions)이다.

#### 왜 ESP가 아니라 EBP를 쓰는가 (보충)

ESP로도 인수를 읽을 수는 있다. 그러나 ESP는 `PUSH`·`POP`·`CALL`을 할 때마다 바뀌므로, 같은 인수라도 코드의 위치에 따라 주소식이 달라진다.

```asm
; ESP 기준으로 인수를 읽으면 PUSH할 때마다 거리가 바뀐다
INCLUDE Irvine32.inc

.code
main PROC
    push 5
    call ShowParam
    exit
main ENDP

ShowParam PROC
    mov  eax,[esp+4]        ; 인수는 지금 [esp+4]에 있다: EAX = 5
    push ebx                ; 하나를 넣으면
    mov  ebx,[esp+8]        ; 같은 인수가 [esp+8]로 밀려난다: EBX = 5
    pop  ebx
    ret  4
ShowParam ENDP
END main
```

EBP는 프롤로그에서 한 번 정하면 프로시저가 끝날 때까지 바뀌지 않으므로, 인수는 언제나 `[ebp+8]`, `[ebp+12]`, …에 있다. 다만 최적화하는 컴파일러는 EBP를 아껴 일반 레지스터로 쓰려고 ESP 기준 주소를 직접 계산하기도 한다(프레임 포인터 생략, frame pointer omission). [부록 B](#부록-b-c-컴파일러가-만든-스택-프레임)에서 실제 컴파일러 출력을 볼 수 있다.

#### 명시적 스택 매개변수 (Explicit Stack Parameters)

`[ebp+8]`처럼 오프셋을 상수로 직접 적어 매개변수를 가리키는 것을 **명시적 스택 매개변수**라고 한다(When stack parameters are referenced with expressions such as [ebp + 8], we call them explicit stack parameters). 숫자만 보면 무엇인지 알기 어려우므로 `EQU`로 이름을 붙여 쓰기도 한다.

```asm
y_param EQU [ebp + 12]
x_param EQU [ebp + 8]

AddTwo PROC
    push ebp
    mov  ebp,esp
    mov  eax,y_param        ; EAX = 6
    add  eax,x_param        ; EAX = 11
    pop  ebp
    ret
AddTwo ENDP
```

`EQU`는 글자를 그대로 바꿔 넣을 뿐이므로 `x_param`은 어디서 쓰든 `[ebp + 8]`이 된다. EBP가 이 프레임을 가리키고 있을 때만 올바른 값이라는 점에 주의한다.

### 스택 정리하기 (Cleaning Up the Stack)

프로시저가 돌아온 뒤에는 넣었던 인수를 스택에서 치워야 한다. 치우지 않으면 어떻게 되는지 보자. `main`이 `Example1`을 부르고, `Example1`은 인수 두 개를 넣고 `AddTwo`를 부른 다음 그냥 `ret`한다.

```asm
; 인수를 치우지 않아 스택이 무너지는 예
INCLUDE Irvine32.inc

.code
main PROC
    call Example1
    exit                    ; 실행되지 않는다
main ENDP

Example1 PROC
    push 6
    push 5
    call AddTwo             ; EAX = 11, [ESP] = 5, [ESP+4] = 6
    ret                     ; 5를 복귀 주소로 꺼내 주소 5로 점프한다: 접근 위반
Example1 ENDP

AddTwo PROC
    push ebp
    mov  ebp,esp
    mov  eax,[ebp+12]
    add  eax,[ebp+8]
    pop  ebp
    ret
AddTwo ENDP
END main
```

`AddTwo`에서 돌아왔을 때 스택 맨 위에는 `main`으로 돌아갈 복귀 주소가 아니라 인수 5가 있다(stack is corrupted!).

```text
           +------------------+
           |  return address  |   main으로 돌아갈 주소
           |  6               |
           |  5               |   <- ESP
           +------------------+
```

`RET`은 스택 맨 위의 값이 무엇이든 복귀 주소로 믿고 꺼내므로, 주소 5로 점프한다. 그 주소에는 코드가 없으므로 운영체제가 프로그램을 접근 위반(access violation)으로 멈춘다. 고치려면 `call AddTwo` 다음에 `add esp,8`을 넣어 인수 두 개(4바이트 × 2)를 치운다.

```asm
; 인수를 치운 올바른 예
INCLUDE Irvine32.inc

.code
main PROC
    call Example1           ; EAX = 11 (정상적으로 돌아온다)
    exit
main ENDP

Example1 PROC
    push 6
    push 5
    call AddTwo
    add  esp,8              ; 2개 × 4바이트 스택 정리
    ret                     ; 이제 [ESP]는 main으로 돌아갈 주소다
Example1 ENDP

AddTwo PROC
    push ebp
    mov  ebp,esp
    mov  eax,[ebp+12]
    add  eax,[ebp+8]
    pop  ebp
    ret
AddTwo ENDP
END main
```

### 32비트 호출 규약 (32-Bit Calling Conventions)

**호출 규약**(calling convention)은 인수를 넣는 순서, 인수를 치우는 쪽, 반환값을 돌려주는 곳, 보존해야 할 레지스터 등을 정한 약속이다. 호출하는 쪽과 호출되는 쪽이 같은 규약을 따라야 한다. 32비트 Windows 프로그램에서 많이 쓰는 것은 C 규약과 STDCALL 규약이다.

#### C 호출 규약 (The C Calling Convention)

C와 C++이 쓰는 규약이다. 인수를 **역순**(오른쪽부터)으로 넣으므로 `AddTwo(A, B)`를 부를 때는 B를 먼저, A를 나중에 넣는다(Subroutine parameters are pushed on the stack in reverse order). 그리고 **호출한 쪽**이 `CALL` 바로 다음에 ESP에 인수 크기를 더해 인수를 치운다.

```asm
Example1 PROC
    push  6
    push  5
    call  AddTwo
    add   esp,8                 ; remove arguments from the stack
    ret
Example1 ENDP
```

#### STDCALL 호출 규약 (STDCALL Calling Convention)

인수를 넣는 순서는 C 규약과 같지만, 인수를 **호출된 쪽**이 치운다. `RET`에 정수 피연산자를 주면, `RET`은 복귀 주소를 꺼낸 다음 ESP에 그 값을 더한다. 이 정수는 매개변수가 차지한 스택 바이트 수와 같아야 한다(The integer must equal the number of bytes of stack space consumed by the procedure's parameters).

```asm
AddTwo PROC
    push  ebp
    mov   ebp,esp               ; base of stack frame
    mov   eax,[ebp + 12]        ; second parameter
    add   eax,[ebp + 8]         ; first parameter
    pop   ebp
    ret   8                     ; clean up the stack
AddTwo ENDP
```

두 규약을 한 프로그램에서 비교해 보자. 호출 전의 ESP를 EBX에 기억해 두고, 호출이 끝난 뒤 ESP가 원래대로 돌아왔는지 본다.

```asm
; C 규약과 STDCALL 규약 비교
INCLUDE Irvine32.inc

.code
main PROC
    mov  ebx,esp            ; 호출 전 ESP를 기억해 둔다
    ; C 규약: 호출한 쪽이 인수를 치운다
    push 6
    push 5
    call AddTwo_C           ; EAX = 11, ESP = EBX-8
    add  esp,8              ; ESP = EBX
    ; STDCALL: 호출된 쪽이 ret 8로 치운다
    push 6
    push 5
    call AddTwo_Std         ; EAX = 11, ESP = EBX
    exit
main ENDP

AddTwo_C PROC
    push ebp
    mov  ebp,esp
    mov  eax,[ebp+12]
    add  eax,[ebp+8]
    pop  ebp
    ret                     ; 복귀 주소만 꺼낸다
AddTwo_C ENDP

AddTwo_Std PROC
    push ebp
    mov  ebp,esp
    mov  eax,[ebp+12]
    add  eax,[ebp+8]
    pop  ebp
    ret  8                  ; 복귀 주소를 꺼낸 다음 ESP에 8을 더한다
AddTwo_Std ENDP
END main
```

`AddTwo_C`에서 돌아온 직후에는 인수 8바이트가 아직 남아 있어(ESP = EBX − 8) 호출한 쪽이 치워야 하고, `AddTwo_Std`에서 돌아온 직후에는 이미 치워져 있다.

| 구분 | C 규약 (`cdecl`) | STDCALL 규약 |
|---|---|---|
| 인수를 넣는 순서 | 오른쪽 → 왼쪽 | 오른쪽 → 왼쪽 |
| 인수를 치우는 쪽 | 호출한 쪽 (`add esp,n`) | 호출된 쪽 (`ret n`) |
| 프로시저의 복귀 명령어 | `ret` | `ret n` |
| 인수 개수가 정해지지 않은 함수 | 만들 수 있다 (`printf`) | 만들 수 없다 (`n`이 상수) |
| 코드 크기 | 호출할 때마다 `add esp,n`이 붙는다 | `ret n` 하나로 끝난다 |
| Microsoft의 이름 장식 | `_AddTwo` | `_AddTwo@8` (인수 바이트 수) |
| 주로 쓰는 곳 | C/C++의 기본 규약 | Windows API, Irvine32 라이브러리 |

C 규약에서 가변 인수가 가능한 이유는 인수를 몇 개 넣었는지 **호출한 쪽만** 알기 때문이다. `printf`는 형식 문자열을 읽어야 인수 개수를 알 수 있으므로 `ret n`의 n을 미리 정할 수 없다. 그래서 Microsoft 컴파일러도 가변 인수 함수는 STDCALL로 선언해도 C 규약으로 만든다.

### 레지스터 저장과 복원 (Saving and Restoring Registers)

프로시저는 바꿀 레지스터의 값을 먼저 스택에 저장해 두었다가 돌아가기 전에 되살리는 경우가 많다(Subroutines often save the current contents of registers on the stack before modifying them). 저장은 **`mov ebp,esp` 다음에** 한다. 그래야 EBP에서 매개변수까지의 거리가 레지스터를 몇 개 저장하든 바뀌지 않는다.

```asm
; 레지스터를 저장하고 되살리는 프로시저
INCLUDE Irvine32.inc

.code
main PROC
    mov  ecx,1111h
    mov  edx,2222h
    push 5
    call MySub              ; EAX = 5, ECX = 1111h, EDX = 2222h
    exit
main ENDP

MySub PROC
    push ebp                ; save base pointer
    mov  ebp,esp            ; base of stack frame
    push ecx
    push edx                ; save EDX: [ebp-4] = 1111h, [ebp-8] = 2222h
    mov  eax,[ebp+8]        ; get the stack parameter: EAX = 5
    mov  ecx,0              ; 이제 ECX와 EDX를 마음대로 써도 된다
    mov  edx,0
    pop  edx                ; restore saved registers
    pop  ecx
    pop  ebp                ; restore base pointer
    ret  4                  ; clean up the stack (인수 4바이트)
MySub ENDP
END main
```

`push edx`까지 실행한 뒤의 프레임은 다음과 같다.

```text
           +------------------+
 [EBP+8]   |  (parameter)     |
 [EBP+4]   |  return address  |
 [EBP]     |  EBP             |   <- EBP
 [EBP-4]   |  ECX             |
 [EBP-8]   |  EDX             |   <- ESP
           +------------------+
```

마지막 `RET`은 `[EBP+4]` 자리에 있던 복귀 주소를 꺼내 호출한 함수로 돌아간다. 반환값을 EAX로 돌려주는 프로시저는 EAX를 저장·복원하면 안 된다. 되살리는 순간 반환값이 지워지기 때문이다.

> [!NOTE]
> **슬라이드 정정**: 슬라이드 12번의 `MySub`는 마지막 줄이 `ret ; clean up the stack`이다. 그런데 `RET`만으로는 복귀 주소만 꺼낼 뿐 인수는 치우지 않는다. 주석대로 인수를 치우려면 위 코드처럼 `ret 4`로 써야 한다(교재 예제 파일 `UsesTest.asm`의 같은 프로시저도 `ret 4`다). `ret`으로 두려면 C 규약처럼 호출한 쪽이 `add esp,4`를 해야 한다.

### 지역 변수 (Local Variables)

고급 언어에서 한 서브루틴 안에서 만들어지고, 쓰이고, 사라지는 변수를 **지역 변수**(local variable)라고 한다. 지역 변수는 실행 중에 스택에 만들어지며, 보통 EBP **아래**에 놓인다(Local variables are created on the runtime stack, usually below the base pointer (EBP)).

```c
void MySub()
{
    int X = 10;
    int Y = 20;
}
```

| 변수 (Variable) | 크기 (Bytes) | 스택 위치 (Stack Offset) |
|---|---|---|
| X | 4 | EBP − 4 |
| Y | 4 | EBP − 8 |

```asm
; 스택에 지역 변수 두 개 만들기
INCLUDE Irvine32.inc

.code
main PROC
    call MySub
    exit
main ENDP

MySub PROC
    push ebp
    mov  ebp,esp
    sub  esp,8                      ; create locals: ESP = EBP-8
    mov  DWORD PTR [ebp-4],10       ; X: [ebp-4] = 10
    mov  DWORD PTR [ebp-8],20       ; Y: [ebp-8] = 20
    mov  esp,ebp                    ; remove locals from stack: ESP = EBP
    pop  ebp
    ret
MySub ENDP
END main
```

```text
           +------------------+
           |  return address  |
           |  EBP             |   <- EBP
 [EBP-4]   |  10 (X)          |
 [EBP-8]   |  20 (Y)          |   <- ESP
           +------------------+
```

`sub esp,8`은 ESP를 8바이트 내려 그 사이를 지역 변수 자리로 만든다. 끝내기 전에 `mov esp,ebp`로 ESP를 EBP 값으로 되돌리면 지역 변수가 한꺼번에 스택에서 풀려난다(Before finishing, the function resets the stack pointer by assigning it the value of EBP. The effect is to release the local variables from the stack). 메모리를 지우는 것은 아니고, ESP가 그 위로 올라가서 "빈 자리"로 취급될 뿐이다.

매개변수처럼 지역 변수에도 `EQU`로 이름을 붙일 수 있다(교재 예제 `LocalVars.asm`).

```asm
X_local EQU DWORD PTR [ebp-4]
Y_local EQU DWORD PTR [ebp-8]

MySub PROC
    push ebp
    mov  ebp,esp
    sub  esp,8              ; create variables
    mov  X_local,20         ; [ebp-4] = 20
    mov  Y_local,10         ; [ebp-8] = 10
    mov  esp,ebp            ; remove locals from stack
    pop  ebp
    ret
MySub ENDP
```

#### 지역 변수는 초기화되지 않는다 (보충)

`sub esp,8`은 자리만 만들 뿐 값을 넣지 않는다. 그래서 지역 변수에는 **그 자리를 마지막으로 쓴 누군가의 값**이 남아 있다. 다음 프로그램에서 `GetLocal`은 지역 변수에 아무것도 넣지 않았는데, 바로 전에 같은 깊이에서 실행된 `SetLocal`이 남긴 값을 읽는다.

```asm
; 초기화하지 않은 지역 변수에는 이전 값이 남아 있다
INCLUDE Irvine32.inc

.code
main PROC
    call SetLocal
    call GetLocal           ; EAX = 1234
    exit
main ENDP

SetLocal PROC
    push ebp
    mov  ebp,esp
    sub  esp,4
    mov  DWORD PTR [ebp-4],1234     ; 지역 변수에 1234를 넣고 돌아간다
    mov  esp,ebp
    pop  ebp
    ret
SetLocal ENDP

GetLocal PROC
    push ebp
    mov  ebp,esp
    sub  esp,4                      ; 같은 자리에 지역 변수를 만들고
    mov  eax,[ebp-4]                ; 초기화하지 않고 읽으면: EAX = 1234
    mov  esp,ebp
    pop  ebp
    ret
GetLocal ENDP
END main
```

C에서 초기화하지 않은 지역 변수의 값이 "쓰레기 값"인 이유가 이것이다. 지역 변수는 쓰기 전에 반드시 값을 넣어야 한다.

#### 지역 변수의 주소를 돌려주면 안 된다 (보충)

반대로, 프로시저가 돌아간 뒤에는 그 프레임 자리를 **다음 호출이 다시 쓴다**. 그래서 지역 변수의 주소를 반환값으로 돌려주면, 그 주소에 있는 값은 곧 다른 값으로 바뀐다. C에서 지역 배열의 포인터를 반환하면 안 되는 이유다.

```asm
; 사라진 지역 변수를 가리키는 포인터
INCLUDE Irvine32.inc

.code
main PROC
    call BadProc            ; EAX에 BadProc의 지역 변수 주소가 들어온다
    mov  ebx,[eax]          ; 아직은 남아 있다: EBX = 99
    call OtherProc          ; 다른 프로시저를 한 번만 불러도
    mov  ebx,[eax]          ; 그 자리가 덮어쓰인다: EBX = 5555h
    exit
main ENDP

BadProc PROC
    push ebp
    mov  ebp,esp
    sub  esp,4
    mov  DWORD PTR [ebp-4],99
    lea  eax,[ebp-4]                ; 지역 변수의 주소를 돌려준다 (잘못)
    mov  esp,ebp
    pop  ebp
    ret
BadProc ENDP

OtherProc PROC
    push ebp
    mov  ebp,esp
    sub  esp,4
    mov  DWORD PTR [ebp-4],5555h    ; 같은 자리를 자기 지역 변수로 쓴다
    mov  esp,ebp
    pop  ebp
    ret
OtherProc ENDP
END main
```

`lea eax,[ebp-4]`는 다음 절에서 다룬다. EBP − 4라는 **주소**를 EAX에 넣는 명령어다.

### 참조 매개변수 (Reference Parameters)

참조 매개변수는 보통 EBP 기준의 **베이스-오프셋 주소 지정**으로 다룬다(Reference parameters are usually accessed by procedures using base-offset addressing (from EBP)). 매개변수 자체는 주소이므로, 먼저 그 주소를 레지스터에 꺼낸 다음 그 레지스터로 간접 주소 지정을 한다.

`ArrayFill`은 16비트 정수 배열을 의사 난수(pseudorandom)로 채운다(fills an array with a pseudorandom sequence of 16-bit integers). 배열의 주소와 원소 개수를 스택으로 받는다.

```asm
; ArrayFill: 배열을 16비트 의사 난수로 채운다
INCLUDE Irvine32.inc

.data
count = 5
array WORD count DUP(?)

.code
main PROC
    push OFFSET array       ; 배열의 주소: [ebp+12]가 된다
    push count              ; 원소 개수: [ebp+8]이 된다
    call ArrayFill
    ; 결과 확인: 원소를 하나씩 16진수로 출력한다
    mov  esi,OFFSET array
    mov  ecx,count
L1: movzx eax,WORD PTR [esi]
    call WriteHex
    call Crlf
    add  esi,TYPE WORD
    loop L1
    exit
main ENDP

ArrayFill PROC
    push ebp
    mov  ebp,esp
    pushad                  ; save registers
    mov  esi,[ebp+12]       ; offset of array
    mov  ecx,[ebp+8]        ; array length: ECX = 5
    cmp  ecx,0              ; ECX == 0?
    je   L2                 ; yes: skip over loop (점프하지 않는다)
L1:
    mov  eax,10000h         ; get random 0 - FFFFh
    call RandomRange        ; from the link library
    mov  [esi],ax           ; insert value in array
    add  esi,TYPE WORD      ; move to next element
    loop L1
L2: popad                   ; restore registers
    pop  ebp
    ret  8                  ; clean up the stack
ArrayFill ENDP
END main
```

실행 결과:

```text
000029E2
000023F6
0000BE87
00008471
0000E1DF
```

```text
           +------------------+
 [EBP+12]  |  offset (array)  |
 [EBP+8]   |  count           |
           |  return address  |
           |  EBP             |   <- EBP, ESP
           +------------------+
```

`mov esi,[ebp+12]`로 꺼낸 것은 배열의 **주소**이고, 실제 원소는 `[esi]`로 쓴다. `ArrayFill`이 바꾼 것은 `main`의 `array` 자체이므로, 돌아온 뒤 `main`에서 바뀐 값을 볼 수 있다.

> [!TIP]
> 위 출력은 `Randomize`를 부르지 않았을 때의 값이다. Irvine32의 `Random32`는 시드(seed)를 1로 시작하는 선형 합동 생성기이므로, `Randomize`를 부르지 않으면 실행할 때마다 같은 수열이 나온다. 디버깅할 때는 이 성질이 오히려 편리하다. 실행할 때마다 다른 값을 원하면 프로그램 시작 부분에서 `call Randomize`를 한 번 한다.

### LEA 명령어 (LEA Instruction)

`LEA`(load effective address)는 간접 피연산자의 **주소**를 계산해 레지스터에 넣는다(The LEA instruction returns the address of an indirect operand). 메모리에서 값을 읽지 않는다는 점이 `MOV`와 다르다. 스택에 있는 지역 변수의 주소는 실행할 때 EBP 값에 따라 정해지므로, 어셈블할 때 주소를 계산하는 `OFFSET`으로는 구할 수 없고 `LEA`를 써야 한다.

다음 C 함수는 지역 배열 `myString`을 `'*'`로 채운다.

```c
void makeArray( )
{
    char myString[30];
    for( int i = 0; i < 30; i++ )
        myString[i] = '*';
}
```

```asm
; makeArray: 스택에 만든 문자 배열을 '*'로 채운다
INCLUDE Irvine32.inc

.code
main PROC
    call makeArray
    exit
main ENDP

makeArray PROC
    push ebp
    mov  ebp,esp
    sub  esp,32                     ; myString is at EBP-30: ESP = EBP-32
    lea  esi,[ebp-30]               ; load address of myString: ESI = EBP-30
    mov  ecx,30                     ; loop counter
L1: mov  BYTE PTR [esi],'*'         ; fill one position
    inc  esi                        ; move to next
    loop L1                         ; continue until ECX = 0 (끝나면 ECX = 0, ESI = EBP)
    add  esp,32                     ; remove the array: ESP = EBP, BYTE PTR [ebp-30] = 2Ah
    pop  ebp
    ret
makeArray ENDP
END main
```

배열은 30바이트인데 ESP를 32 내린 것은 ESP를 4의 배수로 유지하기 위해서다. 32비트 스택은 4바이트 단위로 쓰이므로 ESP가 4의 배수가 아니면 이후의 `PUSH`·`POP`이 모두 어긋난 주소에서 일어나 느려진다. 남는 2바이트(EBP − 32, EBP − 31)는 쓰지 않는다.

> [!NOTE]
> **슬라이드 정정**: 슬라이드 16번의 `lea esi,[ebp–30]`과 주석 `EBP–30`의 빼기 기호는 하이픈(`-`)이 아니라 대시(`–`)다. 그대로 복사해 어셈블하면 오류가 나므로 `[ebp-30]`으로 고쳐 써야 한다.

`OFFSET`과 `LEA`, 그리고 `MOV`의 차이를 정리하면 다음과 같다.

| 명령어 | ESI에 들어가는 것 | 계산 시점 |
|---|---|---|
| `mov esi,OFFSET var` | 전역 변수 `var`의 주소 | 어셈블·링크할 때 (상수) |
| `lea esi,[ebp-30]` | 주소 EBP − 30 | 실행할 때 |
| `mov esi,[ebp-30]` | 주소 EBP − 30에 **들어 있는 4바이트 값** | 실행할 때 (메모리를 읽는다) |

`OFFSET`에 레지스터가 들어간 주소식을 주면 어셈블러는 값을 계산할 수 없으므로 오류를 낸다.

```asm
mov  esi,OFFSET [ebp-30]        ; 어셈블 오류
lea  esi,[ebp-30]               ; 이렇게 써야 한다
```

#### LEA로 계산하기 (보충)

`LEA`는 메모리를 건드리지 않고 주소식만 계산하므로, "베이스 + 인덱스 × 배율 + 변위" 꼴의 산술에도 쓸 수 있다. 플래그도 바꾸지 않는다.

```asm
mov  ebx,100
mov  ecx,3
lea  eax,[ebx+ecx*4+8]          ; EAX = 120 (100 + 3 × 4 + 8)
lea  edx,[eax+eax*4]            ; EDX = 600 (EAX × 5)
```

### ENTER와 LEAVE 명령어 (ENTER and LEAVE Instructions)

`ENTER`는 호출된 프로시저의 스택 프레임을 자동으로 만든다. EBP를 스택에 저장하고, EBP를 프레임의 기준점으로 정하고, 지역 변수 자리를 확보한다(It reserves stack space for local variables and saves EBP on the stack).

1. **Push EBP**: 현재의 EBP를 스택에 넣는다.
2. **Set EBP**: EBP를 현재 ESP로 바꾼다.
3. **Reserve Space**: 지역 변수에 필요한 바이트만큼 ESP를 내린다.

```text
ENTER numbytes, nestinglevel
```

피연산자는 두 개다. 첫 번째는 지역 변수용으로 확보할 바이트 수, 두 번째는 프로시저의 **어휘적 중첩 수준**(lexical nesting level)이다(The first is a constant specifying the number of bytes of stack space to reserve for local variables and the second specifies the lexical nesting level of the procedure). C·C++·어셈블리에서는 두 번째 피연산자를 항상 0으로 쓴다.

| `ENTER` | 같은 일을 하는 명령어 |
|---|---|
| `enter 0,0` | `push ebp` / `mov ebp,esp` |
| `enter 8,0` | `push ebp` / `mov ebp,esp` / `sub esp,8` |

```text
 Before                          After executing ENTER 8,0
 +------------------+            +------------------+
 |                  |  <- ESP    |                  |
 |                  |            |  EBP             |  <- EBP
 |                  |            |  ????            |
 |                  |            |  ????            |  <- ESP
 +------------------+            +------------------+
```

`ENTER`로 확보한 자리(그림의 물음표)는 초기화되지 않는다.

`LEAVE`는 프레임을 없앤다. ESP와 EBP를 프로시저가 호출되었을 때의 값으로 되돌려 `ENTER`가 한 일을 거꾸로 한다(It reverses the action of a previous ENTER instruction by restoring ESP and EBP to the values they were assigned when the procedure was called). 즉 `mov esp,ebp` / `pop ebp`와 같다.

| 프로시저 (`ENTER`/`LEAVE`) | 같은 일을 하는 명령어 |
|---|---|
| `enter 8,0` … `leave` / `ret` | `push ebp` / `mov ebp,esp` / `sub esp,8` … `mov esp,ebp` / `pop ebp` / `ret` |

직접 실행해서 확인해 보자. 진입 직후의 ESP와 EBP를 EBX와 EDX에 기억해 두고, `LEAVE` 뒤에 그대로 돌아왔는지 본다.

```asm
; ENTER와 LEAVE가 하는 일 확인하기
INCLUDE Irvine32.inc

.code
main PROC
    call MySub
    exit
main ENDP

MySub PROC
    mov  ebx,esp            ; 확인용: 진입 직후의 ESP
    mov  edx,ebp            ; 확인용: 호출한 쪽의 EBP
    enter 8,0               ; EBP = EBX-4, ESP = EBP-8
    mov  eax,[ebp]          ; 저장된 EBP는 호출한 쪽의 EBP: EAX = EDX
    mov  DWORD PTR [ebp-4],1        ; 지역 변수 두 개를 쓴다
    mov  DWORD PTR [ebp-8],2
    leave                   ; ESP = EBX, EBP = EDX
    ret
MySub ENDP
END main
```

`ENTER`를 쓴다면 같은 프로시저의 끝에서 `LEAVE`도 쓰는 것이 좋다(If you use the ENTER instruction, it is strongly advised that you also use the LEAVE instruction at the end of the same procedure). 그렇지 않으면 확보한 지역 변수 자리가 풀리지 않아 `RET`이 복귀 주소 대신 지역 변수를 꺼내게 된다. 반대로 `LEAVE`는 `ENTER` 없이도 쓸 수 있다. `push ebp` / `mov ebp,esp` / `sub esp,n`으로 직접 만든 프레임도 `LEAVE` 하나로 정리된다.

#### 실제로는 ENTER를 잘 쓰지 않는다 (보충)

`ENTER`는 세 명령어를 4바이트짜리 명령어 하나로 줄여 주지만, 세 명령어를 따로 실행하는 것보다 **느리다**. 그래서 요즘 컴파일러는 `ENTER` 대신 `push ebp` / `mov ebp,esp` / `sub esp,n`을 쓴다. 반면 `LEAVE`는 두 명령어보다 빨라서 컴파일러도 즐겨 쓴다([부록 B](#부록-b-c-컴파일러가-만든-스택-프레임)의 GCC 출력에서 볼 수 있다).

두 번째 피연산자인 중첩 수준은 파스칼처럼 프로시저 안에 프로시저를 정의할 수 있는 언어를 위한 것이다. 0이 아니면 `ENTER`는 바깥 프로시저들의 프레임 포인터를 새 프레임에 복사해 둔다(디스플레이 display). 중첩 수준이 1이면 새 프레임 포인터 하나가 더 들어가므로 4바이트를 더 쓴다. 중첩 수준은 하위 5비트만 쓰이므로 0~31 범위다.

```asm
; ENTER의 중첩 수준이 1이면 프레임 포인터 하나가 더 들어간다
INCLUDE Irvine32.inc

.code
main PROC
    call Nested
    exit
main ENDP

Nested PROC
    mov  ebx,esp
    enter 8,1               ; EBP = EBX-4, ESP = EBP-12
    mov  eax,[ebp-4]        ; [ebp-4]에는 새 EBP의 복사본: EAX = EBP
    leave                   ; ESP = EBX
    ret
Nested ENDP
END main
```

### LOCAL 지시어 (LOCAL Directive)

`LOCAL`은 지역 변수를 **이름과 크기 속성**을 붙여 선언한다. `ENTER`는 이름 없는 공간을 한 덩어리로 확보할 뿐이다(LOCAL declares one or more local variables by name, assigning them size attributes. ENTER, on the other hand, only reserves a single unnamed block of stack space for local variables).

```text
LOCAL varlist

varlist의 각 항목:  label:type
```

```asm
MySub PROC
    LOCAL var1:BYTE
    ret
MySub ENDP

BubbleSort PROC
    LOCAL temp:DWORD, SwapFlag:BYTE
    ret
BubbleSort ENDP

Merge PROC
    LOCAL pArray:PTR WORD
    LOCAL TempArray[10]:DWORD
    ret
Merge ENDP
```

`LOCAL`을 쓰면 어셈블러가 프롤로그(`push ebp` / `mov ebp,esp` / ESP 내리기)와 에필로그(`mov esp,ebp` / `pop ebp`)를 대신 만들어 주고, 각 변수 이름을 EBP 기준 주소로 바꿔 준다. `BubbleSort`의 두 변수가 실제로 어디에 놓이는지 확인해 보자.

```asm
; LOCAL로 만든 지역 변수의 위치
INCLUDE Irvine32.inc

.code
main PROC
    call BubbleSort
    exit
main ENDP

BubbleSort PROC
    LOCAL temp:DWORD, SwapFlag:BYTE
    mov  temp,12345678h     ; [ebp-4] = 12345678h
    mov  SwapFlag,1         ; BYTE PTR [ebp-5] = 1
    ret                     ; mov esp,ebp / pop ebp / ret으로 바뀐다
BubbleSort ENDP
END main
```

어셈블러가 만든 코드는 다음과 같다. ESP를 내리는 방법만 어셈블러마다 조금 다르다.

```text
BubbleSort PROC
    push ebp
    mov  ebp,esp
    sub  esp,8                  ; MASM은 add esp,0FFFFFFF8h (-8 더하기)로 만든다
    mov  DWORD PTR [ebp-4],12345678h     ; temp
    mov  BYTE PTR [ebp-5],1              ; SwapFlag
    mov  esp,ebp
    pop  ebp
    ret
BubbleSort ENDP
```

| 선언 | 위치 | 설명 |
|---|---|---|
| `temp:DWORD` | `[ebp-4]` | 4바이트 |
| `SwapFlag:BYTE` | `[ebp-5]` | 1바이트, `temp` 바로 아래 |
| (합계) | ESP를 8 내림 | 5바이트를 4의 배수로 올림 |

`LOCAL` 선언은 `PROC` 줄 바로 다음에 와야 한다. 명령어 뒤에 쓰면 어셈블 오류가 난다.

```asm
Later PROC
    mov  eax,0
    LOCAL t:DWORD           ; 어셈블 오류
    ret
Later ENDP
```

`LOCAL`의 장점은 이름으로 지역 변수를 쓸 수 있다는 것(오프셋을 직접 계산하지 않아도 된다), 크기 속성이 붙어 `mov SwapFlag,1`처럼 `BYTE PTR` 없이도 크기가 정해진다는 것이다. 매개변수 이름까지 붙이는 방법(`PROC`의 매개변수 목록)은 [8.4절](#proc-지시어-proc-directive)에서 다룬다. 바이트·워드 지역 변수가 섞일 때의 배치는 [8.6절](#더블워드가-아닌-지역-변수-non-doubleword-local-variables)에서 더 자세히 본다.

### Microsoft x64 호출 규약 (보충)

교재 8.2.10절에 해당하지만 슬라이드에는 없는 내용이다. 64비트 Windows에는 호출 규약이 사실상 **하나**뿐이고, 레지스터를 적극적으로 쓴다.

| 항목 | 규칙 |
|---|---|
| 처음 네 개의 정수·포인터 인수 | 왼쪽부터 **RCX, RDX, R8, R9** |
| 다섯 번째 이후의 인수 | 스택에 (오른쪽부터) |
| 부동소수점 인수 | XMM0~XMM3 |
| 섀도 공간 (shadow space, home space) | 호출한 쪽이 **32바이트**(레지스터 인수 4개 분량)를 항상 확보한다. 인수가 4개보다 적어도 마찬가지다 |
| 스택 정렬 | 프롤로그·에필로그 밖에서는 RSP가 **16의 배수** |
| 반환값 | 64비트 이하 정수는 RAX |
| 인수 자리를 마련하고 치우는 쪽 | 호출한 쪽 |
| 호출된 쪽이 보존해야 하는 레지스터 | RBX, RBP, RDI, RSI, RSP, R12~R15, XMM6~XMM15 |
| 마음대로 바꿔도 되는 레지스터 | RAX, RCX, RDX, R8~R11, XMM0~XMM5 |

섀도 공간은 호출된 함수가 필요하면 RCX·RDX·R8·R9를 저장해 둘 수 있도록 마련한 자리다. 호출 직전에 RSP가 16의 배수여야 하는데, `CALL`이 8바이트 복귀 주소를 넣으므로 함수에 들어온 직후의 RSP는 16의 배수보다 8 작다. 그래서 다른 함수를 부르는 함수는 보통 `sub rsp,28h`(섀도 공간 20h + 정렬용 8)로 시작한다.

```asm
; 64비트 모드 예 (ml64)
AddFour PROC
    mov  rax,rcx            ; 첫 번째 인수
    add  rax,rdx            ; 두 번째 인수
    add  rax,r8             ; 세 번째 인수
    add  rax,r9             ; 네 번째 인수
    ret
AddFour ENDP

CallAddFour PROC
    sub  rsp,28h            ; 섀도 공간 32바이트 + 정렬용 8바이트
    mov  rcx,1
    mov  rdx,2
    mov  r8,3
    mov  r9,4
    call AddFour            ; RAX = 10
    add  rsp,28h            ; 호출한 쪽이 치운다
    ret
CallAddFour ENDP

AddFive PROC
    mov  rax,rcx
    add  rax,rdx
    add  rax,r8
    add  rax,r9
    add  rax,[rsp+28h]      ; 다섯 번째 인수: 복귀 주소(8) + 섀도 공간(20h) 위
    ret
AddFive ENDP

CallAddFive PROC
    sub  rsp,38h            ; 섀도 공간 20h + 다섯 번째 인수 8 + 정렬용 8
    mov  QWORD PTR [rsp+20h],5      ; 다섯 번째 인수는 섀도 공간 바로 위에 둔다
    mov  rcx,1
    mov  rdx,2
    mov  r8,3
    mov  r9,4
    call AddFive            ; RAX = 15
    add  rsp,38h
    ret
CallAddFive ENDP
```

`AddFive`에 들어온 직후의 스택은 다음과 같다.

```text
           +------------------+
 [RSP+28h] |  5               |   다섯 번째 인수
 [RSP+8]   |  shadow (32 B)   |   RCX, RDX, R8, R9 저장용 자리
 [RSP]     |  return address  |   <- RSP
           +------------------+
```

32비트의 STDCALL과 달리 64비트에서는 인수 자리를 호출한 쪽이 한 번에 확보하고 치우므로 `ret n`을 쓰지 않는다. 또 64비트 MASM(ml64)에는 `INVOKE`가 없어서 이렇게 레지스터와 스택을 직접 채워야 한다.

---

## 8.3 재귀 (Recursion)

**재귀 서브루틴**(recursive subroutine)은 자기 자신을 직접 또는 간접으로 부르는 서브루틴이다(A recursive subroutine is one that calls itself, either directly or indirectly). A가 A를 부르면 직접 재귀, A가 B를 부르고 B가 다시 A를 부르면 간접 재귀다. 재귀가 가능한 것은 호출할 때마다 **새 스택 프레임**이 만들어지기 때문이다. 같은 프로시저라도 호출마다 자기만의 인수, 복귀 주소, 지역 변수를 따로 가진다.

### 끝없는 재귀 (Endless Recursion)

종료 조건이 없는 재귀는 멈추지 않는다.

```asm
; Endless Recursion            (Endless.asm)
INCLUDE Irvine32.inc

.data
endlessStr BYTE "This recursion never stops",0

.code
main PROC
    call Endless
    exit                    ; 실행되지 않는다
main ENDP

Endless PROC
    mov  edx,OFFSET endlessStr
    call WriteString
    call Endless
    ret                     ; never executes (실행되지 않는다)
Endless ENDP
END main
```

`Endless`는 호출될 때마다 복귀 주소 4바이트를 스택에 쌓기만 하고 `RET`에 이르지 못한다. 스택은 크기가 정해져 있으므로(Visual Studio로 만든 32비트 프로그램의 기본 스택 예약 크기는 1MB다) 결국 스택의 끝에 닿고, 운영체제가 **스택 오버플로**(stack overflow) 예외로 프로그램을 멈춘다. Windows에서 이 예외의 코드는 `0xC00000FD`(`STATUS_STACK_OVERFLOW`)다. 리눅스에서 같은 코드를 실행하면 메시지를 수없이 출력한 뒤 스택 영역 밖을 건드려 SIGSEGV로 끝난다.

### 재귀로 합 구하기 (Recursively Calculating a Sum)

쓸모 있는 재귀 서브루틴에는 반드시 **종료 조건**(terminating condition)이 있다. 조건이 참이 되면 더 이상 자신을 부르지 않고 돌아가기 시작한다. `CalcSum`은 1부터 n까지의 합을 재귀로 구한다. 카운터 ECX가 0이 되면 끝난다.

```asm
; Sum of Integers              (RecursiveSum.asm)
INCLUDE Irvine32.inc

.code
main PROC
    mov  ecx,5              ; count = 5
    mov  eax,0              ; holds the sum
    call CalcSum            ; calculate sum: EAX = 15
L1: call WriteDec           ; display EAX
    call Crlf               ; new line
    exit
main ENDP

;---------------------------------------------------
CalcSum PROC
; Calculates the sum of a list of integers
; Receives: ECX = count
; Returns:  EAX = sum
;---------------------------------------------------
    cmp  ecx,0              ; check counter value
    jz   L2                 ; quit if zero
    add  eax,ecx            ; otherwise, add to sum: EAX = 5 → 9 → 12 → 14 → 15 차례로
    dec  ecx                ; decrement counter: ECX = 4 → 3 → 2 → 1 → 0 차례로
    call CalcSum            ; recursive call
L2: ret
CalcSum ENDP
END main
```

실행 결과:

```text
15
```

`CalcSum`의 처음 두 줄은 카운터를 검사해 ECX = 0이면 프로시저를 빠져나간다. 그러면 더 이상 재귀 호출을 하지 않는다. `RET`에 처음 도달하면 바로 전의 `CalcSum` 호출로 돌아가고, 그것은 다시 그 전의 호출로 돌아가는 식으로 차례로 풀린다(When the RET instruction is reached for the first time, it returns to the previous call to CalcSum, which returns to its previous call, and so on).

> [!NOTE]
> **슬라이드 정정**: 슬라이드 24번의 "exit the procedure when ECX 0"은 등호가 빠졌다. "when ECX **=** 0"이다.

다음 표는 `CALL`이 실행될 때마다 스택에 들어가는 복귀 주소와 그 순간의 ECX·EAX 값이다(교재 Table 8-1).

| 스택에 들어가는 복귀 주소 (Pushed on Stack) | ECX | EAX |
|---|---|---|
| L1 (`main`의 `call CalcSum` 다음) | 5 | 0 |
| L2 | 4 | 5 |
| L2 | 3 | 9 |
| L2 | 2 | 12 |
| L2 | 1 | 14 |
| L2 | 0 | 15 |

`CalcSum` 안의 `call CalcSum` 다음 명령어가 `L2: ret`이므로, 재귀 호출이 넣는 복귀 주소는 모두 L2다. 가장 깊은 곳에서는 복귀 주소 여섯 개(L1 하나, L2 다섯 개)가 쌓여 있다. 맨 마지막 호출(ECX = 0)이 `ret`하면 L2로 가고, 그곳의 `ret`이 또 L2로 가는 식으로 `RET`만 다섯 번 연달아 실행되다가 마지막에 L1로 돌아간다. 합은 내려가면서 이미 EAX에 다 모였으므로, 돌아오는 길에는 할 일이 없다.

> [!TIP]
> 슬라이드의 원본 코드는 마지막 줄이 `end Main`처럼 소문자·대문자가 섞여 있다. MASM은 기본 설정에서 식별자의 대소문자를 구분하지 않으므로 어셈블은 되지만, `OPTION CASEMAP:NONE`을 쓰면 오류가 나므로 `END main`으로 맞춰 쓰는 것이 좋다.

### 팩토리얼 계산하기 (Calculating a Factorial)

재귀 서브루틴은 임시 데이터를 스택 매개변수에 두는 경우가 많다. 재귀 호출이 풀릴 때 스택에 저장해 둔 그 데이터가 쓸모 있다(Recursive subroutines often store temporary data in stack parameters. When the recursive calls unwind, the data saved on the stack can be useful). `CalcSum`과 달리 팩토리얼은 **돌아오는 길에** 계산을 한다.

```c
int factorial(int n)
{
    if (n == 0)
        return 1;
    else
        return n * factorial(n - 1);
}
```

> [!NOTE]
> **슬라이드 정정**: 슬라이드 25번의 C 코드는 `int function factorial(int n)`으로 시작한다. C에는 `function` 키워드가 없으므로 `int factorial(int n)`이 맞다.

n!을 구하려면 (n−1)!이 먼저 있어야 하므로, 0!에 닿을 때까지 호출이 계속 내려간다(Recursive calls). 0! = 1(기저 사례, base case)에 닿으면 그때부터 곱하면서 올라온다(Backing up).

```text
 Recursive calls           Backing up
 5! = 5 * 4!               5 * 24 = 120
   4! = 4 * 3!             4 * 6  = 24
     3! = 3 * 2!           3 * 2  = 6
       2! = 2 * 1!         2 * 1  = 2
         1! = 1 * 0!       1 * 1  = 1
           0! = 1          1 = 1           (base case)
```

다음 프로그램은 n을 스택으로 넘기고, 결과를 EAX로 받는다. n은 0~12 사이의 부호 없는 정수다(We pass n (an unsigned integer between 0 and 12) on the stack).

```asm
; Calculating a Factorial      (Fact.asm)
INCLUDE Irvine32.inc

.code
main PROC
    push 5                  ; calc 5!
    call Factorial          ; calculate factorial (EAX): EAX = 120
    call WriteDec           ; display it
    call Crlf
    exit
main ENDP

;---------------------------------------------------
Factorial PROC
; Calculates a factorial.
; Receives: [ebp+8] = n, the number to calculate
; Returns:  eax = the factorial of n
;---------------------------------------------------
    push ebp
    mov  ebp,esp
    mov  eax,[ebp+8]        ; get n: EAX = 5 → 4 → 3 → 2 → 1 → 0 차례로
    cmp  eax,0              ; n > 0?
    ja   L1                 ; yes: continue
    mov  eax,1              ; no: return 1 as the value of 0!
    jmp  L2                 ; and return to the caller
L1: dec  eax
    push eax                ; Factorial(n-1)
    call Factorial

; Instructions from this point on execute when each
; recursive call returns.
ReturnFact:
    mov  ebx,[ebp+8]        ; get n: EBX = 1 → 2 → 3 → 4 → 5 차례로
    mul  ebx                ; EDX:EAX = EAX * EBX: EAX = 1 → 2 → 6 → 24 → 120 차례로
L2: pop  ebp                ; return EAX
    ret  4                  ; clean up stack
Factorial ENDP
END main
```

실행 결과:

```text
120
```

`mov eax,[ebp+8]`은 내려가는 동안 5, 4, 3, 2, 1, 0을 차례로 읽고, `ReturnFact` 아래의 두 줄은 올라오는 동안 n = 1, 2, 3, 4, 5의 순서로 실행된다. 각 호출의 n이 **자기 프레임의 `[ebp+8]`에 그대로 남아 있기 때문에** 돌아온 뒤에 다시 꺼내 곱할 수 있다. 이것이 슬라이드가 말한 "스택에 저장해 둔 데이터"다.

#### N = 3으로 따라가기 (보충 그림)

`Factorial(3)`을 부르면 다음과 같이 진행된다(슬라이드 27~28번 그림). 프레임 하나는 n, 복귀 주소(Ret Addr), 저장된 EBP의 12바이트다.

**1. 내려가기**: 호출할 때마다 프레임이 하나씩 쌓인다. EBP는 항상 가장 아래 프레임의 저장된 EBP를 가리키고, 그 프레임의 n은 `[EBP+8]`이다.

```text
 Factorial(3)        Factorial(2)        Factorial(1)        Factorial(0)
 +------------+      +------------+      +------------+      +------------+
 | N = 3      |      | N = 3      |      | N = 3      |      | N = 3      |
 | (Ret Addr) |      | (Ret Addr) |      | (Ret Addr) |      | (Ret Addr) |
 | (EBP)  <-  |      | (EBP)      |      | (EBP)      |      | (EBP)      |
 +------------+      | N = 2      |      | N = 2      |      | N = 2      |
                     | (Ret Addr) |      | (Ret Addr) |      | (Ret Addr) |
                     | (EBP)  <-  |      | (EBP)      |      | (EBP)      |
                     +------------+      | N = 1      |      | N = 1      |
                                         | (Ret Addr) |      | (Ret Addr) |
                                         | (EBP)  <-  |      | (EBP)      |
                                         +------------+      | N = 0      |
                                                             | (Ret Addr) |
                                                             | (EBP)  <-  |
                                                             +------------+
                                              (<- : EBP와 ESP가 가리키는 곳)
```

**2. 올라오기**: N = 0인 호출은 EAX = 1을 들고 돌아간다. 돌아갈 때마다 `ret 4`가 그 프레임의 n까지 치우므로 프레임이 하나씩 사라진다.

| 돌아간 곳 | 그 프레임의 `[EBP+8]` | `mul ebx` 전의 EAX | `mul ebx` 뒤의 EAX |
|---|---|---|---|
| `Factorial(1)`의 `ReturnFact` | 1 | 1 (= 0!) | 1 (= 1!) |
| `Factorial(2)`의 `ReturnFact` | 2 | 1 | 2 (= 2!) |
| `Factorial(3)`의 `ReturnFact` | 3 | 2 | 6 (= 3!) |
| `main` | — | 6 | 6 |

#### 스택은 얼마나 쓰일까 (보충)

`Factorial(5)`는 n = 5, 4, 3, 2, 1, 0의 여섯 번 호출되므로, 가장 깊은 곳에서는 프레임 여섯 개(12바이트 × 6 = 72바이트)가 쌓여 있다. 호출 전의 ESP를 EBX에 기억해 두고 기저 사례에서 비교하면 확인할 수 있다.

```asm
; 가장 깊은 곳에서 스택을 얼마나 쓰는지 재 보기
INCLUDE Irvine32.inc

.code
main PROC
    mov  esi,esp            ; 호출 전의 ESP
    push 5
    call Factorial          ; EAX = 120, ESP = ESI
    exit
main ENDP

Factorial PROC
    push ebp
    mov  ebp,esp
    mov  eax,[ebp+8]
    cmp  eax,0
    ja   L1
    mov  eax,1              ; 기저 사례 (n = 0): ESP = ESI-72
    jmp  L2
L1: dec  eax
    push eax
    call Factorial
    mov  ebx,[ebp+8]
    mul  ebx
L2: pop  ebp
    ret  4
Factorial ENDP
END main
```

재귀의 깊이가 n이면 스택도 n에 비례해서 쓰인다. 기본 스택 1MB를 프레임 12바이트로 나누면 깊이 8만 단계 남짓이 한계다(실제로는 다른 용도로도 스택을 쓰므로 그보다 적다). 32비트 정수로는 12!까지만 표현할 수 있어 이 프로그램이 스택을 다 쓸 일은 없지만, 깊이가 입력에 따라 커지는 재귀(예: 연결 리스트를 재귀로 순회하기)는 입력이 크면 스택 오버플로가 날 수 있다.

#### 13! 이상은 넘친다 (보충)

12! = 479,001,600은 32비트에 들어가지만, 13! = 6,227,020,800은 2³² = 4,294,967,296보다 크다. `Factorial`은 `MUL`이 만든 64비트 곱 EDX:EAX 중 EAX만 돌려주므로, 13!을 구하면 상위 32비트(EDX)를 잃은 엉뚱한 값이 나온다. 7장에서 본 것처럼 `MUL` 뒤에 CF = 1이면 곱이 EAX에 다 들어가지 않은 것이다.

```asm
push 13
call Factorial              ; EAX = 1932053504 (6,227,020,800 - 2^32), EDX = 1, CF = 1
```

넘침을 알리려면 `mul ebx` 바로 다음에 `jc`로 검사하면 된다([부록 F 연습 2](#연습-2-반복과-재귀-팩토리얼-넘침-검사)).

### 재귀와 반복 (보충)

`CalcSum`처럼 돌아오는 길에 할 일이 없는 재귀(재귀 호출이 마지막 동작인 **꼬리 재귀** tail recursion)는 쉽게 반복문으로 바꿀 수 있다. 반복문은 스택을 더 쓰지 않으므로 깊이 제한이 없고, `CALL`/`RET`이 없어 빠르다.

```asm
; CalcSum을 반복문으로 바꾼 것
INCLUDE Irvine32.inc

.code
main PROC
    mov  ecx,5
    mov  eax,0
    call CalcSumLoop        ; EAX = 15
    exit
main ENDP

CalcSumLoop PROC
    jecxz L2                ; ECX = 0이면 바로 끝낸다
L1: add  eax,ecx
    loop L1                 ; ECX를 줄이며 반복한다
L2: ret
CalcSumLoop ENDP
END main
```

최적화하는 C 컴파일러는 팩토리얼 같은 재귀 함수도 반복문으로 바꿔 버리곤 한다([부록 B](#부록-b-c-컴파일러가-만든-스택-프레임)). 그래도 재귀가 쓸모 있는 이유는 트리 순회, 퀵 정렬, 하노이의 탑처럼 **문제 자체가 재귀적인 구조**일 때 코드가 훨씬 짧고 분명해지기 때문이다([부록 F](#부록-f-프로그래밍-연습-풀이-포함)에 예가 있다).

간접 재귀의 예로, 서로를 부르는 두 프로시저로 짝수·홀수를 판정해 보자. `IsEven(n)`은 n = 0이면 참, 아니면 `IsOdd(n−1)`의 결과를, `IsOdd(n)`은 n = 0이면 거짓, 아니면 `IsEven(n−1)`의 결과를 돌려준다.

```asm
; 간접 재귀: IsEven과 IsOdd가 서로를 부른다
INCLUDE Irvine32.inc

.code
main PROC
    mov  ecx,7
    call IsEven             ; 7은 짝수가 아니다: EAX = 0
    mov  ecx,10
    call IsEven             ; 10은 짝수다: EAX = 1
    exit
main ENDP

IsEven PROC                 ; ECX(n)을 받아 짝수이면 1, 아니면 0을 EAX로 돌려준다
    mov  eax,1
    jecxz Done              ; n = 0이면 짝수
    dec  ecx
    call IsOdd              ; IsEven(n) = IsOdd(n-1)
Done:
    ret
IsEven ENDP

IsOdd PROC                  ; ECX(n)을 받아 홀수이면 1, 아니면 0을 EAX로 돌려준다
    mov  eax,0
    jecxz Done              ; n = 0이면 홀수가 아니다
    dec  ecx
    call IsEven             ; IsOdd(n) = IsEven(n-1)
Done:
    ret
IsOdd ENDP
END main
```

두 프로시저에 같은 이름의 레이블 `Done`이 있어도 괜찮다. `PROC` 안의 코드 레이블은 그 프로시저 안에서만 보이기 때문이다.

---

## 8.4 INVOKE, ADDR, PROC, PROTO

8.2절에서는 인수를 넣고, 프레임을 만들고, `ret n`으로 치우는 일을 모두 손으로 했다. MASM의 고급 지시어를 쓰면 이 일을 어셈블러가 대신 해 준다. 다만 `INVOKE`와 그 인수에 쓰는 `ADDR`은 **32비트 MASM에서만** 쓸 수 있다. 64비트 MASM(ml64)에는 `INVOKE`가 없어서 인수를 직접 레지스터와 스택에 넣어야 한다.

| 지시어·연산자 | 하는 일 |
|---|---|
| `INVOKE` | 인수를 규약에 맞는 순서로 `PUSH`하고 `CALL`한다. C 규약이면 `add esp,n`도 붙인다 |
| `ADDR` | `INVOKE`의 인수로 변수의 **주소**를 넘긴다 |
| `PROC` (매개변수 목록) | 매개변수에 이름을 붙이고 프롤로그·에필로그와 `ret n`을 만든다 |
| `PROTO` | 프로시저의 원형(prototype)을 선언한다. `INVOKE`가 인수를 검사하는 데 쓴다 |

### INVOKE 지시어 (INVOKE Directive)

`INVOKE`는 인수를 스택에 넣고(`.MODEL` 지시어의 언어 지정자가 정한 순서로) 프로시저를 부른다. 여러 인수를 한 줄로 넘길 수 있어 `CALL`을 편하게 대신한다(INVOKE is a convenient replacement for the CALL instruction because it lets you pass multiple arguments using a single line of code). Irvine32.inc가 포함하는 SmallWin.inc에 `.MODEL flat, stdcall`이 있으므로 기본 규약은 STDCALL이다.

```text
INVOKE procedureName [, argumentList]
```

다음 두 코드는 같은 기계어가 된다.

```text
push  TYPE array
push  LENGTHOF array
push  OFFSET array
call  DumpArray

INVOKE DumpArray, OFFSET array, LENGTHOF array, TYPE array
```

`INVOKE`에는 인수를 **적힌 순서대로**(왼쪽부터) 쓰고, 어셈블러가 STDCALL 규약에 맞게 오른쪽부터 넣는다. 인수 개수에는 사실상 제한이 없고, 인수 하나하나를 다른 줄에 써도 된다(줄 끝의 쉼표가 다음 줄로 이어진다는 표시다).

```asm
; INVOKE로 인수 세 개를 넘기기
INCLUDE Irvine32.inc

DumpArray PROTO, pArray:PTR DWORD, count:DWORD, elemSize:DWORD

.data
array DWORD 10, 20, 30, 40

.code
main PROC
    mov  ebx,esp
    ; CALL로 직접 부르기: 인수를 오른쪽부터 넣는다
    push TYPE array
    push LENGTHOF array
    push OFFSET array
    call DumpArray          ; ESP = EBX
    ; INVOKE로 같은 호출을 한 줄에
    INVOKE DumpArray, OFFSET array, LENGTHOF array, TYPE array
    ; 인수를 여러 줄에 나눠 써도 된다
    INVOKE DumpArray,               ; displays an array
        OFFSET array,               ; points to the array
        LENGTHOF array,             ; the array length
        TYPE array                  ; array component size
    exit
main ENDP

DumpArray PROC USES eax ecx esi,
    pArray:PTR DWORD, count:DWORD, elemSize:DWORD
    mov  esi,pArray
    mov  ecx,count          ; ECX = 4
L1: mov  eax,[esi]
    call WriteDec
    mov  al,' '
    call WriteChar
    add  esi,elemSize
    loop L1
    call Crlf
    ret
DumpArray ENDP
END main
```

실행 결과:

```text
10 20 30 40
10 20 30 40
10 20 30 40
```

`DumpArray`가 `main`보다 뒤에 정의되어 있으므로 맨 위에 `PROTO`가 필요하다([PROTO 지시어](#proto-지시어-proto-directive) 참고).

#### 인수의 종류 (Argument Types)

`INVOKE`의 인수로는 다음과 같은 것을 쓸 수 있다(교재 Table 8-2). 오른쪽 열은 어셈블러가 그 인수를 넣으려고 만드는 코드다(DWORD 매개변수에 넘길 때, JWasm 2.21의 목록 파일에서 확인).

| 종류 (Type) | 예 (Examples) | 만들어지는 코드 |
|---|---|---|
| 즉시값 (Immediate value) | `10`, `3000h`, `OFFSET mylist`, `TYPE array` | `push 10` |
| 정수식 (Integer expression) | `(10 * 20)`, `COUNT` | `push 200` (어셈블할 때 계산) |
| 변수 (Variable) | `myList`, `array`, `myWord`, `myDword` | `push myDword` / 작은 변수는 `movzx eax,myWord` + `push eax` |
| 주소식 (Address expression) | `[myList+2]`, `[ebx + esi]` | `push [ebx+esi]` |
| 레지스터 (Register) | `eax`, `bl`, `edi` | `push eax` |
| `ADDR name` | `ADDR myList` | `push OFFSET myList` (전역) / `lea eax,name` + `push eax` (지역) |
| `OFFSET name` | `OFFSET myList` | `push OFFSET myList` |

> [!WARNING]
> **INVOKE가 EAX를 덮어쓸 수 있다.** 32비트보다 작은 인수를 넘기거나 지역 변수의 주소를 `ADDR`로 넘기면, 어셈블러는 값을 32비트로 만들거나 주소를 계산하려고 **EAX를 몰래 쓴다**(교재는 EDX도 바뀔 수 있다고 경고한다). 그래서 EAX에 넣어 둔 값을 인수로 쓰려던 계획이 어긋날 수 있다. 인수는 되도록 32비트로 넘기고, EAX를 지켜야 하면 `INVOKE` 전후에 저장·복원한다.

```asm
; INVOKE가 EAX를 바꾸는 예
INCLUDE Irvine32.inc

ShowByte PROTO, b:BYTE

.data
bv BYTE 7

.code
main PROC
    mov  eax,12345678h
    INVOKE ShowByte, bv     ; bv를 넣으려고 AL을 쓴다: EAX = ??????07h
    exit
main ENDP

ShowByte PROC, b:BYTE       ; EAX를 건드리지 않고 돌아간다
    ret
ShowByte ENDP
END main
```

`ShowByte`는 EAX를 쓰지 않았는데도 돌아온 뒤 EAX의 하위 바이트가 `bv`의 값 7로 바뀌어 있다. JWasm은 이 인수를 `mov al,bv` / `push eax`로 넣었다. 어떤 코드를 만들든 EAX가 바뀐다는 점은 같으므로 위 주석에서는 상위 비트를 `?`로 두었다.

### ADDR 연산자 (ADDR Operator)

`ADDR`은 `INVOKE`로 프로시저를 부를 때 포인터 인수를 넘기는 데 쓴다(The ADDR operator can be used to pass a pointer argument when calling a procedure using INVOKE). 예를 들어 다음 문장은 `myArray`의 주소를 `FillArray`에 넘긴다.

```text
INVOKE FillArray, ADDR myArray
```

`ADDR`은 `INVOKE` 안에서만 쓸 수 있다(The ADDR operator can only be used in conjunction with INVOKE). 일반 명령어에서 주소가 필요하면 `OFFSET`(전역 변수)이나 `LEA`(스택 변수)를 쓴다.

```asm
.data
myArray DWORD 10 DUP(0)
.code
mov  esi,ADDR myArray           ; 어셈블 오류
mov  esi,OFFSET myArray         ; 이렇게 쓴다
```

`ADDR`이 전역 변수에 쓰이면 `push OFFSET 변수`가 되고, `LOCAL` 변수나 스택 매개변수에 쓰이면 실행 중에 주소를 계산해야 하므로 `lea eax,변수` / `push eax`가 된다. 다음 예에서 `Swap`에 넘기는 두 인수는 각각 `OFFSET Array`, `OFFSET Array+4`로 바뀐다.

```asm
.data
Array DWORD 20 DUP(?)
.code
INVOKE Swap,
    ADDR Array,
    ADDR [Array+4]
```

```text
push  OFFSET Array+4
push  OFFSET Array
call  Swap
```

> [!NOTE]
> **슬라이드 보충·정정**: 슬라이드 32번은 "ADDR에 넘기는 인수는 어셈블할 때 정해지는 상수여야 한다(The argument passed to ADDR must be an assembly time constant)"라고 하고, 그 예로 `INVOKE mySub, ADDR [ebp+12] ; error`를 든다. 그러나 `ADDR`은 `LOCAL` 변수나 이름 붙은 매개변수처럼 **실행 중에 주소가 정해지는 변수에도 쓸 수 있다.** 이때 어셈블러가 `LEA`로 주소를 계산하는 코드를 만들 뿐이다(아래 `Read_File` 예와 [8.6절](#86-매개변수-고급-활용-advanced-use-of-parameters-보충) 참고). 교재에 따르면 MASM은 `[ebp+12]`처럼 **레지스터로 직접 쓴 주소식**을 `ADDR`의 피연산자로 받지 않는다. 이 동작은 어셈블러마다 달라서, JWasm은 같은 문장을 `lea eax,[ebp+12]` / `push eax`로 받아들였다. 스택 주소를 넘기고 싶으면 매개변수나 `LOCAL` 변수에 이름을 붙여 `ADDR 이름`으로 쓰는 것이 확실하다.

### PROC 지시어 (PROC Directive)

`PROC`는 프로시저를 정의하는 지시어다. 5장에서는 이름만 붙였지만, 실제로는 속성, 저장할 레지스터 목록, 매개변수 목록까지 지정할 수 있다.

```text
label PROC [attributes] [USES reglist], parameter_list

attributes:  [distance] [langtype] [visibility] [prologuearg]
```

| 속성 (Attribute) | 설명 (Description) |
|---|---|
| distance | `NEAR` 또는 `FAR`. 어셈블러가 만드는 복귀 명령어(`RET` 또는 `RETF`)의 종류를 정한다 |
| langtype | 호출 규약(`C`, `PASCAL`, `STDCALL` 등). `.MODEL` 지시어에서 정한 언어를 이 프로시저에 한해 바꾼다 |
| visibility | 다른 모듈에서 보이는지 여부. `PRIVATE`, `PUBLIC`(기본값), `EXPORT`가 있다. `EXPORT`는 링커가 프로시저 이름을 내보내기 테이블(export table)에 넣게 하며, `PUBLIC`도 함께 뜻한다 |
| prologuearg | 프롤로그·에필로그 코드를 만드는 방식에 영향을 주는 인수 |

#### 매개변수 목록 (Parameter Lists)

매개변수는 쉼표로 구분해 나열하고, 각각 `paramName:type` 꼴로 쓴다. 한 줄에 써도 되고, 줄을 나눠 써도 된다. MASM 문서의 문법에서 매개변수 목록은 쉼표로 시작하므로(`USES` 목록이나 속성과 구분하기 위해서다), 교재처럼 `AddTwo PROC,`의 형태로 첫 매개변수 앞에 쉼표를 붙여 쓰는 것이 안전하다.

```text
label PROC [attributes] [USES reglist],
    parameter_1,
    parameter_2,
    ...
    parameter_n

label PROC [attributes], parameter_1, parameter_2, ..., parameter_n
```

타입에는 `BYTE`, `SBYTE`, `WORD`, `SWORD`, `DWORD`, `SDWORD`, `QWORD` 같은 내장 타입과 `PTR BYTE`, `PTR DWORD` 같은 포인터 타입을 쓴다. 이름 붙은 매개변수를 쓰면 어셈블러가 다음을 대신 해 준다.

1. 프롤로그(`push ebp` / `mov ebp,esp`)와 에필로그를 만든다.
2. 매개변수 이름을 `[ebp+8]`, `[ebp+12]`, …로 바꾼다.
3. STDCALL이면 `ret`을 `ret n`(n = 매개변수 바이트 수)으로 바꾼다.

**예 1**: `AddTwo`는 더블워드 두 개를 받아 합을 EAX로 돌려준다(The AddTwo procedure receives two doubleword values and returns their sum in EAX).

```asm
; PROC의 매개변수 목록: 어셈블러가 프레임을 만들어 준다
INCLUDE Irvine32.inc

AddTwo PROTO, val1:DWORD, val2:DWORD

.code
main PROC
    mov  ebx,esp
    INVOKE AddTwo, 5, 6     ; EAX = 11, ESP = EBX
    exit
main ENDP

AddTwo PROC,
    val1:DWORD,
    val2:DWORD
    mov  eax,val1           ; val1은 [ebp+8]: EAX = 5
    add  eax,val2           ; val2는 [ebp+12]: EAX = 11
    ret                     ; 어셈블러가 에필로그와 ret 8로 바꾼다
AddTwo ENDP
END main
```

어셈블러가 실제로 만든 코드를 나란히 놓으면 다음과 같다. 왼쪽은 슬라이드에 실린 MASM의 결과, 오른쪽은 이 문서를 검증한 JWasm의 결과다.

```text
MASM (slide)                         JWasm 2.21
AddTwo PROC                          AddTwo PROC
    push ebp                             push ebp
    mov  ebp,esp                         mov  ebp,esp
    mov  eax,dword ptr [ebp+8]           mov  eax,[ebp+8]
    add  eax,dword ptr [ebp+0Ch]         add  eax,[ebp+0Ch]
    leave                                pop  ebp
    ret  8                               ret  8
AddTwo ENDP                          AddTwo ENDP
```

MASM은 `leave`로, JWasm은 `pop ebp`로 프레임을 정리한다. 이 프로시저에는 지역 변수가 없어 ESP와 EBP가 이미 같으므로 두 코드는 같은 일을 한다. 다만 프로시저 안에서 `PUSH`한 것을 `POP`하지 않고 `ret`하면, `leave`는 ESP를 EBP로 되돌려 주지만 `pop ebp`는 그러지 못한다. 어느 쪽이든 `PUSH`와 `POP`의 짝은 직접 맞춰야 한다.

**예 2, 3**: `FillArray`는 바이트 배열을 가리키는 포인터를, `Swap`은 더블워드를 가리키는 포인터 두 개를 받는다.

```text
FillArray PROC,
    pArray:PTR BYTE
    . . .
FillArray ENDP

Swap PROC,
    pValX:PTR DWORD,
    pValY:PTR DWORD
    . . .
Swap ENDP
```

**예 4**: `Read_File`은 바이트 포인터 `pBuffer`를 받고, 더블워드 지역 변수 `fileHandle`을 쓰며, EAX와 EBX를 스택에 저장한다(It has a local doubleword variable named fileHandle, and it saves two registers on the stack (EAX and EBX)). `USES`, 매개변수, `LOCAL`이 모두 들어간 경우다.

```asm
; USES, 매개변수, LOCAL을 함께 쓴 프로시저
INCLUDE Irvine32.inc

Read_File PROTO, pBuffer:PTR BYTE

.data
buffer BYTE 16 DUP(0)

.code
main PROC
    mov  eax,77h
    INVOKE Read_File, ADDR buffer
    exit
main ENDP

Read_File PROC USES eax ebx,
    pBuffer:PTR BYTE
    LOCAL fileHandle:DWORD
    mov  esi,pBuffer        ; pBuffer는 [ebp+8]: ESP = EBP-12
    mov  fileHandle,eax     ; fileHandle은 [ebp-4]: [ebp-4] = 77h
    ret
Read_File ENDP
END main
```

```text
MASM (slide)                         JWasm 2.21
Read_File PROC                       Read_File PROC
    push ebp                             push ebp
    mov  ebp,esp                         mov  ebp,esp
    add  esp,0FFFFFFFCh                  sub  esp,4          ; fileHandle
    push eax                             push eax            ; USES eax
    push ebx                             push ebx            ; USES ebx
    mov  esi,dword ptr [ebp+8]           mov  esi,[ebp+8]    ; pBuffer
    mov  dword ptr [ebp-4],eax           mov  [ebp-4],eax    ; fileHandle
    pop  ebx                             pop  ebx
    pop  eax                             pop  eax
    leave                                mov  esp,ebp
                                         pop  ebp
    ret  4                               ret  4
Read_File ENDP                       Read_File ENDP
```

`USES`로 지정한 레지스터는 지역 변수 자리를 만든 **다음에** 저장된다. 그래서 프레임은 위에서부터 매개변수, 복귀 주소, 저장된 EBP, 지역 변수, 저장된 레지스터의 순서가 되어 8.2절의 그림과 같아진다. `add esp,0FFFFFFFCh`는 ESP에 −4를 더하는 것이므로 `sub esp,4`와 같다.

#### PROC가 바꾸는 RET 명령어 (RET Instruction Modified by PROC)

STDCALL이 기본 규약일 때 매개변수가 n개 있는 `PROC`에서 `ret`을 쓰면, MASM은 다음과 같은 진입·종료 코드를 만든다(When PROC is used with one or more parameters and STDCALL is the default protocol, MASM generates the following entry and exit code).

```text
push ebp
mov  ebp,esp
  .
  .
leave
ret  (n*4)
```

규약에 따라 `ret`이 어떻게 바뀌는지 정리하면 다음과 같다.

| 프로시저 선언 | 소스의 `ret` | 어셈블러가 만드는 복귀 코드 | 인수를 치우는 쪽 |
|---|---|---|---|
| `AddTwo PROC, a:DWORD, b:DWORD` (STDCALL) | `ret` | 프레임 정리 + `ret 8` | 호출된 쪽 |
| `AddTwo PROC C, a:DWORD, b:DWORD` | `ret` | 프레임 정리 + `ret` | 호출한 쪽 (`INVOKE`가 `add esp,8`을 붙인다) |
| `MySub PROC USES ecx edx` (매개변수 없음) | `ret` | `pop edx` / `pop ecx` / `ret` | — |
| `MySub PROC` (아무것도 없음) | `ret` | `ret` | — |

### PROTO 지시어 (PROTO Directive)

`PROTO`는 프로시저의 **원형**(prototype)을 선언한다. 이름, 호출 규약, 매개변수의 개수와 타입을 미리 알려 주는 것으로, C의 함수 선언 `int AddTwo(int, int);`에 해당한다. 슬라이드에는 `Swap PROTO`가 예제 속에 한 번 나올 뿐이지만, `INVOKE`를 쓰려면 꼭 알아야 한다.

```text
label PROTO [attributes] [, parameter_list]

AddTwo PROTO,
    val1:DWORD,
    val2:DWORD
```

`PROTO`가 필요한 경우는 두 가지다.

- **`INVOKE`가 프로시저 정의보다 앞에 나올 때.** 어셈블러는 소스를 위에서부터 읽으므로, 아직 보지 못한 프로시저의 매개변수를 알 수 없다. 그래서 `main`이 맨 위에 있는 프로그램에서는 `PROTO`가 필요하다.
- **다른 모듈이나 라이브러리에 있는 프로시저를 `INVOKE`할 때.** `Irvine32.inc`에는 라이브러리 프로시저의 `PROTO`가 모두 들어 있다(`WriteStackFrame PROTO, numParam:DWORD, …` 등).

```asm
; PROTO 없이 뒤에 정의된 프로시저를 INVOKE하면 오류다
INCLUDE Irvine32.inc

.code
main PROC
    INVOKE Later, 1         ; 어셈블 오류
    exit
main ENDP

Later PROC, x:DWORD
    mov  eax,x
    ret
Later ENDP
END main
```

`PROTO`를 쓰면 어셈블러가 `INVOKE`의 인수 개수와 크기를 검사해 준다. 인수가 너무 많거나 적으면 어셈블할 때 바로 오류가 나므로, 손으로 `PUSH`할 때 생기는 실수(인수를 하나 빠뜨려 스택이 어긋나는 것)를 막을 수 있다.

```asm
; PROTO와 인수 개수가 다르면 어셈블되지 않는다
INCLUDE Irvine32.inc

AddTwo PROTO, val1:DWORD, val2:DWORD

.code
main PROC
    INVOKE AddTwo, 1, 2, 3  ; 어셈블 오류
    INVOKE AddTwo, 1        ; 어셈블 오류
    INVOKE AddTwo, 1, 2     ; EAX = 3
    exit
main ENDP

AddTwo PROC, val1:DWORD, val2:DWORD
    mov  eax,val1
    add  eax,val2
    ret
AddTwo ENDP
END main
```

`PROTO`를 만드는 가장 쉬운 방법은 `PROC` 줄을 복사해서 `PROC`를 `PROTO`로 바꾸고 `USES` 목록을 지우는 것이다. `USES`는 프로시저 내부의 일이라 호출하는 쪽과는 상관이 없기 때문이다.

#### C 규약과 가변 인수 (보충)

`PROTO`와 `PROC`에 `C`를 붙이면 C 규약이 된다. `INVOKE`는 `CALL` 다음에 `add esp,n`을 자동으로 붙이고, 프로시저의 `ret`은 그대로 `ret`이 된다. C 규약에서는 마지막 매개변수를 `VARARG`로 선언해 **개수가 정해지지 않은 인수**를 받을 수 있다. 다음 `SumAll`은 첫 인수로 개수를 받고, 그 뒤의 인수를 모두 더한다.

```asm
; C 규약 + VARARG: 가변 개수 인수의 합
INCLUDE Irvine32.inc

SumAll PROTO C, count:DWORD, args:VARARG

.code
main PROC
    mov  ebx,esp
    INVOKE SumAll, 3, 10, 20, 30            ; EAX = 60, ESP = EBX
    INVOKE SumAll, 5, 1, 2, 3, 4, 5         ; EAX = 15, ESP = EBX
    exit
main ENDP

SumAll PROC C USES ecx esi, count:DWORD, args:VARARG
    mov  eax,0
    mov  ecx,count
    lea  esi,args           ; 가변 인수는 count 바로 위([ebp+12])부터 있다
    jecxz Done
L1: add  eax,[esi]
    add  esi,4
    loop L1
Done:
    ret                     ; C 규약이므로 그냥 ret (치우는 것은 호출한 쪽)
SumAll ENDP
END main
```

두 `INVOKE`의 인수 개수가 달라도 ESP가 제대로 돌아온 것은, `INVOKE`가 각 호출 뒤에 `add esp,16`과 `add esp,24`를 따로 붙였기 때문이다. STDCALL로는 이런 프로시저를 만들 수 없다.

### 매개변수 분류 (Parameter Classifications)

매개변수는 호출한 쪽과 호출된 프로시저 사이에서 데이터가 **어느 방향으로** 흐르는지에 따라 세 가지로 나눈다(Procedure parameters are usually classified according to the direction of data transfer between the calling program and the called procedure).

| 분류 | 쓰는 경우 | 넘기는 방법 | C의 예 |
|---|---|---|---|
| **입력** (Input Parameter) | 프로시저가 데이터를 바꾸면 안 될 때 | 값 (또는 읽기만 하는 포인터) | `int Square(int n)` |
| **출력** (Output Parameter) | 프로시저가 호출한 쪽의 변수에 값을 넣어 줘야 할 때 | 포인터 | `void GetTime(int *pHour)` |
| **입력-출력** (Input-Output Parameter) | 프로시저가 기존 데이터를 고쳐야 할 때 | 포인터 | `void Increment(int *p)` |

입력 매개변수는 값으로 넘기면 호출한 쪽의 변수가 안전하다. 출력·입력-출력 매개변수는 주소로 넘겨야 호출된 쪽이 원래 변수에 접근할 수 있다.

```asm
; 입력, 출력, 입력-출력 매개변수
INCLUDE Irvine32.inc

Square PROTO, n:DWORD, pResult:PTR DWORD
Increment PROTO, pValue:PTR DWORD

.data
result  DWORD ?
counter DWORD 41

.code
main PROC
    INVOKE Square, 9, ADDR result       ; n은 입력, pResult는 출력: result = 81
    INVOKE Increment, ADDR counter      ; pValue는 입력-출력: counter = 42
    exit
main ENDP

Square PROC USES eax esi, n:DWORD, pResult:PTR DWORD
    mov  eax,n
    imul eax,eax            ; n의 제곱
    mov  esi,pResult
    mov  [esi],eax          ; 출력: 호출한 쪽의 변수에 쓴다
    ret
Square ENDP

Increment PROC USES esi, pValue:PTR DWORD
    mov  esi,pValue
    inc  DWORD PTR [esi]    ; 입력-출력: 읽어서 고친 다음 다시 쓴다
    ret
Increment ENDP
END main
```

### 예제: 두 정수 교환하기 (Example: Exchanging Two Integers)

`Swap`은 두 정수를 가리키는 포인터를 받아 두 값을 맞바꾼다. 두 매개변수 모두 입력-출력 매개변수다.

```asm
; Swap Procedure Example       (Swap.asm)
INCLUDE Irvine32.inc

Swap PROTO, pValX:PTR DWORD, pValY:PTR DWORD

.data
Array DWORD 10000h,20000h

.code
main PROC
    ; Display the array before the exchange:
    mov  esi,OFFSET Array
    mov  ecx,2              ; count = 2
    mov  ebx,TYPE Array
    call DumpMem            ; dump the array values
    INVOKE Swap, ADDR Array, ADDR [Array+4]
    ; Display the array after the exchange:
    call DumpMem
    exit
main ENDP

;------------------------------------------------------
Swap PROC USES eax esi edi,
    pValX:PTR DWORD,        ; pointer to first integer
    pValY:PTR DWORD         ; pointer to second integer
;
; Exchange the values of two 32-bit integers
; Returns: nothing
;------------------------------------------------------
    mov  esi,pValX          ; get pointers
    mov  edi,pValY
    mov  eax,[esi]          ; get first integer: EAX = 10000h
    xchg eax,[edi]          ; exchange with second: EAX = 20000h
    mov  [esi],eax          ; replace first integer
    ret                     ; PROC generates RET 8 here
Swap ENDP
END main
```

실행 결과(주소는 실행 환경마다 다르므로 …로 줄였다):

```text
Dump of offset …
-------------------------------
00010000  00020000

Dump of offset …
-------------------------------
00020000  00010000
```

`XCHG`는 레지스터와 메모리의 값을 한 번에 맞바꾸므로, 임시 변수 없이 레지스터 하나로 교환할 수 있다. `Swap`이 `USES eax esi edi`로 세 레지스터를 지켜 주므로 `main`의 ESI, ECX, EBX는 그대로이고, 두 번째 `DumpMem`도 같은 인수로 다시 부를 수 있다.

> [!NOTE]
> **슬라이드 정정**: 슬라이드 40번은 `INVOKE`를 "함수 호출용 매크로"라고 하고, `INVOKE`가 "호출 규칙(stdcall, cdecl 등)에 따라 스택 정리까지 자동 처리"한다고 설명한다. 두 가지를 바로잡는다.
> - `INVOKE`는 매크로가 아니라 어셈블러에 내장된 **지시어**다(결과가 여러 명령어로 바뀐다는 점은 매크로와 비슷하다).
> - `INVOKE`가 스택 정리 코드(`add esp,n`)를 붙이는 것은 **C 규약일 때뿐**이다. 이 예제처럼 STDCALL이면 `INVOKE`는 `PUSH`와 `CALL`만 만들고, 스택은 프로시저의 `ret 8`이 치운다. 그 `ret 8`을 만드는 것은 `INVOKE`가 아니라 `PROC` 지시어다(주석 "PROC generates RET 8 here").

### 디버깅 팁 (Debugging Tips)

`INVOKE`와 `PROTO`가 인수 개수와 크기를 검사해 주지만, **주소가 가리키는 대상**까지 검사하지는 못한다. 다음은 어셈블은 잘 되지만 틀리게 동작하는 대표적인 경우다.

#### 인수 크기 착오 (Argument Size Mismatch)

배열의 주소식에서 오프셋은 **바이트 단위**다. 더블워드 배열의 두 번째 원소는 `[DoubleArray + 4]`인데, 원소 번호처럼 `+ 1`을 쓰면 엉뚱한 곳을 가리킨다.

```asm
.data
DoubleArray DWORD 10000h,20000h
.code
INVOKE Swap, ADDR [DoubleArray + 0], ADDR [DoubleArray + 1]
mov  eax,DoubleArray            ; EAX = 00000100h
mov  ebx,DoubleArray+4          ; EBX = 00020000h
```

`[DoubleArray + 1]`은 첫 원소의 두 번째 바이트부터 시작하는 4바이트를 가리키므로, 두 원소가 맞바뀌는 대신 겹친 바이트들이 뒤섞였다. `ADDR [DoubleArray + 4]` 또는 `ADDR [DoubleArray + TYPE DoubleArray]`로 써야 한다.

#### 잘못된 타입의 포인터 (Passing the Wrong Type of Pointer)

`Swap`은 더블워드 포인터 두 개를 기대한다. 실수로 바이트를 가리키는 포인터를 넘겨도 어셈블러는 막지 않는다(`PTR DWORD` 매개변수에 바이트 변수의 주소를 넘겨도 오류가 나지 않는다).

```asm
.data
ByteArray BYTE 10h,20h,30h,40h,50h,60h,70h,80h
.code
INVOKE Swap, ADDR [ByteArray + 0], ADDR [ByteArray + 1]
mov  eax,DWORD PTR ByteArray            ; EAX = 50403020h
mov  ebx,DWORD PTR ByteArray+4          ; EBX = 80706040h
```

바이트 두 개를 맞바꾸려던 의도와 달리, `Swap`은 4바이트씩 읽고 써서 배열의 앞 다섯 바이트가 `20 30 40 50 40`으로 바뀌었다. 바이트를 교환하려면 바이트용 프로시저를 따로 만들어야 한다.

#### 즉시값을 포인터로 넘기기 (Passing Immediate Values)

포인터를 받는 프로시저에 실수로 즉시값을 넘기면, 프로시저는 그 값을 주소로 믿고 따라간다.

```asm
; 포인터 대신 즉시값을 넘긴 실수
INCLUDE Irvine32.inc

Sub2 PROTO, dataPtr:PTR WORD

.code
main PROC
    INVOKE Sub2, 1000h
    exit                    ; 실행되지 않는다
main ENDP

Sub2 PROC, dataPtr:PTR WORD
    mov  esi,dataPtr        ; get the address: ESI = 1000h
    mov  WORD PTR [esi],0   ; dereference, assign zero: 접근 위반
    ret
Sub2 ENDP
END main
```

`Sub2`는 1000h를 포인터 값으로 받아 메모리 1000h번지에 0을 쓰려 한다(The Sub2 procedure receives 1000h as a pointer value and dereferences memory location 1000h). 그 주소는 프로그램에 할당된 메모리가 아니므로 **실행 중 오류**(runtime error)인 접근 위반이 난다. 어셈블러는 `1000h`가 주소로 쓰기에 올바른지 알 수 없으므로 오류를 내지 않는다.

### WriteStackFrame 프로시저 (WriteStackFrame Procedure)

Irvine32 라이브러리의 `WriteStackFrame`은 현재 프로시저의 스택 프레임을 화면에 보여 준다. 스택 매개변수, 복귀 주소, 지역 변수, 저장된 레지스터가 각각 무엇인지 표시해 준다(It shows the procedure's stack parameters, return address, local variables, and saved registers). 프레임 구조를 공부하거나 디버깅할 때 유용하다.

```text
WriteStackFrame PROTO,
    numParam:DWORD,         ; 매개변수 개수
    numLocalVal:DWORD,      ; 더블워드 지역 변수 개수
    numSavedReg:DWORD       ; 저장된 레지스터 개수
```

```asm
; WriteStackFrame으로 스택 프레임 보기
INCLUDE Irvine32.inc

myProc PROTO, x:DWORD, y:DWORD

.code
main PROC
    mov  eax,0EAEAEAEAh
    mov  ebx,0EBEBEBEBh
    INVOKE myProc, 1111h, 2222h     ; pass two integer arguments
    exit
main ENDP

myProc PROC USES eax ebx,
    x:DWORD, y:DWORD
    LOCAL a:DWORD, b:DWORD
    PARAMS = 2
    LOCALS = 2
    SAVED_REGS = 2
    mov  a,0AAAAh
    mov  b,0BBBBh
    INVOKE WriteStackFrame, PARAMS, LOCALS, SAVED_REGS
    ret
myProc ENDP
END main
```

실행 결과:

```text
Stack Frame

00002222  ebp+12 (parameter)
00001111  ebp+8 (parameter)
…  ebp+4 (return address)
…  ebp+0 (saved ebp) <--- ebp
0000AAAA  ebp-4 (local variable)
0000BBBB  ebp-8 (local variable)
EAEAEAEA  ebp-12 (saved register)
EBEBEBEB  ebp-16 (saved register) <--- esp
```

복귀 주소와 저장된 EBP는 실행 환경마다 달라서 …로 줄였다(슬라이드에서는 각각 `00401083`, `0012FFF0`이다). 출력을 위에서부터 읽으면 8.2절의 그림을 그대로 위아래로 펼친 모양이다. 저장된 레지스터 자리에 `main`에서 넣은 `EAEAEAEA`(EAX)와 `EBEBEBEB`(EBX)가 보이고, `<--- esp`가 가장 마지막에 저장된 EBX를 가리킨다.

- `WriteStackFrame`은 STDCALL 프로시저이고 `Irvine32.inc`에 `PROTO`가 있으므로 `INVOKE`로 부른다.
- 이름도 함께 출력하고 싶으면 `WriteStackFrameName`에 프로시저 이름 문자열의 주소를 네 번째 인수로 더 넘긴다(`INVOKE WriteStackFrameName, 2, 2, 2, ADDR procName`). 그러면 첫 줄이 `Stack Frame for myProc`이 된다.
- 슬라이드의 코드에는 `myProc PROTO`가 없다. `main`이 `myProc`보다 앞에 있으므로 `INVOKE myProc, …`를 하려면 위처럼 `PROTO`를 추가해야 한다.
- 슬라이드의 출력은 값과 `ebp` 사이가 한 칸이지만, 라이브러리 소스(`Irvine32.asm`)는 두 칸(`"  ebp"`)을 출력한다.

---

## 8.5 다중 모듈 프로그램 (Creating Multimodule Programs)

큰 프로그램을 소스 파일 하나에 담으면 다루기도 어렵고 어셈블하는 시간도 길어진다. 그래서 프로그램을 여러 **모듈**(module, 따로 어셈블하는 소스 파일)로 나눈다. 각 모듈은 독립적으로 어셈블되므로, 한 모듈의 소스를 고치면 그 모듈만 다시 어셈블하면 된다. 링커는 어셈블된 모듈(OBJ 파일)들을 하나의 실행 파일로 빠르게 합친다. 많은 오브젝트 모듈을 링크하는 시간은 같은 수의 소스 파일을 어셈블하는 시간보다 훨씬 짧다(Linking large numbers of object modules requires far less time than assembling the same number of source code files).

```text
 main.asm  --(assemble)-->  main.obj  --+
 sub1.asm  --(assemble)-->  sub1.obj  --+--(link)-->  program.exe
 sub2.asm  --(assemble)-->  sub2.obj  --+      Irvine32.lib, kernel32.lib 등도 함께
```

모듈 사이에서 프로시저와 변수를 주고받는 방법은 두 가지다(슬라이드 46번).

| 방식 | 다른 모듈의 프로시저를 알리는 방법 | 부르는 방법 | 특징 |
|---|---|---|---|
| 전통적인 방식 (Traditional) | `EXTERN name@n:PROC` | `PUSH` + `CALL` | 어셈블러에 덜 의존하므로 이식성이 좋다 |
| Microsoft 고급 방식 (Microsoft Advanced) | `PROTO` | `INVOKE` | 인수 검사와 이름 장식을 어셈블러가 해 주어 간단하다 |

### 프로시저 이름 숨기기와 내보내기 (Hiding and Exporting Procedure Names)

MASM은 기본적으로 모든 프로시저를 **공개**(public)한다. 같은 프로그램의 다른 어느 모듈에서도 부를 수 있다는 뜻이다. `PRIVATE` 한정자를 붙이면 이 동작을 바꿀 수 있다(By default, MASM makes all procedures public. You can override this behavior using the PRIVATE qualifier).

```text
mySub PROC PRIVATE
```

프로시저를 비공개로 만들면 캡슐화(encapsulation) 원칙에 따라 프로시저를 모듈 안에 숨길 수 있고, 다른 모듈에 같은 이름의 프로시저가 있어도 이름이 충돌하지 않는다.

#### OPTION PROC:PRIVATE 지시어

파일 맨 위에 `OPTION PROC:PRIVATE`를 쓰면 그 모듈의 모든 프로시저가 기본적으로 비공개가 된다. 그런 다음 내보낼 프로시저만 `PUBLIC` 지시어로 지정한다. `PUBLIC`에는 쉼표로 구분한 이름 목록을 쓸 수 있고, 프로시저마다 `PROC PUBLIC`으로 지정해도 된다.

```asm
; privdemo.asm: 기본 공개 범위를 바꾼 모듈
INCLUDE Irvine32.inc
OPTION PROC:PRIVATE
PUBLIC sub2

.code
sub1 PROC                   ; 비공개 (기본값을 PRIVATE로 바꿨다)
    ret
sub1 ENDP

sub2 PROC                   ; PUBLIC 지시어로 공개
    ret
sub2 ENDP

sub3 PROC PUBLIC            ; 프로시저 하나만 공개
    ret
sub3 ENDP
END
```

이 모듈을 어셈블한 오브젝트 파일에는 `sub2`와 `sub3`의 이름(`_sub2@0`, `_sub3@0`)만 공개 기호로 남고, `sub1`은 다른 모듈에서 찾을 수 없다. 다른 모듈이 `sub1`을 부르면 링크할 때 "확인할 수 없는 외부 기호(unresolved external symbol)" 오류가 난다.

`OPTION PROC:PRIVATE`를 프로그램의 시작 모듈에 쓴다면, 시작 프로시저(보통 `main`)를 반드시 `PUBLIC`으로 지정해야 한다.

```text
main PROC PUBLIC
```

> [!NOTE]
> **슬라이드 정정**: 슬라이드 48번은 `main`을 공개하지 않으면 "운영체제의 로더(the operating system's loader)가 찾지 못한다"고 설명한다. 그러나 진입점(entry point) 이름을 찾아 주소로 바꾸는 것은 **링커**다. 링커는 그 주소를 실행 파일의 헤더에 기록하고, 로더는 기록된 주소를 읽어 실행을 시작할 뿐 이름을 찾지 않는다. 따라서 `main`이 감춰지면 문제는 링크 단계에서 생긴다. 참고로 JWasm은 `END main`에 지정한 진입점을 `OPTION PROC:PRIVATE`가 있어도 공개 기호로 내보냈다. 어셈블러에 따라 다르므로 `PUBLIC`을 명시하는 것이 안전하다.

### 외부 프로시저 호출하기 (Calling External Procedures)

현재 모듈 밖의 프로시저를 부를 때는 `EXTERN` 지시어로 프로시저의 이름을 알린다. STDCALL 규약을 쓰는 32비트 프로그램에서는 이름 끝에 `@n`이 붙는데, n은 **선언된 매개변수가 차지하는 스택 바이트 수**다(The @n suffix at the end of a procedure name identifies the total stack space used by declared parameters).

```text
INCLUDE Irvine32.inc
EXTERN sub1@0:PROC
.code
main PROC
    call sub1@0
    exit
main ENDP
END main
```

확장된 `PROC` 지시어로 매개변수를 선언한 프로시저는 매개변수 하나마다 4바이트를 더한다(If you declare a procedure using the extended PROC directive, add 4 bytes for every parameter). 다음 `AddTwo`는 매개변수가 두 개이므로 이름이 `AddTwo@8`이 된다.

```text
AddTwo PROC,                    AddTwo PROTO,
    val1:DWORD,                     val1:DWORD,
    val2:DWORD                      val2:DWORD
    . . .
AddTwo ENDP                     ; 또는 다른 모듈에서: EXTERN AddTwo@8:PROC
```

> [!NOTE]
> **슬라이드 정정**: 슬라이드 49번 첫 문단은 `EXTERN`이 프로시저의 "이름과 스택 프레임 크기(stack frame size)"를 알린다고 설명한다. 그러나 `@n`의 n은 프레임 전체(복귀 주소, 저장된 EBP, 지역 변수, 저장된 레지스터)의 크기가 아니라 **매개변수의 바이트 수**뿐이다. 같은 슬라이드의 두 번째 문단("the total stack space used by declared parameters")이 정확한 설명이다. 그래서 `n`은 STDCALL 프로시저가 `ret n`으로 치우는 바이트 수와 같다.

두 모듈로 나눠 직접 확인해 보자. 첫 모듈은 프로시저만 정의하고, 두 번째 모듈이 `EXTERN`으로 그것을 부른다.

```asm
; subs.asm: 다른 모듈에서 부를 프로시저들
INCLUDE Irvine32.inc

.code
sub1 PROC                   ; 매개변수 없음: 외부 이름은 sub1@0
    mov  eax,1
    ret
sub1 ENDP

AddTwo PROC,                ; 매개변수 8바이트: 외부 이름은 AddTwo@8
    val1:DWORD,
    val2:DWORD
    mov  eax,val1
    add  eax,val2
    ret
AddTwo ENDP
END
```

```asm
; extmain.asm: EXTERN으로 다른 모듈의 프로시저를 부른다
INCLUDE Irvine32.inc
EXTERN sub1@0:PROC
EXTERN AddTwo@8:PROC

.code
main PROC
    call sub1@0             ; EAX = 1
    push 6
    push 5
    call AddTwo@8           ; EAX = 11 (인수는 AddTwo의 ret 8이 치운다)
    exit
main ENDP
END main
```

Microsoft 컴파일러와 같은 이름 장식 규칙에 따라, STDCALL 이름은 오브젝트 파일에서 앞에 밑줄이 붙은 `_sub1@0`, `_AddTwo@8`이 된다(C 규약이면 `_AddTwo`). `@n`을 잘못 계산하면 링커가 이름을 찾지 못해 링크 오류가 난다. `EXTERN` 대신 `AddTwo PROTO, val1:DWORD, val2:DWORD`를 쓰면 어셈블러가 이름을 장식해 주므로 그냥 `INVOKE AddTwo, 5, 6`이라고 쓸 수 있다. 이것이 Microsoft 고급 방식이다.

### 모듈 경계를 넘는 변수와 기호 (Using Variables and Symbols across Module Boundaries)

#### 변수와 기호 내보내기 (Exporting Variables and Symbols)

프로시저와 달리 변수와 기호는 기본적으로 자신이 속한 모듈 안에서만 보인다(Variables and symbols are, by default, private to their enclosing modules). 특정 이름을 내보내려면 `PUBLIC`을 쓴다.

```text
PUBLIC count, SYM1
SYM1 = 10
.data
count DWORD 0
```

#### 외부 변수와 기호 쓰기 (Accessing External Variables and Symbols)

다른 모듈이 내보낸 변수와 기호는 `EXTERN`으로 가져온다. 변수는 크기 타입을, `=`나 `EQU`로 정의한 상수 기호는 `ABS`를 쓴다.

```text
EXTERN name : type

EXTERN one:WORD, two:SDWORD, three:PTR BYTE, four:ABS
```

#### EXTERNDEF를 쓴 포함 파일 (Using an INCLUDE File with EXTERNDEF)

MASM의 `EXTERNDEF`는 `PUBLIC`과 `EXTERN`을 한꺼번에 대신한다(EXTERNDEF takes the place of both PUBLIC and EXTERN). 이름을 정의한 모듈에서는 `PUBLIC`처럼, 이름을 쓰기만 하는 모듈에서는 `EXTERN`처럼 동작하고, 쓰지도 정의하지도 않으면 무시된다. 그래서 `EXTERNDEF` 선언을 포함 파일 하나에 모아 두고 모든 모듈이 그 파일을 `INCLUDE`하면 된다.

```asm
; vars.inc
EXTERNDEF count:DWORD, SYM1:ABS
```

```asm
; sub1.asm
.386
.model flat,STDCALL
INCLUDE vars.inc
SYM1 = 10
.data
count DWORD 0
END
```

```asm
; main.asm
.386
.model flat,stdcall
.stack 4096
ExitProcess proto, dwExitCode:dword
INCLUDE vars.inc
.code
main PROC
    mov   count,2000h       ; 다른 모듈의 변수에 쓴다: count = 2000h
    mov   eax,SYM1          ; 다른 모듈의 상수: EAX = 10
    INVOKE ExitProcess,0
main ENDP
END main
```

`sub1.asm`은 `count`와 `SYM1`을 정의하므로 `vars.inc`의 `EXTERNDEF`가 `PUBLIC`으로 동작하고, `main.asm`은 둘을 쓰기만 하므로 `EXTERN`으로 동작한다. 두 모듈 모두 `.model`을 직접 쓰고 Irvine32를 쓰지 않는 최소한의 형태다.

### 예제: ArraySum 프로그램 (Example: ArraySum Program)

사용자에게 정수 여러 개를 입력받아 배열에 저장하고, 합을 구해 출력하는 프로그램을 모듈 다섯 개로 나눠 보자. 프로시저의 호출 관계는 다음과 같다(교재 Figure 8-5). `Clrscr`, `WriteString`, `ReadInt`, `WriteInt`는 Irvine32 라이브러리 프로시저다.

```text
                        ArraySum Program (main)
                                  |
     +------------------+---------+----------+-------------------+
     |                  |                    |                   |
  Clrscr        PromptForIntegers        ArraySum           DisplaySum
                        |                                        |
               +--------+--------+                    +----------+--------+
               |                 |                    |                   |
          WriteString         ReadInt            WriteString          WriteInt
```

슬라이드 54번은 비어 있으므로, 교재의 Microsoft 고급 방식(`INVOKE`·`PROTO`) 코드로 채운다. 모든 모듈이 포함하는 `sum.inc`에 세 프로시저의 `PROTO`를 모아 두었다.

```asm
; sum.inc: ArraySum 프로그램의 포함 파일
INCLUDE Irvine32.inc

PromptForIntegers PROTO,
    ptrPrompt:PTR BYTE,     ; prompt string
    ptrArray:PTR DWORD,     ; points to the array
    arraySize:DWORD         ; size of the array

ArraySum PROTO,
    ptrArray:PTR DWORD,     ; points to the array
    count:DWORD             ; size of the array

DisplaySum PROTO,
    ptrPrompt:PTR BYTE,     ; prompt string
    theSum:DWORD            ; sum of the array
```

```asm
; _prompt.asm: 정수를 입력받아 배열을 채운다
INCLUDE sum.inc

.code
PromptForIntegers PROC,
    ptrPrompt:PTR BYTE,     ; prompt string
    ptrArray:PTR DWORD,     ; pointer to array
    arraySize:DWORD         ; size of the array
    pushad                  ; save all registers
    mov  ecx,arraySize
    cmp  ecx,0              ; array size <= 0?
    jle  L2                 ; yes: quit
    mov  edx,ptrPrompt      ; address of the prompt
    mov  esi,ptrArray
L1: call WriteString        ; display string
    call ReadInt            ; read integer into EAX
    call Crlf               ; go to next output line
    mov  [esi],eax          ; store in array
    add  esi,4              ; next integer
    loop L1
L2: popad                   ; restore all registers
    ret
PromptForIntegers ENDP
END
```

```asm
; _arrysum.asm: 배열의 합을 구한다
INCLUDE sum.inc

.code
ArraySum PROC,
    ptrArray:PTR DWORD,     ; pointer to array
    arraySize:DWORD         ; size of array
    push ecx                ; don't push EAX
    push esi
    mov  eax,0              ; set the sum to zero
    mov  esi,ptrArray
    mov  ecx,arraySize
    cmp  ecx,0              ; array size <= 0?
    jle  L2                 ; yes: quit
L1: add  eax,[esi]          ; add each integer to sum
    add  esi,4              ; point to next integer
    loop L1                 ; repeat for array size
L2: pop  esi
    pop  ecx                ; return sum in EAX
    ret
ArraySum ENDP
END
```

```asm
; _display.asm: 합을 출력한다
INCLUDE sum.inc

.code
DisplaySum PROC,
    ptrPrompt:PTR BYTE,     ; prompt string
    theSum:DWORD            ; the array sum
    push eax
    push edx
    mov  edx,ptrPrompt      ; pointer to prompt
    call WriteString
    mov  eax,theSum
    call WriteInt           ; display EAX
    call Crlf
    pop  edx
    pop  eax
    ret
DisplaySum ENDP
END
```

```asm
; Sum_main.asm: 정수 합계 프로그램의 주 모듈
INCLUDE sum.inc

Count = 3                   ; modify Count to change the size of the array

.data
prompt1 BYTE "Enter a signed integer: ",0
prompt2 BYTE "The sum of the integers is: ",0
array   DWORD Count DUP(?)
sum     DWORD ?

.code
main PROC
    call Clrscr
    INVOKE PromptForIntegers,
        ADDR prompt1,
        ADDR array,
        Count
    INVOKE ArraySum,
        ADDR array,
        Count
    mov  sum,eax            ; save the sum: sum = 25
    INVOKE DisplaySum,
        ADDR prompt2,
        sum
    call Crlf
    exit
main ENDP
END main
```

10, −25, 40을 입력했을 때의 실행 결과:

```text
Enter a signed integer: 10

Enter a signed integer: -25

Enter a signed integer: 40

The sum of the integers is: +25
```

입력 줄 사이의 빈 줄은 `ReadInt` 다음의 `call Crlf`가 만든 것이다(사용자가 누른 Enter로 이미 줄이 바뀐 뒤에 한 번 더 바꾼다). `WriteInt`는 부호를 항상 붙여 출력하므로 `+25`가 된다.

모듈 사이의 연결은 모두 `sum.inc`의 `PROTO`가 맡는다. 같은 `PROTO`를 정의하는 모듈(`_arrysum.asm` 등)이 포함하면 정의와 원형이 일치하는지 어셈블러가 검사하고, 호출하는 모듈(`Sum_main.asm`)이 포함하면 외부 프로시저 선언이 된다. 전통적인 방식으로 쓴다면 `Sum_main.asm`에 `EXTERN ArraySum@0:PROC`처럼 선언하고 인수를 직접 `PUSH`한 뒤, 각 프로시저는 매개변수 목록 없이 `[ebp+8]`로 인수를 읽고 `ret 8`처럼 직접 치워야 한다(교재 예제 `ModSum32_traditional`). 이때 매개변수를 선언하지 않았으므로 이름은 `@0`으로 끝난다.

> [!TIP]
> Visual Studio에서는 모듈 파일들을 모두 같은 프로젝트에 추가하면 각각 어셈블되어 함께 링크된다. 명령줄에서는 `ml /c /coff main.asm sub1.asm` 처럼 모듈을 따로 어셈블한 뒤 `link main.obj sub1.obj ...`로 합친다. `.inc` 파일은 어셈블하지 않고 `INCLUDE`로만 쓴다.

---

## 8.6 매개변수 고급 활용 (Advanced Use of Parameters, 보충)

교재 8.6절(선택 주제)의 내용이다. 슬라이드에는 없지만, 스택 매개변수를 손으로 다룰 때 실제로 자주 부딪히는 문제들이다.

### USES 연산자가 스택에 주는 영향 (Stack Affected by the USES Operator)

`USES`로 지정한 레지스터는 프로시저의 **맨 처음**에 `PUSH`되고, 모든 `ret` 앞에서 거꾸로 `POP`된다. 매개변수도 `LOCAL`도 없는 프로시저라면 간단하다.

```text
MySub1 PROC USES ecx edx            MySub1 PROC
    ret                                 push ecx
MySub1 ENDP                             push edx
                                        pop  edx
                                        pop  ecx
                                        ret
                                    MySub1 ENDP
```

문제는 `USES`를 쓰면서 프레임을 **손으로** 만들 때 생긴다. 어셈블러가 넣은 `push ecx` / `push edx`가 손으로 쓴 `push ebp`보다 **먼저** 실행되므로, 매개변수가 생각보다 8바이트 더 멀리 있게 된다.

```asm
; USES와 손으로 만든 프레임을 섞으면 오프셋이 바뀐다
INCLUDE Irvine32.inc

.code
main PROC
    mov  ecx,1111h
    mov  edx,2222h
    push 6
    call MySub2             ; EAX = 6, ECX = 1111h, EDX = 2222h
    exit
main ENDP

MySub2 PROC USES ecx edx
    push ebp                ; save base pointer
    mov  ebp,esp            ; base of stack frame: [ebp+8] = 1111h, [ebp+4] = 2222h
    mov  eax,[ebp+16]       ; get the stack parameter: EAX = 6
    pop  ebp                ; restore base pointer
    ret  4                  ; clean up the stack
MySub2 ENDP
END main
```

```text
           +------------------+
 [EBP+16]  |  6 (parameter)   |
 [EBP+12]  |  return address  |
 [EBP+8]   |  ECX             |   USES가 저장한 레지스터
 [EBP+4]   |  EDX             |
 [EBP]     |  EBP             |   <- EBP, ESP
           +------------------+
```

습관대로 `[ebp+8]`을 읽었다면 매개변수가 아니라 저장된 ECX(1111h)를 읽었을 것이다. 해결 방법은 둘 중 하나다.

- 프레임을 손으로 만들 때는 `USES`를 쓰지 말고, `mov ebp,esp` 다음에 레지스터를 직접 `PUSH`한다(8.2절의 `MySub`).
- `USES`를 쓸 때는 매개변수를 `PROC`의 매개변수 목록으로 선언한다. 그러면 어셈블러가 `push ebp` / `mov ebp,esp`를 `USES`의 `PUSH`보다 먼저 만들어 주어 매개변수가 `[ebp+8]`에 온다(8.4절의 `Read_File`).

### 8비트·16비트 인수 전달 (Passing 8-Bit and 16-Bit Arguments on the Stack)

32비트 모드에서 스택 인수는 32비트로 넣는 것이 원칙이다. `PUSH`는 8비트 피연산자를 받지 않는다.

```asm
.data
charVal BYTE 'x'
.code
push charVal                ; 어셈블 오류 (8비트 PUSH는 없다)
push 'x'                    ; 즉시값은 32비트로 들어간다: [ESP] = 78h
add  esp,4
```

바이트 변수를 넘기려면 먼저 `MOVZX`(부호 없는 값)나 `MOVSX`(부호 있는 값)로 32비트 레지스터에 넓힌 다음 넣는다. 다음 `Uppercase`는 문자 하나를 스택으로 받아 소문자이면 대문자로 바꿔 AL로 돌려준다.

```asm
; Demonstrate 8-bit stack argument     (Uppercase.asm)
INCLUDE Irvine32.inc

.data
charVal BYTE 'x'

.code
main PROC
    movzx eax,charVal       ; move with extension
    push eax                ; [ESP] = 78h
    call Uppercase          ; AL = 58h
    call WriteChar
    call Crlf
    exit
main ENDP

Uppercase PROC              ; convert stack char arg to uppercase
    push ebp
    mov  ebp,esp
    mov  al,[ebp+8]         ; AL = character
    cmp  al,'a'             ; less than 'a'?
    jb   L1                 ; yes: do nothing
    cmp  al,'z'             ; greater than 'z'?
    ja   L1                 ; yes: do nothing
    sub  al,32              ; no: convert it
L1: pop  ebp
    ret  4                  ; clean up the stack
Uppercase ENDP
END main
```

실행 결과:

```text
X
```

16비트 값은 `PUSH`할 수는 있지만 2바이트만 들어가므로 ESP가 4의 배수에서 벗어난다. 그 뒤의 모든 스택 접근이 어긋난 주소에서 일어나 느려지고, 매개변수 오프셋 계산도 헷갈리게 된다. 다음 `Smallint`는 16비트 인수를 받아 두 배로 만든다. 2바이트를 받았으므로 `ret 2`로 치워야 한다.

```asm
; Demonstrate 16-bit stack parameter   (Smallint.asm)
INCLUDE Irvine32.inc

.data
wordVal WORD 1234h

.code
main PROC
    mov  ebx,esp
    push wordVal            ; 2바이트만 들어간다: ESP = EBX-2
    call Smallint           ; EAX = 00002468h, ESP = EBX
    exit
main ENDP

Smallint PROC               ; receives a 16-bit stack parameter. Uses STDCALL.
    push ebp
    mov  eax,0
    mov  ebp,esp
    mov  ax,[ebp+8]         ; get 16-bit parameter: AX = 1234h
    add  ax,ax              ; double it, return in EAX
    pop  ebp
    ret  2                  ; clean up the stack
Smallint ENDP
END main
```

(교재 예제 파일 `Smallint.asm`은 `PROC` 앞의 프로시저 이름이 빠져 있어 그대로는 어셈블되지 않는다. 위 코드에서는 `Smallint PROC`로 채웠다.)

`INVOKE`는 이런 넓히기를 자동으로 해 준다. 8.4절에서 본 것처럼 바이트·워드 변수를 DWORD 매개변수에 넘기면 `movzx eax,변수` / `push eax`를 만든다. 그 대가로 EAX가 바뀐다.

### 64비트 인수 전달 (Passing 64-Bit Arguments)

32비트 모드에서 64비트 정수는 더블워드 두 개로 나눠 넣는다. **상위 더블워드를 먼저, 하위 더블워드를 나중에** 넣으면, 스택에서 하위 더블워드가 낮은 주소(`[ebp+8]`)에, 상위 더블워드가 높은 주소(`[ebp+12]`)에 놓인다. 메모리에 저장된 64비트 정수와 같은 리틀 엔디안 순서다.

```asm
; Multiword procedure arguments        (Multiword.asm)
INCLUDE Irvine32.inc

WriteHex64Proto PROTO, qVal:QWORD

.data
longVal QWORD 1234567800ABCDEFh

.code
main PROC
    push DWORD PTR longVal + 4      ; high
    push DWORD PTR longVal          ; low: [ESP] = 00ABCDEFh, [ESP+4] = 12345678h
    call WriteHex64
    call Crlf
    INVOKE WriteHex64Proto, longVal ; INVOKE도 상위 → 하위 순서로 넣는다
    call Crlf
    exit
main ENDP

; Displays a 64-bit integer in hexadecimal
WriteHex64 PROC
    push ebp
    mov  ebp,esp
    mov  eax,[ebp+12]       ; high doubleword: EAX = 12345678h
    call WriteHex
    mov  eax,[ebp+8]        ; low doubleword: EAX = 00ABCDEFh
    call WriteHex
    pop  ebp
    ret  8                  ; clean up the stack
WriteHex64 ENDP

; 같은 일을 QWORD 매개변수로
WriteHex64Proto PROC, qVal:QWORD
    mov  eax,DWORD PTR qVal+4       ; high doubleword
    call WriteHex
    mov  eax,DWORD PTR qVal         ; low doubleword
    call WriteHex
    ret                             ; 어셈블러가 ret 8로 바꾼다
WriteHex64Proto ENDP
END main
```

실행 결과:

```text
1234567800ABCDEF
1234567800ABCDEF
```

`INVOKE WriteHex64Proto, longVal`은 `push DWORD PTR longVal+4` / `push DWORD PTR longVal`로 바뀐다. 매개변수가 8바이트이므로 이 프로시저의 외부 이름은 `WriteHex64Proto@8`이다.

### 더블워드가 아닌 지역 변수 (Non-Doubleword Local Variables)

`LOCAL`로 바이트·워드 변수를 선언하면, 어셈블러는 각 변수를 **자기 크기의 배수 위치**에 놓고(4바이트보다 큰 것은 4의 배수), 전체 크기를 4의 배수로 올려 ESP를 내린다. `LOCAL var1:BYTE` 하나만 있어도 ESP는 4 내려가고 `var1`은 `[ebp-1]`에 놓이며, 그 아래 3바이트는 쓰이지 않는다.

```asm
; 크기가 다른 지역 변수들의 배치
INCLUDE Irvine32.inc

.code
main PROC
    call Example1
    call MixedLocals
    exit
main ENDP

Example1 PROC
    LOCAL var1:BYTE
    mov  var1,0FFh          ; ESP = EBP-4, BYTE PTR [ebp-1] = 0FFh
    ret
Example1 ENDP

MixedLocals PROC
    LOCAL w1:WORD, b1:BYTE, d1:DWORD, q1:QWORD
    mov  w1,1               ; ESP = EBP-16, WORD PTR [ebp-2] = 1
    mov  b1,2               ; BYTE PTR [ebp-3] = 2
    mov  d1,3               ; [ebp-8] = 3
    mov  DWORD PTR q1,4     ; [ebp-16] = 4
    mov  DWORD PTR q1+4,5   ; [ebp-12] = 5
    ret
MixedLocals ENDP
END main
```

| 선언 | 위치 | 크기 | 비고 |
|---|---|---|---|
| `w1:WORD` | `[ebp-2]` | 2 | |
| `b1:BYTE` | `[ebp-3]` | 1 | `w1` 바로 아래 |
| `d1:DWORD` | `[ebp-8]` | 4 | 4의 배수 위치로 맞추느라 `[ebp-4]`는 비운다 |
| `q1:QWORD` | `[ebp-16]` | 8 | 하위 더블워드가 `[ebp-16]`, 상위가 `[ebp-12]` |
| (합계) | ESP를 16 내림 | | |

선언 순서를 바꾸면 빈 바이트가 줄어들 수 있다. 예를 들어 `LOCAL d1:DWORD, w1:WORD, b1:BYTE`로 쓰면 `d1`은 `[ebp-4]`, `w1`은 `[ebp-6]`, `b1`은 `[ebp-7]`에 놓여 8바이트로 충분하다.

#### 스택 공간 예약하기 (보충)

지역 변수는 스택에 만들어지므로, 큰 지역 배열(`LOCAL buffer[100000]:BYTE` 같은)이나 깊은 재귀는 스택을 많이 쓴다. Visual Studio로 만든 프로그램의 기본 스택 예약 크기는 1MB이고, 링커의 `/STACK:reserve` 옵션으로 늘릴 수 있다. 큰 데이터는 지역 변수 대신 `.data`의 전역 변수나 힙(heap)에 두는 편이 안전하다.

## 8.7 자바 바이트코드 (Java Bytecodes, 보충)

교재 8.7절(선택 주제)의 내용이다. 자바 프로그램은 x86 기계어가 아니라 **자바 가상 머신**(Java Virtual Machine, JVM)의 명령어인 **바이트코드**(bytecode)로 컴파일된다. JVM은 레지스터 대신 **피연산자 스택**(operand stack)으로 계산하는 **스택 기계**(stack machine)다.

- 메서드를 호출할 때마다 JVM은 **프레임**을 만든다. 프레임에는 **지역 변수 배열**(local variable array, 매개변수가 0번부터 들어간다)과 **피연산자 스택**이 있다. x86의 스택 프레임에서 `[ebp+8]`이 매개변수, `[ebp-4]`가 지역 변수였던 것과 같은 역할이다.
- 대부분의 명령어는 피연산자를 스택에서 꺼내고 결과를 스택에 넣는다. 예를 들어 `iadd`는 int 두 개를 꺼내 더한 값을 넣는다.
- 명령어 이름의 첫 글자가 타입을 나타낸다: `i`(int), `l`(long), `f`(float), `d`(double), `a`(참조).

| 바이트코드 | 하는 일 | 비슷한 x86 코드 |
|---|---|---|
| `iload_0` | 지역 변수 0번을 스택에 넣는다 | `push [ebp+8]` |
| `istore_1` | 스택에서 꺼내 지역 변수 1번에 저장 | `pop [ebp-4]` |
| `iconst_1` | 상수 1을 넣는다 | `push 1` |
| `iadd`, `isub`, `imul` | 두 개를 꺼내 계산한 결과를 넣는다 | `pop` 두 번 + `add` + `push` |
| `iinc 2, 1` | 지역 변수 2번에 1을 더한다(스택을 쓰지 않음) | `inc DWORD PTR [ebp-8]` |
| `if_icmpgt L` | 두 개를 꺼내 비교해 첫째 > 둘째이면 점프 | `cmp` + `jg` |
| `ifne L` | 하나를 꺼내 0이 아니면 점프 | `cmp ...,0` + `jne` |
| `goto L` | 무조건 점프 | `jmp` |
| `invokestatic` | 정적 메서드 호출 (인수는 스택으로) | `call` |
| `ireturn` | 스택 맨 위의 int를 반환 | 반환값을 EAX에 두고 `ret` |

다음 자바 메서드들을 `javac`(JDK 21)로 컴파일하고 `javap -c`로 역어셈블해 보자.

```java
public class StackDemo {
    static int addTwo(int x, int y) {
        return x + y;
    }

    static int sumTo(int n) {
        int sum = 0;
        for (int i = 1; i <= n; i++)
            sum += i;
        return sum;
    }

    static int factorial(int n) {
        if (n == 0)
            return 1;
        return n * factorial(n - 1);
    }
}
```

`javap -c StackDemo.class`의 출력 중 해당 부분:

```text
  static int addTwo(int, int);
    Code:
       0: iload_0
       1: iload_1
       2: iadd
       3: ireturn

  static int sumTo(int);
    Code:
       0: iconst_0
       1: istore_1
       2: iconst_1
       3: istore_2
       4: iload_2
       5: iload_0
       6: if_icmpgt     19
       9: iload_1
      10: iload_2
      11: iadd
      12: istore_1
      13: iinc          2, 1
      16: goto          4
      19: iload_1
      20: ireturn

  static int factorial(int);
    Code:
       0: iload_0
       1: ifne          6
       4: iconst_1
       5: ireturn
       6: iload_0
       7: iload_0
       8: iconst_1
       9: isub
      10: invokestatic  #7                  // Method factorial:(I)I
      13: imul
      14: ireturn
```

맨 앞의 숫자는 메서드 안에서 그 명령어의 바이트 오프셋이다.

- **`addTwo`**: 매개변수 `x`, `y`는 지역 변수 0번, 1번이다. 둘을 스택에 넣고(`iload_0`, `iload_1`), `iadd`가 꺼내 더한 값을 넣고, `ireturn`이 그 값을 돌려준다. 8.2절의 `mov eax,[ebp+8]` / `add eax,[ebp+12]`와 같은 일이다.
- **`sumTo`**: `sum`은 지역 변수 1번, `i`는 2번이다. 오프셋 4~6이 반복 조건 `i <= n`인데, 바이트코드는 **반대 조건**(`i > n`, `if_icmpgt`)일 때 루프 밖(19)으로 점프한다. 6장에서 `if`문을 어셈블리로 옮길 때 조건을 뒤집어 점프하던 것과 같다. `i++`는 스택을 쓰지 않는 `iinc 2, 1` 한 명령어가 된다.
- **`factorial`**: `n == 0`이 아니면(`ifne`) 6으로 점프한다. 6~9에서 `n`과 `n - 1`을 스택에 쌓은 뒤 `invokestatic`으로 자기 자신을 부른다. 호출이 돌아오면 `factorial(n - 1)`의 결과가 스택 맨 위에, 그 밑에 먼저 넣어 둔 `n`이 있으므로 `imul`로 곱한다. 8.3절의 `Factorial`이 `[ebp+8]`에 n을 남겨 두었다가 돌아온 뒤에 곱한 것과 같은 원리다.

`#7`은 상수 풀(constant pool)의 항목 번호로, 컴파일러 버전에 따라 달라질 수 있다. 이 프로그램을 실행해 `addTwo(5, 6)`, `sumTo(5)`, `factorial(5)`를 출력하면 x86 예제와 같은 `11 15 120`이 나온다.

---

## 부록 A. 핵심 정리 표

### 스택 프레임의 구성

`push ebp` / `mov ebp,esp` / `sub esp,n` / (레지스터 저장)으로 만든 표준 프레임에서의 위치다.

| 위치 | 들어 있는 것 | 넣는 쪽 |
|---|---|---|
| `[ebp+8]`, `[ebp+12]`, `[ebp+16]`, … | 첫 번째, 두 번째, 세 번째 인수 … | 호출한 쪽 (`PUSH`, 오른쪽 인수부터) |
| `[ebp+4]` | 복귀 주소 | `CALL` |
| `[ebp]` | 호출한 쪽의 EBP | 호출된 쪽 (`push ebp`) |
| `[ebp-4]`, `[ebp-8]`, … | 지역 변수 | 호출된 쪽 (`sub esp,n`, `ENTER`, `LOCAL`) |
| 지역 변수 아래 | 저장된 레지스터 | 호출된 쪽 (`PUSH`, `USES`) |

프로시저가 끝날 때는 위의 순서를 거꾸로 되돌린다.

| 에필로그 | 하는 일 |
|---|---|
| `pop` (저장한 레지스터를 거꾸로) | 레지스터 복원 |
| `mov esp,ebp` | 지역 변수 해제 |
| `pop ebp` | 호출한 쪽의 EBP 복원 |
| `ret` / `ret n` | 복귀 (STDCALL이면 인수 n바이트도 치운다) |

### 호출 규약 비교

| 항목 | C (`cdecl`) | STDCALL | `__fastcall` (32비트) | Microsoft x64 |
|---|---|---|---|---|
| 인수 전달 | 스택, 오른쪽부터 | 스택, 오른쪽부터 | 처음 둘은 ECX·EDX, 나머지는 스택 | 처음 넷은 RCX·RDX·R8·R9, 나머지는 스택 |
| 인수를 치우는 쪽 | 호출한 쪽 | 호출된 쪽 (`ret n`) | 호출된 쪽 | 호출한 쪽 |
| 가변 인수 | 가능 | 불가능 | 불가능 | 가능 |
| 정수 반환값 | EAX (64비트는 EDX:EAX) | EAX | EAX | RAX |
| C 함수 이름 장식 | `_name` | `_name@n` | `@name@n` | 장식 없음 |
| 그 밖의 약속 | | | | 섀도 공간 32바이트, RSP 16바이트 정렬 |

### 명령어와 지시어

| 명령어·지시어 | 형식 | 하는 일 |
|---|---|---|
| `RET n` | `ret 8` | 복귀 주소를 꺼낸 뒤 ESP에 n을 더한다 |
| `LEA` | `lea esi,[ebp-30]` | 주소식의 값(주소)을 레지스터에 넣는다. 메모리를 읽지 않고 플래그도 바꾸지 않는다 |
| `ENTER` | `enter 8,0` | `push ebp` / `mov ebp,esp` / `sub esp,8`과 같다. 두 번째 피연산자는 중첩 수준 |
| `LEAVE` | `leave` | `mov esp,ebp` / `pop ebp`와 같다 |
| `LOCAL` | `LOCAL temp:DWORD, flag:BYTE` | 이름 있는 지역 변수를 선언한다. `PROC` 바로 다음에 쓴다 |
| `USES` | `MySub PROC USES eax ebx` | 지정한 레지스터를 프로시저 시작에서 저장하고 모든 `ret` 앞에서 복원한다 |
| `PROC` 매개변수 | `AddTwo PROC, a:DWORD, b:DWORD` | 매개변수 이름을 `[ebp+8]` 등으로 바꾸고 프롤로그·에필로그·`ret n`을 만든다 |
| `PROTO` | `AddTwo PROTO, a:DWORD, b:DWORD` | 프로시저의 원형. `INVOKE`의 인수를 검사하고 외부 프로시저를 선언한다 |
| `INVOKE` | `INVOKE AddTwo, 5, 6` | 인수를 넣고 호출한다. C 규약이면 `add esp,n`도 붙인다 (32비트 전용) |
| `ADDR` | `INVOKE Swap, ADDR a, ADDR b` | `INVOKE`의 인수로 주소를 넘긴다. 지역 변수면 `lea eax,…`가 된다 |
| `VARARG` | `Sum PROTO C, n:DWORD, args:VARARG` | C 규약에서 개수가 정해지지 않은 인수 |
| `PRIVATE` / `PUBLIC` | `mySub PROC PRIVATE`, `PUBLIC sub1, sub2` | 프로시저를 감추거나 내보낸다 (프로시저의 기본값은 공개) |
| `OPTION PROC:PRIVATE` | 파일 맨 위 | 그 모듈의 프로시저를 기본적으로 감춘다 |
| `EXTERN` | `EXTERN sub1@0:PROC`, `EXTERN count:DWORD` | 다른 모듈의 이름을 가져온다 (상수는 `ABS`) |
| `EXTERNDEF` | `EXTERNDEF count:DWORD` | 정의한 모듈에서는 `PUBLIC`, 쓰는 모듈에서는 `EXTERN`처럼 동작한다 |

---

## 부록 B. C 컴파일러가 만든 스택 프레임

이 장에서 손으로 만든 프레임은 C 컴파일러가 만드는 것과 같은 구조다. 다음 C 코드를 GCC 13으로 32비트(`-m32`) 어셈블리로 컴파일해 보았다. 출력을 읽기 쉽게 하려고 인텔 문법(`-masm=intel`)을 쓰고, 위치 독립 코드·스택 보호·제어 흐름 보호 같은 부가 기능은 껐다(`-fno-pic -fno-stack-protector -fcf-protection=none -fno-asynchronous-unwind-tables`).

```c
int AddTwo(int x, int y)
{
    return x + y;
}

int __attribute__((stdcall)) AddTwoStd(int x, int y)
{
    return x + y;
}

int caller(void)
{
    return AddTwo(5, 6) + AddTwoStd(5, 6);
}

void makeArray(void)
{
    char myString[30];
    for (int i = 0; i < 30; i++)
        myString[i] = '*';
}

unsigned factorial(unsigned n)
{
    if (n == 0)
        return 1;
    return n * factorial(n - 1);
}
```

### B.1 최적화하지 않았을 때 (`-O0`)

```nasm
AddTwo:
    push    ebp
    mov     ebp, esp
    mov     edx, DWORD PTR [ebp+8]
    mov     eax, DWORD PTR [ebp+12]
    add     eax, edx
    pop     ebp
    ret
AddTwoStd:
    push    ebp
    mov     ebp, esp
    mov     edx, DWORD PTR [ebp+8]
    mov     eax, DWORD PTR [ebp+12]
    add     eax, edx
    pop     ebp
    ret     8
caller:
    push    ebp
    mov     ebp, esp
    push    ebx
    push    6
    push    5
    call    AddTwo
    add     esp, 8
    mov     ebx, eax
    push    6
    push    5
    call    AddTwoStd
    add     eax, ebx
    mov     ebx, DWORD PTR [ebp-4]
    leave
    ret
makeArray:
    push    ebp
    mov     ebp, esp
    sub     esp, 48
    mov     DWORD PTR [ebp-4], 0
    jmp     .L8
.L9:
    lea     edx, [ebp-34]
    mov     eax, DWORD PTR [ebp-4]
    add     eax, edx
    mov     BYTE PTR [eax], 42
    add     DWORD PTR [ebp-4], 1
.L8:
    cmp     DWORD PTR [ebp-4], 29
    jle     .L9
    nop
    nop
    leave
    ret
factorial:
    push    ebp
    mov     ebp, esp
    sub     esp, 8
    cmp     DWORD PTR [ebp+8], 0
    jne     .L11
    mov     eax, 1
    jmp     .L12
.L11:
    mov     eax, DWORD PTR [ebp+8]
    sub     eax, 1
    sub     esp, 12
    push    eax
    call    factorial
    add     esp, 16
    imul    eax, DWORD PTR [ebp+8]
.L12:
    leave
    ret
```

이 장에서 배운 것이 거의 그대로 보인다.

- **프롤로그와 매개변수**: 모든 함수가 `push ebp` / `mov ebp,esp`로 시작하고, `x`와 `y`를 `[ebp+8]`, `[ebp+12]`로 읽는다.
- **C 규약과 STDCALL**: `AddTwo`(C 규약)는 `ret`으로 끝나고 호출한 쪽이 `add esp, 8`로 인수를 치운다. `stdcall`로 선언한 `AddTwoStd`는 `ret 8`로 끝나고 호출한 쪽은 치우지 않는다.
- **인수의 순서**: `AddTwo(5, 6)`을 `push 6` / `push 5`로, 오른쪽 인수부터 넣는다.
- **레지스터 저장**: `caller`는 EBX를 바꾸므로 `push ebx`로 저장했다가 `mov ebx, DWORD PTR [ebp-4]`로 되살린다(이 프레임에서 `[ebp-4]`가 저장된 EBX의 자리다).
- **`LEAVE`**: 지역 변수가 있는 함수는 `mov esp,ebp` / `pop ebp` 대신 `leave`를 쓴다. 반면 `ENTER`는 쓰지 않는다.
- **지역 변수와 `LEA`**: `makeArray`의 `i`는 `[ebp-4]`, `myString`은 `[ebp-34]`에 있고, 배열의 주소를 `lea edx, [ebp-34]`로 구한다. 지역 변수에 필요한 34바이트보다 많은 48바이트를 확보한 것은 아래의 정렬 규칙 때문이다.
- **재귀**: `factorial`은 `n - 1`을 넣고 자기 자신을 `call`한 뒤, 돌아와서 `[ebp+8]`에 남아 있는 `n`을 곱한다(`imul eax, DWORD PTR [ebp+8]`). 8.3절의 `Factorial`과 같은 구조다.

리눅스의 32비트 호출 규약(System V i386 ABI)은 `CALL` 직전에 ESP가 16의 배수이도록 요구한다. 그래서 `factorial`은 인수 하나(4바이트)를 넣기 전에 `sub esp, 12`로 12바이트를 더 내리고, 돌아온 뒤 `add esp, 16`으로 합쳐서 치운다. 이 정렬 규칙은 플랫폼의 약속이므로, Windows용 컴파일러가 만든 32비트 코드에서는 이 부분이 다를 수 있다. ELF 형식이라 함수 이름 앞에 밑줄이 붙지 않은 것도 Windows와 다른 점이다.

### B.2 최적화했을 때 (`-O2`)

```nasm
AddTwo:
    mov     eax, DWORD PTR [esp+8]
    add     eax, DWORD PTR [esp+4]
    ret
AddTwoStd:
    mov     eax, DWORD PTR [esp+8]
    add     eax, DWORD PTR [esp+4]
    ret     8
caller:
    mov     eax, 22
    ret
makeArray:
    ret
factorial:
    mov     eax, DWORD PTR [esp+4]
    mov     edx, 1
    test    eax, eax
    je      .L6
.L7:
    imul    edx, eax
    sub     eax, 1
    jne     .L7
.L6:
    mov     eax, edx
    ret
```

최적화하면 모습이 크게 달라진다.

- **프레임 포인터 생략**: `AddTwo`에 `push ebp` / `mov ebp,esp`가 없다. 대신 ESP 기준으로 `[esp+4]`(첫 인수), `[esp+8]`(둘째 인수)을 읽는다. 함수 안에서 `PUSH`를 하지 않으므로 ESP 기준 오프셋이 바뀌지 않아 가능한 일이다. EBP는 일반 레지스터로 쓸 수 있게 된다.
- **상수 계산**: `caller`의 `AddTwo(5, 6) + AddTwoStd(5, 6)`은 컴파일할 때 22로 계산되어 호출 자체가 사라졌다.
- **쓸모없는 코드 제거**: `makeArray`는 채운 배열을 아무 데도 쓰지 않으므로 `ret` 하나만 남았다.
- **재귀를 반복으로**: `factorial`의 재귀 호출이 사라지고 EDX에 곱을 모으는 루프(`.L7`)가 되었다. 8.3절의 재귀 `Factorial`이 프레임을 n + 1개 쌓는 것과 달리 스택을 전혀 더 쓰지 않는다.

최적화된 프로그램을 디버거로 볼 때 지역 변수의 값을 볼 수 없거나 실행 순서가 소스와 다르게 보이는 이유가 여기에 있다. 변수가 메모리에 없거나, 코드가 아예 사라졌거나, 다른 모양으로 바뀌었기 때문이다.

---

## 부록 C. 자주 하는 실수와 오류 메시지

### 어셈블할 때 걸리는 오류

이 문서의 예제를 JWasm으로 어셈블해서 확인한 오류다. MASM의 메시지 문구와 번호는 조금 다를 수 있다.

| 잘못된 코드 | 원인 | 고치는 방법 |
|---|---|---|
| `INVOKE Later, 1` (`Later`가 뒤에 정의됨) | 원형을 모르는 프로시저를 `INVOKE`했다 (`INVOKE requires prototype for procedure`) | 맨 위에 `Later PROTO, x:DWORD`를 쓴다 |
| `INVOKE AddTwo, 1, 2, 3` | 인수 개수가 `PROTO`와 다르다 | 인수 개수를 맞춘다 |
| `mov esi,ADDR myArray` | `ADDR`은 `INVOKE` 안에서만 쓸 수 있다 | `mov esi,OFFSET myArray` |
| `mov esi,OFFSET [ebp-30]` | `OFFSET`은 어셈블할 때 정해지는 주소만 계산한다 (`Invalid operand for OFFSET`) | `lea esi,[ebp-30]` |
| `push charVal` (BYTE 변수) | 8비트 `PUSH`는 없다 | `movzx eax,charVal` / `push eax` |
| 명령어 다음에 `LOCAL` | `LOCAL`은 `PROC` 바로 다음에 와야 한다 (`PROC, MACRO or macro loop directive must precede LOCAL`) | `LOCAL`을 프로시저 맨 앞으로 옮긴다 |
| `lea esi,[ebp–30]` (대시 문자) | 슬라이드의 `–`는 빼기 기호가 아니다 | 하이픈 `-`로 다시 입력한다 |
| `LOCAL a:BYTE, b:DWORD, c:WORD` | `C`는 호출 규약 이름(`PROC C`)이라 식별자로 쓸 수 없다 (`Syntax error: c`) | 다른 이름(`z` 등)을 쓴다 |

### 어셈블은 되지만 틀리게 동작하는 실수

| 실수 | 증상 | 고치는 방법 |
|---|---|---|
| C 규약 프로시저를 부르고 `add esp,n`을 빠뜨림 | 호출한 프로시저의 `RET`이 인수를 복귀 주소로 꺼내 엉뚱한 곳으로 간다 | 호출 직후 `add esp,n` |
| `ret n`의 n이 인수 바이트 수와 다름 | 돌아온 뒤 ESP가 어긋나 이후의 `POP`과 `RET`이 모두 틀린다 | n = 4 × (DWORD 인수 개수) |
| STDCALL(`ret n`) 프로시저를 부르고 `add esp,n`도 함 | 인수를 두 번 치워 호출한 쪽의 스택이 망가진다 | 규약을 하나로 정한다. `PROTO`/`INVOKE`를 쓰면 실수가 줄어든다 |
| 레지스터를 `mov ebp,esp` 앞에서 저장 | 매개변수가 `[ebp+8]`이 아니라 더 위에 있다 | `mov ebp,esp` 다음에 저장한다 |
| `USES`와 손으로 만든 `push ebp`를 섞음 | 매개변수가 `[ebp+16]` 등으로 밀린다 | 매개변수를 `PROC` 목록으로 선언한다 ([8.6](#uses-연산자가-스택에-주는-영향-stack-affected-by-the-uses-operator)) |
| 매개변수가 있는 `PROC` 안에서 `push ebp` / `mov ebp,esp`를 또 씀 | 어셈블러가 이미 프레임을 만들었으므로 이름 붙은 매개변수가 엉뚱한 곳(복귀 주소 등)을 가리킨다 | 프롤로그를 직접 쓰지 않는다 |
| 반환값이 있는데 EAX를 `USES`에 넣음 | `ret` 앞에서 EAX가 복원되어 반환값이 사라진다 | EAX는 저장하지 않는다 |
| 지역 변수를 초기화하지 않고 읽음 | 이전 호출이 남긴 값이 나온다 | 쓰기 전에 값을 넣는다 |
| 지역 변수의 주소를 돌려줌 | 다음 호출이 그 자리를 덮어써 값이 바뀐다 | 호출한 쪽이 버퍼를 마련해 주소를 넘긴다 |
| `ESP`를 4의 배수가 아닌 값만큼 내림 (`sub esp,30`, 16비트 `PUSH`) | 이후의 스택 접근이 정렬되지 않아 느려지고 오프셋이 헷갈린다 | 4의 배수로 올린다 (`sub esp,32`) |
| 재귀에 종료 조건이 없거나 도달하지 못함 | 스택 오버플로 | 기저 사례를 먼저 검사한다 |
| `INVOKE` 직전에 EAX에 넣은 값을 인수로 기대 | 작은 인수나 지역 변수의 `ADDR` 때문에 EAX가 바뀐다 | 인수를 32비트로 넘기거나 EAX를 저장한다 |
| 배열 원소의 주소를 `[arr+1]`로 계산 (DWORD 배열) | 오프셋은 바이트 단위라 원소 경계를 벗어난다 | `[arr + 1*TYPE arr]` |
| 포인터 매개변수에 즉시값을 넘김 | 그 값을 주소로 따라가 접근 위반 | `ADDR`이나 `OFFSET`으로 주소를 넘긴다 |

---

## 부록 D. 핵심 용어 정리

| 용어 | 설명 |
|---|---|
| 스택 프레임 (stack frame), 활성 레코드 (activation record) | 프로시저 호출 하나가 스택에 차지하는 영역. 인수, 복귀 주소, 저장된 EBP, 지역 변수, 저장된 레지스터로 이루어진다 |
| 프롤로그 / 에필로그 (prologue / epilogue) | 프레임을 만드는 프로시저 앞부분의 코드 / 프레임을 없애고 돌아가는 뒷부분의 코드 |
| 기준 포인터, 프레임 포인터 (base pointer, frame pointer) | 프레임의 기준점을 가리키는 EBP. 인수는 `[ebp+n]`, 지역 변수는 `[ebp-n]`이다 |
| 스택 매개변수 (stack parameter) | 스택으로 넘긴 인수. 명시적 스택 매개변수는 `[ebp+8]`처럼 오프셋을 직접 쓴 것이다 |
| 값 전달 / 참조 전달 (pass by value / by reference) | 값의 복사본을 넘김 / 변수의 주소를 넘김 |
| 입력·출력·입력-출력 매개변수 | 데이터가 호출한 쪽→프로시저, 프로시저→호출한 쪽, 양방향으로 흐르는 매개변수 |
| 호출 규약 (calling convention) | 인수의 전달 순서·위치, 인수를 치우는 쪽, 반환값의 위치, 보존할 레지스터 등의 약속 |
| C 규약 (`cdecl`) | 인수를 오른쪽부터 넣고 호출한 쪽이 치우는 규약. 가변 인수가 가능하다 |
| STDCALL | 인수를 오른쪽부터 넣고 호출된 쪽이 `ret n`으로 치우는 규약. Windows API가 쓴다 |
| `__fastcall` | 32비트 Microsoft 규약. 처음 두 인수를 ECX·EDX로 넘긴다 |
| 섀도 공간 (shadow space, home space) | x64 규약에서 호출한 쪽이 확보하는 32바이트. 호출된 쪽이 레지스터 인수를 저장할 수 있다 |
| 이름 장식 (name decoration) | 오브젝트 파일에서 함수 이름에 규약 정보를 붙이는 것. 예: `_AddTwo@8` |
| 지역 변수 (local variable) | 프로시저 안에서만 쓰는 변수. 스택의 EBP 아래에 만들어진다 |
| `LEA` (load effective address) | 주소식이 가리키는 주소 자체를 레지스터에 넣는 명령어 |
| 중첩 수준 (nesting level) | `ENTER`의 두 번째 피연산자. 중첩 프로시저를 지원하는 언어를 위한 것이다 |
| 재귀 (recursion) | 프로시저가 직접 또는 간접으로 자기 자신을 부르는 것 |
| 기저 사례, 종료 조건 (base case, terminating condition) | 재귀 호출 없이 바로 답을 돌려주는 경우 |
| 꼬리 재귀 (tail recursion) | 재귀 호출이 프로시저의 마지막 동작인 재귀. 반복문으로 바꾸기 쉽다 |
| 스택 오버플로 (stack overflow) | 스택이 예약된 크기를 넘어서는 것. 끝없는 재귀가 대표적인 원인이다 |
| 원형 (prototype) | 프로시저의 이름, 규약, 매개변수를 미리 선언한 것 (`PROTO`) |
| 모듈 (module) | 따로 어셈블되는 소스 파일. 링커가 오브젝트 모듈들을 합친다 |
| 공개 / 비공개 (public / private) | 다른 모듈에서 이름을 볼 수 있는지 여부 |
| 외부 이름 (external name) | 다른 모듈에서 정의된 이름 (`EXTERN`으로 선언) |
| 진입점 (entry point) | 프로그램이 실행을 시작하는 주소. 링커가 실행 파일에 기록한다 |
| 피연산자 스택 (operand stack) | JVM이 계산에 쓰는 스택. 바이트코드 명령어는 여기서 피연산자를 꺼내고 결과를 넣는다 |
| 바이트코드 (bytecode) | 자바 컴파일러가 만드는 JVM용 명령어 |

---

## 부록 E. 복습 문제

교재 8.10절(Review Questions and Exercises)과 같은 유형의 문제를 직접 만들었다. **단답형**은 코드의 결과나 스택의 모양을 예측하는 문제, **알고리즘 작성**은 짧은 프로시저를 직접 써 보는 문제다. 각 문제의 **정답 보기**를 누르면 답과 해설이 펼쳐진다. 답에 나오는 값은 모두 실행해서 확인했다.

### 단답형 (Short Answer)

**Q1.** `push 3` / `push 2` / `push 1` / `call P`로 부른 프로시저 `P`가 `push ebp` / `mov ebp,esp` / `sub esp,8`로 시작한다. (a) 세 번째 인수(3)는 어디에 있는가? (b) 복귀 주소는? (c) 두 번째 DWORD 지역 변수는? (d) 이 시점의 ESP는 EBP와 어떤 관계인가?

<details>
<summary>정답 보기</summary>

(a) `[ebp+16]` (b) `[ebp+4]` (c) `[ebp-8]` (d) ESP = EBP − 8

```asm
; Q1 확인
INCLUDE Irvine32.inc

.code
main PROC
    push 3
    push 2
    push 1
    call P
    exit
main ENDP

P PROC
    push ebp
    mov  ebp,esp
    sub  esp,8              ; [ebp+8] = 1, [ebp+12] = 2, [ebp+16] = 3, ESP = EBP-8
    mov  esp,ebp
    pop  ebp
    ret  12
P ENDP
END main
```

첫 번째 인수가 `[ebp+8]`이고 인수마다 4씩 늘어나므로 세 번째는 8 + 4 × 2 = 16이다. 지역 변수는 EBP 아래로 `[ebp-4]`, `[ebp-8]` 순서다.

</details>

**Q2.** 다음 코드를 실행한 뒤 ESP는 EBX와 어떤 관계인가? (`Sum3_Std`는 `ret 12`로, `Sum3_C`는 `ret`으로 끝난다.)

```asm
mov  ebx,esp
push 3
push 2
push 1
call Sum3_Std
push 3
push 2
push 1
call Sum3_C
```

<details>
<summary>정답 보기</summary>

첫 호출 뒤에는 ESP = EBX(호출된 쪽이 치웠다), 두 번째 호출 뒤에는 ESP = EBX − 12(인수 12바이트가 남아 있다)다. 두 번째 호출 다음에 `add esp,12`가 있어야 한다.

```asm
; Q2 확인
INCLUDE Irvine32.inc

.code
main PROC
    mov  ebx,esp
    push 3
    push 2
    push 1
    call Sum3_Std           ; EAX = 6, ESP = EBX
    push 3
    push 2
    push 1
    call Sum3_C             ; EAX = 6, ESP = EBX-12
    add  esp,12             ; ESP = EBX
    exit
main ENDP

Sum3_Std PROC
    push ebp
    mov  ebp,esp
    mov  eax,[ebp+8]
    add  eax,[ebp+12]
    add  eax,[ebp+16]
    pop  ebp
    ret  12
Sum3_Std ENDP

Sum3_C PROC
    push ebp
    mov  ebp,esp
    mov  eax,[ebp+8]
    add  eax,[ebp+12]
    add  eax,[ebp+16]
    pop  ebp
    ret
Sum3_C ENDP
END main
```

</details>

**Q3.** `ret 8`이 실행될 때 일어나는 일을 순서대로 쓰라. 실행 직전 ESP가 X였다면 실행 직후 ESP는?

<details>
<summary>정답 보기</summary>

1. 스택 맨 위(`[esp]`)의 4바이트를 꺼내 EIP에 넣는다(ESP += 4).
2. ESP에 8을 더한다.

따라서 직후의 ESP는 X + 12다. 복귀 주소 4바이트와 인수 8바이트가 함께 치워진다.

```asm
; Q3 확인
INCLUDE Irvine32.inc

.code
main PROC
    push 2
    push 1
    call Two                ; 돌아온 뒤: ESP = EBX+12
    exit
main ENDP

Two PROC
    mov  ebx,esp            ; ret 8 직전의 ESP (프레임을 만들지 않았다)
    ret  8
Two ENDP
END main
```

</details>

**Q4.** 다음 프로그램에서 두 호출이 끝난 뒤 `val`의 값은 각각 얼마인가?

```asm
.data
val DWORD 5
.code
push val
call IncByValue             ; [esp+4]의 값에 1을 더하고 ret 4
push OFFSET val
call IncByRef               ; [esp+4]가 가리키는 곳에 1을 더하고 ret 4
```

<details>
<summary>정답 보기</summary>

첫 호출 뒤에도 `val`은 5이고, 두 번째 호출 뒤에 6이 된다. `IncByValue`는 스택에 복사된 값만 바꾸고, `IncByRef`는 주소를 따라가 `val` 자체를 바꾼다.

```asm
; Q4 확인
INCLUDE Irvine32.inc

.data
val DWORD 5

.code
main PROC
    push val
    call IncByValue         ; val = 5
    push OFFSET val
    call IncByRef           ; val = 6
    exit
main ENDP

IncByValue PROC
    inc  DWORD PTR [esp+4]  ; 스택의 복사본을 바꾼다
    ret  4
IncByValue ENDP

IncByRef PROC
    mov  eax,[esp+4]        ; 주소를 꺼내
    inc  DWORD PTR [eax]    ; 그 주소의 값을 바꾼다
    ret  4
IncByRef ENDP
END main
```

</details>

**Q5.** `[ebp-8]`에 1234h가 들어 있을 때 다음 두 명령어를 실행하면 EAX는?
(a) `lea eax,[ebp-8]` (b) `mov eax,[ebp-8]`

<details>
<summary>정답 보기</summary>

(a) EAX = EBP − 8 (주소) (b) EAX = 1234h (그 주소의 내용)

```asm
; Q5 확인
INCLUDE Irvine32.inc

.code
main PROC
    call P
    exit
main ENDP

P PROC
    push ebp
    mov  ebp,esp
    sub  esp,8
    mov  DWORD PTR [ebp-8],1234h
    lea  eax,[ebp-8]        ; EAX = EBP-8
    mov  eax,[ebp-8]        ; EAX = 1234h
    mov  esp,ebp
    pop  ebp
    ret
P ENDP
END main
```

</details>

**Q6.** `enter 12,0`과 같은 일을 하는 명령어 세 개를 쓰라. 실행 직후 ESP와 EBP의 관계는? 짝이 되는 명령어는?

<details>
<summary>정답 보기</summary>

`push ebp` / `mov ebp,esp` / `sub esp,12`. 실행 직후 ESP = EBP − 12이고, 짝이 되는 명령어는 `leave`(= `mov esp,ebp` / `pop ebp`)다.

```asm
; Q6 확인
INCLUDE Irvine32.inc

.code
main PROC
    call P
    exit
main ENDP

P PROC
    mov  ebx,esp
    enter 12,0              ; ESP = EBP-12, EBP = EBX-4
    leave                   ; ESP = EBX
    ret
P ENDP
END main
```

</details>

**Q7.** `LOCAL x:BYTE, y:DWORD, z:WORD`로 선언한 세 변수는 각각 어디에 놓이고, ESP는 얼마나 내려가는가?

<details>
<summary>정답 보기</summary>

`x`는 `[ebp-1]`, `y`는 4의 배수 위치인 `[ebp-8]`, `z`는 `[ebp-10]`이다. 사용하는 바이트는 10이지만 4의 배수로 올려 ESP를 12 내린다.

```asm
; Q7 확인
INCLUDE Irvine32.inc

.code
main PROC
    call P
    exit
main ENDP

P PROC
    LOCAL x:BYTE, y:DWORD, z:WORD
    mov  x,1                ; ESP = EBP-12, BYTE PTR [ebp-1] = 1
    mov  y,2                ; [ebp-8] = 2
    mov  z,3                ; WORD PTR [ebp-10] = 3
    ret
P ENDP
END main
```

`DWORD`를 먼저 선언하면(`LOCAL y:DWORD, z:WORD, x:BYTE`) `y`는 `[ebp-4]`, `z`는 `[ebp-6]`, `x`는 `[ebp-7]`이 되어 8바이트로 충분하다.

변수 이름으로 `a`, `b`는 쓸 수 있지만 `c`는 쓸 수 없다. `C`는 호출 규약을 나타내는 예약어(`PROTO C`, `PROC C`)이기 때문이다.

</details>

**Q8.** 8.3절의 `CalcSum`을 ECX = 3, EAX = 0으로 부르면 `CalcSum`은 모두 몇 번 호출되는가? 가장 깊은 곳에서 스택에 쌓인 복귀 주소는 몇 개인가? 결과 EAX는?

<details>
<summary>정답 보기</summary>

ECX = 3, 2, 1, 0일 때 한 번씩 모두 4번 호출된다. 가장 깊은 곳(ECX = 0)에는 복귀 주소 4개(16바이트)가 쌓여 있고, 결과는 EAX = 6(3 + 2 + 1)이다.

```asm
; Q8 확인
INCLUDE Irvine32.inc

.code
main PROC
    mov  ebx,esp
    mov  ecx,3
    mov  eax,0
    call CalcSum            ; EAX = 6, ESP = EBX
    exit
main ENDP

CalcSum PROC
    cmp  ecx,0              ; ECX = 3 → 2 → 1 → 0 차례로
    jz   L2
    add  eax,ecx
    dec  ecx
    call CalcSum
L2: ret                     ; 가장 깊은 곳에서 처음 실행된다: ESP = EBX-12
CalcSum ENDP
END main
```

`L2: ret`이 처음 실행된 직후의 ESP는 복귀 주소 하나를 꺼낸 뒤이므로 EBX − 12다(실행 직전에는 EBX − 16).

</details>

**Q9.** 8.3절의 `Factorial`로 4!을 구할 때, 가장 깊은 곳에서 스택은 호출 전보다 몇 바이트 더 쓰이는가?

<details>
<summary>정답 보기</summary>

n = 4, 3, 2, 1, 0의 다섯 프레임이 각각 12바이트(n, 복귀 주소, 저장된 EBP)이므로 60바이트다.

```asm
; Q9 확인
INCLUDE Irvine32.inc

.code
main PROC
    mov  esi,esp
    push 4
    call Factorial          ; EAX = 24
    exit
main ENDP

Factorial PROC
    push ebp
    mov  ebp,esp
    mov  eax,[ebp+8]
    cmp  eax,0
    ja   L1
    mov  eax,1              ; 가장 깊은 곳: ESP = ESI-60
    jmp  L2
L1: dec  eax
    push eax
    call Factorial
    mov  ebx,[ebp+8]
    mul  ebx
L2: pop  ebp
    ret  4
Factorial ENDP
END main
```

</details>

**Q10.** 다음 두 `INVOKE`가 만드는 코드는 어떻게 다른가?

```text
AddThree   PROTO, x:DWORD, y:DWORD, z:DWORD
AddThree_C PROTO C, x:DWORD, y:DWORD, z:DWORD

INVOKE AddThree, 1, 2, 3
INVOKE AddThree_C, 1, 2, 3
```

<details>
<summary>정답 보기</summary>

둘 다 `push 3` / `push 2` / `push 1` / `call`을 만든다. C 규약인 두 번째에는 `call` 다음에 `add esp,12`가 더 붙는다. 대신 `AddThree`의 `ret`은 어셈블러가 `ret 12`로, `AddThree_C`의 `ret`은 그냥 `ret`으로 만든다. 어느 쪽이든 호출이 끝나면 ESP는 원래대로 돌아온다.

```asm
; Q10 확인
INCLUDE Irvine32.inc

AddThree   PROTO, x:DWORD, y:DWORD, z:DWORD
AddThree_C PROTO C, x:DWORD, y:DWORD, z:DWORD

.code
main PROC
    mov  ebx,esp
    INVOKE AddThree, 1, 2, 3        ; EAX = 6, ESP = EBX
    INVOKE AddThree_C, 1, 2, 3      ; EAX = 6, ESP = EBX
    exit
main ENDP

AddThree PROC, x:DWORD, y:DWORD, z:DWORD
    mov  eax,x
    add  eax,y
    add  eax,z
    ret
AddThree ENDP

AddThree_C PROC C, x:DWORD, y:DWORD, z:DWORD
    mov  eax,x
    add  eax,y
    add  eax,z
    ret
AddThree_C ENDP
END main
```

</details>

**Q11.** `Combine PROC, x:DWORD, y:DWORD, z:DWORD`를 다른 모듈에서 `EXTERN`으로 부르려면 어떻게 선언해야 하는가? 오브젝트 파일에 실제로 기록되는 이름은?

<details>
<summary>정답 보기</summary>

`EXTERN Combine@12:PROC`. 매개변수 세 개가 12바이트이므로 `@12`가 붙고, 오브젝트 파일에는 앞에 밑줄이 붙은 `_Combine@12`로 기록된다. `PROTO`로 선언하면(`Combine PROTO, x:DWORD, y:DWORD, z:DWORD`) 이름 장식을 어셈블러가 해 주므로 `INVOKE Combine, …`으로 부를 수 있다.

</details>

**Q12.** 다음 프로시저에서 `p`, `t`, 저장된 ESI, 저장된 EDI는 각각 EBP 기준으로 어디에 있는가?

```text
Proc1 PROC USES esi edi, p:DWORD
    LOCAL t:DWORD
```

<details>
<summary>정답 보기</summary>

`p`는 `[ebp+8]`, `t`는 `[ebp-4]`, 저장된 ESI는 `[ebp-8]`, 저장된 EDI는 `[ebp-12]`다. 어셈블러는 프레임(`push ebp` / `mov ebp,esp` / `sub esp,4`)을 먼저 만들고 그다음에 `USES` 레지스터를 저장한다.

```asm
; Q12 확인
INCLUDE Irvine32.inc

Proc1 PROTO, p:DWORD

.code
main PROC
    mov  esi,5151h
    mov  edi,0D1D1h
    INVOKE Proc1, 77h
    exit
main ENDP

Proc1 PROC USES esi edi, p:DWORD
    LOCAL t:DWORD
    mov  t,0AAh             ; [ebp+8] = 77h, [ebp-4] = 0AAh, [ebp-8] = 5151h, [ebp-12] = 0D1D1h
    ret
Proc1 ENDP
END main
```

</details>

**Q13.** 다음 프로그램의 `SumTwo`는 EAX로 합을 돌려주려 했지만, 호출한 쪽은 항상 엉뚱한 값을 받는다. 왜 그런가?

```asm
; Q13: 반환값이 사라지는 프로시저
INCLUDE Irvine32.inc

SumTwo PROTO, a:DWORD, b:DWORD

.code
main PROC
    mov  eax,99
    INVOKE SumTwo, 3, 4     ; 호출한 쪽이 받는 값: EAX = 99
    exit
main ENDP

SumTwo PROC USES eax, a:DWORD, b:DWORD
    mov  eax,a
    add  eax,b              ; 여기서는 EAX = 7
    ret
SumTwo ENDP
END main
```

<details>
<summary>정답 보기</summary>

`USES eax` 때문에 어셈블러가 `ret` 앞에 `pop eax`를 넣는다. 그래서 합 7이 프로시저에 들어올 때 저장한 원래 값(99)으로 덮어쓰인다. 반환값을 담는 EAX는 `USES`에 넣으면 안 된다.

</details>

**Q14.** `ret 8`로 끝나는 STDCALL 프로시저를 부른 뒤 C 규약처럼 `add esp,8`도 했다. ESP는 어떻게 되는가?

<details>
<summary>정답 보기</summary>

인수를 두 번 치웠으므로 ESP가 호출 전보다 8 **높아진다**. 호출한 쪽이 스택에 저장해 둔 값(복귀 주소나 저장된 레지스터)을 건너뛰게 되어, 그 프로시저가 돌아갈 때 엉뚱한 곳으로 간다.

```asm
; Q14 확인
INCLUDE Irvine32.inc

.code
main PROC
    mov  ebx,esp
    push 6
    push 5
    call AddTwoStd          ; ESP = EBX
    add  esp,8              ; 한 번 더 치우면: ESP = EBX+8
    sub  esp,8              ; (확인을 위해 되돌린다)
    exit
main ENDP

AddTwoStd PROC
    push ebp
    mov  ebp,esp
    mov  eax,[ebp+12]
    add  eax,[ebp+8]
    pop  ebp
    ret  8
AddTwoStd ENDP
END main
```

</details>

**Q15.** Microsoft x64 호출 규약으로 정수 인수 6개를 받는 함수를 부른다. 호출하기 직전(`call` 실행 전) RSP를 기준으로 다섯 번째와 여섯 번째 인수는 어디에 두어야 하는가? 호출된 함수에 들어간 직후에는 RSP 기준으로 어디에 있는가?

<details>
<summary>정답 보기</summary>

호출 직전에는 섀도 공간 32바이트(`[rsp]`~`[rsp+1Fh]`) 바로 위인 `[rsp+20h]`(다섯 번째), `[rsp+28h]`(여섯 번째)에 둔다. `CALL`이 복귀 주소 8바이트를 넣으므로, 호출된 함수 안에서는 각각 `[rsp+28h]`, `[rsp+30h]`이 된다. 처음 네 인수는 RCX, RDX, R8, R9로 넘어간다. (8.2절의 x64 예제와 같은 방법으로, C 프로그램에서 부른 64비트 함수로 확인했다.)

</details>

### 알고리즘 작성 (Algorithm Workbench)

**W1.** 스택으로 받은 부호 있는 정수 두 개 중 작은 값을 EAX로 돌려주는 STDCALL 프로시저 `MinOfTwo`를 **명시적 스택 매개변수**(`[ebp+8]`, `[ebp+12]`)로 작성하라.

<details>
<summary>정답 보기</summary>

```asm
; W1: 명시적 스택 매개변수로 작은 값 구하기
INCLUDE Irvine32.inc

.code
main PROC
    push -3                 ; 두 번째 인수
    push 10                 ; 첫 번째 인수
    call MinOfTwo           ; EAX = -3
    push 7
    push 7
    call MinOfTwo           ; EAX = 7
    exit
main ENDP

MinOfTwo PROC
    push ebp
    mov  ebp,esp
    mov  eax,[ebp+8]        ; 첫 번째 인수
    cmp  eax,[ebp+12]
    jle  L1                 ; 부호 있는 비교: 이미 작거나 같으면 그대로
    mov  eax,[ebp+12]
L1: pop  ebp
    ret  8
MinOfTwo ENDP
END main
```

부호 있는 값이므로 `JLE`를 썼다. 부호 없는 값이라면 `JBE`를 쓴다.

</details>

**W2.** [디버깅 팁](#잘못된-타입의-포인터-passing-the-wrong-type-of-pointer)의 문제를 고쳐, 두 **바이트**를 맞바꾸는 `SwapBytes PROC, p1:PTR BYTE, p2:PTR BYTE`를 작성하라.

<details>
<summary>정답 보기</summary>

```asm
; W2: 바이트 두 개 교환
INCLUDE Irvine32.inc

SwapBytes PROTO, p1:PTR BYTE, p2:PTR BYTE

.data
ByteArray BYTE 10h,20h,30h,40h

.code
main PROC
    INVOKE SwapBytes, ADDR [ByteArray + 0], ADDR [ByteArray + 1]
    mov  eax,DWORD PTR ByteArray    ; EAX = 40301020h
    exit
main ENDP

SwapBytes PROC USES eax esi edi, p1:PTR BYTE, p2:PTR BYTE
    mov  esi,p1
    mov  edi,p2
    mov  al,[esi]           ; 바이트 단위로 읽고
    xchg al,[edi]           ; 바이트 단위로 바꾼다
    mov  [esi],al
    ret
SwapBytes ENDP
END main
```

`AL`처럼 8비트 레지스터를 쓰면 `XCHG`와 `MOV`가 1바이트씩 동작하므로 이웃한 바이트를 건드리지 않는다. 배열은 `20 10 30 40`이 되어 DWORD로 읽으면 `40301020h`다.

</details>

**W3.** `LOCAL`로 DWORD 10개짜리 지역 배열을 만들고, 원소 i에 i²을 넣은 다음, 원소의 합을 EAX로 돌려주는 프로시저 `SumSquares`를 작성하라.

<details>
<summary>정답 보기</summary>

```asm
; W3: 지역 배열 다루기
INCLUDE Irvine32.inc

.code
main PROC
    call SumSquares         ; EAX = 285
    exit
main ENDP

SumSquares PROC USES ecx esi
    LOCAL squares[10]:DWORD
    lea  esi,squares        ; 지역 배열의 주소는 LEA로 구한다
    mov  ecx,0
L1: mov  eax,ecx
    imul eax,ecx            ; i * i
    mov  [esi+ecx*4],eax
    inc  ecx
    cmp  ecx,10
    jb   L1
    mov  eax,0              ; 합 구하기
    mov  ecx,0
L2: add  eax,[esi+ecx*4]
    inc  ecx
    cmp  ecx,10
    jb   L2
    ret
SumSquares ENDP
END main
```

0 + 1 + 4 + … + 81 = 285다. 지역 배열의 주소는 실행 중에 정해지므로 `OFFSET squares`가 아니라 `lea esi,squares`로 구한다.

</details>

**W4.** baseᵉˣᵖ을 재귀로 계산하는 `Power PROC, base:DWORD, exp:DWORD`를 작성하라(exp = 0이면 1). 2¹⁰과 3⁵로 시험하라.

<details>
<summary>정답 보기</summary>

```asm
; W4: 재귀로 거듭제곱 구하기
INCLUDE Irvine32.inc

Power PROTO, base:DWORD, exp:DWORD

.code
main PROC
    INVOKE Power, 2, 10     ; EAX = 1024
    INVOKE Power, 3, 5      ; EAX = 243
    exit
main ENDP

Power PROC USES ebx edx, base:DWORD, exp:DWORD
    mov  eax,1              ; 기저 사례: base^0 = 1
    mov  ebx,exp
    cmp  ebx,0
    je   Done
    dec  ebx
    INVOKE Power, base, ebx ; EAX = base^(exp-1)
    mul  base               ; EAX = base^exp
Done:
    ret
Power ENDP
END main
```

재귀 호출에 넘길 `exp - 1`은 EBX로 계산해 넘겼다. `MUL`이 EDX를 바꾸므로 `USES`에 EDX를 넣었다.

</details>

**W5.** 부호 없는 정수의 각 자리 숫자의 합을 재귀로 구하는 `SumDigits`를 작성하라(EAX로 받아 EAX로 돌려준다). 예: 98765 → 35.

<details>
<summary>정답 보기</summary>

```asm
; W5: 자릿수 합을 재귀로
INCLUDE Irvine32.inc

.code
main PROC
    mov  eax,98765
    call SumDigits          ; EAX = 35
    mov  eax,7
    call SumDigits          ; EAX = 7
    exit
main ENDP

;-----------------------------------------------------
SumDigits PROC USES ebx edx
; Receives: EAX (부호 없는 정수)
; Returns:  EAX에 각 자리 숫자의 합
;-----------------------------------------------------
    cmp  eax,10
    jb   Done               ; 한 자리이면 그 자체가 답
    mov  edx,0
    mov  ebx,10
    div  ebx                ; EAX = n / 10, EDX = n % 10
    push edx                ; 마지막 자리를 스택에 보관
    call SumDigits          ; EAX = (n / 10)의 자릿수 합
    pop  edx
    add  eax,edx
Done:
    ret
SumDigits ENDP
END main
```

마지막 자리(나머지)를 `push edx`로 스택에 맡겨 두었다가, 재귀 호출이 돌아온 뒤 꺼내 더한다. `Factorial`이 n을 `[ebp+8]`에 남겨 둔 것과 같은 방법이다.

</details>

**W6.** 첫 인수로 받은 개수만큼의 부호 있는 정수 중 최댓값을 돌려주는 C 규약 가변 인수 프로시저 `MaxOf PROTO C, count:DWORD, args:VARARG`를 작성하라.

<details>
<summary>정답 보기</summary>

```asm
; W6: 가변 인수 최댓값
INCLUDE Irvine32.inc

MaxOf PROTO C, count:DWORD, args:VARARG

.code
main PROC
    mov  ebx,esp
    INVOKE MaxOf, 4, 12, -5, 40, 7      ; EAX = 40, ESP = EBX
    INVOKE MaxOf, 2, -8, -3             ; EAX = -3, ESP = EBX
    exit
main ENDP

MaxOf PROC C USES ecx esi, count:DWORD, args:VARARG
    lea  esi,args
    mov  ecx,count
    mov  eax,[esi]          ; 첫 값을 최댓값으로 시작한다
    dec  ecx
    jz   Done
L1: add  esi,4
    cmp  [esi],eax
    jle  L2
    mov  eax,[esi]
L2: loop L1
Done:
    ret
MaxOf ENDP
END main
```

인수를 치우는 일은 `INVOKE`가 붙인 `add esp,20`과 `add esp,12`가 한다.

</details>

---

## 부록 F. 프로그래밍 연습 (풀이 포함)

교재 8.11절 Programming Exercises와 같은 유형의 문제를 이 장에서 배운 방법으로 풀어 본다. 먼저 직접 풀어 본 다음 **풀이 보기**를 펼쳐 비교해 보자. 모든 풀이는 그대로 붙여 넣어 실행할 수 있는 완전한 프로그램(Irvine32 사용)이고, 실행 결과를 확인했다.

### 연습 1. 스택 매개변수로 배열의 합 구하기

부호 있는 DWORD 배열의 주소와 원소 개수를 **스택**으로 받아 합을 EAX로 돌려주는 STDCALL 프로시저 `ArraySum`을 작성하라. `PROC`의 매개변수 목록을 쓰지 말고 `[ebp+8]`, `[ebp+12]`로 인수를 읽어라. 원소가 0개인 경우도 시험하라.

<details>
<summary>풀이 보기</summary>

```asm
; 연습 1: 스택 매개변수로 배열의 합 구하기
INCLUDE Irvine32.inc

.data
array1 SDWORD 10, -20, 30, -40, 50
array2 SDWORD 1000, 2000, 3000
msgSum BYTE "Sum = ",0

.code
main PROC
    push LENGTHOF array1
    push OFFSET array1
    call ArraySum           ; EAX = 30
    call ShowSum
    push LENGTHOF array2
    push OFFSET array2
    call ArraySum           ; EAX = 6000
    call ShowSum
    push 0                  ; 원소 0개
    push OFFSET array2
    call ArraySum           ; EAX = 0
    call ShowSum
    exit
main ENDP

;---------------------------------------------------
ArraySum PROC
; 배열의 합을 구한다 (STDCALL).
; Receives: [ebp+8]에 배열의 주소, [ebp+12]에 원소 개수
; Returns:  EAX에 합
;---------------------------------------------------
    push ebp
    mov  ebp,esp
    push ecx                ; 레지스터는 mov ebp,esp 다음에 저장한다
    push esi
    mov  eax,0
    mov  esi,[ebp+8]
    mov  ecx,[ebp+12]
    jecxz L2                ; 원소가 없으면 0
L1: add  eax,[esi]
    add  esi,4
    loop L1
L2: pop  esi
    pop  ecx
    pop  ebp
    ret  8                  ; 인수 두 개를 치운다
ArraySum ENDP

ShowSum PROC                ; EAX를 "Sum = n" 꼴로 출력한다
    push edx
    mov  edx,OFFSET msgSum
    call WriteString
    call WriteInt
    call Crlf
    pop  edx
    ret
ShowSum ENDP
END main
```

실행 결과:

```text
Sum = +30
Sum = +6000
Sum = +0
```

인수를 오른쪽(개수)부터 넣었으므로 첫 번째 인수인 주소가 `[ebp+8]`에 온다. 반환값을 EAX로 돌려주므로 EAX는 저장·복원하지 않았다.

</details>

### 연습 2. 반복과 재귀 팩토리얼 (넘침 검사)

n!을 구하는 프로시저를 반복문 버전(`FactIter`)과 재귀 버전(`FactRec`)으로 작성하라. 결과가 32비트를 넘으면 CF = 1로 알려야 한다. n = 10~13에 대해 두 버전의 결과를 나란히 출력하고, 넘치면 `overflow`라고 출력하라.

<details>
<summary>풀이 보기</summary>

```asm
; 연습 2: 반복과 재귀 팩토리얼 (넘침 검사)
INCLUDE Irvine32.inc

.data
msgFact BYTE "! = ",0
msgIter BYTE " (iterative), ",0
msgRec  BYTE " (recursive)",0
msgOvf  BYTE "overflow",0

.code
main PROC
    mov  ebx,10                 ; n = 10부터
L1: mov  eax,ebx
    call WriteDec
    mov  edx,OFFSET msgFact
    call WriteString
    mov  ecx,ebx
    call FactIter               ; EAX = n!, CF = 넘침 여부
    call ShowResult
    mov  edx,OFFSET msgIter
    call WriteString
    push ebx
    call FactRec
    call ShowResult
    mov  edx,OFFSET msgRec
    call WriteString
    call Crlf
    inc  ebx
    cmp  ebx,13
    jbe  L1
    exit
main ENDP

ShowResult PROC                 ; CF = 1이면 "overflow", 아니면 EAX를 출력한다
    push edx
    jnc  S1
    mov  edx,OFFSET msgOvf
    call WriteString
    jmp  S2
S1: call WriteDec
S2: pop  edx
    ret
ShowResult ENDP

;---------------------------------------------------
FactIter PROC USES ecx edx
; Receives: ECX에 n
; Returns:  EAX에 n!, 32비트를 넘으면 CF에 1
;---------------------------------------------------
    mov  eax,1
    clc                         ; n = 0이면 넘침 없음
    jecxz F2
F1: mul  ecx                    ; EDX:EAX = EAX * ECX
    jc   F2                     ; 상위 절반이 0이 아니면 넘침
    loop F1                     ; LOOP는 플래그를 바꾸지 않는다
F2: ret
FactIter ENDP

;---------------------------------------------------
FactRec PROC
; Receives: [ebp+8]에 n
; Returns:  EAX에 n!, 32비트를 넘으면 CF에 1
;---------------------------------------------------
    push ebp
    mov  ebp,esp
    push ebx
    push edx
    mov  eax,[ebp+8]
    cmp  eax,0
    ja   R1
    mov  eax,1                  ; 0! = 1
    clc
    jmp  R2
R1: dec  eax
    push eax
    call FactRec                ; EAX = (n-1)!
    jc   R2                     ; 이미 넘쳤으면 그대로 돌려준다
    mov  ebx,[ebp+8]
    mul  ebx                    ; CF = 1이면 넘침
R2: pop  edx                    ; POP과 RET은 플래그를 바꾸지 않는다
    pop  ebx
    pop  ebp
    ret  4
FactRec ENDP
END main
```

실행 결과:

```text
10! = 3628800 (iterative), 3628800 (recursive)
11! = 39916800 (iterative), 39916800 (recursive)
12! = 479001600 (iterative), 479001600 (recursive)
13! = overflow (iterative), overflow (recursive)
```

재귀 버전에서 한 단계라도 넘치면 그 뒤의 곱셈은 잘린 값으로 계산되므로 의미가 없다. 그래서 돌아온 직후 `jc`로 검사해 넘침을 바깥 호출까지 그대로 전달했다. CF가 `POP`과 `RET`을 거쳐도 유지된다는 점을 이용한 것이다.

</details>

### 연습 3. 재귀로 최대공약수 구하기

유클리드 호제법 gcd(a, b) = gcd(b, a mod b), gcd(a, 0) = a를 재귀 프로시저 `GCD PROC, a:DWORD, b:DWORD`로 구현하라. 몇 쌍의 수로 시험하라.

<details>
<summary>풀이 보기</summary>

```asm
; 연습 3: 재귀로 최대공약수 구하기
INCLUDE Irvine32.inc

GCD PROTO, a:DWORD, b:DWORD

.data
pairs  DWORD 48,18, 1071,462, 17,5, 0,9, 100,0
msgGcd BYTE "gcd(",0
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
    INVOKE GCD, [esi], [esi+4]
    call WriteDec
    call Crlf
    add  esi,8
    loop L1
    exit
main ENDP

GCD PROC USES ebx edx, a:DWORD, b:DWORD
    mov  eax,a
    mov  ebx,b
    cmp  ebx,0
    je   Done               ; gcd(a, 0) = a
    mov  edx,0
    div  ebx                ; EDX = a mod b
    INVOKE GCD, ebx, edx    ; gcd(b, a mod b)
Done:
    ret
GCD ENDP
END main
```

실행 결과:

```text
gcd(48, 18) = 6
gcd(1071, 462) = 21
gcd(17, 5) = 1
gcd(0, 9) = 9
gcd(100, 0) = 100
```

재귀 호출이 프로시저의 마지막 동작(꼬리 재귀)이므로, `INVOKE GCD` 대신 a와 b를 바꿔 넣고 처음으로 점프하는 루프로 바꿀 수도 있다. `USES ebx edx` 덕분에 재귀 호출이 EBX·EDX를 바꿔도 호출한 쪽의 값은 지켜진다.

</details>

### 연습 4. 하노이의 탑

원반 n개를 기둥 A에서 C로 옮기는 순서를 출력하는 재귀 프로시저 `Hanoi`를 작성하라. 한 번에 원반 하나만 옮길 수 있고, 큰 원반을 작은 원반 위에 놓을 수 없다. n = 3일 때의 이동 순서와 총 이동 횟수를 출력하라.

<details>
<summary>풀이 보기</summary>

n개를 옮기려면 (1) 위의 n−1개를 보조 기둥으로 옮기고, (2) 가장 큰 원반을 목표 기둥으로 옮긴 다음, (3) n−1개를 다시 목표 기둥으로 옮긴다. (1)과 (3)이 같은 문제의 작은 버전이다.

```asm
; 연습 4: 하노이의 탑
INCLUDE Irvine32.inc

Hanoi PROTO, n:DWORD, fromPeg:DWORD, toPeg:DWORD, viaPeg:DWORD

.data
moves    DWORD 0
msgMove  BYTE "Move disk ",0
msgFrom  BYTE " from ",0
msgTo    BYTE " to ",0
msgTotal BYTE "Total moves: ",0

.code
main PROC
    INVOKE Hanoi, 3, 'A', 'C', 'B'
    mov  edx,OFFSET msgTotal
    call WriteString
    mov  eax,moves          ; EAX = 7
    call WriteDec
    call Crlf
    exit
main ENDP

Hanoi PROC USES eax edx, n:DWORD, fromPeg:DWORD, toPeg:DWORD, viaPeg:DWORD
    mov  eax,n
    cmp  eax,0
    je   Done               ; 옮길 원반이 없다
    dec  eax
    INVOKE Hanoi, eax, fromPeg, viaPeg, toPeg   ; (1) n-1개를 보조 기둥으로
    inc  moves                                  ; (2) 가장 큰 원반을 옮긴다
    mov  edx,OFFSET msgMove
    call WriteString
    mov  eax,n
    call WriteDec
    mov  edx,OFFSET msgFrom
    call WriteString
    mov  eax,fromPeg
    call WriteChar
    mov  edx,OFFSET msgTo
    call WriteString
    mov  eax,toPeg
    call WriteChar
    call Crlf
    mov  eax,n
    dec  eax
    INVOKE Hanoi, eax, viaPeg, toPeg, fromPeg   ; (3) n-1개를 목표 기둥으로
Done:
    ret
Hanoi ENDP
END main
```

실행 결과:

```text
Move disk 1 from A to C
Move disk 2 from A to B
Move disk 1 from C to B
Move disk 3 from A to C
Move disk 1 from B to A
Move disk 2 from B to C
Move disk 1 from A to C
Total moves: 7
```

원반 n개의 이동 횟수는 2ⁿ − 1이다. 재귀의 깊이는 n + 1이지만 호출 횟수는 2ⁿ⁺¹ − 1로 빠르게 늘어난다. 기둥 이름은 문자를 DWORD 매개변수로 넘겼다. 32비트 인수로 넘기면 `INVOKE`가 EAX를 쓰지 않고 바로 `push`하므로, 첫 인수로 넘긴 EAX가 망가질 걱정도 없다.

</details>

### 연습 5. 재귀 이진 탐색

오름차순으로 정렬된 부호 있는 정수 배열에서 키를 찾는 재귀 프로시저 `BinSearch PROC, pArray:PTR SDWORD, loIdx:SDWORD, hiIdx:SDWORD, key:SDWORD`를 작성하라. 찾으면 인덱스를, 없으면 −1을 EAX로 돌려준다.

<details>
<summary>풀이 보기</summary>

```asm
; 연습 5: 재귀 이진 탐색
INCLUDE Irvine32.inc

BinSearch PROTO, pArray:PTR SDWORD, loIdx:SDWORD, hiIdx:SDWORD, key:SDWORD

.data
sorted   SDWORD 2, 5, 8, 12, 16, 23, 38, 56, 72, 91
keys     SDWORD 23, 2, 91, 7, 100
msgIndex BYTE ": index ",0
msgNone  BYTE ": not found",0

.code
main PROC
    mov  esi,OFFSET keys
    mov  ecx,LENGTHOF keys
L1: mov  eax,[esi]
    call WriteDec
    INVOKE BinSearch, ADDR sorted, 0, LENGTHOF sorted - 1, [esi]
    cmp  eax,-1
    je   L2
    mov  edx,OFFSET msgIndex
    call WriteString
    call WriteDec
    jmp  L3
L2: mov  edx,OFFSET msgNone
    call WriteString
L3: call Crlf
    add  esi,4
    loop L1
    exit
main ENDP

BinSearch PROC USES ebx esi, pArray:PTR SDWORD, loIdx:SDWORD, hiIdx:SDWORD, key:SDWORD
    mov  eax,loIdx
    cmp  eax,hiIdx
    jg   NotFound           ; 범위가 비었다
    add  eax,hiIdx
    sar  eax,1              ; mid = (lo + hi) / 2
    mov  esi,pArray
    mov  ebx,[esi+eax*4]    ; arr[mid]
    cmp  ebx,key
    je   Done               ; 찾았다: EAX = mid
    jl   GoRight
    dec  eax                ; arr[mid] > key: 왼쪽 반에서 찾는다
    INVOKE BinSearch, pArray, loIdx, eax, key
    jmp  Done
GoRight:
    inc  eax                ; arr[mid] < key: 오른쪽 반에서 찾는다
    INVOKE BinSearch, pArray, eax, hiIdx, key
    jmp  Done
NotFound:
    mov  eax,-1
Done:
    ret
BinSearch ENDP
END main
```

실행 결과:

```text
23: index 5
2: index 0
91: index 9
7: not found
100: not found
```

호출할 때마다 범위가 절반으로 줄어들므로, 원소가 n개이면 재귀의 깊이는 약 log₂n이다. 원소가 백만 개라도 깊이가 20 정도에 그치므로 스택을 걱정할 필요가 없다. 이것도 꼬리 재귀이므로 반복문으로 쉽게 바꿀 수 있다.

</details>

### 연습 6. 지역 버퍼로 문자열 뒤집기

널로 끝나는 문자열의 주소를 받아 그 문자열을 뒤집는 프로시저 `ReverseString PROC, pStr:PTR BYTE`를 작성하라. `LOCAL`로 64바이트 지역 버퍼를 만들어, 거꾸로 복사했다가 다시 원래 자리로 복사하라. 빈 문자열도 시험하라.

<details>
<summary>풀이 보기</summary>

```asm
; 연습 6: 지역 버퍼로 문자열 뒤집기
INCLUDE Irvine32.inc

ReverseString PROTO, pStr:PTR BYTE

.data
str1 BYTE "Hello, World",0
str2 BYTE "Assembly",0
str3 BYTE "a",0
str4 BYTE 0
strTable DWORD str1, str2, str3, str4

.code
main PROC
    mov  esi,OFFSET strTable
    mov  ecx,LENGTHOF strTable
L1: mov  edx,[esi]
    INVOKE ReverseString, edx
    mov  al,'['
    call WriteChar
    call WriteString        ; EDX가 가리키는 (뒤집힌) 문자열
    mov  al,']'
    call WriteChar
    call Crlf
    add  esi,4
    loop L1
    exit
main ENDP

ReverseString PROC USES eax ecx edx esi edi, pStr:PTR BYTE
    LOCAL buf[64]:BYTE
    INVOKE Str_length, pStr ; EAX에 길이 (63 이하라고 가정)
    mov  ecx,eax
    jecxz Done
    mov  esi,pStr
    lea  edi,buf            ; 지역 버퍼의 주소
    add  edi,ecx
    dec  edi                ; 버퍼의 마지막 칸부터 거꾸로 채운다
L1: mov  dl,[esi]           ; EAX에 길이가 있으므로 문자는 DL로 옮긴다
    mov  [edi],dl
    inc  esi
    dec  edi
    loop L1
    mov  ecx,eax            ; 버퍼의 내용을 원래 문자열 자리로 복사
    lea  esi,buf
    mov  edi,pStr
L2: mov  dl,[esi]
    mov  [edi],dl
    inc  esi
    inc  edi
    loop L2
Done:
    ret
ReverseString ENDP
END main
```

실행 결과:

```text
[dlroW ,olleH]
[ylbmessA]
[a]
[]
```

`buf`는 스택에 있으므로 주소를 `lea edi,buf`로 구했다. 문자열의 길이를 EAX에 둔 채로 두 번째 루프에서 다시 쓰므로, 문자를 옮길 때 AL을 쓰면 길이가 망가진다. 그래서 DL을 썼다(실제로 처음 작성한 풀이가 이 실수로 다른 메모리를 덮어썼다). 버퍼는 프로시저가 돌아가면 사라지므로 결과를 원래 문자열 자리에 복사해 두어야 한다([지역 변수의 주소를 돌려주면 안 된다](#지역-변수의-주소를-돌려주면-안-된다-보충)). 문자열이 64바이트를 넘을 수 있다면 길이를 검사하거나, 지역 버퍼 없이 양 끝에서 가운데로 오며 맞바꾸는 방법을 쓴다.

</details>

### 연습 7. 출력 매개변수로 최솟값과 최댓값 구하기

부호 있는 DWORD 배열에서 최솟값과 최댓값을 **출력 매개변수**로 돌려주는 프로시저 `MinMax PROC, pArray:PTR SDWORD, count:DWORD, pMin:PTR SDWORD, pMax:PTR SDWORD`를 작성하라.

<details>
<summary>풀이 보기</summary>

```asm
; 연습 7: 출력 매개변수로 최솟값과 최댓값 구하기
INCLUDE Irvine32.inc

MinMax PROTO, pArray:PTR SDWORD, count:DWORD, pMin:PTR SDWORD, pMax:PTR SDWORD

.data
values SDWORD 5, -3, 12, 0, 7, -8, 4
minVal SDWORD ?
maxVal SDWORD ?
msgMin BYTE "min = ",0
msgMax BYTE ", max = ",0

.code
main PROC
    INVOKE MinMax, ADDR values, LENGTHOF values, ADDR minVal, ADDR maxVal
    mov  edx,OFFSET msgMin
    call WriteString
    mov  eax,minVal         ; EAX = -8
    call WriteInt
    mov  edx,OFFSET msgMax
    call WriteString
    mov  eax,maxVal         ; EAX = 12
    call WriteInt
    call Crlf
    exit
main ENDP

MinMax PROC USES eax ebx ecx esi edi,
    pArray:PTR SDWORD, count:DWORD, pMin:PTR SDWORD, pMax:PTR SDWORD
    mov  esi,pArray
    mov  ecx,count
    mov  eax,[esi]          ; EAX = 지금까지의 최솟값
    mov  ebx,eax            ; EBX = 지금까지의 최댓값
    dec  ecx
    jz   Store              ; 원소가 하나뿐이면 끝
L1: add  esi,4
    mov  edx,[esi]
    cmp  edx,eax
    jge  L2
    mov  eax,edx            ; 더 작은 값
L2: cmp  edx,ebx
    jle  L3
    mov  ebx,edx            ; 더 큰 값
L3: loop L1
Store:
    mov  edi,pMin           ; 출력 매개변수: 호출한 쪽의 변수에 쓴다
    mov  [edi],eax
    mov  edi,pMax
    mov  [edi],ebx
    ret
MinMax ENDP
END main
```

실행 결과:

```text
min = -8, max = +12
```

돌려줄 값이 두 개라 EAX 하나로는 부족하므로, 결과를 담을 변수의 주소를 받아 거기에 썼다. C의 `void MinMax(int *arr, int n, int *pMin, int *pMax)`와 같은 구조다. `USES`에 EDX를 넣지 않은 것은 실수가 아니다. EDX는 `main`에서 문자열 주소를 넣기 직전에만 쓰므로 바뀌어도 상관없다. 다만 라이브러리처럼 쓰일 프로시저라면 EDX도 저장하는 편이 안전하다.

</details>

### 연습 8. 가변 인수로 합계와 평균 구하기

C 규약과 `VARARG`를 써서, 평균을 담을 변수의 주소와 개수, 그리고 개수만큼의 부호 있는 정수를 받아 합계를 EAX로, 평균(소수점 아래 버림)을 출력 매개변수로 돌려주는 `SumAvg`를 작성하라.

<details>
<summary>풀이 보기</summary>

```asm
; 연습 8: 가변 인수로 합계와 평균 구하기
INCLUDE Irvine32.inc

SumAvg PROTO C, pAvg:PTR SDWORD, count:DWORD, args:VARARG

.data
avg    SDWORD ?
msgSum BYTE "sum = ",0
msgAvg BYTE ", avg = ",0

.code
main PROC
    mov  ebx,esp
    INVOKE SumAvg, ADDR avg, 4, 10, 20, 30, 41     ; EAX = 101, ESP = EBX
    call ShowSumAvg
    INVOKE SumAvg, ADDR avg, 3, -7, 2, -10         ; EAX = -15, ESP = EBX
    call ShowSumAvg
    exit
main ENDP

ShowSumAvg PROC             ; EAX(합계)와 avg를 출력한다
    push edx
    mov  edx,OFFSET msgSum
    call WriteString
    call WriteInt
    mov  edx,OFFSET msgAvg
    call WriteString
    mov  eax,avg
    call WriteInt
    call Crlf
    pop  edx
    ret
ShowSumAvg ENDP

SumAvg PROC C USES ecx edx esi edi, pAvg:PTR SDWORD, count:DWORD, args:VARARG
    mov  eax,0
    mov  ecx,count
    lea  esi,args           ; 첫 번째 가변 인수의 주소
    jecxz Done
L1: add  eax,[esi]
    add  esi,4
    loop L1
    push eax                ; 합계를 보관하고
    cdq                     ; 부호 있는 나눗셈 준비: EDX:EAX = 합계
    idiv count              ; EAX = 평균 (0 쪽으로 버림)
    mov  edi,pAvg
    mov  [edi],eax
    pop  eax                ; 합계를 반환값으로
Done:
    ret
SumAvg ENDP
END main
```

실행 결과:

```text
sum = +101, avg = +25
sum = -15, avg = -5
```

평균은 7장의 `IDIV`로 구했다. `IDIV`는 몫을 0 쪽으로 버리므로 101 / 4 = 25.25는 25가 된다. 인수의 개수가 달라도 `INVOKE`가 `add esp,24`, `add esp,20`을 알맞게 붙이므로 ESP가 정확히 돌아온다. 이 문제에서 count가 0이면 평균을 구하지 않고 끝나므로 `avg`는 바뀌지 않는다.

</details>

### 연습 9. 다중 모듈 통계 프로그램

통계 프로시저 `ArrayMax`와 `ArrayMin`을 별도 모듈 `stats.asm`에 두고, 두 프로시저가 몇 번 호출되었는지 세는 변수 `callCount`를 `EXTERNDEF`로 공유하라. 주 모듈 `statmain.asm`에서 두 배열에 대해 최댓값과 최솟값을 구해 출력한 뒤 `callCount`도 출력하라.

<details>
<summary>풀이 보기</summary>

```asm
; stats.inc: 통계 모듈의 공용 선언
INCLUDE Irvine32.inc

EXTERNDEF callCount:DWORD

ArrayMax PROTO, pArray:PTR SDWORD, count:DWORD
ArrayMin PROTO, pArray:PTR SDWORD, count:DWORD
```

```asm
; stats.asm: 통계 프로시저 모듈
INCLUDE stats.inc

.data
callCount DWORD 0           ; 여기서 정의하므로 EXTERNDEF가 PUBLIC으로 동작한다

.code
ArrayMax PROC USES ecx esi, pArray:PTR SDWORD, count:DWORD
    inc  callCount
    mov  esi,pArray
    mov  ecx,count
    mov  eax,[esi]
    dec  ecx
    jz   Done
L1: add  esi,4
    cmp  [esi],eax
    jle  L2
    mov  eax,[esi]
L2: loop L1
Done:
    ret
ArrayMax ENDP

ArrayMin PROC USES ecx esi, pArray:PTR SDWORD, count:DWORD
    inc  callCount
    mov  esi,pArray
    mov  ecx,count
    mov  eax,[esi]
    dec  ecx
    jz   Done
L1: add  esi,4
    cmp  [esi],eax
    jge  L2
    mov  eax,[esi]
L2: loop L1
Done:
    ret
ArrayMin ENDP
END
```

```asm
; statmain.asm: 통계 프로그램의 주 모듈
INCLUDE stats.inc

.data
data1    SDWORD 3, 9, -4, 15, 0
data2    SDWORD -100, -20, -300
msgMax   BYTE "max = ",0
msgMin   BYTE ", min = ",0
msgCalls BYTE "calls = ",0

.code
main PROC
    INVOKE ArrayMax, ADDR data1, LENGTHOF data1
    INVOKE ArrayMin, ADDR data1, LENGTHOF data1
    INVOKE ArrayMax, ADDR data2, LENGTHOF data2
    INVOKE ArrayMin, ADDR data2, LENGTHOF data2
    mov  esi,OFFSET data1
    mov  ecx,LENGTHOF data1
    call ShowMaxMin
    mov  esi,OFFSET data2
    mov  ecx,LENGTHOF data2
    call ShowMaxMin
    mov  edx,OFFSET msgCalls
    call WriteString
    mov  eax,callCount      ; 다른 모듈의 변수: EAX = 8
    call WriteDec
    call Crlf
    exit
main ENDP

ShowMaxMin PROC             ; ESI(배열 주소), ECX(개수)의 최댓값·최솟값을 출력한다
    mov  edx,OFFSET msgMax
    call WriteString
    INVOKE ArrayMax, esi, ecx
    call WriteInt
    mov  edx,OFFSET msgMin
    call WriteString
    INVOKE ArrayMin, esi, ecx
    call WriteInt
    call Crlf
    ret
ShowMaxMin ENDP
END main
```

실행 결과:

```text
max = +15, min = -4
max = -20, min = -300
calls = 8
```

`stats.inc`의 `EXTERNDEF callCount:DWORD`는 `callCount`를 정의하는 `stats.asm`에서는 `PUBLIC`으로, 그 값을 읽기만 하는 `statmain.asm`에서는 `EXTERN`으로 동작한다. `main`에서 네 번, `ShowMaxMin`에서 네 번 불렀으므로 8이 나온다. 같은 포함 파일의 `PROTO` 덕분에 두 모듈이 같은 원형을 쓰게 되어, 정의와 호출이 어긋나면 어셈블할 때 바로 알 수 있다.

</details>

### 연습 10. 버블 정렬

부호 있는 DWORD 배열을 오름차순으로 정렬하는 `BubbleSort PROC, pArray:PTR SDWORD, count:DWORD`를 작성하라. 한 번의 훑기(pass)에서 교환이 한 번도 없으면 일찍 끝내도록 `LOCAL` 변수를 써라. 배열을 출력하는 `PrintArray`도 작성해 정렬 전후를 비교하라.

<details>
<summary>풀이 보기</summary>

```asm
; 연습 10: 버블 정렬
INCLUDE Irvine32.inc

BubbleSort PROTO, pArray:PTR SDWORD, count:DWORD
PrintArray PROTO, pArray:PTR SDWORD, count:DWORD

.data
nums SDWORD 64, -3, 25, 12, 22, 11, 90, 0

.code
main PROC
    INVOKE PrintArray, ADDR nums, LENGTHOF nums
    INVOKE BubbleSort, ADDR nums, LENGTHOF nums
    INVOKE PrintArray, ADDR nums, LENGTHOF nums
    exit
main ENDP

BubbleSort PROC USES eax ecx esi, pArray:PTR SDWORD, count:DWORD
    LOCAL swapped:DWORD
    mov  ecx,count
    dec  ecx                ; 훑기 횟수는 최대 count-1
    jle  Done               ; 원소가 0개나 1개면 할 일이 없다
Outer:
    mov  swapped,0
    mov  esi,pArray
    push ecx                ; 이번 훑기에서 비교할 횟수 = ECX
Inner:
    mov  eax,[esi]
    cmp  eax,[esi+4]
    jle  NoSwap             ; 이미 순서대로면 그대로 둔다
    xchg eax,[esi+4]        ; 이웃한 두 원소를 맞바꾼다
    mov  [esi],eax
    mov  swapped,1
NoSwap:
    add  esi,4
    loop Inner
    pop  ecx
    cmp  swapped,0
    je   Done               ; 교환이 없었으면 이미 정렬되었다
    loop Outer              ; 가장 큰 값이 끝으로 갔으므로 범위를 하나 줄인다
Done:
    ret
BubbleSort ENDP

PrintArray PROC USES eax ecx esi, pArray:PTR SDWORD, count:DWORD
    mov  esi,pArray
    mov  ecx,count
    jecxz P2
P1: mov  eax,[esi]
    call WriteInt
    mov  al,' '
    call WriteChar
    add  esi,4
    loop P1
P2: call Crlf
    ret
PrintArray ENDP
END main
```

실행 결과:

```text
+64 -3 +25 +12 +22 +11 +90 +0
-3 +0 +11 +12 +22 +25 +64 +90
```

바깥 루프와 안쪽 루프가 모두 ECX를 쓰므로, 안쪽 루프에 들어가기 전에 바깥 루프의 카운터를 `push ecx`로 맡겨 두었다. 훑기를 한 번 할 때마다 가장 큰 값이 맨 뒤로 가므로, 다음 훑기의 비교 횟수(ECX)가 하나씩 줄어드는 것이 자연스럽게 맞아떨어진다. `swapped`는 스택에 있는 지역 변수이고 프로시저 안에서만 쓰인다.

</details>

---

## 부록 G. 슬라이드 정정 사항 모음

본문의 정정 박스에 적은 내용을 한곳에 모았다. 슬라이드 번호는 표지를 1번으로 센 것이다.

| 위치 | 슬라이드 표기 | 올바른 내용 |
|---|---|---|
| 3번 Disadvantages of Register Parameters | "the performance advantage we hoped to gain by **avoiding** register parameters" | 속도 이점은 레지스터 매개변수를 **쓸 때** 얻으려던 것이다. "by **using** register parameters" |
| 4번 그림 | "VALVE" | "VALUE" |
| 12번 Saving and Restoring Registers | `ret ; clean up the stack` | `RET`만으로는 인수가 치워지지 않는다. `ret 4`로 쓰거나(교재 예제 `UsesTest.asm`) 호출한 쪽이 `add esp,4`를 해야 한다 |
| 16번 LEA Instruction | `lea esi,[ebp–30]`, 주석 `EBP–30` | 빼기 기호는 대시(`–`)가 아니라 하이픈(`-`)이다. 그대로 복사하면 어셈블되지 않는다 |
| 24번 Recursion | "exit the procedure when ECX 0" | "when ECX **=** 0" |
| 25번 Calculating a Factorial | `int function factorial(int n)` | C에는 `function` 키워드가 없다. `int factorial(int n)` |
| 32번 ADDR Operator | "The argument passed to ADDR must be an assembly time constant" | `ADDR`은 `LOCAL` 변수나 이름 붙은 매개변수에도 쓸 수 있다(어셈블러가 `lea eax,…` / `push eax`를 만든다). 거부되는 것은 `[ebp+12]`처럼 레지스터로 쓴 주소식이며, 이것도 어셈블러에 따라 다르다(JWasm은 받아들였다) |
| 40번 파란 글씨 | `INVOKE`는 "함수 호출용 매크로", "호출 규칙에 따라 스택 정리까지 자동 처리" | `INVOKE`는 매크로가 아니라 지시어다. 스택 정리 코드(`add esp,n`)를 붙이는 것은 C 규약일 때뿐이고, STDCALL에서는 `PROC`가 만든 `ret n`이 치운다 |
| 48번 PUBLIC | "the operating system's loader will not be able to find it" | 진입점 이름을 찾아 주소로 바꾸는 것은 **링커**다. 로더는 실행 파일 헤더에 기록된 주소를 읽을 뿐이다 |
| 49번 Calling External Procedures | `EXTERN`이 "the procedure's name and stack frame size"를 알린다 | `@n`의 n은 프레임 전체가 아니라 **매개변수의 바이트 수**다(같은 슬라이드 둘째 문단의 설명이 맞다) |

틀린 것은 아니지만 그대로 따라 하면 오해하기 쉬운 부분은 다음과 같다.

| 위치 | 슬라이드 내용 | 주의할 점 |
|---|---|---|
| 23번 RecursiveSum | 마지막 줄 `end Main` | 기본 설정에서는 대소문자를 구분하지 않아 어셈블되지만 `OPTION CASEMAP:NONE`이면 오류다. `END main`으로 맞춘다 |
| 26번 Fact.asm | n은 0~12 | 13!부터는 32비트를 넘는다. 프로그램은 `MUL`의 EDX와 CF를 무시하므로 틀린 값을 그대로 출력한다 |
| 35·37·38번 MASM이 만든 코드 | 에필로그가 `leave` | 어셈블러마다 다르다. JWasm은 같은 일을 `pop ebp`(지역 변수가 없을 때) 또는 `mov esp,ebp` / `pop ebp`로 한다. ESP를 내리는 코드도 MASM은 `add esp,0FFFFFFFCh`, JWasm은 `sub esp,4`다 |
| 37번 Read_File | `USES eax ebx`인데 본문에서 ESI를 바꾼다 | 예제 조각이라 생략된 것이지만, 실제로는 ESI도 `USES`에 넣어야 호출한 쪽의 ESI가 지켜진다 |
| 44번 WriteStackFrame 예제 | `main`에서 `INVOKE myProc, …` | `myProc`이 뒤에 정의되므로 `myProc PROTO, x:DWORD, y:DWORD`가 필요하다 |
| 45번 WriteStackFrame 출력 | 값과 `ebp` 사이가 한 칸 | 라이브러리 소스는 두 칸(`"  ebp"`)을 출력한다 |

슬라이드 21, 29, 54번은 머리글만 있는 빈 슬라이드이고, 57번은 "Github upload"라는 안내만 있다. 슬라이드에 없어서 보충한 부분은 다음과 같다.

| 내용 | 근거 |
|---|---|
| 스택 프레임의 완성된 그림, ESP 대신 EBP를 쓰는 이유 | 교재 8.2절, 실행으로 확인 |
| `__fastcall`, Microsoft x64 호출 규약(섀도 공간, 다섯·여섯 번째 인수의 위치) | Microsoft Learn, 64비트 빌드로 확인 |
| 지역 변수가 초기화되지 않는 것, 지역 변수의 주소를 돌려주면 안 되는 이유 | 실행으로 확인 |
| LEA로 계산하기, ENTER의 중첩 수준, 컴파일러가 ENTER를 쓰지 않는 이유 | 인텔 SDM, Raymond Chen의 글, 실행으로 확인 |
| LOCAL 변수의 실제 배치와 어셈블러가 만든 코드 | JWasm 목록 파일 |
| 재귀의 스택 사용량, 13! 넘침, 꼬리 재귀와 반복, 간접 재귀 | 실행으로 확인 |
| INVOKE가 인수마다 만드는 코드와 EAX 덮어쓰기 | 교재 8.4.1절, JWasm 목록 파일 |
| PROTO 지시어, C 규약과 VARARG | 교재 8.4.4절, Microsoft Learn |
| 매개변수 분류의 예, 디버깅 팁의 실제 결과 값 | 실행으로 확인 |
| 이름 숨기기의 결과, EXTERN 실습, ArraySum 다중 모듈 코드(빈 슬라이드 54번 자리) | 교재 8.5절과 예제 파일, 실행으로 확인 |
| 8.6 매개변수 고급 활용 | 교재 8.6절, 실행으로 확인 |
| 8.7 자바 바이트코드 | 교재 8.7절, JVM 명세, `javac`/`javap`(JDK 21) |
| 부록 B (C 컴파일러가 만든 스택 프레임) | GCC 13 출력 |

---

## 참고 자료

### 예제 값 확인 방법

이 문서의 예제는 눈으로만 검토하지 않고 실제로 돌려서 확인했다.

- `asm` 코드 블록 99개를 MASM 호환 어셈블러(JWasm 2.21)로 어셈블했다(64비트 예제 1개는 64비트 모드로, 포함 파일 블록 3개는 그것을 쓰는 모듈과 함께). 조각 코드는 프로그램 틀을 씌웠고, 다중 모듈 예제는 모듈을 각각 어셈블해 함께 링크했다. Irvine32 프로시저는 같은 이름과 출력 형식으로 만든 리눅스용 대체 라이브러리에 링크했으며, `WriteStackFrame`은 원래 라이브러리 소스를 그대로 옮겨 썼다.
- 실행 파일을 디버거(gdb)로 한 명령어씩 실행하면서 주석에 적힌 레지스터·플래그·변수 값, 스택의 `[ebp+n]`·`[esp+n]` 값, `ESP = EBP-8` 같은 레지스터 사이의 관계, 재귀 호출마다 바뀌는 값("차례로"), 점프 여부, 실행되지 않아야 할 줄, 접근 위반, 어셈블 오류를 실제 결과와 비교했다. `CALL` 줄의 값은 그 호출이 돌아온 직후의 상태와 비교했다. 이렇게 비교한 항목은 232개이고 모두 일치했다.
- "실행 결과" 블록 20개는 프로그램의 실제 출력과 한 줄씩 비교했다. 부록 E의 정답과 부록 F의 풀이도 같은 방법으로 확인했다.
- 64비트 예제는 64비트로 따로 빌드해 C 프로그램에서 Microsoft x64 규약(`ms_abi`)으로 불러 결과와 스택 정렬을 검사했다. 부록 B는 GCC 13의 실제 출력이고, 8.7절의 바이트코드는 `javac`/`javap`(JDK 21)의 실제 출력이다.

다만 다음은 확인 범위 밖이다.

- Windows의 `ml.exe`와 Visual Studio에서 직접 실행한 것은 아니다. 명령어의 동작과 스택의 구조는 운영체제에 상관없이 같지만, 어셈블러가 만드는 프롤로그·에필로그의 모양(`leave` 여부 등)이나 오류 메시지 문구는 MASM과 다를 수 있다. MASM의 동작으로 적은 부분은 교재·슬라이드와 Microsoft 문서를 근거로 했다.
- 복귀 주소, 저장된 EBP, `DumpMem`의 주소처럼 실행 환경마다 다른 값은 …로 줄였다. 리눅스에서 `main`이 시작될 때의 EBP 값처럼 환경에 따라 다른 값은 주석에 쓰지 않았다.
- 스택 오버플로의 예외 코드(`0xC00000FD`)와 기본 스택 크기(1MB)는 Microsoft 문서를 근거로 했다. 리눅스에서는 같은 프로그램이 SIGSEGV로 끝나는 것을 확인했다.

### 문헌과 링크

- Kip R. Irvine, *Assembly Language for x86 Processors* (7th / 8th Edition), Pearson — Chapter 8. Advanced Procedures
- [Kip Irvine 교재 공식 사이트](https://www.asmirvine.com/) (Irvine32 라이브러리와 예제 프로그램)
- [intelligentcm 블로그 — Assembly 카테고리](https://intelligentcm.tistory.com/category/Assembly)
- [Microsoft Learn — Microsoft Macro Assembler(MASM) 참조](https://learn.microsoft.com/ko-kr/cpp/assembler/masm/microsoft-macro-assembler-reference)
- [Microsoft Learn — INVOKE](https://learn.microsoft.com/en-us/cpp/assembler/masm/invoke) (32비트 MASM 전용)
- [Microsoft Learn — PROC](https://learn.microsoft.com/en-us/cpp/assembler/masm/proc), [PROC (Visual Studio 2008 문서)](https://learn.microsoft.com/en-us/previous-versions/visualstudio/visual-studio-2008/01d2az3t(v=vs.90)) (visibility 기본값과 OPTION PROC)
- [Microsoft Learn — EXTERNDEF](https://learn.microsoft.com/en-us/cpp/assembler/masm/externdef)
- [Microsoft Learn — __stdcall](https://learn.microsoft.com/en-us/cpp/cpp/stdcall), [__fastcall](https://learn.microsoft.com/en-gb/cpp/cpp/fastcall?view=msvc-170), [Decorated names](https://learn.microsoft.com/en-us/cpp/build/reference/decorated-names)
- [Microsoft Learn — x64 calling convention](https://learn.microsoft.com/cpp/build/x64-calling-convention)
- [Microsoft Learn — /STACK (Stack allocations)](https://learn.microsoft.com/en-us/cpp/build/reference/stack-stack-allocations) (기본 스택 예약 크기 1MB)
- [Microsoft Learn — Debugging a stack overflow](https://learn.microsoft.com/en-us/windows-hardware/drivers/debugger/debugging-a-stack-overflow) (`0xC00000FD`, `STATUS_STACK_OVERFLOW`)
- [Raymond Chen, The Old New Thing — The Intel 80386, part 9: Stack frame instructions](https://devblogs.microsoft.com/oldnewthing/20190130-00/?p=100835) (ENTER가 느리고 LEAVE가 빠른 이유)
- [MASM32 Forum — OPTION PROC:PRIVATE로 감춘 프로시저와 LNK2001](https://masm32.com/board/index.php?msg=29042)
- [Intel® 64 and IA-32 Architectures Software Developer's Manuals](https://www.intel.com/content/www/us/en/developer/articles/technical/intel-sdm.html) (Volume 2의 CALL, RET, PUSH, POP, LEA, ENTER, LEAVE 항목)
- [The Java® Virtual Machine Specification, Java SE 21 — Chapter 2](https://docs.oracle.com/javase/specs/jvms/se21/html/jvms-2.html) (프레임, 지역 변수, 피연산자 스택)

<br>

> 이 문서는 강의 슬라이드를 바탕으로 개인 학습용으로 정리한 노트입니다.
