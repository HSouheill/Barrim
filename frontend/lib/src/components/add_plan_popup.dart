import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/subscription.dart';

class AddPlanPopupForm extends StatefulWidget {
  final String type; // 'company' or 'service_provider'

  const AddPlanPopupForm({
    Key? key,
    required this.type,
  }) : super(key: key);

  @override
  _AddPlanPopupFormState createState() => _AddPlanPopupFormState();
}

class _AddPlanPopupFormState extends State<AddPlanPopupForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final List<BenefitController> _benefitControllers = [BenefitController()];
  int _selectedDuration = 1; // Default to monthly
  bool _isActive = true;
  File? _selectedImage;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    for (var controller in _benefitControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  void _addBenefitField() {
    setState(() {
      _benefitControllers.add(BenefitController());
    });
  }

  void _removeBenefitField(int index) {
    setState(() {
      _benefitControllers[index].dispose();
      _benefitControllers.removeAt(index);
    });
  }

  CreateSubscriptionPlanRequest? _validateAndCreatePlan() {
    if (!_formKey.currentState!.validate()) {
      return null;
    }

    final benefits = _benefitControllers
        .where((controller) =>
    controller.titleController.text.isNotEmpty ||
        controller.descriptionController.text.isNotEmpty)
        .map((controller) => Benefit(
      title: controller.titleController.text,
      description: controller.descriptionController.text,
    ))
        .toList();

    if (benefits.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one benefit')),
      );
      return null;
    }

    return CreateSubscriptionPlanRequest(
      title: _titleController.text,
      description: _descriptionController.text,
      price: double.parse(_priceController.text),
      duration: _selectedDuration,
      type: widget.type,
      benefits: benefits,
      isActive: _isActive,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        decoration: BoxDecoration(
          color: const Color(0xFF1A237E), // Dark blue background
          borderRadius: BorderRadius.circular(20),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header section with title and upload button
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _titleController,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Title',
                          hintStyle: TextStyle(
                            color: Colors.white70,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          border: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.white70),
                          ),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.white70),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.white),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a title';
                          }
                          return null;
                        },
                      ),
                    ),
                    // const SizedBox(width: 10),
                    // OutlinedButton(
                    //   onPressed: _pickImage,
                    //   style: OutlinedButton.styleFrom(
                    //     side: const BorderSide(color: Colors.white70),
                    //     shape: RoundedRectangleBorder(
                    //       borderRadius: BorderRadius.circular(20),
                    //     ),
                    //     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    //   ),
                    //   child: const Text(
                    //     'Upload Image',
                    //     style: TextStyle(color: Colors.white70, fontSize: 12),
                    //   ),
                    // ),
                  ],
                ),
              ),

              // Duration section
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                margin: const EdgeInsets.only(top: 10, bottom: 20),
                child: DropdownButtonFormField<int>(
                  value: _selectedDuration,
                  decoration: InputDecoration(
                    labelText: 'Duration',
                    labelStyle: const TextStyle(color: Colors.white70),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.white54),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.white),
                    ),
                  ),
                  dropdownColor: const Color(0xFF1A237E), // Dark blue background
                  style: const TextStyle(color: Colors.white70),
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('Monthly')),
                    DropdownMenuItem(value: 6, child: Text('6 Months')),
                    DropdownMenuItem(value: 12, child: Text('Yearly')),
                  ],
                  onChanged: (int? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedDuration = newValue;
                      });
                    }
                  },
                ),
              ),

              // Benefits section
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    ..._benefitControllers.asMap().entries.map((entry) {
                      final index = entry.key;
                      final controller = entry.value;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            const Text(
                              '• ',
                              style: TextStyle(color: Colors.white70, fontSize: 16),
                            ),
                            Expanded(
                              child: TextFormField(
                                controller: controller.titleController,
                                style: const TextStyle(color: Colors.white70),
                                decoration: InputDecoration(
                                  hintText: 'Benefit ${index + 1}',
                                  hintStyle: const TextStyle(color: Colors.white54),
                                  border: const UnderlineInputBorder(
                                    borderSide: BorderSide(color: Colors.white54),
                                  ),
                                  enabledBorder: const UnderlineInputBorder(
                                    borderSide: BorderSide(color: Colors.white54),
                                  ),
                                  focusedBorder: const UnderlineInputBorder(
                                    borderSide: BorderSide(color: Colors.white70),
                                  ),
                                ),
                                validator: (value) {
                                  if (index == 0 && (value == null || value.isEmpty)) {
                                    return 'Please enter at least one benefit';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            if (_benefitControllers.length > 1)
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.white54, size: 18),
                                onPressed: () => _removeBenefitField(index),
                              ),
                          ],
                        ),
                      );
                    }).toList(),

                    // Add benefit button
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: _addBenefitField,
                            child: const Row(
                              children: [
                                Icon(Icons.add, color: Colors.white70, size: 20),
                                SizedBox(width: 5),
                                Text(
                                  'Add',
                                  style: TextStyle(color: Colors.white70, fontSize: 16),
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

              const SizedBox(height: 20),

              // Price section
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: TextFormField(
                  controller: _priceController,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF1A237E),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Price',
                    hintStyle: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                    border: InputBorder.none,
                    prefixText: '\$',
                    prefixStyle: TextStyle(
                      color: Color(0xFF1A237E),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a price';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
              ),

              const SizedBox(height: 20),

              // Action buttons
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final plan = _validateAndCreatePlan();
                          if (plan != null) {
                            Navigator.of(context).pop(plan);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'Save',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[600],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.delete_outline, color: Colors.white),
                        padding: const EdgeInsets.all(12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BenefitController {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
  }
}