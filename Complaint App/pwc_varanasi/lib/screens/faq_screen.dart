import 'package:flutter/material.dart';

class FAQItem {
  final String question;
  final String answer;

  FAQItem({required this.question, required this.answer});
}

class FAQScreen extends StatelessWidget {
  final List<FAQItem> faqItems = [
    FAQItem(
      question: 'Q1',
      answer: 'A1',
    ),
    FAQItem(
      question: 'Q2',
      answer: 'A2',
    ),
    FAQItem(
      question: 'Q3',
      answer: 'A3',
    ),
    // Add more FAQ items as needed
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('FAQ'),
      ),
      body: ListView.builder(
        itemCount: faqItems.length,
        itemBuilder: (BuildContext context, int index) {
          final faqItem = faqItems[index];
          return ExpansionTile(
            title: Text(faqItem.question),
            children: <Widget>[
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(faqItem.answer),
              ),
            ],
          );
        },
      ),
    );
  }
}
