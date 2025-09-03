import 'package:flutter/material.dart';
import '../../functions/uiService.dart';
import '../../functions/matchesService.dart';
import '../../styles.dart';
import '../../widgets/navigation.dart';
import '../../widgets/pill.dart'; 
import '../../widgets/matchCTA.dart';

class Match extends StatefulWidget {
  const Match({super.key});
  @override
  State<Match> createState() => _Match();
}

class _Match extends State<Match> {
  Map<String, dynamic>? profile; 
  RequestStatus _requestStatus = RequestStatus.loading;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final Map<String, dynamic>? profileData = 
      ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;

      if (profileData == null) {
        print("❌ Error: Profile data is null!");
        return;
      }

      setState(() {
        profile = profileData;
      });

      // Check pending request status
      final targetUserId = profile?['userId'];
      if (targetUserId != null) {
        final hasPending = await MatchesService.checkPendingRequest(targetUserId);
        setState(() {
          _requestStatus = hasPending ? RequestStatus.pending : RequestStatus.available;
        });
      } else {
        setState(() {
          _requestStatus = RequestStatus.available;
        });
      }
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
                            '95% Match',
                            style: AppTextStyles.headingLarge.copyWith(
                              color: ColorPalette.peach,
                              fontSize: 48,
                            ),
                          ),
                          Text(
                            "${profile?['firstName'] ?? 'Unknown'}, ${UserActions().calculateAge(profile?['birthDate'])}",
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: ColorPalette.peach,
                            ),
                          ),
                        ],
                      ),
                    ),

                    /* = = = = = = = = = 
                    Key Match Indicators
                    = = = = = = = = = = */
                    Container(
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
                            'Key Match Indicators',
                            style: AppTextStyles.headingMedium.copyWith(
                              color: ColorPalette.peach,
                            ),
                          ),
                          const SizedBox(height: 8),
                          PillText(text: 'complimenting emotional qualities', colorVariant: "white"),
                          const SizedBox(height: 8),
                          PillText(text: 'best friend in a partner', colorVariant: "white"),
                          const SizedBox(height: 8),
                          PillText(text: 'bar hopping', colorVariant: "white"),
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
                            '95%',
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
                          PillText(text: 'complimenting emotional qualities', colorVariant: "peachLite"),
                          const SizedBox(height: 8),
                          PillText(text: 'best friend in a partner', colorVariant: "peachLite"),
                          const SizedBox(height: 8),
                          PillText(text: 'bar hopping', colorVariant: "peachLite"),
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
                    LifeStyle Match
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
                            '95%',
                            style: AppTextStyles.headingLarge.copyWith(
                              color: ColorPalette.white,
                            ),
                          ),
                          Text(
                            'LifeStyle Match',
                            style: AppTextStyles.headingMedium.copyWith(
                              color: ColorPalette.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          PillText(text: 'complimenting emotional qualities', colorVariant: "violetLite"),
                          const SizedBox(height: 8),
                          PillText(text: 'best friend in a partner', colorVariant: "violetLite"),
                          const SizedBox(height: 8),
                          PillText(text: 'bar hopping', colorVariant: "violetLite"),
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
                    Dynamics Match
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
                            '95%',
                            style: AppTextStyles.headingLarge.copyWith(
                              color: ColorPalette.white,
                            ),
                          ),
                          Text(
                            'Dynamics Match',
                            style: AppTextStyles.headingMedium.copyWith(
                              color: ColorPalette.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          PillText(text: 'complimenting emotional qualities', colorVariant: "greenLite"),
                          const SizedBox(height: 8),
                          PillText(text: 'best friend in a partner', colorVariant: "greenLite"),
                          const SizedBox(height: 8),
                          PillText(text: 'bar hopping', colorVariant: "greenLite"),
                        ],
                      ),
                    ),

                    /* = = = = = = = = = 
                    Call to Action
                    = = = = = = = = = = */ 
                    MatchCTA(
                      targetUserId: profile?['userId'] ?? '',
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