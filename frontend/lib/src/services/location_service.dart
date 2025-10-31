class LocationService {
  // Sample location data - in a real app, this would come from an API
  static final Map<String, Map<String, Map<String, List<String>>>> _locationData = {
    'Lebanon': {
      'Akkar': {
        'Akkar': [
          'Halba',
          'Kobayat',
          'Rahbeh'
        ]
      },
      'Baalbek-Hermel': {
        'Baalbek': [
          'Baalbek',
          'Deir el Ahmar',
          'Bodai',
          'Hallanieh',
          'Temnin el Fawka',
          'Chmestar',
          'Kasarnaba',
          'Duris',
          'Arsal',
          'Haouch Er Rafqa',
          'Hadath Baalbek',
          'Yunin',
          'Bouday',
          'Yammouné',
          'Ali El Nahri',
          'Jdeide',
          'Ksarnaba'
        ],
        'Hermel': [
          'Al Hermel',
          'Al Qasr',
          'Al Shawagir Al Fawqa wa Al Thta',
          'Al Kawakh',
          'Fissan',
          'Jawar Al Hashish'
        ]
      },
      'Beirut': {
        'Beirut': [
          'Beirut'
        ]
      },
      'Beqaa': {
        'Rashaya': [
          'Rashaya',
          'Ain Ata',
          'Yanta'
        ],
        'Western Beqaa': [
          'Joub Jannine',
          'Kefraya',
          'Machghara'
        ],
        'Zahlé': [
          'Zahlé',
          'Chtaura',
          'Majdel Anjar',
          'Talabaya',
          'Saadnay\'el',
          'Hazerta',
          'Ferzol',
          'Abilh'
        ]
      },
      'Keserwan-Jbeil': {
        'Byblos': [
          'Byblos',
          'Amshit',
          'Halat',
          'Nahr Ibrahim',
          'Lassa',
          'Al Aqoura'
        ],
        'Keserwan': [
          'Jounieh',
          'Zouk Mikael',
          'Ajaltoun',
          'Blouneh',
          'Zouk Mosbeh',
          'Safra',
          'Tabarja'
        ]
      },
      'Mount Lebanon': {
        'Aley': [
          'Aley',
          'Bhamdoun',
          'Souk el Ghareb',
          'Baysour',
          'Kaifun',
          'Chanehye',
          'Sofar',
          'Majdlaya'
        ],
        'Baabda': [
          'Baabda',
          'Chiyah',
          'Ghobeiry'
        ],
        'Chouf': [
          'Beiteddine',
          'Deir el Qamar',
          'Baakline',
          'Maasser El Chouf',
          'Al Mukhtara',
          'Btouma',
          'Jiyeh'
        ],
        'Matn': [
          'Jdeideh',
          'Dekwaneh',
          'Bikfaya',
          'Fanar',
          'Rabieh',
          'Beit Chabab'
        ]
      },
      'Nabatieh': {
        'Bint Jbeil': [
          'Bint Jbeil',
          'Aita Al Jabal',
          'Tebnine',
          'Kafr Dounin',
          'Yater'
        ],
        'Hasbaya': [
          'Hasbaya',
          'Kfarchouba',
          'Shebaa'
        ],
        'Marjeyoun': [
          'Marjeyoun',
          'Khiam',
          'Mimas'
        ],
        'Nabatieh': [
          'Nabatieh',
          'Houmine Al-Fawqa',
          'Houmine Al-Tahta',
          'Jbaa'
        ]
      },
      'North': {
        'Batroun': [
          'Batroun',
          'Douma',
          'Hamat',
          'Zan',
          'Bqosta',
          'Deir Bela',
          'Salata'
        ],
        'Bsharri': [
          'Bsharri',
          'Tourza',
          'Hasroun',
          'Qannat',
          'Bir Al Ayoan',
          'Hassroun',
          'Beqaa Kafra',
          'Abdeen',
          'Bazoun',
          'Bkrkasha'
        ],
        'Koura': [
          'Amioun',
          'Anfeh',
          'Kaftoun',
          'Fiyeh',
          'Dar Chmizzine',
          'Btouratije'
        ],
        'Miniyeh-Danniyeh': [
          'Miniyeh',
          'Bakhoun',
          'Seer'
        ],
        'Tripoli': [
          'Tripoli',
          'Al Mina',
          'Al Badawi',
          'Al Qalamoun'
        ],
        'Zgharta': [
          'Zgharta',
          'Ehden',
          'Majdalia',
          'Rachiine',
          'Kfarhata',
          'Ayal'
        ]
      },
      'South': {
        'Sidon': [
          'Sidon',
          'Anqoun',
          'Maghdouché'
        ],
        'Jezzine': [
          'Jezzine',
          'Bkassine',
          'Roum'
        ],
        'Tyre': [
          'Tyre',
          'Ain Baal',
          'Jwaya'
        ]
      }
    },
    'Syria': {
      'Damascus': {
        'Damascus': [
          'Old City',
          'Umayyad Mosque',
          'Straight Street',
          'Souk al-Hamidiyah',
          'Azem Palace',
          'National Museum',
          'Damascus Citadel',
          'Saladin Tomb',
          'Ananias Chapel',
          'St. Paul Chapel',
          'Damascus University',
          'Tishreen Park',
          'Abu Rummaneh',
          'Malki',
          'Mazzeh',
          'Kafr Sousa',
          'Dummar',
          'Barzeh',
          'Qaboun',
          'Jobar'
        ]
      },
      'Aleppo': {
        'Aleppo': [
          'Aleppo Citadel',
          'Old City',
          'Souk al-Madina',
          'Great Mosque',
          'Khan al-Wazir',
          'Khan al-Saboun',
          'Aleppo University',
          'Aziziyeh Square',
          'Saadallah al-Jabiri Square',
          'Al-Hamidiyah Souk',
          'Al-Madina Souk',
          'Al-Zirb Market',
          'Al-Attarine Souk',
          'Al-Saqatiyya Souk',
          'Al-Herafiyyin Souk',
          'Al-Saboun Souk',
          'Al-Nahhasin Souk',
          'Al-Dabbagha Souk',
          'Al-Sagha Souk',
          'Al-Khandaq Souk'
        ]
      },
      'Homs': {
        'Homs': [
          'Homs Center',
          'Khalid ibn al-Walid Mosque',
          'Old City',
          'Homs Citadel',
          'Al-Zahra Square',
          'Al-Hamidiya Market',
          'Al-Souk al-Kabir',
          'Al-Souk al-Saghir',
          'Al-Khandaq Street',
          'Al-Qusour',
          'Al-Waer',
          'Al-Baath University',
          'Homs University',
          'Al-Ghouta',
          'Al-Rastan',
          'Al-Qusayr',
          'Al-Mukharram',
          'Al-Qaryatayn',
          'Al-Salamiyah',
          'Al-Mahin'
        ]
      },
      'Latakia': {
        'Latakia': [
          'Latakia Port',
          'Corniche',
          'Latakia University',
          'Al-Salam Square',
          'Al-Mina',
          'Al-Raml al-Janoubi',
          'Al-Raml al-Shamali',
          'Al-Aziziyah',
          'Al-Shaab',
          'Al-Quds',
          'Al-Nuzha',
          'Al-Mahatta',
          'Al-Sinaa',
          'Al-Hamra',
          'Al-Saboun',
          'Al-Kindi',
          'Al-Maamoun',
          'Al-Rashideen',
          'Al-Salam',
          'Al-Nour'
        ]
      }
    },
    'Jordan': {
      'Amman': {
        'Amman': [
          'Downtown Amman',
          'Citadel Hill',
          'Roman Theater',
          'King Abdullah Mosque',
          'King Hussein Mosque',
          'Amman Citadel',
          'Temple of Hercules',
          'Ummayad Palace',
          'Archaeological Museum',
          'Rainbow Street',
          'Abdoun',
          'Jabal Amman',
          'Jabal Luweibdeh',
          'Jabal al-Ashrafieh',
          'Jabal al-Hussein',
          'Jabal al-Nasr',
          'Jabal al-Taj',
          'Jabal al-Qalaa',
          'Jabal al-Weibdeh',
          'Jabal al-Ahliyah'
        ]
      },
      'Irbid': {
        'Irbid': [
          'Irbid Center',
          'Yarmouk University',
          'Irbid Castle',
          'Al-Hussein Bin Talal University',
          'Irbid Museum',
          'Al-Mazar al-Janoubi',
          'Al-Mazar al-Shamali',
          'Al-Kourah',
          'Al-Taybeh',
          'Al-Ramtha',
          'Al-Hashmiyah',
          'Al-Sareeh',
          'Al-Mashariq',
          'Al-Mafraq',
          'Al-Zarqa',
          'Al-Balqa',
          'Al-Karak',
          'Al-Tafilah',
          'Al-Aqaba',
          'Al-Ma\'an'
        ]
      },
      'Zarqa': {
        'Zarqa': [
          'Zarqa Center',
          'Zarqa University',
          'Al-Hashmiyah',
          'Al-Sukhna',
          'Al-Azraq',
          'Al-Ruwaished',
          'Al-Mafraq',
          'Al-Zarqa Industrial City',
          'Al-Hashmiyah Industrial City',
          'Al-Sukhna Industrial City',
          'Al-Azraq Industrial City',
          'Al-Ruwaished Industrial City',
          'Al-Mafraq Industrial City',
          'Al-Zarqa Free Zone',
          'Al-Hashmiyah Free Zone',
          'Al-Sukhna Free Zone',
          'Al-Azraq Free Zone',
          'Al-Ruwaished Free Zone',
          'Al-Mafraq Free Zone',
          'Al-Zarqa Port'
        ]
      }
    },
    'Egypt': {
      'Cairo': {
        'Cairo': [
          'Tahrir Square',
          'Egyptian Museum',
          'Khan el-Khalili',
          'Al-Azhar Mosque',
          'Sultan Hassan Mosque',
          'Al-Rifai Mosque',
          'Cairo Citadel',
          'Mohamed Ali Mosque',
          'Coptic Cairo',
          'Hanging Church',
          'St. George Church',
          'Ben Ezra Synagogue',
          'Islamic Cairo',
          'Al-Muizz Street',
          'Al-Darb al-Ahmar',
          'Al-Gamaliya',
          'Al-Darb al-Asfar',
          'Al-Sayeda Zeinab',
          'Al-Sayeda Aisha',
          'Al-Hussein'
        ]
      },
      'Alexandria': {
        'Alexandria': [
          'Corniche',
          'Qaitbay Citadel',
          'Bibliotheca Alexandrina',
          'Pompey\'s Pillar',
          'Catacombs of Kom el Shoqafa',
          'Montaza Palace',
          'Stanley Bridge',
          'Al-Montazah',
          'Al-Maamoura',
          'Al-Shatby',
          'Al-Gleem',
          'Al-Smouha',
          'Al-Raml',
          'Al-Attarin',
          'Al-Mansheya',
          'Al-Gomrok',
          'Al-Laban',
          'Al-Max',
          'Al-Agamy',
          'Al-Dekheila'
        ]
      },
      'Giza': {
        'Giza': [
          'Giza Pyramids',
          'Great Sphinx',
          'Pyramid of Khufu',
          'Pyramid of Khafre',
          'Pyramid of Menkaure',
          'Solar Boat Museum',
          'Giza Plateau',
          'Nile Valley',
          'Giza Zoo',
          'Orman Garden',
          'Giza Corniche',
          'Al-Haram',
          'Al-Dokki',
          'Al-Mohandessin',
          'Al-Agouza',
          'Al-Imbaba',
          'Al-Warraq',
          'Al-Kitkat',
          'Al-Boulaq',
          'Al-Zamalek'
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
    'Turkey': {
      'Istanbul': {
        'Istanbul': [
          'Sultanahmet',
          'Taksim Square',
          'Galata Tower',
          'Hagia Sophia',
          'Blue Mosque',
          'Topkapi Palace',
          'Grand Bazaar',
          'Spice Bazaar',
          'Bosphorus Bridge',
          'Ortakoy',
          'Beyoglu',
          'Kadikoy',
          'Uskudar',
          'Besiktas',
          'Sisli',
          'Levent',
          'Maslak',
          'Etiler',
          'Ulus',
          'Bebek'
        ]
      },
      'Ankara': {
        'Ankara': [
          'Kizilay',
          'Ulus',
          'Cankaya',
          'Kocatepe Mosque',
          'Anitkabir',
          'Atakule',
          'Ankara Castle',
          'Museum of Anatolian Civilizations',
          'Genclik Park',
          'Tunali Hilmi',
          'Bahcelievler',
          'Kizilcahamam',
          'Beypazari',
          'Polatli',
          'Sincan',
          'Etimesgut',
          'Mamak',
          'Kecioren',
          'Yenimahalle',
          'Pursaklar'
        ]
      },
      'Izmir': {
        'Izmir': [
          'Konak',
          'Alsancak',
          'Karsiyaka',
          'Bornova',
          'Buca',
          'Gaziemir',
          'Balcova',
          'Narlidere',
          'Guzelbahce',
          'Menderes',
          'Torbali',
          'Menemen',
          'Aliağa',
          'Foça',
          'Cesme',
          'Kusadasi',
          'Selcuk',
          'Tire',
          'Bayindir',
          'Kemalpasa'
        ]
      }
    },
    'France': {
      'Paris': {
        'Paris': [
          'Champs-Élysées',
          'Eiffel Tower',
          'Louvre Museum',
          'Notre-Dame',
          'Arc de Triomphe',
          'Montmartre',
          'Sacré-Cœur',
          'Place de la Concorde',
          'Tuileries Garden',
          'Luxembourg Garden',
          'Marais',
          'Le Marais',
          'Saint-Germain-des-Prés',
          'Latin Quarter',
          'Bastille',
          'Canal Saint-Martin',
          'Belleville',
          'Ménilmontant',
          'Buttes-Chaumont',
          'Parc des Buttes-Chaumont'
        ]
      },
      'Lyon': {
        'Lyon': [
          'Vieux Lyon',
          'Place Bellecour',
          'Fourvière Basilica',
          'Lyon Cathedral',
          'Traboules',
          'Presqu\'île',
          'Croix-Rousse',
          'Confluence',
          'Part-Dieu',
          'Gerland',
          'Villeurbanne',
          'Bron',
          'Vénissieux',
          'Saint-Fons',
          'Caluire-et-Cuire',
          'Rillieux-la-Pape',
          'Décines-Charpieu',
          'Meyzieu',
          'Vaulx-en-Velin',
          'Saint-Priest'
        ]
      },
      'Marseille': {
        'Marseille': [
          'Vieux Port',
          'Notre-Dame de la Garde',
          'Le Panier',
          'La Canebière',
          'Rue de la République',
          'Rue d\'Antibes',
          'Promenade des Anglais',
          'Corniche Kennedy',
          'Calanques',
          'Château d\'If',
          'MuCEM',
          'Palais Longchamp',
          'Cours Julien',
          'La Plaine',
          'Noailles',
          'Belsunce',
          'Saint-Charles',
          'La Blancarde',
          'La Timone',
          'La Valentine'
        ]
      }
    },
    'Germany': {
      'Berlin': {
        'Berlin': [
          'Brandenburg Gate',
          'Reichstag',
          'Checkpoint Charlie',
          'Potsdamer Platz',
          'Alexanderplatz',
          'Unter den Linden',
          'Friedrichstraße',
          'Kurfürstendamm',
          'Potsdamer Straße',
          'Leipziger Straße',
          'Mitte',
          'Kreuzberg',
          'Friedrichshain',
          'Prenzlauer Berg',
          'Neukölln',
          'Schöneberg',
          'Charlottenburg',
          'Wilmersdorf',
          'Steglitz',
          'Zehlendorf'
        ]
      },
      'Munich': {
        'Munich': [
          'Marienplatz',
          'Frauenkirche',
          'Viktualienmarkt',
          'Hofbräuhaus',
          'English Garden',
          'Nymphenburg Palace',
          'Residenz',
          'Alte Pinakothek',
          'Neue Pinakothek',
          'Pinakothek der Moderne',
          'Maximilianstraße',
          'Kaufingerstraße',
          'Neuhauser Straße',
          'Odeonsplatz',
          'Karlsplatz',
          'Sendlinger Straße',
          'Theatinerstraße',
          'Residenzstraße',
          'Bayerstraße',
          'Altstadt'
        ]
      },
      'Hamburg': {
        'Hamburg': [
          'Speicherstadt',
          'HafenCity',
          'Elbphilharmonie',
          'Reeperbahn',
          'St. Pauli',
          'Alster',
          'Jungfernstieg',
          'Rathausmarkt',
          'Mönckebergstraße',
          'Spitalerstraße',
          'Neustadt',
          'Altstadt',
          'Sternschanze',
          'Schanzenviertel',
          'Karolinenviertel',
          'Ottensen',
          'Altona',
          'Eimsbüttel',
          'Winterhude',
          'Uhlenhorst'
        ]
      }
    },
    'Italy': {
      'Rome': {
        'Rome': [
          'Colosseum',
          'Roman Forum',
          'Pantheon',
          'Trevi Fountain',
          'Spanish Steps',
          'Vatican City',
          'St. Peter\'s Basilica',
          'Sistine Chapel',
          'Vatican Museums',
          'Castel Sant\'Angelo',
          'Trastevere',
          'Campo de\' Fiori',
          'Piazza Navona',
          'Piazza del Popolo',
          'Via del Corso',
          'Via Veneto',
          'Testaccio',
          'Monti',
          'Pigneto',
          'San Lorenzo'
        ]
      },
      'Milan': {
        'Milan': [
          'Duomo di Milano',
          'Galleria Vittorio Emanuele II',
          'La Scala',
          'Sforza Castle',
          'Brera',
          'Navigli',
          'Porta Nuova',
          'Corso Buenos Aires',
          'Via Montenapoleone',
          'Quadrilatero della Moda',
          'Isola',
          'Garibaldi',
          'Porta Garibaldi',
          'Corso Como',
          'Via Torino',
          'Via Dante',
          'Piazza del Duomo',
          'Piazza della Scala',
          'Piazza Castello',
          'Piazza Gae Aulenti'
        ]
      },
      'Florence': {
        'Florence': [
          'Duomo',
          'Uffizi Gallery',
          'Ponte Vecchio',
          'Pitti Palace',
          'Boboli Gardens',
          'Piazza della Signoria',
          'Ponte Santa Trinita',
          'Ponte alle Grazie',
          'Ponte Amerigo Vespucci',
          'Ponte San Niccolò',
          'Oltrarno',
          'Santo Spirito',
          'San Frediano',
          'San Niccolò',
          'Santa Croce',
          'Santa Maria Novella',
          'Duomo',
          'Baptistery',
          'Campanile',
          'Cupola'
        ]
      }
    },
    'Spain': {
      'Madrid': {
        'Madrid': [
          'Puerta del Sol',
          'Plaza Mayor',
          'Royal Palace',
          'Prado Museum',
          'Retiro Park',
          'Gran Vía',
          'Salamanca',
          'Chueca',
          'Malasaña',
          'Lavapiés',
          'La Latina',
          'Huertas',
          'Antón Martín',
          'Tirso de Molina',
          'Ópera',
          'Callao',
          'Moncloa',
          'Argüelles',
          'Chamberí',
          'Tetuán'
        ]
      },
      'Barcelona': {
        'Barcelona': [
          'Sagrada Familia',
          'Park Güell',
          'Casa Batlló',
          'Casa Milà',
          'Las Ramblas',
          'Gothic Quarter',
          'El Born',
          'Barceloneta',
          'Eixample',
          'Gràcia',
          'Poblenou',
          'Sant Antoni',
          'Raval',
          'Poble Sec',
          'Sants',
          'Les Corts',
          'Sarrià-Sant Gervasi',
          'Horta-Guinardó',
          'Nou Barris',
          'Sant Andreu'
        ]
      },
      'Valencia': {
        'Valencia': [
          'Ciudad de las Artes y las Ciencias',
          'Oceanogràfic',
          'Mercado Central',
          'Lonja de la Seda',
          'Cathedral',
          'Miguelete Tower',
          'Plaza de la Virgen',
          'Plaza de la Reina',
          'Plaza del Ayuntamiento',
          'Plaza de Toros',
          'Ruzafa',
          'El Carmen',
          'Eixample',
          'Campanar',
          'Benimaclet',
          'Patraix',
          'Jesús',
          'Nazaret',
          'Poblats Marítims',
          'Poblats del Nord'
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

  // Get governorates for a specific country (for Lebanon, these are the main governorates)
  static List<String> getGovernorates(String country) {
    final countryData = _locationData[country];
    if (countryData == null) return [];
    return countryData.keys.toList()..sort();
  }

  // Get districts for a specific country and governorate
  static List<String> getDistrictsByGovernorate(String country, String governorate) {
    final countryData = _locationData[country];
    if (countryData == null) return [];
    
    final governorateData = countryData[governorate];
    if (governorateData == null) return [];
    
    return governorateData.keys.toList()..sort();
  }

  // Get streets for a specific country, governorate, and district
  static List<String> getStreetsByGovernorate(String country, String governorate, String district) {
    final countryData = _locationData[country];
    if (countryData == null) return [];
    
    final governorateData = countryData[governorate];
    if (governorateData == null) return [];
    
    final districtData = governorateData[district];
    if (districtData == null) return [];
    
    return districtData..sort();
  }

  // Legacy method for backward compatibility - Get governorates for a specific country, district, and city
  static List<String> getGovernoratesLegacy(String country, String district, String city) {
    return getStreets(country, district, city);
  }

  // Validate if a location combination exists
  static bool isValidLocation(String country, String district, String city, String street) {
    final streets = getStreets(country, district, city);
    return streets.contains(street);
  }

  // Validate if a governorate/district/street combination exists
  static bool isValidLocationByGovernorate(String country, String governorate, String district, String street) {
    final streets = getStreetsByGovernorate(country, governorate, district);
    return streets.contains(street);
  }

  // Get the capital of a governorate (extract from parentheses)
  static String? getGovernorateCapital(String governorate) {
    final match = RegExp(r'\(([^)]+)\)').firstMatch(governorate);
    return match?.group(1);
  }

  // Get the capital of a district (extract from parentheses)
  static String? getDistrictCapital(String district) {
    final match = RegExp(r'\(([^)]+)\)').firstMatch(district);
    return match?.group(1);
  }

  // Check if a country uses the new governorate structure
  static bool usesGovernorateStructure(String country) {
    return country == 'Lebanon';
  }
} 