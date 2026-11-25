// Interface strings in English, French and Japanese.
//
// Each string is written once with its three versions side by side, so none
// can be forgotten. [S.current] is set by LedgerApp before building; the whole
// tree is rebuilt when the language changes (like the theme, see C).

const languages = ['fr', 'en', 'ja'];

class S {
  S(this.lang);
  final String lang;

  /// Current language, read everywhere (also by format.dart and model.dart).
  static S current = S('en');

  /// Device language if supported, else English.
  static String resolve(String? chosen, String deviceLang) =>
      chosen != null && languages.contains(chosen)
      ? chosen
      : languages.contains(deviceLang)
      ? deviceLang
      : 'en';

  String _t(String en, String fr, String ja) => switch (lang) {
    'fr' => fr,
    'ja' => ja,
    _ => en,
  };

  /// Plural helper: `n(3, 'entry', 'entries')` → "3 entries".
  String _n(int k, String en1, String enN, String fr1, String frN, String ja) =>
      _t('$k ${k == 1 ? en1 : enN}', '$k ${k <= 1 ? fr1 : frN}', '$k$ja');

  // Punctuation: French puts a no-break space before ":" "?" "!".
  String get colon => _t(':', ' :', '：');
  String q(String s) => _t('$s?', '$s ?', '$s？');

  String get languageName => _t('English', 'Français', '日本語');
  static const languageNames = {'fr': 'Français', 'en': 'English', 'ja': '日本語'};

  // ───────── dates (format.dart) ─────────
  List<String> get months => switch (lang) {
    'fr' => const [
      'janvier',
      'février',
      'mars',
      'avril',
      'mai',
      'juin',
      'juillet',
      'août',
      'septembre',
      'octobre',
      'novembre',
      'décembre',
    ],
    'ja' => const [
      '1月',
      '2月',
      '3月',
      '4月',
      '5月',
      '6月',
      '7月',
      '8月',
      '9月',
      '10月',
      '11月',
      '12月',
    ],
    _ => const [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ],
  };
  List<String> get monthsShort => switch (lang) {
    'fr' => const [
      'janv.',
      'févr.',
      'mars',
      'avr.',
      'mai',
      'juin',
      'juil.',
      'août',
      'sept.',
      'oct.',
      'nov.',
      'déc.',
    ],
    'ja' => months,
    _ => const [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ],
  };

  /// Monday first.
  List<String> get weekdays => switch (lang) {
    'fr' => const ['lun.', 'mar.', 'mer.', 'jeu.', 'ven.', 'sam.', 'dim.'],
    'ja' => const ['月', '火', '水', '木', '金', '土', '日'],
    _ => const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
  };

  // ───────── navigation ─────────
  String get tabHome => _t('Home', 'Accueil', 'ホーム');
  String get tabJournal => _t('Journal', 'Journal', '仕訳帳');
  String get tabLedger => _t('Ledger', 'Grand livre', '元帳');
  String get tabReports => _t('Reports', 'Rapports', 'レポート');
  String get tabAccounts => _t('Accounts', 'Comptes', '勘定');
  String get titleOverview => _t('Overview', 'Aperçu', '概要');
  String get settings => _t('Settings', 'Paramètres', '設定');
  String get newEntry => _t('New entry', 'Nouvelle écriture', '新規記帳');
  String get previousMonth => _t('Previous month', 'Mois précédent', '前月');
  String get nextMonth => _t('Next month', 'Mois suivant', '翌月');
  String get thisMonth =>
      _t('Back to this month', 'Revenir au mois en cours', '今月に戻る');

  // ───────── home (Overview) ─────────
  String get youKept => _t('You kept', 'Mis de côté', '手元に残った額');
  String get youOverspent => _t('You overspent', 'Dépassement', '使いすぎ');
  String rateKept(int pct) => _t(
    '$pct% of your income stayed with you',
    '$pct % de vos revenus vous restent',
    '収入の$pct%が手元に残りました',
  );
  String rateSpent(int pct) => _t(
    'Spending was $pct% of income',
    'Les dépenses font $pct % des revenus',
    '支出は収入の$pct%でした',
  );
  String get noIncomeYet => _t(
    'No income recorded yet this month',
    'Aucun revenu enregistré ce mois-ci',
    '今月の収入はまだありません',
  );
  String get income => _t('Income', 'Revenus', '収入');
  String get outcome => _t('Outcome', 'Dépenses', '支出');
  String get whereItWent => _t('Where it went', 'Où est passé l’argent', '使い道');
  String get budgets => _t('Budgets', 'Budgets', '予算');
  String get noSpending => _t(
    'No spending recorded this month.',
    'Aucune dépense ce mois-ci.',
    '今月の支出はまだありません。',
  );
  String get moneyIHave => _t('Money I have', 'Mon argent', '手持ちのお金');
  String get latest => _t('Latest', 'Dernières', '最近の記録');
  String nothingIn(String month) => _t(
    'Nothing recorded in $month yet.',
    'Rien d’enregistré en $month.',
    '$monthの記録はまだありません。',
  );

