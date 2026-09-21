import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dotted_border/dotted_border.dart';
import '../core/design_constants.dart';

/// "New Draft" name & `+` import modal. Handles text input and
/// file-picker state internally, reports the result via callbacks.
class NewDraftModal extends StatefulWidget {
  final VoidCallback onCancel;
  final void Function(String draftName, String? instrumentalPath) onSave;

  const NewDraftModal({
    super.key,
    required this.onCancel,
    required this.onSave,
  });

  @override
  State<NewDraftModal> createState() => _NewDraftModalState();
}

class _NewDraftModalState extends State<NewDraftModal> {
  final TextEditingController _nameController = TextEditingController();
  String? _filePath; // full path, used later for waveform/BPM logic
  String? _fileName; // display name only

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickInstrumental() async {
    final pickedFiles = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav'],
    );
    if (pickedFiles.isEmpty) return;

    final picked = pickedFiles.first;
    if (picked.path == null) return;

    setState(() {
      _filePath = picked.path;
      _fileName = picked.name;
    });
  }

  bool get _isWav => (_fileName ?? '').toLowerCase().endsWith('.wav');

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 30,
      top: 276,
      child: Container(
        width: 330,
        height: 234,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D000000),
              offset: Offset(0, 4),
              blurRadius: 10,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.30),
                    Colors.white.withValues(alpha: 0.12),
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.45),
                  width: 1,
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: 20,
                    top: 24,
                    child: Container(
                      width: 290,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.textDark.withValues(alpha: 0.75),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: TextField(
                          controller: _nameController,
                          textAlign: TextAlign.left,
                          cursorWidth: 1.5,
                          cursorHeight: 21,
                          cursorColor: AppColors.textDark,
                          textAlignVertical: TextAlignVertical.center,
                          style: const TextStyle(
                            fontFamily: 'Arial',
                            fontSize: 18,
                            height: 1.0,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textDark,
                          ),
                          decoration: InputDecoration(
                            hintText: 'untitled',
                            hintStyle: TextStyle(
                              fontFamily: 'Arial',
                              fontSize: 18,
                              height: 1.0,
                              fontWeight: FontWeight.w400,
                              color: Colors.black.withValues(alpha: 0.25),
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            isDense: true,
                            contentPadding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    top: 68,
                    child: Text(
                      _fileName ?? 'add instrumental',
                      style: TextStyle(
                        fontFamily: 'Arial',
                        fontSize: 14,
                        color: Colors.black.withValues(alpha: 0.25),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    top: 90,
                    child: GestureDetector(
                      onTap: _pickInstrumental,
                      child: DottedBorder(
                        options: RoundedRectDottedBorderOptions(
                          radius: const Radius.circular(16),
                          dashPattern: const [4, 4],
                          strokeWidth: 2,
                          color: AppColors.textDark.withValues(alpha: 0.16),
                        ),
                        child: SizedBox(
                          width: 286,
                          height: 70,
                          child: Center(
                            child: _fileName == null
                                ? SvgPicture.asset(
                                    'assets/icons/add_icon.svg',
                                    width: 30,
                                    height: 30,
                                  )
                                : SvgPicture.asset(
                                    _isWav
                                        ? 'assets/icons/wav_icon.svg'
                                        : 'assets/icons/mp3_icon.svg',
                                    width: 30,
                                    height: 30,
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    top: 184,
                    child: GestureDetector(
                      onTap: widget.onCancel,
                      child: Container(
                        width: 140,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.strokeGray.withValues(alpha: 0.7),
                            width: 2,
                          ),
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                        child: const Text(
                          'cancel',
                          style: TextStyle(
                            fontFamily: 'Arial',
                            fontSize: 18,
                            color: AppColors.strokeGray,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 170,
                    top: 184,
                    child: GestureDetector(
                      onTap: () {
                        final name = _nameController.text.trim().isEmpty
                            ? 'untitled'
                            : _nameController.text.trim();
                        widget.onSave(name, _filePath);
                      },
                      child: Container(
                        width: 140,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFF343434),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text(
                          'save',
                          style: TextStyle(
                            fontFamily: 'Arial',
                            fontSize: 18,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
