InkWell(
  onTap: () => _safeLaunch(Uri.parse('https://www.instagram.com/muhammadibrahimubharay/')),
  borderRadius: BorderRadius.circular(20),
  child: Stack(
    alignment: Alignment.center,
    children: [
      // 1. Your Latest Video Thumbnail
      ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.asset(
          'assets/images/latest_post.jpg', // Ensure this file exists
          height: 220,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      ),
      // 2. The "Play" Overlay
      Container(
        height: 220,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      Column(
        children: [
          const Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 60),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFE1306C), // Instagram Pink
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'See on Instagram',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    ],
  ),
)
