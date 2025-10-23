import 'package:flutter/material.dart';
import '../../functions/miscService.dart';
import '../../styles.dart';
import '../../widgets/navigation.dart';
import '../../widgets/pill.dart'; 
import '../../widgets/matchCTA.dart';
import '../../widgets/flagUser.dart';

class Match extends StatefulWidget {
  const Match({super.key});
  @override
  State<Match> createState() => _Match();
}

class _Match extends State<Match> {
  Map<String, dynamic>? profile; 

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final Map<String, dynamic>? profileData = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;

      if (profileData == null) {
        print("❌ Error: Profile data is null!");
        return;
      }

      setState(() {
        profile = profileData;
      });

    });
  
  }

  @override
  Widget build(BuildContext context) {
    if (profile == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final photos = profile!['photos'] as List;
    
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const CustomStatusBar(),
              Container(
                padding: const EdgeInsets.all(16),
                child: Column (
                  children: [
                    
                    /* = = = = = = = = = 
                    First Photo
                    = = = = = = = = = = */
                    if (photos.isNotEmpty)
                      Container(
                        width: double.infinity,
                        height: 400,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            photos[0],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[300],
                                child: const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                              );
                            },
                          ),
                        ),
                      ),

                    /* = = = = = = = = = 
                    Match Overview
                    = = = = = = = = = = */
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                      margin: const EdgeInsets.only(bottom: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Match ${profile?['compatibility']?['percentage']?.toInt() ?? 0}%',
                            style: AppTextStyles.headingLarge.copyWith(
                              color: ColorPalette.peach,
                              fontSize: 48,
                            ),
                          ),
                          Text(
                            "${profile?['firstName'] ?? 'Unknown'}, ${MiscService().calculateAge(profile?['birthDate'])}, ${profile?['school']}, ${profile?['career']}",
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: ColorPalette.peach,
                            ),
                          ),
                        ],
                      ),
                    ),

                    /* = = = = = = = = = 
                    MBTI Overview
                    = = = = = = = = = = */
                    /*Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 30),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: ColorPalette.peachLite,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MBTI Match',
                            style: AppTextStyles.headingMedium.copyWith(
                              color: ColorPalette.peach,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Lorium ipsum lorium ipsum',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: ColorPalette.peach,
                            ),
                          ),
                        ],
                      ),
                    ),*/

                    /* = = = = = = = = = 
                    Chemistry Match
                    = = = = = = = = = = */
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 30),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: ColorPalette.peach,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${profile?['compatibility']?['chemistry']?['percentage']?.toInt() ?? 0}%',
                            style: AppTextStyles.headingLarge.copyWith(
                              color: ColorPalette.white,
                            ),
                          ),
                          Text(
                            'Chemistry Match',
                            style: AppTextStyles.headingMedium.copyWith(
                              color: ColorPalette.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          // Display the reason
                          if (profile?['compatibility']?['chemistry']?['reason'] != null)
                            Column(
                              children: [
                                PillText(
                                  text: profile!['compatibility']['chemistry']['reason'],
                                  colorVariant: "peachLite"
                                ),
                                const SizedBox(height: 8),
                              ],
                            ),
                          
                          // Display all matches (not just the first one)
                          if (profile?['compatibility']?['chemistry']?['matches'] != null)
                            ...((profile!['compatibility']['chemistry']['matches'] as List).map((match) => 
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: PillText(
                                  text: match, 
                                  colorVariant: "peachLite"
                                ),
                              ),
                            ).toList()),
                        ],
                      ),
                    ),

                    /* = = = = = = = = = 
                    Second Photo
                    = = = = = = = = = = */
                    if (photos.length > 1)
                      Container(
                        width: double.infinity,
                        height: 400,
                        margin: const EdgeInsets.only(bottom: 20),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            photos[1],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[300],
                                child: const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                              );
                            },
                          ),
                        ),
                      ),

                    /* = = = = = = = = = 
                    Personality Match
                    = = = = = = = = = = */
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 30),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: ColorPalette.peach,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${profile?['compatibility']?['personality']?['percentage']?.toInt() ?? 0}%',
                            style: AppTextStyles.headingLarge.copyWith(
                              color: ColorPalette.white,
                            ),
                          ),
                          Text(
                            'Personality Match',
                            style: AppTextStyles.headingMedium.copyWith(
                              color: ColorPalette.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (profile?['compatibility']?['personality']?['reason'] != null)
                            Column(
                              children: [
                                PillText(
                                  text: profile!['compatibility']['personality']['reason'],
                                  colorVariant: "peachLite"
                                ),
                                const SizedBox(height: 8),
                              ],
                            ),                                  
                          if (profile?['compatibility']?['personality']?['matches'] != null && 
                              (profile!['compatibility']['personality']['matches'] as List).isNotEmpty)
                            ...((profile!['compatibility']['personality']['matches'] as List).map((match) => 
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: PillText(
                                  text: match, 
                                  colorVariant: "peachLite"
                                ),
                              ),
                            ).toList()),
                        ],
                      ),
                    ),

                    /* = = = = = = = = = 
                    Third Photo
                    = = = = = = = = = = */
                    if (photos.length > 2)
                      Container(
                        width: double.infinity,
                        height: 400,
                        margin: const EdgeInsets.only(bottom: 20),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            photos[2],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[300],
                                child: const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                              );
                            },
                          ),
                        ),
                      ),

                    /* = = = = = = = = = 
                    Interests Match
                    = = = = = = = = = = */
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 30),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: ColorPalette.violet,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${profile?['compatibility']?['interests']?['percentage']?.toInt() ?? 0}%',
                            style: AppTextStyles.headingLarge.copyWith(
                              color: ColorPalette.white,
                            ),
                          ),
                          Text(
                            'Interests Match',
                            style: AppTextStyles.headingMedium.copyWith(
                              color: ColorPalette.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (profile?['compatibility']?['interests']?['reason'] != null)
                            Column(
                              children: [
                                PillText(
                                  text: profile!['compatibility']['interests']['reason'],
                                  colorVariant: "peachLite"
                                ),
                                const SizedBox(height: 8),
                              ],
                            ),                                  
                          if (profile?['compatibility']?['interests']?['matches'] != null && 
                              (profile!['compatibility']['interests']['matches'] as List).isNotEmpty)
                            ...((profile!['compatibility']['interests']['matches'] as List).map((match) => 
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: PillText(
                                  text: match, 
                                  colorVariant: "peachLite"
                                ),
                              ),
                            ).toList()),
                        ],
                      ),
                    ),

                    /* = = = = = = = = = 
                    Fourth Photo
                    = = = = = = = = = = */
                    if (photos.length > 3)
                      Container(
                        width: double.infinity,
                        height: 400,
                        margin: const EdgeInsets.only(bottom: 20),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            photos[3],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[300],
                                child: const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                              );
                            },
                          ),
                        ),
                      ),

                    /* = = = = = = = = = 
                    Goals Match
                    = = = = = = = = = = */
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 30),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: ColorPalette.green,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${profile?['compatibility']?['goals']?['percentage']?.toInt() ?? 0}%',
                            style: AppTextStyles.headingLarge.copyWith(
                              color: ColorPalette.white,
                            ),
                          ),
                          Text(
                            'Life Goals Alignment',
                            style: AppTextStyles.headingMedium.copyWith(
                              color: ColorPalette.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (profile?['compatibility']?['goals']?['reason'] != null)
                            Column(
                              children: [
                                PillText(
                                  text: profile!['compatibility']['goals']['reason'],
                                  colorVariant: "peachLite"
                                ),
                                const SizedBox(height: 8),
                              ],
                            ),                                  
                          if (profile?['compatibility']?['goals']?['matches'] != null && 
                              (profile!['compatibility']['goals']['matches'] as List).isNotEmpty)
                            ...((profile!['compatibility']['goals']['matches'] as List).map((match) => 
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: PillText(
                                  text: match, 
                                  colorVariant: "peachLite"
                                ),
                              ),
                            ).toList()),
                        ],
                      ),
                    ),

                    /* = = = = = = = = = 
                    Call to Action
                    = = = = = = = = = = */ 
                    MatchCTA(
                      targetUserId: profile?['userId'] ?? '',
                    ),

                    /* = = = = = = = = = 
                    Flag User Button
                    = = = = = = = = = = */ 
                    IconButton(
                      icon: const Icon(Icons.flag, color: Colors.red),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => FlagUserWidget(
                            targetUserId: profile?['userId'] ?? '',
                            chatId: 'optional_chat_id', // Optional - pass if flagging from a chat
                          ),
                        );
                      },
                    )
                 
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