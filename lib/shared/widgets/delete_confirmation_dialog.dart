import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:kawangizi_mobile/core/theme/app_colors.dart';

class DeleteConfirmationDialog extends StatelessWidget {
  const DeleteConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    required this.onConfirm,
    required this.onCancel,
    this.isDeleting = false,
  });

  final String title;
  final String message;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final boolean isDeleting;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: AppColors.redSoft, borderRadius: BorderRadius.circular(12)),
            child: const Icon(LucideIcons.trash2, size: 22, color: AppColors.red),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.text))),
        ],
      ),
      content: Text(message, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
      actions: [
        TextButton(onPressed: isDeleting ? null : onCancel, child: const Text('Batal', style: TextStyle(fontWeight: FontWeight.w700))),
        FilledButton(
          onPressed: isDeleting ? null : onConfirm,
          style: FilledButton.styleFrom(backgroundColor: AppColors.red, foregroundColor: Colors.white),
          child: isDeleting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Hapus', style: TextStyle(fontWeight: FontWeight.w800)),
        ),
      ],
    );
  }
}
