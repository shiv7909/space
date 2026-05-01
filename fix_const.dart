import 'dart:io';

void main() {
  final file = File('lib/Features/solo/widgets/challenge_result_card.dart');
  var content = file.readAsStringSync();
  
  // Remove `const ` before EdgeInsets, SizedBox, Text, TextStyle
  content = content.replaceAll(RegExp(r'const\s+(EdgeInsets|SizedBox|Text|TextStyle)'), r'$1');

  // Fix _buildFailureSpaceTag missing context
  content = content.replaceAll('_buildFailureSpaceTag(habit)', '_buildFailureSpaceTag(context, habit)');
  content = content.replaceAll('Widget _buildFailureSpaceTag(EndedHabit habit)', 'Widget _buildFailureSpaceTag(BuildContext context, EndedHabit habit)');
  
  content = content.replaceAll('_buildSpaceTag(habit)', '_buildSpaceTag(context, habit)');
  content = content.replaceAll('Widget _buildSpaceTag(EndedHabit habit)', 'Widget _buildSpaceTag(BuildContext context, EndedHabit habit)');
  
  // Fix _buildVerticalDivider missing context
  content = content.replaceAll('_buildVerticalDivider()', '_buildVerticalDivider(context)');
  content = content.replaceAll('Widget _buildVerticalDivider()', 'Widget _buildVerticalDivider(BuildContext context)');
  
  file.writeAsStringSync(content);
}
