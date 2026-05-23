import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../services/favorites_service.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../../services/contact_service.dart';

class AddFavoriteDialog extends StatefulWidget {
  final bool isDarkMode;
  final Function() onAdded;
  final FavoriteType? initialType;
  final FavoriteItem? editItem;
  final String? initialId;
  final String? initialAmount;
  final String? initialName;

  const AddFavoriteDialog({
    super.key,
    required this.isDarkMode,
    required this.onAdded,
    this.initialType,
    this.editItem,
    this.initialId,
    this.initialAmount,
    this.initialName,
  });

  static Future<void> show(
    BuildContext context, {
    required bool isDarkMode,
    required Function() onAdded,
    FavoriteType? initialType,
    FavoriteItem? editItem,
    String? initialId,
    String? initialAmount,
    String? initialName,
  }) async {
    return showDialog(
      context: context,
      builder:
          (context) => AddFavoriteDialog(
            isDarkMode: isDarkMode,
            onAdded: onAdded,
            initialType: initialType,
            editItem: editItem,
            initialId: initialId,
            initialAmount: initialAmount,
            initialName: initialName,
          ),
    );
  }

  @override
  State<AddFavoriteDialog> createState() => _AddFavoriteDialogState();
}

class _AddFavoriteDialogState extends State<AddFavoriteDialog> {
  final _idController = TextEditingController();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  late FavoriteType _selectedType;

  @override
  void initState() {
    super.initState();
    _selectedType =
        widget.editItem?.type ?? widget.initialType ?? FavoriteType.recharge;
    if (widget.editItem != null) {
      _idController.text = widget.editItem!.id;
      _nameController.text = widget.editItem!.name;
      if (widget.editItem!.amount != null) {
        _amountController.text = widget.editItem!.amount!;
      }
    } else {
      if (widget.initialId != null) _idController.text = widget.initialId!;
      if (widget.initialAmount != null)
        // ignore: curly_braces_in_flow_control_structures
        _amountController.text = widget.initialAmount!;
      if (widget.initialName != null)
        // ignore: curly_braces_in_flow_control_structures
        _nameController.text = widget.initialName!;
    }
  }

  String get _getIdLabel {
    switch (_selectedType) {
      case FavoriteType.recharge:
      case FavoriteType.remittance:
        return 'fav_id_label'.tr();
      case FavoriteType.wallet:
        return 'fav_id_label_wallet'.tr();
      case FavoriteType.payment:
        return 'fav_id_label_payment'.tr();
      default:
        return 'fav_id_label'.tr();
    }
  }

  String get _getIdHint {
    switch (_selectedType) {
      case FavoriteType.recharge:
      case FavoriteType.remittance:
        return 'XXXXXXXXX';
      case FavoriteType.wallet:
        return 'fav_wallet_hint'.tr();
      case FavoriteType.payment:
        return 'fav_payment_hint'.tr();
      default:
        return 'XXXXXXXXX';
    }
  }

  IconData get _getIdIcon {
    switch (_selectedType) {
      case FavoriteType.recharge:
        return Icons.phone_android_rounded;
      case FavoriteType.wallet:
        return Icons.account_balance_wallet_rounded;
      case FavoriteType.remittance:
        return Icons.person_pin_rounded;
      case FavoriteType.payment:
        return Icons.storefront_rounded;
      default:
        return Icons.contact_phone_outlined;
    }
  }

  TextInputType get _getKeyboardType {
    switch (_selectedType) {
      case FavoriteType.recharge:
      case FavoriteType.remittance:
      case FavoriteType.wallet:
        return TextInputType.phone;
      case FavoriteType.payment:
        return TextInputType.number;
      default:
        return TextInputType.text;
    }
  }

