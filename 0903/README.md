Binary, Hexadecimal, and Boolean Exercises
1. Most Significant Bit (MSB)
문제

In an 8-bit binary number, which is the most significant bit (MSB)?

번역

8비트 이진수에서 최상위 비트(MSB)는 무엇입니까?

풀이

MSB(Most Significant Bit)는 가장 큰 자릿값을 가지는 비트입니다.

8비트 이진수에서는 왼쪽부터 다음과 같이 번호를 붙입니다.

Bit:  7 6 5 4 3 2 1 0
      ↑
     MSB

정답

가장 왼쪽에 있는 비트, 즉 7번 비트

2. Unsigned Binary → Decimal
문제

What is the decimal representation of each of the following unsigned binary integers?

번역

다음 각 부호 없는 이진 정수의 십진수 표현은 무엇입니까?

문제
a. 00110101
b. 10010110
c. 11001100
풀이
a. 00110101

각 비트의 값을 계산합니다.

0×128 + 0×64 + 1×32 + 1×16 + 0×8 + 1×4 + 0×2 + 1×1
= 32 + 16 + 4 + 1
= 53

b. 10010110
1×128 + 0×64 + 0×32 + 1×16 + 0×8 + 1×4 + 1×2 + 0×1
= 128 + 16 + 4 + 2
= 150

c. 11001100
1×128 + 1×64 + 0×32 + 0×16 + 1×8 + 1×4 + 0×2 + 0×1
= 128 + 64 + 8 + 4
= 204

정답
a. 53
b. 150
c. 204
3. Binary Addition
문제

What is the sum of each pair of binary integers?

번역

각 이진 정수 쌍의 합은 무엇입니까?

문제
a. 10101111 + 11011011
b. 10010111 + 11111111
c. 01110101 + 10101100
풀이
a.
  10101111
+ 11011011
-----------
 110001010


따라서:

110001010₂

b.
  10010111
+ 11111111
-----------
 100010110


따라서:

100010110₂

c.
  01110101
+ 10101100
-----------
 100100001


따라서:

100100001₂

정답
a. 110001010
b. 100010110
c. 100100001
4. Binary Subtraction
문제

Calculate binary 00001101 minus 00000111.

번역

이진수 00001101에서 00000111을 뺀 값을 계산하세요.

풀이
  00001101
- 00000111
-----------
  00000110


10진수로 확인하면:

13 - 7 = 6

정답

00000110

5. Data Types and Number of Bits
문제

How many bits are used by each of the following data types?

번역

다음 각 데이터 유형은 몇 비트를 사용합니까?

Data Type	Bits	Bytes
word	16 bits	2 bytes
doubleword	32 bits	4 bytes
quadword	64 bits	8 bytes
double quadword	128 bits	16 bytes
정답
a. word → 16비트 (2바이트)
b. doubleword → 32비트 (4바이트)
c. quadword → 64비트 (8바이트)
d. double quadword → 128비트 (16바이트)
6. Minimum Number of Bits
문제

What is the minimum number of binary bits needed to represent each of the following unsigned decimal integers?

번역

다음 각 부호 없는 10진 정수를 표현하는 데 필요한 최소 이진 비트 수는 얼마입니까?

a. 4095
b. 65534
c. 42319
풀이

부호 없는 n비트로 표현할 수 있는 최대값은:

2ⁿ - 1

a. 4095
2¹² - 1 = 4095


따라서 12비트가 필요합니다.

b. 65534
2¹⁶ - 1 = 65535


65534를 표현하려면 16비트가 필요합니다.

c. 42319
2¹⁵ = 32768
2¹⁶ = 65536

32768 < 42319 < 65536


따라서 16비트가 필요합니다.

정답
a. 12 bits
b. 16 bits
c. 16 bits
7. Binary → Hexadecimal
문제

What is the hexadecimal representation of each of the following binary numbers?

번역

다음 각 이진수의 16진수 표현은 무엇입니까?

문제
a. 0011 0101 1101 1010
b. 1100 1110 1010 0011
c. 1111 1110 1101 1011
풀이

이진수는 4비트씩 묶어서 16진수로 변환합니다.

Binary	Hex
0011	3
0101	5
1101	D
1010	A

따라서:

0011 0101 1101 1010
 ↓    ↓    ↓    ↓
 3    5    D    A

정답
a. 35DA
b. CEA3
c. FEDB
8. Hexadecimal → Binary
문제

What is the binary representation of the following hexadecimal numbers?

번역

다음 16진수들의 이진수 표현은 무엇입니까?

문제
a. 0126F9D4
b. 6ACDFA95
c. F69BDC2A
풀이

각 16진수 한 자리는 정확히 4비트로 표현할 수 있습니다.

a. 0126F9D4
0    1    2    6    F    9    D    4
0000 0001 0010 0110 1111 1001 1101 0100

