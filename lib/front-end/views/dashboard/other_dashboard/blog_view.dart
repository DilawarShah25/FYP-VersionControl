import 'package:flutter/material.dart';
import '../../authentication/user_login_view.dart';

class BlogView extends StatefulWidget {
  const BlogView({super.key});

  @override
  _BlogViewState createState() => _BlogViewState();
}

class _BlogViewState extends State<BlogView> {
  final List<Map<String, String>> blogData = [
    {
      'title': 'Hair Loss Types',
      'imagePath': 'lib/front-end/assets/images/hair_loss_types.png',
      'destination': 'DetailScreen1',
    },
    {
      'title': 'Revamp Your Hair Care Routine',
      'imagePath': 'lib/front-end/assets/images/hair_loss_types.png',
      'destination': 'DetailScreen2',
    },
    {
      'title': 'Effective Ways to Prevent Hair Loss',
      'imagePath': 'lib/front-end/assets/images/hair_loss_types.png',
      'destination': 'DetailScreen3',
    },
    {
      'title': 'Healthy Scalp, Healthy Hair',
      'imagePath': 'lib/front-end/assets/images/hair_loss_types.png',
      'destination': 'DetailScreen5',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70.0), // height of the AppBar
        child: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF004e92),
                  Color(0xFF000428),
                ],
              ),
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          title: const Padding(
            padding: EdgeInsets.only(right: 50.0, top: 12.0),
            child: Center(
              child: Text(
                'Blog',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 36,
                ),
              ),
            ),
          ),
          centerTitle: true,
        ),
      ),
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF004e92),
                Color(0xFF000428),
              ],
            ),
          ),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        // Blog Sections
                        for (var blog in blogData) // for loop to dynamically render
                          BlogSection(
                            title: blog['title']!,
                            imagePath: blog['imagePath']!,
                            onImageTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) {
                                    if (blog['destination'] == 'DetailScreen1') {
                                      return const UserLoginView();
                                    } else if (blog['destination'] == 'DetailScreen2') {
                                      return const UserLoginView();
                                    } else if (blog['destination'] == 'DetailScreen3') {
                                      return const UserLoginView();
                                    } else {
                                      return const BlogView();
                                    }
                                  },
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BlogSection extends StatelessWidget {
  final String title;
  final String imagePath;
  final VoidCallback onImageTap;

  const BlogSection({
    super.key,
    required this.title,
    required this.imagePath,
    required this.onImageTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onImageTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(imagePath),
                  fit: BoxFit.cover,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