  // ───────── home styles (1b / 1c / 1d) ─────────
  String get homeStyle => _t('Home screen', 'Écran d’accueil', 'ホーム画面');
  String get styleOverview => _t('Overview', 'Aperçu', '概要');
  String get styleOverviewSub => _t(
    'Cards, categories and latest entries',
    'Cartes, catégories et dernières écritures',
    'カード・カテゴリー・最近の記録',
  );
  String get styleEditorial => _t('Editorial', 'Éditorial', 'エディトリアル');
  String get styleEditorialSub =>
      _t('The month as one sentence', 'Le mois en une phrase', '今月を一文で');
  String get styleTAccount => _t('T-account', 'Compte en T', 'T字勘定');
  String get styleTAccountSub => _t(
    'The month as a debit / credit page',
    'Le mois en page débit / crédit',
    '今月を借方・貸方で',
  );
  String get stylePebbles => _t('Pebbles', 'Galets', 'ペブル');
  String get stylePebblesSub => _t(
    'Spending as soft shapes + daily rhythm',
    'Les dépenses en formes + le rythme du mois',
    '支出を形で、日々のリズムも',
  );

  /// Editorial sentence, as (before, income, middle, spent, verb, kept, after).
  List<String> editorialParts({
    required String inc,
    required String exp,
    required String kept,
    required bool short,
  }) => switch (lang) {
    'fr' => [
      'Vous avez reçu ',
      inc,
      ', dépensé ',
      exp,
      short ? ' et il vous manque ' : ' et mis de côté ',
      kept,
      ' MRU.',
    ],
    'ja' => [
      '収入は',
      inc,
      '、支出は',
      exp,
      short ? '、不足は' : '、残りは',
      kept,
      ' MRUでした。',
    ],
    _ => [
      'You brought in ',
      inc,
      ', spent ',
      exp,
      short ? ' and went short by ' : ' and kept ',
      kept,
      ' MRU.',
    ],
  };
  String comparedWith(String month) =>
      _t('Compared with $month', 'Par rapport à $month', '$monthとの比較');
  String get recordSomething =>
      _t('+ Record something', '+ Noter quelque chose', '+ 記録する');
  String get myMonth => _t('My month', 'Mon mois', '今月の収支');
  String get drMoneyIn => _t('Dr · money in', 'Débit · entrées', '借方・入金');
  String get crMoneyOut => _t('Cr · money out', 'Crédit · sorties', '貸方・出金');
  String get keptCd => _t('Kept (c/d)', 'À reporter', '繰越（残高）');
  String get shortfallCd => _t('Shortfall (c/d)', 'Déficit reporté', '繰越（不足）');
  String get carriedDown => _t(
    'Balance carried down — what you kept',
    'Solde reporté — ce qui vous reste',
    '繰越残高 — 手元に残った額',
  );
  String get spentMoreThanEarned => _t(
    'You spent more than you earned by',
    'Vous avez dépensé de plus que gagné',
    '収入を上回った支出額',
  );
  String get outLabel => _t('Out', 'Sorties', '支出');
  String get inLabel => _t('In', 'Entrées', '収入');
  String get dailySpending =>
      _t('Daily spending', 'Dépenses par jour', '日別の支出');
  String peak(String v) => _t('peak $v', 'max $v', '最大 $v');

  // ───────── journal / ledger ─────────
  String get debits => _t('Debits', 'Débits', '借方');
  String get credits => _t('Credits', 'Crédits', '貸方');
  String get balanced => _t('Balanced', 'Équilibré', '貸借一致');
  String get checkEntries => _t('Check entries', 'À vérifier', '要確認');
  String get outOfBalance => _t('Out of balance', 'Déséquilibré', '不一致');
  String nothingRecorded(String month) => _t(
    'Nothing recorded in $month.\nTap + to add your first entry.',
    'Rien d’enregistré en $month.\nTouchez + pour ajouter une écriture.',
    '$monthの記録はありません。\n＋で最初の記帳を追加できます。',
  );
  String to(String account) => _t('to $account', 'à $account', '$account へ');
  String get noAccounts =>
      _t('No accounts yet.', 'Aucun compte pour l’instant.', '勘定はまだありません。');
  String get opening => _t('Opening', 'Ouverture', '期首');
  String get closing => _t('Closing', 'Clôture', '期末');
  String get colEntry => _t('Entry', 'Écriture', '記帳');
  String get colDebit => _t('Debit', 'Débit', '借方');
  String get colCredit => _t('Credit', 'Crédit', '貸方');
  String get colBalance => _t('Balance', 'Solde', '残高');
  String get colAccount => _t('Account', 'Compte', '勘定');
  String get monthTotal => _t('Month total', 'Total du mois', '月合計');
  String noMovement(String month) => _t(
    'No movement on this account in $month.',
    'Aucun mouvement sur ce compte en $month.',
    '$monthはこの勘定の動きがありません。',
  );
  String normalSide(String hint, bool debit) => _t(
    '$hint · normal side: ${debit ? 'debit' : 'credit'}',
    '$hint · sens normal : ${debit ? 'débit' : 'crédit'}',
    '$hint・通常の側：${debit ? '借方' : '貸方'}',
  );

