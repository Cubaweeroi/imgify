#!/bin/bash
set -u
FAIL=0
PASS=0

run_case() {
	local name="$1"
	local input="$2"

	bin2png -i "$input" -o /tmp/test_out.png > /tmp/bin2png.log 2>&1
	local rc1=$?
	if [ $rc1 -ne 0 ]; then
		echo "[ОШИБКА] $name: bin2png остановлен с ошибкой $rc1"
		FAIL=$((FAIL+1))
		return
	fi

	png2bin -i /tmp/test_out.png -o /tmp/test_out.bin > /tmp/png2bin.log 2>&1
	local rc2=$?
	if [ $rc2 -ne 0 ]; then
		echo "[ОШИБКА] $name: png2bin остановлен с ошибкой $rc2"
		FAIL=$((FAIL+1))
		return
	fi

	if diff -q "$input" /tmp/test_out.bin > /dev/null; then
		echo "[ВЫПОЛНЕНО] $name"
		PASS=$((PASS+1))
	else
		echo "[ОШИБКА] $name: round-trip проверка не сошлась"
		FAIL=$((FAIL+1))
	fi

	rm -f /tmp/test_out.png /tmp/test_out.bin
}

# Кейс 1: обычный текстовый файл (README.md)
run_case "обычный текстовый файл (README.md)" "README.md"

# Кейс 2: маленький файл (1 байт)
printf 'a' > /tmp/tiny.bin
run_case "маленький файл (1 байт)" "/tmp/tiny.bin"

# Кейс 3: файл, не требующий padding
head -c 400 /dev/urandom > /tmp/exact.bin  # 10*10*4 = 400 байт
run_case "файл, не требующий padding" "/tmp/exact.bin"

# Кейс 4: файл, требующий padding
head -c 397 /dev/urandom > /tmp/padded.bin
run_case "файл, требующий padding " "/tmp/padded.bin"

# Кейс 5: большой файл (100 кБ)
head -c 100000 /dev/urandom > /tmp/big.bin
run_case "большой файл (100 кБ)" "/tmp/big.bin"

# Кейс 6-7: произвольный pad_byte на файле, требующем padding
run_case "произвольный pad_byte 0x00" "/tmp/padded.bin" "-p 0"
run_case "произвольный pad_byte 255" "/tmp/padded.bin" "-p 255"

# Кейс 8: некорректный pad_byte (вне диапазона 0-255)
bin2png -i README.md -o /tmp/x.png -p 999 > /tmp/badpad.log 2>&1
rc=$?
if [ $rc -eq 1 ]; then
	echo "[ВЫПОЛНЕНО] некорректный pad_byte (вне диапазона 0-255): отказано с ошибкой $rc"
	PASS=$((PASS+1))
else
	echo "[ОШИБКА] некорректный pad_byte (вне диапазона 0-255): ожидалась ошибка 1, отказано с ошибкой $rc"
	FAIL=$((FAIL+1))
fi

# Кейс 9: некорректные аргументы (без -o) 
# (ловится падение по сигналу 139 = SIGSEGV или 134 = SIGABRT)
bin2png -i README.md > /tmp/badargs.log 2>&1
rc=$?
if [ $rc -eq 139 ] || [ $rc -eq 134 ]; then
	echo "[ОШИБКА?] некорректные аргументы (без -o):  падение программы с ошибкой $rc – смотрите /tmp/badargs.log"
	FAIL=$((FAIL+1))
elif [ $rc -ne 0 ]; then
	echo "[ВЫПОЛНЕНО] некорректные аргументы (без -o):  отказано с ошибкой $rc "
	PASS=$((PASS+1))
else
	echo "[ОШИБКА] некорректные аргументы (без -o):  не отказано "
	FAIL=$((FAIL+1))
fi

# Кейс 10: некорректные аргументы (без -i)
bin2png -o /tmp/x.png > /tmp/badargs2.log 2>&1
rc=$?
if [ $rc -eq 139 ] || [ $rc -eq 134 ]; then
	echo "[ОШИБКА?] некорректные аргументы (без -i):  падение программы с ошибкой $rc – смотрите /tmp/badargs2.log"
	FAIL=$((FAIL+1))
elif [ $rc -ne 0 ]; then
	echo "[ВЫПОЛНЕНО] некорректные аргументы (без -i):  отказано с ошибкой $rc "
	PASS=$((PASS+1))
else
	echo "[ОШИБКА] некорректные аргументы (без -i):  не отказано "
	FAIL=$((FAIL+1))
fi

# Кейс 11: несуществующий входной файл
bin2png -i /no/such/file -o /tmp/x.png > /tmp/badfile.log 2>&1
rc=$?
if [ $rc -ne 0 ]; then
	echo "[ВЫПОЛНЕНО] несуществующий входной файл: отказано с ошибкой $rc"
	PASS=$((PASS+1))
else
	echo "[ОШИБКА] несуществующий входной файл: не отказано"
	FAIL=$((FAIL+1))
fi

rm -f /tmp/tiny.bin /tmp/exact.bin /tmp/padded.bin /tmp/big.bin

echo "----"
echo "ВЫПОЛНЕНО: $PASS, ОШИБКА: $FAIL"
if [ $FAIL -ne 0 ]; then
	exit 1
fi
exit 0

