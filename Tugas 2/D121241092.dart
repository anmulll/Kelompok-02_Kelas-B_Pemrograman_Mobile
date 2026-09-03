void main() {
  
  Map<String, int> daftarHarga = {
    'Beras': 12000,
    'Minyak Goreng': 15000,
    'Gula Pasir': 13000,
    'Telur': 28000,
    'Susu Kotak': 18000,
  };

  List<Map<String, dynamic>> daftarBelanjaan = [
    {'nama': 'Beras', 'jumlah': 2},
    {'nama': 'Minyak Goreng', 'jumlah': 1},
    {'nama': 'Telur', 'jumlah': 3},
    {'nama': 'Susu Kotak', 'jumlah': 2},
  ];

  print('===== STRUK BELANJA =====');

  double subtotal = hitungSubtotal(daftarHarga, daftarBelanjaan);

  print('--------------------------');
  print('Subtotal      : Rp${subtotal.toStringAsFixed(0)}');

  double persenDiskon = tentukanDiskon(subtotal);
  double nominalDiskon = subtotal * (persenDiskon / 100);

  double totalAkhir = subtotal - nominalDiskon;

  print('Diskon        : $persenDiskon% (Rp${nominalDiskon.toStringAsFixed(0)})');
  print('--------------------------');
  print('TOTAL AKHIR   : Rp${totalAkhir.toStringAsFixed(0)}');
  print('==========================');
}

double hitungSubtotal(
  Map<String, int> daftarHarga,
  List<Map<String, dynamic>> daftarBelanjaan,
) {
  double subtotal = 0;

  for (var item in daftarBelanjaan) {
    String nama = item['nama'];
    int jumlah = item['jumlah'];

    if (daftarHarga.containsKey(nama)) {
      int hargaSatuan = daftarHarga[nama]!;
      double totalHarga = (hargaSatuan * jumlah).toDouble();
      subtotal += totalHarga;

      print('${nama.padRight(15)} x$jumlah  = Rp${totalHarga.toStringAsFixed(0)}');
    } else {

      print('${nama.padRight(15)} => harga tidak ditemukan, dilewati');
    }
  }

  return subtotal;
}

double tentukanDiskon(double subtotal) {
  double diskon;

  if (subtotal >= 500000) {
    diskon = 20; 
  } else if (subtotal >= 300000) {
    diskon = 15; 
  } else if (subtotal >= 100000) {
    diskon = 10; 
  } else if (subtotal >= 50000) {
    diskon = 5; 
  } else {
    diskon = 0; 
  }

  return diskon;
}