  // ───────── reports ─────────
  String get trialBalance => _t('Trial balance', 'Balance', '試算表');
  String get monthly => _t('Monthly', 'Mensuel', '月次');
  String balancesAsAt(String date) =>
      _t('Balances as at $date', 'Soldes au $date', '$date時点の残高');
  String get total => _t('Total', 'Total', '合計');
  String get tbHint => _t(
    "Every entry has equal debits and credits, so these two columns must match. If they don't, an entry was recorded wrong.",
    'Chaque écriture a autant de débit que de crédit : ces deux colonnes doivent donc être égales. Sinon, une écriture est fausse.',
    'どの記帳も借方と貸方が同額なので、この2列は一致するはずです。一致しなければ、記帳に誤りがあります。',
  );
  String get colMonth => _t('Month', 'Mois', '月');
  String get colIn => _t('In', 'Entrées', '収入');
  String get colOut => _t('Out', 'Sorties', '支出');
  String get colKept => _t('Kept', 'Reste', '残り');
  String get noEntries6 => _t(
    'No entries yet in the last six months.',
    'Aucune écriture sur les six derniers mois.',
    '過去6か月の記帳はまだありません。',
  );
  String avgSpend(String v, String compare) => _t(
    'Over the months with entries you spend about $v MRU a month. $compare',
    'Sur les mois renseignés, vous dépensez environ $v MRU par mois. $compare',
    '記録のある月の平均支出は約$v MRUです。$compare',
  );
  String get noDataLastMonth => _t(
    'No data for last month yet.',
    'Pas encore de données pour le mois dernier.',
    '先月のデータはまだありません。',
  );
  String spentMore(String v) => _t(
    'You spent $v MRU more than last month.',
    'Vous avez dépensé $v MRU de plus que le mois dernier.',
    '先月より$v MRU多く使いました。',
  );
  String spentLess(String v) => _t(
    'You spent $v MRU less than last month.',
    'Vous avez dépensé $v MRU de moins que le mois dernier.',
    '先月より$v MRU少なく済みました。',
  );
  String get sameSpending => _t(
    'Same spending as last month.',
    'Mêmes dépenses que le mois dernier.',
    '先月と同じ支出です。',
  );
  String spentOfBudget(String month) => _t(
    'Spent of budget · $month',
    'Budget consommé · $month',
    '予算の消化・$month',
  );
  String overBudget(String v) =>
      _t('$v MRU over budget', '$v MRU de dépassement', '予算を$v MRU超過');
  String closeToLimit(String v) =>
      _t('Close to limit · $v left', 'Presque atteint · reste $v', '上限間近・残り$v');
  String left(String v) => _t('$v MRU left', 'Reste $v MRU', '残り$v MRU');
  String get noBudgets => _t(
    'No budgets yet. Set a monthly budget on any expense account in the Accounts tab.',
    'Pas encore de budget. Fixez un budget mensuel sur un compte de dépenses, dans l’onglet Comptes.',
    '予算はまだありません。「勘定」タブで費用勘定に月予算を設定できます。',
  );
  String get tapToEditBudget => _t(
    'Tap a category to change its monthly budget.',
    'Touchez une catégorie pour changer son budget mensuel.',
    'カテゴリーをタップすると月予算を変更できます。',
  );

  // ───────── accounts ─────────
  String budgetPerMonth(String v) =>
      _t('Budget $v / month', 'Budget $v / mois', '予算 $v／月');
  String get totalToDate => _t('Total to date', 'Total à ce jour', '累計');
  String get balanceToday => _t('Balance today', 'Solde actuel', '現在の残高');
  String get newAccountButton =>
      _t('+ New account', '+ Nouveau compte', '+ 新しい勘定');
  String typeLabel(String type) => switch (type) {
    'asset' => _t('Asset', 'Actif', '資産'),
    'liability' => _t('Liability', 'Passif', '負債'),
    'equity' => _t('Equity', 'Capitaux propres', '純資産'),
    'income' => _t('Income', 'Revenu', '収益'),
    _ => _t('Expense', 'Dépense', '費用'),
  };
  String groupLabel(String type) => switch (type) {
    'asset' => _t('Assets', 'Actifs', '資産'),
    'liability' => _t('Liabilities', 'Passifs', '負債'),
    'equity' => _t('Equity', 'Capitaux propres', '純資産'),
    'income' => _t('Income', 'Revenus', '収益'),
    _ => _t('Expenses', 'Dépenses', '費用'),
  };
  String typeHint(String type) => switch (type) {
    'asset' => _t('What I have', 'Ce que j’ai', '持っているもの'),
    'liability' => _t('What I owe', 'Ce que je dois', '借りているもの'),
    'equity' => _t('Starting point', 'Point de départ', '出発点'),
    'income' => _t('Money coming in', 'L’argent qui entre', '入ってくるお金'),
    _ => _t('Money going out', 'L’argent qui sort', '出ていくお金'),
  };
  String typeOption(String type) => switch (type) {
    'asset' => _t('Asset — what I have', 'Actif — ce que j’ai', '資産 — 持っているもの'),
    'liability' => _t(
      'Liability — what I owe',
      'Passif — ce que je dois',
      '負債 — 借りているもの',
    ),
    _ => typeLabel(type),
  };

