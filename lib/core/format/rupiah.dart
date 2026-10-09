import 'package:flutter/services.dart';

/// Format Rupiah konsisten seluruh app: Rp8.000.000 (PRD 3.4).
String formatRupiah(int value) {
  final negative = value < 0;
  final digits = value.abs().toString();
  final grouped = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) {
      grouped.write('.');
    }
    grouped.write(digits[i]);
  }
  return '${negative ? '-' : ''}Rp$grouped';
}

/// Ambil digit dari teks input currency, mis. "Rp8.000.000" -> 8000000.
int parseRupiah(String raw) {
  final digits = raw.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return 0;
  return int.tryParse(digits) ?? 0;
}

/// Input formatter: hanya digit, tampil sebagai Rp8.000.000.
class RupiahInputFormatter extends TextInputFormatter {
  const RupiahInputFormatter();

  static const int _maxDigits = 15;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > _maxDigits) {
      digits = digits.substring(0, _maxDigits);
    }
    digits = digits.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }
    final text = formatRupiah(int.parse(digits));
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
