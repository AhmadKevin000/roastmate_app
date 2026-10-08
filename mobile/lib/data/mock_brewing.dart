import '../domain/brew_recipe.dart';

/// Data mock knowledge base brewing (sementara).
///
/// Bentuk field selaras dengan `brew_methods` + `brew_recipes`
/// (`docs/DATABASE_SCHEMA.md` §4–§5). Nanti diganti `BrewingRepository` (SQLite).
final List<BrewMethod> mockBrewMethods = const [
  BrewMethod(
    methodId: 'M001',
    methodName: 'V60 / Pour Over',
    methodType: 'pour_over',
    subtitle: 'Metode Drip Perkusi Manual',
    description:
        'Menonjolkan keasaman bersih, aroma buah tropis, dan sweetness halus.',
  ),
  BrewMethod(
    methodId: 'M002',
    methodName: 'French Press',
    methodType: 'immersion',
    subtitle: 'Ekstraksi Immersion Rendam Total',
    description:
        'Body tebal, rasa cokelat & earthy yang kaya, ekstraksi merata tanpa filter kertas.',
  ),
  BrewMethod(
    methodId: 'M003',
    methodName: 'Kopi Tubruk Tradisional',
    methodType: 'immersion',
    subtitle: 'Warisan Seduh Nusantara',
    description:
        'Intensitas bold, aromatik klasik Nusantara, sederhana dan autentik.',
  ),
];

