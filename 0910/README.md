
<img width="1276" height="699" alt="image" src="https://github.com/user-attachments/assets/5d4f2d06-21c7-4b39-9305-8ba33c5aedf2" />

이거는 반드시 암기하라고 하심(16개의 레지스터등등)

# x86 Processor Architecture & PC Components

## 1. 개요 (Overview)
본 문서는 x86 프로세서의 기본 아키텍처, 32비트 및 64비트 작동 모드, 주요 레지스터 구조, 그리고 PC 주요 구성요소 및 입출력(I/O) 시스템에 대해 정리한 자료입니다.

## 2. x86 프로세서 아키텍처 (x86 Processor Architecture)
### 명령어 실행 주기 (Instruction Execution Cycle)
1. **Fetch Instruction**: 메모리에서 명령어를 가져옵니다.
2. **Decode Instruction**: 명령어의 이진 패턴을 분석합니다.
3. **Fetch Operands**: 레지스터나 메모리에서 피연산자를 가져옵니다.
4. **Execute Instruction**: 명령어를 실행합니다.
5. **Update Status Flags**: Zero, Carry, Overflow 등 상태 플래그를 업데이트합니다.
6. **Store Result**: 결과를 출력 피연산자에 저장합니다.

### 32-bit vs 64-bit 프로세서
* **32-Bit (x86)**: 
  * 범용 레지스터(EAX, EBX 등) 및 세그먼트 레지스터(CS, DS 등) 사용.
  * 보호 모드(Protected Mode), 실제 주소 모드(Real-Address Mode), 가상-8086 모드 지원.
  * 초창기 별도 칩이었던 FPU(부동소수점 연산 장치)가 Intel486부터 프로세서에 통합됨.
* **64-Bit (x86-64)**:
  * 기본 피연산자 크기는 32비트이나 REX 접두사를 통해 64비트로 확장.
  * R8~R15 번호 지정 레지스터를 추가 확장하여 64비트 피연산자 처리 지원.

## 3. PC 주요 구성 요소 (Components of a Typical x86 Computer)
* **Motherboard (메인보드)**: CPU 소켓, BIOS 칩, CMOS RAM, 메모리 슬롯, PCI 버스 커넥터, 대용량 저장장치 커넥터 등을 물리적으로 연결하는 중심 축.
* **CPU**: 시스템의 두뇌 역할을 하는 중앙 처리 장치.
* **Chipset**: 메모리, 그래픽, I/O 간의 데이터 흐름을 제어 (예: Intel P965 Express 칩셋).
* **Main Memory**: 빠른 데이터 접근을 위해 실행 중인 프로그램과 데이터를 임시 저장.
* **Input/Output Devices**: 키보드, 마우스 등 사용자와 상호작용하기 위한 입출력 포트 연결.

## 4. 입출력 시스템 (Input-Output System)
하드웨어 입출력 처리는 계층적(Layered)으로 이루어집니다.
1. **Level 3 (Application Program)**: 응용 프로그램에서 표준 라이브러리 함수 호출.
2. **Level 2 (OS Function)**: 운영체제가 디바이스 I/O 요청 수신 및 관리.
3. **Level 1 (BIOS Function)**: 하드웨어 종속적인 BIOS 서브루틴을 통해 제어.
4. **Level 0 (Hardware)**: 실제 컨트롤러(예: 비디오 컨트롤러)가 물리적 신호로 변환하여 동작 수행.



