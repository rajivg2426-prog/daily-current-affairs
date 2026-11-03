import '../../../../common/models/bilingual.dart';
import '../../../../common/utils/category.dart';
import '../models/article.dart';

/// SAMPLE CONTENT for offline / demo mode.
///
/// These are evergreen exam explainers with stable facts, so the app is
/// useful before the Firebase backend is live. They are dated relative to
/// "now" only so the Today screen has something to show. Live mode replaces
/// all of this with editor-approved articles from Firestore.
List<Article> sampleArticles(DateTime now) {
  DateTime ago(int hours) => now.subtract(Duration(hours: hours));

  return [
    Article(
      id: 'rbi-mpc',
      category: NewsCategory.economy,
      examTags: const ['banking', 'upsc', 'ssc'],
      headline: const Bi(
        'RBI Monetary Policy Committee: how the repo rate decision works',
        'RBI मौद्रिक नीति समिति: रेपो दर का निर्णय कैसे होता है',
      ),
      summary: const Bi(
        'The six-member MPC sets the repo rate to keep CPI inflation near 4%, within a 2% to 6% band. The RBI Governor chairs it and has a casting vote.',
        'छह सदस्यीय MPC रेपो दर तय करती है ताकि CPI महंगाई 2% से 6% के दायरे में, 4% के आसपास रहे। RBI गवर्नर इसकी अध्यक्षता करते हैं और बराबरी पर निर्णायक मत देते हैं।',
      ),
      keyPoints: const BiList(
        [
          'The repo rate is the rate at which the RBI lends short-term funds to banks.',
          'The MPC has six members: three from the RBI and three appointed by the Centre.',
          'The RBI Governor chairs the MPC and has a casting vote in a tie.',
          'The inflation target is 4% CPI, with a tolerance band of 2% to 6%.',
        ],
        [
          'रेपो दर वह दर है जिस पर RBI बैंकों को अल्पकालिक ऋण देता है।',
          'MPC में छह सदस्य होते हैं: तीन RBI से और तीन केंद्र सरकार द्वारा नियुक्त।',
          'RBI गवर्नर MPC के अध्यक्ष होते हैं और बराबर मत होने पर निर्णायक मत देते हैं।',
          'महंगाई का लक्ष्य 4% CPI है, जिसकी सहनशील सीमा 2% से 6% है।',
        ],
      ),
      body: const Bi(
        'When inflation runs above target, the MPC can raise the repo rate. Borrowing becomes costlier for banks, which pass it on as higher loan rates, cooling demand. When growth is weak and inflation is under control, a cut does the opposite. The flexible inflation targeting framework was written into the RBI Act, 1934 through an amendment in 2016.',
        'जब महंगाई लक्ष्य से ऊपर होती है, तो MPC रेपो दर बढ़ा सकती है। इससे बैंकों के लिए उधार महंगा होता है, वे ऋण दरें बढ़ाते हैं और मांग घटती है। जब विकास धीमा हो और महंगाई नियंत्रण में हो, तो दर घटाने से उल्टा असर होता है। लचीले मुद्रास्फीति लक्ष्यीकरण ढांचे को 2016 में संशोधन द्वारा RBI अधिनियम, 1934 में जोड़ा गया।',
      ),
      whyImportant: const Bi(
        'MPC composition, the inflation band and policy rates are asked almost every year in Banking and SSC general awareness, and in UPSC GS-III.',
        'MPC की संरचना, महंगाई दायरा और नीतिगत दरें बैंकिंग व SSC सामान्य जागरूकता तथा UPSC GS-III में लगभग हर साल पूछी जाती हैं।',
      ),
      syllabus: 'GS-III Economy',
      relevance: 'both',
      source: const SourceCredit(name: 'RBI', url: 'https://rbi.org.in', attribution: 'Source: Reserve Bank of India'),
      publishDate: ago(2),
      readMinutes: 5,
      facts: const [
        Bi('The RBI Monetary Policy Committee has six members.', 'RBI मौद्रिक नीति समिति में छह सदस्य हैं।'),
        Bi('India\'s CPI inflation target is 4% (band 2% to 6%).', 'भारत का CPI महंगाई लक्ष्य 4% है (दायरा 2% से 6%)।'),
      ],
      mcqs: const [
        Mcq(
          id: 'rbi-mpc-q1',
          question: Bi('How many members sit on the RBI\'s Monetary Policy Committee?', 'RBI की मौद्रिक नीति समिति में कितने सदस्य होते हैं?'),
          options: BiList(['Four', 'Five', 'Six', 'Seven'], ['चार', 'पांच', 'छह', 'सात']),
          answerIndex: 2,
          explanation: Bi(
            'Six: three from the RBI, including the Governor, and three appointed by the Central Government.',
            'छह: गवर्नर सहित तीन RBI से और तीन केंद्र सरकार द्वारा नियुक्त।',
          ),
        ),
        Mcq(
          id: 'rbi-mpc-q2',
          question: Bi('What is the upper limit of the RBI\'s inflation tolerance band?', 'RBI के महंगाई सहनशील दायरे की ऊपरी सीमा क्या है?'),
          options: BiList(['4%', '5%', '6%', '8%'], ['4%', '5%', '6%', '8%']),
          answerIndex: 2,
          explanation: Bi('The target is 4% CPI with a band of 2% to 6%.', 'लक्ष्य 4% CPI है, दायरा 2% से 6%।'),
        ),
      ],
    ),
    Article(
      id: 'pm-kisan',
      category: NewsCategory.schemes,
      examTags: const ['ssc', 'banking', 'upsc', 'statepsc'],
      headline: const Bi('PM-KISAN: what the scheme gives and who runs it', 'पीएम-किसान: योजना क्या देती है और कौन चलाता है'),
      summary: const Bi(
        'PM-KISAN gives eligible farmer families ₹6,000 a year in three instalments of ₹2,000, paid directly to bank accounts. It was launched in February 2019.',
        'पीएम-किसान पात्र किसान परिवारों को सालाना ₹6,000 देती है, ₹2,000 की तीन किस्तों में, सीधे बैंक खाते में। इसे फरवरी 2019 में शुरू किया गया।',
      ),
      keyPoints: const BiList(
        [
          'Income support of ₹6,000 a year per eligible farmer family.',
          'Paid in three equal instalments of ₹2,000 by direct benefit transfer.',
          'Launched in February 2019.',
          'Run by the Ministry of Agriculture and Farmers Welfare.',
        ],
        [
          'प्रति पात्र किसान परिवार सालाना ₹6,000 की आय सहायता।',
          'प्रत्यक्ष लाभ अंतरण से ₹2,000 की तीन बराबर किस्तों में भुगतान।',
          'फरवरी 2019 में शुरू।',
          'कृषि एवं किसान कल्याण मंत्रालय द्वारा संचालित।',
        ],
      ),
      body: const Bi(
        'PM-KISAN is a central sector scheme, which means the Centre funds it fully. Money goes straight to the farmer\'s bank account through direct benefit transfer, which cuts out middlemen. Questions usually test the amount, the number of instalments, the launch year and the ministry.',
        'पीएम-किसान एक केंद्रीय क्षेत्र योजना है, यानी इसका पूरा खर्च केंद्र उठाता है। पैसा प्रत्यक्ष लाभ अंतरण से सीधे किसान के खाते में जाता है, जिससे बिचौलिए हटते हैं। प्रश्न आमतौर पर राशि, किस्तों की संख्या, शुरुआत का वर्ष और मंत्रालय पर होते हैं।',
      ),
      whyImportant: const Bi(
        'A favourite in SSC, Banking and State PSC schemes questions; useful for UPSC GS-III agriculture and DBT.',
        'SSC, बैंकिंग और राज्य PSC में योजनाओं के प्रश्नों में अक्सर पूछा जाता है; UPSC GS-III कृषि और DBT के लिए उपयोगी।',
      ),
      syllabus: 'GS-III Agriculture',
      relevance: 'prelims',
      source: const SourceCredit(name: 'PIB', url: 'https://pib.gov.in', attribution: 'Source: Press Information Bureau (PIB)'),
      publishDate: ago(4),
      facts: const [
        Bi('PM-KISAN pays ₹6,000 a year in three instalments.', 'पीएम-किसान सालाना ₹6,000 तीन किस्तों में देती है।'),
      ],
      mcqs: const [
        Mcq(
          id: 'pm-kisan-q1',
          question: Bi('How much does PM-KISAN pay an eligible farmer family each year?', 'पीएम-किसान एक पात्र किसान परिवार को हर साल कितनी राशि देती है?'),
          options: BiList(['₹4,000', '₹6,000', '₹8,000', '₹12,000'], ['₹4,000', '₹6,000', '₹8,000', '₹12,000']),
          answerIndex: 1,
          explanation: Bi('₹6,000 a year, paid in three instalments of ₹2,000.', 'सालाना ₹6,000, ₹2,000 की तीन किस्तों में।'),
        ),
      ],
    ),
    Article(
      id: 'weo-imf',
      category: NewsCategory.international,
      examTags: const ['ssc', 'banking', 'upsc'],
      headline: const Bi('World Economic Outlook: who publishes it and when', 'वर्ल्ड इकोनॉमिक आउटलुक: इसे कौन और कब प्रकाशित करता है'),
      summary: const Bi(
        'The International Monetary Fund publishes the World Economic Outlook twice a year, in April and October. The World Bank\'s flagship forecast is Global Economic Prospects.',
        'अंतरराष्ट्रीय मुद्रा कोष (IMF) वर्ल्ड इकोनॉमिक आउटलुक साल में दो बार, अप्रैल और अक्टूबर में प्रकाशित करता है। विश्व बैंक की प्रमुख रिपोर्ट ग्लोबल इकोनॉमिक प्रॉस्पेक्ट्स है।',
      ),
      keyPoints: const BiList(
        [
          'World Economic Outlook: published by the IMF.',
          'Released twice a year, in April and October.',
          'Global Economic Prospects: published by the World Bank.',
        ],
        [
          'वर्ल्ड इकोनॉमिक आउटलुक: IMF द्वारा प्रकाशित।',
          'साल में दो बार, अप्रैल और अक्टूबर में जारी।',
          'ग्लोबल इकोनॉमिक प्रॉस्पेक्ट्स: विश्व बैंक द्वारा प्रकाशित।',
        ],
      ),
      body: const Bi(
        'Report-and-publisher pairs are a common one-mark question. Mixing up the IMF and the World Bank is the usual trap, so learn the flagship reports of each together.',
        'रिपोर्ट और प्रकाशक की जोड़ी एक आम एक-अंक वाला प्रश्न है। IMF और विश्व बैंक में भ्रम सामान्य जाल है, इसलिए दोनों की प्रमुख रिपोर्टें साथ याद करें।',
      ),
      whyImportant: const Bi('Reports and indices are asked in SSC, Banking and UPSC Prelims.', 'रिपोर्ट और सूचकांक SSC, बैंकिंग और UPSC प्रारंभिक परीक्षा में पूछे जाते हैं।'),
      syllabus: 'GS-II International institutions',
      relevance: 'prelims',
      source: const SourceCredit(name: 'PIB', url: 'https://pib.gov.in', attribution: 'Source: Press Information Bureau (PIB)'),
      publishDate: ago(6),
      readMinutes: 3,
      facts: const [Bi('The IMF publishes the World Economic Outlook.', 'IMF वर्ल्ड इकोनॉमिक आउटलुक प्रकाशित करता है।')],
      mcqs: const [
        Mcq(
          id: 'weo-q1',
          question: Bi('Which organisation publishes the World Economic Outlook?', 'वर्ल्ड इकोनॉमिक आउटलुक कौन सा संगठन प्रकाशित करता है?'),
          options: BiList(
            ['World Bank', 'International Monetary Fund', 'World Trade Organization', 'OECD'],
            ['विश्व बैंक', 'अंतरराष्ट्रीय मुद्रा कोष', 'विश्व व्यापार संगठन', 'OECD'],
          ),
          answerIndex: 1,
          explanation: Bi('The IMF publishes it in April and October.', 'IMF इसे अप्रैल और अक्टूबर में प्रकाशित करता है।'),
        ),
      ],
    ),
    Article(
      id: 'kaziranga',
      category: NewsCategory.environment,
      examTags: const ['upsc', 'ssc', 'statepsc'],
      headline: const Bi('Kaziranga National Park: key facts for exams', 'काज़ीरंगा राष्ट्रीय उद्यान: परीक्षा के लिए मुख्य तथ्य'),
      summary: const Bi(
        'Kaziranga, in Assam, is known for the greater one-horned rhinoceros. It became a UNESCO World Heritage Site in 1985 and a tiger reserve in 2006.',
        'असम में स्थित काज़ीरंगा एक सींग वाले गैंडे के लिए प्रसिद्ध है। यह 1985 में यूनेस्को विश्व धरोहर स्थल और 2006 में बाघ अभयारण्य बना।',
      ),
      keyPoints: const BiList(
        [
          'Located in Assam, on the floodplains of the Brahmaputra.',
          'Home to the largest population of the greater one-horned rhinoceros.',
          'UNESCO World Heritage Site since 1985.',
          'Declared a tiger reserve in 2006.',
        ],
        [
          'असम में ब्रह्मपुत्र के बाढ़ के मैदानों में स्थित।',
          'एक सींग वाले गैंडों की सबसे बड़ी आबादी।',
          '1985 से यूनेस्को विश्व धरोहर स्थल।',
          '2006 में बाघ अभयारण्य घोषित।',
        ],
      ),
      body: const Bi(
        'Protected areas are a steady source of Prelims questions: state, signature species, and UNESCO status. Kaziranga combines all three, which is why it appears so often.',
        'संरक्षित क्षेत्र प्रारंभिक परीक्षा के प्रश्नों का नियमित स्रोत हैं: राज्य, प्रमुख प्रजाति और यूनेस्को दर्जा। काज़ीरंगा में तीनों हैं, इसलिए यह अक्सर पूछा जाता है।',
      ),
      whyImportant: const Bi('Environment and protected areas carry steady weight in UPSC Prelims and State PSCs.', 'पर्यावरण और संरक्षित क्षेत्रों का UPSC प्रारंभिक और राज्य PSC में स्थिर महत्व है।'),
      syllabus: 'GS-III Environment',
      relevance: 'prelims',
      source: const SourceCredit(name: 'PIB', url: 'https://pib.gov.in', attribution: 'Source: Press Information Bureau (PIB)'),
      publishDate: ago(9),
      readMinutes: 3,
      facts: const [
        Bi('Kaziranga National Park is in Assam.', 'काज़ीरंगा राष्ट्रीय उद्यान असम में है।'),
        Bi('Kaziranga became a UNESCO World Heritage Site in 1985.', 'काज़ीरंगा 1985 में यूनेस्को विश्व धरोहर स्थल बना।'),
      ],
      mcqs: const [
        Mcq(
          id: 'kaziranga-q1',
          question: Bi('Kaziranga National Park is located in which state?', 'काज़ीरंगा राष्ट्रीय उद्यान किस राज्य में है?'),
          options: BiList(['West Bengal', 'Assam', 'Arunachal Pradesh', 'Meghalaya'], ['पश्चिम बंगाल', 'असम', 'अरुणाचल प्रदेश', 'मेघालय']),
          answerIndex: 1,
          explanation: Bi('Kaziranga is in Assam, on the Brahmaputra floodplains.', 'काज़ीरंगा असम में, ब्रह्मपुत्र के मैदानों में है।'),
        ),
      ],
    ),
    Article(
      id: 'ins-vikrant',
      category: NewsCategory.defence,
      examTags: const ['defence', 'ssc', 'upsc'],
      headline: const Bi('INS Vikrant: India\'s first indigenous aircraft carrier', 'INS विक्रांत: भारत का पहला स्वदेशी विमानवाहक पोत'),
      summary: const Bi(
        'INS Vikrant, India\'s first indigenously built aircraft carrier, was commissioned on 2 September 2022. It was built by Cochin Shipyard Limited.',
        'भारत का पहला स्वदेशी विमानवाहक पोत INS विक्रांत 2 सितंबर 2022 को नौसेना में शामिल हुआ। इसे कोचीन शिपयार्ड लिमिटेड ने बनाया।',
      ),
      keyPoints: const BiList(
        [
          'First aircraft carrier designed and built in India.',
          'Commissioned on 2 September 2022.',
          'Built by Cochin Shipyard Limited, Kochi.',
        ],
        [
          'भारत में डिज़ाइन और निर्मित पहला विमानवाहक पोत।',
          '2 सितंबर 2022 को कमीशन किया गया।',
          'कोचीन शिपयार्ड लिमिटेड, कोच्चि द्वारा निर्मित।',
        ],
      ),
      body: const Bi(
        'Defence exams ask about commissioning dates, builders and "firsts". Link Vikrant to the Atmanirbhar Bharat push in defence manufacturing for Mains-style answers.',
        'रक्षा परीक्षाओं में कमीशनिंग तिथि, निर्माता और "पहले" के बारे में पूछा जाता है। मुख्य परीक्षा के उत्तरों में विक्रांत को रक्षा निर्माण में आत्मनिर्भर भारत से जोड़ें।',
      ),
      whyImportant: const Bi('Core static-plus-current topic for NDA, CDS, AFCAT and SSC.', 'NDA, CDS, AFCAT और SSC के लिए मुख्य विषय।'),
      syllabus: 'GS-III Security',
      relevance: 'both',
      source: const SourceCredit(name: 'PIB', url: 'https://pib.gov.in', attribution: 'Source: Press Information Bureau (PIB)'),
      publishDate: ago(12),
      facts: const [Bi('INS Vikrant was built by Cochin Shipyard Limited.', 'INS विक्रांत का निर्माण कोचीन शिपयार्ड लिमिटेड ने किया।')],
      mcqs: const [
        Mcq(
          id: 'vikrant-q1',
          question: Bi('Which shipyard built INS Vikrant?', 'INS विक्रांत का निर्माण किस शिपयार्ड ने किया?'),
          options: BiList(
            ['Mazagon Dock', 'Cochin Shipyard', 'Garden Reach Shipbuilders', 'Hindustan Shipyard'],
            ['मझगांव डॉक', 'कोचीन शिपयार्ड', 'गार्डन रीच शिपबिल्डर्स', 'हिंदुस्तान शिपयार्ड'],
          ),
          answerIndex: 1,
          explanation: Bi('Cochin Shipyard Limited, Kochi, built the carrier.', 'कोचीन शिपयार्ड लिमिटेड, कोच्चि ने इसे बनाया।'),
        ),
      ],
    ),
    Article(
      id: 'science-day',
      category: NewsCategory.days,
      examTags: const ['ssc', 'railway', 'banking'],
      headline: const Bi('10 November: World Science Day for Peace and Development', '10 नवंबर: शांति और विकास के लिए विश्व विज्ञान दिवस'),
      summary: const Bi(
        'World Science Day for Peace and Development is observed on 10 November. UNESCO proclaimed it in 2001.',
        'शांति और विकास के लिए विश्व विज्ञान दिवस 10 नवंबर को मनाया जाता है। यूनेस्को ने 2001 में इसकी घोषणा की।',
      ),
      keyPoints: const BiList(
        ['Observed every year on 10 November.', 'Proclaimed by UNESCO in 2001.'],
        ['हर साल 10 नवंबर को मनाया जाता है।', 'यूनेस्को ने 2001 में इसकी घोषणा की।'],
      ),
      body: const Bi(
        'Important days are quick marks in SSC and Railway papers. Learn the date and the body that proclaimed it.',
        'महत्वपूर्ण दिवस SSC और रेलवे परीक्षाओं में आसान अंक हैं। तिथि और घोषित करने वाली संस्था याद रखें।',
      ),
      whyImportant: const Bi('Date-and-organisation questions appear in SSC, Railway and Banking.', 'तिथि और संस्था वाले प्रश्न SSC, रेलवे और बैंकिंग में आते हैं।'),
      syllabus: 'Static GK: Important days',
      relevance: 'prelims',
      source: const SourceCredit(name: 'PIB', url: 'https://pib.gov.in', attribution: 'Source: Press Information Bureau (PIB)'),
      publishDate: ago(14),
      readMinutes: 2,
      facts: const [Bi('World Science Day for Peace and Development: 10 November.', 'शांति और विकास के लिए विश्व विज्ञान दिवस: 10 नवंबर।')],
      mcqs: const [
        Mcq(
          id: 'science-day-q1',
          question: Bi('World Science Day for Peace and Development is observed on:', 'शांति और विकास के लिए विश्व विज्ञान दिवस कब मनाया जाता है?'),
          options: BiList(['28 February', '10 November', '11 May', '5 June'], ['28 फरवरी', '10 नवंबर', '11 मई', '5 जून']),
          answerIndex: 1,
          explanation: Bi('10 November. 28 February is India\'s National Science Day.', '10 नवंबर। 28 फरवरी भारत का राष्ट्रीय विज्ञान दिवस है।'),
        ),
      ],
    ),
    Article(
      id: 'chandrayaan3',
      category: NewsCategory.scitech,
      examTags: const ['upsc', 'ssc', 'railway'],
      headline: const Bi('Chandrayaan-3 and National Space Day', 'चंद्रयान-3 और राष्ट्रीय अंतरिक्ष दिवस'),
      summary: const Bi(
        'Chandrayaan-3 landed near the Moon\'s south pole on 23 August 2023. India now marks 23 August as National Space Day.',
        'चंद्रयान-3 ने 23 अगस्त 2023 को चंद्रमा के दक्षिणी ध्रुव के पास लैंडिंग की। भारत अब 23 अगस्त को राष्ट्रीय अंतरिक्ष दिवस के रूप में मनाता है।',
      ),
      keyPoints: const BiList(
        [
          'Landed near the lunar south pole on 23 August 2023.',
          'Lander: Vikram. Rover: Pragyan.',
          '23 August is observed as National Space Day.',
        ],
        [
          '23 अगस्त 2023 को चंद्र दक्षिणी ध्रुव के पास उतरा।',
          'लैंडर: विक्रम। रोवर: प्रज्ञान।',
          '23 अगस्त को राष्ट्रीय अंतरिक्ष दिवस मनाया जाता है।',
        ],
      ),
      body: const Bi(
        'Space missions are asked through names (lander, rover), dates and "firsts". Pair Chandrayaan-3 with National Space Day to answer both kinds of question.',
        'अंतरिक्ष मिशनों पर नाम (लैंडर, रोवर), तिथियां और "पहली बार" वाले प्रश्न आते हैं। चंद्रयान-3 को राष्ट्रीय अंतरिक्ष दिवस के साथ याद करें।',
      ),
      whyImportant: const Bi('Science and technology current affairs for UPSC, SSC and Railway.', 'UPSC, SSC और रेलवे के लिए विज्ञान-प्रौद्योगिकी करेंट अफेयर्स।'),
      syllabus: 'GS-III Science & Technology',
      relevance: 'prelims',
      source: const SourceCredit(name: 'PIB', url: 'https://pib.gov.in', attribution: 'Source: Press Information Bureau (PIB)'),
      publishDate: ago(20),
      readMinutes: 3,
      facts: const [Bi('Chandrayaan-3\'s rover is named Pragyan.', 'चंद्रयान-3 के रोवर का नाम प्रज्ञान है।')],
      mcqs: const [
        Mcq(
          id: 'ch3-q1',
          question: Bi('What is the name of Chandrayaan-3\'s rover?', 'चंद्रयान-3 के रोवर का नाम क्या है?'),
          options: BiList(['Vikram', 'Pragyan', 'Aryabhata', 'Mangal'], ['विक्रम', 'प्रज्ञान', 'आर्यभट', 'मंगल']),
          answerIndex: 1,
          explanation: Bi('Vikram is the lander; Pragyan is the rover.', 'विक्रम लैंडर है; प्रज्ञान रोवर है।'),
        ),
      ],
    ),
    Article(
      id: 'bharat-ratna',
      category: NewsCategory.awards,
      examTags: const ['ssc', 'banking', 'railway', 'upsc'],
      headline: const Bi('Bharat Ratna: India\'s highest civilian award', 'भारत रत्न: भारत का सर्वोच्च नागरिक सम्मान'),
      summary: const Bi(
        'The Bharat Ratna is India\'s highest civilian award. It was instituted in 1954.',
        'भारत रत्न भारत का सर्वोच्च नागरिक सम्मान है। इसकी स्थापना 1954 में हुई।',
      ),
      keyPoints: const BiList(
        ['Highest civilian award of India.', 'Instituted in 1954.', 'Recommended by the Prime Minister to the President.'],
        ['भारत का सर्वोच्च नागरिक सम्मान।', '1954 में स्थापित।', 'प्रधानमंत्री राष्ट्रपति को सिफारिश करते हैं।'],
      ),
      body: const Bi(
        'Award questions test the order of civilian honours (Bharat Ratna, then Padma Vibhushan, Padma Bhushan, Padma Shri) and the year each began.',
        'पुरस्कार प्रश्नों में नागरिक सम्मानों का क्रम (भारत रत्न, फिर पद्म विभूषण, पद्म भूषण, पद्म श्री) और उनकी शुरुआत का वर्ष पूछा जाता है।',
      ),
      whyImportant: const Bi('Awards and honours are standard in SSC, Banking and Railway general awareness.', 'पुरस्कार और सम्मान SSC, बैंकिंग और रेलवे सामान्य जागरूकता में मानक विषय हैं।'),
      syllabus: 'Static GK: Awards',
      relevance: 'prelims',
      source: const SourceCredit(name: 'PIB', url: 'https://pib.gov.in', attribution: 'Source: Press Information Bureau (PIB)'),
      publishDate: ago(26),
      readMinutes: 2,
      facts: const [Bi('The Bharat Ratna was instituted in 1954.', 'भारत रत्न की स्थापना 1954 में हुई।')],
      mcqs: const [
        Mcq(
          id: 'bharat-ratna-q1',
          question: Bi('In which year was the Bharat Ratna instituted?', 'भारत रत्न की स्थापना किस वर्ष हुई?'),
          options: BiList(['1950', '1952', '1954', '1956'], ['1950', '1952', '1954', '1956']),
          answerIndex: 2,
          explanation: Bi('It was instituted in 1954.', 'इसकी स्थापना 1954 में हुई।'),
        ),
      ],
    ),
  ];
}
