// lib/core/models/tag_colors.dart
import 'package:flutter/material.dart';
import 'package:front/features/home/viewmodels/home_view_model.dart';

const Map<TagType, Color> kTagColors = {
  TagType.location: Color(0xFF4A90D9),
  TagType.time:     Color(0xFF7B68EE),
  TagType.gender:   Color(0xFFE8A838),
  TagType.ageRange: Color(0xFF50C878),
  TagType.interest: Color(0xFFE05C5C),
};
