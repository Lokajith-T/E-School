import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Help & Support'.tr()),
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: const Icon(Icons.email_outlined),
            title: Text('Contact Support'.tr()),
            subtitle: const Text('support@eschool.com'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Opening email client...'.tr())),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.phone_outlined),
            title: Text('Call Us'.tr()),
            subtitle: const Text('+1 800 123 4567'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Opening dialer...'.tr())),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.question_answer_outlined),
            title: Text('FAQs'.tr()),
            subtitle: Text('Find answers to common questions'.tr()),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('FAQs coming soon'.tr())),
              );
            },
          ),
        ],
      ),
    );
  }
}