정답
a. 0000 0001 0010 0110 1111 1001 1101 0100
b. 0110 1010 1100 1101 1111 1010 1001 0101
c. 1111 0110 1001 1011 1101 1100 0010 1010
9. Hexadecimal → Unsigned Decimal
문제

What is the unsigned decimal representation of each of the following hexadecimal integers?

문제
a. 3A
b. 1BF
c. 1001
풀이

16진수는 각 자리의 값을 16ⁿ으로 계산합니다.

a. 3A
3 × 16 + 10
= 48 + 10
= 58

b. 1BF
1 × 16² + 11 × 16 + 15
= 256 + 176 + 15
= 447

c. 1001
1 × 16³ + 0 × 16² + 0 × 16 + 1
= 4096 + 1
= 4097

정답
a. 58
b. 447
c. 4097
10. Hexadecimal → Unsigned Decimal
문제
a. 62
b. 4B3
c. 29F
풀이
a. 62
6 × 16 + 2
= 96 + 2
= 98

b. 4B3
4 × 16² + 11 × 16 + 3
= 1024 + 176 + 3
= 1203

c. 29F
2 × 16² + 9 × 16 + 15
= 512 + 144 + 15
= 671

정답
a. 98
b. 1203
c. 671
11. Signed Decimal → 16-bit Hexadecimal
문제

What is the 16-bit hexadecimal representation of each of the following signed decimal integers?

문제
a. -24
b. -331
풀이