  // ───────── settings ─────────
  String get language => _t('Language', 'Langue', '言語');
  String get theme => _t('Theme', 'Thème', 'テーマ');
  String get themeHint => _t(
    'Each theme changes colours and fonts.',
    'Chaque thème change les couleurs et les polices.',
    'テーマごとに色とフォントが変わります。',
  );
  String get brightness =>
      _t('Brightness (Organic)', 'Luminosité (Organic)', '明るさ（Organic）');
  String get system => _t('System', 'Système', 'システム');
  String get light => _t('Light', 'Clair', 'ライト');
  String get dark => _t('Dark', 'Sombre', 'ダーク');
  String themeName(String id) => switch (id) {
    'cappuccino' => 'Cappuccino',
    'amoled' => _t('AMOLED Black', 'Noir AMOLED', 'AMOLEDブラック'),
    'arctic' => _t('Arctic', 'Arctique', 'アークティック'),
    'sahara' => 'Sahara',
    'sakura' => _t('Sakura', 'Sakura', '桜'),
    _ => 'Organic',
  };
  String themeMood(String id) => switch (id) {
    'cappuccino' => _t(
      'Espresso, foam and caramel',
      'Expresso, mousse et caramel',
      'エスプレッソ・泡・キャラメル',
    ),
    'amoled' => _t(
      'True black, neon accents',
      'Noir profond, accents néon',
      '真っ黒にネオンの差し色',
    ),
    'arctic' => _t(
      'Ice, glacier blue, aurora',
      'Glace, bleu glacier, aurore',
      '氷・氷河の青・オーロラ',
    ),
    'sahara' => _t(
      'Dunes, henna and indigo',
      'Dunes, henné et indigo',
      '砂丘・ヘナ・藍',
    ),
    'sakura' => _t(
      'Cherry blossom and young leaves',
      'Fleurs de cerisier et jeunes feuilles',
      '桜と若葉',
    ),
    _ => _t(
      'Cream, terracotta and sage',
      'Crème, terracotta et sauge',
      'クリーム・テラコッタ・セージ',
    ),
  };
  String get bookkeepingMode =>
      _t('Bookkeeping mode', 'Mode de saisie', '記帳モード');
  String get modeSimple => _t('Simple', 'Simple', 'シンプル');
  String get modePro => _t('Accountant', 'Comptable', '会計士');
  String get modeProText => _t(
    'You choose the debit and credit account for every entry. Journal shows full Dr / Cr lines.',
    'Vous choisissez le compte débité et le compte crédité. Le journal affiche toutes les lignes Débit / Crédit.',
    '記帳ごとに借方と貸方の勘定を選びます。仕訳帳には借方・貸方の行がすべて表示されます。',
  );
  String get modeSimpleText => _t(
    'Pick expense, income or transfer — the app writes the debit and credit for you. Switch any time; your data stays the same.',
    'Choisissez dépense, revenu ou virement : l’app écrit le débit et le crédit pour vous. Vous pouvez changer à tout moment, vos données restent les mêmes.',
    '支出・収入・振替を選ぶだけで、借方と貸方はアプリが記入します。いつでも切り替えられ、データはそのままです。',
  );
  String get display => _t('Display', 'Affichage', '表示');
  String get teachingHints => _t('Teaching hints', 'Astuces', 'ヒント');
  String get teachingHintsSub => _t(
    'Explain debits, credits and budgets as you go',
    'Expliquer débits, crédits et budgets au fil de l’eau',
    '借方・貸方・予算をその都度説明します',
  );
  String get showKhoums => _t('Show khoums', 'Afficher les khoums', 'クムを表示');
  String get showKhoumsSub => _t(
    'Display amounts with two decimals',
    'Montants avec deux décimales',
    '金額を小数点以下2桁で表示',
  );
  String get dataAndSync => _t('Data & sync', 'Données et synchro', 'データと同期');
  String get resetDemo =>
      _t('Reset to demo data', 'Revenir aux données de démo', 'デモデータに戻す');
  String get resetDemoQ =>
      q(_t('Reset to demo data', 'Revenir aux données de démo', 'デモデータに戻しますか'));
  String get resetDemoText => _t(
    'This replaces all your accounts and entries with the sample household. It cannot be undone.',
    'Tous vos comptes et écritures seront remplacés par le foyer d’exemple. C’est irréversible.',
    'すべての勘定と記帳がサンプルの家計に置き換わります。元に戻せません。',
  );
  String get reset => _t('Reset', 'Réinitialiser', 'リセット');
  String get demoRestored =>
      _t('Demo data restored', 'Données de démo restaurées', 'デモデータに戻しました');

  /// Nothing of the user's own yet: the book ends up empty.
  String startEmpty(bool onlyDemo) => onlyDemo
      ? _t(
          'Start with an empty book',
          'Commencer avec un livre vide',
          '空の帳簿から始める',
        )
      : _t('Remove the demo data', 'Retirer les données de démo', 'デモデータを取り除く');
  String startEmptyText(int demo, int own) => [
    _t(
      '${_n(demo, 'demo entry', 'demo entries', '', '', '')} will be removed.',
      demo == 1
          ? 'L’écriture de démo sera retirée.'
          : 'Les $demo écritures de démo seront retirées.',
      'デモの記帳$demo件を取り除きます。',
    ),
    if (own > 0)
      _t(
        'Your ${_n(own, 'own entry stays', 'own entries stay', '', '', '')}.',
        own == 1 ? 'Votre écriture reste.' : 'Vos $own écritures restent.',
        'ご自分の記帳$own件は残ります。',
      ),
    _t(
      'Your accounts and budgets stay.',
      'Vos comptes et vos budgets restent.',
      '勘定と予算は残ります。',
    ),
  ].join(_t(' ', ' ', ''));
  String get startEmptySynced => _t(
    'Sync is on: this applies to all your devices and cannot be undone.',
    'La synchro est active : cela vaut pour tous vos appareils, sans annulation.',
    '同期がオンです。すべての端末に反映され、元に戻せません。',
  );
  String openingHint(String cash, String opening) => _t(
    'Then note what you already have: Accountant mode, debit “$cash”, credit “$opening”.',
    'Notez ensuite ce que vous avez déjà : mode Comptable, débit « $cash », crédit « $opening ».',
    '次に手持ちの額を記帳します：会計モードで、借方「$cash」、貸方「$opening」。',
  );
  String get remove => _t('Remove', 'Retirer', '取り除く');
  String get later => _t('Later', 'Plus tard', 'あとで');
  String get demoCard => _t(
    'These are sample entries, to try the app.',
    'Ce sont des écritures d’exemple, pour essayer l’app.',
    'アプリを試すためのサンプルの記帳です。',
  );
  String get demoRemoved =>
      _t('Demo data removed', 'Démo retirée', 'デモを取り除きました');
  String get version => _t('Version', 'Version', 'バージョン');

