import 'package:flutter/material.dart';
import '../widgets/common.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Column(children: [
        // Top bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: const BoxDecoration(
            color: Color(0xFF080D19),
            border: Border(bottom: BorderSide(color: kBorder)),
          ),
          child: Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: kAccent, borderRadius: BorderRadius.circular(10)),
              child: const Center(
                child: Text('G', style: TextStyle(color: Colors.white,
                  fontWeight: FontWeight.w900, fontSize: 24))),
            ),
            const SizedBox(width: 14),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
              Text('GRAYSTONE', style: TextStyle(color: kText,
                fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: 4)),
              Text('AI DEV FILE MANAGER  •  v1.0.0',
                style: TextStyle(color: kMuted, fontSize: 10, letterSpacing: 1)),
            ]),
            const Spacer(),
            _StatusDot(),
            const SizedBox(width: 8),
            const Text('Ready', style: TextStyle(color: kAccent2, fontSize: 11)),
            const SizedBox(width: 16),
            IconButton(
              icon: const Icon(Icons.settings, color: kMuted, size: 20),
              onPressed: () => Navigator.pushNamed(context, '/settings'),
            ),
            IconButton(
              icon: const Icon(Icons.system_update, color: kMuted, size: 20),
              onPressed: () => Navigator.pushNamed(context, '/updater'),
            ),
          ]),
        ),

        // Main grid
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('What do you want to do?',
                style: TextStyle(color: kText, fontWeight: FontWeight.w700, fontSize: 22)),
              const SizedBox(height: 6),
              const Text('Select a module to get started.',
                style: TextStyle(color: kMuted, fontSize: 13)),
              const SizedBox(height: 24),

              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 1.4,
                children: [
                  _NavCard(
                    icon: Icons.grid_view,
                    color: kAccent,
                    title: 'File Manager UI',
                    subtitle: 'All-in-one upload, download, find, install',
                    route: '/manager',
                  ),
                  _NavCard(
                    icon: Icons.folder_open,
                    color: kAccent,
                    title: 'File Manager',
                    subtitle: 'Find, copy, move, zip, replace files',
                    route: '/files',
                  ),
                  _NavCard(
                    icon: Icons.inventory_2,
                    color: const Color(0xFF0369A1),
                    title: 'ASAR Tools',
                    subtitle: 'Extract, repack, install into AnythingLLM',
                    route: '/asar',
                  ),
                  _NavCard(
                    icon: Icons.palette,
                    color: const Color(0xFF7F1D1D),
                    title: 'Splash Screen',
                    subtitle: 'Install Graystone splash into AnythingLLM',
                    route: '/splash',
                  ),
                  _NavCard(
                    icon: Icons.build,
                    color: const Color(0xFF065F46),
                    title: 'Languages',
                    subtitle: 'Download & install 18+ languages',
                    route: '/languages',
                  ),
                  _NavCard(
                    icon: Icons.vpn_key,
                    color: const Color(0xFF78350F),
                    title: 'API Keys',
                    subtitle: 'Manage all your AI provider keys',
                    route: '/apikeys',
                  ),
                  _NavCard(
                    icon: Icons.system_update,
                    color: const Color(0xFF1E3A5F),
                    title: 'Updater',
                    subtitle: 'Check for and install updates',
                    route: '/updater',
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // AnythingLLM paths
              GCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const GCardTitle('AnythingLLM Paths'),
                  ...const {
                    'Install':   r'%LOCALAPPDATA%\Programs\AnythingLLM\resources\',
                    'Storage':   r'%APPDATA%\anythingllm-desktop\storage\',
                    'ASAR':      r'%LOCALAPPDATA%\Programs\AnythingLLM\resources\app.asar',
                    'HTTP':      r'%LOCALAPPDATA%\Programs\AnythingLLM\resources\app.asar.extracted\http\',
                  }.entries.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(children: [
                      SizedBox(width: 70,
                        child: Text(e.key, style: const TextStyle(color: kMuted, fontSize: 11))),
                      Expanded(child: GPathBox(e.value)),
                    ]),
                  )),
                ]),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _StatusDot extends StatefulWidget {
  @override
  State<_StatusDot> createState() => _StatusDotState();
}

class _StatusDotState extends State<_StatusDot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _anim = Tween(begin: 0.3, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(width: 8, height: 8,
        decoration: const BoxDecoration(color: kSuccess, shape: BoxShape.circle)),
    );
  }
}

class _NavCard extends StatefulWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String route;
  const _NavCard({required this.icon, required this.color, required this.title,
    required this.subtitle, required this.route});

  @override
  State<_NavCard> createState() => _NavCardState();
}

class _NavCardState extends State<_NavCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(context, widget.route),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _hovered ? kPanel : kPanel2,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _hovered ? widget.color : kBorder),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(widget.icon, color: widget.color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(widget.title,
              style: const TextStyle(color: kText, fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 4),
            Text(widget.subtitle,
              style: const TextStyle(color: kMuted, fontSize: 11),
              maxLines: 2, overflow: TextOverflow.ellipsis),
          ]),
        ),
      ),
    );
  }
}
