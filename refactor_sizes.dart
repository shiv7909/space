import 'dart:io';

void main() {
  final files = [
    'lib/Features/solo/widgets/challenge_result_card.dart'
  ];
  
  final importStatement = "import '../constants/solo_constants.dart';";

  for (final filePath in files) {
    final file = File(filePath);
    if (!file.existsSync()) {
      print('File not found: $filePath');
      continue;
    }
    
    var content = file.readAsStringSync();
    
    if (!content.contains(importStatement)) {
       content = content.replaceFirst("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\n$importStatement");
    }

    // fontSize: 18 -> fontSize: 18.rs(context)
    content = content.replaceAllMapped(RegExp(r'(fontSize:\s*)([0-9]+(\.[0-9]+)?)(?![\.r])'), (match) {
      return '${match.group(1)}${match.group(2)}.rs(context)';
    });

    // SizedBox(height: 16) -> SizedBox(height: 16.rs(context))
    content = content.replaceAllMapped(RegExp(r'(SizedBox\s*\(\s*(?:width|height):\s*)([0-9]+(\.[0-9]+)?)(?![\.r])'), (match) {
      return '${match.group(1)}${match.group(2)}.rs(context)';
    });

    // padding: const EdgeInsets.all(22) -> padding: EdgeInsets.all(22.rs(context))
    content = content.replaceAllMapped(RegExp(r'const\s*(EdgeInsets\.all\()([0-9]+(\.[0-9]+)?)\)'), (match) {
      return '${match.group(1)}${match.group(2)}.rs(context))';
    });

    // EdgeInsets.symmetric
    content = content.replaceAllMapped(RegExp(r'(const\s+EdgeInsets\.symmetric\()([^)]+)\)'), (match) {
      var res = match.group(1)!.replaceAll('const ', '');
      var inner = match.group(2)!;
      inner = inner.replaceAllMapped(RegExp(r'(horizontal|vertical):\s*([0-9]+(\.[0-9]+)?)'), (m) => '${m.group(1)}: ${m.group(2)}.rs(context)');
      return res + inner + ')';
    });

    // EdgeInsets.only
    content = content.replaceAllMapped(RegExp(r'(const\s+EdgeInsets\.only\()([^)]+)\)'), (match) {
      var res = match.group(1)!.replaceAll('const ', '');
      var inner = match.group(2)!;
      inner = inner.replaceAllMapped(RegExp(r'(left|right|top|bottom):\s*([0-9]+(\.[0-9]+)?)'), (m) => '${m.group(1)}: ${m.group(2)}.rs(context)');
      return res + inner + ')';
    });
    
    // EdgeInsets.fromLTRB
    content = content.replaceAllMapped(RegExp(r'(const\s+EdgeInsets\.fromLTRB\()([^)]+)\)'), (match) {
      var res = match.group(1)!.replaceAll('const ', '');
      var numsString = match.group(2)!;
      var newNums = numsString.split(',').map((n) {
          final trimmed = n.trim();
          if (trimmed.isEmpty) return trimmed;
          if (RegExp(r'^[0-9]+(\.[0-9]+)?$').hasMatch(trimmed)) {
             return '$trimmed.rs(context)';
          }
          return trimmed;
      }).join(', ');
      return res + newNums + ')';
    });
    
    // widths, heights, size
    content = content.replaceAllMapped(RegExp(r'((?:^\s*|\s|\b)(?:width|height|size|blurRadius):\s*)([0-9]+(\.[0-9]+)?)(?![\.r0-9a-zA-Z])'), (match) {
       return '${match.group(1)}${match.group(2)}.rs(context)';
    });

    // BorderRadius.circular
    content = content.replaceAllMapped(RegExp(r'(BorderRadius\.circular\()([0-9]+(\.[0-9]+)?)\)'), (match) {
        return '${match.group(1)}${match.group(2)}.rs(context))';
    });

    file.writeAsStringSync(content);
  }
}