  // ───────── common buttons ─────────
  String get cancel => _t('Cancel', 'Annuler', 'キャンセル');
  String get save => _t('Save', 'Enregistrer', '保存');
  String get delete => _t('Delete', 'Supprimer', '削除');
  String get done => _t('Done', 'Terminé', '完了');
  String get undo => _t('Undo', 'Annuler', '元に戻す');
  String get merge => _t('Merge', 'Fusionner', '統合');
  String get replace => _t('Replace', 'Remplacer', '置き換え');
  String get on => _t('On', 'Activée', 'オン');
  String get off => _t('Off', 'Désactivée', 'オフ');

  // ───────── entry sheet ─────────
  String get expense => _t('Expense', 'Dépense', '支出');
  String get incomeKind => _t('Income', 'Revenu', '収入');
  String get transfer => _t('Transfer', 'Virement', '振替');
  String get category => _t('Category', 'Catégorie', 'カテゴリー');
  String get source => _t('Source', 'Source', '収入源');
  String get moveTo => _t('Move to', 'Vers', '振替先');
  String get paidWith => _t('Paid with', 'Payé avec', '支払い元');
  String get receivedIn => _t('Received in', 'Reçu sur', '入金先');
  String get moveFrom => _t('Move from', 'Depuis', '振替元');
  String get debitDr => _t('Debit (Dr)', 'Débit (D)', '借方');
  String get creditCr => _t('Credit (Cr)', 'Crédit (C)', '貸方');
  String get amountMru => _t('Amount (MRU)', 'Montant (MRU)', '金額（MRU）');
  String get date => _t('Date', 'Date', '日付');
  String get note => _t('Note', 'Note', 'メモ');
  String get hintIncome =>
      _t('e.g. November salary', 'ex. salaire de novembre', '例：11月の給与');
  String get hintExpense =>
      _t('e.g. Weekly groceries', 'ex. courses de la semaine', '例：今週の食料品');
  String get willBeRecorded =>
      _t('WILL BE RECORDED AS', 'SERA ENREGISTRÉ AINSI', '記帳内容');
  String get drShort => _t('Dr', 'D', '借');
  String get crShort => _t('Cr', 'C', '貸');
  String get saveEntry => _t('Save entry', 'Enregistrer', '記帳する');
  String get entrySaved => _t('Entry saved', 'Écriture enregistrée', '記帳しました');
  String get entryDeleted =>
      _t('Entry deleted', 'Écriture supprimée', '記帳を削除しました');
  String get errAmount => _t(
    'Enter an amount above 0.',
    'Saisissez un montant supérieur à 0.',
    '0より大きい金額を入力してください。',
  );
  String get errBothAccounts => _t(
    'Pick both accounts.',
    'Choisissez les deux comptes.',
    '両方の勘定を選んでください。',
  );
  String get errSameAccount => _t(
    'Debit and credit must be different accounts.',
    'Le débit et le crédit doivent être deux comptes différents.',
    '借方と貸方は別の勘定にしてください。',
  );
  String transferTo(String a) =>
      _t('Transfer to $a', 'Virement vers $a', '$aへ振替');
  String amountPreview(String v) => _t('= $v MRU', '= $v MRU', '＝ $v MRU');

  // ───────── account sheet ─────────
  String get editAccount => _t('Edit account', 'Modifier le compte', '勘定を編集');
  String get newAccount => _t('New account', 'Nouveau compte', '新しい勘定');
  String get name => _t('Name', 'Nom', '名前');
  String get hintAccount => _t('e.g. Fuel', 'ex. Carburant', '例：燃料');
  String get type => _t('Type', 'Type', '種類');
  String get monthlyBudget => _t(
    'Monthly budget (MRU, optional)',
    'Budget mensuel (MRU, facultatif)',
    '月予算（MRU・任意）',
  );
  String get errAccountName => _t(
    'Give the account a name.',
    'Donnez un nom au compte.',
    '勘定の名前を入力してください。',
  );
  String get errAccountInUse => _t(
    'This account has entries. Delete those first.',
    'Ce compte a des écritures. Supprimez-les d’abord.',
    'この勘定には記帳があります。先にそれを削除してください。',
  );
  String get accountSaved =>
      _t('Account saved', 'Compte enregistré', '勘定を保存しました');
  String get accountDeleted =>
      _t('Account deleted', 'Compte supprimé', '勘定を削除しました');

  // ───────── describe() ─────────
  String fromAccount(String a) => _t('from $a', 'depuis $a', '$aから');
  String intoAccount(String a) => _t('into $a', 'sur $a', '$aへ');
  String get transferLower => _t('transfer', 'virement', '振替');
  String get deletedAccount => _t('(deleted)', '(supprimé)', '（削除済み）');

