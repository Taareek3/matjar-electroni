import 'option_model.dart';

class OptionGroupModel {
  const OptionGroupModel({
    required this.id,
    required this.title,
    required this.isRequired,
    required this.options,
    this.allowMultiple = false,
  });

  final String id;
  final String title;
  final bool isRequired;
  final List<OptionModel> options;

  /// true = Checkboxes (إضافات متعددة)، false = RadioButtons (اختيار واحد)
  final bool allowMultiple;
}
