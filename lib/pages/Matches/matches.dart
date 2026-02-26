import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/ProfileCarousel.dart';
import '../../widgets/navigation.dart';
import '../../providers/matchState.dart'; 

class Matches extends StatefulWidget {
  final bool shouldUpdate;
  const Matches({Key? key, this.shouldUpdate = false}) : super(key: key);
  
  @override
  State<Matches> createState() => _Matches();
}

class _Matches extends State<Matches> {
  List<Map<String, dynamic>> _matchInstances = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMatchInstances();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    Provider.of<MatchSyncProvider>(context);
    if (!_isLoading && _matchInstances.isNotEmpty) {
      _loadMatchInstances();
    }
  }

  void _loadMatchInstances() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final matchSync = Provider.of<MatchSyncProvider>(context, listen: false);

      await matchSync.firstSnapshotReady;

      _matchInstances = matchSync.allMatchInstances;

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading match instances: $e');
      if (mounted) {
        setState(() {
          _matchInstances = [];
          _isLoading = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const CustomStatusBar(),
            Expanded(
              child: ProfileCarousel(
                matchInstances: _matchInstances,
                isLoading: _isLoading,
              ),
            ),
          ],
        ),
      ),
    );
  }

}