  // ───────── import / export ─────────
  String get damagedText => _t(
    'Your data could not be read, so demo data is shown. Nothing was deleted: a copy is kept on this device. Sync was turned off; if you use it, choose the folder again, then “$useFolderData”.',
    'Vos données n’ont pas pu être lues : ce sont les données de démo qui s’affichent. Rien n’a été supprimé, une copie est conservée sur cet appareil. La synchro a été coupée ; si vous l’utilisez, choisissez de nouveau le dossier, puis « $useFolderData ».',
    'データを読み込めなかったため、デモデータを表示しています。何も削除されていません。コピーをこの端末に保管しました。同期は停止しました。お使いの場合は、フォルダーを選び直して「$useFolderData」を選んでください。',
  );
  String get damagedSavingOff => _t(
    'That copy could not be stored, so nothing is saved until the app is restarted. Save the copy to a file now.',
    'Cette copie n’a pas pu être enregistrée : rien n’est sauvegardé jusqu’au redémarrage de l’app. Enregistrez la copie dans un fichier maintenant.',
    'コピーを保管できませんでした。アプリを再起動するまで何も保存されません。今すぐコピーをファイルに保存してください。',
  );
  String get damagedKept => _t(
    'A copy of data that could not be read is kept on this device.',
    'Une copie de données illisibles est conservée sur cet appareil.',
    '読み込めなかったデータのコピーをこの端末に保管しています。',
  );
  String get saveCopy => _t('Save the copy', 'Enregistrer la copie', 'コピーを保存');
  String get copySaved => _t('Copy saved', 'Copie enregistrée', 'コピーを保存しました');
  String get gotIt => _t('OK', 'Compris', 'わかりました');
  String get data => _t('Data', 'Données', 'データ');
  String get dataText => _t(
    'Export a JSON file to back up or open it in the desktop app. Import merges it with this phone (or replaces, if you choose).',
    'Exportez un fichier JSON pour sauvegarder ou l’ouvrir dans l’app de bureau. L’import le fusionne avec ce téléphone (ou remplace, si vous le choisissez).',
    'JSONファイルを書き出してバックアップしたり、デスクトップ版で開いたりできます。読み込むとこの端末と統合されます（置き換えも選べます）。',
  );
  String get export => _t('Export', 'Exporter', '書き出し');
  String get import => _t('Import', 'Importer', '読み込み');
  String exported(int n) =>
      _t('Exported $n entries', '$n écritures exportées', '$n件を書き出しました');
  String exportFailed(Object e) =>
      _t('Export failed: $e', 'Échec de l’export : $e', '書き出しに失敗しました：$e');
  String cannotReadFile(Object e) => _t(
    'Could not read the file: $e',
    'Impossible de lire le fichier : $e',
    'ファイルを読めませんでした：$e',
  );
  String get importQ =>
      q(_t('Import this file', 'Importer ce fichier', 'このファイルを読み込みますか'));
  String fileHas(int acc, int ent, String span) => _t(
    'The file has $acc accounts and $ent entries$span.',
    'Le fichier contient $acc comptes et $ent écritures$span.',
    'このファイルには勘定$acc件・記帳$ent件があります$span。',
  );
  String span(String from, String to) =>
      _t(' from $from to $to', ', du $from au $to', '（$from〜$to）');
  String get mergeRecommended =>
      _t('Merge (recommended)', 'Fusionner (conseillé)', '統合（推奨）');
  String get upToDateNothingNew => _t(
    'Already up to date: nothing new in this file.',
    'Déjà à jour : rien de nouveau dans ce fichier.',
    'すでに最新です。このファイルに新しい内容はありません。',
  );
  String replaceText(int acc, int ent) => _t(
    "Your $acc accounts and $ent entries become exactly the file's.",
    'Vos $acc comptes et $ent écritures deviennent exactement ceux du fichier.',
    'この端末の勘定$acc件・記帳$ent件が、ファイルの内容と同じになります。',
  );
  String get canUndo => _t(
    'You can undo right after.',
    'Vous pourrez annuler juste après.',
    'すぐ後で元に戻せます。',
  );
  String merged(String summary) =>
      _t('Merged: $summary', 'Fusionné : $summary', '統合しました：$summary');
  String replacedWith(int n) => _t(
    'Replaced with $n entries',
    'Remplacé par $n écritures',
    '$n件の記帳に置き換えました',
  );

  // ───────── merge summary ─────────
  String mergeSummary({
    required int added,
    required int removed,
    required int accAdded,
    required int accUpdated,
    required int accRemoved,
    required int keptInUse,
    required int conflicts,
  }) {
    final parts = [
      if (added > 0)
        '+${_n(added, 'entry', 'entries', 'écriture', 'écritures', '件の記帳')}',
      if (removed > 0)
        '−${_n(removed, 'entry', 'entries', 'écriture', 'écritures', '件の記帳')}',
      if (accAdded > 0)
        '+${_n(accAdded, 'account', 'accounts', 'compte', 'comptes', '件の勘定')}',
      if (accUpdated > 0)
        _t(
          '${_n(accUpdated, 'account', 'accounts', '', '', '')} updated',
          _n(accUpdated, '', '', 'compte modifié', 'comptes modifiés', ''),
          '勘定$accUpdated件を更新',
        ),
      if (accRemoved > 0)
        '−${_n(accRemoved, 'account', 'accounts', 'compte', 'comptes', '件の勘定')}',
      if (keptInUse > 0)
        _t(
          '${_n(keptInUse, 'account', 'accounts', '', '', '')} kept (still used)',
          _n(
            keptInUse,
            '',
            '',
            'compte gardé (utilisé)',
            'comptes gardés (utilisés)',
            '',
          ),
          '使用中の勘定$keptInUse件を保持',
        ),
      if (conflicts > 0)
        _t(
          '$conflicts conflict${conflicts == 1 ? '' : 's'} (kept this device\'s)',
          '$conflicts conflit${conflicts <= 1 ? '' : 's'} (version de cet appareil gardée)',
          '競合$conflicts件（この端末の内容を保持）',
        ),
    ];
    return parts.isEmpty
        ? _t('nothing changed', 'rien n’a changé', '変更なし')
        : parts.join(_t(', ', ', ', '、'));
  }

