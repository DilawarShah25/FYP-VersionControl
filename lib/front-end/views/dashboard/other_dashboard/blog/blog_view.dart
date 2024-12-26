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
                  width: double.infinity, // Ensure full width
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
        return '''
# Revamp Your Hair Care Routine: Steps to Healthier Hair

Having a solid hair care routine is essential to maintaining healthy, thick, and shiny hair. Whether you're dealing with hair loss, dryness, or frizz, a structured routine tailored to your hair type can make all the difference.

## Step 1: Choose the Right Shampoo and Conditioner

Pick a shampoo and conditioner that suits your hair type. Look for formulas that address your specific concerns, such as dryness, damage, or volume. 

- **Dry Hair**: Opt for moisturizing and hydrating products.
- **Oily Hair**: Choose a clarifying shampoo that helps control excess oil.
- **Curly Hair**: Go for sulfate-free shampoos to prevent frizz and keep curls defined.

## Step 2: Regular Scalp Care

Scalp health is essential for healthy hair growth. Use a gentle scrub or scalp massager to remove dead skin and product buildup. Regularly massaging your scalp for a few minutes helps stimulate blood flow and promotes healthy hair growth.

## Step 3: Deep Conditioning Treatments

Once a week, treat your hair to a deep conditioning mask or oil treatment. Deep conditioning helps restore moisture, strengthen hair, and reduce split ends.

- **Oily Scalp**: Use lightweight oils like argan oil.
- **Dry Scalp**: Try heavier oils like coconut oil or jojoba oil.

## Step 4: Minimize Heat Styling

Excessive heat styling can cause severe damage to your hair. Try to limit the use of straighteners, curling irons, and blow dryers. When you must use heat, always apply a heat protectant spray.

## Step 5: Haircuts and Trims

Regular trims are vital to keeping your hair looking healthy. Cutting off damaged ends prevents split ends and encourages healthy hair growth.

## Step 6: Maintain a Balanced Diet

Your hair is a reflection of your health. Ensure you're getting a balanced diet rich in vitamins and minerals such as biotin, vitamin E, iron, and omega-3 fatty acids. Consider adding hair supplements if necessary.

## Conclusion

Revamping your hair care routine can significantly improve the condition and appearance of your hair. Take time to invest in your hair's health by following these simple steps for healthier, stronger, and shinier hair.
''';

      case 'DetailScreen3':
        return '''
# Home Remedy To Stop Hair Fall In Men: Natural Solutions for Thicker Hair

Hair fall can be distressing, especially for men. While medical treatments are available, there are several natural remedies you can try at home to stop hair fall and promote healthier, thicker hair.

## Remedy 1: Aloe Vera for Scalp Health

Aloe vera is well known for its soothing and moisturizing properties. It can help reduce inflammation on the scalp, promote hair growth, and prevent dandruff.

- Apply fresh aloe vera gel directly to your scalp.
- Leave it on for 30 minutes before rinsing with lukewarm water.

## Remedy 2: Onion Juice for Hair Regrowth

Onion juice is rich in sulfur, which helps in collagen production and promotes hair growth. The high sulfur content improves blood circulation in the scalp, allowing hair follicles to receive better nutrients.

- Grate an onion and extract its juice.
- Apply the juice to your scalp and leave it on for 15-30 minutes before washing off.

## Remedy 3: Coconut Oil for Hair Strength

Coconut oil has antifungal and antibacterial properties that help reduce dandruff and protect your hair from further damage. It’s also known for deeply moisturizing and nourishing the scalp.

- Massage warm coconut oil into your scalp.
- Leave it overnight and wash your hair the next morning.

## Remedy 4: Green Tea for DHT Reduction

Green tea contains antioxidants and compounds that can block Dihydrotestosterone (DHT), a hormone linked to hair loss. Regular use of green tea on the scalp can help slow down hair thinning.

- Steep green tea in hot water, let it cool, and apply it to your scalp.
- Leave it on for 30-45 minutes before rinsing off.

## Remedy 5: Diet Rich in Nutrients

Eating a diet rich in vitamins, minerals, and protein is crucial for hair growth. Focus on foods such as eggs, spinach, nuts, and fish to provide your hair with the nutrients it needs.

- Include biotin, zinc, and iron-rich foods to reduce hair fall.

## Conclusion

While these natural remedies may help with hair loss prevention, consistency is key. Results might take time, so it’s important to follow these remedies regularly. Consult a healthcare professional for persistent or severe hair loss issues.
''';

      case 'DetailScreen4':
        return '''
# Healthy Scalp, Healthy Hair: Tips for Scalp Care

A healthy scalp is the foundation for healthy hair. If your scalp is not properly cared for, your hair can become dry, brittle, or prone to hair loss. Below are essential tips for maintaining a healthy scalp.

## Tip 1: Cleanse Regularly

Regular washing is essential for removing buildup of dirt, oil, and styling products from your scalp. Choose a mild, sulfate-free shampoo that matches your hair type.

- Wash your hair 2-3 times per week to prevent over-drying or excessive oil buildup.
- Use lukewarm water instead of hot water to avoid stripping natural oils.

## Tip 2: Exfoliate Your Scalp

Exfoliating your scalp helps remove dead skin cells and prevent clogged follicles, which can lead to hair thinning. Use a scalp scrub or a gentle exfoliating shampoo once a week.

## Tip 3: Moisturize Your Scalp

Just like your skin, your scalp requires hydration. Apply a light, non-greasy moisturizer to your scalp if it feels dry. You can also try oil treatments like jojoba or argan oil for deep hydration.

## Tip 4: Avoid Tight Hairstyles

Tight hairstyles, such as braids, ponytails, and buns, can cause tension on the scalp and lead to traction alopecia, a form of hair loss. Opt for looser styles and avoid pulling hair too tightly.

## Tip 5: Massage Your Scalp

Scalp massage improves circulation, which helps nourish hair follicles and promotes hair growth. Use your fingertips to gently massage your scalp for a few minutes each day.

## Tip 6: Protect Your Scalp From the Sun

Excessive sun exposure can damage your scalp and lead to hair thinning. If you're outdoors for long periods, wear a hat or use a scalp sunscreen.

## Conclusion

Taking care of your scalp is just as important as caring for your hair. By following these simple tips, you can promote healthy hair growth and keep your scalp in top condition. Healthy hair starts with a healthy scalp.
''';

      default:
        return 'Content not available';
    }
  }

}
