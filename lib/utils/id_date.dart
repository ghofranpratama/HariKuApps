// Helper tanggal Bahasa Indonesia (tanpa package intl).

const _dayNames = [
  'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu',
];
const _monthLong = [
  'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
  'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
];
const _monthShort = [
  'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
  'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
];

String dayName(DateTime d) => _dayNames[d.weekday - 1];
String monthLong(DateTime d) => _monthLong[d.month - 1];
String monthShort(DateTime d) => _monthShort[d.month - 1];
String shortDate(DateTime d) => '${d.day} ${monthShort(d)}';
String longDate(DateTime d) => '${d.day} ${monthLong(d)} ${d.year}';

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Selisih hari a - b (positif jika a setelah b).
int daysBetween(DateTime a, DateTime b) =>
    DateTime.utc(a.year, a.month, a.day)
        .difference(DateTime.utc(b.year, b.month, b.day))
        .inDays;

String _two(int n) => n.toString().padLeft(2, '0');

/// Format yyyy-MM-dd untuk dikirim ke API.
String formatApiDate(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${_two(d.month)}-${_two(d.day)}';

String formatHm(DateTime d) => '${_two(d.hour)}:${_two(d.minute)}';
