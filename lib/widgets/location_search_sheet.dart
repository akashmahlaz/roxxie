import 'package:flutter/material.dart';
import '../core/services/location_service.dart';
import '../core/theme/theme.dart';

class LocationSearchSheet extends StatefulWidget {
  final Brightness brightness;

  const LocationSearchSheet({super.key, required this.brightness});

  @override
  State<LocationSearchSheet> createState() => _LocationSearchSheetState();
}

class _LocationSearchSheetState extends State<LocationSearchSheet> {
  final _searchController = TextEditingController();
  final _locationService = LocationService();
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await _locationService.searchLocations(query);
      if (mounted) {
        setState(() {
          _results = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to find locations';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _useCurrentLocation() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final location = await _locationService.getLocationWithAddress();
      if (mounted) {
        Navigator.pop(context, location);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Could not get current location';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.sheetBackground(widget.brightness),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textSec(widget.brightness).withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          Text(
            'Select Location',
            style: TextStyle(
              color: AppColors.text(widget.brightness),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          // Search Box
          TextField(
            controller: _searchController,
            style: TextStyle(color: AppColors.text(widget.brightness)),
            decoration: InputDecoration(
              hintText: 'Search city...',
              hintStyle: TextStyle(color: AppColors.textSec(widget.brightness)),
              prefixIcon: Icon(Icons.search, color: AppColors.textSec(widget.brightness)),
              filled: true,
              fillColor: AppColors.inputFill(widget.brightness),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.arrow_forward_rounded),
                color: AppColors.crimson,
                onPressed: () => _search(_searchController.text),
              ),
            ),
            onSubmitted: _search,
          ),

          const SizedBox(height: 16),

          // Current Location Button
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.crimson.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.my_location, color: AppColors.crimson),
            ),
            title: Text(
              'Use current location',
              style: TextStyle(
                color: AppColors.crimson,
                fontWeight: FontWeight.w600,
              ),
            ),
            onTap: _useCurrentLocation,
          ),

          const Divider(),

          // Results
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: AppColors.crimson,
                    ),
                  )
                : _error != null
                    ? Center(
                        child: Text(
                          _error!,
                          style: TextStyle(color: AppColors.error),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _results.length,
                        itemBuilder: (context, index) {
                          final loc = _results[index];
                          return ListTile(
                            leading: Icon(
                              Icons.location_on_outlined,
                              color: AppColors.textSec(widget.brightness),
                            ),
                            title: Text(
                              loc['address'] ?? 'Unknown',
                              style: TextStyle(color: AppColors.text(widget.brightness)),
                            ),
                            onTap: () => Navigator.pop(context, loc),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
