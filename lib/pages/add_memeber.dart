import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


// ─────────────────────────────────────────
// COLORS
// ─────────────────────────────────────────
class AppColors {
  static const bg        = Color(0xFF12121F);
  static const card      = Color(0xFF1E1E30);
  static const accent    = Color(0xFF3D7BFF);
  static const green     = Color(0xFF2DD4A0);
  static const divider   = Color(0xFF2A2A42);
  static const textPrimary   = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFF9898B0);
  static const textMuted     = Color(0xFF5A5A7A);
  static const error     = Color(0xFFFF5A5A);
}

// ─────────────────────────────────────────
// ADD MEMBER PAGE
// ─────────────────────────────────────────
class AddMemberPage extends StatefulWidget {
  const AddMemberPage({super.key});
  @override
  State<AddMemberPage> createState() => _AddMemberPageState();
}

class _AddMemberPageState extends State<AddMemberPage> {
  final _formKey    = GlobalKey<FormState>();
  final _empId      = TextEditingController();
  final _name       = TextEditingController();
  final _email      = TextEditingController();
  final _phone      = TextEditingController();
  final _address    = TextEditingController();

  DateTime? _joiningDate;
  File?     _pickedImage;
  bool      _saving = false;

  // ── Image picker ────────────────────────
  // Future<void> _pickImage(ImageSource source) async {
  //   final picker = ImagePicker();
  //   final picked = await picker.pickImage(source: source, imageQuality: 80);
  //   if (picked != null) setState(() => _pickedImage = File(picked.path));
  // }

