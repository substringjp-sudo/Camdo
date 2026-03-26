import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/calendar_provider.dart';
import '../utils/app_theme.dart';
import 'login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
      ),
      body: Consumer2<AuthProvider, CalendarProvider>(
        builder: (ctx, authProvider, calProvider, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Profile card
              _ProfileCard(authProvider: authProvider),

              const SizedBox(height: 24),

              // Google Calendar section
              _SettingsSection(
                title: 'Google 캘린더',
                icon: Icons.calendar_month_rounded,
                color: const Color(0xFF4285F4),
                children: [
                  _SettingsTile(
                    icon: calProvider.isSyncEnabled
                        ? Icons.sync_rounded
                        : Icons.sync_disabled_rounded,
                    title: 'Google 캘린더 연동',
                    subtitle: calProvider.isSyncEnabled
                        ? '연동됨 - 탭하여 해제'
                        : '탭하여 구글 캘린더와 연동',
                    trailing: Switch(
                      value: calProvider.isSyncEnabled,
                      onChanged: (_) async {
                        if (calProvider.isSyncEnabled) {
                          await calProvider.disconnectGoogleCalendar();
                        } else {
                          await calProvider.connectGoogleCalendar();
                        }
                      },
                      activeColor: const Color(0xFF4285F4),
                    ),
                  ),
                  if (calProvider.isSyncEnabled)
                    _SettingsTile(
                      icon: Icons.refresh_rounded,
                      title: '캘린더 새로고침',
                      subtitle: '구글 캘린더 이벤트를 다시 불러옵니다',
                      onTap: () => calProvider.fetchEvents(),
                    ),
                ],
              ),

              const SizedBox(height: 16),

              // Notification section
              _SettingsSection(
                title: '알림',
                icon: Icons.notifications_rounded,
                color: AppTheme.secondary,
                children: [
                  _SettingsTile(
                    icon: Icons.alarm_rounded,
                    title: '매일 아침 알림',
                    subtitle: '오전 8시에 오늘의 할 일 알림',
                    trailing: Switch(
                      value: true,
                      onChanged: (_) {},
                      activeColor: AppTheme.secondary,
                    ),
                  ),
                  _SettingsTile(
                    icon: Icons.notification_important_rounded,
                    title: '마감 알림',
                    subtitle: '마감 당일 및 하루 전 알림',
                    trailing: Switch(
                      value: true,
                      onChanged: (_) {},
                      activeColor: AppTheme.secondary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Account section
              _SettingsSection(
                title: '계정',
                icon: Icons.person_rounded,
                color: AppTheme.primary,
                children: [
                  if (authProvider.isAnonymous)
                    _SettingsTile(
                      icon: Icons.login_rounded,
                      title: 'Google로 로그인',
                      subtitle: '데이터를 안전하게 동기화하세요',
                      iconColor: const Color(0xFF4285F4),
                      onTap: () async {
                        final success = await authProvider.signInWithGoogle();
                        if (!success && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('로그인에 실패했습니다')),
                          );
                        }
                      },
                    )
                  else
                    _SettingsTile(
                      icon: Icons.logout_rounded,
                      title: '로그아웃',
                      subtitle: authProvider.displayName,
                      iconColor: AppTheme.error,
                      textColor: AppTheme.error,
                      onTap: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (c) => AlertDialog(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            title: const Text('로그아웃'),
                            content: const Text('정말 로그아웃하시겠습니까?'),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.pop(c, false),
                                  child: const Text('취소')),
                              TextButton(
                                onPressed: () => Navigator.pop(c, true),
                                child: const Text('로그아웃',
                                    style:
                                        TextStyle(color: AppTheme.error)),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true && context.mounted) {
                          await authProvider.signOut();
                          if (context.mounted) {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                  builder: (_) => const LoginScreen()),
                              (_) => false,
                            );
                          }
                        }
                      },
                    ),
                ],
              ),

              const SizedBox(height: 16),

              // App info
              _SettingsSection(
                title: '앱 정보',
                icon: Icons.info_outline_rounded,
                color: Colors.grey.shade600,
                children: [
                  _SettingsTile(
                    icon: Icons.apps_rounded,
                    title: 'Camdo',
                    subtitle: '버전 1.0.0',
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final AuthProvider authProvider;

  const _ProfileCard({required this.authProvider});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primary, AppTheme.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: Colors.white30,
            backgroundImage: authProvider.photoUrl != null
                ? NetworkImage(authProvider.photoUrl!)
                : null,
            child: authProvider.photoUrl == null
                ? const Icon(Icons.person, color: Colors.white, size: 32)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  authProvider.displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  authProvider.isAnonymous
                      ? '익명 사용자'
                      : authProvider.user?.email ?? '',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color? iconColor;
  final Color? textColor;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.trailing,
    this.iconColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: (iconColor ?? AppTheme.primary).withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: iconColor ?? AppTheme.primary,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: textColor ?? Colors.black87,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
      ),
      trailing: trailing ??
          (onTap != null
              ? Icon(Icons.chevron_right,
                  color: Colors.grey.shade400, size: 20)
              : null),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}