음수를 표현할 때 **2의 보수(two's complement)**를 사용합니다.

16비트에서:

-24 → 65536 - 24
    = 65512
    = FFE8₁₆

-331 → 65536 - 331
     = 65205
     = FEB5₁₆

정답
a. FFE8
b. FEB5
12. Signed Decimal → 16-bit Hexadecimal
문제
a. -21
b. -45
풀이
-21 → 65536 - 21
    = 65515
    = FFEB₁₆

-45 → 65536 - 45
    = 65491
    = FFD3₁₆

정답
a. FFEB
b. FFD3
13. 16-bit Hexadecimal → Signed Decimal
문제

The following 16-bit hexadecimal numbers represent signed integers. Convert each to decimal.

문제
a. 6BF9
b. C123
풀이

16비트 signed integer에서는 가장 왼쪽 비트가 0이면 양수, 1이면 음수입니다.

a. 6BF9

첫 번째 16진수 6은 이진수 0110이므로 양수입니다.

6BF9₁₆ = 27641₁₀

b. C123

C는 이진수 1100이므로 음수입니다.

2의 보수를 이용하면:

C123 - 10000 = -3EDD


또는

0xC123 = 49443
49443 - 65536 = -16093

정답
a. 27641
b. -16093
14. 16-bit Hexadecimal → Signed Decimal
문제
a. 4CD2
b. 8230
풀이
a. 4CD2

첫 번째 비트가 0이므로 양수입니다.

4CD2₁₆ = 19666₁₀

b. 8230

8은 이진수 1000이므로 음수입니다.

0x8230 = 33328
33328 - 65536 = -32208

정답
a. 19666
b. -32208
15. Signed Binary → Decimal
문제

What is the decimal representation of each of the following signed binary numbers?

문제
a. 10110101
b. 00101010
c. 11110000
풀이

8비트 signed binary는 2의 보수를 사용합니다.

a. 10110101

MSB가 1이므로 음수입니다.

비트를 반전:

01001010


1을 더하면:

01001011 = 75


따라서:

10110101 = -75

b. 00101010

MSB가 0이므로 양수입니다.

32 + 8 + 2 = 42

c. 11110000

비트를 반전:

00001111


1을 더하면:

00010000 = 16


따라서:

11110000 = -16

정답
a. -75
b. 42
c. -16
16. Signed Binary → Decimal
문제
a. 10000000
b. 11001100
c. 10110111
풀이
a. 10000000

8비트 2의 보수에서:

10000000 = -128

b. 11001100

반전:

00110011


1을 더하면:

00110100 = 52


따라서:

11001100 = -52

c. 10110111

반전:

01001000


1을 더하면:

01001001 = 73


따라서:

10110111 = -73

정답
a. -128
b. -52
c. -73
17. Signed Decimal → 8-bit Binary
문제

What is the 8-bit binary (two’s-complement) representation of each of the following signed decimal integers?

문제
a. -5
b. -42
c. -16
풀이

음수의 2의 보수는:

양수의 이진수 작성
모든 비트 반전
1을 더함
a. -5
  00000101
→ 11111010  (반전)
→ 11111011  (+1)

b. -42
  00101010
→ 11010101
→ 11010110

c. -16
  00010000
→ 11101111
→ 11110000

정답
a. 11111011
b. 11010110
c. 11110000
18. Signed Decimal → 8-bit Binary
문제
a. -72
b. -98
c. -26
풀이
a. -72
72  = 01001000
반전 = 10110111
+1   = 10111000

b. -98
98  = 01100010
반전 = 10011101
+1   = 10011110

c. -26
26  = 00011010
반전 = 11100101
+1   = 11100110

정답
a. 10111000
b. 10011110
c. 11100110
19. Hexadecimal Addition
문제

What is the sum of each pair of hexadecimal integers?

문제
a. 6B4 + 3FE
b. A49 + 6BD
풀이
a.
   6B4
 + 3FE
 -----
   AB2

b.
   A49
 + 6BD
 -----
  1106

정답
a. AB2
b. 1106
20. Hexadecimal Addition
문제
a. 7C4 + 3BE
b. B69 + 7AD
풀이
a.
   7C4
 + 3BE
 -----
  1182

b.
   B69
 + 7AD
 -----
  1316

정답
a. 1182
b. 1316
21. ASCII Character: Capital B
문제

What are the hexadecimal and decimal representations of the ASCII character capital B?

풀이

ASCII에서 대문자 B는:

Binary  : 0100 0010
Hex     : 42
Decimal : 66

정답
Hexadecimal: 42
Decimal: 66
22. ASCII Character: Capital G
문제

What are the hexadecimal and decimal representations of the ASCII character capital G?

풀이

ASCII에서 대문자 G는:

Binary  : 0100 0111
Hex     : 47
Decimal : 71

정답
Hexadecimal: 47
Decimal: 71
23. Challenge: 129-bit Unsigned Integer
문제

What is the largest decimal value you can represent, using a 129-bit unsigned integer?

풀이

부호 없는 n비트의 최댓값은:

2ⁿ - 1


따라서 129비트의 최댓값은:

2¹²⁹ - 1


계산하면:

2¹²⁹ = 680564733841876926926749214863536422912


따라서:

2¹²⁹ - 1
= 680564733841876926926749214863536422911

정답

680564733841876926926749214863536422911

24. Challenge: 86-bit Signed Integer
문제

What is the largest decimal value you can represent, using a 86-bit signed integer?

풀이

2의 보수 signed integer의 최댓값은:

2ⁿ⁻¹ - 1


86비트이므로:

2⁸⁵ - 1


계산하면:

2⁸⁵ = 38685626227668133590597632


따라서:

2⁸⁵ - 1
= 38685626227668133590597631

정답

38685626227668133590597631

25. Boolean Function: ¬(A ∨ B)
문제

Create a truth table to show all possible inputs and outputs for the boolean function described by ¬(A ∨ B).

번역

불리언 함수 ¬(A ∨ B)의 모든 가능한 입력과 출력을 나타내는 진리표를 작성하세요.

풀이

먼저 A ∨ B를 계산하고 결과를 NOT(¬) 합니다.

A	B	A ∨ B	¬(A ∨ B)
0	0	0	1
0	1	1	0
1	0	1	0
1	1	1	0
정답
A	B	Output
0	0	1
0	1	0
1	0	0
1	1	0
26. Boolean Function: (¬A ∧ ¬B)
문제

Create a truth table to show all possible inputs and outputs for the boolean function described by (¬A ∧ ¬B). How would you describe the rightmost column of this table in relation to the table from question number 25? Have you heard of De Morgan’s Theorem?

번역

불리언 함수 (¬A ∧ ¬B)의 모든 가능한 입력과 출력을 나타내는 진리표를 작성하세요.

풀이
A	B	¬A	¬B	¬A ∧ ¬B
0	0	1	1	1
0	1	1	0	0
1	0	0	1	0
1	1	0	0	0

25번 문제의 ¬(A ∨ B) 결과와 비교하면 오른쪽 열의 결과가 완전히 동일합니다.

즉,

¬(A ∨ B) = ¬A ∧ ¬B


이것은 De Morgan's Theorem(드모르간의 법칙) 중 하나입니다.

정답

25번 문제와 26번 문제의 최종 출력은 동일합니다.

¬(A ∨ B) = ¬A ∧ ¬B

27. Truth Table Rows
문제

If a boolean function has four inputs, how many rows are required for its truth table?

풀이

입력이 n개인 불리언 함수의 진리표 행 수는:

2ⁿ


입력이 4개이므로:

2⁴ = 16

정답

16 rows

28. Four-input Multiplexer
문제

How many selector bits are required for a four-input multiplexer?

번역

4입력 멀티플렉서에는 몇 개의 선택 비트(selector bits)가 필요합니까?

풀이

멀티플렉서에서 선택 비트의 개수는:

2ⁿ = 입력 개수


4개의 입력을 선택하려면:

2ⁿ = 4
2² = 4


따라서 선택 비트는 2개가 필요합니다.

예를 들어:

S1 S0

00 → Input 0
01 → Input 1
10 → Input 2
11 → Input 3

정답

2 selector bits
