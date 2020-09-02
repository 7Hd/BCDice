# -*- coding: utf-8 -*-
# frozen_string_literal: true

module BCDice
  module GameSystem
    class HuntersMoon < DiceBot
      # ゲームシステムの識別子
      ID = 'HuntersMoon'

      # ゲームシステム名
      NAME = 'ハンターズ・ムーン'

      # ゲームシステム名の読みがな
      SORT_KEY = 'はんたあすむうん'

      # ダイスボットの使い方
      HELP_MESSAGE = <<INFO_MESSAGE_TEXT
・判定
　判定時にクリティカルとファンブルを自動判定します。
・各種表
　・遭遇表　(ET)
　・都市ロケーション表　(CLT)
　・閉所ロケーション表　(SLT)
　・炎熱ロケーション表　(HLT)
　・冷暗ロケーション表　(FLT)
　・部位ダメージ決定表　(DLT)
　・モノビースト行動表　(MAT)
　・異形アビリティー表　(SATx) (xは個数)
　・異形アビリティー表2　(SA2Tx) (xは個数)
　　→表１と表２の振り分けも判定
　・指定特技(社会)表　　(TST)
　・指定特技(頭部)表　　(THT)
　・指定特技(腕部)表　　(TAT)
　・指定特技(胴部)表　　(TBT)
　・指定特技(脚部)表　　(TLT)
　・指定特技(環境)表　　(TET)
　・異形化表　　　　　　(MST)
　・代償表　　　　　　　(ERT)
　・ディフェンス遭遇表1/2/3 (DS1ET/DS2ET/DS3ET)
　・エスケープ遭遇表1/2/3 (EE1ET/EE2ET/EE3ET)
　・エスコート遭遇表1/2/3 (ET1ET/ET2ET/ET3ET)
　・トラッキング遭遇表1/2/3 (TK1ET/TK2ET/TK3ET)
・D66ダイスあり
INFO_MESSAGE_TEXT

      def initialize
        super

        @sortType = 1
        @d66Type = 2
        @fractionType = "roundUp"; # 端数切り上げに設定
      end

      # ゲーム別成功度判定(2D6)
      def check_2D6(total, dice_total, _dice_list, cmp_op, target)
        return '' if target == '?'
        return '' unless cmp_op == :>=

        if dice_total <= 2
          " ＞ ファンブル(モノビースト追加行動+1)"
        elsif dice_total >= 12
          " ＞ スペシャル(変調1つ回復orダメージ+1D6)"
        elsif total >= target
          " ＞ 成功"
        else
          " ＞ 失敗"
        end
      end

      def rollDiceCommand(command)
        string = command.upcase
        output = '1'
        type = ""
        total_n = ""

        case string.upcase

        when /CLT/i
          type = '都市ロケーション'
          output, total_n = hm_city_location_table
        when /SLT/i
          type = '閉所ロケーション'
          output, total_n = hm_small_location_table
        when /HLT/i
          type = '炎熱ロケーション'
          output, total_n = hm_hot_location_table
        when /FLT/i
          type = '冷暗ロケーション'
          output, total_n = hm_freezing_location_table
        when /DLT/i
          type = '部位ダメージ決定'
          output, total_n = hm_hit_location_table

        when /MAT/i
          type = 'モノビースト行動'
          output, total_n = hm_monobeast_action_table

        when /SA(2)?T(\d*)/i
          isType2 = !Regexp.last_match(1).nil?
          count = Regexp.last_match(2).to_i
          count = 1 if count == 0

          type = '異形アビリティー'
          output, total_n = get_strange_ability_table_result(count, isType2)

        when /TST/i
          type = '指定特技(社会)'
          output, total_n = hm_social_skill_table
        when /THT/i
          type = '指定特技(頭部)'
          output, total_n = hm_head_skill_table
        when /TAT/i
          type = '指定特技(腕部)'
          output, total_n = hm_arm_skill_table
        when /TBT/i
          type = '指定特技(胴部)'
          output, total_n = hm_trunk_skill_table
        when /TLT/i
          type = '指定特技(脚部)'
          output, total_n = hm_leg_skill_table
        when /TET/i
          type = '指定特技(環境)'
          output, total_n = hm_environmental_skill_table

        when 'ET'
          type = '遭遇'
          output, total_n = hm_encount_table

        else
          return getTableCommandResult(command, TABLES)
        end

        return output if output == '1'

        output = "#{type}表(#{total_n}) ＞ #{output}"
        return output
      end

      # ** ロケーション表
      def hm_city_location_table
        table = [
          '住宅街/閑静な住宅街。不意打ちに適しているため、ハンターの攻撃判定に+1の修正をつけてもよい。',
          '学校/夜の学校。遮蔽物が多く入り組んだ構造のため、ハンターはブロック判定によって肩代わりしたダメージを1減少してもよい。',
          '駅/人のいない駅。全てのキャラクターがファンブル時に砂利に突っ込んだり伝染に接触しかけることで1D6のダメージを受ける。',
          '高速道路/高速道路の路上。全てのキャラクターが、ファンブル時には走ってきた車に跳ねられて1D6のダメージを受ける。',
          'ビル屋上/高いビルの屋上。ハンターはファンブル時に屋上から落下して強制的に撤退する。命に別状はない',
          '繁華街/にぎやかな繁華街の裏路地。大量の人の気配が近くにあるため、モノビーストが撤退するラウンドが1ラウンド早くなる。決戦フェイズでは特に効果なし。',
        ]
        return get_table_by_1d6(table)
      end

      def hm_small_location_table
        table = [
          '地下倉庫/広々とした倉庫。探してみれば色々なものが転がっている。ハンターは戦闘開始時に好きなアイテムを一つ入手してもよい。',
          '地下鉄/地下鉄の線路上。全てのキャラクターが、ファンブル時にはなぜか走ってくる列車に撥ねられて1D6ダメージを受ける。',
          '地下道/暗いトンネル。車道や照明の落ちた地下街。ハンターは、ファンブル時にアイテムを一つランダムに失くしてしまう。',
          '廃病院/危険な廃物がたくさん落ちているため、誰もここで戦うのは好きではない。キャラクター全員の【モラル】を3点減少してから戦闘を開始する。',
          '下水道/人が２人並べるくらいの幅の下水道。メンテナンス用の明かりしかなく、非常に視界が悪いため、ハンターの攻撃判定に-1の修正がつく。',
          '都市の底/都市の全てのゴミが流れ着く場所。広い空洞にゴミが敷き詰められている。この敵対的な環境では、ハンターの攻撃判定に-1の修正がつく。さらにハンターは攻撃失敗時に2ダメージを受ける。',
        ]
        return get_table_by_1d6(table)
      end

      def hm_hot_location_table
        table = [
          '温室/植物が栽培されている熱く湿った場所。生命に満ち溢れた様子は、戦闘開始時にハンターの【モラル】を1点増加する。',
          '調理場/調理器具があちこちに放置された、アクションには多大なリスクをともなう場所。全てのキャラクターは、ファンブル時に良くない場所に手をついたり刃物のラックをひっくり返して1D6ダメージを受ける。',
          'ボイラー室/モノビーストは蒸気機関の周囲を好む傾向があるが、ここはうるさくて気が散るうえに暑い。全てのキャラクターは、感情属性が「怒り」の場合、全てのアビリティの反動が1増加する。',
          '機関室/何らかの工場。入り組みすぎて周りを見通せないうえ、配置がわからず出たとこ勝負を強いられる。キャラクター全員が戦闘開始時に「妨害」の変調を発動する。',
          '火事場/事故現場なのかモノビーストの仕業か、あたりは激しく燃え盛っている。ハンターはファンブル時に「炎上」の変調を発動する。',
          '製鉄所/無人ながら稼働中の製鉄所。安全対策が不十分で、溶けた金属の周囲まで近づくことが可能だ。ハンターは毎ラウンド終了時に《耐熱》で行為判定をし、これに失敗すると「炎上」の変調を発動する。',
        ]
        return get_table_by_1d6(table)
      end

      def hm_freezing_location_table
        table = [
          '冷凍保管室/食品が氷漬けにされている場所。ここではモノビーストは氷に覆われてしまう。モノビーストは戦闘開始時に「捕縛」の変調を発動する。',
          '墓地/死んだ人々が眠る場所。ここで激しいアクションを行うことは冒涜的だ。全てのキャラクターは感情属性が恐怖の場合、全てのアビリティの反動が１増加する。',
          '魚市場/発泡スチロールの箱に鮮魚と氷が詰まり、コンクリートの床は濡れていて滑りやすい。ハンターはファンブル時に転んで1D6ダメージを受ける。',
          '博物館/すっかり静まり返った博物館で、モノビーストは動物の剥製の間に潜んでいる。紛らわしい展示物だらけであるため、ハンターは攻撃判定に-1の修正を受ける。',
          '空き地/寒風吹きすさぶ空き地。長くいると凍えてしまいそうだ。ハンターはファンブル時に身体がかじかみ、「重傷」の変調を発動する。',
          '氷室/氷で満たされた洞窟。こんな場所が都市にあったとは信じがたいが、とにかくひどく寒い。ハンターは毎ラウンド終了時に《耐寒》で判定し、失敗すると「重傷」の変調を発動する。',
        ]
        return get_table_by_1d6(table)
      end

      # ** 遭遇表
      def hm_encount_table
        table = [
          '獲物/恐怖/あなたはモノビーストの獲物として追い回される。満月の夜でないと傷を負わせることができない怪物相手に、あなたは逃げ回るしかない。',
          '暗闇/恐怖/あの獣は暗闇の中から現れ、暗闇の中へ消えていった。どんなに振り払おうとしても、あの恐ろしい姿の記憶から逃れられない。',
          '依頼/怒り/あなたはモノビーストの被害者の関係者、あるいはハンターや魔術師の組織から、モノビーストを倒す依頼を受けた。',
          '気配/恐怖/街の気配がどこかおかしい。視線を感じたり、物音が聞こえたり・・・だが、獣の姿を捉えることはできない。漠然とした恐怖があなたの心をむしばむ。',
          '現場/怒り/あなたはモノビーストが獲物を捕食した現場を発見した。派手な血の跡が目に焼きつく。こんなことをする奴を生かしてはおけない。',
          '賭博/怒り/あなたの今回の獲物は、最近ハンターの間で話題になっているモノビーストだ。次の満月の夜にあいつを倒せるか、あなたは他のハンターと賭けをした。',
        ]
        return get_table_by_1d6(table)
      end

      # **
      def hm_monobeast_action_table
        table = [
          '社会/モノビーストは時間をかけて逃げ続けることで、ダメージを回復しようとしているようだ。部位ダメージを自由に一つ回復する。部位ダメージを受けていない場合、【モラル】が1D6回復する。',
          '頭部/モノビーストはハンターを撒こうとしている。次の戦闘が日暮れ、もしくは真夜中である場合、モノビーストは１ラウンド少ないラウンドで撤退する。次の戦闘が夜明けである場合、【モラル】が2D6増加する。',
          '腕部/モノビーストは若い犠牲者を選んで捕食しようとしている。どうやら力を増そうとしているらしい。セッション終了までモノビーストの攻撃によるダメージは+1の修正がつく。',
          '胴部/モノビーストは別のハンターと遭遇し、それを食べて新しいアビリティを手に入れる！　ランダムに異形アビリティを一つ決定し、修得する。',
          '脚部/モノビーストはハンターを特定の場所に誘導しているようだ。ロケーション表を振り、次の戦闘のロケーションを変更する。そのロケーションで次の戦闘が始まった場合、モノビーストは最初のラウンドに追加行動を１回得る。',
          '環境/モノビーストは移動中に人間の団体と遭遇し、食い散らかす。たらふく食ったモノビーストは【モラル】を3D6点増加させる',
        ]
        return get_table_by_1d6(table)
      end

      # ** 部位ダメージ決定表
      def hm_hit_location_table
        table = [
          '脳',
          '利き腕',
          '利き脚',
          '消化器',
          '感覚器',
          '攻撃したキャラクターの任意の部分',
          '口',
          '呼吸器',
          '逆脚',
          '逆腕',
          '心臓',
        ]
        return get_table_by_2d6(table)
      end

      def getStrangeAbilityTable1; end

      # ** 異形アビリティー表
      def get_strange_ability_table_result(count, isType2)
        output = ''
        dice = ''

        table1 = get_strange_ability_table_1
        table2 = get_strange_ability_table_2

        count.times do |i|
          if i != 0
            output += "/"
            dice += ","
          end

          table = table1

          if isType2
            number, = roll(1, 6)
            index = (number.odd? ? 0 : 1)

            table = [table1, table2][index]
            dice += "#{number}-"
            output += "[表#{index + 1}]"
          end

          ability, indexText = get_table_by_d66(table)
          next if  ability == '1'

          output += ability.to_s
          dice += indexText
        end

        return '1', dice if output.empty?

        return output, dice
      end

      def get_strange_ability_table_1
        table = %w{
          大牙
          大鎌
          針山
          大鋏
          吸血根
          巨大化
          瘴気
          火炎放射
          鑢
          ドリル
          絶叫
          粘液噴射
          潤滑液
          皮膚装甲
          器官生成
          翼
          四肢複製
          分解
          異言
          閃光
          冷気
          悪臭
          化膿歯
          気嚢
          触手
          肉瘤
          暗視
          邪視
          超振動
          酸分泌
          結晶化
          裏腹
          融合
          嘔吐
          腐敗
          変色
        }
        return table
      end

      def get_strange_ability_table_2
        table = %w{
          電撃
          障壁
          追加肢
          破裂球
          死病
          ソナー
          未来視
          寄生体
          再構築
          分身
          大角
          鉄塊
          硬質化
          生命力吸収
          鬼火
          金縛り
          排出口
          金属化
          鋼鱗
          神経接合
          光翼
          環境適応
          消化剤
          プロペラ
          血栓
          骨槍
          回転
          怒髪
          煙幕
          脂肪層
          逆棘
          偽頭
          赤化
          発条
          凶運
          巨砲
        }
        return table
      end

      # ** 指定特技ランダム決定(社会)
      def hm_social_skill_table
        table = [
          '怯える',
          '考えない',
          '話す',
          '黙る',
          '売る',
          '伝える',
          '作る',
          '憶える',
          '脅す',
          '騙す',
          '怒る',
        ]
        return get_table_by_2d6(table)
      end

      # ** 指定特技ランダム決定(頭部)
      def hm_head_skill_table
        table = [
          '聴く',
          '感覚器',
          '見つける',
          '反応',
          '閃く',
          '脳',
          '考える',
          '予感',
          '叫ぶ',
          '口',
          '噛む',
        ]
        return get_table_by_2d6(table)
      end

      # ** 指定特技ランダム決定(腕部)
      def hm_arm_skill_table
        table = [
          '操作',
          '殴る',
          '斬る',
          '利き腕',
          '撃つ',
          '掴む',
          '投げる',
          '逆腕',
          '刺す',
          '振る',
          '締める',
        ]
        return get_table_by_2d6(table)
      end

      # ** 指定特技ランダム決定(胴部)
      def hm_trunk_skill_table
        table = [
          '塞ぐ',
          '呼吸器',
          '止める',
          '動かない',
          '受ける',
          '心臓',
          '逸らす',
          'かわす',
          '落ちる',
          '消化器',
          '耐える',
        ]
        return get_table_by_2d6(table)
      end

      # ** 指定特技ランダム決定(脚部)
      def hm_leg_skill_table
        table = [
          '迫る',
          '走る',
          '蹴る',
          '利き脚',
          '跳ぶ',
          '仕掛ける',
          'しゃがむ',
          '逆脚',
          '滑る',
          '踏む',
          '歩く',
        ]
        return get_table_by_2d6(table)
      end

      # ** 指定特技ランダム決定(環境)
      def hm_environmental_skill_table
        table = [
          '耐熱',
          '休む',
          '待つ',
          '捕らえる',
          '隠れる',
          '追う',
          'バランス',
          '現れる',
          '追い込む',
          '休まない',
          '耐寒',
        ]
        return get_table_by_2d6(table)
      end

      TABLES =
        {

          'DS1ET' => {
            :name => "ディフェンス遭遇表1st",
            :type => '1d6',
            :table => <<'TABLE_TEXT_END'
状況　あなたはモノビーストに追い詰められるまま建物に閉じこもる。とりあえず、夜は建物の中を威勢よく動き回り、相手を威嚇しなければ。\n指定特技　《脅す/社会１０》\n成功  建物の外から隙を窺うモノビーストをきつく睨みつける。感情属性を「怒り」に設定。\n失敗 ヤツはあなたを嘲笑うかのように建物の中に出現を繰り返す。感情属性を「恐怖」に設定。
状況　廃墟となって久しいこの建物には、ハンターがいた形跡がある。山と仕掛けられれたトラップに気をつけながら探索を続けるが……。\n指定特技　《見つける/頭部４》\n成功  裏口で格闘の跡を見つける。何かの事情で、出たところを襲われたのだ。感情属性を「怒り」に設定。\n失敗 トラップに引っかかり怪我をする。こんなところに立て篭もって大丈夫か？感情属性を「恐怖」に設定。
状況　あなたの友人のハンターは脚に重傷を負って動けない。しばらくこの建物の中で回復を待つしかなさそうだが、彼は足手まといになるのを嫌って戸外で死のうとする。止めよう。\n指定特技　《逆腕/腕部９》\n成功  必死に引き止めた戸口の向こうで、笑うような息遣いが聞こえた。感情属性を「恐怖」に設定。\n失敗 制止を振り切って出て行った友人は死んだ。感情属性を「怒り」に設定。
状況　エレベーターが落ちた。不運な同行者と一緒に、誰も来ないビルの地下に閉じ込められる。落ちる寸前、天井で聞いた音は間違いなくヤツのものだ。\n指定特技　《落ちる/胴部１０》\n成功  怪我もなく落下を切り抜けたが、同行者を連れて出て行く手段がない。感情属性を「恐怖」に設定。\n失敗 ショックでパニックに陥った同行者はあなたを責め立てる。感情属性を「怒り」に設定。
状況　今回の相手は光が強い環境では消散能力を使えないようだ。あなたは建物中を駆けまわって、照明をつけてまわる。\n指定特技　《逆脚/脚部９》\n成功  なんとか防御体制は整ったが、送電線が気に掛かる。感情属性を「恐怖」に設定。\n失敗 間に合わない。建物の半分の送電が絶たれ、あなたは狭い部屋に閉じこもることになる。感情属性を「怒り」に設定。
状況　金がないのか脚が遅いのか、あなたは逃げ回ることができない。唯一の選択肢は、あらかじめ作っておいた隠れ家に潜むことだ。\n指定特技　《隠れる/環境６》\n成功  とりあえず、うまく隠れることができたようだ。感情属性を「怒り」に設定。\n失敗 隠れ家の装備は、すでに破壊されていた。感情属性を「恐怖」に設定。
TABLE_TEXT_END
          },

          'DS2ET' => {
            :name => "ディフェンス遭遇表2nd",
            :type => '1d6',
            :table => <<'TABLE_TEXT_END'
状況　建物の構造を把握し、憶えこむことで、満月の晩までの生存率は大きく向上するだろう。あなたは眠い目を擦りつつ、昼間も探索を続ける。\n指定特技　《覚える/社会９》\n成功  やつを迎え撃つ自信が湧いてきた。【モラル】が２点増加する。\n失敗 眠くて全然覚えられない。体力を消耗してしまう。「重傷」の変調を発動する。
状況　夜が来るたびに退屈な見張りが始まる。代わり映えのしない景色を眺めていると、モノビーストの襲撃に対する反応速度を保つのは難しい。\n指定特技　《反応/頭部５》\n成功  襲われたが難なくやり過ごす。感情属性を任意に変更できる。\n失敗 後ろに実体化したモノビーストに気付くのが遅れ、痛い代償を払うことになった。アイテムを任意に１つ失う。
状況　モノビーストが実体化するにはある程度のスペースが必要だ。あなたは部屋の中にワイアを張り巡らし、空間を細分することで攻撃を防ぐ。\n指定特技　《斬る/腕部４》\n成功  モノビーストはあなたを警戒するあまり動きが鈍り、「妨害」の変調を発動する。\n失敗 動きづらくなっただけで襲撃が無い……【モラル】が２点減少する。
状況　建物の中にあるものを何でも積んでバリケードを作る。霧になる相手には効果が薄いかもしれないが。移動を制限できるぶん、ないよりマシだ。\n指定特技　《心臓/胴部７》\n成功  この場所は満月の夜にヤツを追い詰める場所としても使えるだろう。【ネット】を入手する。\n失敗 堂々と壁を破って侵入された……撃退はしたが、自らのあまりの愚かさに「動転」してしまう。
状況　自作の罠を建物のあちこちに配置する。うまくいけば、ヤツを退散させる程度の役には立つだろう。\n指定特技　《仕掛ける/脚部７》\n成功  うとうとしていた夜更け、悲鳴とともに逃げ出すモノビーストの移動音で目を覚ます。【モラル】が２点増加する。\n失敗 まるで意に介さないモノビーストに追い回されトラウマを負う。このセッションが終了するまで妨害判定にマイナス２の修正がつく。
状況　やばい。寒い。空調の故障か季節が悪いのか、モノビーストと勝負する前に凍死してしまいそうだ。\n指定特技　《耐寒/環境１２》\n成功  あなたは苦難を耐え切り、自信を身につける。次の遭遇表の行為判定にプラス２の修正がつく。\n失敗 我慢できなくなってアイテムを燃やして暖を取る。ランダムにアイテムを１つ失う。
TABLE_TEXT_END
          },

          'DS3ET' => {
            :name => "ディフェンス遭遇表3rd",
            :type => '1d6',
            :table => <<'TABLE_TEXT_END'
状況　時は来た。問題は立て篭もっていた建物から出て行くタイミングだが、囮を使うことでモノビーストを騙し、安全に出ていけるかもしれない。\n指定特技　《騙す/社会１１》\n成功  相手の不意を打った！次に行う行為判定にプラス２の修正がつく。\n失敗 逆に騙され、日が沈みきっていない早い時間に飛び出してしまう。モノビーストは夕暮れの戦闘で変調を発動しない。
状況　長い潜伏期間を過ごした建物を振り返り、その上に出ている満月を見つめる。この夜でケリがつく。そんな予感があなたの胸を満たす。\n指定特技　《予感/頭部９》\n成功  どんな形で決着がつくか、脳裏にイメージが浮かぶ。感情属性を任意に変更できる。\n失敗 不安があなたの心を締め付ける。【感情】が２点増加する。
状況　さて満月の夜だ。幸い投擲武器が豊富な場所にいるわけで、外にいるモノビーストに、すこし先制攻撃をさせてもらおう。\n指定特技　《投げる/腕部８》\n成功  投げたものがばらばらと当たり、相手はいらついている。モノビーストの【感情】が２点増加する。\n失敗 物を投げるのが楽しくなってしまい、狩りに出遅れる。夕暮れの追跡フェイズで行う判定にマイナス２の修正がつく。
状況　ついに相手と対等になる夜だ、と意気揚々と外に出たあなたを、上空からの不意打ちが襲う。もちろん、ヤツはあなたを待ち構えていたのだ。\n指定特技　《かわす/胴部９》\n成功  待ち伏せくらいは予想のうちだ。【モラル】が２点増加する。\n失敗 まともに食らったが、アイテムのおかげで命拾いする。持っていれば【医療キット】を失う。
状況　狭い所に閉じこもりきりで、これまで走り出したくてうずうずしていた脚に気合を入れる。今夜はどこまでも走っていけそうだ。\n指定特技　《走る/脚部３》\n成功  いい感じに体が軽い。このセッションの間、ロケーション変更判定にプラス２の修正がつく。\n失敗 いきなり脚をくじく。せめて準備運動はするべきだったかもしれない。【モラル】が４点減少する。
状況　こんなこともあろうかと、あなたは秘密の出口を作っておいたのだ。予想もしない場所から出てくるあなたに、ヤツは恐れおののくに違いない。\n指定特技　《現れる/環境９》\n成功  かなり効果的に敵の虚をついた。モノビーストは次に得る追加行動を１回失う。\n失敗 秘密の出口はすでに破壊されていた……とぼとぼと戻る。【感情】が４点増加する。
TABLE_TEXT_END
          },

          'EE1ET' => {
            :name => "エスケープ遭遇表1st",
            :type => '1d6',
            :table => <<'TABLE_TEXT_END'
状況　あなたは見た。夜の街を闊歩し、気ままに人を食い散らかす怪物を。すぐ近くまで追っている危険を、大事な人に伝えなければならない。\n指定特技　《伝える/社会７》\n成功  最近疲れてるんじゃない？と返され絶望する。感情属性を「恐怖」に設定。\n失敗 病院に連れて行かれた。感情属性を「怒り」に設定。
状況　夜道で角を曲がったら怪物がいた。しかもばっちり目が合った。不運を嘆く暇もなく、ヤツは襲い掛かってくる。速く逃げないと！\n指定特技　《反応/頭部５》\n成功  逃げられたが理不尽さに怒りがこみ上げる。感情属性を「怒り」に設定。\n失敗 頭を食いちぎられる寸前で危うくも逃げ出す。感情属性を「恐怖」に設定。
状況　買い物帰り、夜道を並んで歩いていた友人の上半身がいきなり消えた。喰われたのだ。今すぐヤツに買い物袋を投げつけろ。\n指定特技　《投げる/腕部８》\n成功  無駄になった食材と友人のため、感情属性を「怒り」に設定。\n失敗 散らばった買い物に足をとられて転び、捕食シーンをまざまざと見せつけられる。感情属性を「恐怖」に設定。
状況　音がする。床を踏みしめる音。固い何かが触れ合う音。吐く息、吸う息、唸り声、悲鳴。何も聞こえないふりをしなければ、これは本当にあることになってしまう。\n指定特技　《耐える/胴部１２》\n成功 パニックを起こさずに冷静に検討した結果、逃げなければならないと結論が出る。 感情属性を「怒り」に設定。\n失敗 パニックに陥りやみくもに逃げ出す。感情属性を「恐怖」に設定。
状況　この子を頼む、と叫んで幼児を放り投げたハンターは、目の前でモノビーストに食われて死んだ。ヤツは明らかにこの子を狙っているし、まずは受け止める必要がある。\n指定特技　《跳ぶ/脚部６》\n成功  うまくキャッチ！この子を抱えて武器を振り回すわけにはいかない、まずは逃げよう。感情属性を「怒り」に設定。\n失敗 落とした……かと思ったよ。いや危ない危ない。感情属性を「恐怖」に設定。
状況　きつい一日だった。下を向いて歩いていたからだろう。すぐ横にモノビーストがいるのに気付かなかった。あまりに近すぎて動揺し、足がもつれる。\n指定特技　《バランス/環境８》\n成功  見えていることは気づかれていない……感情属性を「恐怖」に設定。\n失敗 モノビーストと接触し、一晩中追い回される。感情属性を「怒り」に設定。
TABLE_TEXT_END
          },

          'EE2ET' => {
            :name => "エスケープ遭遇表2nd",
            :type => '1d6',
            :table => <<'TABLE_TEXT_END'
状況　モノビーストから逃げるあなたの目の前に、パトロール中の警察官が！夜中に必死な顔で走っている理由をひねり出せ。\n指定特技　《騙す/社会１１》\n成功  うまく言い抜けた。【モラル】が１点増加する。\n失敗 質問されているうちにモノビーストが追いつき、警察官を食い殺す。感情属性が反転する。
状況　あの夜以来、毎晩モノビーストに追い回されている。完全に目をつけられたようだ。この状況から抜け出すために、あなたは眠い目を擦りながら昼間も考え続ける。\n指定特技　《考える/頭部８》\n成功  ヤツの能力について整理できた。このセッション中、弱点調査判定にプラス１の修正がつく。\n失敗 眠くて何も考えられない。感情属性を「恐怖」に設定。
状況　車で街から逃走しようとしたところ、ひどい渋滞に引っかかって夜になり、案の定襲撃があって車をひっくり返された。武器になりそうなのは発炎筒だけだ……。\n指定特技　《撃つ/腕部６》\n成功  なんとか撃退成功。駆けつけたJAFの人から【医療キット】を入手できる。\n失敗 まるで効かない。車に積んであった装備を諦め、街に逃げ戻る。【感情】が２点増加する。
状況　密閉した部屋に閉じこもり、隙間がないこと、ヤツが諦めてくれることを神に祈る。どんな神であれ、心から祈れば答えがあるかもしれない。\n指定特技　《心臓/胴部７》\n成功  徴が現れた！【勝利のお守り】を入手できる。\n失敗 何も起こらない。【感情】が２点増加する。
状況　モノビーストには縄張りがある。まっすぐ歩き続ければ、いつかその外に出られるはずだ。\n指定特技　《歩く/脚部１２》\n成功  行く先々で橋は落ち、停電は発生し、公共交通機関は止まっている。感情属性が反転する。\n失敗 いつのまにか迷子になってしまっている。「動転」の変調を発動する。
状況　モノビーストから逃げ続けるなか、ヤツと戦う人間を見かける。あの人を追いかけられれば、協力できるかもしれない。\n指定特技　《追う/環境７》\n成功  任意の他のハンターと出会う。【モラル】が３点増加する。\n失敗 ダメだ、見失ってしまった。【感情】が２点増加する。
TABLE_TEXT_END
          },

          'EE3ET' => {
            :name => "エスケープ遭遇表3rd",
            :type => '1d6',
            :table => <<'TABLE_TEXT_END'
状況　考え付く限りのルートと手段を使って逃げ続けたあなたがたどりついた袋小路には、モノビーストが待っていた。もう何も考えず、必死に戦うしかないようだ。\n指定特技　《考えない/社会３》\n成功  思考停止成功！感情属性を好きに変更できる。\n失敗 別のハンターが倒してくれるかもしれないと考えて気後れする。夕暮れの戦闘フェイズでは自分が行う全ての攻撃判定にマイナス１の修正がつく。
状況　いつまでも逃げ続けるわけにはいかない。体力的にも限界が近づいている。この状況を打開する方法を見つけなければならない。\n指定特技　《見つける/頭部４》\n成功  モノビーストを殺せば逃げなくてもよくなると発見。【モラル】が２点増加する。\n失敗 どうも戦うしかないようだ。感情属性が反転する。
状況　逃げるあなたの巻き添えで、また人が殺される。こんなのはもうたくさんだ。逃げればそのうち何とかなるという考えを振り払わねばならない。\n指定特技　《振る/腕部１１》\n成功  弱気な考えを振り切った。この決意にあたるものとして【興奮剤】を入手することができる。\n失敗 勝てる気がしない。【モラル】が２点減少する。
状況　空を見上げれば満月が浮かんでいる。あなたの実力をもってすれば、今ならモノビーストと戦える。今こそ逃げるのを止めて戦う時なのだ。\n指定特技　《止める/胴部３》\n成功  【激情】を１点得る。ただしこのセッションで【感情】が３０になっても【激情】を得られない。\n失敗 明らかに怯えた様子のあなたを見て、モノビーストの【モラル】が３点増加する。
状況　走ってどこまでも逃げていく。順調にいけば振りきれただろうが、ぬかるみ、血、それに類する何かによってあなたの足は滑り、モノビーストに追いつかれてしまう。覚悟を決める時が来たようだ。\n指定特技　《滑る/脚部１０》\n成功  速度を利用していい位置に。夕暮れの戦闘フェイズでは先制判定を振らず、成功にすることができる。\n失敗 滑り方がよくなかった。「妨害」の変調を発動する。
状況　ハンターが集まり、モノビーストに戦いを挑んでいる。今なら難なく逃げ切れるはずだ……しかし、彼らを見捨てることなどできない。あなたは来た道を引き返していく。\n指定特技　《現れる/環境９》\n成功  突然現れた増援に、モノビーストの【モラル】が２点減少する。\n失敗 逃げる途中で落し物。ランダムにアイテムを１つ失う。
TABLE_TEXT_END
          },

          'ERT' => {
            :name => "代償表",
            :type => '1d6',
            :table => <<'TABLE_TEXT_END'
評判の失墜\n 次のセッションで登場するハンターキラーの合計レベルが1上昇します。\nこの代償を持つハンターがセッションに複数参加している場合、効果の累積はしません。
闇夜の饗宴\n 次のセッションに登場するモノビーストのランクが1上昇します。\nこの代償を持つハンターがセッションに複数参加してる場合、効果の累積はしません。
特技の忘却\n 習得した特技の中から１つを任意に選び、使用不能にします。\n次にモノビーストを殺したタイミングで、この特技は使用可能になります。\nこの代償を複数回得ることで特技が0個になったハンターは、判定および生活が不可能になって死亡します。最終判定すらできません。
能力の不調\n 習得している汎用または武器アビリティの中から1つを任意に選び、使用不能にします。\n次にモノビーストを殺したタイミングで、このアビリティは使用可能になります。\nこの代償を複数回得ることでアビリティを全て失ったハンターは、戦闘不能となり引退します。
自信の喪失\n 【モラル】基準値が1減少します。この減少は、次にモノビーストを殺したタイミングで元に戻ります。\nこの代償を複数回得ることで【モラル】基準値がマイナスになったハンターは、気力を完全に失い引退します。
引退の決意\n 異形アビリティを全て失います。この代償で失った異形アビリティを回復することはできません。\nこの代償を続けて2回得た段階でハンターはモノビーストとの接触を失い、視認できなくなります。つまり強制的に引退です。
TABLE_TEXT_END
          },

          'ET1ET' => {
            :name => "エスコート遭遇表1st",
            :type => '1d6',
            :table => <<'TABLE_TEXT_END'
状況　追われる彼/彼女があなたの前に現れたのは満月の夜。獲物に集中しているモノビーストを攻撃するのは容易いことだったが……。\n指定特技　《怯える/社会２》\n成功  今戦えば彼/彼女は死ぬと思いとどまって一緒に逃げる。感情属性を「恐怖」に設定。\n失敗 モノビーストを倒しきれず、彼/彼女は一生残る傷を負う。感情属性を「怒り」に設定。
状況　彼/彼女は、窓を破りながらあなたの家に飛び込んできた。モノビーストは見えているようだが、あなたの渋い顔は見えていないようだ。\n指定特技　《反応/頭部５》\n成功  とっさに反応し、モノビーストを攻撃して追い払う。感情属性を「怒り」に設定。\n失敗 あまりの唐突さに襲い来るモノビーストへの対応が遅れ、部屋を放棄して逃げることになる。感情属性を「恐怖」に設定。
状況　夜、あなたの隣を歩いている彼/彼女が不意打ちを受ける。どうやら獲物として選ばれたようだが、腕を引いて助けることはできるだろうか？\n指定特技　《利き腕/腕部５》\n成功  紙一重で攻撃を避けさせることに成功。感情属性を「恐怖」に設定。\n失敗 かばう形になり手傷を負う。感情属性を「怒り」に設定。
状況　彼/彼女はどう見てもハンターとしては無能だが、あるモノビーストを倒す必要があるのだという。助力を頼まれたあなたは……。\n指定特技　《止める/頭部４》\n成功  その場の勢いで代わりに戦うことになってしまった。感情属性を「恐怖」に設定。\n失敗 説得するが失敗。彼/彼女は一人で夜の街へ飛び出す。感情属性を「怒り」に設定。
状況　彼/彼女は子供で、子供を餌として好む怪物に追われていて、助けてやれる人はあなたしかいない。安心させるために目の高さを合わせてみよう。\n指定特技　《しゃがむ/脚部８》\n成功  彼/彼女はよくあなたに懐き、それを狙うモノビーストへの感情属性は「怒り」になる。\n失敗 全然ダメ。護衛を放り出すわけにもいかないが先行き不安だ。感情属性を「恐怖」に設定。
状況　あなたはモノビーストの標的となった彼/彼女を数カ月にわたって守り続けている。逃避行のなか、気が休まるのは日が高いうちだけだ。\n指定特技　《休む/環境３》\n成功 よく休み気力は充分だ。今度の満月の夜に、この逃避行を終わらせる。感情属性を「怒り」に設定。 \n失敗 ちょっとした暗がりにヤツが潜んでいる気がしてならない。まるで休めず、感情属性を「恐怖」に設定。
TABLE_TEXT_END
          },

          'ET2ET' => {
            :name => "エスコート遭遇表2nd",
            :type => '1d6',
            :table => <<'TABLE_TEXT_END'
状況　彼/彼女は怪物に狙われる日々に憔悴している。モノビーストは狙いを変えたとか、もう死んだとか、元気付けるようなことを言わなくては。\n指定特技　《騙す/社会１１》\n成功  一時しのぎの嘘だが元気な笑顔が見られる。【勝利のお守り】として記憶に刻んでおいてもよい。\n失敗 あなたの下手な嘘は彼/彼女を「動転」させる。あなたも影響を受けて同じ変調を発動する。
状況　彼/彼女は執拗に狙われる理由を知りたがっている。考えてみよう。もしかしたら、戦わずにすむかもしれない。\n指定特技　《考える/頭部８》\n成功  モノビーストは彼/彼女と似たタイプの人間を殺してきているようだ。このセッション中、習性調査判定にプラス１の修正がつく。\n失敗 全然分からない。【感情】が２点増加する。
状況　彼/彼女はあなたの献身的な姿に罪悪感を覚え、人知れず姿を消し、モノビーストに殺されることであなたの苦労を終わらせようとする。\n指定特技　《掴む/腕部７》\n成功  間一髪のところで掴まえた。感情属性を反転させる。\n失敗 あなたの手は届かない。行方不明になった彼/彼女を探すことで疲労困憊したあなたは「妨害」の変調を発動する。
状況　何日も二人で過ごすうち、あなたの彼/彼女の間には愛情のようなものが芽生え始める。この気持ちは果たして本物だろうか？\n指定特技　《落ちる/胴部１０》\n成功  真実の愛を発見したあなたの【モラル】は６点上昇する。\n失敗 ハンターに愛はいらない。感情属性を任意に変更できる。
状況　不意をうたれた。モノビーストの襲撃から逃れるためには、彼/彼女を抱えて跳ぶしかない\n指定特技　《跳ぶ/脚部６》\n成功  危ういジャンプだったが何とかなった。【モラル】が２点増加する。\n失敗 彼/彼女を放り出し怒られる。釈然とせず【感情】が２点増加する。
状況　あなたは眠らない。彼/彼女をモノビーストの牙にかけるわけにはいかないのだ。しかし、これをいつまで続けることができるのか？\n指定特技　《休まない/環境１１》\n成功  疲労が溜まっていく……あなたは「重傷」の変調を発動する。\n失敗 いつのまにか眠ってしまっていたあなたに毛布がかけられている。幸い襲撃はなかったようだ。【モラル】が２点増加する。
TABLE_TEXT_END
          },

          'ET3ET' => {
            :name => "エスコート遭遇表3rd",
            :type => '1d6',
            :table => <<'TABLE_TEXT_END'
状況　もうすぐ満月が昇る。あなたと彼/彼女は、モノビーストを倒した後に何をするか話しあう。希望の持てる未来のヴィジョンを作れただろうか？\n指定特技　《作る/社会８》\n成功  待ち受ける未来に対して任意に感情属性を変更することができる。\n失敗 特にすることがないような……やけになって【感情】が２点増加する。
状況　あと数日で満月だというのに、彼/彼女はモノビーストに重傷を負わされ、死ぬ。あなたは微かな声で囁かれる最後の言葉を聞き取ろうとする。\n指定特技　《聴く/頭部２》\n成功  【モラル】が６点増加する。\n失敗 意味のある言葉は何も聴きとれない。失意に沈んだあなたはランダムな頭部カテゴリの特技１つが使用不可能になる。
状況　やっと分かった。彼/彼女が肌身離さず持っていたアイテムが狙われる原因だったのだ。あなたは彼/彼女に、そのアイテムをこちらに投げ渡すように頼む。\n指定特技　《投げる/腕部８》\n成功 うまく投げてもらう。【幸運のお守り】を入手できる。\n失敗 あなたはアイテムを取り落とし、微妙な空気がただよう。【感情】が２点増加する。
状況　あなたは夜の街を、彼/彼女の手を引いて駆け抜ける。もう少しで安全な場所につく。そうすれば、あなただけが戻って戦うことができる。\n指定特技　《心臓/胴部７》\n成功  これで彼/彼女の身は安全だ。このセッション中、あなたの【モラル】基準値は１点増加する。\n失敗 息切れ、および時間切れ。狩りの時間だ。ただしあなたの【モラル】は３点減少している。
状況　満月を見上げながら、二人でこれまで踏みしめてきた道を振り返る。背後にモノビーストがいることは分かっている。しかし、もはや二人とも恐れはない……だろうか？\n指定特技　《踏む/脚部１１》\n成功  彼/彼女は狩りの間あなたについていき、一度だけ【医療キット】に相当する応援をしてくれる。\n失敗 いつのまにか彼/彼女が逃げ出していることに気付く。「動転」の変調を発動する。
状況　逃避行がクライマックスに近づくにつれ、二人の間の緊張感は耐え難いほどに高まる。このままでは恋に落ちてしまいそうだが、どうしたものだろうか。\n指定特技　《耐熱/環境２》\n成功  胸の熱い気持ちを押さえ込む。感情属性を任意に変更できる。\n失敗 彼/彼女のために頑張ろう。このセッション中、練習判定にプラス１の修正がつく。
TABLE_TEXT_END
          },

          'MST' => {
            :name => "異形化表",
            :type => '1d6',
            :table => <<'TABLE_TEXT_END'
【感情】が2増加する。
【感情】が4増加する。
【感情】が6増加する。
【感情】が6増加する。部位ダメージを受ける。
【感情】が6増加する。異形アビリティをランダムに1つ失う。\n異形アビリティが1つもなければ部位ダメージを受ける。
【感情】が6増加する。部位ダメージを2回受ける。
TABLE_TEXT_END
          },

          'TK1ET' => {
            :name => "トラッキング遭遇表1st",
            :type => '1d6',
            :table => <<'TABLE_TEXT_END'
状況　あなたは隠れ場所に潜みながらモノビーストが獲物…あなたの大切な誰かを貪るのを見ている。満月の夜は遠く、まだ奴を仕留める事は出来ない。\n指定特技　《黙る/社会５》\n成功 押さえ込んだ怒りが膨れ上がる。感情属性を「怒り」に設定。 \n失敗 思わず声を上げてしまい、無敵のモノビーストに手酷い傷を負わされる。感情属性を「恐怖」に設定。
状況　すばらしい味だった。前の満月の晩に捕り逃した奴の血は、まさに超常的な美味。あの味を空気の中にまで感じ取ることができるようだ。\n指定特技　《口/頭部１１》 \n成功 神々しい味を完璧にイメージできた。感情属性を「恐怖」に設定。\n失敗 待ちきれなくて口の中を噛む。感情属性を「怒り」に設定。
状況　夜、屋根の上。あなたはモノビーストが人家に忍び込まないよう牽制している。屋根はもともと走りまわるようにはできていないのだが。\n指定特技　《掴む/腕部７》\n成功 屋根の縁を掴んで落下を免れる。感情属性を「怒り」に設定。\n失敗 屋根から落ちてひどい目にあう。感情属性を「恐怖」に設定。
状況　数カ月ぶりに獲物が現れたというのに、友人が満月の夜に予定を入れようとしてくる。合コンの人数が足りないらしいのだが、そんなの知るか。\n指定特技　《逸らす/胴部８》\n成功 うまく言い逃れたが苛々する。待ちきれなくて口の中を噛む。感情属性を「怒り」に設定。\n失敗　狩りのあとで顔を出す約束をしてしまう。普通の日常感覚という奴が蘇り、感情属性を「恐怖」に設定。
状況　見間違えようもないモノビーストの足跡をたどり、あなたはこの街まで来た。問題はその足跡が鍵のかかったドアの向こうに続いていることだ。うまく蹴り開けられるだろうか？\n指定特技　《蹴る/脚部４》\n成功 ドアは開き、あなたはその向こうにあるものを見た。感情属性を「恐怖」に設定。\n失敗　足がドアを突き抜けたが開かない。脱出は手間だった。感情属性を「怒り」に設定。
状況　悪天候のなか、あなたはモノビーストの出現を待ち続ける。奴を狩るために、色々なものを犠牲にしてきたのだ。しかし……天気が悪い。\n指定特技　《待つ/環境４》\n成功 奴はまだ現れない。天気に呼応するかのようにあなたの気分も暗くなる。感情属性を「恐怖」に設定。\n失敗　耐えきれずその場を去る。こんな思いをするのも全部ヤツのせいだ。感情属性を「怒り」に設定。
TABLE_TEXT_END
          },

          'TK2ET' => {
            :name => "トラッキング遭遇表2nd",
            :type => '1d6',
            :table => <<'TABLE_TEXT_END'
状況　あなたはモノビーストの眼前に立ちふさがり、相手になってやると宣言する。言葉が通じなくとも、喧嘩を売ったことは伝わるはずだ。\n指定特技　《売る/社会６》\n成功  このセッション中、【基本攻撃】の攻撃判定にプラス１の修正が付く。\n失敗 まるで相手にされない。【感情】が２点増加する。
状況　あなたは病院で目を覚ます。記憶がはっきりしない。どうやら不覚をとったらしく、裏路地で頭を強打して倒れていたようだ。\n指定特技　《脳/頭部７》\n成功  おぼろげに狩りの理由を思い出してきたような気がする。感情属性が反転する。\n失敗 ランダムにアイテムを１つ失う。無くしたことすら気づかない。
状況　夜ごとにモノビーストを追いかける生活が続く中、あなたの腕がうずく。思う存分にふるわれる時が間もないことに気づいているのだろうか。\n指定特技　《逆腕/腕部９》\n成功 このセッション中、練習判定にプラス１の修正がつく。 \n失敗 よく調べたら腕が折れていた。【モラル】が２点減少する。
状況　ヤツの捕食をまめに妨害することで、夜の行動範囲を狭めていく。もうすぐ、満月の夜には追い詰めることができるだろう。\n指定特技　《塞ぐ/胴部２》\n成功  その後のことに想いを馳せる。感情属性を好きに変更できる。\n失敗 追い詰める過程で手傷を負う。「重傷」の変調を発動する。
状況　ヤツを見つけてからいくつの夜が過ぎ去っただろう。モノビーストの足取りを追って移動を続けるあなたの体力は限界を迎えようとしていた。\n指定特技　《逆脚/脚部９》\n成功  いや、まだいける。【モラル】を２点増加させる。\n失敗 もう足が動かない。【モラル】を２点減少する。
状況　モノビーストのねぐらを発見した。問題は人間の匂いに気づいてあたりを嗅ぎ回るヤツからどうやって隠れ、戻るかだ。\n指定特技　《隠れる/環境６》\n成功  じっくりモノビーストを観察する機会を得る。このセッション中、習性調査判定にプラス１の修正がつく。\n失敗 あなたを見つけたモノビーストはこのねぐらを放棄した。感情属性が反転する。
TABLE_TEXT_END
          },

          'TK3ET' => {
            :name => "トラッキング遭遇表3rd",
            :type => '1d6',
            :table => <<'TABLE_TEXT_END'
状況　舞台は整った。やつを追い詰めながら作り上げてきた包囲網は、確実にヤツをあの場所に追い詰めている。急ぐ必要はない。ゆっくりと行こう。\n指定特技　《作る/社会８》\n成功  準備に時間をかけたので、アイテムを一つ入手できる。\n失敗 ゆっくりした結果、モノビーストは何人か犠牲者を増やし、【モラル】を３点増加させている。
状況　煌々と輝く月の下、行くべき場所はすでに分かっていた。武器が、体が、夜に満ちる死の予感に震える。決戦の時が来たのだ。\n指定特技　《予感/頭部９》\n成功  日暮れの戦闘フェイズの間、自分が行う全ての攻撃のダメージにプラス１の修正がつく。\n失敗 あれ、いない？あてがはずれた結果、日暮れの追跡フェイズの判定すべてにマイナス２の修正がつく。
状況　ついにモノビーストに追いつき、憎しみを込めて殴りつける。この夜の間だけは対等だ。痛みと自分の血の味を知るがいい！\n指定特技　《殴る/腕部３》\n成功  命中！モノビーストの【モラル】を２点減少させる。\n失敗 効いた様子がない。【感情】が２点増加する。
状況　ついに追いつめたモノビーストが威嚇とともに襲いかかってくるが、あなたは慌てずにその攻撃を受け止める。驚いた顔のまま死ぬ人間ばかりではないことを教えてやろう。\n指定特技　《受ける/腕部６》\n成功  攻撃を受けてみた結果、感情属性を好きに変更できる。\n失敗 攻撃を受けたときに、「流血」の変調を発動する。
状況　ヤツは満月の持つ意味を知っていた。だが、必死に逃げようとするモノビーストにも知らないことはあった。あなたはヤツより速いのだ。\n指定特技　《迫る/脚部２》\n成功  ヤツは動揺している。モノビーストの【感情】が２点増加する。\n失敗 速いはずだがなぜか追いつけない。日暮れの戦闘フェイズの先制判定を行わず、必ず後攻になる。
状況　モノビーストの出現ポイントにあたりをつけ、あなたは狩りの前に休息をとる。あの獣を自分の手で殺すため、今は力をたくわえよう。\n指定特技　《休む/環境３》\n成功  英気を養った。【モラル】が２点増加する。\n失敗 じっとしているうちに不安になってきた。感情属性が反転する。
TABLE_TEXT_END
          },
        }.freeze

      setPrefixes(['(ET|CLT|SLT|HLT|FLT|DLT|MAT|SAT|SA2T|TST|THT|TAT|TBT|TLT|TET)\d*'] + TABLES.keys)
    end
  end
end
