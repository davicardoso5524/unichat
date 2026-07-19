import 'package:flutter/material.dart';
import 'package:unichat/theme/app_colors.dart';
import 'package:unichat/theme/text_styles.dart';

class NotificationsView extends StatefulWidget {
  const NotificationsView({super.key});

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  bool _pushNotifications = true;
  bool _messageSound = true;
  bool _vibrate = true;
  bool _newContactNotification = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Notificações', style: AppTextStyles.title),
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Gerencie suas preferências de notificação',
              style: AppTextStyles.body.copyWith(color: Colors.grey[600]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Text('Preferências', style: AppTextStyles.titleSmall),
          ),
          SwitchListTile(
            title: const Text('Notificações push'),
            subtitle: const Text('Receber notificações no dispositivo'),
            value: _pushNotifications,
            activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
            onChanged: (bool value) {
              setState(() {
                _pushNotifications = value;
              });
            },
          ),
          SwitchListTile(
            title: const Text('Som de mensagem'),
            subtitle: const Text('Tocar som ao receber mensagem'),
            value: _messageSound,
            activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
            onChanged: (bool value) {
              setState(() {
                _messageSound = value;
              });
            },
          ),
          SwitchListTile(
            title: const Text('Vibrar'),
            subtitle: const Text('Vibrar ao receber notificação'),
            value: _vibrate,
            activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
            onChanged: (bool value) {
              setState(() {
                _vibrate = value;
              });
            },
          ),
          SwitchListTile(
            title: const Text('Notificação de novo contato'),
            subtitle: const Text('Avisar quando novos usuários se cadastram'),
            value: _newContactNotification,
            activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
            onChanged: (bool value) {
              setState(() {
                _newContactNotification = value;
              });
            },
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'As notificações push requerem permissão do dispositivo.',
              style: AppTextStyles.caption.copyWith(color: Colors.grey[500]),
            ),
          ),
        ],
      ),
    );
  }
}