  // void _showImageOptions() {
  //   showModalBottomSheet(
  //     context: context,
  //     backgroundColor: AppColors.card,
  //     shape: const RoundedRectangleBorder(
  //       borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
  //     ),
  //     builder: (_) => Padding(
  //       padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
  //       child: Column(
  //         mainAxisSize: MainAxisSize.min,
  //         children: [
  //           Container(
  //             width: 40, height: 4,
  //             decoration: BoxDecoration(
  //               color: AppColors.divider,
  //               borderRadius: BorderRadius.circular(2),
  //             ),
  //           ),
  //           const SizedBox(height: 20),
  //           const Text('Select Photo',
  //               style: TextStyle(
  //                   fontSize: 16,
  //                   fontWeight: FontWeight.w700,
  //                   color: AppColors.textPrimary)),
  //           const SizedBox(height: 20),
  //           Row(
  //             children: [
  //               Expanded(
  //                 child: _SheetOption(
  //                   icon: Icons.camera_alt_rounded,
  //                   label: 'Camera',
  //                   color: AppColors.accent,
  //                   onTap: () {
  //                     Navigator.pop(context);
  //                     _pickImage(ImageSource.camera);
  //                   },
  //                 ),
  //               ),
  //               const SizedBox(width: 12),
  //               Expanded(
  //                 child: _SheetOption(
  //                   icon: Icons.photo_library_rounded,
  //                   label: 'Gallery',
  //                   color: AppColors.green,
  //                   onTap: () {
  //                     Navigator.pop(context);
  //                     _pickImage(ImageSource.gallery);
  //                   },
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  // ── Date picker ─────────────────────────
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.accent,
            surface: AppColors.card,
            onSurface: AppColors.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _joiningDate = picked);
  }





  // ── Save Data in FireStore Database────────────────────────────────
  final CollectionReference membersCollection = FirebaseFirestore.instance
      .collection('users')
      .doc(FirebaseAuth.instance.currentUser!.uid)
      .collection('members');

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_joiningDate == null) {
      _showSnack('Please select a joining date', isError: true);
      return;
    }

    setState(() => _saving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showSnack('Not logged in!', isError: true);
        return;
      }

      await FirebaseFirestore.instance
          .collection('users')       // ← top level
          .doc(user.uid)             // ← scoped to logged-in user's UID
          .collection('members')     // ← this user's members only
          .add({
        'employeeId':  _empId.text.trim(),
        'name':        _name.text.trim(),
        'email':       _email.text.trim(),
        'phone':       _phone.text.trim(),
        'address':     _address.text.trim(),
        'joiningDate': Timestamp.fromDate(_joiningDate!),
        'ownerUid':    user.uid,       // ← store who created it
        'ownerEmail':  user.email,     // ← store owner email
        'createdAt':   FieldValue.serverTimestamp(),
      });

      _showSnack('Member saved successfully!');

      // Clear all fields
      _empId.clear();
      _name.clear();
      _email.clear();
      _phone.clear();
      _address.clear();
      setState(() {
        _joiningDate  = null;
        _pickedImage  = null;
      });

    } catch (e) {
      _showSnack('Failed to save: $e', isError: true);
    } finally {
      setState(() => _saving = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColors.error : AppColors.green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')} / '
          '${d.month.toString().padLeft(2, '0')} / '
          '${d.year}';

  @override
  void dispose() {
    _empId.dispose(); _name.dispose(); _email.dispose();
    _phone.dispose(); _address.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textSecondary, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Add Member',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary)),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Avatar picker ────────────
              Center(child: _buildAvatarPicker()),
              const SizedBox(height: 32),

              // ── Fields ───────────────────
              _label('Employee ID'),
              _field(
                controller: _empId,
                hint: 'e.g. EMP-00412',
                icon: Icons.badge_outlined,
                iconColor: const Color(0xFFFFB347),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              _gap(),

              _label('Full Name'),
              _field(
                controller: _name,
                hint: 'Muzamil Mahmood',
                icon: Icons.person_outline_rounded,
                iconColor: AppColors.accent,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              _gap(),

              _label('Email Address'),
              _field(
                controller: _email,
                hint: 'malik@gmail.com',
                icon: Icons.email_outlined,
                iconColor: AppColors.green,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v!.isEmpty) return 'Required';
                  if (!v.contains('@')) return 'Enter valid email';
                  return null;
                },
              ),
              _gap(),

              _label('Phone Number'),
              _field(
                controller: _phone,
                hint: '+92 (302) 000-9573',
                icon: Icons.phone_outlined,
                iconColor: const Color(0xFFB47FFF),
                keyboardType: TextInputType.phone,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              _gap(),

              _label('Address'),
              _field(
                controller: _address,
                hint: '123 Main Street, City ,Country',
                icon: Icons.location_on_outlined,
                iconColor: const Color(0xFFFF7F7F),
                maxLines: 2,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              _gap(),

              _label('Joining Date'),
              _buildDateField(),
              const SizedBox(height: 36),

              // ── Save button ───────────────
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Avatar Picker ────────────────────────
  Widget _buildAvatarPicker() {
    return GestureDetector(
      onTap: (){
        Fluttertoast.showToast(
          msg: "Coming Soon.....! This feature is under development.",
          toastLength: Toast.LENGTH_SHORT, // Duration (short or long)
          gravity: ToastGravity.CENTER,    // Position (CENTER, BOTTOM, TOP)
          timeInSecForIosWeb: 1,           // Duration for iOS/web
          backgroundColor: Colors.black54,  // Background color
          textColor: Colors.red,         // Text color
          fontSize: 20.0,                  // Text size
        );
      },
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.card,
              border: Border.all(
                color: AppColors.accent.withOpacity(0.4),
                width: 2.5,
              ),
              image: _pickedImage != null
                  ? DecorationImage(
                image: FileImage(_pickedImage!),
                fit: BoxFit.cover,
              )
                  : null,
            ),
            child: _pickedImage == null
                ? const Icon(Icons.person_rounded,
                color: AppColors.textMuted, size: 44)
                : null,
          ),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF3D7BFF), Color(0xFF1A4FCC)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: AppColors.bg, width: 2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(Icons.camera_alt_rounded,
                color: Colors.white, size: 15),
          ),
        ],
      ),
    );
  }

  // ── Date field ───────────────────────────
  Widget _buildDateField() {
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppColors.green.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.calendar_today_rounded,
                  color: AppColors.green, size: 16),
            ),
            const SizedBox(width: 12),
            Text(
              _joiningDate != null
                  ? _formatDate(_joiningDate!)
                  : 'Select joining date',
              style: TextStyle(
                fontSize: 14,
                color: _joiningDate != null
                    ? AppColors.textPrimary
                    : AppColors.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }

  // ── Save button ──────────────────────────
  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _saving ? null : _save,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: EdgeInsets.zero,
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF3D7BFF), Color(0xFF1A4FCC)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withOpacity(0.4),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Container(
            alignment: Alignment.center,
            child: _saving
                ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2.5),
            )
                : const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.save_rounded, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Text('Save Member',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────
  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text,
        style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: 0.5)),
  );

  Widget _gap() => const SizedBox(height: 18);

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required Color iconColor,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(
          color: AppColors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
            color: AppColors.textMuted, fontSize: 14),
        prefixIcon: Padding(
          padding: const EdgeInsets.all(12),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
        ),
        filled: true,
        fillColor: AppColors.card,
        contentPadding:
        const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
          const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
          const BorderSide(color: AppColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
          const BorderSide(color: AppColors.error, width: 1.5),
        ),
        errorStyle:
        const TextStyle(color: AppColors.error, fontSize: 11),
      ),
    );
  }
}

// ─────────────────────────────────────────
// BOTTOM SHEET OPTION BUTTON
// ─────────────────────────────────────────
class _SheetOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _SheetOption(
      {required this.icon,
        required this.label,
        required this.color,
        required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
          ],
        ),
      ),
    );
  }
}