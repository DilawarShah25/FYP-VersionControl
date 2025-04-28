import 'package:flutter/material.dart';
import '../../../../utils/app_theme.dart';
import 'detail_screen.dart';
import 'faq_dynamic.dart';

class FaqView extends StatefulWidget {
  const FaqView({super.key});

  @override
  _FaqViewState createState() => _FaqViewState();
}

class _FaqViewState extends State<FaqView> {
  final List<Map<String, String>> faqData = [
    {
      'title': 'What is Scalp Sense?',
      'description':
      'Scalp Sense provides personalized skin and hair care advice using machine learning.',
      'destination': 'DetailScreen1',
    },
    {
      'title': 'How does Scalp Sense use machine learning?',
      'description':
      'Scalp Sense uses machine learning to analyze skin and hair images to suggest treatments.',
      'destination': 'DetailScreen2',
    },
    {
      'title': 'Who should use Scalp Sense?',
      'description':
      'Anyone seeking advice for skin and hair care can benefit from the Scalp Sense app.',
      'destination': 'DetailScreen3',
    },
    {
      'title': 'Is my data secure with Scalp Sense?',
      'description':
      'Scalp Sense takes privacy seriously with encrypted data storage and secure connections.',
      'destination': 'DetailScreen4',
    },
    {
      'title': 'Early Detection of Hair Fall',
      'description':
      'Early view of hair fall is crucial for effective treatment. Discover our innovative solution to combat hair loss.',
      'destination': 'DetailScreen5',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: _buildAppBar(context),
      body: _buildBody(context),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(70.0),
      child: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'FAQ',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: AppTheme.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.primaryColor, AppTheme.accentColor],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppTheme.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.paddingMedium,
                    vertical: AppTheme.paddingLarge,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: faqData
                        .map((faq) => _buildFaqItem(context, faq))
                        .toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqItem(BuildContext context, Map<String, String> faq) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.paddingMedium),
      child: DynamicContainer(
        title: faq['title']!,
        description: faq['description']!,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailScreen(
                title: faq['title']!,
                content: _getContentForBlog(faq['destination']!),
              ),
            ),
          );
        },
      ),
    );
  }

  String _getContentForBlog(String destination) {
    switch (destination) {
      case 'DetailScreen1':
        return '''
# What is Scalp Sense?

Scalp Sense provides personalized skin and hair care advice using machine learning. The app analyzes your skin and hair images to give tailored recommendations on treatments, products, and hair care routines. By leveraging advanced machine learning algorithms, Scalp Sense ensures that you receive expert advice based on your unique hair and skin condition.

## Key Features:
- Personalized skin and hair care recommendations
- AI-driven analysis of your skin and hair images
- Continuous learning to improve treatment suggestions

## Conclusion
Scalp Sense is revolutionizing the way we care for our skin and hair. With the power of machine learning, you can get customized solutions that suit your needs.
''';
      case 'DetailScreen2':
        return '''
# How does Scalp Sense use machine learning?

Scalp Sense uses machine learning to analyze skin and hair images, allowing it to suggest the most effective treatments. By capturing detailed images of your scalp, the app identifies patterns and issues such as thinning, dryness, and oiliness, offering personalized solutions.

## How It Works:
- **Image Analysis**: Your skin and hair images are analyzed using AI to detect potential issues.
- **Personalized Advice**: Based on the analysis, Scalp Sense recommends hair care treatments, lifestyle changes, and products.
- **Continuous Improvement**: The app learns from your progress and refines its suggestions over time.

## Conclusion
Machine learning is a game-changer in personalized skin and hair care. Scalp Sense uses this technology to give you the best advice tailored to your needs.
''';
      case 'DetailScreen3':
        return '''
# Who should use Scalp Sense?

Scalp Sense is designed for anyone who seeks professional advice on skin and hair care. Whether you're dealing with hair thinning, dry scalp, or simply want to improve your overall hair health, Scalp Sense provides solutions that are customized for you.

## Ideal Users:
- **Individuals with Hair Thinning**: Get personalized treatments for hair restoration.
- **People with Scalp Issues**: Whether you have dandruff, oily scalp, or dryness, Scalp Sense offers tailored solutions.
- **Anyone Seeking Better Hair Care**: Scalp Sense helps everyone, from those with hair loss to those just wanting to optimize their routine.

## Conclusion
No matter your skin or hair condition, Scalp Sense is for anyone who wants to improve their hair and scalp health with expert advice at their fingertips.
''';
      case 'DetailScreen4':
        return '''
# Is my data secure with Scalp Sense?

Scalp Sense takes privacy and security seriously. Your data is stored in an encrypted format, ensuring that it remains private and secure. The app uses secure connections to transmit your data, providing peace of mind while you use the service.

## Security Features:
- **Encrypted Data Storage**: All data is stored securely to prevent unauthorized access.
- **Secure Connections**: Your data is transmitted using industry-standard encryption protocols.
- **Privacy First**: Scalp Sense is committed to protecting your personal information and ensuring confidentiality.

## Conclusion
With Scalp Sense, you can trust that your data is protected with the highest security standards. Your privacy is our top priority.
''';
      case 'DetailScreen5':
        return '''
# Early Detection of Hair Fall

Early view of hair fall is crucial for effective treatment. Scalp Sense offers an innovative solution that helps you identify the first signs of hair loss, enabling you to take action before the situation worsens.

## How It Helps:
- **Scalp Analysis**: The app detects signs of thinning and other early indicators of hair loss.
- **Personalized Treatment Plans**: Based on your condition, Scalp Sense provides early interventions to prevent further damage.
- **Proactive Care**: Catching hair fall early means you can start treatments sooner, reducing the impact.

## Conclusion
With Scalp Sense, early view of hair fall is within your reach. By addressing hair loss early, you can ensure healthier hair in the long run.
''';
      default:
        return 'Content not available';
    }
  }
}