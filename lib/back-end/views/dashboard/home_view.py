import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../slider/carousel_view.dart';
import '../progress/progress_details_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});
  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final ImagePicker _picker = ImagePicker();

  void _showCameraOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera, color: Colors.black),
                title: const Text('Camera',
                    textAlign: TextAlign.start,
                    style: TextStyle(fontWeight: FontWeight.bold)),
                onTap: () async {
                  final XFile? image =
                  await _picker.pickImage(source: ImageSource.camera);
                  if (image != null) {
                    print("Picked image from camera: ${image.path}");
                  }
                  Navigator.pop(context);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.photo, color: Colors.black),
                title: const Text('Gallery',
                    textAlign: TextAlign.start,
                    style: TextStyle(fontWeight: FontWeight.bold)),
                onTap: () async {
                  final XFile? image =
                  await _picker.pickImage(source: ImageSource.gallery);
                  if (image != null) {
                    print("Picked image from gallery: ${image.path}");
                  }
                  Navigator.pop(context);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.cancel, color: Colors.red),
                title: const Text('Cancel',
                    textAlign: TextAlign.start,
                    style: TextStyle(fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showFaqDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Hair Fall Detection And Prevention System FAQ',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Avoid Harsh Chemicals',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.of(context).pop();
                  _showTipDetail(
                    'Avoid Harsh Chemicals',
                    'Excessive use of chemicals can weaken hair, leading to hair loss. Opt for milder, sulfate-free products instead.',
                  );
                },
              ),
              ListTile(
                title: const Text('Balanced Diet for Hair Health',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.of(context).pop();
                  _showTipDetail(
                    'Balanced Diet for Hair Health',
                    'Include protein, vitamins, and minerals in your diet. Biotin, iron, and vitamin E support hair growth.',
                  );
                },
              ),
              ListTile(
                title: const Text('Reduce Heat Styling',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.of(context).pop();
                  _showTipDetail(
                    'Reduce Heat Styling',
                    'Frequent heat styling can damage hair shafts. Try air drying or using low heat settings.',
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        );
      },
    );
  }

  void _showTipDetail(String title, String detail) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          content: Text(detail),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            color: Colors.blue[50],
            child: Column(
              children: [
                const SizedBox(
                  height: 535.0,
                  width: double.infinity,
                  child: Carousel(images: [
                    'lib/assets/images/carousel_item1.png',
                    'lib/assets/images/carousel_item2.png',
                    'lib/assets/images/carousel_item3.png',
                  ]),
                ),
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white54,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Early Detection\nMakes a Difference',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 5.0),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          height: 340.0,
                                          width: double.infinity, // This was the requested change
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(16),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.grey.withOpacity(0.2),
                                                spreadRadius: 2,
                                                blurRadius: 5,
                                              ),
                                            ],
                                          ),
                                          clipBehavior: Clip.hardEdge,
                                          child: const PerformanceDetailsView(),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20.0,),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          height: 150.0,
                                          width: double.infinity, // This was the requested change
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(16),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.grey.withOpacity(0.2),
                                                spreadRadius: 2,
                                                blurRadius: 5,
                                              ),
                                            ],
                                          ),
                                          clipBehavior: Clip.hardEdge,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20.0,),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          height: 150.0,
                                          width: double.infinity, // This was the requested change
                                          decoration: BoxDecoration(
                                            color: Colors.orange,
                                            borderRadius: BorderRadius.circular(16),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.grey.withOpacity(0.2),
                                                spreadRadius: 2,
                                                blurRadius: 5,
                                              ),
                                            ],
                                          ),
                                          clipBehavior: Clip.hardEdge,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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