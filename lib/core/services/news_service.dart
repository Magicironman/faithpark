import '../models/models.dart';

class NewsSource {
  NewsSource({
    required this.name,
    required this.url,
    required this.category,
  });

  final String name;
  final String url;
  final String category;
}

class NewsService {
  /// Replace these with real RSS or backend endpoints.
  final List<NewsSource> sources = [
    NewsSource(
      name: 'CityNews Toronto',
      url: 'https://toronto.citynews.ca/feed/',
      category: 'Toronto',
    ),
    NewsSource(
      name: 'CBC Top Stories',
      url: 'https://www.cbc.ca/webfeed/rss/rss-topstories',
      category: 'Canada',
    ),
    NewsSource(
      name: 'Global News',
      url: 'https://globalnews.ca/feed/',
      category: 'Canada',
    ),
  ];

  Future<List<NewsItem>> fetchHeadlines() async {
    // Starter implementation:
    // To keep setup simple, this returns mocked items if fetching/parsing is not yet added.
    // Replace with an RSS parser or backend summarizer.
    final now = DateTime.now();
    return [
      NewsItem(
        title: 'Toronto traffic and transit updates lead local headlines',
        source: 'CityNews Toronto',
        category: 'Toronto',
        link: 'https://toronto.citynews.ca/',
        publishedAt: now,
        summary: 'Local traffic, transit, and city developments are leading the day.',
      ),
      NewsItem(
        title: 'Canada policy and economy remain in focus',
        source: 'CBC Top Stories',
        category: 'Canada',
        link: 'https://www.cbc.ca/news',
        publishedAt: now,
        summary: 'National headlines are focused on policy, affordability, and business updates.',
      ),
      NewsItem(
        title: 'AI and technology continue to shape daily life',
        source: 'Global News',
        category: 'Tech',
        link: 'https://globalnews.ca/tech/',
        publishedAt: now,
        summary: 'Technology and AI stories remain prominent across Canadian coverage.',
      ),
    ];
  }

  String buildSpokenBriefing(List<NewsItem> items, {required bool cantonese}) {
    if (cantonese) {
      return '''
而家同你講下今日多倫多同加拿大嘅重點新聞。

首先係多倫多本地新聞，${items.isNotEmpty ? items[0].summary : '今日有幾單本地交通同城市發展新聞值得留意。'}

跟住係加拿大全國方面，${items.length > 1 ? items[1].summary : '全國焦點仍然集中喺政策、經濟，同埋民生議題。'}

科技方面，${items.length > 2 ? items[2].summary : 'AI 同科技應用繼續影響日常生活同商業發展。'}

如果你想，我而家可以繼續讀來源同埋詳細分類俾你聽。
''';
    }

    return '''
Here is your Toronto and Canada news briefing.

For local Toronto coverage, ${items.isNotEmpty ? items[0].summary : 'traffic, transit, and city updates are drawing attention today.'}

At the Canada level, ${items.length > 1 ? items[1].summary : 'policy, affordability, and business remain key themes.'}

In technology, ${items.length > 2 ? items[2].summary : 'AI and technology stories continue to shape the day.'}

I can also read the sources and categories next.
''';
  }
}
