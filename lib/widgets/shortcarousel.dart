import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../styles.dart';

enum CarouselItemType { image, matchQuality }
enum CarouselAlignment { left, right, center }
enum CarouselType { 
  imageMatchQuality, 
  matchQualityImage, 
  imageImage, 
  matchQualityMatchQuality,
  singleImage,
  singleMatchQuality
}

class CarouselItem {
  final CarouselItemType type;
  final Map<String, dynamic> data;

  CarouselItem({
    required this.type,
    required this.data,
  });
}

class TwoItemCarousel extends StatelessWidget {
  final CarouselType type;
  final CarouselAlignment alignment;
  final Function()? getNextImage;
  final Function()? getNextMatchQuality;
  final Function()? getNextMatchQuality2;
  final double height;
  final double viewportFraction;
  final bool enlargeCenterPage;
  final EdgeInsets margin;
  

  const TwoItemCarousel({
    Key? key,
    required this.type,
    this.alignment = CarouselAlignment.center,
    this.getNextImage,
    this.getNextMatchQuality,
    this.getNextMatchQuality2,
    this.height = 300,
    this.viewportFraction = 0.85,
    this.enlargeCenterPage = false,
    this.margin = const EdgeInsets.only(bottom: 20),
  }) : super(key: key);

  Widget _buildImageCard(String? imageUrl) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: imageUrl != null
        ? Image.network(
            imageUrl,
            fit: BoxFit.cover,
            height: height,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: height,
                color: Colors.grey[300],
                child: const Icon(
                  Icons.image_not_supported,
                  size: 50,
                  color: Colors.grey,
                ),
              );
            },
          )
        : Container(
            height: height,
            color: Colors.grey[300],
            child: const Icon(
              Icons.image_not_supported,
              size: 50,
              color: Colors.grey,
            ),
          ),
      ),
    );
  }

  Widget _buildMatchQualityCard(Map<String, dynamic>? qualityData) {

    if (qualityData == null) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text(
            'No Data',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: qualityData['color'] ?? ColorPalette.peach,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top section with text
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                qualityData['percentage'] ?? '0%',
                style: AppTextStyles.headingSmall.copyWith(
                  color: ColorPalette.white,
                  fontSize: 28,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                qualityData['description'] ?? '',
                style: AppTextStyles.headingSmall.copyWith(
                  color: ColorPalette.white,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          const Spacer(),
          Align(
            alignment: Alignment.bottomRight,
            child: GestureDetector(
              //onTap: () => _openMessageWindow(context),
              child: const Icon(
                Icons.send,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCarouselItems() {
    List<Widget> items = [];

    switch (type) {
      case CarouselType.imageMatchQuality:
        items = [
          _buildImageCard(getNextImage?.call()),
          _buildMatchQualityCard(getNextMatchQuality?.call()),
        ];
        break;

      case CarouselType.matchQualityImage:
        items = [
          _buildMatchQualityCard(getNextMatchQuality?.call()),
          _buildImageCard(getNextImage?.call()),
        ];
        break;

      case CarouselType.imageImage:
        items = [
          _buildImageCard(getNextImage?.call()),
          _buildImageCard(getNextImage?.call()),
        ];
        break;

      case CarouselType.matchQualityMatchQuality:
        items = [
          _buildMatchQualityCard(getNextMatchQuality?.call()),
          _buildMatchQualityCard(getNextMatchQuality2?.call()),
        ];
        break;

      case CarouselType.singleImage:
        items = [_buildImageCard(getNextImage?.call())];
        break;

      case CarouselType.singleMatchQuality:
        items = [_buildMatchQualityCard(getNextMatchQuality?.call())];
        break;
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final items = _buildCarouselItems();
    
    if (items.isEmpty) {
      return Container(height: height, margin: margin);
    }

    // If only one item, show it centered
    if (items.length == 1) {
      return Container(
        height: height,
        margin: margin,
        child: items[0],
      );
    }

    return Container(
      height: height,
      margin: margin,
      child: Transform.translate(
        offset: Offset(
          alignment == CarouselAlignment.left ? -10 : 
          (alignment == CarouselAlignment.right ? 10 : 0), 
          0
        ),
      child: CarouselSlider(
        options: CarouselOptions(
          height: height,
          viewportFraction: viewportFraction,
          enlargeCenterPage: enlargeCenterPage,
          enableInfiniteScroll: false,
          autoPlay: false,
          initialPage: alignment == CarouselAlignment.right ? 1 : 0,
          //viewportFraction: alignment == CarouselAlignment.right ? 0.7 : (alignment == CarouselAlignment.left ? 0.70 : viewportFraction),
        ),
        items: items,
      ),
      ),
    );
  }
}