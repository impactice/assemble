Five Number Average Calculator (Assembly)
1. 프로젝트 소개

본 프로젝트는 Assembly 언어를 사용하여 사용자로부터 5개의 정수를 입력받고, 입력된 숫자의 평균을 계산하여 출력하는 프로그램입니다.

Microsoft Visual Studio 환경에서 MASM(Microsoft Macro Assembler)을 사용하여 개발하였습니다.

2. 개발 환경
항목	내용
IDE	Visual Studio
Language	Assembly (MASM)
Architecture	x86 (32-bit)
Operating System	Windows
Library	Kernel32.lib
Input API	ReadConsoleW
Output API	WriteConsoleW
3. 주요 기능
사용자로부터 정수 5개 입력
입력 문자열을 정수형으로 변환
입력된 숫자들의 합계 계산
합계를 5로 나누어 평균 계산
계산된 평균을 콘솔에 출력
양수 및 음수 입력 지원
4. 프로그램 동작 과정
GetStdHandle 함수를 사용하여 콘솔 입력 및 출력 핸들을 가져옵니다.
WriteConsoleW 함수를 사용하여 숫자 입력 안내 메시지를 출력합니다.
ReadConsoleW 함수를 사용하여 사용자로부터 숫자를 입력받습니다.
입력된 문자열을 정수형으로 변환합니다.
변환된 숫자를 배열에 저장하고 합계를 계산합니다.
5개의 숫자 입력이 완료되면 합계를 5로 나눕니다.
계산된 평균을 문자열로 변환합니다.
WriteConsoleW 함수를 사용하여 평균을 출력합니다.
5. 사용된 주요 명령어 및 함수
명령어 / 함수	설명
MOV	데이터 이동
ADD	덧셈
SUB	뺄셈
IMUL	부호 있는 곱셈
IDIV	부호 있는 나눗셈
CDQ	EAX의 부호를 EDX로 확장
NEG	부호 반전
CMP	값 비교
JMP	무조건 분기
JE	값이 같을 때 분기
JL	부호 있는 비교에서 작을 때 분기
ReadConsoleW	콘솔 입력
WriteConsoleW	콘솔 출력
GetStdHandle	콘솔 핸들 획득
ExitProcess	프로그램 종료
6. 실행 예시
입력
text
Enter 5 numbers:
10
20
30
40
50

출력
text
Average: 30

음수 입력 예시
text
Enter 5 numbers:
-10
20
30
40
50

Average: 26

7. 참고 사항
입력은 정수 5개를 한 줄씩 입력하는 방식입니다.
양수와 음수를 지원합니다.
평균 계산은 정수 나눗셈을 사용하므로 소수점 이하 값은 버립니다.
32비트(x86) MASM 환경에서 실행해야 합니다.
숫자 입력은 유효한 정수라는 전제로 작성되었습니다.
8. 실행 방법
Visual Studio에서 프로젝트를 생성합니다.
MASM 빌드 사용자 지정을 활성화합니다.
프로젝트 플랫폼을 x86으로 설정합니다.
Assembly 소스 파일(.asm)을 프로젝트에 추가합니다.
빌드 및 실행합니다.

Project: Five Number Average Calculator
Language: MASM Assembly
IDE: Microsoft Visual Studio
