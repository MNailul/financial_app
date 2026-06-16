import 'package:flutter/material.dart';

class FaqPage extends StatelessWidget {
  const FaqPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text(
          'Bantuan & FAQ',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          const Text(
            'Pertanyaan yang Sering Diajukan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          _buildFaqItem(
            'Bagaimana cara menambah transaksi?',
            'Anda dapat menekan tombol tambah (+) di halaman utama atau halaman transaksi, lalu pilih Pemasukan atau Pengeluaran, isi nominal, pilih kategori, dan simpan.',
          ),
          _buildFaqItem(
            'Apakah data saya aman?',
            'Semua data Anda disimpan secara lokal di perangkat ini menggunakan SQLite sehingga data sepenuhnya aman dan hanya bisa diakses oleh Anda.',
          ),
          _buildFaqItem(
            'Bagaimana cara menambah kategori baru?',
            'Buka menu Pengaturan, lalu pilih "Kelola Kategori". Di sana Anda bisa menambahkan kategori baru dengan ikon dan warna khusus.',
          ),
          _buildFaqItem(
            'Bagaimana fitur Pengingat bekerja?',
            'Fitur pengingat akan muncul di halaman utama untuk membantu Anda mengingat tagihan atau hal terkait finansial lainnya. Anda bisa mencentang pengingat jika sudah selesai.',
          ),
        ],
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 5,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
        iconColor: const Color(0xFF2563EB),
        collapsedIconColor: Colors.grey[600],
        childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
        children: [
          Text(
            answer,
            style: TextStyle(
              color: Colors.grey[700],
              height: 1.5,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
