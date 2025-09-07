import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SkeletonLoading extends StatefulWidget {
  final Widget child;
  final bool isLoading;

  const SkeletonLoading({
    super.key,
    required this.child,
    required this.isLoading,
  });

  @override
  State<SkeletonLoading> createState() => _SkeletonLoadingState();
}

class _SkeletonLoadingState extends State<SkeletonLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: const [
                Colors.transparent,
                Colors.white,
                Colors.transparent,
              ],
              stops: [
                _animation.value - 0.3,
                _animation.value,
                _animation.value + 0.3,
              ].map((stop) => stop.clamp(0.0, 1.0)).toList(),
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

class SkeletonBox extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const SkeletonBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.borderColor,
        borderRadius: borderRadius ?? BorderRadius.circular(4),
      ),
    );
  }
}

class SkeletonAvatar extends StatelessWidget {
  final double radius;

  const SkeletonAvatar({super.key, this.radius = 24});

  @override
  Widget build(BuildContext context) {
    return SkeletonBox(
      width: radius * 2,
      height: radius * 2,
      borderRadius: BorderRadius.circular(radius),
    );
  }
}

class SkeletonText extends StatelessWidget {
  final double? width;
  final double height;

  const SkeletonText({
    super.key,
    this.width,
    this.height = 16,
  });

  @override
  Widget build(BuildContext context) {
    return SkeletonBox(
      width: width,
      height: height,
      borderRadius: BorderRadius.circular(height / 2),
    );
  }
}

class SkeletonUserCard extends StatelessWidget {
  const SkeletonUserCard({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonLoading(
      isLoading: true,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User header
            Row(
              children: [
                const SkeletonAvatar(radius: 28),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SkeletonText(width: 120, height: 20),
                      const SizedBox(height: 8),
                      Row(
                        children: List.generate(
                          5,
                          (index) => Container(
                            margin: const EdgeInsets.only(right: 4),
                            child: const SkeletonBox(width: 16, height: 16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const SkeletonText(width: 180, height: 14),
                    ],
                  ),
                ),
                Column(
                  children: [
                    const SkeletonBox(width: 40, height: 24),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const SkeletonBox(width: 80, height: 36),
                        const SizedBox(width: 8),
                        const SkeletonBox(width: 60, height: 36),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Skills section
            Row(
              children: [
                const SkeletonBox(width: 40, height: 40),
                const SizedBox(width: 12),
                const SkeletonText(width: 80, height: 16),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(
                3,
                (index) => const SkeletonBox(width: 100, height: 32),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SkeletonMarketplace extends StatelessWidget {
  const SkeletonMarketplace({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: 5,
      itemBuilder: (context, index) => const SkeletonUserCard(),
    );
  }
}

class SkeletonChatMessage extends StatelessWidget {
  final bool isMe;

  const SkeletonChatMessage({super.key, this.isMe = false});

  @override
  Widget build(BuildContext context) {
    return SkeletonLoading(
      isLoading: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        child: Row(
          mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            if (!isMe) ...[
              const SkeletonAvatar(radius: 16),
              const SizedBox(width: 8),
            ],
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              child: SkeletonBox(
                width: 120 + (isMe ? 0 : 40),
                height: 40,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            if (isMe) ...[
              const SizedBox(width: 8),
              const SkeletonAvatar(radius: 16),
            ],
          ],
        ),
      ),
    );
  }
}

class SkeletonChatList extends StatelessWidget {
  const SkeletonChatList({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ...List.generate(3, (index) => const SkeletonChatMessage(isMe: false)),
        ...List.generate(2, (index) => const SkeletonChatMessage(isMe: true)),
        ...List.generate(2, (index) => const SkeletonChatMessage(isMe: false)),
      ],
    );
  }
}
