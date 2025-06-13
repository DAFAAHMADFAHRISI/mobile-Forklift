import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'admin_theme.dart';

class DaftarFeedback extends StatefulWidget {
  const DaftarFeedback({super.key});

  @override
  State<DaftarFeedback> createState() => _DaftarFeedbackState();
}

class _DaftarFeedbackState extends State<DaftarFeedback> {
  List<Map<String, dynamic>> _feedbacks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchFeedbacks();
  }

  Future<void> fetchFeedbacks() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.get(
        Uri.parse('http://192.168.1.21:3000/api/feedback'),
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List feedbackList = data['data'];
        setState(() {
          _feedbacks = feedbackList
              .map<Map<String, dynamic>>((item) => {
                    'id': item['id_feedback'],
                    'order_id': item['id_pemesanan'],
                    'user_name': 'User #${item['id_user']}',
                    'rating': item['rating'],
                    'komentar': item['komentar'],
                    'tanggal': item['tanggal'].substring(0, 10),
                  })
              .toList();
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mengambil data feedback.')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> deleteFeedback(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.delete(
        Uri.parse('http://192.168.1.21:3000/api/feedback/delete/$id'),
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        setState(() {
          _feedbacks.removeWhere((f) => f['id'] == id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Feedback berhasil dihapus')),
        );
      } else {
        print('Delete error: \\${response.statusCode} - \\${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Gagal menghapus feedback: \\${response.body}')),
        );
      }
    } catch (e) {
      print('Delete exception: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                color: Colors.white, size: 20),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ),
        title: Text('Daftar Feedback', style: AdminTheme.appBarTitle),
        backgroundColor: AdminTheme.primaryDark,
        elevation: 0,
      ),
      body: Container(
        decoration: AdminTheme.backgroundGradient,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _feedbacks.isEmpty
                ? const Center(
                    child: Text('Belum ada feedback.',
                        style: TextStyle(color: Colors.white)))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _feedbacks.length,
                    itemBuilder: (context, index) {
                      final feedback = _feedbacks[index];
                      return Container(
                        decoration: AdminTheme.cardBox,
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Card(
                          color: Colors.transparent,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Feedback #${feedback['id']}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Pemesanan #${feedback['order_id']}',
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          feedback['tanggal'],
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete,
                                              color: Colors.red),
                                          tooltip: 'Hapus Feedback',
                                          onPressed: () async {
                                            final confirm =
                                                await showDialog<bool>(
                                              context: context,
                                              builder: (ctx) => AlertDialog(
                                                title: const Text('Konfirmasi'),
                                                content: const Text(
                                                    'Yakin ingin menghapus feedback ini?'),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                            ctx, false),
                                                    child: const Text('Batal'),
                                                  ),
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                            ctx, true),
                                                    child: const Text('Hapus'),
                                                  ),
                                                ],
                                              ),
                                            );
                                            if (confirm == true) {
                                              deleteFeedback(feedback['id']);
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text('Dari: ${feedback['user_name']}',
                                    style: const TextStyle(fontSize: 14)),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Text('Rating: ',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w500)),
                                    ...List.generate(5, (starIdx) {
                                      return Icon(
                                        Icons.star,
                                        size: 20,
                                        color: starIdx < feedback['rating']
                                            ? Colors.orange
                                            : Colors.grey[300],
                                      );
                                    }),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Komentar:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    feedback['komentar'],
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
