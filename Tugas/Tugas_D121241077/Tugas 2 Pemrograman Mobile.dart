import 'dart:io';

void main() {
  Map<String, int> daftarHarga = {
    'beras': 15000,
    'gula': 13000,
    'minyak': 18000,
    'telur': 30000,
    'kopi': 25000,
  };

  tampilkanDaftarHarga(daftarHarga);

  List<Map<String, dynamic>> daftarBelanjaan = inputDaftarBelanjaan(daftarHarga);

  tampilkanStruk(daftarBelanjaan, daftarHarga);
}

void tampilkanDaftarHarga(Map<String, int> daftarHarga) {
  print('=' * 40);
  print('           DAFTAR HARGA');
  print('=' * 40);

  daftarHarga.forEach((nama, harga) {
    String namaTampil = nama[0].toUpperCase() + nama.substring(1);
    print('${namaTampil.padRight(10)} : Rp$harga');
  });

  print('=' * 40);
}

List<Map<String, dynamic>> inputDaftarBelanjaan(Map<String, int> daftarHarga) {
  List<Map<String, dynamic>> daftarBelanjaan = [];

  stdout.write('Jumlah barang yang mau dibeli? ');
  int jumlahBeli = int.parse(stdin.readLineSync()!);

  for (int i = 0; i < jumlahBeli; i++) {
    stdout.write('Nama barang belanjaan ke-${i + 1}: ');
    String nama = stdin.readLineSync()!.trim().toLowerCase();

    if (!daftarHarga.containsKey(nama)) {
      print("'$nama' tidak ada di daftar harga, silakan input ulang.");
      i--;
      continue;
    }

    stdout.write('Jumlah $nama: ');
    int jumlah = int.parse(stdin.readLineSync()!);

    daftarBelanjaan.add({'nama': nama, 'jumlah': jumlah});
  }

  return daftarBelanjaan;
}

double hitungSubtotal(
  List<Map<String, dynamic>> belanjaan,
  Map<String, int> harga,
) {
  double subtotal = 0.0;

  for (var item in belanjaan) {
    String nama = item['nama'];
    int jumlah = item['jumlah'];

    if (harga.containsKey(nama)) {
      int hargaSatuan = harga[nama]!;
      subtotal += hargaSatuan * jumlah;
    }
  }

  return subtotal;
}

Map<String, double> hitungDiskon(double subtotal) {
  double persenDiskon;

  if (subtotal >= 200000) {
    persenDiskon = 0.20;
  } else if (subtotal >= 100000) {
    persenDiskon = 0.10;
  } else if (subtotal >= 50000) {
    persenDiskon = 0.05;
  } else {
    persenDiskon = 0.0;
  }

  double nominalDiskon = subtotal * persenDiskon;

  return {
    'persen': persenDiskon,
    'nominal': nominalDiskon,
  };
}

void tampilkanStruk(
  List<Map<String, dynamic>> belanjaan,
  Map<String, int> harga,
) {
  print('=' * 40);
  print('           STRUK BELANJA');
  print('=' * 40);

  for (var item in belanjaan) {
    String nama = item['nama'];
    int jumlah = item['jumlah'];

    if (harga.containsKey(nama)) {
      int hargaSatuan = harga[nama]!;
      int totalItem = hargaSatuan * jumlah;
      String namaTampil = nama[0].toUpperCase() + nama.substring(1);
      print(
        '${namaTampil.padRight(10)} x${jumlah.toString().padRight(3)} '
        '@Rp$hargaSatuan = Rp$totalItem',
      );
    }
  }

  double subtotal = hitungSubtotal(belanjaan, harga);
  Map<String, double> diskon = hitungDiskon(subtotal);
  double persenDiskon = diskon['persen']!;
  double nominalDiskon = diskon['nominal']!;
  double totalAkhir = subtotal - nominalDiskon;

  print('-' * 40);
  print('Subtotal        : Rp${subtotal.toStringAsFixed(0)}');
  print(
    'Diskon (${(persenDiskon * 100).toInt()}%)     : '
    'Rp${nominalDiskon.toStringAsFixed(0)}',
  );
  print('Total Akhir     : Rp${totalAkhir.toStringAsFixed(0)}');
  print('=' * 40);
}