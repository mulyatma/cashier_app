import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

class PdfReceiptService {
  static Future<void> generateAndSharePdf(Map<String, dynamic> trx) async {
    final pdf = pw.Document();

    final items = trx['items'] as List<dynamic>;

    pdf.addPage(
      pw.Page(
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(
                  'KasirQu',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text('Tanggal: ${trx['createdAt']}'),
              pw.Text('ID Transaksi: ${trx['_id']}'),
              pw.Divider(),
              ...items.map((item) {
                final menu = item['menu'];
                return pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Expanded(child: pw.Text(menu['name'])),
                    pw.Text("${item['quantity']} x ${menu['price']}"),
                    pw.Text("Rp${item['subtotal']}"),
                  ],
                );
              }),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [pw.Text("Total"), pw.Text("Rp${trx['total']}")],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [pw.Text("Bayar"), pw.Text("Rp${trx['amountPaid']}")],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [pw.Text("Kembalian"), pw.Text("Rp${trx['change']}")],
              ),
              pw.SizedBox(height: 8),
              pw.Center(child: pw.Text("Terima kasih telah berbelanja!")),
            ],
          );
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File("${output.path}/struk_${trx['_id']}.pdf");
    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles([XFile(file.path)], text: "Struk Transaksi");
  }
}
