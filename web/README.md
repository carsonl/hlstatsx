# hlstatsx-revamped-website
HLstatsX Community Edition is an open-source project licensed under GNU General Public License v2 and is a real-time stats and ranking for Source engine based games. HLstatsX Community Edition uses a Perl daemon to parse the log streamed from the game server. The data is stored in a MySQL Database and has a PHP frontend.

## Dependancies
- Database
  - MySQL 5.5+ (5.7.x recommended)
  
- PHP (duh)
  - gd 
  - mysqli
  - curl
  - xml
  
- Perl (Also duh)
  - MaxMind::DB::Reader
  - GeoIP2::Database::Reader
  - Syntax::Keyword::Try
  
- Packages (Linux)
  - build-essential
  - libssl-dev
  - zlib1g-dev
  - libdbd-mysql-perl
  - openssl
  - unzip
  
  Please check [this](https://github.com/NomisCZ/hlstatsx-community-edition/wiki) guide for a tutorial on setup and etc. Or just use google lol.
