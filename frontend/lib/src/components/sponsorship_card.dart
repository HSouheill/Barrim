import 'package:flutter/material.dart';
import '../models/sponsorship.dart';

class SponsorshipCard extends StatelessWidget {
  final Sponsorship sponsorship;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const SponsorshipCard({
    Key? key,
    required this.sponsorship,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    sponsorship.title,
                    style: const TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: onEdit,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: onDelete,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8.0),
            
            // Description
            Text(
              sponsorship.description,
              style: TextStyle(
                fontSize: 14.0,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16.0),
            
            // Code and Status Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.blue.shade300),
                  ),
                  child: Text(
                    'Code: ${sponsorship.code}',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: sponsorship.isActive ? Colors.green.shade100 : Colors.red.shade100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: sponsorship.isActive ? Colors.green.shade300 : Colors.red.shade300,
                    ),
                  ),
                  child: Text(
                    sponsorship.isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      color: sponsorship.isActive ? Colors.green.shade700 : Colors.red.shade700,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            
            // Price and Discount Row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Price',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        sponsorship.formattedPrice,
                        style: const TextStyle(
                          fontSize: 20.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Discount',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        sponsorship.formattedDiscount,
                        style: const TextStyle(
                          fontSize: 20.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            
            // Duration and Max Uses Row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Duration',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        sponsorship.durationText,
                        style: const TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (sponsorship.durationInfo != null)
                        Text(
                          sponsorship.durationInfo!.durationDescription,
                          style: TextStyle(
                            fontSize: 12.0,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Max Uses',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        '${sponsorship.usedCount}/${sponsorship.maxUses}',
                        style: const TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            
            // Date Range
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Start Date',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        '${sponsorship.startDate.day}/${sponsorship.startDate.month}/${sponsorship.startDate.year}',
                        style: const TextStyle(
                          fontSize: 14.0,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'End Date',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        '${sponsorship.endDate.day}/${sponsorship.endDate.month}/${sponsorship.endDate.year}',
                        style: const TextStyle(
                          fontSize: 14.0,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            
            // Usage Progress Bar
            if (sponsorship.maxUses > 0)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Usage Progress',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        '${((sponsorship.usedCount / sponsorship.maxUses) * 100).toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: sponsorship.maxUses > 0 
                        ? sponsorship.usedCount / sponsorship.maxUses 
                        : 0,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      sponsorship.usedCount >= sponsorship.maxUses 
                          ? Colors.red 
                          : Colors.green,
                    ),
                  ),
                ],
              ),
            
            // Status Indicators
            const SizedBox(height: 16.0),
            Row(
              children: [
                if (sponsorship.isExpired)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Expired',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                if (sponsorship.usedCount >= sponsorship.maxUses)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Fully Used',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                if (!sponsorship.isAvailable && !sponsorship.isExpired && sponsorship.usedCount < sponsorship.maxUses)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Unavailable',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
