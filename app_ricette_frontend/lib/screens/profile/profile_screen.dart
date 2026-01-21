import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/profile_controller.dart';
import 'widgets/profile_header.dart';
import 'widgets/profile_tabs.dart';
import 'profile_stats_widget.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with WidgetsBindingObserver {
  ProfileController? _profileController;
  bool _isInitialLoad = true;
  String? _lastShownMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _profileController = Provider.of<ProfileController>(context, listen: false);

    if (_isInitialLoad && _profileController != null) {
      _loadProfile();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cleanupOnExit();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _cleanupOnExit();
    }
  }

  Future<void> _loadProfile() async {
    if (!mounted || _profileController == null) return;

    try {
      await _profileController!.loadProfile();

      if (mounted) {
        setState(() {
          _isInitialLoad = false;
        });
      }
    } catch (e) {
      // Errore silenzioso
    }
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Sei sicuro di voler effettuare il logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _performLogout();
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _performLogout() async {
    try {
      await _profileController?.logout();

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Errore durante il logout'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _cleanupOnExit() {
    _lastShownMessage = null;
    _profileController?.clearSuccessMessage();

    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).clearSnackBars();
    }
  }

  void _showSuccessMessage(String message) {
    if (_lastShownMessage == message || !mounted) return;

    _lastShownMessage = message;

    final snackBar = SnackBar(
      content: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
        ],
      ),
      backgroundColor: Colors.green,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);

    Future.delayed(const Duration(seconds: 4), () {
      if (mounted && _lastShownMessage == message) {
        _lastShownMessage = null;
        _profileController?.clearSuccessMessage();
      }
    });
  }

  Widget _buildErrorWidget(ProfileController controller) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red[700]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  controller.error!,
                  style: TextStyle(color: Colors.red[700]),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: controller.retry,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              foregroundColor: Colors.white,
            ),
            child: const Text('Riprova'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileBody(ProfileController controller) {
    // Controlla se c'è un nuovo messaggio di successo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentMessage = controller.lastSuccessMessage;
      if (currentMessage != null &&
          currentMessage != _lastShownMessage &&
          mounted) {
        _showSuccessMessage(currentMessage);
      }
    });

    return RefreshIndicator(
      onRefresh: () async {
        await controller.refreshProfile();
        if (mounted) {
          setState(() {});
        }
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ProfileHeader(
              key: ValueKey(controller.userProfile?.avatarUrl ?? 'no-avatar'),
            ),
            if (controller.hasProfile && controller.userStats != null)
              ProfileStatsWidget(stats: controller.userStats!),
            SizedBox(
              height: 400,
              child: _isInitialLoad
                  ? const Center(child: CircularProgressIndicator())
                  : const ProfileTabs(),
            ),
            if (controller.error != null) _buildErrorWidget(controller),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Il Mio Profilo',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Consumer<ProfileController>(
        builder: (context, controller, child) {
          return _buildProfileBody(controller);
        },
      ),
    );
  }
}
