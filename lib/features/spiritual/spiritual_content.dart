const List<String> spiritualCategories = [
  'peace',
  'anxiety',
  'wisdom',
  'encouragement',
  'faith',
  'hope',
  'walk_with_god',
  'proverbs',
  'psalms',
];

String spiritualCategoryLabel(String category, bool isCantonese) {
  if (isCantonese) {
    return switch (category) {
      'peace' => '平安',
      'anxiety' => '焦慮',
      'wisdom' => '智慧',
      'encouragement' => '鼓勵',
      'faith' => '信心',
      'hope' => '盼望',
      'walk_with_god' => '與主同行',
      'proverbs' => '箴言',
      'psalms' => '詩篇',
      _ => category,
    };
  }

  return switch (category) {
    'peace' => 'Peace',
    'anxiety' => 'Anxiety',
    'wisdom' => 'Wisdom',
    'encouragement' => 'Encouragement',
    'faith' => 'Faith',
    'hope' => 'Hope',
    'walk_with_god' => 'Walk With God',
    'proverbs' => 'Proverbs',
    'psalms' => 'Psalms',
    _ => category,
  };
}
