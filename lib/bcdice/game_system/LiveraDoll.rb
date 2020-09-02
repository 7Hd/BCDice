# -*- coding: utf-8 -*-
# frozen_string_literal: true

module BCDice
  module GameSystem
    class LiveraDoll < DiceBot
      # ゲームシステムの識別子
      ID = 'LiveraDoll'

      # ゲームシステム名
      NAME = '紫縞のリヴラドール'

      # ゲームシステム名の読みがな
      SORT_KEY = 'ししまのりうらとおる'

      # ダイスボットの使い方
      HELP_MESSAGE = <<MESSAGETEXT
アタックX：[x]ATK(BNo)

[]内のコマンドは省略可能。
「x」でダイス数を指定。省略時は「1」。
(BNo)でブロックナンバーを指定。「236」のように記述。順不同可。

【書式例】
・4ATK263 → 4dでブロックナンバー「2,3,6」の判定。
----------------------------------------------------------------
以下のコマンドは、リヴラデッキカードの補助を目的としたものです。
使用の際は上部メニューより
「カード　→　カード配置の初期化　→　紫縞のリヴラドール：リヴラデッキ」
と操作し、リヴラデッキを使用できる状態にしておいてください。

各リヴラデッキカードの末尾に書かれている [] 内のコマンドをタイプすると、
カード名と効果のテキストを参照できます。
コマンドは【色】【ネイル種別】【管理番号】の3要素で構成されており、
それぞれ、以下の文字が対応しています。

【色】
C：無　K：黒　W：白　R：赤　B：青　G：緑　E：ライヴラリアン

【ネイル種別】
L：リヴラネイル　D：パッシヴドレス　O：オーナーズネイル

