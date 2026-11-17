import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'models.dart';

/// Survey shown in a bottom sheet when a canvasser visits a stop.
/// Pops with a [SurveyAnswers] when submitted.
class SurveyForm extends StatefulWidget {
  final int stopNumber;
  const SurveyForm({super.key, required this.stopNumber});

  @override
  State<SurveyForm> createState() => _SurveyFormState();
}

class _SurveyFormState extends State<SurveyForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _notesController = TextEditingController();

  String? _plans; // 'Yes', 'No', or 'Undecided'
  bool _plansError = false;

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    final valid = _formKey.currentState!.validate();
    setState(() => _plansError = _plans == null);
    if (!valid || _plans == null) return;

    Navigator.pop(
      context,
      SurveyAnswers(
        name: _nameController.text.trim(),
        age: int.parse(_ageController.text.trim()),
        plansToVote: _plans!,
        notes: _notesController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      // Keeps the form above the on-screen keyboard.
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Survey · Stop ${widget.stopNumber}',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Please enter a name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Age',
                  prefixIcon: Icon(Icons.cake_outlined),
                ),
                validator: (v) {
                  final age = int.tryParse((v ?? '').trim());
                  if (age == null) return 'Please enter an age';
                  if (age < 18 || age > 120) {
                    return 'Age must be between 18 and 120';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Text(
                'Do they plan to vote in the next election?',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<String>(
                  showSelectedIcon: false,
                  emptySelectionAllowed: true,
                  segments: const [
                    ButtonSegment(value: 'Yes', label: Text('Yes')),
                    ButtonSegment(value: 'No', label: Text('No')),
                    ButtonSegment(value: 'Undecided', label: Text('Undecided')),
                  ],
                  selected: _plans == null ? <String>{} : {_plans!},
                  onSelectionChanged: (s) => setState(() {
                    _plans = s.isEmpty ? null : s.first;
                    _plansError = false;
                  }),
                ),
              ),
              if (_plansError)
                Padding(
                  padding: const EdgeInsets.only(top: 6, left: 4),
                  child: Text(
                    'Please choose an answer',
                    style: TextStyle(color: scheme.error, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Additional information (optional)',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _submit,
                child: const Text('Save survey'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
