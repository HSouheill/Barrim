import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/sponsorship.dart';

class AddSponsorshipPopupForm extends StatefulWidget {
  final String type;
  final Sponsorship? sponsorship; // For editing existing sponsorship

  const AddSponsorshipPopupForm({
    Key? key,
    required this.type,
    this.sponsorship,
  }) : super(key: key);

  @override
  _AddSponsorshipPopupFormState createState() => _AddSponsorshipPopupFormState();
}

class _AddSponsorshipPopupFormState extends State<AddSponsorshipPopupForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _durationController = TextEditingController();
  final _discountController = TextEditingController();
  
  DateTime _startDate = DateTime.now().toUtc();
  DateTime _endDate = DateTime.now().toUtc().add(const Duration(days: 30));
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.sponsorship != null) {
      // Editing existing sponsorship
      final sponsorship = widget.sponsorship!;
      _titleController.text = sponsorship.title;
      _priceController.text = sponsorship.price.toString();
      _durationController.text = sponsorship.duration.toString();
      _discountController.text = sponsorship.discount?.toString() ?? '';
      _startDate = sponsorship.startDate;
      _endDate = sponsorship.endDate;
    }
    
    // Add listener to duration controller for real-time preview updates
    _durationController.addListener(() {
      setState(() {
        // Also update end date to match duration
        if (_durationController.text.isNotEmpty) {
          final duration = int.tryParse(_durationController.text);
          if (duration != null && duration > 0) {
            _endDate = _startDate.add(Duration(days: duration));
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate.toLocal() : _endDate.toLocal(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked.toUtc();
          // Update end date to match duration if duration is already set
          if (_durationController.text.isNotEmpty) {
            final duration = int.tryParse(_durationController.text);
            if (duration != null && duration > 0) {
              _endDate = _startDate.add(Duration(days: duration));
            }
          } else if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate.add(const Duration(days: 1));
          }
        } else {
          _endDate = picked.toUtc();
        }
      });
    }
  }

  Widget _buildDurationChip(String label, int days) {
    return ActionChip(
      label: Text(label),
      onPressed: () {
        setState(() {
          _durationController.text = days.toString();
        });
      },
      backgroundColor: Colors.blue.shade50,
      labelStyle: TextStyle(color: Colors.blue.shade700),
    );
  }

  String _getDurationPreview() {
    final durationText = _durationController.text;
    if (durationText.isEmpty) return '';
    
    final days = int.tryParse(durationText);
    if (days == null || days < 1) return '';
    
    if (days == 1) return '1 day';
    if (days < 7) return '$days days';
    if (days < 30) return '${days ~/ 7} weeks, ${days % 7} days';
    if (days < 365) return '${days ~/ 30} months, ${days % 30} days';
    return '${days ~/ 365} years, ${(days % 365) ~/ 30} months, ${(days % 365) % 30} days';
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      if (_startDate.isAfter(_endDate)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Start date cannot be after end date'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final request = SponsorshipRequest(
        title: _titleController.text.trim(),
        price: double.parse(_priceController.text),
        duration: int.parse(_durationController.text),
        startDate: _startDate.toUtc(),
        endDate: _endDate.toUtc(),
        type: widget.type,
        discount: _discountController.text.isNotEmpty ? double.parse(_discountController.text) : null,
      );

      Navigator.of(context).pop(request);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.9,
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      width: 450,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.sponsorship != null ? 'Edit Sponsorship' : 'Add Quick Sponsorship',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D1C4B),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Title Field
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
                helperText: 'Enter a descriptive title for the sponsorship',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Title is required';
                }
                if (value.trim().length < 3) {
                  return 'Title must be at least 3 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            
            // Price and Duration Row
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _priceController,
                    decoration: const InputDecoration(
                      labelText: 'Price (\$)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                    ],
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Price is required';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Invalid price format';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _durationController,
                    decoration: const InputDecoration(
                      labelText: 'Duration (days)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.schedule),
                      helperText: '1-365 days',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Duration is required';
                      }
                      final duration = int.tryParse(value);
                      if (duration == null || duration < 1) {
                        return 'Duration must be at least 1 day';
                      }
                      if (duration > 365) {
                        return 'Duration cannot exceed 365 days';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            
            // Quick Duration Selection
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Quick Duration Selection:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF0D1C4B),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildDurationChip('1 Week', 7),
                    _buildDurationChip('1 Month', 30),
                    _buildDurationChip('3 Months', 90),
                    _buildDurationChip('6 Months', 180),
                    _buildDurationChip('1 Year', 365),
                  ],
                ),
                const SizedBox(height: 8),
                // Duration Preview
                if (_durationController.text.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _getDurationPreview(),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),

            // Discount
            TextFormField(
              controller: _discountController,
              decoration: const InputDecoration(
                labelText: 'Discount (%) (Optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.discount),
                helperText: '0-100% or leave empty for no discount',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,1}')),
              ],
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return null; // Discount is optional
                }
                final discount = double.tryParse(value);
                if (discount == null || discount < 0 || discount > 100) {
                  return 'Discount must be 0-100%';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            
            // Date Range
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context, true),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Start Date',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          Text(
                            '${_startDate.day}/${_startDate.month}/${_startDate.year}',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context, false),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'End Date',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          Text(
                            '${_endDate.day}/${_endDate.month}/${_endDate.year}',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D1C4B),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        widget.sponsorship != null ? 'Update Sponsorship' : 'Create Quick Sponsorship',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
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
