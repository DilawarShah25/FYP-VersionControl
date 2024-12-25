import 'package:flutter/material.dart';
import 'detail_screen.dart'; // Import the detail screen
import 'blog_section.dart'; // Import the BlogSection widget
import 'package:flutter_markdown/flutter_markdown.dart'; // Import the markdown package

class BlogView extends StatefulWidget {
  const BlogView({super.key});

  @override
  _BlogViewState createState() => _BlogViewState();
}

class _BlogViewState extends State<BlogView> {
  final List<Map<String, String>> blogData = [
    {
      'title': 'Hair Loss Types',
      'imagePath': 'lib/front-end/assets/images/blog/hair_loss_types.png',
      'destination': 'DetailScreen1',
    },
    {
      'title': 'Revamp Your Hair Care Routine',
      'imagePath': 'lib/front-end/assets/images/blog/hair-care-routine-for-men.jpg',
      'destination': 'DetailScreen2',
    },
    {
      'title': 'Home Remedy To Stop Hair Fall In Men',
      'imagePath': 'lib/front-end/assets/images/blog/home_remedy.png',
      'destination': 'DetailScreen3',
    },
    {
      'title': 'Healthy Scalp, Healthy Hair',
      'imagePath': 'lib/front-end/assets/images/blog/healthy_scalp.jpg',
      'destination': 'DetailScreen4',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70.0),
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
                              String content = _getContentForBlog(blog['destination']!);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) {
                                    return DetailScreen(
                                      title: blog['title']!,
                                      imagePath: blog['imagePath']!,
                                      content: content,
                                    );
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

  String _getContentForBlog(String destination) {
    switch (destination) {
      case 'DetailScreen1':
        return '''
# Hair Loss Types: Understanding Causes and Solutions

Hair loss affects millions worldwide, impacting self-esteem and confidence. Identifying hair loss types and underlying causes enables effective treatment.

## Types of Hair Loss

- **Androgenetic Alopecia (Male/Female Pattern Baldness)**: Hormonal imbalance, genetics, and age-related.
- **Alopecia Areata**: Autoimmune disease causing patchy hair loss.
- **Telogen Effluvium**: Stress-induced excessive hair shedding.
- **Traction Alopecia**: Hair loss due to tight hairstyles (braids, ponytails).
- **Trichotillomania**: Psychological disorder involving compulsive hair pulling.
- **Anagen Effluvium**: Chemotherapy-induced hair loss.
- **Scarring Alopecia**: Permanent hair loss due to inflammation, injury, or infection.

## Hormonal Hair Loss

- **Male Hormonal Hair Loss**: Dihydrotestosterone (DHT) causes hair thinning.
- **Female Hormonal Hair Loss**: Estrogen fluctuations, polycystic ovary syndrome (PCOS).
- **Thyroid-Related Hair Loss**: Hypothyroidism or hyperthyroidism.

## Other Causes

- Genetics
- Stress
- Nutritional Deficiencies (Iron, Vitamin D)
- Hairstyling and Grooming
- Infections (Fungal, Bacterial)
- Autoimmune Disorders
- Medications

## Symptoms 

- Thinning or falling hair
- Balding spots
- Excessive shedding
- Itchy scalp
- Redness and inflammation

## Treatment Options

- **Medications**: Minoxidil, Finasteride
- **Low-Level Laser Therapy (LLLT)**
- **Platelet-Rich Plasma (PRP) Therapy**
- **Hair Transplant**
- **Dietary Changes**: Balanced nutrition
- **Reducing Stress**: Yoga, meditation
- **Consult Dermatologist**: Professional guidance

## Prevention

- Maintain a healthy diet
- Reduce stress
- Use gentle hair care products
- Avoid excessive heat styling
- Regular trims
- Protect from sun damage
- Monitor hormonal balance

## Conclusion

Hair loss affects individuals differently. Understanding types, causes, and solutions empowers effective management. Consult professionals for personalized advice.
''';

      case 'DetailScreen2':
        return '''## Content for Revamp Your Hair Care Routine...''' ;

      case 'DetailScreen3':
        return '''## Content for Home Remedy To Stop Hair Fall In Men...''' ;

      default:
        return 'Content not available';
    }
  }

}