  // ───────── sync ─────────
  String get sync => _t('Sync', 'Synchro', '同期');
  String get syncText => _t(
    'Pick a folder that Syncthing shares with your computer. Each device keeps its own file there; changes merge on their own.',
    'Choisissez un dossier que Syncthing partage avec votre ordinateur. Chaque appareil y garde son propre fichier ; les modifications fusionnent toutes seules.',
    'Syncthingでパソコンと共有しているフォルダーを選んでください。端末ごとに自分のファイルを置き、変更は自動で統合されます。',
  );
  String get chooseSyncFolder =>
      _t('Choose sync folder', 'Choisir le dossier de synchro', '同期フォルダーを選ぶ');
  String get syncNow => _t('Sync now', 'Synchroniser', '今すぐ同期');
  String get disconnect => _t('Disconnect', 'Déconnecter', '接続を解除');
  String get upToDate => _t('Up to date', 'À jour', '最新です');
  String synced(String summary) =>
      _t('Synced: $summary', 'Synchronisé : $summary', '同期しました：$summary');
  String cannotReadFolder(Object e) => _t(
    'Cannot read this folder: $e',
    'Impossible de lire ce dossier : $e',
    'このフォルダーを読めません：$e',
  );
  String folderHasData(String name) => _t(
    '“$name” already has data',
    '« $name » contient déjà des données',
    '「$name」にはすでにデータがあります',
  );
  String folderChoice(int peers, String summary) => _t(
    'It holds files from ${peers == 1 ? '1 other device' : '$peers other devices'}.\n\nMerge: $summary on this phone.\n\nUse folder data: this phone\'s entries are replaced by the folder\'s (handy the first time, if this phone only has demo data).',
    'Il contient les fichiers de ${peers <= 1 ? '1 autre appareil' : '$peers autres appareils'}.\n\nFusionner : $summary sur ce téléphone.\n\nUtiliser le dossier : les écritures de ce téléphone sont remplacées par celles du dossier (pratique la première fois, si ce téléphone n’a que la démo).',
    '他の端末$peers台のファイルがあります。\n\n統合：この端末で$summary。\n\nフォルダーのデータを使う：この端末の記帳がフォルダーの内容に置き換わります（この端末がデモデータだけの初回に便利です）。',
  );
  String demoLeftOut(int n) => _t(
    n == 1
        ? 'If you merge, the demo entry here is removed, so that it does not reach your other devices.'
        : 'If you merge, the $n demo entries here are removed, so that they do not reach your other devices.',
    n == 1
        ? 'Si vous fusionnez, l’écriture de démo présente ici est retirée, pour ne pas arriver sur vos autres appareils.'
        : 'Si vous fusionnez, les $n écritures de démo présentes ici sont retirées, pour ne pas arriver sur vos autres appareils.',
    '統合すると、他の端末に送られないよう、ここにあるデモの記帳$n件は取り除かれます。',
  );
  String get resetNeedsSyncOff => _t(
    'Sync is on: the demo data would be sent to your other devices, and your entries would come back from them. Disconnect the sync folder first.',
    'La synchro est active : les données de démo partiraient sur vos autres appareils, et vos écritures reviendraient. Déconnectez d’abord le dossier de synchro.',
    '同期がオンです。デモデータが他の端末に送られ、記帳は他の端末から戻ってきます。先に同期フォルダーの接続を解除してください。',
  );
  String get replaceNeedsSyncOff => _t(
    'Not while sync is on: your other devices would send back the entries you are replacing. Merge, or disconnect the sync folder first.',
    'Pas pendant la synchro : vos autres appareils renverraient les écritures remplacées. Fusionnez, ou déconnectez d’abord le dossier de synchro.',
    '同期中は使えません。置き換えた記帳が他の端末から戻ってきます。統合するか、先に同期フォルダーの接続を解除してください。',
  );
  String get useFolderData =>
      _t('Use folder data', 'Utiliser le dossier', 'フォルダーのデータを使う');
  String syncOn(String name) => _t(
    'Sync on: this device\'s file is in “$name”',
    'Synchro activée : le fichier de cet appareil est dans « $name »',
    '同期オン：この端末のファイルは「$name」にあります',
  );
  String get syncStopped => _t(
    'Sync stopped (this device\'s file stays in the folder)',
    'Synchro arrêtée (le fichier de cet appareil reste dans le dossier)',
    '同期を停止しました（この端末のファイルはフォルダーに残ります）',
  );
  String thisDevice(String folder, String file) => _t(
    '$folder · this device: $file',
    '$folder · cet appareil : $file',
    '$folder・この端末：$file',
  );
  String otherDevices(int n) => switch (n) {
    0 => _t('no other device yet', 'aucun autre appareil', '他の端末はまだありません'),
    1 => _t('1 other device', '1 autre appareil', '他の端末1台'),
    _ => _t('$n other devices', '$n autres appareils', '他の端末$n台'),
  };
  String connected(String others) =>
      _t('Connected · $others', 'Connecté · $others', '接続済み・$others');
  String syncedAt(String time, String others) => _t(
    'Synced at $time · $others',
    'Synchronisé à $time · $others',
    '$timeに同期・$others',
  );
  String cannotWriteFolder(Object e) => _t(
    'Cannot write to the folder: $e',
    'Impossible d’écrire dans le dossier : $e',
    'フォルダーに書き込めません：$e',
  );
  String skippedFile(String f) => _t(
    'Skipped unreadable file $f',
    'Fichier illisible ignoré : $f',
    '読めないファイルをスキップ：$f',
  );
  String syncFailed(Object e) =>
      _t('Sync failed: $e', 'Échec de la synchro : $e', '同期に失敗しました：$e');
  String get chooseFolderTitle => _t(
    'Choose the Syncthing folder',
    'Choisir le dossier Syncthing',
    'Syncthingのフォルダーを選ぶ',
  );
  String get exportTitle =>
      _t('Export ledger', 'Exporter le carnet', '帳簿を書き出す');
  String get importTitle =>
      _t('Import ledger', 'Importer un carnet', '帳簿を読み込む');

