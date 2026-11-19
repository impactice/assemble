// Visual Studio / MSVC: build for x86 (Win32), NOT x64.
// Save as a .cpp file. No Irvine32 or separate .asm file is required.
#include <iostream>
#include <iomanip>
#include <cstdint>
#include <string>

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error This program requires Microsoft Visual C++ with the x86 (Win32) target.
#endif

// Print register snapshots as four-digit uppercase hexadecimal values.
void printRegisters(
    unsigned short regAX,
    unsigned short regBX,
    unsigned short regCX,
    unsigned short regDX)
{
    const auto oldFlags = std::cout.flags();
    const auto oldFill = std::cout.fill();

    std::cout << std::hex << std::uppercase << std::setfill('0')
              << "  AX = " << std::setw(4) << regAX
              << "  BX = " << std::setw(4) << regBX
              << "  CX = " << std::setw(4) << regCX
              << "  DX = " << std::setw(4) << regDX
              << '\n';

    std::cout.flags(oldFlags);
    std::cout.fill(oldFill);
}

// Combine saved DX:AX without repeating the arithmetic calculation.
std::uint32_t combineWords(
    unsigned short highWord,
    unsigned short lowWord)
{
    return (static_cast<std::uint32_t>(highWord) << 16)
         | static_cast<std::uint32_t>(lowWord);
}

// Strict decimal token input: rejects signs, letters, decimal points,
// missing values and values above 65535.
bool readUInt16(unsigned short& value)
{
    std::string token;
    if (!(std::cin >> token))
        return false;

    unsigned int result = 0;
    for (char ch : token)
    {
        if (ch < '0' || ch > '9')
            return false;

        result = result * 10 + static_cast<unsigned int>(ch - '0');
        if (result > 65535)
            return false;
    }

    value = static_cast<unsigned short>(result);
    return true;
}

int main()
{
    unsigned short numberA = 0;
    unsigned short numberB = 0;

    std::cout << "First number (0..65535): ";
    if (!readUInt16(numberA))
    {
        std::cout << "Invalid input.\n";
        return 1;
    }

    std::cout << "Second number (0..65535): ";
    if (!readUInt16(numberB))
    {
        std::cout << "Invalid input.\n";
        return 1;
    }

    unsigned short regAX = 0;
    unsigned short regBX = 0;
    unsigned short regCX = 0;
    unsigned short regDX = 0;

    // ADD: unsigned DX:AX = A + B.
    __asm
    {
        mov ax, numberA
        mov bx, numberB
        xor cx, cx
        xor dx, dx

        add ax, bx
        adc dx, 0

        mov regAX, ax
        mov regBX, bx
        mov regCX, cx
        mov regDX, dx
    }

    const std::uint32_t addResult = combineWords(regDX, regAX);
    std::cout << "\n[ADD] Result = " << addResult << '\n';
    printRegisters(regAX, regBX, regCX, regDX);

    // SUB: signed DX:AX = A - B.
    __asm
    {
        mov ax, numberA
        mov bx, numberB
        xor cx, cx
        xor dx, dx

        sub ax, bx
        sbb dx, 0

        mov regAX, ax
        mov regBX, bx
        mov regCX, cx
        mov regDX, dx
    }

    // Interpret the saved result, whose range is -65535..65535.
    std::int32_t subResult = static_cast<std::int32_t>(regAX);
    if (regDX == 0xFFFF)
        subResult -= 65536;

    std::cout << "\n[SUB] Result = " << subResult << '\n';
    printRegisters(regAX, regBX, regCX, regDX);

    // MUL: unsigned DX:AX = A * B.
    __asm
    {
        mov ax, numberA
        mov bx, numberB
        xor cx, cx
        xor dx, dx

        mul bx

        mov regAX, ax
        mov regBX, bx
        mov regCX, cx
        mov regDX, dx
    }

    const std::uint32_t mulResult = combineWords(regDX, regAX);
    std::cout << "\n[MUL] Result = " << mulResult << '\n';
    printRegisters(regAX, regBX, regCX, regDX);

    // DIV: AX = quotient, DX = remainder.
    if (numberB == 0)
    {
        std::cout << "\n[DIV] Cannot divide by zero.\n";
    }
    else
    {
        __asm
        {
            mov ax, numberA
            mov bx, numberB
            xor cx, cx
            xor dx, dx

            div bx

            mov regAX, ax
            mov regBX, bx
            mov regCX, cx
            mov regDX, dx
        }

        std::cout << "\n[DIV] Quotient = " << regAX
                  << ", Remainder = " << regDX << '\n';
        printRegisters(regAX, regBX, regCX, regDX);
    }

    return 0;
}
