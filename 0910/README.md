
<img width="1276" height="699" alt="image" src="https://github.com/user-attachments/assets/5d4f2d06-21c7-4b39-9305-8ba33c5aedf2" />

이거는 반드시 암기하라고 하심(16개의 레지스터등등)

System bus 
    control, data, address 




```
1단계: Visual Studio 다운로드 및 설치Visual Studio 공식 홈페이지에서 Community 버전(무료)을 다운로드합니다. (이미 깔려 있다면 생략 가능)설치 관리자(Installer) 창이 뜨면, 워크로드 항목 중 C++를 사용한 데스크톱 개발을 반드시 체크하고 설치를 완료합니다. (MASM 컴파일러가 여기에 포함되어 있습니다.)
2단계: 프로젝트 생성 및 MASM(어셈블러) 활성화Visual Studio를 실행하고 새 프로젝트 만들기 ➔ C++ 비어 있는 프로젝트를 선택해 생성합니다.우측 솔루션 탐색기에서 생성된 프로젝트 이름을 마우스 우클릭합니다.빌드 종속성(Build Dependencies) ➔ 빌드 사용자 지정(Build Customizations...)을 클릭합니다.리스트에서 masm 항목의 체크박스를 켜고 확인을 누릅니다. (이제 이 프로젝트에서 어셈블리 코드를 읽을 수 있습니다.)
3단계: .asm 파일 추가 및 속성 변경솔루션 탐색기에서 소스 파일 폴더 우클릭 ➔ 추가 ➔ 새 항목을 누릅니다.파일 이름을 정할 때 확장자를 반드시 main.asm처럼 .asm으로 직접 입력하여 추가합니다. (C++ 파일로 만들어지면 안 됩니다.)추가한 main.asm 파일을 우클릭 ➔ 속성으로 들어갑니다.일반 ➔ 항목 유형 항목이 Microsoft Macro Assembler로 되어 있는지 확인합니다. (자동으로 지정되지만 안 되어 있다면 수동으로 변경해 주세요.)
4단계: 테스트 코드 작성 및 실행새로 만든 main.asm 파일에 아래의 가장 단순한 32비트 테스트 코드를 복사해서 붙여넣습니다.
assembly
.386
.model flat, stdcall
.stack 4096

ExitProcess PROTO, dwExitCode:DWORD

.data
    ; (발표용 변수가 필요하면 여기에 선언)

.code
main PROC
    mov eax, 5      ; EAX 레지스터에 5를 넣음
    add eax, 10     ; EAX 레지스터에 10을 더함 (결과: 15)

    INVOKE ExitProcess, 0
main ENDP
END main
코드를 사용할 때는 주의가 필요합니다.주의: 상단 툴바의 빌드 환경이 x86(또는 Win32)으로 설정되어 있는지 확인합니다. (위 코드는 32비트 기준입니다.)Ctrl + F5를 누르면 빌드가 시작되고, 오류 없이 검은색 콘솔 창(프로그램이 정상 종료되었다는 메시지)이 뜨면 실행 성공입니다.🎤 교수님 앞 발표 꿀팁 (인증 포인트)단순히 검은 창만 보여주면 "진행이 잘 된 건가?" 하실 수 있으므로, 디버깅 모드를 활용해 값이 바뀌는 걸 보여주는 것이 핵심입니다.add eax, 10 줄 왼쪽에 중단점(F9)을 걸어둡니다.F5를 눌러 디버깅을 시작합니다.상단 메뉴에서 디버그 ➔ 창 ➔ 레지스터(Registers)를 켭니다.F10을 한 줄씩 누르면서 오른쪽 레지스터 창의 EAX 값이 0000000F(16진수 15)로 변하는 과정을 보여주면 감점 없는 완벽한 발표가 됩니다.
```
