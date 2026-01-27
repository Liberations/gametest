import 'dart:ui' as ui;

import 'package:flutter/material.dart';

///需求 一个充值奖励活动页面 充值奖励档位有多个 完成对应档位即可领取奖励
//// 页面从上往下显示多个档位 每个档位有个标题描述 文本说明 奖励列表 充值按钮或者领取按钮 每个档位的奖励以表格形式展示
//// 档位底部是一个规则说明 请完成
/// 资源文件 claim_able 领取按钮背景 claim_unable 不可领取背景
/// recharge_gift_box_bg 充值奖励背景
/// recharge_level_bg 每个档位充值奖励背景
/// top_bg 充值档位顶部是这个背景 底下拼接充值档位
/// leve_all_bg 是所有充值档位的背景保证顶部30px不变形 底部背景拉伸
/// tim_bg 是顶部区域的倒计时背景
class RechargeEventview extends StatefulWidget {
  const RechargeEventview({super.key});

  @override
  State<RechargeEventview> createState() => _RechargeEventviewState();
}

enum TierStatus { locked, needRecharge, canClaim, claimed }

class RewardItem {
  final String name;
  final String amount;
  final IconData icon;

  RewardItem({required this.name, required this.amount, required this.icon});
}

class RewardTier {
  final String title;
  final String desc;
  final int targetAmount; // required recharge amount for this tier
  final List<RewardItem> rewards;
  int currentProgress; // how much the player has recharged toward this tier
  bool claimed;

  RewardTier({
    required this.title,
    required this.desc,
    required this.targetAmount,
    required this.rewards,
    this.currentProgress = 0,
    this.claimed = false,
  });

  TierStatus get status {
    if (claimed) return TierStatus.claimed;
    if (currentProgress >= targetAmount) return TierStatus.canClaim;
    if (currentProgress > 0) return TierStatus.needRecharge;
    return TierStatus.locked;
  }
}

class _RechargeEventviewState extends State<RechargeEventview> {
  // Mock data - replace with real data from API when ready
  final List<RewardTier> _tiers = [
    RewardTier(
      title: 'Starter Pack',
      desc: 'Recharge 5\$ to unlock these starter rewards',
      targetAmount: 5,
      rewards: [
        RewardItem(name: 'Gold', amount: '100', icon: Icons.monetization_on),
        RewardItem(name: 'Gem', amount: '10', icon: Icons.diamond),
        RewardItem(name: 'Chest', amount: '1', icon: Icons.card_giftcard),
      ],
      currentProgress: 0,
    ),
    RewardTier(
      title: 'Value Pack',
      desc: 'Recharge 30\$ to claim bigger rewards',
      targetAmount: 30,
      rewards: [
        RewardItem(name: 'Gold', amount: '1000', icon: Icons.monetization_on),
        RewardItem(name: 'Gem', amount: '50', icon: Icons.diamond),
        RewardItem(name: 'Skin', amount: '1', icon: Icons.person),
        RewardItem(name: 'Boost', amount: '3', icon: Icons.bolt),
      ],
      currentProgress: 10,
    ),
    RewardTier(
      title: 'Super Pack',
      desc: 'Recharge 100\$ to claim the top tier rewards',
      targetAmount: 100,
      rewards: [
        RewardItem(name: 'Gold', amount: '10000', icon: Icons.monetization_on),
        RewardItem(name: 'Gem', amount: '500', icon: Icons.diamond),
        RewardItem(name: 'Exclusive', amount: '1', icon: Icons.emoji_events),
      ],
      currentProgress: 100,
      claimed: false,
    ),
  ];

  void _onRecharge(RewardTier tier) async {
    // Placeholder: integrate actual recharge flow here.
    // For demo we increment progress to simulate a recharge.
    setState(() {
      tier.currentProgress += tier.targetAmount; // simulate full recharge
      if (tier.currentProgress > tier.targetAmount)
        tier.currentProgress = tier.targetAmount;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Recharged for "${tier.title}". You can now claim.'),
      ),
    );
  }

