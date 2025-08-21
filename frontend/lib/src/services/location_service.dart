class LocationService {
  // Sample location data - in a real app, this would come from an API
  static final Map<String, Map<String, Map<String, List<String>>>> _locationData = {
    'Lebanon': {
      'Beirut': {
        'Beirut': [
          'Hamra Street',
          'Corniche Beirut',
          'Gemmayzeh Street',
          'Mar Mikhael',
          'Achrafieh',
          'Ras Beirut',
          'Downtown Beirut',
          'Verdun',
          'Manara',
          'Raouche',
          'Sodeco',
          'Tabaris',
          'Furn el Chebbak',
          'Mazraa',
          'Basta',
          'Bourj Hammoud',
          'Sin el Fil',
          'Hazmieh',
          'Chiyah',
          'Haret Hreik'
        ],
        'Achrafieh': [
          'Sassine Square',
          'Monot Street',
          'Gouraud Street',
          'Sodeco',
          'Tabaris',
          'Furn el Chebbak',
          'Sassine',
          'Gouraud',
          'Monot',
          'Sursock',
          'Rmeil',
          'Mina el Hosn'
        ]
      },
      'Mount Lebanon': {
        'Baabda': [
          'Baabda Main Street',
          'Hazmieh',
          'Chouf',
          'Aley',
          'Bhamdoun',
          'Deir el Qamar',
          'Beit ed-Dine',
          'Barouk',
          'Ain Zhalta',
          'Bmariam',
          'Kfarmatta',
          'Kfarnabrakh'
        ],
        'Jounieh': [
          'Jounieh Bay',
          'Maameltein',
          'Harissa',
          'Zouk Mikael',
          'Dbayeh',
          'Zouk Mosbeh',
          'Nahr el-Kalb',
          'Tabarja',
          'Faitroun',
          'Ghazir',
          'Bikfaya',
          'Bhamdoun el-Mhatta'
        ]
      },
      'North Lebanon': {
        'Tripoli': [
          'Tripoli Port',
          'Al Mina',
          'El Tall',
          'Abu Samra',
          'Qalamoun',
          'Al Qobbeh',
          'Al Zahriyah',
          'Al Mankoubin',
          'Al Ghorba',
          'Al Haddadin',
          'Al Qalamoun',
          'Al Mina Port'
        ],
        'Zgharta': [
          'Zgharta Center',
          'Ehden',
          'Bsharri',
          'Koura',
          'Amioun',
          'Kfarhazir',
          'Kfarhata',
          'Kfarzina',
          'Kfarhbab',
          'Kfarhata',
          'Kfarhazir',
          'Kfarhbab'
        ]
      },
      'South Lebanon': {
        'Sidon': [
          'Sidon Port',
          'Old City',
          'Sidon Castle',
          'Ain al-Hilweh',
          'Mieh Mieh',
          'Abu al-Aswad',
          'Al Ghaziyah',
          'Al Kafr',
          'Al Kafr al-Jawzi',
          'Al Kafr al-Miski',
          'Al Kafr al-Sawda',
          'Al Kafr al-Zayt'
        ],
        'Tyre': [
          'Tyre Port',
          'Al Mina',
          'Rashidieh',
          'Qana',
          'Al Qulaylah',
          'Al Jibbayn',
          'Al Mansouri',
          'Al Qulaylah',
          'Al Jibbayn',
          'Al Mansouri',
          'Al Qulaylah',
          'Al Jibbayn'
        ]
      },
      'Bekaa': {
        'Zahle': [
          'Zahle Center',
          'Chtaura',
          'Anjar',
          'Baalbek',
          'Hermel',
          'Nabatieh',
          'Jezzine',
          'Marjayoun',
          'Hasbaya',
          'Rashaya',
          'Western Bekaa',
          'Rachaya'
        ],
        'Baalbek': [
          'Baalbek Temples',
          'Baalbek Center',
          'Hermel',
          'Nabatieh',
          'Jezzine',
          'Marjayoun',
          'Hasbaya',
          'Rashaya',
          'Western Bekaa',
          'Rachaya',
          'Baalbek Temples',
          'Baalbek Center'
        ]
      }
    },
    'United Arab Emirates': {
      'Dubai': {
        'Dubai': [
          'Sheikh Zayed Road',
          'Jumeirah Beach Road',
          'Al Wasl Road',
          'Al Khaleej Street',
          'Al Maktoum Street',
          'Al Dhiyafah Street',
          'Al Wasl Street',
          'Al Thanya Street',
          'Al Qudra Road',
          'Emirates Road',
          'Al Meydan Road',
          'Al Khail Road',
          'Al Asayel Street',
          'Al Hadiqa Street',
          'Al Safa Street',
          'Al Manara Street',
          'Al Wasl Street',
          'Al Thanya Street',
          'Al Qudra Road',
          'Emirates Road'
        ],
        'Jumeirah': [
          'Jumeirah Beach Road',
          'Jumeirah Road',
          'Al Wasl Road',
          'Al Thanya Street',
          'Al Qudra Road',
          'Al Safa Street',
          'Al Manara Street',
          'Al Wasl Street',
          'Al Thanya Street',
          'Al Qudra Road',
          'Jumeirah Beach Road',
          'Jumeirah Road'
        ],
        'Palm Jumeirah': [
          'Palm Jumeirah Road',
          'Palm Tower Road',
          'Atlantis Road',
          'Palm West Beach',
          'Palm East Beach',
          'Palm Central',
          'Palm Gateway',
          'Palm Crescent',
          'Palm Trunk',
          'Palm Fronds',
          'Palm Shoreline',
          'Palm Marina'
        ]
      },
      'Abu Dhabi': {
        'Abu Dhabi': [
          'Corniche Road',
          'Sheikh Zayed Street',
          'Al Salam Street',
          'Al Falah Street',
          'Al Najda Street',
          'Al Markaziyah',
          'Al Zahiyah',
          'Al Bateen',
          'Al Mushrif',
          'Al Karamah',
          'Al Ras Al Akhdar',
          'Al Qurm',
          'Al Khalidiyah',
          'Al Bateen',
          'Al Mushrif',
          'Al Karamah',
          'Al Ras Al Akhdar',
          'Al Qurm',
          'Al Khalidiyah',
          'Al Bateen'
        ],
        'Al Ain': [
          'Al Ain Road',
          'Al Jimi',
          'Al Qattara',
          'Al Hili',
          'Al Buraimi',
          'Al Muwaiji',
          'Al Jahili',
          'Al Qattara',
          'Al Hili',
          'Al Buraimi',
          'Al Muwaiji',
          'Al Jahili'
        ]
      },
      'Sharjah': {
        'Sharjah': [
          'Al Wahda Street',
          'King Faisal Street',
          'Al Ittihad Street',
          'Al Arouba Street',
          'Al Khan Street',
          'Al Majaz',
          'Al Qasba',
          'Al Nahda',
          'Al Taawun',
          'Al Rolla',
          'Al Qasba',
          'Al Nahda',
          'Al Taawun',
          'Al Rolla',
          'Al Majaz',
          'Al Khan',
          'Al Arouba',
          'Al Ittihad',
          'King Faisal',
          'Al Wahda'
        ]
      },
      'Ajman': {
        'Ajman': [
          'Sheikh Humaid Street',
          'Al Nuaimiya',
          'Al Rashidiya',
          'Al Mowaihat',
          'Al Zahra',
          'Al Rawda',
          'Al Hamriya',
          'Al Bustan',
          'Al Jerf',
          'Al Muntazah',
          'Al Nuaimiya',
          'Al Rashidiya'
        ]
      }
    },
    'Saudi Arabia': {
      'Riyadh': {
        'Riyadh': [
          'King Fahd Road',
          'King Abdullah Road',
          'King Salman Road',
          'Olaya Street',
          'Tahlia Street',
          'King Khalid Road',
          'King Abdulaziz Road',
          'King Faisal Road',
          'King Saud Road',
          'King Khalid International Airport Road',
          'King Fahd Medical City Road',
          'King Abdulaziz Medical City Road',
          'King Faisal Medical City Road',
          'King Saud Medical City Road',
          'King Khalid Medical City Road',
          'King Fahd Medical City Road',
          'King Abdulaziz Medical City Road',
          'King Faisal Medical City Road',
          'King Saud Medical City Road',
          'King Khalid Medical City Road'
        ],
        'Diriyah': [
          'King Salman Road',
          'Al Diriyah Road',
          'Al Bujairi',
          'Al Turaif',
          'Al Samhan',
          'Al Diriyah Gate',
          'Al Diriyah Museum',
          'Al Diriyah Heritage',
          'Al Diriyah Cultural',
          'Al Diriyah Historical',
          'Al Diriyah Traditional',
          'Al Diriyah Modern'
        ]
      },
      'Jeddah': {
        'Jeddah': [
          'King Abdulaziz Road',
          'King Fahd Road',
          'King Abdullah Road',
          'Corniche Road',
          'Al Hamra Street',
          'Al Balad',
          'Al Hamra',
          'Al Zahra',
          'Al Salamah',
          'Al Rawdah',
          'Al Andalus',
          'Al Malaz',
          'Al Sahafah',
          'Al Naeem',
          'Al Rehab',
          'Al Faisaliyah',
          'Al Shati',
          'Al Corniche',
          'Al Hamra',
          'Al Zahra'
        ]
      },
      'Mecca': {
        'Mecca': [
          'King Abdulaziz Road',
          'King Fahd Road',
          'Al Haram Street',
          'Al Aziziyah',
          'Al Misfalah',
          'Al Shubaikah',
          'Al Taneem',
          'Al Adl',
          'Al Shafaa',
          'Al Marwa',
          'Al Haram',
          'Al Aziziyah',
          'Al Misfalah',
          'Al Shubaikah',
          'Al Taneem',
          'Al Adl',
          'Al Shafaa',
          'Al Marwa',
          'Al Haram',
          'Al Aziziyah'
        ]
      },
      'Medina': {
        'Medina': [
          'King Fahd Road',
          'King Abdullah Road',
          'Al Haram Street',
          'Al Anbariyah',
          'Al Awali',
          'Al Qiblatain',
          'Al Quba',
          'Al Uhud',
          'Al Quba',
          'Al Uhud',
          'Al Anbariyah',
          'Al Awali',
          'Al Qiblatain',
          'Al Quba',
          'Al Uhud',
          'Al Anbariyah',
          'Al Awali',
          'Al Qiblatain',
          'Al Quba',
          'Al Uhud'
        ]
      }
    },
    'United States': {
      'California': {
        'Los Angeles': [
          'Hollywood Boulevard',
          'Sunset Boulevard',
          'Wilshire Boulevard',
          'Santa Monica Boulevard',
          'Ventura Boulevard',
          'Melrose Avenue',
          'Beverly Hills',
          'Venice Beach',
          'Santa Monica',
          'Pasadena',
          'Downtown LA',
          'Echo Park',
          'Silver Lake',
          'Los Feliz',
          'Atwater Village',
          'Glendale',
          'Burbank',
          'Culver City',
          'Marina del Rey',
          'Manhattan Beach'
        ],
        'San Francisco': [
          'Market Street',
          'Mission Street',
          'Geary Boulevard',
          'Van Ness Avenue',
          'Lombard Street',
          'Fisherman\'s Wharf',
          'Alcatraz',
          'Golden Gate Bridge',
          'Chinatown',
          'North Beach',
          'Marina District',
          'Pacific Heights',
          'Nob Hill',
          'Russian Hill',
          'Telegraph Hill',
          'Financial District',
          'SOMA',
          'Hayes Valley',
          'Castro District',
          'Mission District'
        ],
        'San Diego': [
          'Gaslamp Quarter',
          'Seaport Village',
          'Balboa Park',
          'La Jolla',
          'Coronado',
          'Mission Beach',
          'Pacific Beach',
          'Ocean Beach',
          'Point Loma',
          'Old Town',
          'Downtown San Diego',
          'Little Italy',
          'East Village',
          'North Park',
          'South Park',
          'Hillcrest',
          'University Heights',
          'Normal Heights',
          'Kensington',
          'Talmadge'
        ]
      },
      'New York': {
        'New York City': [
          'Broadway',
          'Fifth Avenue',
          'Park Avenue',
          'Madison Avenue',
          'Lexington Avenue',
          'Times Square',
          'Central Park',
          'Brooklyn Bridge',
          'Wall Street',
          'Harlem',
          'Upper East Side',
          'Upper West Side',
          'Midtown Manhattan',
          'Lower Manhattan',
          'Chelsea',
          'Greenwich Village',
          'SoHo',
          'Tribeca',
          'Financial District',
          'Battery Park'
        ],
        'Buffalo': [
          'Main Street',
          'Elmwood Avenue',
          'Delaware Avenue',
          'Chippewa Street',
          'Allen Street',
          'Allentown',
          'Elmwood Village',
          'North Buffalo',
          'South Buffalo',
          'West Side',
          'East Side',
          'Black Rock',
          'Riverside',
          'University Heights',
          'Kensington',
          'Lovejoy',
          'Fillmore',
          'Grant',
          'Bailey',
          'Seneca'
        ]
      },
      'Texas': {
        'Houston': [
          'Main Street',
          'Westheimer Road',
          'Kirby Drive',
          'Richmond Avenue',
          'Washington Avenue',
          'Montrose',
          'Rice Village',
          'Galleria',
          'Museum District',
          'Heights',
          'Midtown',
          'Downtown Houston',
          'Medical Center',
          'River Oaks',
          'Memorial',
          'Spring Branch',
          'Katy',
          'Sugar Land',
          'The Woodlands',
          'Cypress'
        ],
        'Austin': [
          'Congress Avenue',
          'Sixth Street',
          'Lamar Boulevard',
          'Guadalupe Street',
          'Burnet Road',
          'Downtown Austin',
          'East Austin',
          'West Austin',
          'South Austin',
          'North Austin',
          'Zilker',
          'Barton Springs',
          'Travis Heights',
          'Hyde Park',
          'Clarksville',
          'Tarrytown',
          'Westlake',
          'Lake Travis',
          'Round Rock',
          'Cedar Park'
        ],
        'Dallas': [
          'Main Street',
          'Oak Lawn Avenue',
          'Greenville Avenue',
          'McKinney Avenue',
          'Deep Ellum',
          'Uptown',
          'Downtown Dallas',
          'Bishop Arts District',
          'Trinity Groves',
          'Design District',
          'Victory Park',
          'Arts District',
          'West End',
          'Cedar Springs',
          'Knox-Henderson',
          'Lower Greenville',
          'Lakewood',
          'M Streets',
          'Preston Hollow',
          'Highland Park'
        ]
      },
      'Florida': {
        'Miami': [
          'Ocean Drive',
          'Collins Avenue',
          'Washington Avenue',
          'Lincoln Road',
          'South Beach',
          'North Beach',
          'Mid-Beach',
          'Downtown Miami',
          'Brickell',
          'Coconut Grove',
          'Coral Gables',
          'Key Biscayne',
          'Miami Beach',
          'Wynwood',
          'Design District',
          'Little Havana',
          'Calle Ocho',
          'Bayside',
          'Bayfront Park',
          'Vizcaya'
        ],
        'Orlando': [
          'International Drive',
          'Orange Blossom Trail',
          'Colonial Drive',
          'Mills Avenue',
          'Downtown Orlando',
          'Winter Park',
          'Thornton Park',
          'College Park',
          'Audubon Park',
          'Baldwin Park',
          'Lake Nona',
          'Dr. Phillips',
          'Windermere',
          'Celebration',
          'Kissimmee',
          'Lake Buena Vista',
          'Universal Studios',
          'Disney World',
          'SeaWorld',
          'Legoland'
        ]
      }
    },
    'United Kingdom': {
      'England': {
        'London': [
          'Oxford Street',
          'Regent Street',
          'Bond Street',
          'Piccadilly',
          'Carnaby Street',
          'Covent Garden',
          'Soho',
          'Mayfair',
          'Chelsea',
          'Camden',
          'Notting Hill',
          'Kensington',
          'Knightsbridge',
          'Belgravia',
          'Marylebone',
          'Fitzrovia',
          'Bloomsbury',
          'Holborn',
          'Clerkenwell',
          'Shoreditch'
        ],
        'Manchester': [
          'Market Street',
          'Deansgate',
          'Oxford Road',
          'Wilmslow Road',
          'Rusholme',
          'Northern Quarter',
          'Spinningfields',
          'Castlefield',
          'Ancoats',
          'Didsbury',
          'Chorlton',
          'Withington',
          'Fallowfield',
          'Hulme',
          'Moss Side',
          'Longsight',
          'Levenshulme',
          'Burnage',
          'Withington',
          'Didsbury'
        ],
        'Birmingham': [
          'New Street',
          'High Street',
          'Corporation Street',
          'Bull Street',
          'Colmore Row',
          'Digbeth',
          'Jewellery Quarter',
          'Gun Quarter',
          'Chinese Quarter',
          'Irish Quarter',
          'Gay Village',
          'Custard Factory',
          'Mailbox',
          'Brindleyplace',
          'Broad Street',
          'Hurst Street',
          'Moseley',
          'Kings Heath',
          'Selly Oak',
          'Edgbaston'
        ]
      },
      'Scotland': {
        'Edinburgh': [
          'Royal Mile',
          'Princes Street',
          'George Street',
          'Rose Street',
          'Grassmarket',
          'Old Town',
          'New Town',
          'Leith',
          'Stockbridge',
          'Morningside',
          'Bruntsfield',
          'Marchmont',
          'Tollcross',
          'Haymarket',
          'West End',
          'East End',
          'Portobello',
          'Musselburgh',
          'Dalkeith',
          'Penicuik'
        ],
        'Glasgow': [
          'Buchanan Street',
          'Sauchiehall Street',
          'Argyle Street',
          'Byres Road',
          'Great Western Road',
          'Merchant City',
          'West End',
          'East End',
          'South Side',
          'North Glasgow',
          'Finnieston',
          'Partick',
          'Hillhead',
          'Kelvingrove',
          'Garnethill',
          'Charing Cross',
          'Cowcaddens',
          'Townhead',
          'Calton',
          'Bridgeton'
        ]
      },
      'Wales': {
        'Cardiff': [
          'Queen Street',
          'St. Mary Street',
          'High Street',
          'Castle Street',
          'Church Street',
          'Cathays',
          'Roath',
          'Canton',
          'Grangetown',
          'Butetown',
          'Adamsdown',
          'Splott',
          'Tremorfa',
          'Rumney',
          'Llanrumney',
          'Llanedeyrn',
          'Pentwyn',
          'Llanishen',
          'Thornhill',
          'Lisvane'
        ]
      }
    },
    'Canada': {
      'Ontario': {
        'Toronto': [
          'Yonge Street',
          'Queen Street',
          'King Street',
          'Bloor Street',
          'Dundas Street',
          'College Street',
          'Spadina Avenue',
          'Bathurst Street',
          'Ossington Avenue',
          'Dufferin Street',
          'Queen West',
          'King West',
          'Entertainment District',
          'Financial District',
          'Distillery District',
          'Kensington Market',
          'Chinatown',
          'Little Italy',
          'Greektown',
          'Little India'
        ],
        'Ottawa': [
          'Wellington Street',
          'Sparks Street',
          'Bank Street',
          'Elgin Street',
          'Rideau Street',
          'Sussex Drive',
          'ByWard Market',
          'Centretown',
          'Westboro',
          'Hintonburg',
          'Glebe',
          'Sandy Hill',
          'Rockcliffe Park',
          'New Edinburgh',
          'Vanier',
          'Overbrook',
          'Alta Vista',
          'Billings Bridge',
          'Heron Park',
          'Riverside South'
        ]
      },
      'Quebec': {
        'Montreal': [
          'Saint Catherine Street',
          'Saint Denis Street',
          'Saint Laurent Boulevard',
          'Sherbrooke Street',
          'Mount Royal Avenue',
          'Parc Avenue',
          'Crescent Street',
          'Peel Street',
          'McGill Street',
          'University Street',
          'Old Montreal',
          'Plateau Mont-Royal',
          'Mile End',
          'Outremont',
          'Westmount',
          'NDG',
          'Verdun',
          'Lachine',
          'LaSalle',
          'Ahuntsic'
        ]
      },
      'British Columbia': {
        'Vancouver': [
          'Robson Street',
          'Granville Street',
          'West Georgia Street',
          'Hastings Street',
          'Commercial Drive',
          'Main Street',
          'Cambie Street',
          'Oak Street',
          'Arbutus Street',
          'West Broadway',
          'Gastown',
          'Yaletown',
          'Chinatown',
          'West End',
          'Kitsilano',
          'Mount Pleasant',
          'Strathcona',
          'Commercial-Broadway',
          'Metrotown',
          'Richmond'
        ]
      }
    },
    'Australia': {
      'New South Wales': {
        'Sydney': [
          'George Street',
          'Pitt Street',
          'Castlereagh Street',
          'Macquarie Street',
          'Circular Quay',
          'The Rocks',
          'Darling Harbour',
          'Bondi Beach',
          'Manly Beach',
          'Coogee Beach',
          'Surry Hills',
          'Paddington',
          'Glebe',
          'Newtown',
          'Balmain',
          'Rozelle',
          'Leichhardt',
          'Marrickville',
          'Redfern',
          'Waterloo'
        ]
      },
      'Victoria': {
        'Melbourne': [
          'Collins Street',
          'Bourke Street',
          'Flinders Street',
          'Swanston Street',
          'Elizabeth Street',
          'Chapel Street',
          'Brunswick Street',
          'Smith Street',
          'Lygon Street',
          'Acland Street',
          'Fitzroy',
          'Carlton',
          'Northcote',
          'Thornbury',
          'Preston',
          'Brunswick',
          'Coburg',
          'Footscray',
          'Yarraville',
          'Williamstown'
        ]
      },
      'Queensland': {
        'Brisbane': [
          'Queen Street',
          'Adelaide Street',
          'Edward Street',
          'George Street',
          'Albert Street',
          'Wickham Street',
          'Fortitude Valley',
          'West End',
          'South Bank',
          'Kangaroo Point',
          'New Farm',
          'Teneriffe',
          'Bulimba',
          'Hawthorne',
          'East Brisbane',
          'Woolloongabba',
          'Highgate Hill',
          'Dutton Park',
          'Fairfield',
          'Annerley'
        ]
      }
    },
    'Germany': {
      'Berlin': {
        'Berlin': [
          'Unter den Linden',
          'Friedrichstraße',
          'Kurfürstendamm',
          'Potsdamer Straße',
          'Leipziger Straße',
          'Alexanderplatz',
          'Brandenburger Tor',
          'Checkpoint Charlie',
          'Mitte',
          'Kreuzberg',
          'Friedrichshain',
          'Prenzlauer Berg',
          'Neukölln',
          'Schöneberg',
          'Charlottenburg',
          'Wilmersdorf',
          'Steglitz',
          'Zehlendorf',
          'Spandau',
          'Reinickendorf'
        ]
      },
      'Bavaria': {
        'Munich': [
          'Maximilianstraße',
          'Kaufingerstraße',
          'Neuhauser Straße',
          'Marienplatz',
          'Odeonsplatz',
          'Karlsplatz',
          'Sendlinger Straße',
          'Theatinerstraße',
          'Residenzstraße',
          'Bayerstraße',
          'Altstadt',
          'Maxvorstadt',
          'Schwabing',
          'Haidhausen',
          'Au-Haidhausen',
          'Ludwigsvorstadt',
          'Isarvorstadt',
          'Sendling',
          'Thalkirchen',
          'Obergiesing'
        ]
      }
    },
    'France': {
      'Île-de-France': {
        'Paris': [
          'Champs-Élysées',
          'Avenue des Champs-Élysées',
          'Rue de Rivoli',
          'Boulevard Saint-Germain',
          'Rue Saint-Honoré',
          'Avenue Montaigne',
          'Rue du Faubourg Saint-Honoré',
          'Place de la Concorde',
          'Place Vendôme',
          'Place de l\'Opéra',
          'Le Marais',
          'Saint-Germain-des-Prés',
          'Montmartre',
          'Pigalle',
          'Bastille',
          'Canal Saint-Martin',
          'Belleville',
          'Ménilmontant',
          'Buttes-Chaumont',
          'Parc des Buttes-Chaumont'
        ]
      },
      'Provence-Alpes-Côte d\'Azur': {
        'Marseille': [
          'La Canebière',
          'Rue de la République',
          'Rue d\'Antibes',
          'Promenade des Anglais',
          'Vieux Port',
          'Le Panier',
          'La Joliette',
          'Endoume',
          'Vallon des Auffes',
          'Cours Julien',
          'La Plaine',
          'Noailles',
          'Belsunce',
          'Saint-Charles',
          'La Blancarde',
          'La Timone',
          'La Valentine',
          'Les Trois-Lucs',
          'La Rose',
          'Les Aygalades'
        ]
      }
    },
    'Japan': {
      'Tokyo': {
        'Tokyo': [
          'Ginza',
          'Shibuya Crossing',
          'Harajuku',
          'Akihabara',
          'Shinjuku',
          'Shibuya',
          'Roppongi',
          'Omotesando',
          'Aoyama',
          'Ebisu',
          'Daikanyama',
          'Nakameguro',
          'Jiyugaoka',
          'Kichijoji',
          'Shimokitazawa',
          'Koenji',
          'Nakano',
          'Ikebukuro',
          'Ueno',
          'Asakusa'
        ]
      },
      'Osaka': {
        'Osaka': [
          'Dotonbori',
          'Shinsaibashi',
          'Namba',
          'Umeda',
          'Tennoji',
          'Nipponbashi',
          'Amerikamura',
          'Horie',
          'Nishi-Shinsaibashi',
          'Minami',
          'Kita',
          'Chuo',
          'Naniwa',
          'Tennoji',
          'Abeno',
          'Ikuno',
          'Higashisumiyoshi',
          'Nishinari',
          'Taisho',
          'Konohana'
        ]
      }
    },
    'South Korea': {
      'Seoul': {
        'Seoul': [
          'Gangnam',
          'Myeongdong',
          'Hongdae',
          'Itaewon',
          'Insadong',
          'Dongdaemun',
          'Namdaemun',
          'Gwanghwamun',
          'Yeouido',
          'Jamsil',
          'Songpa',
          'Gangdong',
          'Gangseo',
          'Yangcheon',
          'Guro',
          'Geumcheon',
          'Yeongdeungpo',
          'Gangnam',
          'Seocho',
          'Mapo'
        ]
      }
    }
  };

  // Get all countries
  static List<String> getCountries() {
    return _locationData.keys.toList()..sort();
  }

  // Get districts for a specific country
  static List<String> getDistricts(String country) {
    final countryData = _locationData[country];
    if (countryData == null) return [];
    return countryData.keys.toList()..sort();
  }

  // Get cities for a specific country and district
  static List<String> getCities(String country, String district) {
    final countryData = _locationData[country];
    if (countryData == null) return [];
    
    final districtData = countryData[district];
    if (districtData == null) return [];
    
    return districtData.keys.toList()..sort();
  }

  // Get streets for a specific country, district, and city
  static List<String> getStreets(String country, String district, String city) {
    final countryData = _locationData[country];
    if (countryData == null) return [];
    
    final districtData = countryData[district];
    if (districtData == null) return [];
    
    final cityData = districtData[city];
    if (cityData == null) return [];
    
    return cityData..sort();
  }

  // Validate if a location combination exists
  static bool isValidLocation(String country, String district, String city, String street) {
    final streets = getStreets(country, district, city);
    return streets.contains(street);
  }
} 