final List<BrewRecipe> mockBrewRecipes = const [
  // ---------------------------------------------------------------------------
  // V60 / Pour Over
  // ---------------------------------------------------------------------------
  BrewRecipe(
    recipeId: 'R001',
    methodId: 'M001',
    species: 'Arabica',
    qualityProfile: 'High',
    roastContext: 'Light/Medium',
    doseG: 15,
    waterVolumeMl: 225,
    grindSize: 'Medium-Fine',
    temperatureC: 92,
    brewingTimeS: 165,
    source: 'BR001',
    isDefault: true,
    flavorProfile: 'Clean & Bright Extraction',
    pourLabel: '3 Tahap',
    notes: 'Rasa kopi dipengaruhi oleh laju aliran dan ukuran gilingan:',
    steps: [
      // Persiapan & Alat Seduh
      BrewStep(
        stepNo: 1,
        phase: BrewStepPhase.prep,
        title: 'Drifter V60 & Paper Filter',
        description:
            'Dibilas merata dengan air hangat, lalu buang air bilasan dari server.',
      ),
      BrewStep(
        stepNo: 2,
        phase: BrewStepPhase.prep,
        title: 'Teko Leher Angsa (Gooseneck Kettle)',
        description:
            'Air panas suhu 92°C siap mengalir dengan stabil dan presisi.',
      ),
      BrewStep(
        stepNo: 3,
        phase: BrewStepPhase.prep,
        title: 'Timbangan Digital (Scale) & Timer',
        description:
            'Dikalibrasi dan di-tare ke angka 0.0g setelah kopi masuk.',
      ),
      // Panduan Langkah
      BrewStep(
        stepNo: 1,
        phase: BrewStepPhase.brew,
        title: 'Persiapan & Rinsing',
        targetTime: '00:00',
        description:
            'Pasang kertas filter pada dripper, bilas dengan air panas untuk menghilangkan aroma kertas serta memanaskan server, lalu buang air bilasan. Masukkan 15g bubuk kopi gilingan medium-fine dan ratakan permukaannya.',
      ),
      BrewStep(
        stepNo: 2,
        phase: BrewStepPhase.brew,
        title: 'Blooming',
        targetTime: '00:00 – 00:45',
        description:
            'Tuang 45ml air suhu 92°C secara melingkar perlahan dari tengah ke luar. Diamkan selama 45 detik untuk degassing (pelepasan gas CO2) agar ekstraksi rasa manis dan keasaman kopi terbuka optimal.',
        callout: 'Target timbangan: 45 ml',
      ),
      BrewStep(
        stepNo: 3,
        phase: BrewStepPhase.brew,
        title: 'Penuangan Pertama',
        targetTime: '00:45 – 01:30',
        description:
            'Lanjutkan penuangan kedua sebesar +105ml air dengan aliran stabil dan konsisten (pola spiral dari tengah ke tepi tanpa mengenai dinding kertas filter) hingga timbangan menyentuh 150ml.',
        callout: 'Aliran stabil spiral • Target timbangan: 150 ml',
      ),
      BrewStep(
        stepNo: 4,
        phase: BrewStepPhase.brew,
        title: 'Penuangan Kedua',
        targetTime: '01:30 – 02:15',
        description:
            'Tuang +75ml air. Pertahankan ketinggian air di dalam dripper tetap tenang dan konsisten untuk memastikan ekstraksi rasa yang seimbang dan merata.',
        callout: 'Target total akhir: 225 ml',
      ),
      BrewStep(
        stepNo: 5,
        phase: BrewStepPhase.brew,
        title: 'Penirisan & Penyajian',
        targetTime: '02:15 – 02:45',
        description:
            'Beri sedikit putaran lembut (gentle swirl) pada dripper agar ampas kopi turun merata (flat coffee bed). Biarkan air menetes habis hingga waktu menunjukkan sekitar 02:45. Angkat dripper, aduk cangkir/server, dan nikmati secangkir kopi segar!',
        callout: 'Aduk (swirl) server 3-5 putaran sebelum dituang ke cangkir',
      ),
    ],
  ),

  // ---------------------------------------------------------------------------
  // French Press
  // ---------------------------------------------------------------------------
  BrewRecipe(
    recipeId: 'R002',
    methodId: 'M002',
    species: 'Arabica',
    qualityProfile: 'Medium',
    roastContext: 'Medium/Dark',
    doseG: 18,
    waterVolumeMl: 252,
    grindSize: 'Coarse',
    temperatureC: 94,
    brewingTimeS: 240,
    source: 'BR001',
    isDefault: true,
    flavorProfile: 'Rich & Full Body',
    pourLabel: '1 Tahap',
    notes: 'Rasa kopi dipengaruhi oleh durasi perendaman dan ukuran gilingan:',
    steps: [
      BrewStep(
        stepNo: 1,
        phase: BrewStepPhase.prep,
        title: 'French Press & Filter Mesh',
        description:
            'Bilas plunger dan tabung dengan air panas agar suhu seduh lebih stabil.',
      ),
      BrewStep(
        stepNo: 2,
        phase: BrewStepPhase.prep,
        title: 'Teko Leher Angsa (Gooseneck Kettle)',
        description:
            'Air panas suhu 94°C siap mengalir dengan stabil dan presisi.',
      ),
      BrewStep(
        stepNo: 3,
        phase: BrewStepPhase.prep,
        title: 'Timbangan Digital (Scale) & Timer',
        description:
            'Dikalibrasi dan di-tare ke angka 0.0g setelah kopi masuk.',
      ),
      BrewStep(
        stepNo: 1,
        phase: BrewStepPhase.brew,
        title: 'Persiapan & Pemanasan',
        targetTime: '00:00',
        description:
            'Bilas French Press dengan air panas, lalu buang airnya. Masukkan 18g bubuk kopi gilingan coarse dan ratakan permukaannya.',
      ),
      BrewStep(
        stepNo: 2,
        phase: BrewStepPhase.brew,
        title: 'Penuangan Awal',
        targetTime: '00:00 – 00:30',
        description:
            'Tuang seluruh 252ml air suhu 94°C secara perlahan, pastikan seluruh bubuk kopi terbasahi merata.',
        callout: 'Target timbangan: 252 ml',
      ),
      BrewStep(
        stepNo: 3,
        phase: BrewStepPhase.brew,
        title: 'Perendaman (Steeping)',
        targetTime: '00:30 – 03:30',
        description:
            'Tutup French Press dan diamkan selama 3 menit agar ekstraksi merata dan body tebal terbentuk.',
        callout: 'Aduk perlahan permukaan (crust) satu kali',
      ),
      BrewStep(
        stepNo: 4,
        phase: BrewStepPhase.brew,
        title: 'Penekanan (Press)',
        targetTime: '03:30 – 04:00',
        description:
            'Tekan plunger perlahan dan konsisten hingga dasar untuk memisahkan ampas dari seduhan.',
        callout: 'Tekan dengan kecepatan tetap',
      ),
      BrewStep(
        stepNo: 5,
        phase: BrewStepPhase.brew,
        title: 'Penyajian',
        targetTime: '04:00',
        description:
            'Segera tuang seluruh kopi ke server/cangkir agar ekstraksi tidak berlanjut dan rasa tetap seimbang.',
        callout: 'Jangan biarkan kopi lama di dalam press',
      ),
    ],
  ),

  // ---------------------------------------------------------------------------
  // Kopi Tubruk Tradisional
  // ---------------------------------------------------------------------------
  BrewRecipe(
    recipeId: 'R003',
    methodId: 'M003',
    species: 'Robusta',
    qualityProfile: 'Medium',
    roastContext: 'Dark',
    doseG: 15,
    waterVolumeMl: 180,
    grindSize: 'Fine',
    temperatureC: 95,
    brewingTimeS: 240,
    source: 'BR003',
    isDefault: true,
    flavorProfile: 'Bold & Authentic',
    pourLabel: '1 Tahap',
    notes: 'Rasa kopi dipengaruhi oleh durasi rendam dan ukuran gilingan:',
    steps: [
      BrewStep(
        stepNo: 1,
        phase: BrewStepPhase.prep,
        title: 'Gelas Saji & Sendok',
        description:
            'Gelas tahan panas dibersihkan dan sendok disiapkan untuk mengaduk seduhan.',
      ),
      BrewStep(
        stepNo: 2,
        phase: BrewStepPhase.prep,
        title: 'Ketel Air Panas',
        description: 'Air panas suhu 95°C siap dituang dengan stabil.',
      ),
      BrewStep(
        stepNo: 3,
        phase: BrewStepPhase.prep,
        title: 'Timbangan Digital (Scale)',
        description:
            'Dikalibrasi dan di-tare ke angka 0.0g sebelum menakar kopi.',
      ),
      BrewStep(
        stepNo: 1,
        phase: BrewStepPhase.brew,
        title: 'Penakaran & Penempatan',
        targetTime: '00:00',
        description:
            'Masukkan 15g bubuk kopi gilingan fine ke dalam gelas saji secara merata di dasar gelas.',
      ),
      BrewStep(
        stepNo: 2,
        phase: BrewStepPhase.brew,
        title: 'Penuangan Air',
        targetTime: '00:00 – 00:20',
        description:
            'Tuang 180ml air panas suhu 95°C perlahan hingga seluruh permukaan kopi terendam.',
        callout: 'Target timbangan: 180 ml',
      ),
      BrewStep(
        stepNo: 3,
        phase: BrewStepPhase.brew,
        title: 'Perendaman',
        targetTime: '00:20 – 03:30',
        description:
            'Diamkan selama kurang lebih 3 menit agar ampas mengendap dan ekstraksi terbentuk sempurna.',
        callout: 'Tutup gelas agar suhu stabil',
      ),
      BrewStep(
        stepNo: 4,
        phase: BrewStepPhase.brew,
        title: 'Pengadukan & Penyajian',
        targetTime: '03:30 – 04:00',
        description:
            'Aduk perlahan sekali, biarkan ampas mengendap, lalu nikmati seduhan langsung dari gelas.',
        callout: 'Aduk searah 3-5 putaran',
      ),
    ],
  ),
];
