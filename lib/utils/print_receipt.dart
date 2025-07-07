import 'package:blue_thermal_printer/blue_thermal_printer.dart';

class PrintReceiptService {
  static final BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;

  static Future<void> printReceipt(Map<String, dynamic> trx) async {
    // Cek apakah printer terhubung
    bool? isConnected = await bluetooth.isConnected;
    if (isConnected != true) {
      throw Exception("Tidak ada printer thermal yang terhubung");
    }

    // Mulai cetak
    bluetooth.printCustom("KasirQu", 3, 1);
    bluetooth.printNewLine();
    bluetooth.printLeftRight("Tanggal:", trx['createdAt'].toString(), 1);
    bluetooth.printLeftRight("ID:", trx['_id'], 1);
    bluetooth.printNewLine();

    bluetooth.printCustom("ITEMS", 2, 0);
    final items = trx['items'] as List<dynamic>;
    for (var item in items) {
      final menu = item['menu'];
      bluetooth.printLeftRight(
        menu['name'],
        "${item['quantity']} x ${menu['price']}",
        1,
      );
      bluetooth.printCustom("Subtotal: Rp${item['subtotal']}", 1, 0);
      bluetooth.printNewLine();
    }

    bluetooth.printNewLine();
    bluetooth.printLeftRight("TOTAL", "Rp${trx['total']}", 2);
    bluetooth.printLeftRight("Bayar", "Rp${trx['amountPaid']}", 1);
    bluetooth.printLeftRight("Kembalian", "Rp${trx['change']}", 1);
    bluetooth.printNewLine();
    bluetooth.printCustom("Terima kasih!", 2, 1);
    bluetooth.printNewLine();
    bluetooth.printNewLine();
  }
}
