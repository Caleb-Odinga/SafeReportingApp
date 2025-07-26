import 'package:flutter/material.dart';
import 'package:safe_reporting/models/contact_info.dart';

class ContactInfoForm extends StatefulWidget {
  final ContactInfo? initialContactInfo;
  final Function(ContactInfo?) onContactInfoChanged;
  final bool showPrivacyWarning;

  const ContactInfoForm({
    Key? key,
    this.initialContactInfo,
    required this.onContactInfoChanged,
    this.showPrivacyWarning = true,
  }) : super(key: key);

  @override
  State<ContactInfoForm> createState() => _ContactInfoFormState();
}

class _ContactInfoFormState extends State<ContactInfoForm> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();

  bool _allowFollowUp = false;
  String _preferredMethod = 'email';
  String _bestTimeToContact = 'anytime';

  final List<String> _contactMethods = ['email', 'phone', 'either'];
  final List<String> _contactTimes = ['anytime', 'morning', 'afternoon', 'evening'];

  @override
  void initState() {
    super.initState();
    if (widget.initialContactInfo != null) {
      final contact = widget.initialContactInfo!;
      _nameController.text = contact.name ?? '';
      _emailController.text = contact.email ?? '';
      _phoneController.text = contact.phone ?? '';
      _notesController.text = contact.additionalNotes ?? '';
      _allowFollowUp = contact.allowFollowUp;
      _preferredMethod = contact.preferredMethod ?? 'email';
      _bestTimeToContact = contact.bestTimeToContact ?? 'anytime';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _updateContactInfo() {
    if (!_allowFollowUp) {
      widget.onContactInfoChanged(null);
      return;
    }

    final contactInfo = ContactInfo(
      name: _nameController.text.trim().isEmpty ? null : _nameController.text.trim(),
      email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      preferredMethod: _preferredMethod,
      allowFollowUp: _allowFollowUp,
      bestTimeToContact: _bestTimeToContact,
      additionalNotes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    widget.onContactInfoChanged(contactInfo);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Contact Information (Optional)',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        
        // Privacy warning
        if (widget.showPrivacyWarning)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.amber.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Providing contact information is optional and will reduce your anonymity. Only provide if you want to be contacted for follow-up.',
                    style: TextStyle(
                      color: Colors.amber.shade700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        
        // Allow follow-up toggle
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Allow follow-up contact'),
          subtitle: const Text('Enable if you want responders to contact you'),
          value: _allowFollowUp,
          onChanged: (value) {
            setState(() {
              _allowFollowUp = value;
            });
            _updateContactInfo();
          },
        ),
        
        if (_allowFollowUp) ...[
          const SizedBox(height: 16),
          
          // Name field
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Name (Optional)',
              hintText: 'Your name or preferred identifier',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
            ),
            onChanged: (_) => _updateContactInfo(),
          ),
          
          const SizedBox(height: 16),
          
          // Email field
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email Address',
              hintText: 'your.email@example.com',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.email),
            ),
            keyboardType: TextInputType.emailAddress,
            onChanged: (_) => _updateContactInfo(),
            validator: (value) {
              if (_allowFollowUp && _preferredMethod != 'phone' && (value == null || value.isEmpty)) {
                return 'Email is required for follow-up';
              }
              if (value != null && value.isNotEmpty && !value.contains('@')) {
                return 'Please enter a valid email address';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          // Phone field
          TextFormField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              hintText: '+1 (555) 123-4567',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.phone),
            ),
            keyboardType: TextInputType.phone,
            onChanged: (_) => _updateContactInfo(),
            validator: (value) {
              if (_allowFollowUp && _preferredMethod == 'phone' && (value == null || value.isEmpty)) {
                return 'Phone number is required for phone contact';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          // Preferred contact method
          DropdownButtonFormField<String>(
            value: _preferredMethod,
            decoration: const InputDecoration(
              labelText: 'Preferred Contact Method',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.contact_phone),
            ),
            items: _contactMethods.map((method) {
              String label;
              switch (method) {
                case 'email':
                  label = 'Email';
                  break;
                case 'phone':
                  label = 'Phone';
                  break;
                case 'either':
                  label = 'Either Email or Phone';
                  break;
                default:
                  label = method;
              }
              return DropdownMenuItem<String>(
                value: method,
                child: Text(label),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _preferredMethod = value!;
              });
              _updateContactInfo();
            },
          ),
          
          const SizedBox(height: 16),
          
          // Best time to contact
          DropdownButtonFormField<String>(
            value: _bestTimeToContact,
            decoration: const InputDecoration(
              labelText: 'Best Time to Contact',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.schedule),
            ),
            items: _contactTimes.map((time) {
              String label;
              switch (time) {
                case 'anytime':
                  label = 'Anytime';
                  break;
                case 'morning':
                  label = 'Morning (8 AM - 12 PM)';
                  break;
                case 'afternoon':
                  label = 'Afternoon (12 PM - 6 PM)';
                  break;
                case 'evening':
                  label = 'Evening (6 PM - 10 PM)';
                  break;
                default:
                  label = time;
              }
              return DropdownMenuItem<String>(
                value: time,
                child: Text(label),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _bestTimeToContact = value!;
              });
              _updateContactInfo();
            },
          ),
          
          const SizedBox(height: 16),
          
          // Additional notes
          TextFormField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Additional Notes (Optional)',
              hintText: 'Any specific instructions for contacting you',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.note),
            ),
            maxLines: 3,
            onChanged: (_) => _updateContactInfo(),
          ),
          
          const SizedBox(height: 16),
          
          // Contact summary
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Contact Information Summary',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_nameController.text.isNotEmpty)
                  Text('Name: ${_nameController.text}', style: TextStyle(fontSize: 12)),
                if (_emailController.text.isNotEmpty)
                  Text('Email: ${_emailController.text}', style: TextStyle(fontSize: 12)),
                if (_phoneController.text.isNotEmpty)
                  Text('Phone: ${_phoneController.text}', style: TextStyle(fontSize: 12)),
                Text('Preferred method: ${_preferredMethod}', style: TextStyle(fontSize: 12)),
                Text('Best time: ${_bestTimeToContact}', style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
