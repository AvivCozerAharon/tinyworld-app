import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tinyworld_app/core/theme/styles.dart';

class HumanizedProfileSheet extends StatefulWidget {
  final List<String> photos;
  final String name;
  final int? age;
  final List<String> hobbies;

  const HumanizedProfileSheet({
    super.key,
    required this.photos,
    required this.name,
    this.age,
    this.hobbies = const [],
  });

  static Future<void> show(
    BuildContext context, {
    required List<String> photos,
    required String name,
    int? age,
    List<String> hobbies = const [],
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => HumanizedProfileSheet(
        photos: photos,
        name: name,
        age: age,
        hobbies: hobbies,
      ),
    );
  }

  @override
  State<HumanizedProfileSheet> createState() => _HumanizedProfileSheetState();
}

class _HumanizedProfileSheetState extends State<HumanizedProfileSheet> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: TwColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: TwColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            if (widget.photos.isNotEmpty) ...[
              SizedBox(
                height: 280,
                child: PageView.builder(
                  itemCount: widget.photos.length,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (_, i) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(TwRadius.xl),
                      child: Image.memory(
                        base64Decode(widget.photos[i]),
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    ),
                  ),
                ),
              ),
              if (widget.photos.length > 1)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      widget.photos.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: _page == i ? 16 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _page == i ? TwColors.primary : TwColors.border,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
            ],
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                children: [
                  Text(
                    widget.age != null
                        ? '${widget.name}, ${widget.age}'
                        : widget.name,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: TwColors.onBg,
                    ),
                  ),
                  if (widget.hobbies.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.hobbies
                          .map((h) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: TwColors.card,
                                  borderRadius:
                                      BorderRadius.circular(TwRadius.pill),
                                  border: Border.all(color: TwColors.border),
                                ),
                                child: Text(
                                  h,
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: TwColors.onSurface,
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