  // ───────── file validation (model.dart) ─────────
  String get errNotJson => _t(
    'This is not a JSON file.',
    'Ce n’est pas un fichier JSON.',
    'JSONファイルではありません。',
  );
  String get errNotLedger => _t(
    'This JSON is not a Ledger export.',
    'Ce JSON n’est pas un export de Ledger.',
    'このJSONはLedgerの書き出しではありません。',
  );
  String get errMalformed => _t(
    'Some accounts or entries are malformed.',
    'Certains comptes ou écritures sont mal formés.',
    '一部の勘定または記帳の形式が不正です。',
  );
  String get errDupId => _t(
    'Two accounts share the same id.',
    'Deux comptes ont le même identifiant.',
    '2つの勘定が同じIDを持っています。',
  );
  String get errUnknownType => _t(
    'An account has an unknown type.',
    'Un compte a un type inconnu.',
    '種類が不明な勘定があります。',
  );
  String errBadDate(String memo) => _t(
    'Entry "$memo" has an invalid date.',
    'L’écriture « $memo » a une date invalide.',
    '記帳「$memo」の日付が不正です。',
  );
  String errUnbalanced(String memo, String date) => _t(
    'Entry "$memo" ($date) is not balanced.',
    'L’écriture « $memo » ($date) n’est pas équilibrée.',
    '記帳「$memo」（$date）は貸借が一致しません。',
  );
  String errUnknownAccount(String memo) => _t(
    'Entry "$memo" uses an unknown account.',
    'L’écriture « $memo » utilise un compte inconnu.',
    '記帳「$memo」に不明な勘定が使われています。',
  );

  // ───────── demo data (seeded in the current language) ─────────
  String demoAccount(String id) => switch (id) {
    'cash' => _t('Cash', 'Espèces', '現金'),
    'bank' => _t('Bank account', 'Compte bancaire', '銀行口座'),
    'wallet' => _t('Mobile wallet', 'Portefeuille mobile', 'モバイルウォレット'),
    'savings' => _t('Savings', 'Épargne', '貯金'),
    'loan' => _t('Money I owe', 'Ce que je dois', '借入金'),
    'opening' => _t('Opening balance', 'Solde d’ouverture', '開始残高'),
    'salary' => _t('Salary', 'Salaire', '給与'),
    'side' => _t('Side work', 'Petits boulots', '副業'),
    'rent' => _t('Rent', 'Loyer', '家賃'),
    'food' => _t('Groceries', 'Courses', '食料品'),
    'transport' => _t('Transport', 'Transport', '交通費'),
    'utilities' => _t('Water & electricity', 'Eau et électricité', '水道光熱費'),
    'phone' => _t('Phone & internet', 'Téléphone et internet', '通信費'),
    'eating' => _t('Eating out', 'Restaurants', '外食'),
    'family' => _t('Family support', 'Aide à la famille', '家族への仕送り'),
    'health' => _t('Health', 'Santé', '医療費'),
    _ => id,
  };
  String demoMemo(String key) => switch (key) {
    'opening' => _t('Opening balances', 'Soldes d’ouverture', '開始残高'),
    'rent' => _t('Monthly rent', 'Loyer du mois', '今月の家賃'),
    'atm' => _t('ATM withdrawal', 'Retrait au distributeur', 'ATMで引き出し'),
    'salary' => _t('Salary', 'Salaire', '給与'),
    'bill' => _t(
      'Electricity & water bill',
      'Facture eau et électricité',
      '電気・水道代',
    ),
    'phone' => _t(
      'Phone & internet plan',
      'Forfait téléphone et internet',
      '通信プラン',
    ),
    'savings' => _t('Move to savings', 'Virement vers l’épargne', '貯金へ移す'),
    'groceries' => _t('Weekly groceries', 'Courses de la semaine', '今週の食料品'),
    'taxi' => _t('Taxi', 'Taxi', 'タクシー'),
    'family' => _t('Sent to family', 'Envoi à la famille', '家族へ送金'),
    'lunch' => _t('Lunch with friends', 'Déjeuner entre amis', '友人とランチ'),
    'topup' => _t('Wallet top-up', 'Recharge du portefeuille', 'ウォレットにチャージ'),
    'repaid' => _t(
      'Repaid brother (part)',
      'Remboursement au frère (partiel)',
      '兄に一部返済',
    ),
    'pharmacy' => _t('Pharmacy', 'Pharmacie', '薬局'),
    'website' => _t('Website job', 'Création de site web', 'ウェブサイト制作'),
    'dinner' => _t('Dinner out', 'Dîner au restaurant', '外で夕食'),
    'borrowed' => _t('Borrowed from brother', 'Emprunt au frère', '兄から借りた'),
    _ => key,
  };
}
