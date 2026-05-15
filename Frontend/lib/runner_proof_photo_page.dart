//26
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_new_app/runner_payment_confirm_page.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';

class RunnerProofPhotoPage extends StatefulWidget {
  final String orderId;
  final String runnerId;
  final StreamChatClient client;

  const RunnerProofPhotoPage({
    super.key, 
    required this.orderId,
    required this.runnerId,
    required this.client,
    });

  @override
  State<RunnerProofPhotoPage> createState() => _RunnerProofPhotoPageState();
}

class _RunnerProofPhotoPageState extends State<RunnerProofPhotoPage>{
  File? proofImage;
  final ImagePicker picker = ImagePicker();
  bool isLoading = false;

  //Take photo/Pick photo
  Future<void> takePhoto() async {
  final XFile? pickedImage = await picker.pickImage(
    source: ImageSource.camera,
    imageQuality: 80,
  );

  if (pickedImage != null) {
    setState(() {
      proofImage = File(pickedImage.path);
    });
    }
  }

  //Time watermark
  String _getTime(){
    final now = DateTime.now();
    return "${now.year}-${now.month}-${now.day} ${now.hour}:${now.minute}";
  }

  //Upload photo and navigate to next page
 Future<void> uploadPhoto() async {
  if (proofImage == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Please take a photo first.")),
    );
    return;
  }

  setState(() => isLoading = true); // 建议加个 loading 状态

  try {
    var request = http.MultipartRequest(
      'POST', 
      Uri.parse('http://10.0.2.2:5000/api/order/upload_proof')
    );

    // 2. 添加文字字段
    request.fields['order_id'] = widget.orderId.trim();
    request.fields['runner_id'] = widget.runnerId.trim();

    // 3. 添加图片文件
    request.files.add(
      await http.MultipartFile.fromPath(
        'proof_image', // 后端接收的 key 名
        proofImage!.path,
      ),
    );

    // 4. 发送请求
    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      print("Server Error: ${response.body}"); 
    }

    if (response.statusCode == 200) {

  // GET ORDER SUMMARY
  final summaryResponse = await http.get(
    Uri.parse(
      'http://10.0.2.2:5000/api/order/summary?order_id=${widget.orderId}'
    ),
  );

  if (summaryResponse.statusCode == 200) {

    final data = jsonDecode(summaryResponse.body);

    print("API Summary Data: $data");

    if (!mounted) return;

    // 定义一个安全的双精度转换函数
    double tryParseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

// 在 Navigator 处使用
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RunnerPaymentConfirmPage(
          studentID: widget.runnerId,
          client: widget.client,
          // 更加稳健的金额解析
          amount: tryParseDouble(data['total_price']), 
          
          // 增加多重兜底，防止后端字段名变动
          customerName: data['user_name'] ?? data['customer_name'] ?? "Customer",
          customerStudentID: data['user_id'] ?? data['requester_id'] ?? "Unknown",
          customerContact: data['user_contact'] ?? data['requester_contact'] ?? "N/A",
          orderId: widget.orderId,
        ),
      ),
    );

  } else {
    throw Exception("Failed to load order summary");
  }

}
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error: $e")),
    );
  } finally {
    setState(() => isLoading = false);
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        // 🌈 Background gradient
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFEAF3FF),
              Color(0xFFD6E8FF),
              Color(0xFFBFD9FF),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
            child: Column(
              children: [

                // Top bar
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Color(0xFF6C8EF5),
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 22),
                    const Expanded(
                      child: Text(
                        "Proof Photo",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2F3A5A),
                        ),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 16),

                // Photo container
                Container(
                  width: double.infinity,
                  height: 320,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha:0.9),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha:0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: proofImage == null
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.camera_alt_outlined,
                              size: 70,
                              color: Color(0xFF6C8EF5),
                            ),
                            SizedBox(height: 12),
                            Text(
                              "No photo taken yet",
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF2F3A5A2F),
                              ),
                            )
                          ],
                        )
                        
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Stack(
                            children: [
                              Image.file(
                                proofImage!,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                              ),

                              // Watermark
                              Positioned(
                                bottom: 12,
                                left: 12,
                                right: 12,
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha:0.5),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Runner: ${widget.runnerId}",
                                        style: const TextStyle(
                                            color: Colors.white, fontSize: 12),
                                      ),
                                      Text(
                                        _getTime(),
                                        style: const TextStyle(
                                            color: Colors.white, fontSize: 12),
                                      ),
                                      const Text(
                                        "XMUM Campus",
                                        style: TextStyle(
                                            color: Colors.white, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
                const SizedBox(height: 30),

                //Take Photo Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: takePhoto, // ✅ FIX
                    icon: const Icon(Icons.camera_alt),
                    label: const Text("Take Photo"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C8EF5),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                //Upload Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: uploadPhoto, // ✅ FIX
                    icon: const Icon(Icons.cloud_upload_outlined),
                    label: const Text("Upload to User"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF6C8EF5),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}