  Future<void> _pickContact() async {
    if (await FlutterContacts.requestPermission()) {
      contactService.preLoadContacts(force: true);
      final contact = await FlutterContacts.openExternalPick();
      if (contact == null) return;

      var full = contact;
      if (contact.phones.isEmpty) {
        final fetched = await FlutterContacts.getContact(
          contact.id,
          withProperties: true,
        );
        if (fetched != null) full = fetched;
      }

      if (full.phones.isNotEmpty) {
        String raw = full.phones.first.number;
        String phone = raw.replaceAll(RegExp(r'\D'), '');
        if (phone.startsWith('967')) phone = phone.substring(3);
        if (phone.length > 9) phone = phone.substring(phone.length - 9);

        setState(() {
          _idController.text = phone;
          // If name is empty, auto-fill with contact name
          if (_nameController.text.isEmpty) {
            _nameController.text = full.displayName;
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isDarkMode ? AppColors.scaffoldDark : Colors.white;
    final textColor = widget.isDarkMode ? Colors.white : AppColors.textBlack;
    final inputColor =
        widget.isDarkMode ? AppColors.inputDark : Colors.grey.shade100;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with Title and Close Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 5),
                    child: Text(
                      widget.editItem != null
                          ? 'fav_edit_title'.tr()
                          : 'fav_add_title'.tr(),
                      style: TextStyle(
                        color: textColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close,
                      color: textColor.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),

              // Types Row (Radio Buttons)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildRadioButton(
                    FavoriteType.recharge,
                    'fav_recharge'.tr(),
                    textColor,
                  ),
                  _buildRadioButton(
                    FavoriteType.wallet,
                    'fav_wallet'.tr(),
                    textColor,
                  ),
                  _buildRadioButton(
                    FavoriteType.remittance,
                    'fav_remittance'.tr(),
                    textColor,
                  ),
                  _buildRadioButton(
                    FavoriteType.payment,
                    'fav_payment'.tr(),
                    textColor,
                  ),
                ],
              ),

              const SizedBox(height: 23),

              // ID/Phone Input
              _buildLabeledInput(
                label: _getIdLabel,
                controller: _idController,
                hint: _getIdHint,
                icon: _getIdIcon,
                keyboardType: _getKeyboardType,
                inputColor: inputColor,
                textColor: textColor,
                autofocus: widget.editItem == null, // Autofocus if adding new
              ),

              const SizedBox(height: 13),

              // Name Input
              _buildLabeledInput(
                label: 'fav_name_label'.tr(),
                controller: _nameController,
                hint: 'fav_name_hint'.tr(),
                icon: null,
                inputColor: inputColor,
                textColor: textColor,
              ),

              const SizedBox(height: 13),

              // Amount Input
              _buildLabeledInput(
                label: 'fav_amount_label'.tr(),
                controller: _amountController,
                hint: '0.00',
                icon: null,
                inputColor: inputColor,
                textColor: textColor,
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 18),

              // Action Buttons
              if (widget.editItem != null)
                Row(
                  children: [
                    // Delete Button
                    Expanded(
                      flex: 1,
                      child: SizedBox(
                        height: 48,
                        child: TextButton(
                          onPressed: _onDelete,
                          style: TextButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                              side: BorderSide(
                                color: AppColors.errorRed.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.delete_outline_rounded,
                                color: AppColors.errorRed,
                                size: 18,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'delete_label'.tr(),
                                style: TextStyle(
                                  color: AppColors.errorRed,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Update Button
                    Expanded(
                      flex: 2,
                      child: _buildGradientButton(
                        onPressed: _onAdd,
                        text: 'update_label'.tr(),
                      ),
                    ),
                  ],
                )
              else
                _buildGradientButton(
                  onPressed: _onAdd,
                  text: 'fav_add_label'.tr(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onDelete() async {
    if (widget.editItem == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor:
                widget.isDarkMode ? AppColors.cardDark : Colors.white,
            title: Text(
              'delete_label'.tr(),
              style: TextStyle(
                color: widget.isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            content: Text(
              'msg_confirm_delete'.tr(),
              style: TextStyle(
                color: widget.isDarkMode ? Colors.white70 : Colors.black54,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('cancel'.tr()),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  'delete_label'.tr(),
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (confirm == true) {
      await favoritesService.removeFavorite(
        widget.editItem!.id,
        widget.editItem!.type,
      );
      widget.onAdded();
      if (!mounted) return;
      Navigator.pop(context);
    }
  }

  Widget _buildRadioButton(FavoriteType type, String label, Color textColor) {
    final isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? AppColors.secondaryBlue.withValues(alpha: 0.1)
                  : (widget.isDarkMode
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.grey.withValues(alpha: 0.05)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.secondaryBlue : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.secondaryBlue : Colors.grey,
                  width: 2,
                ),
              ),
              child: Center(
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        isSelected
                            ? AppColors.secondaryBlue
                            : Colors.transparent,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 7),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? textColor : Colors.grey,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabeledInput({
    required String label,
    required TextEditingController controller,
    required String hint,
    IconData? icon,
    required Color inputColor,
    required Color textColor,
    TextInputType keyboardType = TextInputType.text,
    bool autofocus = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          child: Text(
            label,
            style: TextStyle(
              color: textColor.withValues(alpha: 0.7),
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: inputColor,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
          ),
          child: TextField(
            controller: controller,
            autofocus: autofocus,
            style: TextStyle(color: textColor),
            keyboardType: keyboardType,
            textAlign: TextAlign.start,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: textColor.withValues(alpha: 0.3),
                fontSize: 14,
              ),
              prefixIcon:
                  icon != null
                      ? Icon(icon, color: AppColors.secondaryBlue)
                      : null,
              suffixIcon:
                  icon != null
                      ? IconButton(
                        onPressed: _pickContact,
                        icon: Icon(
                          Icons.contacts,
                          color: AppColors.secondaryBlue,
                          size: 20,
                        ),
                      )
                      : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGradientButton({
    required VoidCallback onPressed,
    required String text,
  }) {
    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        gradient: AppColors.buttonGradient,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondaryBlue.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Future<void> _onAdd() async {
    if (_idController.text.isEmpty || _nameController.text.isEmpty) {
      return;
    }

    String categoryName = '';
    switch (_selectedType) {
      case FavoriteType.recharge:
        categoryName = 'fav_recharge'.tr();
        break;
      case FavoriteType.wallet:
        categoryName = 'fav_wallet'.tr();
        break;
      case FavoriteType.remittance:
        categoryName = 'fav_remittance'.tr();
        break;
      case FavoriteType.payment:
        categoryName = 'fav_payment'.tr();
        break;
      case FavoriteType.subscriber:
        categoryName = 'fav_subscriber'.tr();
        break;
      case FavoriteType.pos:
        categoryName = 'fav_pos'.tr();
        break;
      case FavoriteType.bill:
        categoryName = 'fav_bill'.tr();
        break;
    }

    await favoritesService.addFavoriteNew(
      id: _idController.text,
      name: _nameController.text,
      type: _selectedType,
      amount: _amountController.text.isEmpty ? null : _amountController.text,
      category: categoryName,
    );

    widget.onAdded();
    if (!mounted) return;
    Navigator.pop(context);
  }
}
