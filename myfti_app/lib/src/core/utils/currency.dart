/// Format angka rupiah tanpa desimal: 1500000 -> "Rp 1.500.000"
String formatRupiah(int amount) {
  final digits = amount.abs().toString();
  final buffer = StringBuffer();

  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }

  return '${amount < 0 ? '-' : ''}Rp $buffer';
}
