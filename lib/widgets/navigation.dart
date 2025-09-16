import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/userState.dart';
import 'menu.dart';
import '../router/router.dart';

class CustomStatusBar extends StatefulWidget {
  const CustomStatusBar({
    Key? key,
  }) : super(key: key);

  @override
  State<CustomStatusBar> createState() => _CustomStatusBarState();
}

class _CustomStatusBarState extends State<CustomStatusBar> {
  int refinedMatchesCount = 12000;
  bool infoIncomplete = true;
  bool needsUpdated = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onPressed: () { 
              AppMenuOverlay.show(context); 
            },
          ), 
          ElevatedButton(
            onPressed: () async {
              final userSync = Provider.of<UserSyncProvider>(context, listen: false);
              await userSync.refreshDiscoverableUsers(context);
            },
            child: const Text('Refresh Users'),
          ),
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.black),
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.editNeeds);
            },
          )
        ],
      ),
    );
  }

  
}