  void _onClaim(RewardTier tier) async {
    // Placeholder: call claim API here. For demo we mark claimed.
    if (tier.status == TierStatus.canClaim) {
      setState(() {
        tier.claimed = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Claimed rewards for "${tier.title}"')),
      );
    }
  }

  Widget _buildRewardTile(RewardItem r, double size) {
    // size is total tile height/width (design 140)
    return SizedBox(
      width: 70,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 70,
            height: 70,
            padding: EdgeInsets.all(2),
            decoration: BoxDecoration(
              image: const DecorationImage(
                image: AssetImage('lib/assets/recharge_gift_box_bg.webp'),
                fit: BoxFit.cover,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Image.asset(
                'lib/assets/fill_code_coin_big.webp',
                width: 65,
                height: 65,
                fit: BoxFit.contain,
              ),
            ),
          ),
          SizedBox(
            width: 132,
            child: Center(
              child: Text(
                "diamond*10M",
                style: TextStyle(color: Colors.white, fontSize: 11),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTierCard(RewardTier tier) {
    final status = tier.status;
    String buttonText;
    bool buttonEnabled = true;

    switch (status) {
      case TierStatus.locked:
        buttonText = 'Recharge(${tier.currentProgress}/${tier.targetAmount})';
        buttonEnabled = true;
        break;
      case TierStatus.needRecharge:
        buttonText = 'Recharge(${tier.currentProgress}/${tier.targetAmount})';
        buttonEnabled = true;
        break;
      case TierStatus.canClaim:
        buttonText = 'Claim';
        buttonEnabled = true;
        break;
      case TierStatus.claimed:
        buttonText = 'Claimed';
        buttonEnabled = false;
        break;
    }

    // Scale everything from design baseline width 750px
    final double screenWidth = MediaQuery.of(context).size.width;
    final double scale = screenWidth / 750.0;
    final double containerW = 651.0 * scale;
    final double containerH = 510.0 * scale;
    final double tierVerticalMargin = 14.0 * scale; // top/bottom -> 28 total
    final double titleFont = 25.0 * scale;
    final double descFont = 22.0 * scale;
    final double rewardItemSize = 140.0 * scale;
    final double rewardSpacing = 30.0 * scale;

    // Each tier centered, fixed background size 651x510, vertical spacing between tiers = 28px
    return Center(
      child: Container(
        width: containerW,
        height: containerH,
        margin: EdgeInsets.symmetric(vertical: tierVerticalMargin),
        decoration: BoxDecoration(
          image: const DecorationImage(
            image: AssetImage('lib/assets/recharge_level_bg.webp'),
            fit: BoxFit.fill,
          ),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Padding(
          padding: EdgeInsets.only(top: 5),
          child: Column(
            children: [
              Text(
                tier.title,
                style: TextStyle(
                  fontSize: titleFont,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 15),
              // Description (left aligned)
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8.0, top: 5),
                  child: Text(
                    tier.desc,
                    style: TextStyle(fontSize: descFont, color: Colors.white),
                    textAlign: TextAlign.left,
                  ),
                ),
              ),
              // spacing between desc and rewards
              // Rewards area centered both vertically and horizontally within this positioned area
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Center(
                    child: LayoutBuilder(
                      builder: (ctx, constraints2) {
                        final rewards = tier.rewards;
                        final availableWidth = constraints2.maxWidth;
                        final double spacing = rewardSpacing;
                        // clamp availableWidth to a minimum to avoid negative sizes
                        final double safeAvailable = availableWidth <= 0
                            ? 1
                            : availableWidth;

                        final int cols = rewards.length < 4
                            ? rewards.length
                            : 4;
                        final double maxItem =
                            (safeAvailable - (cols - 1) * spacing) / cols;
                        final double itemUsed =
                            (maxItem.isFinite && maxItem > 40)
                            ? (maxItem < rewardItemSize
                                  ? maxItem
                                  : rewardItemSize)
                            : (rewardItemSize < 40 ? 40 : rewardItemSize);

                        return SizedBox(
                          child: GridView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: cols,
                                  mainAxisSpacing: spacing,
                                  crossAxisSpacing: spacing,
                                  childAspectRatio: 0.8,
                                ),
                            itemCount: rewards.length,
                            itemBuilder: (_, idx) =>
                                _buildRewardTile(rewards[idx], itemUsed),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: SizedBox(
                    width: 132,
                    height: 31,
                    child: _ImageButton(
                      text: buttonText,
                      enabled: buttonEnabled,
                      onTap: buttonEnabled
                          ? () {
                              if (status == TierStatus.canClaim) {
                                _onClaim(tier);
                              } else {
                                _onRecharge(tier);
                              }
                            }
                          : null,
                    ),
                  ),
                ),
              ),
              // Main content area (title, desc, rewards) - reserved area above button
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 20,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('lib/assets/tim_bg.webp'),
          fit: BoxFit.none,
        ),
      ),
      child: Text(
        'Countdown: 02:12:45',
        textAlign: TextAlign.center,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(color: Colors.white, fontSize: 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: StretchableBottomBg(
          asset: 'lib/assets/top_bg.webp',
          preserveTop: 300, // top 186px should not be stretched (design px)
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 250),
                child: SizedBox(
                  width: double.maxFinite,
                  child: _buildHeader(context),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(top: 20),
                child: Column(
                  children: [
                    Container(
                      margin: EdgeInsets.only(top: 20),
                      child: StretchableBottomBg(
                        asset: 'lib/assets/leve_all_bg.webp',
                        preserveTop: 200,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 120),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ..._tiers.map((t) => _buildTierCard(t)).toList(),
                              const SizedBox(height: 10),
                              // Rules section (scaled from design)
                              Builder(
                                builder: (ctx) {
                                  final double scale =
                                      MediaQuery.of(ctx).size.width / 750.0;
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                    child: Padding(
                                      padding: EdgeInsets.all(12.0 * scale),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Rules',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 28.0 * scale,
                                            ),
                                          ),
                                          SizedBox(height: 8.0 * scale),
                                          Text(
                                            '1. Recharge amounts stack across the event period.',
                                            style: TextStyle(
                                              fontSize: 28.0 * scale,
                                              color: const Color(0xFFFFEDA1),
                                            ),
                                          ),
                                          Text(
                                            '2. Each tier can only be claimed once per account.',
                                            style: TextStyle(
                                              fontSize: 28.0 * scale,
                                              color: const Color(0xFFFFEDA1),
                                            ),
                                          ),
                                          Text(
                                            '3. Rewards will be delivered to your in-game mailbox.',
                                            style: TextStyle(
                                              fontSize: 28.0 * scale,
                                              color: const Color(0xFFFFEDA1),
                                            ),
                                          ),
                                          Text(
                                            '4. The organizer reserves the right to final interpretation.',
                                            style: TextStyle(
                                              fontSize: 28.0 * scale,
                                              color: const Color(0xFFFFEDA1),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImageButton extends StatelessWidget {
  final String text;
  final bool enabled;
  final VoidCallback? onTap;

  const _ImageButton({required this.text, required this.enabled, this.onTap});

  @override
  Widget build(BuildContext context) {
    final asset = enabled
        ? 'lib/assets/claim_able.webp'
        : 'lib/assets/claim_unable.webp';
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        decoration: BoxDecoration(
          image: DecorationImage(image: AssetImage(asset), fit: BoxFit.fill),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            color: enabled ? Colors.white : Colors.white70,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

/// Widget that draws an image background where only a slice (near bottom) stretches while
/// the top preserve area remains un-stretched, using DecorationImage.centerSlice when possible.
class StretchableBottomBg extends StatefulWidget {
  final String asset;
  final double preserveTop; // pixels in the image coordinates (design pixels)
  final Widget child;

  const StretchableBottomBg({
    required this.asset,
    required this.preserveTop,
    required this.child,
    super.key,
  });

  @override
  State<StretchableBottomBg> createState() => _StretchableBottomBgState();
}

class _StretchableBottomBgState extends State<StretchableBottomBg> {
  ui.Image? _img;

  @override
  void initState() {
    super.initState();
    _resolveImage();
  }

  void _resolveImage() {
    final provider = AssetImage(widget.asset);
    final cfg = const ImageConfiguration();
    final stream = provider.resolve(cfg);
    ImageStreamListener? listener;
    listener = ImageStreamListener(
      (ImageInfo info, bool sync) {
        setState(() {
          _img = info.image;
        });
        stream.removeListener(listener!);
      },
      onError: (err, stack) {
        // ignore errors and fall back to non-sliced background
        stream.removeListener(listener!);
      },
    );
    stream.addListener(listener);
  }

  @override
  Widget build(BuildContext context) {
    // If we couldn't resolve the image size yet, just draw the image normally.
    if (_img == null) {
      return Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(widget.asset),
            fit: BoxFit.fill,
          ),
        ),
        child: widget.child,
      );
    }

    final imgW = _img!.width.toDouble();
    final imgH = _img!.height.toDouble();

    // preserveTop is in design px; assume it maps approximately to image pixels.
    // Clamp preserveTop to valid range inside the image.
    double preserveTopPx = widget.preserveTop;
    if (preserveTopPx < 1) preserveTopPx = 1;
    if (preserveTopPx > imgH - 2) preserveTopPx = imgH - 2;

    final sliceTop = preserveTopPx;
    final sliceHeight = 1.0; // stretch a 1px-high horizontal strip
    // centerSlice Rect must be fully inside the image
    final rect = Rect.fromLTWH(1.0, sliceTop, imgW - 2.0, sliceHeight);

    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(widget.asset),
          fit: BoxFit.fill,
          centerSlice: rect,
        ),
      ),
      child: widget.child,
    );
  }
}
