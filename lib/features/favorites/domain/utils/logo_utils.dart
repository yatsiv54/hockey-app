String logoUrlFromAbbrev(String abbrev) {
  final code = abbrev.toUpperCase().trim();
  return 'https://assets.nhle.com/logos/nhl/svg/${code}_dark.svg';
}
