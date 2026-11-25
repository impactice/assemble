# x86 어셈블리: 구조체와 매크로 (Structures and Macros)

![Assembler](https://img.shields.io/badge/Assembler-MASM-blue)
![Architecture](https://img.shields.io/badge/Architecture-x86%2032--bit-lightgrey)
![IDE](https://img.shields.io/badge/IDE-Visual%20Studio%202022-5C2D91)
![Chapter](https://img.shields.io/badge/Irvine-Chapter%2010-orange)

> Kip R. Irvine, *Assembly Language for x86 Processors* — Chapter 10. Structures and Macros 강의 정리
>
> 슬라이드 내용을 절 순서대로 정리하고, 슬라이드에 없는 동작 원리, 추가 예제, 자주 하는 실수를 보충했다. 슬라이드가 비어 있거나 다루지 않은 부분(Wraps 프로그램의 실행 결과, 행의 합을 구하는 매크로, 연결 리스트, `REPEAT` 예제)도 채웠다.
> 슬라이드의 오류는 본문에 정정 박스로 표시하고 [부록 G](#부록-g-슬라이드-정정-사항-모음)에 모아 두었다.
> 예제 코드의 주석에 적힌 레지스터·변수·필드 값, 실행 결과, 어셈블할 때 나오는 메시지, 목록 파일(.lst)의 매크로 확장은 직접 어셈블하고 실행해서 확인한 것이다([예제 값 확인 방법](#예제-값-확인-방법)).

---

## 한눈에 보기 (TL;DR)

- **구조체**(structure)는 서로 관련된 변수들을 묶은 **틀**이다. `이름 STRUCT` … `이름 ENDS`로 정의하고, 정의 자체는 메모리를 차지하지 않는다. `worker Employee <>`처럼 **구조체 변수**를 선언해야 메모리가 잡힌다.
- 필드에는 구조체 시작으로부터의 **오프셋**이 정해진다. `worker.Years`는 "worker의 주소 + Years의 오프셋"이고, `TYPE`·`SIZEOF`·`LENGTHOF`·`OFFSET`을 구조체와 필드에 그대로 쓸 수 있다.
- 레지스터로 가리킬 때는 `(Employee PTR [esi]).Years`처럼 **`PTR`로 구조체 형식을 알려 줘야** 필드 이름을 쓸 수 있다.
- 필드를 크기에 맞는 주소에 놓으려면 `ALIGN`을 쓴다. 정렬이 어긋나도 결과는 같지만, 접근이 캐시 줄(64바이트) 경계를 넘으면 눈에 띄게 느려진다.
- **공용체**(union)는 모든 필드가 오프셋 0에서 시작해 **같은 메모리를 겹쳐 쓴다**. 크기는 가장 큰 필드의 크기다.
- **매크로**(macro)는 이름 붙인 문장 묶음으로, 호출한 자리에 **텍스트로 펼쳐진다**(인라인 확장). 프로시저처럼 `CALL`/`RET`이 없는 대신 호출할 때마다 코드가 복사된다.
- 매크로 안의 레이블과 변수는 `LOCAL`로 선언해야 여러 번 호출해도 이름이 겹치지 않는다(`??0000`, `??0001`…). 매개변수에는 `:REQ`(필수)와 `:=<기본값>`을 붙일 수 있다.
- **조건부 어셈블리**(`IF`, `IFB`, `IFIDNI`, `IFDEF` …)와 **반복 블록**(`WHILE`, `REPEAT`, `FOR`, `FORC`)은 모두 **어셈블할 때** 실행된다. 실행 중의 레지스터 값으로 판단하는 `.IF`와 헷갈리지 말자.
- 특수 연산자 `&`(치환), `<>`(텍스트 묶기), `!`(문자 그대로), `%`(식의 값을 텍스트로)는 매크로가 인수를 텍스트로 다룬다는 사실에서 나온다.

---

## 목차

| 구분 | 내용 |
|---|---|
| [들어가며](#들어가며-9장에서-10장으로) | 9장과의 연결, C의 구조체·매크로와의 대응 |
| [10.1 구조체](#101-구조체-structures) | 정의, 필드 정렬, 변수 선언, 참조(TYPE·SIZEOF·OFFSET·PTR), 정렬과 성능, 시스템 시간, 중첩 구조체, Drunkard's Walk, 공용체 |
| [10.2 매크로](#102-매크로-macros) | 정의와 호출, 목록 파일로 확인하기, REQ, 주석, ECHO, LOCAL, 코드와 데이터를 담은 매크로, 중첩 매크로, Macros.inc, Wraps 프로그램 |
| [10.3 조건부 어셈블리 지시어](#103-조건부-어셈블리-지시어-conditional-assembly-directives) | IFB, 기본 인수, 불리언 식, IF/ELSE, IFIDN/IFIDNI, 행의 합 매크로, 특수 연산자(&, <>, !, %), 줄 번호 표시, 매크로 함수 |
| [10.4 반복 블록 정의](#104-반복-블록-정의-defining-repeat-blocks) | WHILE, REPEAT, FOR, FORC, 어셈블할 때 만드는 연결 리스트 |
| [부록 A](#부록-a-핵심-정리-표) | 핵심 정리 표 (지시어, 연산자, 매크로와 프로시저) |
| [부록 B](#부록-b-c-컴파일러가-만든-구조체-코드와-c의-매크로) | C 컴파일러가 만든 구조체 코드와 C의 매크로 |
| [부록 C](#부록-c-자주-하는-실수와-오류-메시지) | 자주 하는 실수와 오류 메시지 |
| [부록 D](#부록-d-핵심-용어-정리) | 핵심 용어 정리 |
| [부록 E](#부록-e-복습-문제) | 복습 문제 (단답형 15문제, 알고리즘 작성 6문제, 정답 접기) |
| [부록 F](#부록-f-프로그래밍-연습-풀이-포함) | 프로그래밍 연습 10문제와 풀이 (매크로, 구조체·공용체, 반복 블록, VARARG) |
| [부록 G](#부록-g-슬라이드-정정-사항-모음) | 슬라이드 정정 사항 모음 |
| [참고 자료](#참고-자료) | 예제 값 확인 방법, 교재, 공식 문서 |

---

## 들어가며: 9장에서 10장으로

9장까지 다룬 데이터는 모두 같은 형식의 원소가 늘어선 배열이었다. 그런데 실제 프로그램이 다루는 데이터는 "사번(문자열) + 이름(문자열) + 근속 연수(WORD) + 연봉 기록(DWORD 배열)"처럼 **형식이 서로 다른 값들의 묶음**인 경우가 많다. 10장의 앞부분은 이런 묶음을 하나의 단위로 다루는 **구조체**와 **공용체**를 다룬다. Windows API의 `COORD`(화면 좌표), `SYSTEMTIME`(날짜와 시각) 같은 자료형이 모두 구조체다.

뒷부분은 **매크로**다. 8장까지 같은 코드를 여러 번 쓰지 않으려고 프로시저를 만들었다면, 매크로는 같은 목적을 **어셈블할 때 텍스트를 펼쳐 넣는** 방식으로 이룬다. 여기에 조건부 어셈블리와 반복 블록을 더하면, 어셈블러가 인수를 검사하고 오류 메시지를 내거나, 표를 자동으로 만들어 주는 작은 "프로그램을 만드는 프로그램"을 쓸 수 있다.

| 하고 싶은 일 | 이 장에서 배우는 도구 | C에서 비슷한 것 | 절 |
|---|---|---|---|
| 서로 다른 형식의 값을 하나로 묶는다 | `STRUCT` … `ENDS` | `struct` | 10.1 |
| 필드에 접근한다 | `worker.Years`, `(Employee PTR [esi]).Years` | `worker.Years`, `p->Years` | 10.1 |
| 크기와 위치를 구한다 | `SIZEOF Employee`, `OFFSET Employee.Years` | `sizeof`, `offsetof` | 10.1 |
| 같은 메모리를 여러 형식으로 본다 | `UNION` … `ENDS` | `union` | 10.1 |
| 짧은 코드를 이름 붙여 재사용한다 | `MACRO` … `ENDM` | `#define` 매크로 | 10.2 |
| 인수에 따라 다른 코드를 만든다 | `IF`, `IFB`, `IFIDNI`, `IFDEF` | `#if`, `#ifdef` | 10.3 |
| 인수를 텍스트로 붙이거나 값을 문자열로 바꾼다 | `&`, `%`, `<>`, `!` | `##`, `#` | 10.3 |
| 데이터나 코드를 반복해서 만든다 | `WHILE`, `REPEAT`, `FOR`, `FORC` | (C 전처리기에는 반복이 없다) | 10.4 |

> [!NOTE]
> 이 문서의 예제는 MASM과 호환되는 어셈블러 JWasm으로 어셈블해서 확인했다. 매크로를 펼친 결과를 보여 주는 **목록 파일**(listing, `.lst`)과 어셈블할 때 콘솔에 나오는 메시지도 JWasm의 실제 출력을 그대로 실었다. MASM(`ml.exe`)의 목록 파일과 오류 메시지는 형식과 번호가 조금 다를 수 있으며, 차이가 있는 부분은 본문에 적어 두었다.

---

## 10.1 구조체 (Structures)

**구조체**(structure)는 논리적으로 관련된 변수들의 묶음에 붙인 **틀**(template, pattern)이다. 구조체 안의 변수를 **필드**(field)라고 부른다. 프로그램은 구조체를 하나의 덩어리로 다룰 수도 있고, 필드 하나하나에 접근할 수도 있다. 구조체의 필드는 형식이 서로 다른 경우가 많다.

**공용체**(union)도 여러 식별자를 하나로 묶지만, 그 식별자들이 **같은 메모리 영역을 겹쳐서** 쓴다는 점이 다르다(10.1절 끝에서 다룬다).

Windows API에 정의된 `COORD` 구조체는 화면의 X, Y 좌표를 나타낸다.

```asm
COORD STRUCT
    X WORD ?                ; offset 00
    Y WORD ?                ; offset 02
COORD ENDS
```

`X`는 구조체의 시작에서 0바이트, `Y`는 2바이트 떨어진 곳에 있다. 이 **오프셋**이 구조체를 이해하는 열쇠다. 구조체 변수의 필드 주소는 "변수의 시작 주소 + 필드의 오프셋"으로 정해진다. C의 `struct COORD { short X; short Y; };`와 같은 모양이다.

> [!NOTE]
> `COORD`는 `Irvine32.inc`가 포함하는 `SmallWin.inc`에 이미 정의되어 있으므로, 실제 프로그램에서는 다시 정의하지 않고 그대로 쓰면 된다. 위처럼 **필드가 똑같은** 정의를 한 번 더 쓰는 것은 허용되지만(benign redefinition), 필드 이름이나 형식이 하나라도 다르면 JWasm은 `Non-benign structure redefinition: COORD` 오류를 낸다.

### 구조체 정의 (Defining Structures)

구조체는 `STRUCT`와 `ENDS` 지시어로 정의한다.

```text
name STRUCT
    field-declarations
name ENDS
```

필드 선언은 보통의 데이터 정의와 같은 모양이고, 초기값(field initializer)을 줄 수 있다. 이 초기값은 나중에 구조체 변수를 선언할 때 따로 값을 주지 않은 필드의 **기본값**이 된다.

| 초기값 | 뜻 | 예 |
|---|---|---|
| `?` | 정하지 않음(undefined) | `X WORD ?` |
| 문자열 리터럴 | 따옴표로 둘러싼 문자열 | `IdNum BYTE "000000000"` |
| 정수 | 정수 상수나 정수 식 | `Years WORD 0` |
| 배열 | `DUP` 연산자로 원소를 초기화 | `LastName BYTE 30 DUP(0)` |

다음은 직원 정보를 담는 `Employee` 구조체다.

```asm
Employee STRUCT
    IdNum         BYTE "000000000"   ; 사번 9바이트 (널 문자 없음)
    LastName      BYTE 30 DUP(0)
    Years         WORD 0
    SalaryHistory DWORD 0,0,0,0
Employee ENDS
```

메모리에는 필드가 선언한 순서대로 빈틈없이 놓인다.

```text
offset  0          9                        39      41               57
        +----------+------------------------+-------+----------------+
        | IdNum    | LastName               | Years | SalaryHistory  |
        | (9)      | (30)                   | (2)   | (16)           |
        +----------+------------------------+-------+----------------+
```

`IdNum`은 9바이트를 문자로 꽉 채웠으므로 끝에 널 문자가 없다. `WriteString`으로 출력하면 바로 뒤의 `LastName`까지 이어서 출력되니, 출력할 때는 길이를 직접 지정해야 한다.

### 구조체 필드의 정렬 (Aligning Structure Fields)

메모리 입출력 성능을 가장 좋게 하려면 각 필드를 그 **데이터 형식에 맞는 주소**에 두어야 한다(WORD는 2의 배수, DWORD는 4의 배수 주소). 그렇지 않으면 CPU가 필드에 접근하는 데 시간이 더 걸릴 수 있다. 구조체 안에서는 `ALIGN` 지시어로 다음 필드의 오프셋을 맞춘다.

```text
ALIGN datatype
```

```asm
EmployeeBad STRUCT                   ; 정렬하지 않은 원래 구조체
    IdNum         BYTE "000000000"
    LastName      BYTE 30 DUP(0)
    Years         WORD 0
    SalaryHistory DWORD 0,0,0,0
EmployeeBad ENDS

Employee STRUCT
    IdNum         BYTE "000000000"   ;  9
    LastName      BYTE 30 DUP(0)     ; 30
    ALIGN         WORD               ;  1 byte added
    Years         WORD 0             ;  2
    ALIGN         DWORD              ;  2 bytes added
    SalaryHistory DWORD 0,0,0,0      ; 16
Employee ENDS                        ; 60 total

mov  eax,OFFSET EmployeeBad.Years           ; EAX = 39
mov  eax,OFFSET EmployeeBad.SalaryHistory   ; EAX = 41
mov  eax,SIZEOF EmployeeBad                 ; EAX = 57
mov  eax,OFFSET Employee.Years              ; EAX = 40
mov  eax,OFFSET Employee.SalaryHistory      ; EAX = 44
mov  eax,SIZEOF Employee                    ; EAX = 60
```

`OFFSET 구조체이름.필드`는 그 필드의 오프셋(구조체 시작부터의 거리)이다. `ALIGN WORD`가 1바이트를, `ALIGN DWORD`가 2바이트를 채워 넣어 구조체가 57바이트에서 60바이트로 늘었다.

| 필드 | 크기 | `EmployeeBad`의 오프셋 | `Employee`의 오프셋 |
|---|---|---|---|
| `IdNum` | 9 | 0 | 0 |
| `LastName` | 30 | 9 | 9 |
| (채우기 바이트) | 1 | — | 39 |
| `Years` | 2 | 39 (홀수) | 40 |
| (채우기 바이트) | 2 | — | 42 |
| `SalaryHistory` | 16 | 41 (4의 배수가 아님) | 44 |
| 전체 | | **57** | **60** |

필드 형식별로 맞추는 기준은 교재의 Table 10-1과 같다.

| 필드 형식 | 정렬 기준 |
|---|---|
| `BYTE`, `SBYTE` | 8비트(바이트) 경계 |
| `WORD`, `SWORD` | 16비트(워드) 경계 |
| `DWORD`, `SDWORD` | 32비트(더블워드) 경계 |
| `QWORD` | 64비트(쿼드워드) 경계 |
| `REAL4` | 32비트(더블워드) 경계 |
| `REAL8` | 64비트(쿼드워드) 경계 |
| 구조체 | 멤버 중 가장 큰 정렬 기준 |
| 공용체 | 첫 번째 멤버의 정렬 기준 |

#### STRUCT의 정렬 인수 (보충)

MASM 문서의 `STRUCT` 구문은 `name STRUCT ⟦alignment⟧ ⟦, NONUNIQUE⟧`로, 이름 뒤에 정렬 값을 적을 수 있다. 필드마다 `ALIGN`을 쓰는 대신 `STRUCT 4`라고 쓰면, 각 필드가 "필드 크기와 4 중 작은 값"의 배수 오프셋에 놓인다. JWasm으로 확인한 결과 위의 `Employee`와 똑같은 배치가 나왔다.

```asm
EmployeeA STRUCT 4
    IdNum         BYTE "000000000"
    LastName      BYTE 30 DUP(0)
    Years         WORD 0
    SalaryHistory DWORD 0,0,0,0
EmployeeA ENDS

mov  eax,OFFSET EmployeeA.Years             ; EAX = 40
mov  eax,OFFSET EmployeeA.SalaryHistory     ; EAX = 44
mov  eax,SIZEOF EmployeeA                   ; EAX = 60
```

C 컴파일러도 기본적으로 이와 같은 규칙으로 필드를 배치한다. 같은 필드를 가진 C 구조체의 크기도 60바이트다([부록 B](#부록-b-c-컴파일러가-만든-구조체-코드와-c의-매크로)).

### 구조체 변수 선언 (Declaring Structure Variables)

구조체 변수는 구조체 이름을 데이터 형식처럼 써서 선언하고, 필요하면 꺾쇠괄호(또는 중괄호) 안에 초기값을 준다.

```text
identifier structureType < initializer-list >
                           initializer [, initializer] ...
```

빈 꺾쇠괄호 `< >`를 쓰면 모든 필드가 구조체 정의의 기본값을 가진다. 초기값 목록은 필드 순서대로 대응하고, 쉼표만 쓰고 비워 둔 자리는 기본값을 그대로 쓴다. 즉 **원하는 필드만 골라서** 초기값을 바꿀 수 있다.

```asm
.data
point1  COORD <5,10>                ; X = 5, Y = 10
point2  COORD <20>                  ; X = 20, Y = ?
point3  COORD <>                    ; X = ?, Y = ?
worker  Employee <>                 ; (default initializers)
person1 Employee <"555223333">      ; IdNum만 바꾼다
person2 Employee {"555223333"}      ; 중괄호도 같은 뜻
person3 Employee <,"dJones">        ; 두 번째 필드(LastName)만 바꾼다
person4 Employee <,,,2 DUP(20000)>  ; SalaryHistory의 앞 두 원소만 바꾼다
.code
mov  ax,point1.Y                    ; AX = 10
mov  ax,point2.X                    ; AX = 20
mov  ax,point2.Y                    ; AX = 0
mov  edx,OFFSET person1.IdNum       ; person1.IdNum = "555223333", person3.LastName = "dJones"
mov  eax,person4.SalaryHistory      ; person4.SalaryHistory = [20000, 20000, 0, 0]
```

- `point2 COORD <20>`처럼 뒤쪽 초기값을 생략하면 그 필드는 기본값(`COORD`에서는 `?`)이다. `.data` 섹션에서 `?`는 실제로는 0으로 채워진다.
- `person3`의 `LastName`은 30바이트 필드에 `"dJones"`(6바이트)만 주었다. 나머지 24바이트는 0으로 채워져 자연스럽게 널 종료 문자열이 된다.
- `person4`는 `SalaryHistory`의 앞 두 원소만 20000으로 바꾸고, 나머지 두 원소는 기본값 0을 그대로 둔다.

**구조체 배열** (Array of Structures). `DUP`로 구조체 변수 여러 개를 한 번에 만들 수 있다.

```asm
NumPoints = 3
.data
AllPoints COORD NumPoints DUP(<0,0>)
.code
mov  eax,SIZEOF AllPoints           ; EAX = 12
mov  eax,LENGTHOF AllPoints         ; EAX = 3
mov  eax,TYPE AllPoints             ; EAX = 4
```

**구조체 변수의 정렬** (Aligning Structure Variables). 프로세서 성능을 가장 좋게 하려면 구조체 변수 자체도 **가장 큰 필드의 크기**에 맞는 경계에 두는 것이 좋다. `Employee`에서 가장 큰 필드는 DWORD이므로 `ALIGN DWORD`를 쓴다.

```asm
.data
odd    BYTE 1                       ; 정렬을 깨뜨리는 1바이트
ALIGN DWORD
person Employee <>
.code
mov  eax,OFFSET person
and  eax,3                          ; EAX = 0
```

`ALIGN DWORD`가 채우기 바이트를 넣어 `person`의 주소가 4의 배수가 되었다(아래 2비트가 0). 구조체 안의 `ALIGN`이 맞추는 것은 구조체 시작으로부터의 **오프셋**이므로, 필드의 실제 주소까지 정렬되려면 변수의 시작 주소도 정렬되어 있어야 한다.

### 구조체 변수 참조 (Referencing Structure Variables)

`TYPE`과 `SIZEOF` 연산자는 구조체 이름과 구조체 변수에 모두 쓸 수 있다. 앞의 정렬된 `Employee`와 `worker Employee <>`를 그대로 쓴다.

```asm
mov  eax,TYPE Employee                      ; EAX = 60
mov  eax,SIZEOF Employee                    ; EAX = 60
mov  eax,SIZEOF worker                      ; EAX = 60
```

**필드 참조** (References to Members). 필드에도 `TYPE`, `LENGTHOF`, `SIZEOF`를 쓸 수 있다. 이때 필드 이름 앞에는 반드시 구조체 이름이나 구조체 변수 이름을 붙여야 한다(`Employee.SalaryHistory`, `worker.Years`). 필드 이름만 따로 쓰면 정의되지 않은 기호다.

```asm
mov  eax,TYPE Employee.SalaryHistory        ; EAX = 4
mov  eax,LENGTHOF Employee.SalaryHistory    ; EAX = 4
mov  eax,SIZEOF Employee.SalaryHistory      ; EAX = 16
mov  eax,TYPE Employee.Years                ; EAX = 2
mov  dx,worker.Years                        ; DX = 0
mov  worker.SalaryHistory,20000             ; first salary
mov  [worker.SalaryHistory+4],30000         ; second salary: worker.SalaryHistory = [20000, 30000, 0, 0]
```

`worker.SalaryHistory`는 DWORD 필드이므로 상수 20000을 저장할 때 `DWORD PTR`이 필요 없다. 두 번째 원소는 필드 주소에 4를 더해 `[worker.SalaryHistory+4]`로 접근한다.

**OFFSET 연산자** (Using the OFFSET Operator). 구조체 변수 안의 필드 주소를 구한다.

```asm
mov  esi,OFFSET worker
mov  edx,OFFSET worker.LastName             ; EDX = ESI+9
mov  ebx,OFFSET worker.SalaryHistory        ; EBX = ESI+44
```

`OFFSET Employee.LastName`(구조체 이름)은 오프셋 9라는 **상수**이고, `OFFSET worker.LastName`(변수 이름)은 worker의 주소에 9를 더한 **주소**다.

### 간접 피연산자와 인덱스 피연산자 (Indirect and Indexed Operands)

레지스터(예: ESI)로 구조체를 가리키면, 구조체의 주소를 프로시저에 넘기거나 구조체 배열을 훑을 때 유연하게 쓸 수 있다. 이때는 레지스터가 **어떤 구조체를 가리키는지** `PTR` 연산자로 알려 줘야 필드 이름을 쓸 수 있다.

```asm
mov  esi,OFFSET worker
mov  worker.Years,5
mov  ax,(Employee PTR [esi]).Years          ; AX = 5
mov  ax,[esi].Years                         ; 어셈블 오류
```

어셈블러는 `[esi]`가 무엇을 가리키는지 모르므로, 형식 없이 `[esi].Years`라고 쓰면 `Years`를 찾지 못한다(JWasm: `Symbol not defined : Years`).

#### 같은 뜻의 다른 표기와 ASSUME (보충)

`(Employee PTR [esi]).Years`는 결국 `[esi + 40]`이다. 다음 세 줄은 모두 같은 기계어가 된다. 마지막 방법은 `ASSUME`으로 "ESI는 `Employee`를 가리킨다"고 미리 선언해 두는 것으로, 같은 레지스터로 필드를 여러 번 읽을 때 편하다. 다 쓴 뒤에는 `ASSUME esi:NOTHING`으로 풀어 둔다.

```asm
mov  esi,OFFSET worker
mov  worker.Years,7
mov  ax,[esi + Employee.Years]              ; AX = 7
mov  bx,[esi].Employee.Years                ; BX = 7
ASSUME esi:PTR Employee
mov  cx,[esi].Years                         ; CX = 7
ASSUME esi:NOTHING
```

**인덱스 피연산자** (Indexed Operands). 구조체 배열의 원소에 접근할 때 쓴다. 인덱스 레지스터에는 원소 번호가 아니라 **바이트 오프셋**(원소 번호 × `TYPE Employee`)을 넣는다.

```asm
.data
department Employee 5 DUP(<>)
.code
mov  esi,TYPE Employee                      ; index = 1
mov  department[esi].Years, 4
mov  ax,department[esi].Years               ; AX = 4
mov  bx,department.Years                    ; BX = 0
```

`department[esi].Years`는 "department의 주소 + ESI + 40"이다. ESI = 60이므로 두 번째 원소(index 1)의 `Years`가 바뀌고, 첫 번째 원소의 `Years`(`department.Years`)는 그대로 0이다.

**배열 훑기** (Looping through an Array). 루프와 간접·인덱스 주소 지정으로 구조체 배열 전체를 처리할 수 있다.

```asm
; Loop Through Array (AllPoints.asm)
INCLUDE Irvine32.inc
NumPoints = 3
.data
ALIGN WORD
AllPoints COORD NumPoints DUP(<0,0>)
.code
main PROC
    mov  edi,0                      ; array index
    mov  ecx,NumPoints              ; loop counter
    mov  ax,1                       ; starting X, Y values
L1: mov  (COORD PTR AllPoints[edi]).X,ax
    mov  (COORD PTR AllPoints[edi]).Y,ax
    add  edi,TYPE COORD
    inc  ax
    loop L1                         ; 끝나면 WORD PTR AllPoints = [1, 1, 2, 2, 3, 3]
    exit
main ENDP
END main
```

EDI는 원소 하나의 크기(`TYPE COORD` = 4)씩 늘어나므로 차례로 0, 4, 8번째 바이트의 원소를 가리킨다. 루프가 끝나면 세 점이 (1,1), (2,2), (3,3)이 된다.

### 정렬된 필드의 성능 (Performance of Aligned Structure Members)

교재는 정렬하지 않은 `EmployeeBad`와 정렬한 `Employee`로 같은 일을 하는 루프의 시간을 비교한다. 두 필드에 값을 쓰는 일을 약 43억 번(ECX = 0FFFFFFFFh) 반복한다.

```asm
.data
ALIGN DWORD
startTime DWORD ?                   ; align startTime
emp Employee <>                     ; or: emp EmployeeBad <>
.code
    call GetMSeconds                ; get starting time
    mov  startTime,eax
    mov  ecx,0FFFFFFFFh             ; loop counter
L1: mov  emp.Years,5
    mov  emp.SalaryHistory,35000
    loop L1
    call GetMSeconds                ; get ending time
    sub  eax,startTime
    call WriteDec                   ; display elapsed time
```

> [!NOTE]
> 슬라이드 11번은 두 번째 `call GetMSeconds`에도 `; get starting time`이라는 주석을 달았다(교재 예제 `Struct1.asm`도 같다). 루프가 끝난 뒤의 시각이므로 **ending time**이 맞다.

교재 예제 `Struct1.asm`의 주석에 적힌 결과는 `Employee`가 6141ms, `EmployeeBad`가 6203ms로, 차이가 1%밖에 나지 않는다. 같은 일(WORD 하나와 DWORD 하나를 쓰는 루프 10억 번)을 C로 옮겨 직접 재 보면 이유를 알 수 있다(이 문서를 만든 환경의 Intel Xeon 2.1GHz, 세 번 잰 범위).

| 필드 위치 | 시간 |
|---|---|
| `Employee` (Years 40, SalaryHistory 44: 모두 정렬됨) | 750~837ms |
| `EmployeeBad` (Years 39, SalaryHistory 41: 정렬 안 됨, 같은 캐시 줄 안) | 747~791ms |
| `EmployeeBad`인데 SalaryHistory가 64바이트 캐시 줄 경계에 걸침 | 1100~1201ms |

최근의 x86 프로세서는 정렬되지 않은 접근도 **같은 캐시 줄(64바이트) 안**에 있으면 정렬된 접근과 거의 같은 속도로 처리한다. 느려지는 것은 4바이트 값이 두 캐시 줄에 걸쳐 있을 때로, 이 측정에서는 약 1.5배 느려졌다. 정렬해 두면 어떤 주소에 놓이든 이런 경계 걸침이 생기지 않으므로, 정렬은 여전히 좋은 습관이다. 또한 SSE의 `MOVAPS`처럼 정렬되지 않은 주소에서 예외를 일으키는 명령어도 있다.

### 예: 시스템 시간 표시 (Example: Displaying the System Time)

Windows API 함수 두 개가 구조체를 쓴다. `SetConsoleCursorPosition`은 커서 위치를 `COORD`로 받고, `GetLocalTime`은 현재 날짜와 시각을 `SYSTEMTIME` 구조체에 채워 준다. 두 구조체는 `SmallWin.inc`에 정의되어 있다.

```text
SYSTEMTIME STRUCT
    wYear         WORD ?
    wMonth        WORD ?
    wDayOfWeek    WORD ?     ; 0 = 일요일
    wDay          WORD ?
    wHour         WORD ?
    wMinute       WORD ?
    wSecond       WORD ?
    wMilliseconds WORD ?
SYSTEMTIME ENDS
```

```asm
; Structures                  (ShowTime.ASM)
INCLUDE Irvine32.inc
.data
sysTime SYSTEMTIME <>
XYPos   COORD <10,5>
consoleHandle DWORD ?
colonStr BYTE ":",0
.code
main PROC
; Get the standard output handle for the Win32 Console.
    INVOKE GetStdHandle, STD_OUTPUT_HANDLE
    mov  consoleHandle,eax
; Set the cursor position and get the system time.
    INVOKE SetConsoleCursorPosition, consoleHandle, XYPos
    INVOKE GetLocalTime, ADDR sysTime
; Display the system time (hh:mm:ss).
    movzx eax,sysTime.wHour         ; hours
    call WriteDec
    mov  edx,OFFSET colonStr        ; ":"
    call WriteString
    movzx eax,sysTime.wMinute       ; minutes
    call WriteDec
    call WriteString
    movzx eax,sysTime.wSecond       ; seconds
    call WriteDec
    call Crlf
    call WaitMsg                    ; "Press any key..."
    exit
main ENDP
END main
```

실행 결과(실행한 시각이 나온다. 커서 이동은 반영하지 않았다):

```text
…:…:…
Press any key to continue...
```

- 필드는 `sysTime.wHour`처럼 변수 이름으로 접근한다. WORD 필드를 `WriteDec`으로 출력하려고 `MOVZX`로 EAX 전체에 넓혔다.
- 두 번째 `WriteString` 앞에서 EDX를 다시 설정하지 않았다. `WriteDec`과 `WriteString`이 EDX를 바꾸지 않으므로 EDX는 여전히 `":"`를 가리킨다.
- `WriteDec`은 앞에 0을 채우지 않으므로 9시 5분 3초는 `09:05:03`이 아니라 `9:5:3`으로 출력된다. 두 자리로 맞추는 방법은 [부록 F 연습 2](#연습-2-시각을-두-자리씩-출력하기)에서 다룬다.

#### 구조체를 값으로 넘기기 (보충)

`SetConsoleCursorPosition`의 두 번째 매개변수는 `COORD` **구조체 자체**(값)다. `COORD`는 4바이트이므로 `INVOKE`는 이것을 DWORD 하나로 스택에 넣는다. 아래 2바이트가 X, 위 2바이트가 Y다(리틀 엔디언).

목록 파일에서 INVOKE가 만든 코드:

```text
0000000C                                INVOKE SetConsoleCursorPosition, consoleHandle, XYPos
0000000C FF35 00000000o     *    push XYPos
00000012 FF35 00000000o     *    push consoleHandle
00000018 E8 FFFFFFFCr       *    call SetConsoleCursorPosition
```

`*`가 붙은 줄은 어셈블러가 만들어 넣은 코드다. 인수는 오른쪽부터 넣으므로 `XYPos`(5 × 10000h + 10 = 0005000Ah)가 먼저 스택에 들어간다.

### 구조체를 포함한 구조체 (Structures Containing Structures)

구조체의 필드가 다른 구조체일 수 있다. 사각형은 왼쪽 위와 오른쪽 아래 두 점으로 정해진다.

```asm
Rectangle STRUCT
    UpperLeft  COORD <>
    LowerRight COORD <>
Rectangle ENDS
.data
rect1 Rectangle < >
rect2 Rectangle { }
rect3 Rectangle { {10,10}, {50,20} }
rect4 Rectangle < <10,10>, <50,20> >
.code
mov  eax,SIZEOF Rectangle                   ; EAX = 8
mov  rect1.UpperLeft.X, 10                  ; rect1.UpperLeft.X = 10
mov  esi,OFFSET rect1
mov  (Rectangle PTR [esi]).UpperLeft.Y, 10  ; rect1.UpperLeft.Y = 10
mov  edi,OFFSET rect2.LowerRight
mov  (COORD PTR [edi]).X, 50                ; rect2.LowerRight.X = 50
mov  edi,OFFSET rect2.LowerRight.X
mov  WORD PTR [edi], 50
mov  ax,rect4.LowerRight.Y                  ; AX = 20, WORD PTR rect3 = [10, 10, 50, 20]
```

- 안쪽 구조체의 초기값은 중괄호나 꺾쇠괄호를 한 번 더 써서 준다(`{ {10,10}, {50,20} }`, `< <10,10>, <50,20> >`).
- 필드 이름을 점(`.`)으로 이어 쓰면 안쪽 필드까지 들어간다. `rect1.UpperLeft.X`의 오프셋은 0 + 0 = 0, `rect2.LowerRight.X`는 4 + 0 = 4다.
- 레지스터로 가리킬 때는 바깥 구조체(`Rectangle PTR [esi]`)로 지정하고 필드를 이어 쓰거나, 안쪽 구조체의 주소를 구해 그 형식(`COORD PTR [edi]`)으로 지정한다. 마지막 두 줄처럼 필드 하나의 주소를 구해 `WORD PTR`로 써도 된다.

### 예: 술 취한 사람의 걸음 (Example: Drunkard's Walk)

교재의 Drunkard's Walk 프로그램은 대학 교수가 술에 취해 집으로 걸어가는 모습을 흉내 낸다. 교수는 좌표 (25, 25)에서 출발해 매번 무작위로 동, 서, 남, 북 중 한 방향으로 한 칸씩 움직인다(교재 Figure 10-1). 지나간 경로는 `COORD` 배열을 담은 구조체에 기록한다.

```asm
; Drunkard's Walk (Walk.asm)
; Drunkard's walk program. The professor starts at
; coordinates 25, 25 and wanders around the immediate area.
INCLUDE Irvine32.inc
WalkMax = 50
StartX = 25
StartY = 25
DrunkardWalk STRUCT
    path COORD WalkMax DUP(<0,0>)
    pathsUsed WORD 0
DrunkardWalk ENDS
DisplayPosition PROTO currX:WORD, currY:WORD
.data
aWalk DrunkardWalk <>
.code
main PROC
    mov  esi,OFFSET aWalk
    call TakeDrunkenWalk            ; aWalk.pathsUsed = 50, WORD PTR aWalk.path = [25, 25, 24, 25, 23, 25]
    exit
main ENDP

;------------------------------------------------------
TakeDrunkenWalk PROC
    LOCAL currX:WORD, currY:WORD
;
; Takes a walk in random directions (north, south, east,
; west).
; Receives: ESI points to a DrunkardWalk structure
; Returns:  the structure is initialized with random values
;------------------------------------------------------
    pushad
; Use the OFFSET operator to obtain the address of the
; path, the array of COORD objects, and copy it to EDI.
    mov  edi,esi
    add  edi,OFFSET DrunkardWalk.path
    mov  ecx,WalkMax                ; loop counter
    mov  currX,StartX               ; current X-location
    mov  currY,StartY               ; current Y-location
Again:
    ; Insert current location in array.
    mov  ax,currX
    mov  (COORD PTR [edi]).X,ax
    mov  ax,currY
    mov  (COORD PTR [edi]).Y,ax
    INVOKE DisplayPosition, currX, currY
    mov  eax,4                      ; choose a direction (0-3)
    call RandomRange
    .IF eax == 0                    ; North
        dec currY
    .ELSEIF eax == 1                ; South
        inc currY
    .ELSEIF eax == 2                ; West
        dec currX
    .ELSE                           ; East (EAX는 3)
        inc currX
    .ENDIF
    add  edi,TYPE COORD             ; point to next COORD
    loop Again
Finish:
    mov  (DrunkardWalk PTR [esi]).pathsUsed, WalkMax
    popad
    ret
TakeDrunkenWalk ENDP

;------------------------------------------------------
DisplayPosition PROC currX:WORD, currY:WORD
; Display the current X and Y positions.
;------------------------------------------------------
.data
commaStr BYTE ",",0
.code
    pushad
    movzx eax,currX                 ; current X position
    call WriteDec
    mov  edx,OFFSET commaStr        ; "," string
    call WriteString
    movzx eax,currY                 ; current Y position
    call WriteDec
    call Crlf
    popad
    ret
DisplayPosition ENDP
END main
```

<details>
<summary>실행 결과 (50줄) 펼치기</summary>

실행 결과(`Randomize`를 부르지 않았으므로 매번 같은 경로가 나온다):

```text
25,25
24,25
23,25
24,25
24,26
25,26
25,25
24,25
24,24
24,25
23,25
23,24
23,25
23,24
23,23
23,24
23,25
23,26
22,26
21,26
22,26
23,26
23,27
22,27
22,26
21,26
21,25
21,26
20,26
19,26
20,26
21,26
22,26
23,26
24,26
24,27
23,27
22,27
21,27
20,27
20,26
19,26
18,26
17,26
18,26
19,26
18,26
18,27
18,28
17,28
```

</details>

- `OFFSET DrunkardWalk.path`는 구조체 안에서 `path` 필드의 오프셋(0)이다. 구조체의 주소(ESI)에 이 값을 더해 경로 배열의 주소를 EDI에 만든다. `path`가 첫 필드라 0이지만, 이렇게 써 두면 필드 순서가 바뀌어도 코드를 고칠 필요가 없다.
- `(COORD PTR [edi]).X`로 배열의 각 원소에 좌표를 기록하고, `add edi,TYPE COORD`로 다음 원소로 옮긴다.
- `RandomRange`(EAX = 4)는 0~3을 돌려주고, 이 값에 따라 `.IF`/`.ELSEIF`로 방향을 고른다. `.IF`는 6장의 고급 조건문으로, 실행할 때 EAX를 비교한다. 이 장 뒤에서 나오는 어셈블할 때의 `IF`와 다르다.
- 출력되는 좌표는 움직이기 **전**의 위치이므로 첫 줄은 출발점 (25, 25)다. 루프가 끝나면 `pathsUsed`에 50을 넣는다.

#### WORD 매개변수는 스택에서 몇 바이트일까 (보충)

`DisplayPosition`의 매개변수는 WORD지만, 32비트 스택은 4바이트 단위로 쓰는 것이 원칙이다. JWasm은 WORD 인수 하나마다 `sub esp,2`로 2바이트를 비워 둔 뒤 `push`로 WORD를 넣어, 인수 하나가 4바이트를 차지하게 만든다. 그래서 `DisplayPosition` 안에서 `currX`는 `[ebp+8]`, `currY`는 `[ebp+12]`에 있다.

목록 파일에서 INVOKE가 만든 코드:

```text
0000003D                                INVOKE DisplayPosition, currX, currY
0000003D 83EC02             *    sub esp, 2
00000040 66FF75FC           *    push currY
00000044 83EC02             *    sub esp, 2
00000047 66FF75FE           *    push currX
0000004B E842000000         *    call DisplayPosition
```

`66` 접두사가 붙은 `push`는 16비트 값을 넣는 `PUSH`다. 위쪽 2바이트에는 쓰레기 값이 남지만 `DisplayPosition`은 `MOVZX`로 아래 2바이트만 읽으므로 문제가 없다. MASM이 만드는 코드는 이와 다를 수 있다.

### 공용체 선언과 사용 (Declaring and Using Unions)

구조체의 필드는 각자 다른 오프셋을 가지지만, **공용체의 필드는 모두 같은 오프셋(0)에서 시작한다**. 그래서 공용체의 크기는 가장 긴 필드의 크기와 같다.

```text
unionname UNION                 structname STRUCT
    union-fields                    structure-fields
unionname ENDS                      UNION unionname
                                        union-fields
                                    ENDS
                                structname ENDS
```

왼쪽은 독립된 공용체 형식이고, 오른쪽은 구조체 안에 공용체를 넣는 형식이다. 구조체 안에 넣을 때는 `UNION`과 `ENDS` 사이에 공용체 이름(필드 이름)을 `UNION` 뒤에 쓰고, `ENDS` 앞에는 이름을 쓰지 않는다.

공용체의 필드 선언 규칙은 구조체와 같지만, 각 필드는 **초기값을 하나만** 가질 수 있다.

```asm
Integer UNION
    D DWORD 0
    W WORD  0
    B BYTE  0
Integer ENDS

mov  eax,SIZEOF Integer                     ; EAX = 4
mov  eax,OFFSET Integer.D                   ; EAX = 0
mov  ebx,OFFSET Integer.B                   ; EBX = 0
```

**일관성 있게 쓰기** (Be Consistent). 필드마다 다른 초기값을 주면 **첫 번째 필드의 초기값만** 쓰이고 나머지는 무시된다. 그러니 초기값을 준다면 모두 같은 값을 주는 것이 좋다.

```asm
Integer UNION
    D DWORD 1
    W WORD  5
    B BYTE  8
Integer ENDS
.data
myInt Integer <>
.code
mov  eax,myInt.D                            ; EAX = 1
mov  bx,myInt.W                             ; BX = 1
mov  cl,myInt.B                             ; CL = 1
```

`W`와 `B`에 준 5와 8은 무시되고, 세 필드 모두 같은 메모리(값 1)를 본다.

**구조체 안의 공용체** (Structure Containing a Union). 다음 두 정의는 같은 배치를 만든다. 첫 번째는 미리 정의한 `Integer` 공용체를 필드 형식으로 쓰고, 두 번째는 구조체 안에 공용체를 직접 정의한다.

```asm
Integer UNION
    D DWORD 0
    W WORD  0
    B BYTE  0
Integer ENDS

FileInfo1 STRUCT
    FileID   Integer <>
    FileName BYTE 64 DUP(?)
FileInfo1 ENDS

FileInfo2 STRUCT
    UNION FileID
        D DWORD ?
        W WORD  ?
        B BYTE  ?
    ENDS
    FileName BYTE 64 DUP(?)
FileInfo2 ENDS

mov  eax,SIZEOF FileInfo1                   ; EAX = 68
mov  ebx,SIZEOF FileInfo2                   ; EBX = 68
mov  ecx,OFFSET FileInfo2.FileName          ; ECX = 4
mov  edx,OFFSET FileInfo2.FileID.B          ; EDX = 0
```

공용체 `FileID`가 4바이트(가장 큰 `D`)를 차지하므로 `FileName`은 오프셋 4에서 시작한다. (교재와 슬라이드는 두 정의 모두 이름을 `FileInfo`로 썼는데, 같은 프로그램에 둘 다 넣을 수는 없으므로 여기서는 `FileInfo1`, `FileInfo2`로 구분했다.)

**공용체 변수 선언과 사용** (Declaring and Using Union Variables). 공용체 변수는 구조체 변수와 같은 방식으로 선언하고 초기화하지만, **초기값은 하나만** 줄 수 있다. 그 값은 첫 번째 필드에 들어간다.

```asm
.data
val1 Integer <12345678h>
val2 Integer <100h>
val3 Integer <>
val4 Integer <1,2>                          ; 어셈블 오류
.code
mov  eax,87654321h
mov  val3.B, al                             ; val3.D = 21h
mov  val3.W, ax                             ; val3.D = 4321h
mov  val3.D, eax                            ; val3.D = 87654321h
mov  bx,val1.W                              ; BX = 5678h
mov  cl,val1.B                              ; CL = 78h
mov  dx,val2.W                              ; DX = 0100h
```

- 실행할 명령어에서 공용체 변수를 쓸 때는 반드시 필드 이름(`val3.B`, `val3.W`, `val3.D`)을 붙여 어떤 크기로 접근할지 정한다.
- `val1.W`와 `val1.B`는 `12345678h`의 **아래쪽** 2바이트, 1바이트다. x86은 리틀 엔디언이라 낮은 바이트가 낮은 주소(오프셋 0)에 있기 때문이다.
- 초기값을 두 개 주면(`val4`) JWasm은 `Too many initial values for structure` 오류를 낸다.

**구조체를 포함한 공용체.** 공용체의 필드가 구조체일 수도 있다. Windows API의 `INPUT_RECORD`는 키보드, 마우스, 창 크기 변경 등 여러 종류의 입력 이벤트를 하나의 형식으로 담으려고, 이벤트 종류마다 다른 구조체를 공용체로 겹쳐 놓았다. `SmallWin.inc`의 정의는 다음과 같다.

```text
INPUT_RECORD STRUCT
    EventType WORD ?
    ALIGN DWORD
    UNION Event
        KEY_EVENT_RECORD <>
        MOUSE_EVENT_RECORD <>
        WINDOW_BUFFER_SIZE_RECORD <>
        MENU_EVENT_RECORD <>
        FOCUS_EVENT_RECORD <>
    ENDS
INPUT_RECORD ENDS
```

> [!NOTE]
> **슬라이드 정정**: 슬라이드 21번에는 세 번째 멤버가 `WINDOW BUFFER SIZE RECORD`처럼 밑줄 없이 띄어 쓰여 있다. 이름 안에 공백이 있을 수 없으므로 `WINDOW_BUFFER_SIZE_RECORD`가 맞다.

공용체의 멤버에 필드 이름 없이 구조체 형식만 쓰면(익명 멤버), 그 구조체의 필드를 공용체 이름 다음에 바로 이어 쓸 수 있다.

```asm
.data
inRec INPUT_RECORD <>
.code
mov  eax,SIZEOF INPUT_RECORD                        ; EAX = 20
mov  ebx,OFFSET INPUT_RECORD.Event                  ; EBX = 4
mov  ecx,OFFSET INPUT_RECORD.Event.wVirtualKeyCode  ; ECX = 10
mov  edx,OFFSET INPUT_RECORD.Event.dwMousePosition  ; EDX = 4
mov  inRec.EventType,1
mov  ax,inRec.EventType                             ; AX = 1
```

`EventType`(2바이트) 다음에 `ALIGN DWORD`가 2바이트를 채워 공용체 `Event`는 오프셋 4에서 시작한다. 공용체의 크기는 가장 큰 멤버인 `KEY_EVENT_RECORD`, `MOUSE_EVENT_RECORD`의 16바이트이므로 전체는 4 + 16 = 20바이트다. 키보드 이벤트의 `wVirtualKeyCode`(이벤트 안에서 오프셋 6)와 마우스 이벤트의 `dwMousePosition`(오프셋 0)이 같은 메모리를 겹쳐 쓴다. 프로그램은 먼저 `EventType`을 보고 어느 멤버로 해석할지 정한다.

### 공용체로 바이트 들여다보기 (보충)

슬라이드 22번은 비어 있으므로, 공용체 안에 구조체를 넣어 DWORD 하나를 여러 단위로 나눠 보는 예를 덧붙인다. 4장의 리틀 엔디언 저장 순서를 눈으로 확인할 수 있다.

```asm
Bytes4 STRUCT
    b0 BYTE ?
    b1 BYTE ?
    b2 BYTE ?
    b3 BYTE ?
Bytes4 ENDS

Split UNION
    D DWORD ?
    W WORD  ?
    B Bytes4 <>
Split ENDS
.data
v Split <12345678h>
.code
mov  eax,v.D                                ; EAX = 12345678h
mov  bx,v.W                                 ; BX = 5678h
mov  cl,v.B.b0                              ; CL = 78h
mov  dl,v.B.b3                              ; DL = 12h
mov  v.B.b3,0FFh                            ; v.D = 0FF345678h
```

`v.B.b3`(오프셋 3)는 가장 높은 바이트이므로, 여기에 0FFh를 쓰면 DWORD 값의 맨 앞 두 자리가 바뀐다. 이런 공용체는 네트워크 주소(IPv4 주소 4바이트)나 색상 값(RGBA)처럼 "전체 값"과 "부분"을 번갈아 다룰 때 쓸모가 있다.

---

## 10.2 매크로 (Macros)

### 개요 (Overview)

**매크로 프로시저**(macro procedure)는 어셈블리 문장들에 이름을 붙인 것이다. 매크로를 호출하면 그 자리에 매크로의 코드가 **그대로 복사되어 들어간다**. 이렇게 코드를 자동으로 끼워 넣는 것을 **인라인 확장**(inline expansion)이라고 한다. 이 장에서 "매크로"라고 하면 매크로 프로시저를 가리킨다.

**배치** (Placement). 매크로 정의는 보통 소스 파일의 앞부분에 두거나, 별도의 파일에 모아 두고 `INCLUDE` 지시어로 가져온다. 매크로는 어셈블러의 **전처리 단계**(preprocessing step)에서 펼쳐지므로, 호출하기 **전에** 정의되어 있어야 한다.

```asm
PrintX MACRO
    mov  al,'X'
    call WriteChar
ENDM
.code
PrintX
```

목록 파일에서 확인한 확장 결과:

```text
                                PrintX
00000000 B058                1      mov  al,'X'
00000002 E8 FFFFFFFCr        1      call WriteChar
```

실행 결과:

```text
X
```

목록 파일(`.lst`)에서 매크로 호출 줄 아래의 `1`은 **확장 수준**(1단계 확장으로 생긴 줄)이라는 뜻이다. 매크로 정의만 있고 호출하지 않으면 코드는 하나도 생기지 않는다. 정의는 어셈블러에게 "이런 텍스트를 이 이름으로 기억해 두라"는 지시일 뿐이다.

#### 매크로와 프로시저 비교 (보충)

| | 매크로 | 프로시저 |
|---|---|---|
| 코드가 생기는 때 | 호출할 때마다 펼쳐져 **복사된다** | 한 번만 존재하고 `CALL`로 실행한다 |
| 실행 시 부담 | `CALL`/`RET`, 인수 `PUSH`가 없다 | `CALL`/`RET`과 인수 전달 비용이 있다 |
| 프로그램 크기 | 호출 횟수만큼 커진다 | 호출해도 커지지 않는다 |
| 인수 | **텍스트**로 치환된다(레지스터, 변수, 상수, 명령어 조각 무엇이든) | 값이나 주소가 스택·레지스터로 전달된다 |
| 레이블 | `LOCAL`로 선언하지 않으면 두 번째 호출에서 이름이 겹친다 | 프로시저 안의 레이블은 한 번만 정의된다 |
| 디버깅 | 목록 파일이나 역어셈블로 펼친 모습을 확인해야 한다 | 소스와 실행 코드가 일대일로 대응한다 |
| 잘 맞는 곳 | 짧고 자주 쓰는 코드, 프로시저 호출을 감싸는 껍데기 | 길거나 여러 곳에서 쓰는 복잡한 처리 |

### 매크로 정의 (Defining Macros)

```text
macroname MACRO parameter-1, parameter-2...
    statement-list
ENDM
```

**매개변수** (Parameters). 매크로 매개변수는 호출하는 쪽이 넘기는 **텍스트 인수의 자리 표시자**다. 인수는 실제로는 정수, 변수 이름, 레지스터 이름 등일 수 있지만, 전처리기는 그것을 모두 **텍스트**로 다룬다. 매개변수 이름이 나오는 자리에 인수의 텍스트가 그대로 들어간다.

```asm
mPutchar MACRO char
    push eax
    mov  al,char
    call WriteChar
    pop  eax
ENDM
```

`mPutchar`는 문자 하나를 출력한다. `WriteChar`가 AL을 쓰므로 EAX를 저장했다가 복원해, 호출한 쪽의 EAX가 바뀌지 않게 했다.

#### 인수는 값이 아니라 텍스트다 (보충)

인수가 계산되지 않고 **글자 그대로** 들어간다는 점은 의외의 결과를 낳기도 한다. 다음 매크로에 `2+1`을 넘기면 3 × 3 = 9가 아니라 `2+1*2+1` = 5가 된다. 곱셈이 덧셈보다 먼저 계산되기 때문이다. 매개변수를 괄호로 감싸면 의도대로 된다. C의 `#define` 매크로에서도 똑같은 실수가 생긴다([부록 B](#부록-b-c-컴파일러가-만든-구조체-코드와-c의-매크로)).

```asm
mSquareBad MACRO x
    mov  eax,x*x
ENDM
mSquare MACRO x
    mov  eax,(x)*(x)
ENDM

mSquareBad 2+1                      ; EAX = 5
mSquare 2+1                         ; EAX = 9
```

### 매크로 호출 (Invoking Macros)

매크로는 프로그램에 이름을 쓰고, 필요하면 뒤에 인수를 적어서 호출한다.

```text
macroname argument-1, argument-2, ...
```

매크로 이름은 소스 코드에서 **이 지점보다 앞에** 정의된 매크로여야 한다. 각 인수는 매크로 안의 매개변수를 대신하는 텍스트 값이다. 인수 개수가 매개변수보다 적으면 남은 매개변수는 빈 텍스트가 된다.

```asm
mPutchar MACRO char
    push eax
    mov  al,char
    call WriteChar
    pop  eax
ENDM
.code
    mPutchar 'A'
    mov  al,'A'
    mov  ecx,20
L1: mPutchar al                     ; macro call
    inc  al
    loop L1                         ; 끝나면 AL = 55h
```

목록 파일에서 확인한 확장 결과:

```text
                                    mPutchar 'A'
00000000 50                  1      push eax
00000001 B041                1      mov  al,'A'
00000003 E8 FFFFFFFCr        1      call WriteChar
00000008 58                  1      pop  eax
00000009 B041                       mov  al,'A'
0000000B B914000000                 mov  ecx,20
00000010                        L1: mPutchar al                     ; macro call
00000010 50                  1      push eax
00000011 8AC0                1      mov  al,al
00000013 E8 FFFFFFFCr        1      call WriteChar
00000018 58                  1      pop  eax
```

실행 결과:

```text
AABCDEFGHIJKLMNOPQRST
```

- 첫 호출 `mPutchar 'A'`에서는 매개변수 `char`가 `'A'`로 바뀌어 `mov al,'A'`가 된다.
- 루프 안의 `mPutchar al`에서는 `mov al,al`이 된다. 쓸데없는 명령어지만 해는 없다. 매크로는 인수가 무엇인지 따지지 않고 텍스트를 바꿔 넣을 뿐이다.
- 매크로는 `PUSH EAX`/`POP EAX`로 EAX를 지키므로 루프의 `inc al`이 제대로 동작해, A부터 T까지 20글자가 출력된다.

### 매크로 디버깅 (Debugging Macros)

매크로를 쓴 프로그램은 소스 코드만 봐서는 실제로 어떤 명령어가 생겼는지 알기 어렵다. 어셈블한 뒤에는 **목록 파일**(확장자 `.LST`)을 열어 각 매크로가 의도한 대로 펼쳐졌는지 확인한다. Visual Studio에서는 디버거를 시작한 뒤 코드 창에서 오른쪽 버튼을 눌러 **Go to Disassembly**를 고르면, 매크로 호출 줄마다 그 매크로가 만든 코드가 이어서 표시된다.

교재 예제 `Macro1.asm`의 `mWriteAt`는 두 매크로(`mGotoxy`, `mWrite`)를 이어 부르는 매크로다. 슬라이드 26번은 `mWriteAt 15,10,"Hi there"`를 Visual Studio에서 역어셈블한 모습이다.

```text
mWriteAt 15,10,"Hi there"
    push  edx
    mov   dh,0Ah
    mov   dl,0Fh
    call  _Gotoxy@0 (401551h)
    pop   edx
    push  edx
    mov   edx,offset ??0000 (405004h)
    call  _WriteString@0 (401D64h)
    pop   edx
```

- `mov dh,0Ah`/`mov dl,0Fh`: 인수 10과 15가 16진수로 표시되었다(`mGotoxy`는 DH에 행, DL에 열을 넣는다).
- `_Gotoxy@0`: STDCALL 규약으로 꾸며진 이름(8장)이다. 매개변수가 없어 `@0`이다.
- `??0000`: `mWrite`가 `LOCAL`로 만든 문자열 레이블이다(아래 LOCAL 지시어 참고). 괄호 안의 주소는 실행 파일에서의 실제 위치다.

### 추가 기능 (Additional Macro Features)

**필수 매개변수** (Required Parameters). 매개변수 뒤에 `:REQ`를 붙이면 반드시 인수를 넘겨야 한다. 인수 없이 호출하면 어셈블러가 오류를 낸다.

```asm
mPutchar MACRO char:REQ
    push eax
    mov  al,char
    call WriteChar
    pop  eax
ENDM
.code
    mPutchar 'A'
    mPutchar                        ; 어셈블 오류
```

JWasm은 `Missing macro argument: mPutchar, parameter 1` 오류를 낸다. `:REQ`가 없으면 `mPutchar`만 써도 오류 없이 `mov al,`이 만들어진다. 그러면 매크로 정의가 아니라 **펼쳐진 줄**에서 문법 오류가 나므로, 원인을 찾기가 훨씬 어렵다.

**매크로 주석** (Macro Comments). 매크로 정의 안의 보통 주석(`;`)은 매크로가 펼쳐질 때마다 같이 펼쳐진다. 정의 안에만 남기고 펼친 결과에는 나타나지 않게 하려면 세미콜론을 **두 개**(`;;`) 쓴다.

```asm
mPutchar MACRO char:REQ
    push eax                ;; reminder: char must contain 8 bits
    mov  al,char
    call WriteChar
    pop  eax
ENDM
```

> [!NOTE]
> 슬라이드 27번의 설명("Ordinary comment lines appearing in a macro definition appear each time the macro is expanded")은 `;` 주석에 대한 것이고, 예제의 `;;` 주석은 그 반대로 확장 결과에 나타나지 **않게** 하는 주석이다. 슬라이드에는 이 구분이 빠져 있다. Microsoft 문서에 따르면 MASM의 목록 파일은 `;;` 주석을 확장된 자리에 보여 주지 않는다. 다만 JWasm의 목록 파일에는 `;;` 주석도 나타나고, 주석 속의 매개변수나 `LOCAL` 이름까지 바뀌어 들어간다(아래 `mWrite`의 목록 파일에서 `;; define the ??0000`). 이 부분은 어셈블러에 따라 다르다.

**ECHO 지시어** (ECHO Directive). `ECHO`는 **어셈블하는 동안** 문자열을 표준 출력(콘솔 창)에 쓴다. 매크로가 언제, 몇 번 펼쳐지는지 확인할 때 쓸모가 있다.

```asm
mPutchar MACRO char:REQ
    ECHO Expanding the mPutchar macro
    push eax
    mov  al,char
    call WriteChar
    pop  eax
ENDM
.code
    mPutchar 'A'
    mPutchar 'B'
```

어셈블할 때 콘솔에 나오는 내용:

```text
Expanding the mPutchar macro
Expanding the mPutchar macro
```

실행 결과:

```text
AB
```

`ECHO`는 실행 파일에 아무 코드도 만들지 않는다. 메시지는 프로그램을 **실행할 때가 아니라 어셈블할 때** 한 번 나온다는 점에 주의하자.

**LOCAL 지시어** (LOCAL Directive). 매크로 정의에는 레이블이 들어가는 경우가 많다. 다음 `makeString` 매크로는 `string`이라는 변수를 선언하고 문자 배열로 초기화한다.

```asm
makeString MACRO text
    .data
    string BYTE text,0
ENDM

    makeString "Hello"
    makeString "Goodbye"            ; 어셈블 오류
```

이 매크로를 두 번 호출하면 `string`이 두 번 정의되므로 두 번째 호출에서 오류가 난다(JWasm: `Symbol already defined: string`). 매크로 안의 레이블을 `LOCAL`로 선언하면, 어셈블러가 호출할 때마다 `??0000`, `??0001`처럼 **겹치지 않는 이름**을 새로 만들어 바꿔 넣는다.

```asm
makeString MACRO text
    LOCAL string
    .data
    string BYTE text,0
ENDM

    makeString "Hello"
    makeString "Goodbye"
```

목록 파일에서 확인한 확장 결과:

```text
                                    makeString "Hello"
                             1      .data
00000000 48656C6C6F00        1      ??0000 BYTE "Hello",0
                                    makeString "Goodbye"
                             1      .data
00000006 476F6F6462796500    1      ??0001 BYTE "Goodbye",0
```

`LOCAL` 지시어는 매크로 본문의 다른 문장보다 **먼저** 와야 한다. 앞에 주석이 있는 것은 괜찮지만, 명령어 다음에 `LOCAL`을 쓰면 JWasm은 `PROC, MACRO or macro loop directive must precede LOCAL` 오류를 낸다.

> [!WARNING]
> `makeString`은 `.data`로 바꾼 뒤 `.code`로 돌아오지 않는다. 코드 중간에서 호출하면 그 뒤의 명령어가 데이터 세그먼트에 들어가고, 프로시저 끝의 `ENDP`가 다른 세그먼트에 있게 되어 JWasm은 `Unmatched block nesting` 오류를 낸다. 슬라이드의 예는 `LOCAL`을 설명하려고 짧게 줄인 것이다. 실제로 쓸 매크로는 다음의 `mWrite`처럼 끝에서 `.code`로 돌아와야 한다.

**코드와 데이터를 함께 담은 매크로** (Macros Containing Code and Data). 매크로는 코드와 데이터를 함께 담는 경우가 많다. 다음 `mWrite`는 문자열 리터럴을 받아 데이터 세그먼트에 문자열을 만들고, 코드 세그먼트로 돌아와 그것을 출력한다.

```asm
mWrite MACRO text
    LOCAL string                    ;; local label
    .data
    string BYTE text,0              ;; define the string
    .code
    push edx
    mov  edx,OFFSET string
    call WriteString
    pop  edx
ENDM
.code
    mWrite "Please enter your first name"
    mWrite "Please enter your last name"
```

목록 파일에서 확인한 확장 결과:

```text
                                    mWrite "Please enter your first name"
                             1      .data
00000000 506C6561736520656E  1      ??0000 BYTE "Please enter your first name",0              ;; define the ??0000
                             1      .code
00000000 52                  1      push edx
00000001 BA 00000000o        1      mov  edx,OFFSET ??0000
00000006 E8 FFFFFFFCr        1      call WriteString
0000000B 5A                  1      pop  edx
                                    mWrite "Please enter your last name"
                             1      .data
0000001D 506C6561736520656E  1      ??0001 BYTE "Please enter your last name",0              ;; define the ??0001
                             1      .code
0000000C 52                  1      push edx
0000000D BA 00000000o        1      mov  edx,OFFSET ??0001
00000012 E8 FFFFFFFCr        1      call WriteString
00000017 5A                  1      pop  edx
```

실행 결과:

```text
Please enter your first namePlease enter your last name
```

두 호출이 펼쳐질 때 문자열마다 겹치지 않는 레이블(`??0000`, `??0001`)이 붙고, `MOV` 명령어도 그 레이블을 가리키도록 바뀐다. 두 문자열 사이에 줄바꿈이 없으므로 출력은 한 줄로 이어진다.

**중첩 매크로** (Nested Macros). 매크로 안에서 다른 매크로를 호출하는 것을 **중첩 매크로**(nested macro)라고 한다. 전처리기는 중첩된 매크로 호출을 만나면 그 자리에서 다시 펼친다. 바깥 매크로가 받은 인수는 그대로 안쪽 매크로에 전달된다.

```asm
mWrite MACRO text
    LOCAL string
    .data
    string BYTE text,0
    .code
    push edx
    mov  edx,OFFSET string
    call WriteString
    pop  edx
ENDM

mWriteln MACRO text
    mWrite text
    call Crlf
ENDM
.code
    mWriteln "My Sample Macro Program"
```

목록 파일에서 확인한 확장 결과:

```text
                                    mWriteln "My Sample Macro Program"
                             1      mWrite "My Sample Macro Program"
                             2      .data
00000000 4D792053616D706C65  2      ??0000 BYTE "My Sample Macro Program",0
                             2      .code
00000000 52                  2      push edx
00000001 BA 00000000o        2      mov  edx,OFFSET ??0000
00000006 E8 FFFFFFFCr        2      call WriteString
0000000B 5A                  2      pop  edx
0000000C E8 FFFFFFFCr        1      call Crlf
```

실행 결과:

```text
My Sample Macro Program
```

`mWriteln`이 펼쳐진 줄에는 `1`, 그 안에서 다시 펼쳐진 `mWrite`의 줄에는 `2`가 붙는다. 숫자가 곧 중첩 깊이다.

### 교재의 매크로 라이브러리 (Using the Book's Macro Library, 32-Bit Mode Only)

교재와 함께 제공되는 `Macros.inc`에는 Irvine32 라이브러리 프로시저를 감싼 매크로들이 들어 있다. `INCLUDE Irvine32.inc` 다음에 `INCLUDE Macros.inc`를 쓰면 된다.

| 매크로 | 매개변수 | 하는 일 |
|---|---|---|
| `mDump` | varName, useLabel | 변수의 이름과 기본 속성(주소, 개수, 크기)으로 메모리를 출력한다 |
| `mDumpMem` | address, itemCount, componentSize | 메모리 범위를 출력한다 (`DumpMem`을 감쌈) |
| `mGotoxy` | X, Y | 콘솔 창 버퍼에서 커서 위치를 정한다 |
| `mReadString` | varName | 키보드에서 문자열을 읽는다 |
| `mShow` | itsName, format | 변수나 레지스터를 여러 형식으로 출력한다 |
| `mShowRegister` | regName, regValue | 32비트 레지스터의 이름과 값을 16진수로 출력한다 |
| `mWrite` | text | 문자열 리터럴을 콘솔에 쓴다 |
| `mWriteSpace` | count | 공백을 하나 이상 쓴다 |
| `mWriteString` | buffer | 문자열 변수의 내용을 콘솔에 쓴다 |

이 매크로들은 대부분 프로시저 호출에 필요한 레지스터 준비와 저장·복원을 대신해 주는 **껍데기**(wrapper)다. 예를 들어 `mReadString`의 정의는 다음과 같다.

```text
mReadString MACRO varName:REQ
;
; Reads from standard input into a buffer.
; Receives: the name of the buffer. Avoid passing
;    ECX and EDX as arguments.
;------------------------------------------------------
    push ecx
    push edx
    mov  edx,OFFSET varName
    mov  ecx,SIZEOF varName
    call ReadString
    pop  edx
    pop  ecx
ENDM
```

버퍼의 크기를 `SIZEOF`로 직접 구해 `ReadString`에 넘기므로, 버퍼보다 긴 입력이 들어와도 넘치지 않는다. 대신 인수는 `OFFSET`과 `SIZEOF`를 붙일 수 있는 **변수 이름**이어야 한다. 주석의 "Avoid passing ECX and EDX"는, 매크로가 ECX와 EDX를 먼저 바꾸므로 그 레지스터를 인수로 넘기면 엉뚱한 값이 쓰인다는 경고다.

`mShow`는 레지스터나 변수의 값을 형식 문자(H: 16진수, D: 부호 없는 10진수, I: 부호 있는 10진수, B: 2진수, N: 줄바꿈)를 조합해 출력한다. 형식을 생략하면 `HIN`이다.

```asm
INCLUDE Irvine32.inc
INCLUDE Macros.inc
.data
wval WORD 0FFFEh
.code
main PROC
    mov  eax,-1234
    mShow eax                       ; 기본 형식 HIN
    mShow wval,HDIBN
    mov  ebx,1A2Bh
    mShowRegister EBX,ebx
    call Crlf
    exit
main ENDP
END main
```

실행 결과:

```text
  eax = FFFFFB2Eh  -1234d
  wval = FFFEh  65534d  -2d  1111 1111 1111 1110b
  EBX=00001A2B
```

`mShow`는 이름이 레지스터인지 변수인지를 `OPATTR` 연산자로 가려내고, 크기에 맞게 `MOVZX`/`MOVSX`로 값을 넓힌 뒤, 형식 문자열을 `FORC`(10.4절)로 한 글자씩 읽어 출력 코드를 만든다. 이 장에서 배우는 조건부 어셈블리와 반복 블록을 모두 쓴 매크로다.

### 예제 프로그램: Wrappers (Example Program: Wrappers)

`Wraps.asm`은 `Macros.inc`의 매크로로 사용자 이름을 입력받아 출력하고, 정수 배열을 메모리 덤프로 보여 준다.

```asm
; Procedure Wrapper Macros           (Wraps.asm)
; This program demonstrates macros as wrappers
; for library procedures. Contents: mGotoxy, mWrite,
; mWriteString, mReadString, and mDumpMem.
INCLUDE Irvine32.inc
INCLUDE Macros.inc                  ; macro definitions
.data
array DWORD 1,2,3,4,5,6,7,8
firstName BYTE 31 DUP(?)
lastName  BYTE 31 DUP(?)
.code
main PROC
    mGotoxy 0,0
    mWrite <"Sample Macro Program",0dh,0ah>
; Input the user's name.
    mGotoxy 0,5
    mWrite "Please enter your first name: "
    mReadString firstName
    call Crlf
    mWrite "Please enter your last name: "
    mReadString lastName
    call Crlf
; Display the user's name.
    mWrite "Your name is "
    mWriteString firstName
    mWriteSpace
    mWriteString lastName
    call Crlf
; Display the array of integers.
    mDumpMem OFFSET array, LENGTHOF array, TYPE array
    exit
main ENDP
END main
```

슬라이드 35번은 비어 있으므로 실행 결과를 싣는다. 이름으로 `Ada`, `Lovelace`를 입력했을 때의 실행 결과(커서 이동은 반영하지 않았다. 실제 콘솔에서는 `mGotoxy 0,5` 때문에 두 번째 줄이 6번째 행에 나온다):

```text
Sample Macro Program
Please enter your first name: Ada

Please enter your last name: Lovelace

Your name is Ada Lovelace

Dump of offset …
-------------------------------
00000001  00000002  00000003  00000004  00000005  00000006  00000007  00000008
```

- `mWrite <"Sample Macro Program",0dh,0ah>`: 문자열 뒤에 CR, LF를 붙이려면 인수 전체를 `< >`로 묶어야 한다. 묶지 않으면 쉼표 때문에 인수가 세 개로 나뉜다(10.3절의 텍스트 리터럴 연산자).
- `mReadString` 다음의 `call Crlf` 때문에 빈 줄이 하나씩 생긴다. 입력을 마치며 누른 Enter가 이미 줄을 바꿨기 때문이다.
- `mWriteSpace`는 인수를 생략하면 기본값 1(공백 하나)을 쓴다(`mWriteSpace MACRO count:=<1>`).
- `mDumpMem`의 주소(`Dump of offset …`)는 실행 환경마다 다르다.

---

## 10.3 조건부 어셈블리 지시어 (Conditional-Assembly Directives)

**조건부 어셈블리 지시어**는 조건에 따라 어떤 문장을 어셈블할지 말지를 정한다. 조건은 **어셈블할 때** 계산되므로, 실행 결과가 아니라 **어떤 코드가 만들어지는지**가 달라진다. 매크로 안에서 쓰면 인수를 검사해 경고를 내거나, 인수에 따라 다른 코드를 만들 수 있다. 일반적인 형식은 다음과 같다.

```text
IF condition
    statements
[ELSE
    statements]
ENDIF
```

교재 Table 10-3의 지시어는 다음과 같다.

| 지시어 | 어셈블하는 조건 |
|---|---|
| `IF expression` | 식의 값이 참(0이 아님)일 때. 관계 연산자 `LT`, `GT`, `EQ`, `NE`, `LE`, `GE`를 쓸 수 있다 |
| `IFB <argument>` | 인수가 **비어 있을** 때. 인수 이름을 꺾쇠괄호 `< >`로 감싸야 한다 |
| `IFNB <argument>` | 인수가 비어 있지 **않을** 때. 꺾쇠괄호로 감싼다 |
| `IFIDN <arg1>,<arg2>` | 두 인수가 같을 때. 대소문자를 **구분한다** |
| `IFIDNI <arg1>,<arg2>` | 두 인수가 같을 때. 대소문자를 **구분하지 않는다** |
| `IFDIF <arg1>,<arg2>` | 두 인수가 다를 때. 대소문자를 구분한다 |
| `IFDIFI <arg1>,<arg2>` | 두 인수가 다를 때. 대소문자를 구분하지 않는다 |
| `IFDEF name` | 이름이 정의되어 있을 때 |
| `IFNDEF name` | 이름이 정의되어 있지 않을 때 |
| `ENDIF` | 조건부 어셈블리 지시어로 시작한 블록을 끝낸다 |
| `ELSE` | 앞의 조건이 거짓이면 다음 `ENDIF`까지의 문장을 어셈블한다 |
| `ELSEIF expression` | 앞의 조건이 거짓이고 이 식이 참이면 `ENDIF`까지의 문장을 어셈블한다 |
| `EXITM` | 매크로를 즉시 빠져나가, 남은 매크로 문장을 펼치지 않는다 |

### 빠진 인수 검사 (Checking for Missing Arguments)

매크로는 인수가 비어 있는지 검사할 수 있다. 다음 `mWriteString`을 인수 없이 호출하면, 매크로 안의 `mov edx,OFFSET string`이 `mov edx,OFFSET`으로 펼쳐져 **펼쳐진 줄에서** 오류가 난다.

```asm
mWriteString MACRO string
    push edx
    mov  edx,OFFSET string
    call WriteString
    pop  edx
ENDM
.code
    mWriteString                    ; 어셈블 오류
```

MASM은 이 줄에서 `error A2081: missing operand after unary operator`를 낸다(슬라이드 37번). JWasm의 메시지는 다르다(`Syntax error`). 어느 쪽이든 오류가 매크로 정의 안의 어느 줄에서 났는지 짐작하기 어렵다. **`IFB`**(if blank) 지시어로 인수가 비었는지 먼저 확인하면 이런 오류를 막고, 무엇이 잘못됐는지 직접 알려 줄 수 있다.

```asm
mWriteString MACRO string
    IFB <string>
        ECHO -------------------------------------------
        ECHO *  Error: parameter missing in mWriteString
        ECHO *  (no code generated)
        ECHO -------------------------------------------
        EXITM
    ENDIF
    push edx
    mov  edx,OFFSET string
    call WriteString
    pop  edx
ENDM
.code
    mWriteString
```

어셈블할 때 콘솔에 나오는 내용:

```text
-------------------------------------------
*  Error: parameter missing in mWriteString
*  (no code generated)
-------------------------------------------
```

`EXITM`이 매크로를 빠져나가므로 `PUSH` 이하의 코드는 만들어지지 않는다. 이 메시지는 "경고"로 출력할 뿐 어셈블러의 오류가 아니므로, 어셈블은 성공한다는 점에 주의하자. 반드시 실패하게 하려면 `.ERR`(무조건 오류를 내는 지시어)을 함께 쓴다.

### 기본 인수 (Default Argument Initializers)

매크로 매개변수에는 기본 인수를 줄 수 있다. 호출할 때 그 인수가 빠지면 기본값이 대신 쓰인다.

```text
paramname := < argument >
```

```asm
INCLUDE Irvine32.inc
INCLUDE Macros.inc

mWriteln MACRO text:=<" ">
    mWrite text
    call Crlf
ENDM

.code
main PROC
    mWrite "Line one"
    mWriteln                        ; 인수가 없으면 " "
    mWriteln "Line two"
    exit
main ENDP
END main
```

실행 결과:

```text
Line one
Line two
```

인수 없이 부른 `mWriteln`은 `mWrite " "`로 펼쳐져 공백 하나를 쓰고 줄을 바꾼다. 기본값이 없었다면 `mWrite`가 빈 인수를 받아 `BYTE ,0`이라는 잘못된 정의가 만들어졌을 것이다. (`Macros.inc`의 `mWrite`처럼 매개변수에 `:REQ`가 붙어 있으면 그 전에 오류가 난다.)

### 불리언 식 (Boolean Expressions)

어셈블러는 `IF` 같은 조건부 지시어에서 다음 관계 연산자로 상수 식을 비교한다. 결과가 참이면 -1(0FFFFFFFFh), 거짓이면 0이다. `AND`, `OR`, `NOT`으로 조건을 묶을 수도 있다.

| 연산자 | 뜻 | 연산자 | 뜻 |
|---|---|---|---|
| `LT` | 작다 | `GT` | 크다 |
| `EQ` | 같다 | `NE` | 같지 않다 |
| `LE` | 작거나 같다 | `GE` | 크거나 같다 |

```asm
mov  eax,(5 LT 10)                  ; EAX = 0FFFFFFFFh
mov  ebx,(5 GT 10)                  ; EBX = 0
```

### IF, ELSE, ENDIF 지시어

`IF` 뒤에는 반드시 **상수 불리언 식**이 와야 한다. 식에는 정수 상수, 기호 상수, 상수 값을 받은 매크로 인수를 쓸 수 있지만, **레지스터나 변수 이름은 쓸 수 없다**. 어셈블할 때는 레지스터와 변수의 값이 아직 없기 때문이다.

```text
IF expression           IF expression
    statement-list          statement-list
ENDIF                   ELSE
                            statement-list
                        ENDIF
```

```asm
DEBUG = 1
.code
IF DEBUG GT 0
    mov  ebx,1                      ; EBX = 1
ELSE
    mov  ebx,2
ENDIF
```

`DEBUG`가 1이므로 첫 번째 블록의 `mov ebx,1`만 어셈블되고, `ELSE` 쪽의 `mov ebx,2`는 실행 파일에 아예 들어가지 않는다. 반면 다음처럼 레지스터를 조건에 쓰면 어셈블 오류가 난다(JWasm: `Constant or relocatable label expected`).

```text
mov  eax,5
IF eax EQ 5                         ; 오류: 어셈블할 때는 EAX의 값이 없다
    nop
ENDIF
```

#### IF와 .IF는 다르다 (보충)

| | `IF` / `ELSE` / `ENDIF` | `.IF` / `.ELSE` / `.ENDIF` (6장) |
|---|---|---|
| 조건을 계산하는 때 | **어셈블할 때** | **실행할 때** |
| 조건에 쓸 수 있는 것 | 상수, 상수 식, 매크로 인수 | 레지스터, 변수, 상수 |
| 결과 | 조건이 거짓인 쪽 코드는 **만들어지지 않는다** | 양쪽 코드가 모두 만들어지고 `CMP`와 조건 점프로 고른다 |
| 용도 | 매크로 인수 검사, 디버그용 코드 넣고 빼기, 플랫폼별 코드 | 프로그램의 실행 흐름 제어 |

### 예: mGotoxyConst 매크로 (Example: mGotoxyConst Macro)

`mGotoxyConst`는 `LT`와 `GT` 연산자로 인수의 범위를 검사한다. 인수 X와 Y는 상수여야 한다.

```asm
;----------------------------------------------------
mGotoxyConst MACRO X:REQ, Y:REQ
;
; Sets the cursor position at column X, row Y.
; Requires X and Y coordinates to be constant expressions
; in the ranges 0 <= X < 80 and 0 <= Y < 25.
;----------------------------------------------------
    LOCAL ERRS                      ;; local constant
    ERRS = 0
    IF (X LT 0) OR (X GT 79)
        ECHO Warning: First argument to mGotoxy (X) is out of range.
        ECHO ******************************************************
        ERRS = 1
    ENDIF
    IF (Y LT 0) OR (Y GT 24)
        ECHO Warning: Second argument to mGotoxy (Y) is out of range.
        ECHO ******************************************************
        ERRS = ERRS + 1
    ENDIF
    IF ERRS GT 0                    ;; if errors found,
        EXITM                       ;; exit the macro
    ENDIF
    push edx
    mov  dh,Y
    mov  dl,X
    call Gotoxy
    pop  edx
ENDM
.code
    mGotoxyConst 10,20
    mGotoxyConst 85,30
```

어셈블할 때 콘솔에 나오는 내용:

```text
Warning: First argument to mGotoxy (85) is out of range.
******************************************************
Warning: Second argument to mGotoxy (30) is out of range.
******************************************************
```

- `ECHO` 문장 안의 `X`, `Y`도 매개변수이므로 인수 85, 30으로 바뀌어 출력되었다.
- `ERRS`는 `LOCAL`로 선언해 호출할 때마다 새 이름(`??0000`, `??0001`, …)의 상수가 된다. `LOCAL`은 레이블뿐 아니라 매크로 안에서만 쓰는 **상수 이름**에도 쓸 수 있다.
- 범위를 벗어나면 `EXITM`으로 빠져나가므로 두 번째 호출은 아무 코드도 만들지 않는다. 첫 번째 호출(10, 20)만 `Gotoxy`를 부르는 코드가 된다.

### IFIDN과 IFIDNI 지시어 (The IFIDN and IFIDNI Directives)

`IFIDNI`는 두 기호(매크로 매개변수 포함)를 **대소문자 구분 없이** 비교해 같으면 참이다. `IFIDN`은 문법이 같고 대소문자를 구분한다.

```text
IFIDNI <symbol>, <symbol>
    statements
ENDIF
```

다음 `mReadBuf` 매크로에서 두 번째 인수는 EDX일 수 없다. 버퍼의 주소를 EDX에 넣는 순간 EDX에 들어 있던 최대 글자 수가 덮어써지기 때문이다.

```asm
;----------------------------------------------------
mReadBuf MACRO bufferPtr, maxChars
;
; Reads from the keyboard into a buffer.
; Receives: offset of the buffer, count of the maximum
;    number of characters that can be entered. The
;    second argument cannot be edx or EDX.
;----------------------------------------------------
    IFIDNI <maxChars>,<EDX>
        ECHO Warning: Second argument to mReadBuf cannot be EDX
        ECHO **************************************************
        EXITM
    ENDIF
    push ecx
    push edx
    mov  edx,bufferPtr
    mov  ecx,maxChars
    call ReadString
    pop  edx
    pop  ecx
ENDM
.data
buffer BYTE 20 DUP(0)
.code
    mov  edx,20
    mReadBuf OFFSET buffer,edx
    mReadBuf OFFSET buffer,20       ; buffer = "Hello"
```

어셈블할 때 콘솔에 나오는 내용:

```text
Warning: Second argument to mReadBuf cannot be EDX
**************************************************
```

`IFIDNI`이므로 소문자 `edx`도 걸러진다. 대소문자를 구분하는 `IFIDN <maxChars>,<EDX>`였다면 `edx`는 통과해 버렸을 것이다. 두 번째 호출은 정상적으로 펼쳐져 키보드(여기서는 입력 `Hello`)에서 문자열을 읽는다.

### 예: 행의 합 구하기 (Example: Summing a Matrix Row, 보충)

교재 10.3.6절의 예로, 슬라이드에는 없다. 9장의 `calc_row_sum` 프로시저를 매크로로 바꾸고, 원소 형식(`BYTE`, `WORD`, `DWORD`)을 인수로 받아 형식에 맞는 명령어를 고른다.

```asm
; Row Sum Calculation           (RowSum.asm를 바로잡은 것)
INCLUDE Irvine32.inc

;------------------------------------------------------------
mCalc_row_sum MACRO index, arrayOffset, rowSize, eltType
; Calculates the sum of a row in a two-dimensional array.
;
; Receives: row index, offset of the array, number of bytes
; in each table row, and the array type (BYTE, WORD, or DWORD).
; Returns: EAX = sum.
;------------------------------------------------------------
LOCAL L1
    push ebx                        ; save changed regs
    push ecx
    push edx
    push esi
; set up the required registers
    mov  eax,index
    mov  ebx,arrayOffset
    mov  ecx,rowSize
; calculate the row offset.
    mul  ecx                        ; row index * row size
    add  ebx,eax                    ; row offset
; prepare the loop counter.
    shr  ecx,(TYPE eltType / 2)     ; byte=0, word=1, dword=2
; initialize the accumulator and column indexes
    mov  eax,0                      ; accumulator
    mov  esi,0                      ; column index
L1:
    IFIDNI <eltType>, <DWORD>
        mov   edx,eltType PTR [ebx + esi*(TYPE eltType)]
    ELSE
        movzx edx,eltType PTR [ebx + esi*(TYPE eltType)]
    ENDIF
    add  eax,edx                    ; add to accumulator
    inc  esi
    loop L1
    pop  esi                        ; restore changed regs
    pop  edx
    pop  ecx
    pop  ebx
ENDM

.data
tableB BYTE   10h,  20h,  30h,  40h,  50h
RowSizeB = ($ - tableB)
       BYTE   60h,  70h,  80h,  90h, 0A0h
       BYTE  0B0h, 0C0h, 0D0h, 0E0h, 0F0h
tableW WORD   10h,  20h,  30h,  40h,  50h
RowSizeW = ($ - tableW)
       WORD   60h,  70h,  80h,  90h, 0A0h
       WORD  0B0h, 0C0h, 0D0h, 0E0h, 0F0h
tableD DWORD  10h,  20h,  30h,  40h,  50h
RowSizeD = ($ - tableD)
       DWORD  60h,  70h,  80h,  90h, 0A0h
       DWORD 0B0h, 0C0h, 0D0h, 0E0h, 0F0h
index DWORD 1

.code
main PROC
    mCalc_row_sum index, OFFSET tableB, RowSizeB, BYTE
    call WriteHex
    call Crlf
    mCalc_row_sum index, OFFSET tableW, RowSizeW, WORD
    call WriteHex
    call Crlf
    mCalc_row_sum index, OFFSET tableD, RowSizeD, DWORD
    call WriteHex                   ; EAX = 280h
    call Crlf
    exit
main ENDP
END main
```

실행 결과:

```text
00000280
00000280
00000280
```

- `TYPE eltType`에서 `eltType`은 `BYTE` 같은 **형식 이름 텍스트**로 바뀌므로 `TYPE BYTE`(1), `TYPE WORD`(2), `TYPE DWORD`(4)가 된다. 행의 바이트 수를 원소 크기로 나눠 원소 개수를 구하는데, 나눗셈 대신 `SHR`로 0, 1, 2비트 민다.
- `MOVZX`는 32비트 원본을 받을 수 없으므로, `IFIDNI`로 DWORD일 때만 `MOV`를 쓰도록 **어셈블할 때** 골랐다. 실행할 때 원소 크기를 비교하는 코드는 하나도 없다.
- 레이블 `L1`은 `LOCAL`로 선언했으므로 매크로를 세 번 호출해도 레이블이 겹치지 않는다.
- 세 표의 값이 같으므로 1행(60h + 70h + 80h + 90h + A0h)의 합이 모두 280h다.

> [!WARNING]
> 교재 예제 파일 `RowSum.asm`에는 두 가지 문제가 있어 위 코드에서 고쳤다. ① `tableB`와 `tableW`의 둘째·셋째 행이 `DWORD`로 선언되어 있다. 예제가 0행(`index`의 초기값 `?`는 0)만 계산해서 드러나지 않을 뿐, 1행 이후를 계산하면 엉뚱한 값이 나온다. ② `MUL`과 `MOV/MOVZX EDX,…`가 EDX를 바꾸는데 매크로가 EDX를 저장·복원하지 않는다.

### 특수 연산자 (Special Operators)

매크로 인수는 텍스트이므로, 텍스트를 다루는 연산자 네 가지가 따로 있다.

| 연산자 | 이름 | 하는 일 |
|---|---|---|
| `&` | 치환 연산자 (substitution) | 따옴표 안이나 다른 글자와 붙어 있는 매개변수 이름을 인수로 바꾸게 한다 |
| `< >` | 텍스트 리터럴 연산자 (literal-text) | 쉼표 등이 들어 있는 글자들을 하나의 텍스트로 묶는다 |
| `!` | 문자 리터럴 연산자 (literal-character) | 바로 다음 문자를 연산자가 아닌 보통 문자로 다룬다 |
| `%` | 확장 연산자 (expansion) | 텍스트 매크로를 펼치거나 상수 식을 그 값의 텍스트로 바꾼다 |

#### 치환 연산자 (Substitution Operator, &)

`&`는 매크로 안에서 매개변수 이름이 애매하게 쓰인 곳을 인수로 바꾸게 한다. 따옴표로 둘러싼 문자열 안의 글자는 보통 매개변수로 보지 않기 때문이다. 다음은 레지스터 이름과 값을 출력하려는 `mShowRegister`의 두 버전이다.

```asm
mShowRegister1 MACRO regName
    LOCAL tempStr
    .data
    tempStr BYTE "  regName=",0
    .code
    push edx
    mov  edx,OFFSET tempStr
    call WriteString
    pop  edx
    push eax
    mov  eax,regName
    call WriteHex
    pop  eax
ENDM

mShowRegister2 MACRO regName
    LOCAL tempStr
    .data
    tempStr BYTE "  &regName=",0
    .code
    push edx
    mov  edx,OFFSET tempStr
    call WriteString
    pop  edx
    push eax
    mov  eax,regName
    call WriteHex
    pop  eax
ENDM
.code
    mov  ecx,101h
    mShowRegister1 ECX
    call Crlf
    mShowRegister2 ECX
    call Crlf
```

실행 결과:

```text
  regName=00000101
  ECX=00000101
```

첫 번째 버전은 문자열 안의 `regName`을 그대로 둬서 `regName=`이 출력된다. 두 번째 버전은 `&regName`으로 써서 인수 `ECX`로 바뀌었다. 문자열 밖의 `mov eax,regName`은 `&` 없이도 바뀐다.

#### 확장 연산자 (Expansion Operator, %)

`%`는 텍스트 매크로를 펼치거나 **상수 식을 그 값의 텍스트**로 바꾼다.

```asm
count = 10
sumVal TEXTEQU %(5 + count)         ; = "15"
% ECHO The value of sumVal is sumVal
```

어셈블할 때 콘솔에 나오는 내용:

```text
The value of 15 is 15
```

`TEXTEQU %(5 + count)`는 식의 값 15를 계산해 텍스트 `"15"`로 만든다. 마지막 줄은 맨 앞의 `%` 때문에 줄 안의 **모든** 텍스트 매크로가 펼쳐져서, 설명으로 쓴 `sumVal`까지 15로 바뀌었다. 이 동작은 아래 "줄 맨 앞의 %"에서 자세히 본다.

매크로를 호출할 때 인수 앞에 `%`를 붙이면, 식을 계산한 **값**이 인수로 전달된다. 앞의 `mGotoxyConst`에 쓰면 범위 검사도 계산된 값으로 한다.

```asm
mGotoxyConst MACRO X:REQ, Y:REQ
    LOCAL ERRS
    ERRS = 0
    IF (X LT 0) OR (X GT 79)
        ERRS = 1
    ENDIF
    IF (Y LT 0) OR (Y GT 24)
        ERRS = ERRS + 1
    ENDIF
    IF ERRS GT 0
        EXITM
    ENDIF
    push edx
    mov  dh,Y
    mov  dl,X
    call Gotoxy
    pop  edx
ENDM
.code
    mGotoxyConst %(5 * 10), %(3 + 4)
```

목록 파일에서 확인한 확장 결과(조건부 지시어로 걸러진 줄은 빼고):

```text
00000000 52                  1      push edx
00000001 B607                1      mov  dh,7
00000003 B232                1      mov  dl,50
00000005 E8 FFFFFFFCr        1      call Gotoxy
0000000A 5A                  1      pop  edx
```

**줄 맨 앞의 %** (% at Beginning of Line). `%`가 줄의 첫 글자이면, 전처리기는 그 줄의 모든 텍스트 매크로와 매크로 함수를 펼친다. `ECHO`는 뒤의 내용을 글자 그대로 출력하므로, 줄 중간에 `%`를 쓰는 것으로는 식이 계산되지 않는다. `TEXTEQU`로 식의 값을 텍스트 매크로에 담은 다음, 줄 맨 앞의 `%`로 그 줄을 펼쳐야 한다.

```asm
.data
array DWORD 1,2,3,4,5,6,7,8
.code
ECHO The array contains (SIZEOF array) bytes
ECHO The array contains %(SIZEOF array) bytes
TempStr TEXTEQU %(SIZEOF array)
%   ECHO The array contains TempStr bytes
```

어셈블할 때 콘솔에 나오는 내용:

```text
The array contains (SIZEOF array) bytes
The array contains %(SIZEOF array) bytes
The array contains 32 bytes
```

#### 줄 번호 표시 (Displaying the Line Number)

다음 `Mul32` 매크로는 앞의 두 인수를 곱해 세 번째 인수에 저장한다. 두 번째 인수가 EAX이면 잘못된 결과가 나오므로, 그 경우 경고를 내면서 **매크로를 호출한 줄의 번호**를 함께 보여 준다. 고칠 곳을 찾기 쉽게 하기 위해서다.

```asm
; Mul32 매크로 (Macro3.asm을 바탕으로)
INCLUDE Irvine32.inc

Mul32 MACRO op1, op2, product
    IFIDNI <op2>,<EAX>
        LINENUM TEXTEQU %(@LINE)
        ECHO --------------------------------------------------
%       ECHO *  Error on line LINENUM: EAX cannot be the second
        ECHO *  argument when invoking the MUL32 macro.
        ECHO --------------------------------------------------
        EXITM
    ENDIF
    push eax
    mov  eax,op1
    mul  op2
    mov  product,eax
    pop  eax
ENDM

.data
val1 DWORD 1234h
val2 DWORD 1000h
val3 DWORD ?

.code
main PROC
    Mul32 val1,val2,val3            ; val3 = 1234000h
    mov  eax,val2
    Mul32 val1,eax,val3             ; issues a warning
    exit
main ENDP
END main
```

어셈블할 때 콘솔에 나오는 내용:

```text
--------------------------------------------------
*  Error on line 29: EAX cannot be the second
*  argument when invoking the MUL32 macro.
--------------------------------------------------
```

- `@LINE`은 지금 어셈블하는 줄의 번호를 돌려주는 **미리 정의된 기호**다. 매크로 안에서 쓰면 매크로를 **호출한** 줄의 번호(위 프로그램에서 29번째 줄)가 된다.
- `%(@LINE)`으로 그 값을 텍스트로 바꿔 `LINENUM`에 담고, `%`로 시작하는 `ECHO` 줄에서 펼친다. `LINENUM`을 매크로 바깥에서 정의하면 정의한 줄의 번호만 나오므로 반드시 매크로 안에서 정의해야 한다(교재 예제 `Macro3.asm`의 주석).

> [!NOTE]
> **슬라이드 정정**: 슬라이드 47번은 `Mul32`의 매개변수가 "레지스터, 메모리, 즉시값(곱을 담을 피연산자만 빼고)"일 수 있다고 설명한다. 그러나 `MUL`에는 즉시값 피연산자가 없으므로 **두 번째 인수(op2)도 즉시값일 수 없다**. `Mul32 5,6,val3`처럼 호출하면 `mul 6`이 만들어져 JWasm에서 `Invalid instruction operands` 오류가 난다. 즉시값이 될 수 있는 것은 `mov eax,op1`로 쓰이는 첫 번째 인수뿐이다. 또한 `MUL`이 결과의 위쪽 절반을 EDX에 쓰는데 매크로가 EDX를 저장하지 않으므로 호출한 쪽의 EDX가 바뀌고, 곱을 EAX에 받으려 하면(`product`가 EAX) 마지막 `pop eax`에 덮어써진다.

#### 텍스트 리터럴 연산자 (Literal-Text Operator, < >)

`< >`는 문자와 기호 여러 개를 **하나의 텍스트 리터럴**로 묶어, 전처리기가 그 안의 쉼표 등을 인수 구분자로 해석하지 않게 한다. 문자열에 쉼표, 퍼센트(`%`), 앰퍼샌드(`&`), 세미콜론(`;`)처럼 구분자나 다른 연산자로 해석될 문자가 들어 있을 때 특히 쓸모 있다.

```asm
INCLUDE Irvine32.inc
INCLUDE Macros.inc
.code
main PROC
    mWrite "Line three", 0dh, 0ah   ; 어셈블 경고
    mWrite <"Line three", 0dh, 0ah>
    exit
main ENDP
END main
```

어셈블할 때 콘솔에 나오는 내용:

```text
…: Warning A4149: Too many arguments in macro call: mWrite: , 0dh, 0ah
```

실행 결과:

```text
Line threeLine three
```

첫 번째 호출은 쉼표 때문에 인수가 `"Line three"`, `0dh`, `0ah` 세 개로 나뉜다. `mWrite`의 매개변수는 하나뿐이므로 나머지는 버려지고(JWasm은 경고를 낸다) 줄바꿈 없이 출력된다. 두 번째 호출은 셋을 묶은 하나의 인수가 되어 `BYTE "Line three", 0dh, 0ah,0`이 만들어진다.

#### 문자 리터럴 연산자 (Literal-Character Operator, !)

`!`는 `< >`와 비슷한 목적으로 만들어졌다. 바로 다음 문자 하나를 미리 정의된 연산자가 아닌 **보통 문자**로 다루게 한다. 다음 텍스트 매크로에서 `>`는 원래 텍스트를 닫는 괄호지만, `!>`로 쓰면 글자 `>`가 된다.

```text
BadYValue TEXTEQU <Warning: Y-coordinate is !> 24>
```

**경고 메시지 예** (Warning Message Example). `%`, `&`, `!`가 함께 동작하는 모습을 보자.

```asm
INCLUDE Irvine32.inc
INCLUDE Macros.inc

BadYValue TEXTEQU <Warning: Y-coordinate is !> 24>

ShowWarning MACRO message
    mWrite "&message"
ENDM

.code
main PROC
    ShowWarning %BadYValue
    call Crlf
    exit
main ENDP
END main
```

실행 결과:

```text
Warning: Y-coordinate is > 24
```

① `!>` 덕분에 `BadYValue`의 텍스트는 `Warning: Y-coordinate is > 24`가 된다. ② 인수 앞의 `%`가 텍스트 매크로 `BadYValue`를 그 내용으로 펼쳐 넘긴다. `%`가 없으면 `BadYValue`라는 이름 자체가 넘어간다. ③ 매크로 안에서는 따옴표 속의 `&message`가 인수로 바뀌어 `mWrite "Warning: Y-coordinate is > 24"`가 된다.

### 매크로 함수 (Macro Functions)

**매크로 함수**(macro function)는 문장들에 이름을 붙인다는 점에서 매크로 프로시저와 같지만, `EXITM` 지시어로 **항상 상수(정수나 문자열)를 돌려준다**는 점이 다르다. `EXITM`은 매크로의 나머지 확장을 모두 멈춘다.

```asm
IsDefined MACRO symbol
    IFDEF symbol
        EXITM <-1>                  ;; True
    ELSE
        EXITM <0>                   ;; False
    ENDIF
ENDM
```

**매크로 함수 호출** (Invoking a Macro Function). 매크로 함수를 호출할 때는 인수 목록을 반드시 **괄호로 감싸야** 한다.

```text
IF IsDefined( RealMode )            ; RealMode가 이 지점보다 앞에서 정의되었으면
    mov ax,@data                    ; 이 두 줄이 어셈블된다
    mov ds,ax
ENDIF
```

이 `IF`는 매크로 안에 넣을 수도 있다. `Macros.inc`의 `Startup` 매크로가 그렇다. 16비트 실제 주소 모드 프로그램은 시작할 때 DS를 데이터 세그먼트로 맞춰야 하지만, 32비트 보호 모드에서는 필요 없다.

```text
Startup MACRO
    IF IsDefined( RealMode )
        mov ax,@data
        mov ds,ax
    ENDIF
ENDM
```

`IsDefined` 같은 매크로는 여러 메모리 모델용 프로그램을 하나의 소스로 만들 때 쓸모 있다. 포함할 라이브러리 파일도 고를 수 있다.

```text
IF IsDefined( RealMode )
    INCLUDE Irvine16.inc
ELSE
    INCLUDE Irvine32.inc
ENDIF
```

**RealMode 기호 정의하기** (Defining the RealMode Symbol). 소스 파일 앞쪽에 `RealMode = 1`이라고 쓰거나, 어셈블러의 명령줄 옵션으로 정의한다. 명령줄에서 정의하면 소스를 고치지 않고 두 가지 버전을 만들 수 있다.

```text
ML -c -DRealMode=1 myProg.asm       ; 16비트 실제 모드 버전
ML -c myProg.asm                    ; 32비트 보호 모드 버전
```

**HelloNew 프로그램.** 같은 소스를 실제 모드와 보호 모드 모두로 어셈블할 수 있는 프로그램이다.

```asm
; Macro Functions               (HelloNew.asm)
INCLUDE Macros.inc
IF IsDefined( RealMode )
    INCLUDE Irvine16.inc
ELSE
    INCLUDE Irvine32.inc
ENDIF
.code
main PROC
    Startup
    mWrite <"This program can be assembled to run ",0dh,0ah>
    mWrite <"in both Real mode and Protected mode.",0dh,0ah>
    exit
main ENDP
END main
```

`RealMode`를 정의하지 않고 32비트로 어셈블했을 때의 실행 결과:

```text
This program can be assembled to run
in both Real mode and Protected mode.
```

`INCLUDE Macros.inc`가 `INCLUDE Irvine32.inc`보다 **먼저** 나온다는 점에 주목하자. `IsDefined`를 쓰려면 매크로가 먼저 정의되어 있어야 하기 때문이다. 16비트 버전은 `Irvine16` 라이브러리와 16비트 링커가 필요해 여기서는 확인하지 않았다.

### 매크로 함수 직접 만들기와 텍스트 처리 함수 (보충)

슬라이드 54번은 비어 있으므로 매크로 함수의 활용을 덧붙인다. 매크로 함수는 상수가 필요한 곳 어디서나 쓸 수 있다. 다음 `mMax`는 두 상수 중 큰 값을 돌려준다.

```asm
mMax MACRO a, b
    IF a GT b
        EXITM <a>
    ELSE
        EXITM <b>
    ENDIF
ENDM

BufSize = mMax(80, 100)
.data
buffer BYTE mMax(80, 100) DUP(0)
.code
mov  eax,BufSize                    ; EAX = 100
mov  ebx,SIZEOF buffer              ; EBX = 100
```

MASM에는 텍스트를 다루는 매크로 함수도 미리 정의되어 있다. 이름 앞에 `@`가 붙는다.

| 매크로 함수 | 돌려주는 값 | 같은 일을 하는 지시어 |
|---|---|---|
| `@SizeStr(text)` | 텍스트의 길이 | `SIZESTR` |
| `@CatStr(text1, text2, …)` | 텍스트를 이어 붙인 것 | `CATSTR` |
| `@SubStr(text, start, length)` | 텍스트의 일부(start는 1부터) | `SUBSTR` |
| `@InStr(start, text, search)` | search가 처음 나오는 위치(없으면 0) | `INSTR` |

```asm
% ECHO @SizeStr(<Hello>) @CatStr(<ab>,<cd>) @SubStr(<Assembly>,1,3) @InStr(1,<Assembly>,<bly>)
```

어셈블할 때 콘솔에 나오는 내용:

```text
5 abcd Ass 6
```

---

## 10.4 반복 블록 정의 (Defining Repeat Blocks)

MASM에는 문장 블록을 되풀이해서 만들어 내는 반복 지시어가 네 가지 있다. 모두 **어셈블할 때** 반복되어, 반복 횟수만큼 펼쳐진 문장이 프로그램에 들어간다. 실행할 때 반복하는 `LOOP`나 `.WHILE`과는 전혀 다르다.

| 지시어 | 반복 기준 | 예전 이름 |
|---|---|---|
| `WHILE` | 불리언 상수 식이 참인 동안 | — |
| `REPEAT` | 정해진 횟수(카운터 값)만큼 | `REPT` |
| `FOR` | 쉼표로 구분한 기호 목록의 원소마다 | `IRP` |
| `FORC` | 문자열의 문자마다 | `IRPC` |

네 지시어 모두 블록의 끝은 `ENDM`이다. 예전 이름(`REPT`, `IRP`, `IRPC`)도 같은 뜻으로 쓸 수 있다(Microsoft 문서: "Same as …").

### WHILE 지시어 (WHILE Directive)

`WHILE`은 상수 식이 참인 동안 문장 블록을 반복한다.

```text
WHILE constExpression
    statements
ENDM
```

다음 코드는 0F0000000h보다 작은 피보나치 수를 모두 DWORD로 만든다. 확인을 위해 첫 값 앞에 레이블 `fibs`를 붙이고, 만들어진 개수를 `FibCount`로 구했다.

```asm
.data
val1 = 1
val2 = 1
fibs LABEL DWORD
DWORD val1                          ; first two values
DWORD val2
val3 = val1 + val2
WHILE val3 LT 0F0000000h
    DWORD val3
    val1 = val2
    val2 = val3
    val3 = val1 + val2
ENDM
FibCount = ($ - fibs) / 4
.code
mov  eax,FibCount                   ; EAX = 47, fibs = [1, 1, 2, 3, 5, 8, 13, 21, 34, 55]
mov  ebx,fibs[(FibCount - 1) * 4]   ; EBX = 0B11924E1h
```

- `val1`, `val2`, `val3`은 `=`로 정의한 **상수**(재정의할 수 있는 기호)다. 블록 안에서 값을 바꿔 가며 다음 피보나치 수를 계산한다. 변수가 아니므로 메모리를 차지하지 않는다.
- `DWORD val3`처럼 이름 없이 형식만 쓴 데이터 정의는 그 자리에 값 하나를 만든다.
- 마지막 값 0B11924E1h(2,971,215,073)는 47번째 피보나치 수다. 그다음 수 4,807,526,976은 0F0000000h(4,026,531,840)보다 크므로 반복이 끝난다.

### REPEAT 지시어 (REPEAT Directive)

`REPEAT`는 문장 블록을 **어셈블할 때** 정해진 횟수만큼 반복한다.

```text
REPEAT constExpression
    statements
ENDM
```

`constExpression`은 부호 없는 상수 정수 식으로, 반복 횟수를 정한다. 슬라이드 57번에는 예제가 없으므로 교재 예제 `Repeat.asm`의 코드를 보충한다. 다음 코드는 10, 20, …, 1000의 DWORD 100개를 만든다.

```asm
.data
iVal = 10
values LABEL DWORD
REPEAT 100                          ; begin REPT loop
    DWORD iVal                      ; status
    iVal = iVal + 10
ENDM
ValCount = ($ - values) / 4
.code
mov  esi,OFFSET values              ; values = [10, 20, 30, 40, 50]
mov  ecx,ValCount                   ; ECX = 100
mov  ebx,values[99 * 4]             ; EBX = 1000
```

`REPEAT`는 구조체 정의 안에서도 쓸 수 있다. 다음 `WeatherReadings` 구조체는 1년 52주 동안의 강수량과 습도 필드를 반복으로 만든다. 필드 이름이 겹치지 않도록 `LOCAL`로 선언했으므로, 필드 이름은 `??0000`, `??0001`, …처럼 자동으로 붙는다.

```asm
WEEKS_PER_YEAR = 52
WeatherReadings STRUCT
    location BYTE 50 DUP(0)
    REPEAT WEEKS_PER_YEAR
        LOCAL rainfall, humidity
        rainfall DWORD ?
        humidity DWORD ?
    ENDM
WeatherReadings ENDS

mov  eax,SIZEOF WeatherReadings     ; EAX = 466
```

크기는 50 + 52 × (4 + 4) = 466바이트다. 다만 필드 이름이 자동으로 만들어진 것이라 이름으로 접근하기는 불편하다. 실제로는 `rainfall DWORD WEEKS_PER_YEAR DUP(?)`처럼 배열 필드로 쓰는 편이 낫다.

### FOR 지시어 (FOR Directive)

`FOR`는 쉼표로 구분한 기호 목록을 차례로 돌면서 문장 블록을 반복한다. 반복할 때마다 매개변수가 목록의 다음 원소로 바뀐다.

```text
FOR parameter,<arg1,arg2,arg3,...>
    statements
ENDM
```

**학생 수강 신청 예** (Student Enrollment Example). 과목(`COURSE`)과, 과목 6개를 담는 학기(`SEMESTER`) 구조체를 정의하고, `FOR`로 학기 변수 네 개를 만든다.

```asm
COURSE STRUCT
    Number  BYTE 9 DUP(?)
    Credits BYTE ?
COURSE ENDS

; A semester contains an array of courses.
SEMESTER STRUCT
    Courses    COURSE 6 DUP(<>)
    NumCourses WORD ?
SEMESTER ENDS

.data
FOR semName,<Fall2013,Spring2014,Summer2014,Fall2014>
    semName SEMESTER <>
ENDM
.code
mov  eax,SIZEOF SEMESTER                    ; EAX = 62
mov  ebx,OFFSET Spring2014
sub  ebx,OFFSET Fall2013                    ; EBX = 62
mov  ecx,OFFSET Fall2014
sub  ecx,OFFSET Fall2013                    ; ECX = 186
```

`FOR`가 펼쳐진 결과는 다음 네 줄을 직접 쓴 것과 같다.

```text
.data
Fall2013   SEMESTER <>
Spring2014 SEMESTER <>
Summer2014 SEMESTER <>
Fall2014   SEMESTER <>
```

`COURSE`는 9 + 1 = 10바이트, `SEMESTER`는 10 × 6 + 2 = 62바이트이므로 학기 변수는 62바이트 간격으로 놓인다.

#### FOR로 코드 만들기 (보충)

`FOR`는 데이터뿐 아니라 코드도 만든다. 여러 레지스터를 저장하고 복원하는 코드를 매크로로 만들어 보자. 복원은 저장의 반대 순서여야 하므로 목록도 거꾸로 준다.

```asm
mPushRegs MACRO regs
    FOR r,<regs>
        push r
    ENDM
ENDM
mPopRegs MACRO regs
    FOR r,<regs>
        pop  r
    ENDM
ENDM
.code
    mov  eax,1
    mov  ebx,2
    mov  ecx,3
    mPushRegs <eax,ebx,ecx>
    mov  eax,0
    mov  ebx,0
    mov  ecx,0
    mPopRegs  <ecx,ebx,eax>         ; EAX = 1, EBX = 2, ECX = 3
```

매크로의 인수 `<eax,ebx,ecx>`는 꺾쇠괄호로 묶여 하나의 텍스트로 전달되고, 매크로 안의 `<regs>`에서 다시 목록으로 풀려 `FOR`가 원소 하나씩 반복한다.

### FORC 지시어 (FORC Directive)

`FORC`는 문자열의 **문자 하나하나**에 대해 문장 블록을 반복한다.

```text
FORC parameter, <string>
    statements
ENDM
```

다음 코드는 특수 문자 9개로 이루어진 조회용 표(lookup table)를 만든다.

```asm
.data
Delimiters LABEL BYTE
FORC code,<@#$%^&*!<!>>
    BYTE "&code"
ENDM
.code
mov  esi,OFFSET Delimiters          ; Delimiters = [40h, 23h, 24h, 25h, 5Eh, 26h, 2Ah, 3Ch, 3Eh]
```

목록 파일에서 확인한 확장 결과:

```text
00000000 40                  1      BYTE "@"
00000001 23                  1      BYTE "#"
00000002 24                  1      BYTE "$"
00000003 25                  1      BYTE "%"
00000004 5E                  1      BYTE "^"
00000005 26                  1      BYTE "&"
00000006 2A                  1      BYTE "*"
00000007 3C                  1      BYTE "<"
00000008 3E                  1      BYTE ">"
```

- 문자열 안에서 `<`와 `>`는 텍스트를 여닫는 연산자이므로 `!<`, `!>`로 써서 보통 문자로 만들었다.
- 따옴표 안의 매개변수는 그대로는 바뀌지 않으므로 `"&code"`처럼 `&`를 붙였다.
- `%`, `&` 같은 문자도 `FORC`의 문자열 안에서는 매개변수 값으로 하나씩 정상적으로 처리되었다.

### 예: 연결 리스트 (Example: Linked List, 보충)

교재 10.4.5절의 예로, 슬라이드에는 없다(슬라이드 60번은 비어 있다). **연결 리스트**(linked list)는 각 노드가 데이터와 **다음 노드의 주소**를 함께 가진 자료 구조다. 마지막 노드(꼬리)의 다음 주소는 0(NULL)이다.

```text
LinkedList
 +------+------+     +------+------+           +------+------+     +------+------+
 |  1   | next-+---> |  2   | next-+---> ... > |  15  | next-+---> |  0   |  0   |
 +------+------+     +------+------+           +------+------+     +------+------+
 NodeData NextPtr                                                    tail node
```

교재 예제 `List.asm`은 `REPT`(`REPEAT`)로 노드 15개를 **어셈블할 때** 만든다.

```asm
; Creating a Linked List          (List.asm의 리스트 만드는 부분)
INCLUDE Irvine32.inc
ListNode STRUCT
    NodeData DWORD ?
    NextPtr  DWORD ?
ListNode ENDS

TotalNodeCount = 15
NULL = 0
Counter = 0
.data
LinkedList LABEL PTR ListNode
REPT TotalNodeCount
    Counter = Counter + 1
    ListNode <Counter, ($ + Counter * SIZEOF ListNode)>
ENDM
ListNode <0,0>                      ; tail node
.code
main PROC
    exit
main ENDP
END main
```

`NextPtr`에 넣는 식 `$ + Counter * SIZEOF ListNode`는 `$`(위치 카운터)가 반복할 때마다 **리스트의 시작 주소**일 때만 맞는다. 그래야 k번째 노드(오프셋 8(k − 1))의 `NextPtr`이 리스트 시작 + 8k, 즉 다음 노드를 가리킨다. 교재의 예제는 MASM에서 이렇게 계산된다고 보고 작성되었다.

그런데 JWasm에서는 구조체 초기값 안의 `$`가 **지금 초기화하고 있는 필드의 주소**가 된다. 그래서 첫 노드의 `NextPtr`(오프셋 4)에는 4 + 1 × 8 = 0Ch가, 두 번째 노드의 `NextPtr`(오프셋 0Ch)에는 0Ch + 2 × 8 = 1Ch가 들어가 다음 노드의 주소(8, 10h)와 어긋난다.

목록 파일에서 확인한 JWasm의 결과(노드 두 개):

```text
 = 1                         1      Counter = Counter + 1
00000000 010000000C000000    1      ListNode <Counter, ($ + Counter * SIZEOF ListNode)>
 = 2                         1      Counter = Counter + 1
00000008 020000001C000000    1      ListNode <Counter, ($ + Counter * SIZEOF ListNode)>
```

목록 파일의 기계어 열은 노드 하나(8바이트)를 `NodeData`, `NextPtr` 순서의 리틀 엔디언으로 보여 준다. 첫 노드는 `01000000`(1)과 `0C000000`(데이터 섹션 안의 오프셋 0Ch, 링크할 때 실제 주소로 바뀐다)이다. JWasm으로 만든 원래 프로그램을 실행하면 첫 노드의 1을 출력한 뒤, 두 번째 노드의 중간(0Ch)을 노드로 읽어 엉뚱한 값(주소값)을 출력하고, 그다음 잘못된 주소를 따라가다 접근 위반으로 멈췄다. `$`의 의미가 어셈블러에 따라 달라질 수 있는 셈이다. 어느 어셈블러에서든 확실하게 동작하게 하려면 `$` 대신 **리스트의 레이블**을 기준으로 주소를 계산하면 된다. 다음은 그렇게 고친 완전한 프로그램이다.

```asm
; Creating a Linked List          (List.asm을 $ 없이 고친 것)
INCLUDE Irvine32.inc
ListNode STRUCT
    NodeData DWORD ?
    NextPtr  DWORD ?
ListNode ENDS

TotalNodeCount = 15
NULL = 0
Counter = 0
.data
LinkedList LABEL PTR ListNode
REPT TotalNodeCount
    Counter = Counter + 1
    ListNode <Counter, (LinkedList + Counter * SIZEOF ListNode)>
ENDM
ListNode <0,0>                      ; tail node

.code
main PROC
    mov  esi,OFFSET LinkedList
; Display the integers in the NodeData members.
NextNode:
    ; Check for the tail node.
    mov  eax,(ListNode PTR [esi]).NextPtr
    cmp  eax,NULL
    je   quit
    ; Display the node data.
    mov  eax,(ListNode PTR [esi]).NodeData
    call WriteDec
    call Crlf
    ; Get pointer to next node.
    mov  esi,(ListNode PTR [esi]).NextPtr
    jmp  NextNode
quit:
    exit
main ENDP
END main
```

실행 결과:

```text
1
2
3
4
5
6
7
8
9
10
11
12
13
14
15
```

- `LinkedList LABEL PTR ListNode`는 메모리를 차지하지 않고, 바로 뒤에 오는 첫 노드의 주소에 이름을 붙인다.
- `LinkedList + Counter * SIZEOF ListNode`는 "레이블 + 상수" 꼴의 **재배치 가능한 주소**로, 링커가 실제 주소로 바꿔 넣는다. k번째 노드의 `NextPtr`은 리스트 시작 + 8k, 즉 (k + 1)번째 노드를 가리킨다.
- 루프는 `NextPtr`이 0인 꼬리 노드를 만나면 끝나므로, 꼬리 노드의 데이터(0)는 출력하지 않는다.
- 어셈블할 때 만든 리스트이므로 노드는 메모리에 차례로 붙어 있다. 실행 중에 노드를 추가·삭제하려면 11장에서 다루는 동적 메모리 할당(힙)이 필요하다.

---

## 부록 A. 핵심 정리 표

### 구조체와 공용체

| 문법 | 뜻 | 예 |
|---|---|---|
| `이름 STRUCT` … `이름 ENDS` | 구조체 형식 정의 (메모리를 차지하지 않는다) | `COORD STRUCT` / `X WORD ?` / `Y WORD ?` / `COORD ENDS` |
| `이름 STRUCT 4` | 필드를 (필드 크기, 4) 중 작은 값의 배수에 맞춰 배치 | `EmployeeA STRUCT 4` |
| `ALIGN 형식` | 다음 필드(또는 변수)를 그 형식의 크기 배수에 맞춘다 | `ALIGN DWORD` |
| `이름 UNION` … `이름 ENDS` | 공용체 형식 정의 (모든 필드가 오프셋 0) | `Integer UNION` |
| `UNION 필드이름` … `ENDS` | 구조체 안에 공용체를 직접 정의 | `UNION FileID` … `ENDS` |
| `변수 구조체 <…>` / `{…}` | 구조체 변수 선언과 초기화 | `point1 COORD <5,10>` |
| `<,"x">`, `<,,,값>` | 일부 필드만 초기화 (나머지는 기본값) | `person3 Employee <,"dJones">` |
| `구조체 n DUP(<>)` | 구조체 배열 | `AllPoints COORD 3 DUP(<0,0>)` |
| `변수.필드`, `변수.필드.필드` | 필드 참조 (주소 = 변수 주소 + 필드 오프셋) | `rect1.UpperLeft.X` |
| `(형식 PTR [reg]).필드` | 레지스터가 가리키는 구조체의 필드 | `(Employee PTR [esi]).Years` |
| `ASSUME reg:PTR 형식` | 레지스터의 형식을 미리 선언 (`ASSUME reg:NOTHING`으로 해제) | `ASSUME esi:PTR Employee` |
| `배열[reg].필드` | 구조체 배열의 원소 필드 (reg = 원소 번호 × 크기) | `department[esi].Years` |
| `TYPE`, `SIZEOF` 구조체/변수 | 구조체 하나의 크기 / 변수 전체 크기 | `SIZEOF Employee` = 60 |
| `TYPE`, `LENGTHOF`, `SIZEOF` 필드 | 필드의 원소 크기 / 원소 수 / 전체 크기 | `SIZEOF Employee.SalaryHistory` = 16 |
| `OFFSET 구조체.필드` | 필드의 오프셋 (상수) | `OFFSET Employee.Years` = 40 |
| `OFFSET 변수.필드` | 필드의 주소 | `OFFSET worker.LastName` |

### 매크로 정의와 호출

| 문법 | 뜻 |
|---|---|
| `이름 MACRO p1, p2` … `ENDM` | 매크로 정의 (호출 전에 정의되어 있어야 한다) |
| `이름 인수1, 인수2` | 매크로 호출 (인수는 텍스트로 치환된다) |
| `p:REQ` | 필수 매개변수 (빠지면 어셈블 오류) |
| `p:=<기본값>` | 기본 인수 |
| `p:VARARG` | 마지막 매개변수가 남은 인수를 모두 받는다 ([부록 F 연습 10](#연습-10-개수가-정해지지-않은-인수-vararg)) |
| `LOCAL 이름, …` | 호출할 때마다 겹치지 않는 이름(`??0000` …)으로 바뀌는 레이블·변수·상수 (매크로 본문의 맨 앞에 쓴다) |
| `;;` 주석 | 매크로 정의에만 남고 확장 결과(MASM 목록 파일)에는 나오지 않는 주석 |
| `ECHO 텍스트` | 어셈블할 때 콘솔에 텍스트를 출력 |
| `EXITM` / `EXITM <값>` | 매크로 확장을 멈춘다 / 매크로 함수의 값을 돌려준다 |
| `이름(인수)` | 매크로 함수 호출 (괄호 필수) |
| `이름 TEXTEQU <텍스트>` / `%(식)` | 텍스트 매크로 정의 (`%(식)`은 식의 값을 텍스트로) |
| `@LINE` | 지금 어셈블하는 줄의 번호 (매크로 안에서는 호출한 줄) |
| `@SizeStr`, `@CatStr`, `@SubStr`, `@InStr` | 텍스트 처리용 미리 정의된 매크로 함수 |

### 조건부 어셈블리와 반복 블록

| 지시어 | 참이 되는(반복하는) 조건 |
|---|---|
| `IF 식` / `ELSEIF 식` / `ELSE` / `ENDIF` | 상수 식이 0이 아닐 때 (`LT GT EQ NE LE GE`, `AND OR NOT`) |
| `IFB <arg>` / `IFNB <arg>` | 인수가 비었을 때 / 비지 않았을 때 |
| `IFIDN <a>,<b>` / `IFIDNI <a>,<b>` | 두 텍스트가 같을 때 (대소문자 구분 / 무시) |
| `IFDIF <a>,<b>` / `IFDIFI <a>,<b>` | 두 텍스트가 다를 때 (대소문자 구분 / 무시) |
| `IFDEF 이름` / `IFNDEF 이름` | 기호가 정의되어 있을 때 / 없을 때 |
| `WHILE 식` … `ENDM` | 식이 참인 동안 반복 |
| `REPEAT n` (`REPT`) … `ENDM` | n번 반복 |
| `FOR p,<a,b,c>` (`IRP`) … `ENDM` | 목록의 원소마다 반복 |
| `FORC p,<문자열>` (`IRPC`) … `ENDM` | 문자마다 반복 |

### 특수 연산자

| 연산자 | 이름 | 예 | 결과 |
|---|---|---|---|
| `&` | 치환 | `BYTE "&regName="` (`regName` = ECX) | `BYTE "ECX="` |
| `< >` | 텍스트 리터럴 | `mWrite <"Hi",0dh,0ah>` | 인수 하나 `"Hi",0dh,0ah` |
| `!` | 문자 리터럴 | `<is !> 24>` | 텍스트 `is > 24` |
| `%` | 확장 | `%(5 + count)` (count = 10) | 텍스트 `15` |
| `%` (줄 맨 앞) | 줄 전체 확장 | `% ECHO TempStr bytes` | 텍스트 매크로를 펼쳐서 출력 |

### 어셈블할 때와 실행할 때

| 어셈블할 때 (전처리·어셈블 단계) | 실행할 때 (CPU) |
|---|---|
| `IF` / `ELSE` / `ENDIF` | `.IF` / `.ELSE` / `.ENDIF`, `CMP` + 조건 점프 |
| `WHILE`, `REPEAT`, `FOR`, `FORC` | `.WHILE`, `.REPEAT`, `LOOP` |
| 매크로 호출 (코드가 펼쳐진다) | `CALL` / `RET` (프로시저) |
| `ECHO` (콘솔에 어셈블 메시지) | `WriteString` 등 (프로그램 출력) |
| `=`, `EQU`, `TEXTEQU` 상수 | 변수 (메모리) |
| 조건에 쓸 수 있는 것: 상수, 기호 상수, 매크로 인수 | 조건에 쓸 수 있는 것: 레지스터, 변수, 상수 |

### C와의 대응

| C | MASM |
|---|---|
| `struct S { short x; int y; };` | `S STRUCT` / `x WORD ?` / `ALIGN DWORD` / `y DWORD ?` / `S ENDS` |
| `union U { int d; char b; };` | `U UNION` / `d DWORD ?` / `b BYTE ?` / `U ENDS` |
| `sizeof(struct S)`, `offsetof(struct S, y)` | `SIZEOF S`, `OFFSET S.y` |
| `p->y` | `(S PTR [esi]).y` |
| `#pragma pack(1)` | 필드 사이에 `ALIGN`을 쓰지 않는다 (기본이 빈틈없는 배치) |
| `#define SQR(x) ((x)*(x))` | `mSqr MACRO x` … `ENDM` (괄호를 쓰는 습관도 같다) |
| `#if`, `#ifdef`, `#else`, `#endif` | `IF`, `IFDEF`, `ELSE`, `ENDIF` |
| `#x` (문자열로 만들기) | `"&x"` |
| `a##b` (토큰 붙이기) | `a&b` |
| `cc -DNAME=1` | `ML -DNAME=1` (`/D`) |
| (반복 없음) | `WHILE`, `REPEAT`, `FOR`, `FORC` |

---

## 부록 B. C 컴파일러가 만든 구조체 코드와 C의 매크로

### 구조체의 배치와 필드 접근

교재의 `Employee`와 같은 필드를 가진 C 구조체를 GCC 13으로 32비트 코드로 컴파일했다(`gcc -m32 -O2 -masm=intel -S`). `#pragma pack(1)`은 채우기 바이트 없이 배치하라는 지시로, MASM에서 `ALIGN`을 쓰지 않은 `EmployeeBad`와 같다.

```c
#include <stddef.h>

struct Employee {               /* 교재의 Employee와 같은 필드 */
    char  IdNum[9];
    char  LastName[30];
    short Years;
    int   SalaryHistory[4];
};

#pragma pack(push, 1)           /* 채우기 바이트 없이 */
struct EmployeeBad {
    char  IdNum[9];
    char  LastName[30];
    short Years;
    int   SalaryHistory[4];
};
#pragma pack(pop)

int info[] = {
    sizeof(struct Employee),                    /* 60 */
    offsetof(struct Employee, Years),           /* 40 */
    offsetof(struct Employee, SalaryHistory),   /* 44 */
    sizeof(struct EmployeeBad),                 /* 57 */
    offsetof(struct EmployeeBad, Years),        /* 39 */
};

void set_years(struct Employee *e, short y) {
    e->Years = y;
}

int total_salary(const struct Employee *e) {
    int t = 0;
    for (int i = 0; i < 4; i++)
        t += e->SalaryHistory[i];
    return t;
}
```

컴파일 결과(지시어 일부를 뺐다):

```nasm
set_years:
    mov    eax, DWORD PTR [esp+4]
    mov    edx, DWORD PTR [esp+8]
    mov    WORD PTR [eax+40], dx
    ret
total_salary:
    mov    edx, DWORD PTR [esp+4]
    mov    eax, DWORD PTR [edx+48]
    add    eax, DWORD PTR [edx+44]
    add    eax, DWORD PTR [edx+52]
    add    eax, DWORD PTR [edx+56]
    ret
    .data
info:
    .long    60
    .long    40
    .long    44
    .long    57
    .long    39
```

- **배치가 MASM과 같다.** C 컴파일러는 별도의 지시 없이도 각 필드를 자신의 크기에 맞게 정렬하므로, `ALIGN`을 넣은 MASM의 `Employee`와 똑같이 `Years`가 40, `SalaryHistory`가 44, 전체가 60바이트다. `pack(1)`을 쓴 구조체는 57바이트, `Years`가 39로 `EmployeeBad`와 같다.
- `e->Years = y`는 `mov WORD PTR [eax+40], dx` 한 줄이다. EAX가 구조체의 주소이고 40이 필드 오프셋이다. MASM의 `(Employee PTR [eax]).Years`가 만드는 것과 같은 주소 지정이다.
- `total_salary`의 루프는 원소가 4개뿐이라 컴파일러가 루프를 풀어(unroll) 오프셋 44, 48, 52, 56을 직접 더했다.
- `short y`도 스택에서는 4바이트 자리를 차지해 `DWORD PTR [esp+8]`로 읽는다. 10.1절의 `DisplayPosition`에서 WORD 인수가 4바이트를 차지한 것과 같은 이유다.

### C 전처리기의 매크로

C의 `#define` 매크로도 MASM 매크로처럼 **컴파일 전에 텍스트를 바꿔 넣는** 전처리기 기능이다. 다음 파일을 `gcc -E -P`로 전처리만 해 보았다.

```c
#define SQUARE_BAD(x)  x * x
#define SQUARE(x)      ((x) * (x))
#define NAME(x)        #x
#define FIELD(n)       field_##n

int field_1, field_2;

int f(int a) {
    return SQUARE_BAD(a + 1) + SQUARE(a + 1);
}

const char *s = NAME(EAX);
int *p = &FIELD(2);
```

전처리 결과:

```text
int field_1, field_2;
int f(int a) {
    return a + 1 * a + 1 + ((a + 1) * (a + 1));
}
const char *s = "EAX";
int *p = &field_2;
```

- `SQUARE_BAD(a + 1)`은 `a + 1 * a + 1`로 펼쳐진다. 10.2절의 `mSquareBad 2+1`이 5가 된 것과 똑같은 함정이다. 실제로 a = 3일 때 `SQUARE_BAD(a + 1)`은 7, `SQUARE(a + 1)`은 16이었다. 매개변수를 괄호로 감싸는 습관이 두 언어 모두에서 필요하다.
- `#x`는 인수를 문자열로 만든다. MASM에서는 따옴표 안에 `&x`를 쓴다(`"&regName="`).
- `##`는 두 토큰을 이어 붙인다. MASM에서는 `&`가 같은 역할을 한다(`field_&n`).
- C 전처리기에는 `WHILE`, `REPEAT`, `FOR`, `FORC` 같은 반복 지시어가 없다. 표를 만들 때는 보통 프로그램으로 소스를 생성하거나 실행할 때 계산한다.

---

## 부록 C. 자주 하는 실수와 오류 메시지

### 어셈블할 때 걸리는 오류

이 문서의 예제를 JWasm으로 어셈블해서 확인한 오류다. MASM의 메시지 문구와 번호는 조금 다를 수 있다.

| 잘못된 코드 | 원인 (JWasm의 메시지) | 고치는 방법 |
|---|---|---|
| `mov ax,[esi].Years` | 레지스터가 가리키는 구조체 형식을 모른다 (`Symbol not defined : Years`) | `(Employee PTR [esi]).Years` 또는 `ASSUME esi:PTR Employee` |
| `COORD STRUCT` / `X WORD ?` / `Z WORD ?` … | `SmallWin.inc`의 `COORD`와 다른 내용으로 다시 정의 (`Non-benign structure redefinition`) | 다른 이름을 쓴다. 같은 내용의 재정의는 허용된다 |
| `val4 Integer <1,2>` | 공용체 변수의 초기값은 하나뿐 (`Too many initial values for structure`) | 초기값을 하나만 준다 |
| `mPutchar` (`char:REQ`) | 필수 인수가 빠졌다 (`Missing macro argument: mPutchar, parameter 1`) | 인수를 넘긴다 |
| `LOCAL` 없는 `makeString`을 두 번 호출 | 매크로 안의 레이블이 두 번 정의된다 (`Symbol already defined: string`) | `LOCAL string` |
| `makeString` 뒤에 코드, 그리고 `main ENDP` | `.data`로 바꾼 채 매크로가 끝나 `ENDP`가 다른 세그먼트에 있다 (`Unmatched block nesting: main`) | 매크로 끝에서 `.code`로 돌아온다 |
| `IF eax EQ 5` | 조건부 지시어에는 상수만 쓸 수 있다 (`Constant or relocatable label expected`) | 실행할 때 판단하려면 `.IF eax == 5` |
| `Mul32 5,6,val3` | `mul 6`이 만들어진다. `MUL`에는 즉시값 형식이 없다 (`Invalid instruction operands`) | 즉시값은 레지스터에 넣은 뒤 곱한다 |
| `mWrite "Line three", 0dh, 0ah` | 경고: 인수가 매개변수보다 많아 뒤의 것은 버려진다 (`Warning A4149: Too many arguments in macro call`) | `mWrite <"Line three", 0dh, 0ah>` |
| `st BYTE 1`, `c DWORD ?` | `ST`(FPU 레지스터), `C`(호출 규약 이름)는 예약어다 (`Syntax error`) | 다른 이름을 쓴다 |
| `mWriteString` (IFB 검사 없이) | 펼쳐진 `mov edx,OFFSET` 줄에서 오류 (JWasm `Syntax error`, MASM `A2081`) | `:REQ`나 `IFB`로 인수를 검사한다 |

### 어셈블은 되지만 틀리게 동작하는 실수

| 실수 | 증상 | 고치는 방법 |
|---|---|---|
| 구조체 배열의 인덱스 레지스터에 원소 **번호**를 넣음 | `department[esi].Years`에서 ESI = 1이면 1바이트 어긋난 곳을 쓴다 | 원소 번호 × `TYPE Employee` |
| 널 문자가 없는 문자열 필드(`IdNum`)를 `WriteString`으로 출력 | 다음 필드까지 이어서 출력된다 | 길이를 지정해 출력하거나 크기를 1 늘려 널을 넣는다 |
| 구조체 필드만 `ALIGN`하고 변수는 정렬하지 않음 | 필드 오프셋은 맞아도 실제 주소가 어긋날 수 있다 | 변수 앞에도 `ALIGN DWORD` 등 |
| 공용체의 필드마다 다른 초기값 | 첫 필드의 값만 쓰인다 | 같은 값으로 쓰거나 첫 필드에만 준다 |
| 매크로 인수로 식을 넘기고 괄호 없이 사용 | `mSquareBad 2+1`이 5가 된다 | 매크로 안에서 `(x)`처럼 괄호로 감싼다 |
| 매크로가 바꾸는 레지스터를 인수로 넘김 | `mReadString`에 ECX/EDX, `mGotoxy`에 DH/DL을 넘기면 값이 덮어써진다 | 매크로 주석의 "Avoid passing …"을 확인한다 |
| 매크로가 레지스터를 저장하지 않음 | `Mul32`는 EDX를, 교재 `RowSum.asm`의 매크로도 EDX를 바꾼다 | 바꾸는 레지스터를 모두 `PUSH`/`POP` |
| `IFB`로 경고만 출력하고 `EXITM` | 어셈블은 "성공"하므로 경고를 못 보고 지나치기 쉽다 | 반드시 실패해야 하면 `.ERR`을 쓴다 |
| `IFIDN`으로 레지스터 이름 비교 | `edx`와 `EDX`를 다른 것으로 본다 | 레지스터 이름은 `IFIDNI`로 비교 |
| 줄 중간의 `%(식)`이 계산될 거라 기대 | `ECHO … %(SIZEOF array)`는 글자 그대로 출력된다 | `TEXTEQU %(…)`로 담고 줄 맨 앞에 `%` |
| 구조체 초기값 안에서 `$` 사용 | 어셈블러에 따라 값이 다르다(10.4절 연결 리스트) | 레이블 + 상수 식으로 주소를 계산 |

---

## 부록 D. 핵심 용어 정리

| 용어 | 영어 | 뜻 |
|---|---|---|
| 구조체 | structure | 관련된 변수들을 묶은 틀. `STRUCT`/`ENDS`로 정의한다 |
| 필드 | field, member | 구조체나 공용체 안의 변수 |
| 필드 초기값 | field initializer | 구조체 정의에서 필드에 준 기본값 |
| 구조체 변수 | structure variable | 구조체 형식으로 선언해 실제로 메모리를 차지하는 변수 |
| 정렬 | alignment | 데이터를 크기의 배수 주소에 놓는 것 |
| 채우기 바이트 | padding | 정렬을 맞추려고 필드 사이에 넣는 빈 바이트 |
| 중첩 구조체 | nested structure | 다른 구조체를 필드로 가진 구조체 |
| 공용체 | union | 모든 필드가 같은 메모리를 겹쳐 쓰는 형식 |
| 매크로 (프로시저) | macro (procedure) | 이름 붙인 문장 묶음. 호출한 자리에 펼쳐진다 |
| 인라인 확장 | inline expansion | 매크로 코드가 호출 위치에 복사되어 들어가는 것 |
| 매크로 매개변수 / 인수 | macro parameter / argument | 매크로 정의의 자리 표시자 / 호출할 때 넘기는 텍스트 |
| 필수 매개변수 | required parameter (`:REQ`) | 생략하면 오류가 나는 매개변수 |
| 기본 인수 | default argument initializer (`:=`) | 인수가 빠졌을 때 대신 쓰이는 값 |
| 지역 레이블 | local label (`LOCAL`) | 호출마다 `??nnnn` 꼴의 새 이름으로 바뀌는 레이블 |
| 목록 파일 | listing file (`.lst`) | 소스와 기계어, 매크로 확장을 함께 보여 주는 어셈블러 출력 |
| 중첩 매크로 | nested macro | 다른 매크로 안에서 호출된 매크로 |
| 래퍼 | wrapper | 프로시저 호출을 감싸 인수 준비를 대신하는 매크로 |
| 조건부 어셈블리 | conditional assembly | 조건에 따라 어셈블할 문장을 고르는 기능 |
| 매크로 함수 | macro function | `EXITM <값>`으로 상수를 돌려주는 매크로 |
| 텍스트 매크로 | text macro (`TEXTEQU`) | 이름에 텍스트를 담은 기호 |
| 치환 연산자 | substitution operator (`&`) | 따옴표 안 등에서 매개변수를 인수로 바꾸게 하는 연산자 |
| 텍스트 리터럴 연산자 | literal-text operator (`< >`) | 여러 글자를 하나의 텍스트로 묶는 연산자 |
| 문자 리터럴 연산자 | literal-character operator (`!`) | 다음 문자를 보통 문자로 다루게 하는 연산자 |
| 확장 연산자 | expansion operator (`%`) | 텍스트 매크로나 상수 식을 펼치는 연산자 |
| 반복 블록 | repeat block | `WHILE`, `REPEAT`, `FOR`, `FORC`로 만든, 어셈블할 때 되풀이되는 블록 |
| 위치 카운터 | location counter (`$`) | 지금 어셈블하는 위치의 오프셋 |
| 연결 리스트 | linked list | 각 노드가 다음 노드의 주소를 가진 자료 구조 |

---

## 부록 E. 복습 문제

교재 10.7절(Review Questions and Exercises)과 같은 유형의 문제를 직접 만들었다. **단답형**은 코드의 결과를 예측하는 문제, **알고리즘 작성**은 짧은 코드를 직접 써 보는 문제다. 각 문제의 **정답 보기**를 누르면 답과 해설이 펼쳐진다. 답에 나오는 값은 모두 어셈블하고 실행해서 확인했다.

### 단답형 (Short Answer)

**Q1.** 다음 코드에서 `a2`의 주소는 `a1`의 주소보다 몇 바이트 뒤인가?

```asm
.data
a1 BYTE 1
Point3 STRUCT
    X DWORD ?
    Y DWORD ?
    Z DWORD ?
Point3 ENDS
a2 BYTE 2
```

<details>
<summary>정답 보기</summary>

**1바이트**다. 구조체 **정의**는 틀일 뿐이어서 메모리를 차지하지 않는다. 메모리는 `Point3` 형식의 **변수**를 선언할 때 잡힌다.

```asm
.data
a1 BYTE 1
Point3 STRUCT
    X DWORD ?
    Y DWORD ?
    Z DWORD ?
Point3 ENDS
a2 BYTE 2
.code
mov  eax,OFFSET a2
sub  eax,OFFSET a1                  ; EAX = 1
```

</details>

**Q2.** 다음 두 구조체의 필드 오프셋과 크기는?

```asm
Rec STRUCT
    flag  BYTE ?
    count DWORD ?
    code  WORD ?
Rec ENDS

RecA STRUCT
    flag  BYTE ?
    ALIGN DWORD
    count DWORD ?
    code  WORD ?
RecA ENDS
```

<details>
<summary>정답 보기</summary>

`Rec`은 빈틈없이 놓여 `flag` 0, `count` 1, `code` 5, 크기 **7**바이트다. `RecA`는 `ALIGN DWORD`가 3바이트를 채워 `count` 4, `code` 8, 크기 **10**바이트다. 구조체 끝에는 채우기 바이트를 넣지 않았으므로 10에서 끝난다(C 컴파일러라면 배열을 생각해 끝을 4의 배수인 12로 맞춘다).

```asm
Rec STRUCT
    flag  BYTE ?
    count DWORD ?
    code  WORD ?
Rec ENDS

RecA STRUCT
    flag  BYTE ?
    ALIGN DWORD
    count DWORD ?
    code  WORD ?
RecA ENDS

mov  eax,OFFSET Rec.code            ; EAX = 5
mov  ebx,SIZEOF Rec                 ; EBX = 7
mov  ecx,OFFSET RecA.code           ; ECX = 8
mov  edx,SIZEOF RecA                ; EDX = 10
```

</details>

**Q3.** `p COORD <,7>`로 선언하면 X와 Y는 각각 얼마인가?

<details>
<summary>정답 보기</summary>

첫 자리를 비웠으므로 X는 `COORD`의 기본값 `?`이고, `.data`에서는 0으로 채워진다. Y는 7이다.

```asm
.data
p COORD <,7>
.code
mov  ax,p.X                         ; AX = 0
mov  bx,p.Y                         ; BX = 7
```

</details>

**Q4.** `pts COORD 5 DUP(<>)`에 대해 `TYPE pts`, `LENGTHOF pts`, `SIZEOF pts`는?

<details>
<summary>정답 보기</summary>

원소 하나(`COORD`)가 4바이트이고 원소가 5개이므로 각각 4, 5, 20이다.

```asm
.data
pts COORD 5 DUP(<>)
.code
mov  eax,TYPE pts                   ; EAX = 4
mov  ebx,LENGTHOF pts               ; EBX = 5
mov  ecx,SIZEOF pts                 ; ECX = 20
```

</details>

**Q5.** 위의 `pts`에서 세 번째 원소(index 2)의 Y를 `pts[esi].Y`로 읽으려면 ESI에 얼마를 넣어야 하는가?

<details>
<summary>정답 보기</summary>

인덱스 레지스터에는 원소 번호가 아니라 바이트 오프셋을 넣으므로 2 × `TYPE COORD` = **8**이다.

```asm
.data
pts COORD <1,2>, <3,4>, <5,6>, <7,8>, <9,10>
.code
mov  esi,2 * TYPE COORD             ; ESI = 8
mov  ax,pts[esi].Y                  ; AX = 6
```

</details>

**Q6.** ESI가 `COORD` 변수를 가리킬 때 `mov ax,[esi].X`가 어셈블되지 않는 이유와, 고치는 방법 두 가지는?

<details>
<summary>정답 보기</summary>

어셈블러는 ESI가 어떤 구조체를 가리키는지 모르므로 `X`가 어느 구조체의 필드인지 정할 수 없다. `PTR`로 형식을 알려 주거나, `ASSUME`으로 레지스터의 형식을 미리 선언한다.

```asm
.data
pt COORD <10,20>
.code
mov  esi,OFFSET pt
mov  ax,(COORD PTR [esi]).X         ; AX = 10
ASSUME esi:PTR COORD
mov  bx,[esi].Y                     ; BX = 20
ASSUME esi:NOTHING
```

</details>

**Q7.** 다음 공용체 변수에서 `v.w`와 `v.b`의 값은?

```asm
U UNION
    d DWORD 0AABBCCDDh
    w WORD  ?
    b BYTE  ?
U ENDS
.data
v U <>
```

<details>
<summary>정답 보기</summary>

모든 필드가 오프셋 0에서 시작하고 x86은 리틀 엔디언이므로 `w`는 아래 2바이트 **0CCDDh**, `b`는 맨 아래 바이트 **0DDh**다.

```asm
U UNION
    d DWORD 0AABBCCDDh
    w WORD  ?
    b BYTE  ?
U ENDS
.data
v U <>
.code
mov  ax,v.w                         ; AX = 0CCDDh
mov  bl,v.b                         ; BL = 0DDh
```

</details>

**Q8.** `Buf UNION` 안에 `d DWORD ?`와 `s BYTE 10 DUP(?)`가 있으면 `SIZEOF Buf`는?

<details>
<summary>정답 보기</summary>

공용체의 크기는 가장 긴 필드의 크기이므로 **10**이다.

```asm
Buf UNION
    d DWORD ?
    s BYTE 10 DUP(?)
Buf ENDS
mov  eax,SIZEOF Buf                 ; EAX = 10
```

</details>

**Q9.** 네 개의 명령어로 이루어진 매크로를 10번 호출한 프로그램과, 같은 명령어를 프로시저로 만들어 10번 호출한 프로그램의 차이를 코드 크기와 실행 속도 면에서 설명하라.

<details>
<summary>정답 보기</summary>

매크로는 호출할 때마다 네 명령어가 복사되므로 코드가 10벌 생겨 프로그램이 커진다. 대신 `CALL`/`RET`이 없어 호출 비용이 없다. 프로시저는 코드가 한 벌뿐이라 작지만, 호출할 때마다 `CALL`과 `RET`(필요하면 인수를 넣는 `PUSH`)를 실행한다. 짧고 자주 쓰는 코드는 매크로, 길거나 여러 곳에서 쓰는 코드는 프로시저가 알맞다.

</details>

**Q10.** `LOCAL` 없이 레이블을 정의한 매크로를 두 번 호출하면 무슨 일이 생기는가? `LOCAL`을 쓰면 레이블 이름은 어떻게 되는가?

<details>
<summary>정답 보기</summary>

같은 레이블이 두 번 정의되어 두 번째 호출에서 어셈블 오류가 난다(JWasm: `Symbol already defined`). `LOCAL`로 선언하면 어셈블러가 호출할 때마다 `??0000`, `??0001`처럼 겹치지 않는 이름으로 바꿔 넣는다.

</details>

**Q11.** `;`로 시작하는 주석과 `;;`로 시작하는 주석은 매크로 안에서 어떻게 다른가?

<details>
<summary>정답 보기</summary>

`;` 주석은 매크로가 펼쳐질 때마다 함께 펼쳐진다(목록 파일의 확장 부분에 나온다). `;;` 주석은 매크로 정의에만 남고, MASM의 목록 파일에서 확장된 자리에는 나타나지 않는다. (JWasm의 목록 파일에는 `;;` 주석도 나타난다.)

</details>

**Q12.** 다음 두 `IF`는 어셈블할 때 어떤 메시지를 출력하는가?

```asm
mTest MACRO reg
    IFIDN <reg>,<EAX>
        ECHO IFIDN:  same
    ENDIF
    IFIDNI <reg>,<EAX>
        ECHO IFIDNI: same
    ENDIF
ENDM
mTest eax
```

<details>
<summary>정답 보기</summary>

`IFIDN`은 대소문자를 구분하므로 `eax`와 `EAX`를 다르게 보고, `IFIDNI`는 같게 본다. 그래서 두 번째 메시지만 나온다.

```asm
mTest MACRO reg
    IFIDN <reg>,<EAX>
        ECHO IFIDN:  same
    ENDIF
    IFIDNI <reg>,<EAX>
        ECHO IFIDNI: same
    ENDIF
ENDM
mTest eax
```

어셈블할 때 콘솔에 나오는 내용:

```text
IFIDNI: same
```

</details>

**Q13.** 다음 줄은 어셈블할 때 무엇을 출력하는가?

```asm
side = 6
% ECHO area = @CatStr(%(side * 7))
```

<details>
<summary>정답 보기</summary>

`%(side * 7)`이 식의 값 42를 텍스트로 바꾸고, 줄 맨 앞의 `%`가 줄 안의 매크로 함수 `@CatStr`를 펼친다. 그래서 `area = 42`가 출력된다. 줄 맨 앞의 `%`가 없으면 `@CatStr(%(side * 7))`이 글자 그대로 출력된다.

```asm
side = 6
% ECHO area = @CatStr(%(side * 7))
```

어셈블할 때 콘솔에 나오는 내용:

```text
area = 42
```

</details>

**Q14.** 다음 코드는 DWORD를 몇 개 만드는가? 마지막 값은?

```asm
.data
n = 1
WHILE n LT 100
    DWORD n
    n = n * 2
ENDM
```

<details>
<summary>정답 보기</summary>

1, 2, 4, 8, 16, 32, 64의 **7개**이고 마지막 값은 64다. n이 128이 되면 조건이 거짓이 되어 멈춘다.

```asm
.data
pow2 LABEL DWORD
n = 1
WHILE n LT 100
    DWORD n
    n = n * 2
ENDM
Count = ($ - pow2) / 4
.code
mov  eax,Count                      ; EAX = 7, pow2 = [1, 2, 4, 8, 16, 32, 64]
mov  ebx,pow2[(Count - 1) * 4]      ; EBX = 64
```

</details>

**Q15.** `FORC ltr,<ABC>` / `BYTE '&ltr',0` / `ENDM`이 만드는 바이트는?

<details>
<summary>정답 보기</summary>

문자마다 한 번씩 반복하므로 `'A',0,'B',0,'C',0`의 6바이트다. 작은따옴표 안에서도 매개변수를 바꾸려면 `&`가 필요하다.

```asm
.data
chars LABEL BYTE
FORC ltr,<ABC>
    BYTE '&ltr',0
ENDM
.code
mov  esi,OFFSET chars               ; chars = [41h, 0, 42h, 0, 43h, 0]
```

</details>

### 알고리즘 작성 (Algorithm Workbench)

**W1.** 제목(30바이트), 출판 연도(WORD), 가격(DWORD)을 담는 `Book` 구조체를 각 필드가 정렬되도록 정의하고, 원소 3개짜리 배열에서 두 번째 책의 연도를 2024로 바꾸는 코드를 인덱스 피연산자로 작성하라.

<details>
<summary>정답 보기</summary>

```asm
Book STRUCT
    BookName BYTE 30 DUP(0)
    Year  WORD 0                    ; 오프셋 30 (이미 2의 배수)
    Price DWORD 0                   ; 오프셋 32 (이미 4의 배수)
Book ENDS
.data
ALIGN DWORD
books Book 3 DUP(<>)
.code
mov  esi,1 * TYPE Book              ; ESI = 36
mov  books[esi].Year,2024
mov  ax,books[esi].Year             ; AX = 2024
mov  ebx,SIZEOF Book                ; EBX = 36
```

`BookName`이 30바이트라 `Year`는 오프셋 30(2의 배수), `Price`는 32(4의 배수)에 저절로 맞는다. 이런 경우에는 `ALIGN`이 필요 없지만, 필드 순서나 크기가 바뀔 때를 대비해 넣어 두어도 손해는 없다. 구조체 변수 앞의 `ALIGN DWORD`는 배열의 시작 주소를 맞춘다.

</details>

**W2.** 두 DWORD 메모리 피연산자의 값을 맞바꾸는 매크로 `mSwap32`를 작성하라. 호출한 쪽의 레지스터는 바뀌지 않아야 한다.

<details>
<summary>정답 보기</summary>

메모리끼리는 `XCHG`할 수 없으므로 EAX를 거친다. EAX는 저장했다가 복원한다.

```asm
mSwap32 MACRO a:REQ, b:REQ
    push eax
    mov  eax,a
    xchg eax,b
    mov  a,eax
    pop  eax
ENDM
.data
x DWORD 111
y DWORD 222
.code
mov  eax,5
mSwap32 x,y                         ; x = 222, y = 111, EAX = 5
```

</details>

**W3.** `FOR`를 써서 EAX, EBX, ECX, EDX를 모두 0으로 만드는 매크로 `mZeroRegs`를 작성하라.

<details>
<summary>정답 보기</summary>

```asm
mZeroRegs MACRO
    FOR r,<eax,ebx,ecx,edx>
        xor  r,r
    ENDM
ENDM
.code
mov  eax,1
mov  ebx,2
mov  ecx,3
mov  edx,4
mZeroRegs                           ; EAX = 0, EBX = 0, ECX = 0, EDX = 0
```

`XOR reg,reg`는 `MOV reg,0`보다 짧은 기계어로 레지스터를 0으로 만드는 관용구다.

</details>

**W4.** 2의 n제곱을 어셈블할 때 계산해 돌려주는 매크로 함수 `mPow2`를 작성하라.

<details>
<summary>정답 보기</summary>

```asm
mPow2 MACRO n
    EXITM %(1 SHL (n))
ENDM
.code
mov  eax,mPow2(10)                  ; EAX = 1024
mov  ebx,mPow2(3 + 2)               ; EBX = 32
```

`SHL`은 어셈블할 때 쓰는 **연산자**로, 상수를 왼쪽으로 민다(명령어 `SHL`과 이름이 같다). `%( )`로 값을 텍스트로 바꿔 돌려주므로, 매크로 함수를 부른 자리에 `1024`라는 상수가 들어간다. 매개변수를 괄호로 감쌌으므로 `3 + 2`도 5로 계산된다.

</details>

**W5.** ESI가 가리키는 `COORD`의 X와 Y를 맞바꾸는 프로시저 `SwapXY`를 작성하라.

<details>
<summary>정답 보기</summary>

```asm
; W5: COORD의 X와 Y 맞바꾸기
INCLUDE Irvine32.inc
.data
pt COORD <3,9>
.code
main PROC
    mov  esi,OFFSET pt
    call SwapXY                     ; pt.X = 9, pt.Y = 3
    exit
main ENDP

SwapXY PROC USES eax
; Receives: ESI = COORD 구조체의 주소
    mov  ax,(COORD PTR [esi]).X
    xchg ax,(COORD PTR [esi]).Y
    mov  (COORD PTR [esi]).X,ax
    ret
SwapXY ENDP
END main
```

</details>

**W6.** `REPEAT`로 0부터 9까지의 제곱수 표 `squares`를 만들고, 인덱스 7의 값을 읽는 코드를 작성하라.

<details>
<summary>정답 보기</summary>

```asm
.data
k = 0
squares LABEL DWORD
REPEAT 10
    DWORD k * k
    k = k + 1
ENDM
.code
mov  esi,7
mov  eax,squares[esi * TYPE squares]    ; EAX = 49, squares = [0, 1, 4, 9, 16, 25, 36, 49, 64, 81]
```

표를 어셈블할 때 만들어 두면, 실행할 때는 곱셈 없이 메모리를 한 번 읽는 것으로 값을 얻는다. 이런 표를 **조회표**(lookup table)라고 한다. `TYPE squares`는 `LABEL DWORD`이므로 4다.

</details>

---

## 부록 F. 프로그래밍 연습 (풀이 포함)

교재 10.8절 Programming Exercises와 같은 유형의 문제를 이 장에서 배운 방법으로 풀어 본다. 먼저 직접 풀어 본 다음 **풀이 보기**를 펼쳐 비교해 보자. 모든 풀이는 그대로 붙여 넣어 실행할 수 있는 완전한 프로그램(Irvine32 사용)이고, 실행 결과와 어셈블할 때의 메시지를 확인했다.

| 연습 | 주제 | 주로 쓰는 것 |
|---|---|---|
| 1 | 메모리 사이의 복사 매크로 | 매크로, `IFIDNI`, `ECHO` |
| 2 | 시각을 두 자리씩 출력하기 | `SYSTEMTIME`, 매크로 |
| 3 | 안전한 곱셈 매크로 | `OPATTR`, `IF`, 레지스터 보존 |
| 4 | 학생 성적 구조체 배열 | 구조체 배열, 배열 필드, `PTR` |
| 5 | IPv4 주소 공용체 | 공용체, 이름 없는 구조체 |
| 6 | 방향을 기억하는 Drunkard's Walk | `COORD`, `RandomRange` |
| 7 | 어셈블할 때 만드는 모음 판별표 | `WHILE` + `FORC` + `IF`, `XLAT` |
| 8 | 연결 리스트의 합과 최댓값 | `FOR`로 노드 만들기, 리스트 순회 |
| 9 | 사각형의 넓이 | 중첩 구조체, 구조체 포인터, `ASSUME` |
| 10 | 개수가 정해지지 않은 인수 (VARARG) | `:VARARG`, `FOR` |

### 연습 1. 메모리 사이의 복사 매크로

x86의 `MOV`는 메모리에서 메모리로 바로 복사할 수 없다. 두 피연산자가 모두 메모리여도 되는 `mMove32 dest, source` 매크로를 작성하라. 호출한 쪽의 레지스터는 바뀌지 않아야 하고, 이 방식으로는 `dest`가 EAX일 수 없으므로 그 경우 어셈블할 때 경고를 내고 코드를 만들지 않아야 한다.

<details>
<summary>풀이 보기</summary>

```asm
; 연습 1: 메모리 사이의 복사 매크로
INCLUDE Irvine32.inc

;------------------------------------------------------
mMove32 MACRO dest:REQ, source:REQ
; dest = source (둘 다 메모리 피연산자여도 된다)
; EAX를 거치지만 호출한 쪽의 EAX는 바뀌지 않는다.
;------------------------------------------------------
    IFIDNI <dest>,<EAX>
        ECHO Warning: mMove32 cannot use EAX as the destination
        EXITM
    ENDIF
    push eax
    mov  eax,source
    mov  dest,eax
    pop  eax
ENDM

.data
val1 DWORD 12345678h
val2 DWORD ?

.code
main PROC
    mov  eax,0FFh
    mMove32 val2,val1               ; val2 = 12345678h, EAX = 0FFh
    mMove32 val1,1000               ; val1 = 1000
    mMove32 eax,val1                ; 경고만 나고 코드는 없다
    mov  eax,val2
    call WriteHex
    call Crlf
    mov  eax,val1
    call WriteDec
    call Crlf
    exit
main ENDP
END main
```

어셈블할 때 콘솔에 나오는 내용:

```text
Warning: mMove32 cannot use EAX as the destination
```

실행 결과:

```text
12345678
1000
```

EAX를 거쳐 복사하고 `PUSH`/`POP`으로 원래 값을 되살린다. `dest`가 EAX이면 복사한 값이 마지막 `pop eax`에 덮어써지므로 `IFIDNI`로 걸렀다. `source`에는 즉시값(1000)도 쓸 수 있다.

</details>

### 연습 2. 시각을 두 자리씩 출력하기

10.1절의 ShowTime 프로그램은 9시 5분 3초를 `9:5:3`으로 출력한다. WORD 필드의 값(0~99)을 항상 두 자리로 출력하는 매크로 `mWrite2Digits`를 만들어 `09:05:03`처럼 출력하라. 결과를 확인하기 쉽도록 `SYSTEMTIME` 변수에 시각을 직접 넣어 시험하라.

<details>
<summary>풀이 보기</summary>

```asm
; 연습 2: 시각을 두 자리씩 출력하기
INCLUDE Irvine32.inc

;------------------------------------------------------
mWrite2Digits MACRO field
; WORD 값(0~99)을 두 자리 10진수로 출력한다.
;------------------------------------------------------
    push eax
    push ecx
    push edx
    movzx eax,field
    mov  edx,0
    mov  ecx,10
    div  ecx                        ; EAX = 십의 자리, EDX = 일의 자리
    add  al,'0'
    call WriteChar
    mov  al,dl
    add  al,'0'
    call WriteChar
    pop  edx
    pop  ecx
    pop  eax
ENDM

.data
; wYear, wMonth, wDayOfWeek, wDay, wHour, wMinute, wSecond, wMilliseconds
sysTime SYSTEMTIME <2026, 11, 5, 20, 9, 5, 3, 0>
colonStr BYTE ":",0

.code
main PROC
    ; 실제 프로그램에서는 여기서 INVOKE GetLocalTime, ADDR sysTime
    mWrite2Digits sysTime.wHour
    mov  edx,OFFSET colonStr
    call WriteString
    mWrite2Digits sysTime.wMinute
    call WriteString
    mWrite2Digits sysTime.wSecond
    call Crlf
    exit
main ENDP
END main
```

실행 결과:

```text
09:05:03
```

10으로 나눈 몫이 십의 자리, 나머지가 일의 자리다. 각 자리에 `'0'`(30h)을 더하면 그 숫자의 ASCII 문자가 된다. `SYSTEMTIME`의 초기값은 필드 순서(`wYear`, `wMonth`, `wDayOfWeek`, `wDay`, …)대로 준다. 매크로가 EDX를 저장·복원하므로 두 번째 `WriteString`에서도 EDX는 여전히 `":"`를 가리킨다.

</details>

### 연습 3. 안전한 곱셈 매크로

10.3절의 `Mul32`는 두 번째 인수로 즉시값을 받지 못하고, EDX를 바꾸며, 곱을 EAX에 받을 수 없다. 이 문제를 고친 `mMul32 op1, op2, product`를 작성하라. 두 번째 인수가 즉시값이면 ECX를 거쳐 곱하고, 두 번째 인수나 곱이 EAX 또는 EDX이면 경고를 내라.

<details>
<summary>풀이 보기</summary>

```asm
; 연습 3: 안전한 곱셈 매크로
INCLUDE Irvine32.inc

;------------------------------------------------------
mMul32 MACRO op1:REQ, op2:REQ, product:REQ
; product = op1 * op2 (아래 32비트)
; op2가 즉시값이어도 되고, EAX와 EDX는 보존된다.
;------------------------------------------------------
    IFIDNI <op2>,<EAX>
        ECHO Warning: mMul32 - the 2nd argument cannot be EAX
        EXITM
    ENDIF
    IFIDNI <product>,<EAX>
        ECHO Warning: mMul32 - the 3rd argument cannot be EAX
        EXITM
    ENDIF
    IFIDNI <product>,<EDX>
        ECHO Warning: mMul32 - the 3rd argument cannot be EDX
        EXITM
    ENDIF
    push eax
    push edx
    mov  eax,op1
    IF (OPATTR (op2)) AND 00000100b ;; 즉시값이면
        push ecx
        mov  ecx,op2
        mul  ecx
        pop  ecx
    ELSE
        mul  op2
    ENDIF
    mov  product,eax
    pop  edx
    pop  eax
ENDM

.data
val1 DWORD 1234h
val2 DWORD 1000h
val3 DWORD ?

.code
main PROC
    mov  edx,0AAAAh
    mMul32 val1,val2,val3           ; val3 = 1234000h, EDX = 0AAAAh
    mMul32 val1,10,val3             ; val3 = 0B608h
    mov  ebx,6
    mMul32 7,ebx,ecx                ; ECX = 42
    mMul32 val1,eax,val3            ; 경고
    exit
main ENDP
END main
```

어셈블할 때 콘솔에 나오는 내용:

```text
Warning: mMul32 - the 2nd argument cannot be EAX
```

- `OPATTR`는 피연산자의 성질을 비트로 알려 주는 연산자다. 비트 2(값 4)가 1이면 즉시값, 비트 4(값 16)가 1이면 레지스터다. 교재의 `mShow` 매크로도 이 연산자로 레지스터인지 판별한다.
- 즉시값을 ECX에 넣어 곱할 때는 ECX도 저장·복원한다. `mul`이 EDX에 쓰는 위쪽 32비트는 버리고, EDX는 `PUSH`/`POP`으로 원래 값을 되살린다.
- 1234h × 10 = 0B608h, 7 × 6 = 42다.
- 경고 문장에 매개변수 이름을 쓰지 않도록 주의하자. 처음에 `ECHO Warning: mMul32 - op2 cannot be EAX`라고 썼더니, 문장 속의 `op2`가 인수로 바뀌어 `eax cannot be EAX`가 출력되었다. `ECHO` 뒤의 텍스트도 매크로 안에서는 매개변수 치환을 받는다(10.3절의 `mGotoxyConst`가 `(85)`를 출력한 것과 같은 원리).

</details>

### 연습 4. 학생 성적 구조체 배열

학생 이름(12바이트)과 점수 3개(DWORD 배열), 평균(DWORD)을 담는 `Student` 구조체를 정의하고, 학생 3명의 배열을 초기값과 함께 선언하라. ESI가 가리키는 학생의 평균을 구해 `Average` 필드에 넣는 프로시저 `CalcAverage`를 작성하고, 모든 학생의 이름과 평균을 출력하라.

<details>
<summary>풀이 보기</summary>

```asm
; 연습 4: 학생 성적 구조체 배열
INCLUDE Irvine32.inc

NUM_SCORES = 3
Student STRUCT
    StuName BYTE 12 DUP(0)
    Scores  DWORD NUM_SCORES DUP(0)
    Average DWORD 0
Student ENDS

.data
ALIGN DWORD
roster Student <"Kim",<90,80,70>>, <"Lee",<100,95,90>>, <"Park",<60,75,92>>
msgAvg BYTE ": average ",0

.code
main PROC
    mov  esi,OFFSET roster
    mov  ecx,LENGTHOF roster
L1: call CalcAverage
    lea  edx,(Student PTR [esi]).StuName
    call WriteString
    mov  edx,OFFSET msgAvg
    call WriteString
    mov  eax,(Student PTR [esi]).Average
    call WriteDec
    call Crlf
    add  esi,TYPE Student
    loop L1
    exit
main ENDP

;------------------------------------------------------
CalcAverage PROC USES eax ebx ecx edx
; ESI가 가리키는 Student의 점수 평균(나머지 버림)을
; Average 필드에 넣는다.
;------------------------------------------------------
    mov  eax,0
    mov  ebx,0                      ; Scores 안의 바이트 오프셋
    mov  ecx,NUM_SCORES
L1: add  eax,(Student PTR [esi]).Scores[ebx]
    add  ebx,TYPE DWORD
    loop L1
    mov  edx,0
    mov  ecx,NUM_SCORES
    div  ecx
    mov  (Student PTR [esi]).Average,eax
    ret
CalcAverage ENDP
END main
```

실행 결과:

```text
Kim: average 80
Lee: average 95
Park: average 75
```

- 배열 필드의 초기값은 꺾쇠괄호를 한 번 더 써서 `<"Kim",<90,80,70>>`처럼 준다. 이름 필드는 12바이트 중 남은 자리가 0으로 채워지므로 그대로 `WriteString`에 넘길 수 있다.
- `(Student PTR [esi]).Scores[ebx]`는 `[esi + ebx + 12]`(Scores의 오프셋 12)다. 구조체 포인터와 배열 인덱스를 함께 쓸 수 있다.
- `LEA`로 필드의 주소를 구했다. `StuName`은 오프셋 0이라 `mov edx,esi`와 같지만, 필드 이름으로 쓰면 구조체가 바뀌어도 그대로 동작한다.
- Park의 평균은 227 ÷ 3 = 75(나머지 2)다.

</details>

### 연습 5. IPv4 주소 공용체

IPv4 주소(32비트)를 DWORD 하나로도, 바이트 4개로도 다룰 수 있는 공용체 `IPv4`를 정의하라. 주소를 점 표기(예: `192.168.0.1`)로 출력하는 프로시저 `ShowIP`를 작성하고, 주소와 넷마스크의 AND로 네트워크 주소를 구해 출력하라. 마지막으로 바이트 단위로 주소를 만들고 DWORD 값을 16진수로 출력하라.

<details>
<summary>풀이 보기</summary>

```asm
; 연습 5: IPv4 주소 공용체
INCLUDE Irvine32.inc

IPv4 UNION
    full DWORD ?
    STRUCT
        b0 BYTE ?                   ; 가장 낮은 바이트
        b1 BYTE ?
        b2 BYTE ?
        b3 BYTE ?                   ; 가장 높은 바이트
    ENDS
IPv4 ENDS

.data
host    IPv4 <0C0A80001h>           ; 192.168.0.1
netmask IPv4 <0FFFFFF00h>           ; 255.255.255.0
network IPv4 <>
gateway IPv4 <>

.code
main PROC
    mov  esi,OFFSET host
    call ShowIP
    mov  esi,OFFSET netmask
    call ShowIP
    mov  eax,host.full
    and  eax,netmask.full
    mov  network.full,eax           ; network.full = 0C0A80000h
    mov  esi,OFFSET network
    call ShowIP
    mov  gateway.b3,192             ; 바이트 단위로 만든다
    mov  gateway.b2,168
    mov  gateway.b1,0
    mov  gateway.b0,254
    mov  eax,gateway.full           ; EAX = 0C0A800FEh
    call WriteHex
    call Crlf
    exit
main ENDP

;------------------------------------------------------
ShowIP PROC USES eax
; ESI가 가리키는 IPv4 주소를 점 표기로 출력한다.
;------------------------------------------------------
    movzx eax,(IPv4 PTR [esi]).b3
    call WriteDec
    mov  al,'.'
    call WriteChar
    movzx eax,(IPv4 PTR [esi]).b2
    call WriteDec
    mov  al,'.'
    call WriteChar
    movzx eax,(IPv4 PTR [esi]).b1
    call WriteDec
    mov  al,'.'
    call WriteChar
    movzx eax,(IPv4 PTR [esi]).b0
    call WriteDec
    call Crlf
    ret
ShowIP ENDP
END main
```

실행 결과:

```text
192.168.0.1
255.255.255.0
192.168.0.0
C0A800FE
```

- 공용체 안에 **이름 없는 구조체**(`STRUCT` … `ENDS`)를 넣으면, 그 필드를 `host.b3`처럼 공용체 이름 바로 다음에 쓸 수 있다. 네 바이트가 `full`과 같은 메모리를 겹쳐 쓴다.
- 점 표기의 첫 숫자(192)는 DWORD의 **가장 높은** 바이트(b3)다. 리틀 엔디언이라 메모리에서는 맨 뒤(오프셋 3)에 있다.
- 필드 이름을 `addr`, `mask`로 하고 싶겠지만 둘 다 MASM의 연산자(`ADDR`, `MASK`)라 쓸 수 없다.

</details>

### 연습 6. 방향을 기억하는 Drunkard's Walk

10.1절의 Drunkard's Walk에서 교수는 출발점 근처를 맴도는 경향이 있다. 매 걸음마다 50% 확률로 **직전 방향을 유지**하고, 나머지 50%일 때만 네 방향 중 하나를 새로 고르도록 바꿔라(새로 고른 방향이 우연히 같을 수도 있다). 위치는 `COORD` 변수에 저장하고, 50걸음 뒤의 위치와 실제로 방향이 바뀐 횟수를 출력하라.

<details>
<summary>풀이 보기</summary>

```asm
; 연습 6: 방향을 기억하는 Drunkard's Walk
INCLUDE Irvine32.inc

WalkMax = 50
StartX = 25
StartY = 25

.data
pos     COORD <StartX, StartY>
dir     DWORD ?                     ; 0 북, 1 남, 2 서, 3 동
changes DWORD 0
msgEnd  BYTE "End position: ",0
msgChg  BYTE "Direction changes: ",0

.code
main PROC
    mov  eax,4
    call RandomRange
    mov  dir,eax                    ; 처음 방향
    mov  ecx,WalkMax
L1: mov  eax,2
    call RandomRange                ; 0 또는 1
    cmp  eax,0
    je   L2                         ; 0이면 같은 방향으로 계속
    mov  eax,4
    call RandomRange                ; 새 방향 0~3
    cmp  eax,dir
    je   L2
    mov  dir,eax
    inc  changes
L2: mov  eax,dir
    .IF eax == 0                    ; North
        dec pos.Y
    .ELSEIF eax == 1                ; South
        inc pos.Y
    .ELSEIF eax == 2                ; West
        dec pos.X
    .ELSE                           ; East
        inc pos.X
    .ENDIF
    loop L1
    mov  edx,OFFSET msgEnd
    call WriteString
    movzx eax,pos.X
    call WriteDec
    mov  al,','
    call WriteChar
    movzx eax,pos.Y
    call WriteDec
    call Crlf
    mov  edx,OFFSET msgChg
    call WriteString
    mov  eax,changes
    call WriteDec
    call Crlf
    exit
main ENDP
END main
```

실행 결과(`Randomize`를 부르지 않았으므로 매번 같다):

```text
End position: 22,32
Direction changes: 22
```

`RandomRange`(EAX = 2)로 동전을 던져 0이면 방향을 유지한다. 원래 프로그램은 매번 방향을 새로 고르므로 바로 되돌아가는 걸음이 많지만, 이 프로그램은 같은 방향으로 여러 걸음 이어 가는 일이 많다. 이번 실행은 (22, 32)에서 끝나 출발점과의 맨해튼 거리(가로 거리 + 세로 거리)가 10이었다(원래 프로그램이 마지막으로 출력한 위치는 (17, 28)로 11). 한 번의 결과로는 경향을 알 수 없으므로 같은 규칙으로 10만 번 흉내 내어 보니(파이썬 시뮬레이션), 50걸음 뒤의 평균 맨해튼 거리가 원래 방법은 약 8.0, 이 방법은 약 13.6으로 출발점에서 훨씬 멀리 갔다. 이렇게 무작위로 걷는 과정을 **랜덤 워크**(random walk)라고 한다.

</details>

### 연습 7. 어셈블할 때 만드는 모음 판별표

문자 코드(0~127)를 인덱스로 하는 128바이트 표 `isVowel`을 **어셈블할 때** 만들어라. 모음(`aeiouAEIOU`)의 자리는 1, 나머지는 0이다. 그런 다음 이 표와 `XLAT` 명령어로 문자열의 모음 개수를 세라.

<details>
<summary>풀이 보기</summary>

```asm
; 연습 7: 어셈블할 때 만드는 모음 판별표
INCLUDE Irvine32.inc

.data
isVowel LABEL BYTE                  ; isVowel[c] = 1이면 c는 모음
chCode = 0
WHILE chCode LT 128
    vflag = 0
    FORC v,<aeiouAEIOU>
        IF chCode EQ '&v'
            vflag = 1
        ENDIF
    ENDM
    BYTE vflag
    chCode = chCode + 1
ENDM
text BYTE "Assembly Language Programming",0
msg  BYTE "vowels: ",0

.code
main PROC
    mov  esi,OFFSET text
    mov  ebx,OFFSET isVowel         ; XLAT이 쓰는 표의 주소
    mov  ecx,0                      ; 모음 개수
L1: mov  al,[esi]
    cmp  al,0
    je   L2
    xlat                            ; AL = isVowel[AL]
    movzx eax,al
    add  ecx,eax
    inc  esi
    jmp  L1
L2: mov  edx,OFFSET msg
    call WriteString
    mov  eax,ecx
    call WriteDec
    call Crlf
    exit
main ENDP
END main
```

실행 결과:

```text
vowels: 9
```

- `WHILE`이 문자 코드 0~127을 돌고, 그 안의 `FORC`가 모음 10개와 하나씩 비교한다. 어셈블할 때 128 × 10번의 비교가 일어나지만, 실행 파일에는 결과인 128바이트 표만 남는다.
- `'&v'`처럼 작은따옴표 안에서도 `&`를 붙여야 `FORC`의 매개변수가 문자로 바뀐다.
- `XLAT`은 `AL = [EBX + AL]`을 하는 명령어로, 표를 찾아보는(lookup) 데 쓴다. 모음이면 1, 아니면 0이 AL에 들어오므로 그대로 더하면 개수가 된다. 문자열에는 A, e, a, u, a, e, o, a, i의 9개가 있다.

</details>

### 연습 8. 연결 리스트의 합과 최댓값

부호 있는 정수 5, 12, −7, 30, 9를 데이터로 갖는 연결 리스트를 `FOR` 지시어로 어셈블할 때 만들어라(꼬리 노드는 `<0,0>`). 그리고 리스트를 따라가며 데이터의 합과 최댓값을 구해 출력하라.

<details>
<summary>풀이 보기</summary>

```asm
; 연습 8: 연결 리스트의 합과 최댓값
INCLUDE Irvine32.inc

ListNode STRUCT
    NodeData SDWORD ?
    NextPtr  DWORD ?
ListNode ENDS

.data
List LABEL PTR ListNode
idx = 0
FOR val,<5,12,-7,30,9>
    idx = idx + 1
    ListNode <val, List + idx * SIZEOF ListNode>
ENDM
ListNode <0,0>                      ; 꼬리 노드
msgSum BYTE "sum = ",0
msgMax BYTE "max = ",0

.code
main PROC
    mov  esi,OFFSET List
    mov  ebx,0                      ; 합
    mov  edi,80000000h              ; 최댓값 (가장 작은 SDWORD에서 시작)
L1: cmp  (ListNode PTR [esi]).NextPtr,0
    je   L3                         ; 꼬리 노드면 끝
    mov  eax,(ListNode PTR [esi]).NodeData
    add  ebx,eax
    cmp  eax,edi
    jle  L2                         ; 부호 있는 비교
    mov  edi,eax
L2: mov  esi,(ListNode PTR [esi]).NextPtr
    jmp  L1
L3: mov  edx,OFFSET msgSum
    call WriteString
    mov  eax,ebx                    ; EAX = 49
    call WriteInt
    call Crlf
    mov  edx,OFFSET msgMax
    call WriteString
    mov  eax,edi                    ; EAX = 30
    call WriteInt
    call Crlf
    exit
main ENDP
END main
```

실행 결과:

```text
sum = +49
max = +30
```

- `FOR`가 값 목록을 하나씩 돌며 노드를 만든다. `idx`는 몇 번째 노드인지 세는 상수로, k번째 노드의 `NextPtr`은 `List + k × 8`, 즉 (k + 1)번째 노드의 주소다(10.4절에서 `$` 대신 레이블로 계산한 방법과 같다).
- 최댓값의 초깃값을 0이 아니라 가장 작은 SDWORD(80000000h)로 해야 음수만 있는 리스트에서도 맞는 답이 나온다. 비교도 부호 있는 `JLE`를 쓴다.

</details>

### 연습 9. 사각형의 넓이

10.1절의 `Rectangle` 구조체(`UpperLeft`, `LowerRight` 두 `COORD`)의 주소를 받아 넓이를 EAX로 돌려주는 프로시저 `RectArea`를 작성하라. 프로시저 안에서는 `ASSUME`으로 레지스터의 형식을 선언해 필드에 접근하라. 사각형 세 개의 넓이를 출력하라.

<details>
<summary>풀이 보기</summary>

```asm
; 연습 9: 사각형의 넓이
INCLUDE Irvine32.inc

Rectangle STRUCT
    UpperLeft  COORD <>
    LowerRight COORD <>
Rectangle ENDS

RectArea PROTO, pRect:PTR Rectangle

.data
rects Rectangle <<10,10>,<50,20>>, <<0,0>,<80,25>>, <<5,5>,<6,6>>

.code
main PROC
    mov  esi,OFFSET rects
    mov  ecx,LENGTHOF rects
L1: INVOKE RectArea, esi
    call WriteDec
    call Crlf
    add  esi,TYPE Rectangle
    loop L1
    exit
main ENDP

;------------------------------------------------------
RectArea PROC USES ebx edx esi, pRect:PTR Rectangle
; Returns: EAX = (오른쪽 아래 X - 왼쪽 위 X) * (오른쪽 아래 Y - 왼쪽 위 Y)
;------------------------------------------------------
    mov  esi,pRect
    ASSUME esi:PTR Rectangle
    movzx eax,[esi].LowerRight.X
    movzx ebx,[esi].UpperLeft.X
    sub  eax,ebx                    ; 너비
    movzx ebx,[esi].LowerRight.Y
    movzx edx,[esi].UpperLeft.Y
    sub  ebx,edx                    ; 높이
    ASSUME esi:NOTHING
    mul  ebx                        ; EAX = 넓이
    ret
RectArea ENDP
END main
```

실행 결과:

```text
400
2000
1
```

`ASSUME esi:PTR Rectangle` 다음부터는 `[esi].LowerRight.X`처럼 `PTR` 없이 중첩된 필드까지 쓸 수 있다. 다 쓴 뒤 `ASSUME esi:NOTHING`으로 풀어 두지 않으면, 같은 프로시저에서 ESI를 다른 용도로 쓸 때 헷갈릴 수 있다. `MUL`이 EDX를 바꾸므로 `USES`에 EDX를 넣었다.

</details>

### 연습 10. 개수가 정해지지 않은 인수 (VARARG)

매개변수 뒤에 `:VARARG`를 붙이면 그 매개변수가 **남은 인수를 모두** 쉼표로 구분된 텍스트로 받는다. 이것과 `FOR`를 이용해 ① 인수를 몇 개든 받아 모두 더하는 `mSumAll dest, values` 매크로와 ② 레지스터 여러 개의 이름과 값을 한 줄에 출력하는 `mShowRegs` 매크로를 작성하라. `mShowRegs`는 `Macros.inc`의 `mShowRegister`를 이용한다.

<details>
<summary>풀이 보기</summary>

```asm
; 연습 10: 개수가 정해지지 않은 인수
INCLUDE Irvine32.inc
INCLUDE Macros.inc

;------------------------------------------------------
mSumAll MACRO dest:REQ, values:VARARG
; dest = values의 합 (values는 몇 개든 된다)
;------------------------------------------------------
    mov  dest,0
    FOR v,<values>
        add  dest,v
    ENDM
ENDM

;------------------------------------------------------
mShowRegs MACRO regs:VARARG
; 레지스터마다 이름과 값을 16진수로 출력한다.
;------------------------------------------------------
    FOR r,<regs>
        mShowRegister r,r
    ENDM
    call Crlf
ENDM

.data
n1 DWORD 100

.code
main PROC
    mSumAll eax, 1, 2, 3, 4         ; EAX = 10
    mSumAll ebx, n1, 20h, -1        ; EBX = 131
    mSumAll ecx, 7                  ; ECX = 7
    mShowRegs eax, ebx, ecx
    exit
main ENDP
END main
```

실행 결과:

```text
  eax=0000000A  ebx=00000083  ecx=00000007
```

- `values:VARARG`는 `1, 2, 3, 4`를 통째로 받고, `FOR v,<values>`가 다시 하나씩 나눠 `add dest,v`를 네 번 만든다. `VARARG` 매개변수는 맨 마지막 매개변수여야 한다.
- `mShowRegister r,r`의 첫 `r`은 출력할 이름(`"  &regName="`), 두 번째 `r`은 값을 읽을 레지스터다. 인수를 소문자로 넘겼으므로 이름도 소문자로 출력된다.
- 131 = 100 + 32 − 1 = 83h다.

</details>

---

## 부록 G. 슬라이드 정정 사항 모음

본문의 정정 박스에 적은 내용을 한곳에 모았다. 슬라이드 번호는 표지를 1번으로 센 것이다.

| 위치 | 슬라이드 표기 | 올바른 내용 |
|---|---|---|
| 11번 Performance of Aligned Structure Members | 두 번째 `call GetMSeconds`의 주석 `; get starting time` | 루프가 끝난 뒤의 시각이므로 `; get ending time` |
| 21번 INPUT_RECORD | `WINDOW BUFFER SIZE RECORD <>` | 이름에 공백이 들어갈 수 없다. `WINDOW_BUFFER_SIZE_RECORD <>` |
| 27번 Macro Comments | 설명은 "보통 주석은 매크로가 펼쳐질 때마다 나타난다"인데 예제는 `;;` 주석 | 설명은 `;` 주석에 대한 것이다. `;;` 주석은 반대로 확장 결과(목록 파일)에 나타나지 **않는다** |
| 47번 Mul32 | 매개변수가 "레지스터, 메모리, 즉시값(곱만 빼고)"일 수 있다 | `MUL`에는 즉시값 피연산자가 없으므로 **두 번째 인수도 즉시값일 수 없다**. 또한 EDX가 바뀌고, 곱을 EAX로 받을 수 없다 |

틀린 것은 아니지만 그대로 따라 하면 오해하기 쉬운 부분은 다음과 같다.

| 위치 | 슬라이드 내용 | 주의할 점 |
|---|---|---|
| 5번 구조체 변수 선언 | `point2 COORD <20> ; X = 20, Y = ?` | `.data`에서 `?`는 실제로는 0으로 채워진다 |
| 12번 ShowTime | 시·분·초를 `WriteDec`으로 출력 | 앞에 0이 붙지 않아 9시 5분 3초가 `9:5:3`으로 나온다([부록 F 연습 2](#연습-2-시각을-두-자리씩-출력하기)) |
| 17·19번 FileInfo | 두 가지 정의에 같은 이름 `FileInfo` | 한 프로그램에는 하나만 둘 수 있다. 둘을 비교하려면 이름을 달리해야 한다 |
| 28번 makeString | `.data`로 바꾼 뒤 `.code`로 돌아오지 않는다 | 코드 중간에서 호출하면 뒤의 명령어가 데이터 세그먼트에 들어간다(JWasm: `Unmatched block nesting`) |
| 36~54번 머리글 | "Conditional-Assembler Directives" | 교재의 절 제목과 Table 10-3의 제목은 "Conditional-Assembly Directives"다 |
| 37번 오류 메시지 | `error A2081: missing operand after unary operator` | MASM의 메시지다. 어셈블러마다 문구와 번호가 다르다(JWasm은 `Syntax error`) |
| 57번 REPEAT | 문법만 있고 예제가 없다 | 10.4절에 교재 예제 `Repeat.asm`의 코드를 보충했다 |

교재 예제 파일에서 발견한 점도 함께 적어 둔다.

| 파일 | 내용 | 주의할 점 |
|---|---|---|
| `Struct1.asm` | `mov eax,TYPE worker ; 82` | `Employee`는 60바이트이므로 60이다 |
| `Struct1.asm` | 점 배열 루프에서 `(COORD PTR AllPoints[edi]).X`에 두 번 저장 | 두 번째는 `.Y`여야 한다(`AllPoints.asm`은 맞게 되어 있다) |
| `RowSum.asm` | `tableB`, `tableW`의 둘째·셋째 행을 `DWORD`로 선언 | 행 크기가 맞지 않아 1행 이후의 합이 틀린다. 매크로가 EDX를 저장하지 않는 문제도 있다(10.3절에서 고쳤다) |
| `List.asm` | `NextPtr`을 `$ + Counter * SIZEOF ListNode`로 계산 | `$`의 값이 어셈블러에 따라 달라, JWasm에서는 포인터가 어긋나 접근 위반이 난다. 레이블 기준으로 고친 코드를 10.4절에 실었다 |
| `Repeat.asm` | 루프 안에서 `mov ecx,8`(ReadString의 최대 길이) 후 `loop L1` | 루프 카운터 ECX를 덮어써서 `LOOP`가 끝나지 않는다. 입력이 끝나도 계속 물어본다 |

슬라이드 22, 35, 54, 60번은 머리글만 있는 빈 슬라이드이고, 63번은 "Github upload"라는 안내만 있다. 슬라이드에 없어서 보충한 부분은 다음과 같다.

| 내용 | 근거 |
|---|---|
| `COORD`를 다시 정의할 때의 규칙, `STRUCT`의 정렬 인수 | Microsoft Learn(STRUCT 구문), JWasm으로 확인 |
| 구조체 변수 초기값의 실제 메모리 값, 정렬된 변수의 주소 | 실행으로 확인 |
| `PTR` 없이 쓸 때의 오류, 같은 뜻의 다른 표기와 `ASSUME` | JWasm, 실행으로 확인 |
| 정렬과 캐시 줄 경계에 따른 속도 차이 | 직접 측정 |
| `SYSTEMTIME` 정의, 구조체를 값으로 넘기는 `INVOKE`, WORD 인수의 스택 배치 | Microsoft Learn, JWasm 목록 파일 |
| 공용체의 리틀 엔디언 확인, `INPUT_RECORD`의 이름 없는 멤버(빈 슬라이드 22번 자리) | 실행으로 확인 |
| 매크로와 프로시저 비교, 인수가 텍스트로 치환되는 함정 | 실행으로 확인 |
| 매크로 확장 결과 (`PrintX`, `mPutchar`, `makeString`, `mWrite`, `mWriteln`, `FORC`) | JWasm 목록 파일 |
| `;;` 주석의 동작 | Microsoft Learn(operator ;;), JWasm으로 확인 |
| `Macros.inc`의 내부(`mReadString`, `mShow`), Wraps 프로그램의 실행 결과(빈 슬라이드 35번 자리) | 교재 `Macros.inc`, 실행으로 확인 |
| `IF`와 `.IF`의 차이, `.ERR` | 실행으로 확인 |
| 행의 합 매크로(교재 10.3.6절) | 교재 예제 `RowSum.asm`, 실행으로 확인 |
| 특수 연산자의 실제 출력, `@LINE` | JWasm으로 확인 |
| 매크로 함수 만들기, 텍스트 처리 함수(빈 슬라이드 54번 자리) | JWasm으로 확인 |
| `REPEAT` 예제, 구조체 안의 `REPEAT`, `FOR`로 코드 만들기 | 교재 예제 `Repeat.asm`, 실행으로 확인 |
| 연결 리스트(교재 10.4.5절, 빈 슬라이드 60번 자리)와 `$`의 차이 | 교재 예제 `List.asm`, JWasm 목록 파일, 실행으로 확인 |
| 부록 B (C 컴파일러가 만든 구조체 코드, C 전처리기) | GCC 13 출력 |

---

## 참고 자료

### 예제 값 확인 방법

이 문서의 예제는 눈으로만 검토하지 않고 실제로 돌려서 확인했다.

- `asm` 코드 블록 98개를 MASM 호환 어셈블러(JWasm 2.21)로 어셈블했다. 조각 코드는 프로그램 틀을 씌웠다. Irvine32 프로시저는 같은 이름과 출력 형식으로 만든 리눅스용 대체 라이브러리에 링크했으며, `Random32`·`RandomRange`·`DumpMem`은 원래 라이브러리와 같은 계산식과 출력 형식을 쓰고, `Macros.inc`는 교재의 파일을 그대로 썼다. Windows API 중 `GetStdHandle`, `SetConsoleCursorPosition`, `GetLocalTime`은 같은 이름의 대체 함수를 만들어 썼다(커서 이동은 하지 않고, 시각은 UTC로 채운다).
- 실행 파일을 디버거(gdb)로 한 명령어씩 실행하면서 주석에 적힌 값을 실제 결과와 비교했다. 레지스터와 변수 값뿐 아니라 `rect1.UpperLeft.X`처럼 **구조체 필드**의 값, `WORD PTR AllPoints = [1, 1, 2, 2, 3, 3]`처럼 구조체 배열의 내용도 비교했다. 필드의 주소와 크기는 어셈블러가 직접 계산하게 했다(`OFFSET`, `SIZEOF`, `TYPE`을 담은 확인용 데이터를 프로그램 끝에 붙였다). 매크로 호출 줄의 값은 펼쳐진 코드를 모두 실행한 뒤의 상태와 비교했다. 어셈블 오류·경고가 나야 하는 줄도 확인했다. 이렇게 비교한 항목은 153개이고 모두 일치했다.
- "실행 결과" 블록 25개는 프로그램의 실제 출력과, "어셈블할 때 콘솔에 나오는 내용" 블록 13개는 어셈블러의 실제 콘솔 출력과, "목록 파일" 블록 10개는 JWasm이 만든 목록 파일과 한 줄씩 비교했다. 부록 E의 정답과 부록 F의 풀이도 같은 방법으로 확인했다.
- 10.1절의 정렬 속도는 C로 작성한 측정 프로그램의 결과이고, 부록 B는 GCC 13의 실제 출력이다.

다만 다음은 확인 범위 밖이다.

- Windows의 `ml.exe`와 Visual Studio에서 직접 실행한 것은 아니다. 구조체 배치와 명령어의 동작은 운영체제에 상관없이 같지만, **목록 파일의 형식, 오류·경고 메시지의 문구와 번호**는 MASM과 다르다. `;;` 주석의 목록 표시, 구조체 초기값 안의 `$`처럼 어셈블러에 따라 결과가 달랐던 부분은 본문에 적어 두었다. MASM의 동작으로 적은 부분은 교재·슬라이드와 Microsoft 문서를 근거로 했다.
- 16비트 실제 모드용 `HelloNew`(Irvine16 라이브러리)는 확인하지 않았다.
- ShowTime의 출력은 실행한 시각에 따라 다르므로 형식(`…:…:…`)만 비교했다. 속도 측정값은 이 문서를 만든 환경(Intel Xeon 2.1GHz)에서 잰 것이다.

### 문헌과 링크

- Kip R. Irvine, *Assembly Language for x86 Processors* (7th / 8th Edition), Pearson — Chapter 10. Structures and Macros
- [Kip Irvine 교재 공식 사이트](https://www.asmirvine.com/) (Irvine32 라이브러리, `Macros.inc`와 예제 프로그램)
- [intelligentcm 블로그 — Assembly 카테고리](https://intelligentcm.tistory.com/category/Assembly)
- [Microsoft Learn — Microsoft Macro Assembler(MASM) 참조](https://learn.microsoft.com/ko-kr/cpp/assembler/masm/microsoft-macro-assembler-reference)
- [Microsoft Learn — STRUCT (MASM)](https://learn.microsoft.com/en-us/cpp/assembler/masm/struct-masm), [UNION](https://learn.microsoft.com/en-us/cpp/assembler/masm/union) (구문, 중첩 공용체의 `ENDS`)
- [Microsoft Learn — operator ;;](https://learn.microsoft.com/en-us/cpp/assembler/masm/operator-semicolons) (확장 결과에 나타나지 않는 매크로 주석)
- [Microsoft Learn — REPEAT](https://learn.microsoft.com/en-us/cpp/assembler/masm/repeat), [FOR](https://learn.microsoft.com/en-us/cpp/assembler/masm/for-masm), [FORC](https://learn.microsoft.com/en-us/cpp/assembler/masm/forc) (각각 REPT, IRP, IRPC와 같다)
- [Microsoft Learn — operator OPATTR](https://learn.microsoft.com/en-us/cpp/assembler/masm/operator-opattr)
- [Microsoft Learn — SYSTEMTIME structure](https://learn.microsoft.com/en-us/windows/win32/api/minwinbase/ns-minwinbase-systemtime) (필드 순서, `wDayOfWeek` 0 = 일요일)
- [Intel® 64 and IA-32 Architectures Software Developer's Manuals](https://www.intel.com/content/www/us/en/developer/articles/technical/intel-sdm.html) (Volume 2의 MUL, XLAT, MOVAPS 항목)

<br>

> 이 문서는 강의 슬라이드를 바탕으로 개인 학습용으로 정리한 노트입니다.