例：CL1（無色のリヴラネイルの1番目『ストライク』）
例：KD2（黒のパッシヴドレスの2番目『第二夜の黒』）
例：WO3（白のオーナーズネイルの3番目『罪なき純白』）
MESSAGETEXT

      setPrefixes([
        '(C|K|W|R|B|G|E)(L|D|O)\d+',
        '(\d+)?ATK([1-6])?([1-6])?([1-6])?([1-6])?([1-6])?([1-6])?'
      ])

      def initialize
        super

        @sortType = 3
      end

      def rollDiceCommand(command)
        output =
          case command.upcase

          when /^(\d+)?ATK([1-6])?([1-6])?([1-6])?([1-6])?([1-6])?([1-6])?$/i
            diceCount = (Regexp.last_match(1) || 1).to_i
            blockNo = [(Regexp.last_match(2) || 0).to_i, (Regexp.last_match(3) || 0).to_i, (Regexp.last_match(4) || 0).to_i, (Regexp.last_match(5) || 0).to_i, (Regexp.last_match(6) || 0).to_i, (Regexp.last_match(7) || 0).to_i]
            blockNo.delete(0)
            blockNo = blockNo.sort
            blockNo = blockNo.uniq

            output = checkRoll(diceCount, blockNo)

          when /^(C|K|W|R|B|G|E)(L|D|O)(\d+)$/i
            color = Regexp.last_match(1).upcase
            cardtype = Regexp.last_match(2).upcase
            cardindex = Regexp.last_match(3).to_i
            get_card_text(color, cardtype, cardindex)

          end

        return output
      end

      def checkRoll(diceCount, blockNo)
        _dice, diceText = roll(diceCount, 6, @sortType)
        diceArray = diceText.split(/,/).collect { |i| i.to_i }

        resultArray = []
        success = 0
        diceArray.each do |i|
          if blockNo.count(i) > 0
            resultArray.push("×")
          else
            resultArray.push(i)
            success += 1
          end
        end

        blockText = blockNo.join(',')
        resultText = resultArray.join(',')

        result = "#{diceCount}D6(Block:#{blockText}) ＞ #{diceText} ＞ #{resultText} ＞ 成功数：#{success}"

        return result
      end

      def get_card_text(color, cardtype, cardindex)
        if cardindex == 0
          return nil
        end

        case color
        when 'C'
          case cardtype
          when 'L'
            table = [
              [1, '『ストライク』　対象に【アタック：１《ＯＤ》】を行い、可能ならば追加で【エクストルード】を行う（可能な状況であれば行わなければならない）。'],
              [2, '『シュート』　対象に【アタック：１《ＯＤ》】を行う。対象が自身より低い「高度」に存在する場合、代わりに【アタック：２《ＯＤ》】を行う。'],
              [3, '『スナイプ』　対象に【アタック：１《ＯＤ》】を行う。対象が自身より低い「高度」に存在する場合、代わりに【アタック：２《ＯＤ》】を行う。'],
              [4, '『ウォーク』　【ムーヴ：１】を行う。'],
              [5, '『ラン』　【ムーヴ：２】を行う。'],
              [6, '『オルタネート』　直後に行うアタックネイルでは、ダイスロールを２度行い、任意の一方の結果を選ぶことが出来る。'],
              [7, '『ジャンプ』　このアタックネイル終了時まで自身が「高度：３《ＯＤ》」に存在するものとして扱う。'],
              [8, '『オーヴァードライヴ』　直後のネイルでは《ＯＤ》指定された数値を「４《ＯＤ》」増加する。'],
              [9, '『ガード』　ダイスロールで使用されたダイスの内ふたつまでを選ぶ。その出目を１減少する。'],
              [10, '『パリィ』　ダイスロールで使用されたダイスの内ふたつまでを選ぶ。そのダイスを振り直しさせる。この時、振り直した後の値のみを採用する。'],
              [11, '『カウンターアタック』　自身の「シールドレス」を破壊したユニットに対し、即座に【アタック：１】を行う。'],
              [12, '『トラップ』　移動を行ったユニットに対し、即座に【アタック：１】を行う。'],
              [13, '『ミスチーフ』　移動を行ったユニットに、追加で【ムーヴ：１】を行わせる。この移動先は貴女が決定する。'],
              [14, '『ライトニングダンス』　即座に【ムーヴ：１】を行う。（これによって、直後のアタックネイルの射程の外に出た場合、そのアタックネイルのダイスロールは行われず、失敗したことになる）'],
            ]
          when 'D'
            table = [
              [1, '『貴女好みの装い（おすきなように）』　貴女好みの装いは破壊されない。'],
              [2, '『迷子の貴女へ（きめられないのなら、そのままどうぞ）』　全ての色（無色を含む）のＡｓレベルが３であるかのようにオーナーズネイルを使用することが出来る。'],
            ]
          end
        when 'K'
          case cardtype
          when 'L'
            table = [
              [1, '『黒爪の掻きむしり（デザイア・スクラッチ）』　対象に【アタック：黒Ａｓレベル《ＯＤ》＋１】を行う。'],
              [2, '『黒爪の突き刺し（ヘイトレッド・ピアース）』　対象に【アタック：３《ＯＤ》】を行い、その後【エクストルード】を行ってもよい。'],
              [3, '『黒弾の豪雨（ブラックレイン・ダムネイション）』　対象に【アタック：４】を行う。その後自身に【アタック：１】を行う。'],
              [4, '『黒弾の奔流（ブラックニードルカスケイド）』　対象に【アタック：２】を行う。対象が自身よりも低い「高度」に存在する場合、代わりに【アタック：４《ＯＤ》】を行う。'],
              [5, '『黒影の疾走（シャドウ・ストリート・ラン）』　【ムーヴ：１】か【ムーヴ：２】のどちらかを行う。'],
              [6, '『夜空を征け（ナイト・ランナー）』　【ムーヴ：１】を行う。このムーヴネイル以降、クリンナップフェイズ終了時まで、自身が「高度：７」に存在するものとして扱う。'],
              [7, '『黒刃の執行者（ブラック・エンフォーサー）』　直後に行うアタックネイルでは、《ＯＤ》指定された数値を「２《ＯＤ》」増加する。また、２以上の成功数が出た場合、攻撃対象の「シールドレス」を追加でもう１枚破壊する。'],
              [8, '『黒茨の塔を駆け抜けよ（スーサイド・ドライヴ）』　自身に【アタック：１】を行う。これ以降クリンナップフェイズ終了時まで、地震が「高度：１３《ＯＤ》」に存在するものとして扱う。'],
              [9, '『舞い踊る黒刃（ハイマニューバ・ブラック・ブレイド）』　直前のムーヴネイルで移動したセル数に等しい回数だけ、直後のアタックネイルの複製を作成し、実行する。'],
              [10, '『影跳び（シャドウ・ダッジ）』　直前のアタックネイルによって、自身の「シールドレス」が１枚も破壊されていなかった場合、即座に【ドロゥ：１】を行う。'],
              [11, '『報復の刃（アヴェンジャー・エッジ）』　自身の「シールドレス」を破壊したユニットに対し、即座に【アタック：黒Ａｓレベル】を行う。'],
            ]
          when 'D'
            table = [
              [1, '『始まりの黒（ニューブラック・ドレス）』'],
              [2, '『第二夜の黒（クレセントブラック・ドレス）』　自身がドロゥを行う時、自身に【アタック：１】を行うことで、ドロゥ数を＋２しても良い。'],
              [3, '『第三夜の黒（ハーフブラック・ドレス）』　自身がドロゥを行う時、ダイスロールを行うダイスのうちひとつを振らず、任意の出目を出したものとして良い。'],
              [4, '『第四夜の黒（フルブラック・ドレス）』　いずれかのユニットがムーヴネイルを使用する度、そのユニットに対し即座に【アタック：２】を行ってもよい。'],
              [5, '『終わりの黒（ダークブラック・ドレス）』　自身を含む全てのユニットの、ドロゥフェイズ中のドロゥ数を５減少する。'],
            ]
          when 'O'
            table = [
              [1, '『意志の介入（マインド・ランペイジ）』　プレイヤーの１人を対象とする。対象のオーナーズネイルをすべて見る。その後、その中のひとつを「使用済」にする。'],
              [2, '『意志の散逸（マインド・ロスト）』　ドロゥのダイスロールに使用されたダイスひとつを取り除く。（取り除かれたダイスはセットダイスとしてセットされない）'],
              [3, '『漆黒の願い（ブラック・ウィッシュ）』　このラウンドの終了時まで、自身の黒のコスト上限を３増加する。（例えば、現在の黒のＡｓレベルが２である場合、このラウンドの間のみＡｓレベルが５であるかのようにオーナーズネイルを使用することが出来る。ただし、実際にＡｓレベルが上昇しているわけではないことに注意すること）'],
              [4, '『想いの黒刃（ハートブレイド：ブラック）』　ユニット１体を対象とする。対象に【アタック：３】を行い、自身のリヴラドールに【アタック：１】を行う。'],
              [5, '『黒の報酬（ブラック・サプライズ）』　自身のリヴラドールに【アタック：１】を行う。このフェイズで行う自身のドロゥ数を２増加する。'],
              [6, '『翔けよ黒夜（ミッドナイトホーク）』　このラウンド終了時まで、貴女のリヴラドールが使用するアタックネイルに以下の一文を追加する。「対象が自身よりも低い「高度」に存在する場合、追加で【アタック：１】を行う。」'],
              [7, '『傷跡の共鳴（ハート・レゾナンス）』　プレイヤー１人を対象とする。対象の「シールドレス」を１枚破壊する。その後自身の「シールドレス」を１枚破壊する。'],
              [8, '『居心地の悪さ（ブラック・マイアズマ）』　このムーヴネイルを打ち消す。'],
              [9, '『鉄茨よ侵食せよ（ブラックブランブル）』　セルひとつを指定する。指定したセルに「鉄茨マーカー」を設置する。'],
              [10, '『鉄華乱舞（アイアン・ブルーム）』　ユニット１体を対象とする。対象に【アタック：３】を行う。これによって対象の「シールドレス」を１枚以上破壊した場合、対象のセットダイスの内、貴女の任意のふたつを取り除く。'],
              [11, '『だむねいしょん』　自身のリヴラドールを含む、ナインライヴラリ上に存在する全てのユニットの現在の「パッシヴドレス」を１枚破壊する。（現在のパッシヴドレスの前に装備していたパッシヴドレスへと変更される）'],
              [12, '『残酷な真実（クルーエルトゥルース）』　リヴラオーナー１人を対象とする。対象のオーナーズネイルをすべて見る。その後、その中のみっつを「使用済」にする。'],
              [13, '『孤独と銃と最前線（アヴァンドナー）』　これ以降自身のリヴラが行うムーヴネイル全てに以下の一文を追加する。「移動先のセルに存在するユニットに対し【アタック：１】を行っても良い」。これはリヴラバトル終了時まで継続する。'],
              [14, '『節制の黒絢（テンパランス：ザ　ブラックソード）』　自身のオーナーズネイルの内、任意のふたつの「使用済」を解除する。'],
              [15, '『雷電の黒絢（ライトニング：ザ　ブラックソード）』　ユニット１体を対象とする。対象に【アタック：２】を行う。これによって対象の「シールドレス」を１枚以上破壊した場合、さらに対象のセットダイスを１個取り除く。'],
              [16, '『思索の黒絢（マインド：ザ　ブラックソード）』　全てのプレイヤーはプレイヤー自身のセットダイスを１個取り除く。その後貴女は【ドロゥ：２】を行う。'],
              [17, '『爛熱の黒絢（グロウス：ザ　ブラックソード）』　全てのプレイヤーは【ドロゥ：１】を行う。その後、貴女は【ドロゥ：２】を行う。'],
            ]
          end
        when 'W'
          case cardtype
          when 'L'
            table = [
              [1, '『閃け白刃（ホワイトブレイド）』　対象に【アタック：白Ａｓレベル《ＯＤ》＋１】を行い、その後【エクストルード】を行ってもよい。'],
              [2, '『二重に響け白刃（ホワイト・ダブルストライク）』　対象に【アタック：１】を行い、その後【アタック：１】を行う。'],
              [3, '『白き弾丸にて狙い撃て（ホワイト・スナイパー）』　対象に【アタック：２】を行う。対象が自身よりも低い「高度」に存在する場合、代わりに【アタック：４《ＯＤ》】を行う。'],
              [4, '『白き弾丸よ降り注げ（ホワイト・バレットシャワー）』　対象に【アタック：３《ＯＤ》】を行い、続けて【アタック：３】を行う。'],
              [5, '『白光の如く駆けよ（フラッシュ・ランニング）』　【ムーヴ：３】を行う。'],
              [6, '『閃光の突撃（フラッシュチャージ）』　対象が存在するセルへ移動する。'],
              [7, '『白光の衣（ホワイト・エンチャント）』　直後のアタックネイルで、現在の自身の「シールドレス」の枚数以上の成功数が出た場合、自身の「シールドレス」を１枚回復する。'],
              [8, '『荘厳なりし白の塔（ホワイトゴールドタワー）』　クリンナップフェイズ終了時まで、自身が「高度：８《ＯＤ》」に存在するものとして扱う。'],
              [9, '『輝きの盾（ホワイトシールド）』　自身のパッシヴドレスの「ブロックナンバー」に６を追加する。この効果はこのダイスロールの結果のみに有効である。'],
              [10, '『より疾きは光の一手（ライトニング・インターセプト）』　移動を行ったユニットに対し、即座に【アタック：２】を行う。'],
              [11, '『白の語り部（ホワイトテラー）』　ダイスロールで使用されたダイス全ての出目を６に変更する。'],
            ]
          when 'D'
            table = [
              [1, '『愚者の白（ホワイトフール）』'],
              [2, '『魔術師の白（ホワイトマジシャン）』　自身が「高度：６」以上に存在する時、ドロゥ数を＋１しても良い。'],
              [3, '『女教皇の白（ホワイトハイプリエステス）』　１ラウンドに１回まで、自身のダイスロールの出目ひとつを１増加しても良い。'],
              [4, '『女帝の白（ホワイトエンプレス）』　自身の白のアタックネイルに、以下の一文を追加する。「続けて【アタック：１】を行う。射程はこのアタックネイルに準ずる」'],
              [5, '『皇帝の白（ホワイトエンペラー）』　自身の「シールドレス」が破壊される度に、１ｄ６のダイスロールを行う。この時１か２の出目が出た場合「シールドレス」を１枚回復する。'],
            ]
          when 'O'
            table = [
              [1, '『秩序の護り手（ホワイト・ディフェンダー）』　【ドロゥ：１】を行う。'],
              [2, '『あなたにも愛を（トゥーミーユアラヴリィ）』　自身の「シールドレス」を１枚回復し、その後自身以外の「シールドレス」を１枚回復する。'],
              [3, '『罪なき純白（じゅんぱくイノセント）』　このドロゥフェイズで行うダイスロールの出目を全て１減少する。（１の出目は１のままである）'],
              [4, '『白銀に輝け我が左腕（アージェティア）』　このアタックネイルで「シールドレス」を少なくとも１枚以上破壊した場合、追加で【アタック：２】を行う。'],
              [5, '『撲滅の白（パニッシュメント・ブレス）』　自身のリヴラドールを含む、ナインライヴラリ上に存在する全てのユニットに【アタック：２】を行う。'],
              [6, '『誠実の白（ホワイトオネスティ）』　次のスタンバイフェイズ開始時まで、自身のリヴラドールのパッシヴドレス「ブロックナンバー」に５を追加する。'],
              [7, '『正義の剣（ソード・オブ・ジャスティス）』　このアタックネイルで「シールドレス」を少なくとも２枚以上破壊した場合、自身の「シールドレス」を１枚回復する。'],
              [8, '『物語の護り手（ロア・ディフェンダー）』　ナインライヴラリ上に存在するマーカーを、任意の数取り除く。'],
              [9, '『撲滅の賦（がらすまどのむこうがわ）』　自身のリヴラドールを含む、ナインライヴラリ上に存在する全てのユニットの現在の「パッシヴドレス」を１枚破壊する。（現在のパッシヴドレスの前に装備していたパッシヴドレスへと変更される）'],
              [10, '『忘却の白（ホワイト・オブリビオン）』　自身のセットダイスを全て取り除く。自身のオーナーズネイルの内、任意のふたつの「使用済」を解除する。'],
              [11, '『白の従者（ホワイト・フォロワ）』　セルひとつを指定する。指定したセルに「白従者マーカー」を設置する。'],
              [12, '『秩序の龍（クロム・クラーク・レプリカ）』　セルひとつを指定する。指定したセルに「偽龍マーカー」を設置する。'],
              [13, '『夢の向こうの旅人（ロアテラ）』　このドロゥフェイズで行うダイスロールでは、ダイスそれぞれに対し、任意の出目が出たものとして扱う。'],
              [14, '『混色もまた物語：黒（ロア：ブラック）』　自身を含む全てのユニットに【アタック：４】を行う。'],
              [15, '『混色もまた物語：赤（ロア：レッド）』　ユニット１体を対象とする。対象に【アタック：ラウンド数】を行う。このアタックで「シールドレス」を破壊した場合、貴女の「シールドレス」を１枚回復する。'],
              [16, '『混色もまた物語：青（ロア：ブルー）』　使用されたオーナーズネイルの効果は発揮されず、「使用済」となる。'],
              [17, '『混色もまた物語：緑（ロア：グリーン）』　プレイヤー１人を対象とする。対象の「シールドレス」を１枚回復する。'],
            ]
          end
        when 'R'
          case cardtype
          when 'L'
            table = [
              [1, '『焼きつくせ炎の爪（ファイアクロウ）』　対象に【アタック：赤Ａｓレベル《ＯＤ》＋２】を行う。'],
              [2, '『焦がれの情熱（ファイアフィスト）』　対象に【アタック：４】を行い、その後追加で【エクストルード】を行っても良い。'],
              [3, '『掻きむしれ炎禍（ファイアドライヴ）』　対象に【アタック：赤Ａｓレベル】を行い、その後【エクストルード】を行う。移動先は対象ごとに、貴女が決定する。'],
              [4, '『炎の壁よなぎ払え（ファイアウォール）』　自身の存在するセルと、隣接しているセル全てに存在するユニット全て（自身を除く）を対象とする。対象に【アタック：２】を行う。'],
              [5, '『赤熱鉄柱ぶん回しの刑（マス・ファイア・ブレード）』　対象に【アタック：４】を行い、続けて【アタック：３《ＯＤ》】を行う。その後【エクストルード】を２度行う。'],
              [6, '『赤熱溶断ぶった斬り（ヒュージ・ファイア・ブレード）』　対象に【アタック：３《ＯＤ》】を行い、続けて【アタック：２】を行い、続けて【アタック：１】を行う。'],
              [7, '『追い打ちの炎渦（ファイアストーム）』　直後に行うアタックネイルでは、《ＯＤ》指定された数値を「３」増加する。また、このアタックネイルで「シールドレス」を１枚以上破壊した場合、即座に【ドロゥ：２】を行い、続けてセットダイスを２個取り除く。'],
              [8, '『雷電疾走（ライトニング・ランニング）』　【ムーヴ：３】を行う。'],
              [9, '『烈火流星雨あられ（メテオストーム）』　このムーヴネイルに以下の一文を追加する。「このムーヴネイルの移動開始セル、通過したセル、移動完了セルに存在する全てのユニット（自身を含む）に【アタック：３】を行う」'],
              [10, '『あなたは私のもの！（にがさない）』　移動を行ったユニットを、自身と同じセルまで移動させる。'],
              [11, '『叩き落とせ！（フォールアウト）』　アタックネイルを使用するユニット１体を対象とする。対象が存在するセルの高度を０に変更する。また対象の「高度」をクリンナップフェイズまで、即座に０に変更する。'],
            ]
          when 'D'
            table = [
              [1, '『灯散らす赤き花輪（フローラルリング）』　リヴラフェイズ開始時に、任意のユニット１体を対象とし【アタック：１】を行ってもよい。'],
              [2, '『アネモスのビスチェ』　ドロウフェイズ時、自身のドロゥ数を１減少することで、自身を除く全てのユニットに【アタック：１】を行うことを選んでも良い。'],
              [3, '『ベラドンナのピンヒール』　自身の行う【アタック：Ｘ】では、攻撃対象のブロックナンバーのうち「２」を無視して攻撃を行うことが出来る。'],
              [4, '『オダマキの花冠（フラワークラウン）』　クリンナップフェイズの開始時に、自身を除く全てのユニットに【アタック：２】を行う。'],
              [5, '『朱塔の花園（ブルーミングガーデン）』　メインフェイズ開始時、自身の「シールドレス」を１枚破壊しても良い。こうした場合、オーナーズネイルひとつの「使用済」を解除する。'],
            ]
          when 'O'
            table = [
              [1, '『走れ雷電（ライトニング・ボルト）』　ユニット１体を対象とし、【アタック：２】を行う。全てのプレイヤーは、このオーナイズネイルに対し、リアクトネイルを使用することが出来ない。'],
              [2, '『穿て炎槍（フレイムランス）』　ユニット１体を対象とし、【アタック：２】を行う。全てのプレイヤーは、このオーナイズネイルに対し、リアクトネイルを使用することが出来ない。'],
              [3, '『熱情と踊れ（ダンス・ウィズ・ヒート）』　自身のリヴラドールを含む全てのユニットに対し【アタック：１】を行う。'],
              [4, '『昇炎の罠（ファイアリングトラップ）』　直後のムーヴネイルで移動を行ったユニットを対象とし、【アタック：３】を行う。'],
              [5, '『精神混沌の炎（レッド・パラノイア）』　自身のセットダイスのうち、任意のふたつを取り除き、【ドロゥ：２】を行う。セットダイスがふたつ以上存在しない場合にはこのネイルを使用することが出来ない。'],
              [6, '『愛情の渇望（あなたがほしい）』　任意のユニット１体を対象とする。対象を自身と同じセルに移動させる。その後自身と同じセルに存在するユニット全てに【アタック：２】を行う。'],
              [7, '『過去からの想い（６４００年後の私へ）』　このドロゥフェイズで貴女はドロゥを行うことが出来ない。次のラウンドのドロゥフェイズでは、貴女のドロゥ数を７増加する。'],
              [8, '『咲き乱れよ百合の花（レッド・リリィ）』　自身を含む全てのユニットが行ったドロゥのダイスロール結果全てを振り直させる。'],
              [9, '『煉獄の恋（ヘルフレイム・ラヴソング）』　プレイヤー１人を対象とする。対象の「シールドレス」を１枚破壊する。その後自身の「シールドレス」を１枚破壊する。'],
              [10, '『その信頼は重圧（トラストユー）』　ユニット１体を対象とする。このラウンドの終了時まで、対象がいずれかのユニットに【アタック：Ｘ】を行う度に、対象に【アタック：１】を行う。'],
              [11, '『龍炎の嵐（ドラゴンストーム）』　セルひとつを指定する。指定したセルに「炎龍マーカー」を設置する。'],
              [12, '『復讐の花（ブルーム・オブ・リベンジ）』　自身のリヴラドールを除く全てのユニットに【アタック：４】を行い、続けて【アタック：３】を行う。'],
              [13, '『再臨の銀（アガートラム）』　このドロゥフェイズで行った自身のダイスロール結果のダイス全ての出目を３減少する。その後【ドロゥ：３】を行う（このドロゥには出目減少の効果は適用されない）。'],
              [14, '『銀腕、携えるは黒（フレイガラク：ブラック）』　自身のセットダイスを２個取り除く。ユニット１体を対象とする。対象に【アタック：３】を行い、【アタック：２】を行い、【アタック：１】を行う。'],
              [15, '『銀腕、携えるは白（クライドハームソルース：ホワイト）』　全てのユニットの「シールドレス」を１枚回復する。その後貴女はさらに「シールドレス」を１枚回復する。'],
              [16, '『銀腕、携えるは青（カレトヴルッフ：ブルー）』　【ドロゥ：５】を行う。その後セットダイスを２個取り除く。'],
              [17, '『銀腕、携えるは緑（スカザック：グリーン）』　セルひとつを指定する。指定したセルに「影槍マーカー」を設置する。'],
            ]
          end
        when 'B'
          case cardtype
          when 'L'
            table = [
              [1, '『碧空の剣（ストラトスフィア・ブレイド）』　対象に【アタック：３】を行う。'],
              [2, '『蒼天の剣靴（ストラトスフィア・ブレイドブーツ）』　対象に【アタック：１】を行う。対象が自身よりも低い「高度」に存在する場合、代わりに【アタック：４《ＯＤ》】を行い、対象の存在するセルへ移動する。'],
              [3, '『強襲翼撃（ウィング・ブレイド）』　対象に【アタック：３《ＯＤ》】を行い、対象の存在するセルへ移動する。'],
              [4, '『蒼弓の猛撃（ブルー・アローレイン）』　対象に【アタック：１】を行う。対象が自身よりも低い「高度」に存在する場合、続けて【アタック：３】を行う。'],
              [5, '『空歩き（エアステップ）』　【ムーヴ：２】を行う。このムーヴネイル以降、クリンナップフェイズ終了時まで、自身が「高度：６《ＯＤ》」に存在するものとして扱う。'],
              [6, '『凪歩き（カームステップ）』　【ムーヴ：１】を行う。移動先のセルにリヴラドールが存在する場合、【エクストルード】を行っても良い。'],
              [7, '『風の道標（ウィンドサインポスト）』　このアタックネイルの効果で「シールドレス」を１枚以上破壊した場合、アタックネイルの処理が終わった後、【ドロゥ：１】を行う。'],
              [8, '『精密思考（シャープセンス）』　このアタックネイルでは、攻撃対象のブロックナンバーのうち「３」を無視して攻撃を行うことが出来る。'],
              [9, '『思考の渦（ぐるぐる）』　ダイスロールに使用されたダイスひとつを指定する。そのダイスを振り直させる。'],
              [10, '『空翔けの回避（レビテート）』　そのアタックネイルのダイスロールで使用されたダイス全ての出目を１減少する。'],
              [11, '『たゆたう心、空の様に（ストラトスフィア・ハート）』　自身に適用された【エクストルード】を打ち消し、元のセルへと戻る。その後【ドロゥ：１】を行う。'],
            ]
          when 'D'
            table = [
              [1, '『青空を這い（スカイ・クロウラ）』　セットアップフェイズ毎に、ダイスを１個振っても良い。そうした場合、クリンナップフェイズまで、ダイスの出目に等しい「高度」に自身が存在するものとして扱う。'],
              [2, '『碧海を舞い（ブルー・アルペジオ）』　自身が「高度：０」にいる間、ドロゥ数を２増加する。'],
              [3, '『蒼天を翔ける（キディ・グレイド）』　ドロゥフェイズでのドロゥ数を１減少することで、即座に任意のユニット１体に【アタック：１】を行っても良い。この効果は１ラウンドに１回のみ宣言出来る。'],
              [4, '『戦場の妖精（フェアリィドレス：スノウ・ウィンド）』　自身が「高度：６」以上に存在する間、自身のブロックナンバーに６を追加する。'],
              [5, '『いつか碧空の果てへ（プレアデス）』　自身がドロゥを行う時、ダイスロールに使用するダイスの内最大２個を任意の出目が出たことにして良い。'],
            ]
          when 'O'
            table = [
              [1, '『冷静な思案（いま、このタイミング）』　【ドロゥ：青Ａｓレベル】を行う。'],
              [2, '『入念な思考（これとこれは、いらないかな）』　【ドロゥ：１】を行い、セットダイスから任意のひとつを取り除く。'],
              [3, '『即決即断（みてたよ。させないんだから）』　このダイスロールのダイス目全てを２減少する。'],
              [4, '『方針変更（こっちの方がきっといいよ）』　ダイスロールで使用されたダイスひとつを裏返す（もしくは７からその出目の数値を引いた出目に変更する）。'],
              [5, '『小さな知略（マハトマ）』　任意のプレイヤー１人を対象とする。対象のオーナーズネイルを見る。その中から１枚を指定する。対象はそのオーナーズネイルを次のラウンドのクリンナップフェイズまで使用できなくなる。'],
              [6, '『青の精鋭（ブルー・アデプト）』　セットダイスを２個取り除く。ユニット１体を対象とする。対象に【アタック：２】を行う。'],
              [7, '『対抗（カウンタースペル）』　使用されたオーナーズネイルの効果は発揮されず、「使用済」となる。'],
              [8, '『碧空の加護（オルガ）』　自身のオーナーズネイルひとつの「使用済」を解除する。'],
              [9, '『思考妨害（あ、あれ見て？）』　ダイスロールに使用されたダイスの内、最大ふたつまでを指定する。それらのダイスを振り直させる。'],
              [10, '『碩学式回路（ジーニアス・サーキット）』　【ドロゥ：３】を行い、セットダイスから任意のふたつを取り除く。'],
              [11, '『碩学式"大"回路（ジーニアス・メガ・サーキット）』　任意のプレイヤー１人を対象とする。対象のオーナーズネイルを見る。その中から１枚を指定する。そのオーナーズネイルに以下の一文を追加する。「この効果を解決した後、自身に【アタック：５】を行う。」'],
              [12, '『偉大なる集合知（ハイアラキ）』　【ドロゥ：６】を行い、セットダイスから任意のみっつを取り除く。'],
              [13, '『碧空を越える者（ストラトスフィア・ブレイヴ）』　【ドロゥ：自身のリヴラドールの現在の高度】を行う。'],
              [14, '『深淵なる熟慮（わるだくみ）』　【ドロゥ：２】を行う。この時、６の出目を出したダイスはセットされず、取り除かれる。'],
              [15, '『深遠たる秩序（知識こそが正義）』　１～６の内、数字をひとつ指定する。このドロゥフェイズの間、全てのプレイヤーが行う【ドロゥ：Ｘ】では、指定した出目を出したダイスはセットすることが出来ない。'],
              [16, '『深淵より至れ、始まりへ（アマランサス・レプリカ）』　自身の「シールドレス」を１枚破壊する。【ドロゥ：３】を行い、自身のオーナーズネイルひとつの「使用済」を解除する。'],
              [17, '『深遠より至れ原初の森（混沌の森）』　リヴラドール１体を対象とする。対象の現在のパッシヴドレスと、自身のパッシヴドレスを交換する。この効果はクリンナップフェイズまで継続する。（効果中にパッシヴドレスが破壊されていた場合、破壊される前のパッシヴドレスに戻る）'],
            ]
          end
        when 'G'
          case cardtype
          when 'L'
            table = [
              [1, '『隕鉄の剣（メテオ・ブランド）』　対象に【アタック：緑Ａｓレベル＋２《ＯＤ》】を行う。'],
              [2, '『大樹の槌（トネリコ・ハンマー）』　対象に【アタック：緑Ａｓレベル＋１】を行い、続けて【エクストルード】を行う。'],
              [3, '『巨腕の操者（ストレングス・アーム）』　対象に【アタック：５】を行い、【アタック：２】を行い、続けて【エクストルード】を行う。'],
              [4, '『地を割る弾丸（ガイア・バレット）』　対象に【アタック：３《ＯＤ》】を行う。'],
              [5, '『踏み割り進め！（デストラクトウォーク）』　【ムーヴ：１】を行う。移動先のセルの「高度」を１減少する（高度は０より低い値にはならない）。'],
              [6, '『鋼の木樹を纏うように（ワイヤーアクション）』　【ムーヴ：１】を行う。自身が「高度：５」より高いセルから移動する場合、代わりに任意の座標へ移動する。'],
              [7, '『より大きく！（ビッグ・アンド・ビガー）』　直後に行うアタックネイルでは、合計３以上の成功数が出た場合、攻撃対象の「シールドレス」を追加でもう１枚破壊する。'],
              [8, '『より強靭に！（アンド・タフ）』　直後に行うアタックネイルで、合計３以上の成功数が出た場合、自身の「シールドレス」を１枚回復する。'],
              [9, '『翼の切断（まっさかさまにおちなさい）』　対象の「高度」を０に変更する。移動先のセルに「高度」が設定されている場合はその「高度」に変更する。'],
              [10, '『茸の道（マッシュロード）』　即座に【ムーヴ：１】を行う。'],
              [11, '『分かれ道（ロード・トゥワイス）』　対象の移動距離を１減少する。'],
            ]
          when 'D'
            table = [
              [1, '『仮面舞踏会（マスカレイド）』'],
              [2, '『黙示の鎧（アポカリプス）』　自身が「高度：０」に存在する間、自身のブロックナンバーに「５、６」を追加する。'],
              [3, '『昇華の階段（スパイラル・アセンション）』　スタンバイフェイズ毎に、ダイスを２個振り、セルをひとつ指定して良い。そうした場合、そのセルの高度はダイスので目の合計値に変更される。'],
              [4, '『忘却の森（フォレスト：ジ　オブリビオン）』　自身が行う【アタック：Ｘ】で２以上の成功数を出していた場合、破壊する「シールドレス」の枚数は１枚ではなく、成功数の値に等しくなる。'],
              [5, '『永遠に続く一日（バンデッド　アゲート：ザ　ドリーミング）』　自身の全てのネイルの《ＯＤ》指定された値を「５」増加する（この計算は、他の《ＯＤ》指定された数値を変動させる効果の前に行われる）'],
            ]
          when 'O'
            table = [
              [1, '『限定巨大化（リミテッド・グロウス）』　このラウンドの終了時まで、自身のリヴラネイルの【アタック：Ｘ】は【アタック：Ｘ＋１】に変更される。'],
              [2, '『被覆の盾（シュラウド・シールド）』　このアタックネイルの成功数を１減少する。'],
              [3, '『自然の叡智（ネイチャーズ・ウィズダム）』　アタックネイル、リアクトネイルのいずれか一方を指定する。全てのプレイヤーはこのラウンド終了時まで、選択されたネイルを使用することが出来ない。'],
              [4, '『茨の道（ソーン・ロード）』　直後のムーヴネイルで移動を行ったユニットを対象とし、【アタック：２】を行う。'],
              [5, '『小さな花園（リトル・リトル・フラワーガーデン）』　このアタックネイルの【アタック：Ｘ】を【アタック：Ｘ－１】に変更する。'],
              [6, '『バジリスクの寄せ餌（バジリスク・ルア）』　このラウンドの終了時まで、全てのユニットはアタックネイルを使用する度に、使用したユニット自身に【アタック：１】を行う。'],
              [7, '『生命の芽吹き（カム・イントゥ・バッズ）』　セットダイスを２個取り除く。自身のシールドレスを１枚回復する。'],
              [8, '『絡めとり（まちなさい！）』　ユニット１体を対象とする。対象が「高度：１」以上の高度に存在する場合、対象の行う全てのダイスロールの出目を１減少する。'],
              [9, '『繁栄の礎（プロスペリティ）』　直後の自身のドロゥフェイズで、ドロゥを行わないことを選ぶ代わりに、自身の緑のＡｓレベルを１上昇しても良い。'],
              [10, '『なる（ように）なる（ケ・セラ・セラ）』　自身のオーナーズネイルの「使用済」を解除する。'],
              [11, '『現代の災厄の象徴（すけいるどわーむ）』　ユニット１体を対象とする。対象はこのラウンドの終了時までアタックネイルを除くリヴラネイルを使用することが出来ない。また、対象が行うアタックネイルの【アタック：Ｘ】は、【アタック：Ｘ＋２】に変更される。'],
              [12, '『吠え猛る龍禍（ワン・ゼイ・フィア）』　全てのユニットは、そのユニット自身に対して【アタック：そのユニットが存在する高度】を行う。この攻撃によって１枚以上シールドレスが破壊されたユニットは、自身のセットダイスを２個取り除く。'],
              [13, '『緩やかなる原初の監獄（エンクロージア）』　貴女を含む全てのプレイヤーは、そのプレイヤー自身のシールドレスを１枚回復することを選んでも良い。その後、貴女はこれによって回復したシールドレスの合計枚数に等しい数のシールドレスをさらに回復する。'],
              [14, '『裏切りの大渦（ベトレイアル・メイルストロム）』　ユニット１体を対象とする。対象に【アタック：３】を行い、【アタック：２】を行う。その後対象は【ドロゥ：１】を行う。'],
              [15, '『秩序の大渦（メイルストロム・オーダー）』　このラウンドの終了時まで、全てのユニットはアタックネイルを使用することが出来ない。'],
              [16, '『憤怒の大渦（アンガー・メイルストロム）』　全てのプレイヤーのシールドレスを、現在最もシールドレスの枚数が少ないプレイヤーの枚数と同じ枚数に変更する。'],
              [17, '『神秘の大渦（ミスティック・メイルストロム）』　使用されたオーナーズネイルの効果は発揮されず、「使用済」となる。'],
            ]
          end
        when 'E'
          case cardtype
          when 'D'
            table = [
              [1, '『黒の餓狼（ブラックソード・ウルフ）』　1.このユニットが使用するアタックネイルの対象を１増加しても良い。　2.このユニットの【アタック：Ｘ】で３以上の成功数が出た場合、自身のシールドレスを１枚回復する。'],
              [2, '『白の鋼鉄騎士（ぼくめつのりゅう）』　このユニットが使用するアタックネイルの対象を１増加しても良い。'],
              [3, '『赤の飛龍（クロムクラーク）』　1.このユニットが使用するアタックネイルの対象を１増加しても良い。　2.このユニットのアタックネイルの【アタック：Ｘ】のＸを２増加する。'],
              [4, '『青の翼龍（ヴァイエル）』　1.このユニットが使用するアタックネイルの対象を１増加しても良い。　2.このユニットが「高度：９」以上に存在する限り、ブロックナンバーに４を追加する。'],
              [5, '『緑の操り人形（グリーン・ジェイラー）』　自身を含む、このユニットと同じセルに存在するユニットは、クリンナッププロセスの終了時にシールドレスを１枚失う。'],
            ]
          end
        end

        return get_table_by_number(cardindex, table)
      end
    end
  end
end
